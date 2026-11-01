# Loads a watcher into launchd: watch-add.sh <name>  (the folder must already exist)
set -euo pipefail
WATCH_HOME="${WATCH_HOME:-$HOME/.claude/watchers}"
name="$1"; D="$WATCH_HOME/$name"; label="com.watch.$name"
plist="$HOME/Library/LaunchAgents/$label.plist"
here="$(cd "$(dirname "$0")" && pwd)"
interval=$(jq -er .interval "$D/watch.json")   # seconds
for f in watch.json prompt.md; do [ -f "$D/$f" ] || { echo "missing $D/$f" >&2; exit 1; }; done
# launchd must not point into the plugin cache (it is replaced on update): keep our own copy.
bin="$WATCH_HOME/.bin"; mkdir -p "$bin" "$HOME/Library/LaunchAgents"
cp "$here/watch-run.sh" "$here/../assets/watcher-icon.png" "$bin/"
claude_bin=$(command -v claude || true)
cat > "$plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>$label</string>
<key>ProgramArguments</key><array><string>/bin/bash</string><string>$bin/watch-run.sh</string><string>$name</string></array>
<key>EnvironmentVariables</key><dict>
<key>PATH</key><string>$PATH:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
<key>WATCH_HOME</key><string>$WATCH_HOME</string>
<key>CLAUDE_BIN</key><string>${claude_bin:-claude}</string>
</dict>
<key>StartInterval</key><integer>$interval</integer>
<key>RunAtLoad</key><true/>
<key>StandardOutPath</key><string>$D/launchd.log</string>
<key>StandardErrorPath</key><string>$D/launchd.log</string>
</dict></plist>
PL
rm -f "$D/state"
launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$plist"
echo "watching $name every ${interval}s"
