#!/bin/bash
# Runs the speak-pv helper (speak-pv.swift), compiling it on first use or when
# the source changed. The binary lives in ~/.claude/claude-speak/bin so the
# plugin cache stays source-only. Passes all arguments and stdin through.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.claude/claude-speak/bin"
BIN="$BIN_DIR/speak-pv"

if [ ! -x "$BIN" ] || [ "$DIR/speak-pv.swift" -nt "$BIN" ]; then
  command -v swiftc >/dev/null 2>&1 || { echo "claude-speak: swiftc is needed to build speak-pv (install Xcode command line tools)" >&2; exit 1; }
  mkdir -p "$BIN_DIR"
  swiftc -O "$DIR/speak-pv.swift" -o "$BIN" >&2 || exit 1
fi

exec "$BIN" "$@"
