#!/bin/bash
# Finds the most recently updated Claude Code session transcript and speaks
# the last main-thread (non-subagent) assistant message from it, verbatim,
# via speak-format.sh. Used by /speak. No LLM involved — purely mechanical.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# `stat` flags differ between GNU (Linux) and BSD (macOS) coreutils — try
# GNU syntax first, fall back to BSD. On the wrong platform the first form
# exits non-zero (unrecognized option), so `||` correctly falls through.
stat_mtime_and_name() {
  stat -c '%Y %n' "$1" 2>/dev/null || stat -f '%m %N' "$1" 2>/dev/null
}
stat_size() {
  stat -c '%s' "$1" 2>/dev/null || stat -f '%z' "$1" 2>/dev/null
}

transcript=""
best_mtime=-1
while IFS= read -r f; do
  line=$(stat_mtime_and_name "$f") || continue
  mtime=${line%% *}
  if [ "$mtime" -gt "$best_mtime" ] 2>/dev/null; then
    best_mtime="$mtime"
    transcript="$f"
  fi
done < <(find "$HOME/.claude/projects" -name '*.jsonl' 2>/dev/null)

[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

# The transcript is written asynchronously and can lag the in-memory
# conversation (same reason the Stop hook uses last_assistant_message
# instead of this file). Wait for the file to go quiet before reading it,
# so we don't catch the previous turn's line mid-flush.
prev_size=-1
stable=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  cur_size=$(stat_size "$transcript")
  if [ "$cur_size" = "$prev_size" ]; then
    stable=$((stable + 1))
    [ "$stable" -ge 2 ] && break
  else
    stable=0
  fi
  prev_size="$cur_size"
  sleep 0.15
done

text=$(jq -s -r '
  map(select(.type == "assistant" and ((.isSidechain // false) == false)))
  | map(select([.message.content[]? | select(.type == "text" and (.text // "") != "")] | length > 0))
  | last
  | .message.content
  | map(select(.type == "text") | .text)
  | join(" ")
' "$transcript" 2>/dev/null)

[ -n "$text" ] || exit 0

printf '%s' "$text" | "$DIR/speak-format.sh"
