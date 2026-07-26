# worklog — append every command to ~/.local/share/worklog/shell-YYYY-MM-DD.jsonl
# Part of the workflow-tracking system; see setup-wiki/worklog.md in ~/knowledge.
# Logs: timestamp, zellij session/pane, cwd, command, duration, exit code.
# NOTE: logs raw command text (including anything pasted inline). Local only.

zmodload zsh/datetime
autoload -Uz add-zsh-hook

WORKLOG_DIR="${WORKLOG_DIR:-$HOME/.local/share/worklog}"

_worklog_preexec() {
  _worklog_cmd=$1
  _worklog_start=$EPOCHREALTIME
}

_worklog_precmd() {
  local exit_code=$?
  [[ -z $_worklog_cmd ]] && return
  local cmd=$_worklog_cmd
  unset _worklog_cmd
  (( ${+commands[jq]} )) || return
  local dur
  printf -v dur '%.2f' $(( EPOCHREALTIME - _worklog_start ))
  mkdir -p "$WORKLOG_DIR"
  jq -cn \
    --arg ts "$(strftime '%Y-%m-%dT%H:%M:%S' $EPOCHSECONDS)" \
    --arg session "${ZELLIJ_SESSION_NAME:-}" \
    --arg pane "${ZELLIJ_PANE_ID:-}" \
    --arg cwd "$PWD" \
    --arg cmd "$cmd" \
    --argjson dur "$dur" \
    --argjson exit "$exit_code" \
    '{ts:$ts, src:"zsh", session:$session, pane:$pane, cwd:$cwd, cmd:$cmd, dur_s:$dur, exit:$exit}' \
    >> "$WORKLOG_DIR/shell-$(strftime '%Y-%m-%d' $EPOCHSECONDS).jsonl" 2>/dev/null
}

add-zsh-hook preexec _worklog_preexec
add-zsh-hook precmd _worklog_precmd
