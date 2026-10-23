#!/bin/bash
# Detects the available TTS backend and exposes voice listing/validation in
# a backend-agnostic way. Shared by speak-say.sh (actual speech) and
# /speak-voice (listing/validating voice names). Rate (-r / -s) needs no
# translation between backends — both take words-per-minute directly — but
# voice *names* are backend-specific namespaces (macOS "Daniel" vs espeak's
# "en-us"), so a stored voice preference only makes sense on the backend it
# was set against.
#
# Supported backends:
#   macos  — macOS `say`
#   espeak — espeak-ng (or the older `espeak`) on Linux

espeak_bin() {
  command -v espeak-ng >/dev/null 2>&1 && { echo "espeak-ng"; return 0; }
  command -v espeak >/dev/null 2>&1 && { echo "espeak"; return 0; }
  return 1
}

detect_backend() {
  case "$(uname -s)" in
    Darwin)
      command -v say >/dev/null 2>&1 && { echo "macos"; return 0; }
      ;;
    Linux)
      espeak_bin >/dev/null 2>&1 && { echo "espeak"; return 0; }
      ;;
  esac
  echo "unsupported"
  return 1
}

list_voices() {
  backend="$(detect_backend)"
  case "$backend" in
    macos) say -v '?' | grep -E '^\S+\s+en' ;;
    espeak) "$(espeak_bin)" --voices=en | tail -n +2 ;;
    *)
      echo "claude-speak: no supported TTS backend found (need macOS \`say\` or Linux \`espeak-ng\`/\`espeak\`)" >&2
      return 1
      ;;
  esac
}

validate_voice() {
  name="$1"
  backend="$(detect_backend)"
  case "$backend" in
    macos) say -v '?' | awk '{print $1}' | grep -qx "$name" ;;
    espeak) "$(espeak_bin)" --voices=en | tail -n +2 | awk '{print $2}' | grep -qx "$name" ;;
    *) return 1 ;;
  esac
}

# Picks a voice for an ISO 639-1 language code. A per-language override in
# ~/.claude/claude-speak/voice.<code> wins; otherwise macOS uses the first
# installed voice whose locale starts with <code>_, espeak uses the code
# itself as the voice name. Prints nothing if no voice is found.
voice_for_lang() {
  code="$1"
  override="$HOME/.claude/claude-speak/voice.$code"
  [ -s "$override" ] && { cat "$override"; return 0; }
  case "$(detect_backend)" in
    macos)
      # Skip macOS novelty voices (Albert, Zarvox, ...) when auto-picking.
      # Voice names can contain spaces/parentheses ("Eddy (German (Germany))"),
      # so split name and locale with a regex instead of by field.
      say -v '?' | perl -ne '
        BEGIN { %skip = map { $_ => 1 } qw(Albert Bad Bahh Bells Boing Bubbles Cellos Good Jester Organ Superstar Trinoids Whisper Wobble Zarvox Fred Junior Kathy Ralph Princess Agnes); }
        if (/^(.+?)\s+'"$code"'_[A-Z]{2}\s+#/ && !$skip{(split " ", $1)[0]}) { print "$1\n"; exit }' ;;
    espeak) echo "$code" ;;
  esac
}

case "$1" in
  detect) detect_backend ;;
  voice-for-lang) voice_for_lang "$2" ;;
  list-voices) list_voices ;;
  validate-voice) validate_voice "$2" ;;
  *)
    echo "usage: $(basename "$0") {detect|list-voices|validate-voice <name>|voice-for-lang <code>}" >&2
    exit 2
    ;;
esac
