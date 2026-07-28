---
description: Read your immediately preceding response aloud via macOS `say` — mac mode (verbatim, mechanical) or llm mode (LLM-written spoken summary)
argument-hint: [mac|llm]
---

Determine which mode to use for this call:
1. If the argument passed to this command is exactly `llm` or exactly `mac`, use that mode for this call only.
2. Otherwise, read the persisted default: run `cat ~/.claude/claude-speak/mode 2>/dev/null` via Bash. If it outputs exactly `llm`, use llm mode. Otherwise (empty, missing file, or anything else), use mac mode. Toggle the persisted default with `/toggle-speak-mode`.

**Mac mode** (mechanical, the default): run this exact command via Bash and do nothing else besides a brief confirmation once it finishes:

```
"${CLAUDE_PLUGIN_ROOT}/scripts/speak-last-response.sh"
```

This script reads your last response straight from the session transcript, strips markdown, truncates at a sentence boundary if long, and speaks it verbatim. Do not read, paraphrase, or summarize the response yourself in this mode — just run the script.

**LLM mode**: take the plain-text content of your own response immediately preceding this command (not this instruction, not older turns) and speak it aloud by piping it into `"${CLAUDE_PLUGIN_ROOT}/scripts/speak-say.sh"` via Bash, e.g. `printf '%s' "<text>" | "${CLAUDE_PLUGIN_ROOT}/scripts/speak-say.sh"` (this applies the persisted rate/voice; don't call `say` directly here). If that response is longer than roughly 600 characters, don't read it verbatim — write a concise, spoken-friendly summary of it instead.

Don't narrate which mode you picked, or that you're doing this, beyond a brief confirmation once `say` (or the script) has finished.
