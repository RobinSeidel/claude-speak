#!/bin/bash
# Stop hook: speaks the assistant's last message via macOS `say`, gated by
# the ~/.claude/claude-speak/enabled flag file (see /toggle-speak command).
# Reads Stop hook input JSON on stdin and uses last_assistant_message directly
# rather than the transcript file, since the transcript is written async and can lag.
# Formatting/truncation is shared with /speak via speak-format.sh.

FLAG="$HOME/.claude/claude-speak/enabled"
[ -f "$FLAG" ] || exit 0

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

input="$(cat)"
text=$(printf '%s' "$input" | jq -r '.last_assistant_message // empty')
[ -n "$text" ] || exit 0

printf '%s' "$text" | "$DIR/speak-format.sh"
