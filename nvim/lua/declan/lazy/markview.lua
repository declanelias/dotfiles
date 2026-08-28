return {
	"OXY2DEV/markview.nvim",

	-- Off for now: raw markdown while editing. Flip back to true (or
	-- delete this line) to get the rendered preview again -- everything
	-- below is left intact.
	enabled = false,

	-- NOT lazy-loaded on purpose. The plugin lazy-loads itself internally, so
	-- an `ft = "markdown"` spec only delays the first preview.
	lazy = false,

	dependencies = {
		"nvim-treesitter/nvim-treesitter", -- needs the markdown + markdown_inline parsers
		"nvim-tree/nvim-web-devicons",     -- language icons on fenced code blocks
	},

	-- A function, not a table, so the preset can be required at load time.
	opts = function()
		return {
			preview = {
				-- Use the devicons already in the plugin list, not the bundled set.
				icon_provider = "devicons",

				-- `modes` is left at the default { "n", "no", "c" }: insert mode
				-- is absent, so raw markup comes back while you type.
				--
				-- hybrid_modes (render the buffer but leave the cursor's node or
				-- line raw) would be the nicer version of that, but it has a bug
				-- worth knowing about: with hybrid on, markview never renders
				-- line 1 of the buffer, no matter where the cursor is. Every
				-- journal entry opens with `# <date>` on line 1, so the day
				-- title would be the one heading that stayed raw. Verified
				-- against markview 5d9fc2a with all of { "n" }, { "n", "i" },
				-- and both linewise_hybrid_mode settings.
				hybrid_modes = {},
			},

			markdown = {
				-- The plugin ships this preset: heading icons become the
				-- heading's position in the outline (1, 1.1, 1.1.2), recomputed
				-- as sections move.
				headings = vim.tbl_deep_extend("force", require("markview.presets").headings.numbered, {
					-- One space of indent per level, on top of the number.
					shift_width = 1,

					-- Level is carried by the number and the indent, so drop
					-- color entirely. `hl` is applied as `line_hl_group` across
					-- the whole heading line, and markview's own
					-- MarkviewHeading{N} groups each carry a palette-tinted
					-- background -- that rainbow is the thing being replaced.
					-- Both of these are stock groups: Normal is bare body-text
					-- fg, @markup.strong is bold with no color of its own.
					heading_1 = { hl = "@markup.strong" },
					heading_2 = { hl = "Normal" },
					heading_3 = { hl = "Normal" },
					heading_4 = { hl = "Normal" },
					heading_5 = { hl = "Normal" },
					heading_6 = { hl = "Normal" },
				}),
			},
		}
	end,
}
