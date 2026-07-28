#!/usr/bin/env bash
# Shared bats test helpers for claude-speak.
#
# Provides an isolated $HOME (so tests never touch a real ~/.claude/claude-speak)
# and a fake TTS backend: both `say` and `espeak-ng` stubs log their invocation
# args to one file instead of actually speaking. Providing both means the same
# tests run correctly whichever OS the CI runner actually is — tts-backend.sh
# detects the real OS and picks one, and whichever it picks logs to the same
# place.

SCRIPTS_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../scripts" && pwd)"

setup_fake_backend() {
  FAKE_BIN="$(mktemp -d)"
  SPOKEN_LOG="$(mktemp)"

  cat > "$FAKE_BIN/say" <<EOF
#!/bin/bash
printf '%s\n' "\$*" >> "$SPOKEN_LOG"
EOF
  cat > "$FAKE_BIN/espeak-ng" <<EOF
#!/bin/bash
printf '%s\n' "\$*" >> "$SPOKEN_LOG"
EOF
  chmod +x "$FAKE_BIN/say" "$FAKE_BIN/espeak-ng"

  export PATH="$FAKE_BIN:$PATH"
}

teardown_fake_backend() {
  rm -rf "$FAKE_BIN" "$SPOKEN_LOG"
}

# speak-say.sh launches the backend fully detached, so give it a moment to
# land instead of assuming it's already written by the time we check.
spoken_text() {
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    [ -s "$SPOKEN_LOG" ] && break
    sleep 0.1
  done
  cat "$SPOKEN_LOG"
}

rate_flag() {
  case "$(uname -s)" in
    Darwin) echo "-r" ;;
    *) echo "-s" ;;
  esac
}

setup_isolated_home() {
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  mkdir -p "$HOME/.claude/claude-speak"
}

teardown_isolated_home() {
  rm -rf "$TEST_HOME"
}
