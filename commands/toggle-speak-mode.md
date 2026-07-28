---
description: Toggle /speak's persisted default mode between mac (mechanical) and llm (LLM-summarized)
---

Run this exact command via Bash and report the result to the user in one short sentence:

```
mkdir -p ~/.claude/claude-speak; CUR=$(cat ~/.claude/claude-speak/mode 2>/dev/null); if [ "$CUR" = "llm" ]; then echo mac > ~/.claude/claude-speak/mode && echo "speak-mode: mac"; else echo llm > ~/.claude/claude-speak/mode && echo "speak-mode: llm"; fi
```

Do not do anything else — just run the command and relay whether speak-mode is now mac or llm. This only changes the default /speak uses when called with no argument; /speak mac or /speak llm still overrides per-call regardless of this setting.
