---
description: Toggle whether Claude speaks each response aloud automatically via the Stop hook
---

Run this exact command via Bash and report the result to the user in one short sentence:

```
mkdir -p ~/.claude/claude-speak; if [ -f ~/.claude/claude-speak/enabled ]; then rm ~/.claude/claude-speak/enabled && echo "toggle-speak: OFF"; else touch ~/.claude/claude-speak/enabled && echo "toggle-speak: ON"; fi
```

Do not do anything else — just run the command and relay whether it is now ON or OFF.
