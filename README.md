# claude-speak

[![Tests](https://github.com/JosephScript/claude-speak/actions/workflows/test.yml/badge.svg)](https://github.com/JosephScript/claude-speak/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Give Claude Code a voice. Hear responses read aloud on demand, or automatically after every turn — no API keys, no external services, just your OS's built-in speech engine.

Works on **macOS** (`say`) and **Linux** (`espeak-ng`, or the older `espeak`). Windows isn't supported yet — see [Platform support](#platform-support).

## Why

- **Step away from the screen.** Kick off a long task, hear it announce completion or ask a question from across the room instead of babysitting the terminal.
- **Accessibility.** If reading dense terminal output is slow, tiring, or difficult — low vision, reading fatigue, or just preference — hearing it read aloud is a genuine alternative, not a bolt-on afterthought. See [Accessibility](#accessibility) for what this does and doesn't cover.
- **Pairs with Claude Code's own voice input.** Claude Code already has built-in dictation (hold-to-talk / tap-to-toggle, speech-to-text only — no output). Turn on `/toggle-speak` alongside it and you get a genuine two-way voice loop: speak your prompt in, hear the response out. See [Pairing with voice input](#pairing-with-voice-input).

## Quick start

```
/toggle-speak         # turn on automatic speaking after every response
/speak-rate normal     # (optional) set a comfortable pace
/speak-voice list      # (optional) see what voices are installed
/speak-voice <name>    # (optional) pick one
```

Or skip the automatic hook entirely and just read things back one at a time with `/speak`.

## Commands

| Command | Arguments | Default | What it does |
|---|---|---|---|
| `/speak` | `local` \| `llm` | `local` | Reads your immediately preceding response aloud, once. |
| `/toggle-speak-mode` | — | — | Flips `/speak`'s default mode (used when you call `/speak` with no argument) between `local` and `llm`. |
| `/toggle-speak` | — | off | Turns automatic speaking of every response on/off, via a Stop hook. Always `local` mode — a hook can't cheaply call an LLM without adding latency to every turn. |
| `/speak-rate` | `<wpm>` \| `slow` \| `normal` \| `fast` \| `reset` | engine default (~175–200 wpm) | Words-per-minute. No argument reports the current value. Same units on both backends. |
| `/speak-voice` | `<name>` \| `auto` \| `list` \| `reset` | `auto` (voice follows the text's language) | Voice used for speech. No argument reports the current value; `list` shows what's installed. |
| `/speak-limit` | `<bytes>` \| `reset` | `2000` | Truncation cap for the mechanical path (`/toggle-speak` and `/speak` local mode). No effect on `/speak llm`. |

`/speak`'s two modes:

| Mode | Speed | How | Best for |
|---|---|---|---|
| `local` (default) | Instant | Reads the transcript directly, strips markdown, truncates at a sentence boundary if long. No LLM involved. | Everyday use, short-to-medium responses. |
| `llm` | Costs a turn | Claude writes a concise spoken-friendly summary instead of reading verbatim. | Long or code-heavy responses that would otherwise get cut off or read awkwardly. |

## Automatic language detection

Without an explicit voice (or with `/speak-voice auto`), `scripts/detect-lang.sh` guesses the language of the text (en, de, fr, es, it, pt, nl; stopword-based, no dependencies) and picks a matching installed voice. Pin a voice per language by writing its name to `~/.claude/claude-speak/voice.<code>`, e.g. `voice.de`. Mixed-language or very short text falls back to English.

## Accessibility

This is a practical audio-feedback layer, not a certified assistive technology (AT) and not a screen reader replacement — it doesn't integrate with VoiceOver, Orca, NVDA, or any system accessibility API. What it *does* give you:

- Full responses read aloud without needing to visually track terminal output.
- Adjustable rate and voice (`/speak-rate`, `/speak-voice`) to match your own comfortable listening pace.
- An always-on mode (`/toggle-speak`) so you never have to remember to ask for it.

If you rely on real assistive technology day-to-day, this sits alongside it as an extra channel, not a substitute.

## Pairing with voice input

Claude Code has its own built-in voice mode — hold-to-talk or tap-to-toggle dictation — but it's speech-to-text only; it has no way to talk back. `claude-speak` is the other half. Enable both and you get a genuinely hands-free loop: speak your prompt in, hear the response out, no keyboard or screen required for either direction.

Claude Code's dictation is controlled by its own `voice`/`voiceEnabled` settings (see `/config` or your `settings.json`) — that's independent of this plugin. Turn that on for input, `/toggle-speak` on for output, and you've got the full loop.

## Platform support

| Platform | Backend | Status |
|---|---|---|
| macOS | `say` | Fully supported |
| Linux (Arch, Debian, Ubuntu, etc.) | `espeak-ng` (falls back to `espeak`) | Fully supported — tested against real `espeak-ng` output in Docker (Arch's official image has no arm64 build; verified on Debian instead, which shares the same upstream `espeak-ng` binary and GNU coreutils) |
| Windows | — | Not yet. Claude Code hooks run via PowerShell on Windows rather than bash, and Windows' TTS API (SAPI) uses a different rate scale — this would need a parallel implementation, not a patch to the existing scripts. |

Requirements: `jq`, `perl`, `bash`, and the platform's TTS backend (`say` is preinstalled on macOS; install espeak-ng with `pacman -S espeak-ng` on Arch or `apt install espeak-ng` on Debian/Ubuntu).

## How it works

- `/speak` (local mode) and the `/toggle-speak` Stop hook share one formatter (`scripts/speak-format.sh`): strip markdown noise, split code identifiers (`LC_ALL=C` → "LC ALL C", `toggleSpeakEnabled` → "toggle Speak Enabled") so the speech engine doesn't mangle them, and truncate at the last sentence boundary within the configured byte limit.
- The Stop hook reads `last_assistant_message` directly from the hook's stdin JSON rather than the transcript file, since the transcript is written asynchronously and can lag. `/speak` has no such shortcut (it's a fresh command, not a hook), so it reads the transcript and waits for the file to go quiet before extracting text. Finding "the current transcript" and reading file size/mtime uses a small GNU/BSD `stat` compatibility shim (`scripts/speak-last-response.sh`), since those flags differ between Linux and macOS.
- `scripts/tts-backend.sh` detects which speech engine is available (`say` on macOS, `espeak-ng`/`espeak` on Linux) and exposes backend-agnostic voice listing/validation. `scripts/speak-say.sh` is the single point that actually invokes it — applying rate/voice and launching it fully detached (own process group, not just a plain background job) so a hook's turn ending doesn't cut speech off mid-sentence.

## Testing

A [bats-core](https://github.com/bats-core/bats-core) suite in `tests/` covers the markdown/whitespace/truncation formatting logic, backend detection and dispatch, transcript extraction, and the Stop hook's flag-gating — all against fake `say`/`espeak-ng` stubs (or, for a couple of backend-detection tests, whatever real engine is actually installed), so no audio ever plays during a test run. Runs on every push/PR via GitHub Actions across `macos-latest` and `ubuntu-latest`.

```bash
brew install bats-core   # or: apt install bats
chmod +x scripts/*.sh
bats tests/
```

## Configuration

All settings persist as plain files in `~/.claude/claude-speak/` — nothing to edit by hand, use the commands above. All optional; missing means default.

| File | Set by | Holds | Missing means |
|---|---|---|---|
| `enabled` | `/toggle-speak` | presence = on | Automatic speaking off |
| `mode` | `/toggle-speak-mode` | `local` or `llm` | `/speak` defaults to `local` |
| `rate` | `/speak-rate` | words per minute | Engine's own default rate |
| `voice` | `/speak-voice` | backend-specific voice name/code | Engine's own default voice |
| `limit` | `/speak-limit` | byte count | `2000` |

## Install

**From this repo on GitHub**, once published — add to `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "claude-speak": {
      "source": { "source": "github", "repo": "JosephScript/claude-speak" }
    }
  },
  "enabledPlugins": {
    "claude-speak@claude-speak": true
  }
}
```

**From a local clone/checkout** (development, or before this is published anywhere):

```json
{
  "extraKnownMarketplaces": {
    "claude-speak": {
      "source": { "source": "directory", "path": "/absolute/path/to/claude-speak" }
    }
  },
  "enabledPlugins": {
    "claude-speak@claude-speak": true
  }
}
```

Either way, the settings.json entries above make the plugin *functional* immediately (commands and hooks load), but `/plugin list` only shows plugins that have gone through a formal install step. Run this once to fully register it:

```bash
claude plugin install claude-speak@claude-speak
```

## Before publishing

- Tag a release matching the `version` in both manifests (currently `1.1.0`) if you want others to pin to it.

## Author

[JosephScript](https://github.com/JosephScript) — hi@josephscript.com

Issues and PRs welcome.

## Personal Voice

`say` cannot use macOS Personal Voices. Set the voice to `personal:<name>` (e.g. `echo 'personal:Ben' > ~/.claude/claude-speak/voice.en`) and `scripts/speak-pv.sh` speaks with it via `AVSpeechSynthesizer`. It compiles `scripts/speak-pv.swift` into `~/.claude/claude-speak/bin/` on first use (needs `swiftc`), and Personal Voice access must be allowed for apps in System Settings → Accessibility → Personal Voice.

## Siri voices

`say -v` cannot select Siri voices, but `say` without `-v` uses the system voice, which can be a Siri voice (System Settings → Accessibility → Spoken Content → System Voice). Set a per-language voice to `system` to use it, e.g. `echo system > ~/.claude/claude-speak/voice.de`.
