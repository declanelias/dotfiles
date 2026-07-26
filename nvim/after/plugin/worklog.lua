-- worklog — editor activity logger for the workflow-tracking system.
-- Writes JSONL to ~/.local/share/worklog/nvim-YYYY-MM-DD.jsonl:
--   buf_enter / buf_write  — file timeline
--   stats (every 60s)      — key counts, mode times, repeat runs, leader maps
--   macro_recorded         — register + duration
-- Privacy: insert-mode/cmdline keys are COUNTED but their content is never
-- recorded; only normal/visual-mode key identities are kept.

local uv = vim.uv or vim.loop
local logdir = vim.fn.expand("~/.local/share/worklog")
local session = vim.env.ZELLIJ_SESSION_NAME or ""
local pane = vim.env.ZELLIJ_PANE_ID or ""

local function today()
  return os.date("%Y-%m-%d")
end

local function log(entry)
  entry.ts = os.date("%Y-%m-%dT%H:%M:%S")
  entry.src = "nvim"
  entry.session = session
  entry.pane = pane
  local ok, line = pcall(vim.json.encode, entry)
  if not ok then return end
  local f = io.open(logdir .. "/nvim-" .. today() .. ".jsonl", "a")
  if not f then return end
  f:write(line, "\n")
  f:close()
end

if vim.fn.mkdir(logdir, "p") ~= 1 then return end

local aug = vim.api.nvim_create_augroup("worklog", { clear = true })

-- ── buffer timeline ─────────────────────────────────────────────────────
local buf_entered = {} -- bufnr -> uv.now() ms
local last_file = nil

vim.api.nvim_create_autocmd("BufEnter", {
  group = aug,
  callback = function(ev)
    local file = vim.api.nvim_buf_get_name(ev.buf)
    if file == "" or vim.bo[ev.buf].buftype ~= "" then return end
    buf_entered[ev.buf] = uv.now()
    if file ~= last_file then
      last_file = file
      log({ event = "buf_enter", file = vim.fn.fnamemodify(file, ":~"), ft = vim.bo[ev.buf].filetype })
    end
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = aug,
  callback = function(ev)
    local file = vim.api.nvim_buf_get_name(ev.buf)
    if file == "" then return end
    local dur = buf_entered[ev.buf] and math.floor((uv.now() - buf_entered[ev.buf]) / 1000) or nil
    log({ event = "buf_write", file = vim.fn.fnamemodify(file, ":~"), time_in_buf_s = dur })
  end,
})

-- ── macros ──────────────────────────────────────────────────────────────
local rec_start = nil
vim.api.nvim_create_autocmd("RecordingEnter", {
  group = aug,
  callback = function() rec_start = uv.now() end,
})
vim.api.nvim_create_autocmd("RecordingLeave", {
  group = aug,
  callback = function()
    local dur = rec_start and math.floor((uv.now() - rec_start) / 1000) or nil
    log({ event = "macro_recorded", register = vim.fn.reg_recording(), dur_s = dur })
  end,
})

-- ── mode time ───────────────────────────────────────────────────────────
local mode_time = {} -- group -> ms
local mode_since = uv.now()
local function mode_group()
  local m = vim.api.nvim_get_mode().mode:sub(1, 1)
  if m == "i" or m == "R" then return "insert" end
  if m == "v" or m == "V" or m == "\22" then return "visual" end
  if m == "c" then return "cmdline" end
  if m == "t" then return "terminal" end
  return "normal"
end
local cur_mode = "normal"

vim.api.nvim_create_autocmd("ModeChanged", {
  group = aug,
  callback = function()
    local now = uv.now()
    mode_time[cur_mode] = (mode_time[cur_mode] or 0) + (now - mode_since)
    mode_since = now
    cur_mode = mode_group()
  end,
})

-- ── keys ────────────────────────────────────────────────────────────────
local key_counts = {} -- keytrans name -> n   (normal/visual only)
local key_total = 0
local insert_keys = 0
local arrow_keys = 0
local repeat_runs = {} -- { {key=, len=} }
local run_key, run_len = nil, 0
local MOVEMENT = { j = true, k = true, h = true, l = true, w = true, b = true, e = true, x = true }

local leader_pending = nil -- { keys = {}, deadline = ms }
local leader_counts = {}
local leader_key = vim.fn.keytrans(vim.g.mapleader or " ")

local function end_run()
  if run_key and run_len >= 5 and #repeat_runs < 20 then
    table.insert(repeat_runs, { key = run_key, len = run_len })
  end
  run_key, run_len = nil, 0
end

vim.on_key(function(key, typed)
  local ok = pcall(function()
    local raw = (typed and typed ~= "") and typed or key
    if raw == "" then return end
    key_total = key_total + 1
    local mode = mode_group()
    if mode == "insert" or mode == "cmdline" or mode == "terminal" then
      insert_keys = insert_keys + 1
      end_run()
      leader_pending = nil
      return
    end
    local name = vim.fn.keytrans(raw)
    if name:match("^<%a*Mouse") or name:match("^<.*Scroll") or name:match("^<%a*Drag") or name:match("^<%a*Release") then
      key_total = key_total - 1
      return
    end
    key_counts[name] = (key_counts[name] or 0) + 1
    if name == "<Up>" or name == "<Down>" or name == "<Left>" or name == "<Right>" then
      arrow_keys = arrow_keys + 1
    end

    -- repeat-run detection (jjjjjjj etc.)
    if MOVEMENT[name] then
      if name == run_key then
        run_len = run_len + 1
      else
        end_run()
        run_key, run_len = name, 1
      end
    else
      end_run()
    end

    -- leader-sequence capture
    local now = uv.now()
    if leader_pending then
      if now > leader_pending.deadline or #leader_pending.keys >= 3 then
        leader_pending = nil
      else
        table.insert(leader_pending.keys, name)
        local seq = "<leader>" .. table.concat(leader_pending.keys)
        if vim.fn.maparg(vim.g.mapleader .. table.concat(leader_pending.keys), "n") ~= "" then
          leader_counts[seq] = (leader_counts[seq] or 0) + 1
          leader_pending = nil
        end
      end
    elseif name == leader_key then
      leader_pending = { keys = {}, deadline = now + 2000 }
    end
  end)
  if not ok then return end
end)

-- ── periodic flush ──────────────────────────────────────────────────────
local last_flush = uv.now()

local function flush_stats()
  if key_total == 0 then
    last_flush = uv.now()
    return
  end
  end_run()
  local now = uv.now()
  mode_time[cur_mode] = (mode_time[cur_mode] or 0) + (now - mode_since)
  mode_since = now

  local top = {}
  for k, n in pairs(key_counts) do
    table.insert(top, { k, n })
  end
  table.sort(top, function(a, b) return a[2] > b[2] end)
  local top_keys = {}
  for i = 1, math.min(15, #top) do
    top_keys[top[i][1]] = top[i][2]
  end
  local modes = {}
  for m, ms in pairs(mode_time) do
    modes[m] = math.floor(ms / 1000)
  end

  log({
    event = "stats",
    window_s = math.floor((now - last_flush) / 1000),
    keys = key_total,
    insert_keys = insert_keys,
    arrow_keys = arrow_keys,
    top = top_keys,
    repeats = repeat_runs,
    leader = next(leader_counts) and leader_counts or nil,
    modes = modes,
  })

  key_counts, key_total, insert_keys, arrow_keys = {}, 0, 0, 0
  repeat_runs, leader_counts, mode_time = {}, {}, {}
  last_flush = now
end

local timer = uv.new_timer()
if timer then
  timer:start(60000, 60000, vim.schedule_wrap(function()
    pcall(flush_stats)
  end))
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = aug,
  callback = function() pcall(flush_stats) end,
})
