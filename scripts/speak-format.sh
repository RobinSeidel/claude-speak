#!/bin/bash
# Reads raw text on stdin, strips markdown noise, truncates at the last
# sentence boundary within a length cap, and speaks it via macOS `say`.
# Shared by toggle-speak-stop.sh (Stop hook) and speak-last-response.sh (/speak).
# No LLM involved — purely mechanical, so long text is truncated, not summarized.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

text="$(cat)"
[ -n "$text" ] || exit 0

text=$(printf '%s' "$text" | perl -0777 -pe '
  s/```.*?```//gs;                 # fenced code blocks
  # inline code: split snake_case/kebab-case/=//-joined tokens and camelCase
  # into separate words so `say` reads them as chunks instead of one mangled
  # blob (e.g. `LC_ALL=C` -> "LC ALL C", `grep -bo` -> "grep bo")
  s/`([^`]*)`/ my $c = $1; $c =~ s{[_\-\/=]+}{ }g; $c =~ s{(?<=[a-z0-9])(?=[A-Z])}{ }g; $c =~ s{\s+}{ }g; $c =~ s{^\s+|\s+$}{}g; $c /ge;
  s/\[([^\]]*)\]\([^)]*\)/$1/g;    # [text](url) -> text
  s/^\s*#{1,6}\s*//gm;             # headers
  s/^\s*[-*+]\s+/ /gm;             # bullet markers
  s/^\s*\d+\.\s+/ /gm;             # numbered list markers
  s/^\s*>\s?//gm;                  # blockquote/callout markers
  s/\*\*([^*]+)\*\*/$1/g;          # bold
  s/\*([^*]+)\*/$1/g;              # italics
  s/(?<!\w)_{1,2}([^_\s](?:[^_\n]*[^_\s])?)_{1,2}(?!\w)/$1/g;  # underscore emphasis (not snake_case)
  s/\n+/ /g;                       # collapse all newlines (cut -c below is per-line otherwise)
  # Several substitutions above (bullet/numbered-list markers) replace a
  # marker with a leading space; once newlines are also collapsed to spaces
  # that leaves a double space at every list item, which `say` reads as an
  # audible extra pause. Collapse any run of whitespace to one space, and
  # trim the ends.
  s/[ \t]+/ /g;
  s/^\s+|\s+$//g;
')

# Cap length, preferring to end at the last sentence boundary within the cap.
# Byte-consistent (LC_ALL=C) throughout: grep -bo reports byte offsets, and
# under a UTF-8 locale `cut -c` counts characters, not bytes — with multi-byte
# characters (em dashes, etc.) before the cutoff those two disagree, so the
# truncation would run past the sentence boundary and dangle a fragment after it.
LIMIT=2000
LIMIT_FILE="$HOME/.claude/claude-speak/limit"
if [ -s "$LIMIT_FILE" ]; then
  file_limit=$(cat "$LIMIT_FILE")
  case "$file_limit" in
    ''|*[!0-9]*) ;;              # not a valid positive integer, keep default
    *) LIMIT="$file_limit" ;;
  esac
fi

byte_len=$(printf '%s' "$text" | LC_ALL=C wc -c | tr -d ' ')
if [ "$byte_len" -gt "$LIMIT" ]; then
  head=$(printf '%s' "$text" | LC_ALL=C cut -c1-"$LIMIT")
  cut_at=$(printf '%s' "$head" | LC_ALL=C grep -boE '[.!?]' | tail -1 | cut -d: -f1)
  if [ -n "$cut_at" ]; then
    text=$(printf '%s' "$head" | LC_ALL=C cut -c1-$((cut_at + 1)))
  else
    text="$head"
  fi
fi

printf '%s' "$text" | "$DIR/speak-say.sh"
