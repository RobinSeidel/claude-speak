#!/bin/bash
# Stops speech started by speak-say.sh. Only kills the process recorded in the
# pid file, and only if it is still a TTS process, so a recycled pid or the
# user's own `say` is never touched.
PID_FILE="$HOME/.claude/claude-speak/pid"
[ -s "$PID_FILE" ] || exit 0
pid="$(cat "$PID_FILE")"
case "$(ps -p "$pid" -o comm= 2>/dev/null)" in
  *say|*speak-pv|*espeak|*espeak-ng) kill "$pid" 2>/dev/null ;;
esac
rm -f "$PID_FILE"
exit 0
