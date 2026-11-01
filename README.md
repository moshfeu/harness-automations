# harness-automations

A Claude Code plugin for out-of-session watchers (macOS, launchd).

A launchd job runs a cheap shell check on an interval. It costs no tokens. When the check returns a "done" value, it runs one `claude -p` agent with a saved prompt, sends a desktop notification, and removes itself.

## Install

```
/plugin marketplace add moshfeu/harness-automations
/plugin install harness-automations@harness-automations
```

Then run `/harness-automations:watch <what to wait for and what to do>` or `/harness-automations:watch list`.

## Try it from a local clone

```
claude --plugin-dir /path/to/harness-automations
```

Edit a file, then run `/reload-plugins` in the session.

## Needs

`jq`, `claude` on your PATH, and whatever your check command uses (for example `gh`). For banners with an image, install `terminal-notifier` (`brew install terminal-notifier`); without it the notification is plain text through `osascript`.

Data lives in `~/.claude/watchers/<name>/` (set `WATCH_HOME` to change it).
