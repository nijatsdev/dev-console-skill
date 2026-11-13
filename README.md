# dev-console

An agent skill that teaches an AI coding agent (Claude Code, Codex, or any agent that reads
[Agent Skills](https://agentskills.io)) to build a local **dev console** for a mobile app project. A dev
console is one small server and one web page on your Mac that:

- **build and install** the app on every picked phone and simulator at once, with build failures explained
  in plain words and a warning before a free Apple team's 7-day profile runs out
- **drive running debug builds** over the LAN: jump to any screen, flip state (offline, theme, time of day),
  switch test accounts and grab a screenshot. Each control goes to one picked app
- **run backend admin actions** (log in as a test user, review reports, see failed pushes) with a server key
  that stays in a git-ignored file on the Mac and never reaches the phone

It's a recipe and a protocol, not a framework. The agent generates a small standard-library server and a
debug-only client for your project. You don't install anything.

## Install

Claude Code:

```bash
git clone https://github.com/nijatsdev/dev-console-skill ~/.claude/skills/dev-console
```

Other agents that read `~/.agents/skills`:

```bash
git clone https://github.com/nijatsdev/dev-console-skill ~/.agents/skills/dev-console
```

Then ask your agent something like "build a dev console for this app".

## What's inside

| File | What it covers |
|---|---|
| [SKILL.md](SKILL.md) | when to build one and when an existing tool fits better, the build recipe, optional modules, common mistakes |
| [protocol.md](protocol.md) | the check-in and long-poll protocol, with a Python server sketch and a Swift client sketch |
| [build-and-install.md](build-and-install.md) | xcodebuild, devicectl, simctl, Gradle and adb commands, free-team signing, plain-language failure reasons |
| [backend-admin.md](backend-admin.md) | keeping the server key on the Mac, one-time sign-in tokens (Supabase, Firebase, your own API), test accounts only |
| [guardrails.md](guardrails.md) | localhost-only controls, Host and CSRF checks, a pairing secret, no debug code in release, and curl checks that prove it |

It covers iOS in depth, with notes for Android, React Native/Expo and Flutter.

## Status

This is a draft built from one production console for a SwiftUI + Supabase app. It hasn't yet been tested
by having agents build consoles for other projects. Issues and pull requests are welcome.

## License

[MIT](LICENSE)
