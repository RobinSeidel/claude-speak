---
description: Get, set, or reset the max byte length spoken before truncating at a sentence boundary
argument-hint: [bytes|reset]
---

Based on the argument passed to this command, do exactly one of the following via Bash, then report the result in one short sentence — nothing else:

- **No argument**: report the current limit. Run `cat ~/.claude/claude-speak/limit 2>/dev/null`; if empty/missing, the limit is the default (2000 bytes).
- **A positive integer** (e.g. `1200`): set that as the new limit: `mkdir -p ~/.claude/claude-speak && echo <number> > ~/.claude/claude-speak/limit`.
- **`reset`**: clear back to the default: `rm -f ~/.claude/claude-speak/limit`.
- **Anything else**: don't write anything — tell the user the argument wasn't understood (must be a positive integer or `reset`).

This limit applies everywhere the mechanical formatter runs: the automatic `/toggle-speak` Stop hook and `/speak` (local mode). It has no effect on `/speak llm`, whose length is controlled by the model's own summarization instead of this cap.
