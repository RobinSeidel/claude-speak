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

@test "strips fenced code blocks entirely" {
  printf 'before\n```\ncode here\n```\nafter' | "$SCRIPTS_DIR/speak-format.sh"
  text="$(spoken_text)"
  [[ "$text" == *"before"* ]]
  [[ "$text" == *"after"* ]]
  [[ "$text" != *"code here"* ]]
}

@test "splits inline code identifiers into pronounceable words" {
  printf 'Fixed by forcing `LC_ALL=C` and checking `grep -bo` and `toggleSpeakEnabled`.' | "$SCRIPTS_DIR/speak-format.sh"
  text="$(spoken_text)"
  [[ "$text" == *"LC ALL C"* ]]
  [[ "$text" == *"grep bo"* ]]
  [[ "$text" == *"toggle Speak Enabled"* ]]
}

@test "preserves snake_case identifiers outside backticks" {
  printf 'The last_assistant_message field stays intact, as does toggle_speak_enabled.' | "$SCRIPTS_DIR/speak-format.sh"
  text="$(spoken_text)"
  [[ "$text" == *"last_assistant_message"* ]]
  [[ "$text" == *"toggle_speak_enabled"* ]]
}

@test "strips real underscore emphasis but leaves snake_case alone" {
  printf 'This is _truly_ emphasized and __really__ so, but last_assistant_message is not.' | "$SCRIPTS_DIR/speak-format.sh"
  text="$(spoken_text)"
  [[ "$text" == *"truly emphasized"* ]]
  [[ "$text" == *"really so"* ]]
  [[ "$text" == *"last_assistant_message"* ]]
  [[ "$text" != *"_truly_"* ]]
  [[ "$text" != *"__really__"* ]]
}

@test "strips bold and italic markers" {
  printf 'This is **bold** and this is *italic*.' | "$SCRIPTS_DIR/speak-format.sh"
  text="$(spoken_text)"
  [[ "$text" == *"This is bold and this is italic."* ]]
}

@test "strips headers and blockquote markers" {
  printf '## Title\n\n> a quote\nnormal text' | "$SCRIPTS_DIR/speak-format.sh"
  text="$(spoken_text)"
  [[ "$text" == *"Title"* ]]
  [[ "$text" == *"a quote"* ]]
  [[ "$text" == *"normal text"* ]]
  [[ "$text" != *"#"* ]]
  [[ "$text" != *">"* ]]
}

@test "converts markdown links to their link text" {
  printf 'See [the docs](https://example.com/docs) for details.' | "$SCRIPTS_DIR/speak-format.sh"
  text="$(spoken_text)"
  [[ "$text" == *"See the docs for details."* ]]
  [[ "$text" != *"https://"* ]]
}

@test "collapses bullet-marker whitespace so no double spaces remain" {
  printf 'Changed:\n\n- one\n- two\n- three\n\nDone.' | "$SCRIPTS_DIR/speak-format.sh"
  text="$(spoken_text)"
  [[ "$text" != *"  "* ]]
}

@test "collapses numbered-list whitespace so no double spaces remain" {
  printf '1. first\n2. second\n3. third\n' | "$SCRIPTS_DIR/speak-format.sh"
  text="$(spoken_text)"
  [[ "$text" != *"  "* ]]
}

@test "passes short text through untouched" {
  printf 'Short response, no truncation needed.' | "$SCRIPTS_DIR/speak-format.sh"
  text="$(spoken_text)"
  [ "$text" = "Short response, no truncation needed." ]
}

@test "truncates at a real sentence boundary, byte-consistent with em dashes" {
  echo 120 > "$HOME/.claude/claude-speak/limit"
  long="First sentence — with an em dash — ends here. Second sentence — also with a dash — pads this out well past one hundred and twenty bytes for certain. Third should never appear."
  printf '%s' "$long" | "$SCRIPTS_DIR/speak-format.sh"
  text="$(spoken_text)"
  [[ "$text" != *"Third"* ]]
  last="${text%$'\n'}"
  last="${last: -1}"
  [[ "$last" == "." || "$last" == "!" || "$last" == "?" ]]
}

@test "respects a custom /speak-limit value" {
  echo 40 > "$HOME/.claude/claude-speak/limit"
  printf 'One sentence here. Two sentence here. Three sentence here.' | "$SCRIPTS_DIR/speak-format.sh"
  text="$(spoken_text)"
  # 40 bytes plus the trailing newline our fake binary appends
  [ "${#text}" -le 41 ]
}

@test "falls back to the default limit on a non-numeric /speak-limit value" {
  echo "not-a-number" > "$HOME/.claude/claude-speak/limit"
  long=""
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
    long="${long}Sentence padding this out. "
  done
  printf '%s' "$long" | "$SCRIPTS_DIR/speak-format.sh"
  text="$(spoken_text)"
  # default limit is 2000; this input is well under it, so nothing should truncate
  [ "${#text}" -gt 700 ]
}
