# Runs one check for a watcher. Called by launchd: watch-run.sh <name>
# Folder: $WATCH_HOME/<name>/{watch.json,prompt.md,log,state}
WATCH_HOME="${WATCH_HOME:-$HOME/.claude/watchers}"
name="$1"; D="$WATCH_HOME/$name"; LOG="$D/log"
ICON="$(cd "$(dirname "$0")" && pwd)/watcher-icon.png"
cfg() { jq -r "$1" "$D/watch.json"; }
log() { echo "$(date '+%F %T') $*" >> "$LOG"; }

notify() { # $1 = message. Tries the local relay, then terminal-notifier, then osascript.
  title=$(cfg .title); url=$(cfg '.link // ""')
  jq -nc --arg t "$title" --arg m "$1" --arg u "$url" --arg i "$ICON" \
    '{title:$t,message:$m,url:$u,image:$i,sound:"Glass"}' |
    curl -s -m 5 -f -X POST "${NOTIFY_URL:-http://127.0.0.1:4738/notify}" \
      -H 'Content-Type: application/json' -d @- >/dev/null 2>&1 && return
  if command -v terminal-notifier >/dev/null; then
    terminal-notifier -title "$title" -message "$1" -sound Glass -contentImage "$ICON" \
      ${url:+-open "$url"} >/dev/null 2>&1 && return
  fi
  osascript -e 'on run {m, t}' -e 'display notification m with title t' -e 'end run' "$1" "$title" \
    >/dev/null 2>&1 || log "notify failed"
}

finish() { # $1 = done|stopped, $2 = message
  echo "$1" > "$D/state"; log "$1: $2"; notify "$2"
  launchctl bootout "gui/$(id -u)/com.watch.$name" 2>/dev/null
}

[ -f "$D/watch.json" ] || exit 0
value=$(sh -c "$(cfg .check)" 2>>"$LOG")
log "check=${value:-<empty>}"
if jq -e --arg v "$value" '.done | index($v)' "$D/watch.json" >/dev/null; then
  out=$(cd "$D" && "${CLAUDE_BIN:-claude}" -p "$(cat "$D/prompt.md")" --model "$(cfg .model)" \
        --allowedTools "Read,Edit,Write,Grep,Glob,Bash" 2>&1)
  echo "$out" >> "$LOG"
  finish done "$(echo "$out" | grep '^RESULT:' | tail -1 | sed 's/^RESULT: *//' | grep . || echo "Agent finished with no RESULT line. See $LOG")"
elif jq -e --arg v "$value" '(.stopped // []) | index($v)' "$D/watch.json" >/dev/null; then
  finish stopped "Stopped: the check returned $value"
fi
# anything else (still waiting, or the check failed): try again next interval
