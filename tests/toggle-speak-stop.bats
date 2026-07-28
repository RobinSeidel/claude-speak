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

@test "stays silent when the toggle-speak flag is off" {
  echo '{"last_assistant_message":"should not speak"}' | "$SCRIPTS_DIR/toggle-speak-stop.sh"
  sleep 0.3
  [ ! -s "$SPOKEN_LOG" ]
}

@test "speaks last_assistant_message when the flag is on" {
  touch "$HOME/.claude/claude-speak/enabled"
  echo '{"last_assistant_message":"hello from the hook"}' | "$SCRIPTS_DIR/toggle-speak-stop.sh"
  text="$(spoken_text)"
  [[ "$text" == *"hello from the hook"* ]]
}

@test "stays silent when the flag is on but the message is empty" {
  touch "$HOME/.claude/claude-speak/enabled"
  echo '{"last_assistant_message":""}' | "$SCRIPTS_DIR/toggle-speak-stop.sh"
  sleep 0.3
  [ ! -s "$SPOKEN_LOG" ]
}

@test "stays silent on malformed JSON input rather than erroring" {
  touch "$HOME/.claude/claude-speak/enabled"
  run bash -c "echo 'not json at all' | \"$SCRIPTS_DIR/toggle-speak-stop.sh\""
  [ "$status" -eq 0 ]
  sleep 0.3
  [ ! -s "$SPOKEN_LOG" ]
}

@test "applies markdown stripping through to the spoken output" {
  touch "$HOME/.claude/claude-speak/enabled"
  echo '{"last_assistant_message":"Fixed by forcing `LC_ALL=C`, keep last_assistant_message intact."}' | "$SCRIPTS_DIR/toggle-speak-stop.sh"
  text="$(spoken_text)"
  [[ "$text" == *"LC ALL C"* ]]
  [[ "$text" == *"last_assistant_message"* ]]
  [[ "$text" != *'`'* ]]
}
