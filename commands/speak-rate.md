---
description: Get or set the speech rate (words per minute) used by all `say`-based speech output
argument-hint: [wpm|slow|normal|fast|reset]
---

Based on the argument passed to this command, do exactly one of the following via Bash, then report the result in one short sentence — nothing else:

- **No argument**: report the current rate. Run `cat ~/.claude/claude-speak/rate 2>/dev/null`; if empty/missing, the rate is "system default".
- **A plain number** (e.g. `220`): set that exact words-per-minute value: `mkdir -p ~/.claude/claude-speak && echo <number> > ~/.claude/claude-speak/rate`.
- **`slow`**: `mkdir -p ~/.claude/claude-speak && echo 140 > ~/.claude/claude-speak/rate`
- **`normal`**: `mkdir -p ~/.claude/claude-speak && echo 180 > ~/.claude/claude-speak/rate`
- **`fast`**: `mkdir -p ~/.claude/claude-speak && echo 250 > ~/.claude/claude-speak/rate`
- **`reset`**: clear back to the system default: `rm -f ~/.claude/claude-speak/rate`
- **Anything else**: don't write anything — tell the user the argument wasn't understood and list the accepted forms above.

This rate applies everywhere speech is used: the automatic `/toggle-speak` Stop hook, `/speak` (local mode), and `/speak llm`.
