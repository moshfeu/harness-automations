---
name: watch
description: Create or list out-of-session watchers. A launchd job runs a cheap shell check on an interval (no agent, no tokens) and, when the check returns a "done" value, runs ONE `claude -p` agent with a saved prompt, sends a desktop notification, and removes itself. Use for "when PR X merges do Y", "tell me when the build is green and then do Z", "/watch list".
---

# Watch

macOS only (launchd). One folder per watcher: `~/.claude/watchers/<name>/` with `watch.json`, `prompt.md`, `log` and `state` (`done` or `stopped`, written at the end). The folder stays after the job removes itself, so it is the history.

Scripts are in `../../scripts/` relative to this skill's base directory (shown when the skill loads): `watch-add.sh <name>` (writes the plist, loads it) and `watch-list.sh` (table). Use the full path when you run them.

## `/watch list`

Run `bash <scripts>/watch-list.sh` and show the table. Nothing else.

## `/watch <what to wait for and what to do>`

1. Ask only what is missing: the cheap check, which output means done, which means stopped (optional), the interval (default 2h), the model for the final run (default `sonnet`; `opus` for hard work).
2. The check is one shell command that prints one short value and costs nothing, for example `gh pr view N --repo OWNER/REPO --json state -q .state`. It must work under launchd, which has a minimal environment. Run it once by hand first.
3. Write `watch.json`:
   ```json
   {"title":"short banner title","check":"<command>","done":["MERGED"],"stopped":["CLOSED"],
    "interval":7200,"model":"sonnet","link":"https://..."}
   ```
4. Write `prompt.md`: everything the agent needs, because it has no memory of this session. Give the context, the exact steps, what it must verify first, and that it must not send anything outward (chat, email, PR comments) or push without approval. The last line must be `RESULT: <one plain-English sentence>`. The runner uses that line as the notification text.
5. Show the plan and ask before loading it: `bash <scripts>/watch-add.sh <name>`. The job checks once at load, then every interval.
6. When the job ends it unloads itself and notifies.

## Notes

- A check output that is not in `done` or `stopped`, or an empty output (offline, VPN), means "try again next time".
- Notifications: the runner posts to a local relay if one listens on `$NOTIFY_URL` (default `http://127.0.0.1:4738/notify`), then tries `terminal-notifier`, then `osascript`.
