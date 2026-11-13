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

Claude Code (as a plugin):

```
/plugin marketplace add nijatsdev/dev-console-skill
/plugin install dev-console@dev-console-skill
```

On Claude Code 2.1.275 or later, one line does both:

```
/plugin install dev-console --marketplace nijatsdev/dev-console-skill
```

As a plain skill, for Claude Code or any agent that reads `~/.agents/skills`, copy the
`skills/dev-console` folder:

```bash
git clone https://github.com/nijatsdev/dev-console-skill /tmp/dev-console-skill
cp -R /tmp/dev-console-skill/skills/dev-console ~/.claude/skills/dev-console   # or ~/.agents/skills/
```

Then ask your agent something like "build a dev console for this app".

## What's inside

All in [skills/dev-console/](skills/dev-console):

| File | What it covers |
|---|---|
| [SKILL.md](skills/dev-console/SKILL.md) | when to build one and when an existing tool fits better, the build recipe, optional modules, common mistakes |
| [protocol.md](skills/dev-console/protocol.md) | the two-listener check-in and long-poll protocol, with a Python server sketch and a Swift client sketch |
| [build-and-install.md](skills/dev-console/build-and-install.md) | xcodebuild, devicectl, simctl, Gradle and adb commands, free-team signing, plain-language failure reasons |
| [backend-admin.md](skills/dev-console/backend-admin.md) | keeping the server key on the Mac, one-time sign-in tokens (Supabase, Firebase, your own API), test accounts only |
| [guardrails.md](skills/dev-console/guardrails.md) | loopback-only controls, Host and CSRF checks, a pairing secret, no debug code in release, and curl checks that prove it |
| [evals/](skills/dev-console/evals) | three test cases with small dummy projects and pass/fail checks |

It covers iOS in depth, with notes for Android, React Native/Expo and Flutter.

## Testing

The skill was tested with three realistic requests: an iOS multi-device installer, an iOS screen jumper with
screenshots, and an Android + Supabase test-user login. Each one was run by an agent with the skill and by
one without it, and the two results were graded blind against 9 to 11 checks each.

| Round | With the skill | Without it |
|---|---|---|
| 1 (first draft) | 96% | 86% |
| 2 (after fixes) | 100% | 79% |

Round 1 found two problems the skill itself caused, and both are fixed. First, `adb reverse` combined with
"trust localhost" let any app on the phone reach the admin routes. The skill now uses two listeners. Second,
the agent missed a launch crash in the app. The skill now has a step to read the app's launch path first.
These numbers come from one run per case, so read them as a direction, not a measurement. The test cases are
in `evals/`, and Claude Code can run them with `claude plugin eval`.

## License

[MIT](LICENSE)
