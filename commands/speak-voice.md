---
description: Get, set, list, or reset the TTS voice used by all speech output (macOS `say` or Linux espeak-ng)
argument-hint: [voice-name|list|reset]
---

Based on the argument passed to this command, do exactly one of the following via Bash, then report the result in one short sentence — nothing else besides that (for `list`, show the list itself, not a one-line summary):

- **No argument**: report the current voice. Run `cat ~/.claude/claude-speak/voice 2>/dev/null`; if empty/missing, the voice is "system default".
- **`list`**: run `"${CLAUDE_PLUGIN_ROOT}/scripts/tts-backend.sh" list-voices` and show the result — these are the installed English voices available to pick from on this machine's backend (macOS `say` or Linux espeak-ng).
- **`reset`**: clear back to the system default voice: `rm -f ~/.claude/claude-speak/voice`.
- **Any other value**: treat it as a voice name. First verify it exists: `"${CLAUDE_PLUGIN_ROOT}/scripts/tts-backend.sh" validate-voice "<name>"`. If that fails, tell the user the voice name wasn't recognized and suggest running `/speak-voice list`. If it succeeds, write it: `mkdir -p ~/.claude/claude-speak && echo "<name>" > ~/.claude/claude-speak/voice`.

This voice applies everywhere speech is used: the automatic `/toggle-speak` Stop hook, `/speak` (local mode), and `/speak llm`. Voice names are backend-specific (macOS uses names like `Daniel`/`Samantha`, espeak-ng uses codes like `en-us`/`en-gb`) — a voice set on one machine's backend won't mean anything on another.
