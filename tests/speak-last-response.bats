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

write_transcript() {
  # write_transcript <path> <jsonl-content>
  mkdir -p "$(dirname "$1")"
  printf '%s' "$2" > "$1"
}

@test "does nothing when no transcript exists at all" {
  "$SCRIPTS_DIR/speak-last-response.sh"
  sleep 0.3
  [ ! -s "$SPOKEN_LOG" ]
}

@test "speaks the last assistant text entry from the transcript" {
  write_transcript "$HOME/.claude/projects/-test/session.jsonl" \
'{"type":"user","message":{"content":"hi"}}
{"type":"assistant","isSidechain":false,"message":{"content":[{"type":"text","text":"first reply"}]}}
{"type":"assistant","isSidechain":false,"message":{"content":[{"type":"text","text":"second and final reply"}]}}
'
  "$SCRIPTS_DIR/speak-last-response.sh"
  text="$(spoken_text)"
  [[ "$text" == *"second and final reply"* ]]
  [[ "$text" != *"first reply"* ]]
}

@test "skips a trailing tool-call-only entry with no text" {
  write_transcript "$HOME/.claude/projects/-test/session.jsonl" \
'{"type":"assistant","isSidechain":false,"message":{"content":[{"type":"text","text":"the real reply"}]}}
{"type":"assistant","isSidechain":false,"message":{"content":[{"type":"tool_use","name":"Bash"}]}}
'
  "$SCRIPTS_DIR/speak-last-response.sh"
  text="$(spoken_text)"
  [[ "$text" == *"the real reply"* ]]
}

@test "ignores sidechain (subagent) assistant entries" {
  write_transcript "$HOME/.claude/projects/-test/session.jsonl" \
'{"type":"assistant","isSidechain":false,"message":{"content":[{"type":"text","text":"main thread reply"}]}}
{"type":"assistant","isSidechain":true,"message":{"content":[{"type":"text","text":"subagent chatter"}]}}
'
  "$SCRIPTS_DIR/speak-last-response.sh"
  text="$(spoken_text)"
  [[ "$text" == *"main thread reply"* ]]
  [[ "$text" != *"subagent chatter"* ]]
}

@test "picks the most recently modified transcript across multiple projects" {
  write_transcript "$HOME/.claude/projects/-older/session.jsonl" \
'{"type":"assistant","isSidechain":false,"message":{"content":[{"type":"text","text":"older project reply"}]}}
'
  sleep 1.1
  write_transcript "$HOME/.claude/projects/-newer/session.jsonl" \
'{"type":"assistant","isSidechain":false,"message":{"content":[{"type":"text","text":"newer project reply"}]}}
'
  "$SCRIPTS_DIR/speak-last-response.sh"
  text="$(spoken_text)"
  [[ "$text" == *"newer project reply"* ]]
  [[ "$text" != *"older project reply"* ]]
}

@test "joins multiple text blocks within one assistant message" {
  write_transcript "$HOME/.claude/projects/-test/session.jsonl" \
'{"type":"assistant","isSidechain":false,"message":{"content":[{"type":"text","text":"part one."},{"type":"text","text":"part two."}]}}
'
  "$SCRIPTS_DIR/speak-last-response.sh"
  text="$(spoken_text)"
  [[ "$text" == *"part one."* ]]
  [[ "$text" == *"part two."* ]]
}
