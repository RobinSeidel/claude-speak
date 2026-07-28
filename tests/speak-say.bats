#!/usr/bin/env bats

load 'test_helper'

setup() {
  setup_isolated_home
  setup_fake_backend
}

teardown() {
  teardown_isolated_home
  teardown_fake_backend
}

@test "speaks plain text with no rate or voice set" {
  printf 'hello there' | "$SCRIPTS_DIR/speak-say.sh"
  text="$(spoken_text)"
  [ "$text" = "hello there" ]
}

@test "applies a persisted rate with the correct per-backend flag" {
  echo 220 > "$HOME/.claude/claude-speak/rate"
  printf 'hello rate' | "$SCRIPTS_DIR/speak-say.sh"
  text="$(spoken_text)"
  flag="$(rate_flag)"
  [[ "$text" == "$flag 220 hello rate" ]]
}

@test "applies a persisted voice" {
  echo test-voice > "$HOME/.claude/claude-speak/voice"
  printf 'hello voice' | "$SCRIPTS_DIR/speak-say.sh"
  text="$(spoken_text)"
  [[ "$text" == *"-v test-voice hello voice"* ]]
}

@test "applies both rate and voice together" {
  echo 180 > "$HOME/.claude/claude-speak/rate"
  echo test-voice > "$HOME/.claude/claude-speak/voice"
  printf 'hello both' | "$SCRIPTS_DIR/speak-say.sh"
  text="$(spoken_text)"
  flag="$(rate_flag)"
  [[ "$text" == "$flag 180 -v test-voice hello both" ]]
}

@test "returns before the backend process has actually finished" {
  # The fake backend sleeps to simulate a slow utterance. speak-say.sh should
  # return before that sleep completes, because it detaches the process
  # (own process group + disown) instead of waiting on it inline. A file-
  # existence check avoids the flakiness of second-granularity wall-clock
  # timing.
  cat > "$FAKE_BIN/say" <<EOF
#!/bin/bash
sleep 2
touch "$SPOKEN_LOG.done"
EOF
  cat > "$FAKE_BIN/espeak-ng" <<EOF
#!/bin/bash
sleep 2
touch "$SPOKEN_LOG.done"
EOF
  chmod +x "$FAKE_BIN/say" "$FAKE_BIN/espeak-ng"

  printf 'slow utterance' | "$SCRIPTS_DIR/speak-say.sh"
  [ ! -f "$SPOKEN_LOG.done" ]

  # cleanup: don't leave the 2s sleep dangling into the next test
  sleep 2.2
  rm -f "$SPOKEN_LOG.done"
}

@test "does nothing on empty input" {
  printf '' | "$SCRIPTS_DIR/speak-say.sh"
  sleep 0.3
  [ ! -s "$SPOKEN_LOG" ]
}
