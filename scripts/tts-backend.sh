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

case "$1" in
  detect) detect_backend ;;
  list-voices) list_voices ;;
  validate-voice) validate_voice "$2" ;;
  *)
    echo "usage: $(basename "$0") {detect|list-voices|validate-voice <name>}" >&2
    exit 2
    ;;
esac
