# Table of all watchers: name, state, last check, result, link
WATCH_HOME="${WATCH_HOME:-$HOME/.claude/watchers}"
printf '%-22s %-9s %-19s %-28s %s\n' NAME STATE "LAST CHECK" RESULT LINK
for D in "$WATCH_HOME"/*/; do
  [ -f "$D/watch.json" ] || continue
  n=$(basename "$D")
  if launchctl list "com.watch.$n" >/dev/null 2>&1; then st=watching
  else st=$(cat "$D/state" 2>/dev/null || echo idle); fi
  last=$(grep ' check=' "$D/log" 2>/dev/null | tail -1)
  printf '%-22s %-9s %-19s %-28s %s\n' "$n" "$st" "${last:0:19}" "$(echo "${last#*check=}" | cut -c1-28)" "$(jq -r '.link // ""' "$D/watch.json")"
done
