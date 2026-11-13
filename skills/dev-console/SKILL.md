---
name: dev-console
description: Use when a mobile app project (iOS/SwiftUI, Android, React Native/Expo, Flutter) needs a local web page on the developer's Mac to build and install on several phones and simulators at once, to drive running debug builds remotely (jump to a screen, flip state, switch test accounts, take a snapshot), or to run backend admin actions with a server key that must never reach the phone. Also use when installs keep failing with unclear Xcode or adb errors, when free Apple team profiles keep expiring after 7 days, or when debug switches are piling up in the app's own Settings.
---

# Dev console

## Overview

A dev console is one small local server plus one HTML page, generated per project, that sits beside the
app while you work on it. It does three jobs that no single existing tool covers together:

1. **Deploy:** build once per kind (phone, simulator) and install and open the app on every picked device in
   parallel, with failure reasons in plain words.
2. **Debug remote:** every debug build checks in to the page over the LAN and long-polls for commands. Each
   control on the page goes to **one picked app**.
3. **Admin:** backend actions that need a server key (log in as a test user, review reports, see failed
   pushes). The key stays in a git-ignored file on the Mac. The phone only ever gets one-time results.

**Core principle:** a recipe and a protocol, not a framework. Generate a few hundred lines of
standard-library server code and a thin client that fit this project. Don't install a platform.

## When not to build one

Check what the project already has first, and use those tools for their own job:

| Need | Use this instead of building it |
|---|---|
| CI builds, signing certificates, TestFlight / Play uploads | **fastlane** (`match`, `gym`, `pilot`, `supply`) |
| Expo / React Native dev menu, reload, inspector, OTA updates | **Expo dev tools**, dev client, EAS Update |
| Network inspection, request mocking | **Proxyman** (Mac proxy) or **Pulse** (in-app network logger with a Mac viewer) |
| Simulator recording, deep links, push payloads, network speed, design overlays | **RocketSim**, or `xcrun simctl openurl` / `simctl push` |
| Crashes, errors, release health | **Sentry** (or Crashlytics) |

Build a console only for the parts these leave out: installing on many devices at once from one click, live
commands into the project's own screens and state, and admin actions with a key kept on the Mac. A console
can link out to these tools, but it shouldn't copy them.

## Build recipe

Work through these in order. Each step ends in something you can check.

1. **Inventory the project.** Platform and build system (Xcode project or XcodeGen/Tuist, Gradle, Expo),
   build configurations, bundle IDs/application IDs (app and extensions), the backend and its admin API, and
   any debug switches the app already has (often buried in Settings). Don't guess at the backend.
2. **Read the app's launch path** (the `@main` app, `Application`/`MainActivity`, the root model) as if
   you were going to run it. A console is no use if the debug build crashes at launch, and a focused task
   makes that easy to miss. A common example is a model created as a property default that calls the
   backend SDK before the SDK is configured in `init`. Fix anything that would stop the app launching, and
   tell the user what you changed.
3. **Decide the scope from the request.** Build what the user asked for, plus the guardrails, which are
   never optional. Leave out the rest: if they asked for screen jumps, don't add a deploy tab or account
   switching. Name the other modules in one closing line as things you can add later.
4. **Create `tools/dev-console/`** in the project with `server.py` (Python standard library only:
   `http.server.ThreadingHTTPServer`, `threading.Condition`, `subprocess`, `urllib`) and `index.html` (no
   build step, no framework). One command starts it: `python3 tools/dev-console/server.py`, with ports from
   env vars. If the project uses `.claude/launch.json`, add an entry.
5. **Add the guards before any feature.** These are two listeners, a Host check, JSON-only POSTs, a pairing
   secret, and app-reported text shown as text, never as HTML. See [guardrails.md](guardrails.md). Get this
   right first, while the server is still small.
6. **Deploy tab, if asked for:** list devices, build once per kind, install and launch in parallel, stream
   the log, map failures to plain reasons, check signing and show a banner when a profile is about to run
   out. Commands and failure strings are in [build-and-install.md](build-and-install.md).
7. **Debug remote:** the poll endpoint and the in-app client, both from [protocol.md](protocol.md). Compile
   the client out of release builds (`#if DEBUG` around the whole file, Android `src/debug/`, `__DEV__`).
   Start it from the app's root once the model exists.
8. **"Live apps" picker:** a list of apps that checked in within the last ~40 s, showing device, kind,
   signed-in user and current screen. Every control panel sits under it, and **nothing works until one app is
   picked**. Remember the pick in `localStorage`.
9. **Modules** the user asked for, one tab each (below).
10. **Admin actions**, if asked for: key file, git-ignore, test accounts only, one-time tokens only. See
    [backend-admin.md](backend-admin.md).
11. **Verify** with the checklist at the end of [guardrails.md](guardrails.md). If you can't run the server,
    give the user the checks to run. When you can, run them: the control port doesn't answer from the LAN or
    through `adb reverse`, a release build has no debug strings in it, and `git check-ignore` passes on the
    key file. Show the user the results.

## The protocol in one screen

```
Device listener 0.0.0.0:DEVICE_PORT (phones, simulators, adb reverse), only these two routes:
App    →  GET /api/debug/poll?id=<instance>&since=<n>&pair=<secret>&screen=…&user=…
Server ←  holds the call open up to 25 s; answers at once when a command for <instance> arrives
       →  {"next": 42, "commands": [{"id": 42, "action": "screen", "value": "paywall"}]}
App    →  POST /api/debug/snapshot?id=<instance>&pair=<secret>   (PNG body)

Control listener 127.0.0.1:PORT (the page and every other route):
Page   →  POST /api/debug/send {"target": "<instance>", "action": "...", "value": "..."}
```

These are two separate servers in one process, sharing one command queue. A route that isn't on the device
listener can't be reached from a phone, however the phone connects.

`since=-1` on a fresh start returns no commands, so clicks made before launch never replay. If `since` is
greater than the server's last ID, the server has restarted and the client starts over. The full spec,
with a server and a Swift client sketch, is in [protocol.md](protocol.md).

## Modules (optional, one tab each)

| Module | App side | Page side |
|---|---|---|
| **Screen jumper** | one debug entry in the navigation model (`showForDebug(name)`, "real" to leave), not simulated taps. Wait for a tab to appear before opening a sheet on it | a list of every screen, sheet and onboarding step, with a "Real" button |
| **State overrides** | time of day, offline mode, theme, outfit, feature flags. Kept on this device only, never saved to the backend, each with a "Real" reset | chips that show the current value the app reported in its check-in |
| **Accounts** | "start over as a new user" and "switch back" (previous sessions kept in a debug-only list), "log in as" with a one-time token | the test users from the backend, newest first |
| **Snapshot** | draw every window into a PNG and POST it to the page (system keyboard comes out blank) | shows the latest one per app, kept in memory only |
| **Live asset viewer** | none | serves the same Rive, Lottie or 3D file the app bundles and plays it in the pinned web runtime, with the same inputs the app sets |
| **Ops views** | none | reports to review, failed pushes, queue counts (read-only, plus explicit "mark reviewed" actions) |

Put **every debug switch on the console**, not in the app's Settings. Settings is for real users.

## Page conventions

- Tabs: Build, then one per module, then Log. The "Live apps" picker shows on every control tab.
- Every control has a one-line tip under it saying what it does on the picked app.
- Errors read as instructions ("unlock the phone, then tap the app"), not exit codes.
- Poll `/api/debug/apps` every ~1.5 s and `/api/job` every ~1 s while a build runs. Plain `fetch`, no
  websockets needed.
- Device names can repeat (two "iPhone 17 Pro" simulators), so support an optional `nicknames.json`
  mapping UDID to a name.

## Common mistakes

| Mistake | Do this instead |
|---|---|
| One server for the page and the phones, with "localhost only" checked by client IP | Two listeners. With `adb reverse`, an SSH tunnel or a local proxy, **every app on the phone arrives as 127.0.0.1**, so the client IP proves nothing. Only the device port is reversed or opened to the LAN, and it serves only poll and snapshot |
| Trusting loopback against the Mac's own browser | Also check `Host` and require `Content-Type: application/json` on POSTs. A web page in the Mac's browser can otherwise reach localhost (CSRF, DNS rebinding) |
| Device names or screen names put into the page with `innerHTML` | Anything an app reports is untrusted (anything on the Wi-Fi can check in). Build the page with `textContent` / `createElement` |
| Profile expiry estimated from the install date | Read the real `ExpirationDate` from the profile files. An estimate goes wrong the first time Xcode refreshes a profile on its own |
| Baking the Mac's Wi-Fi IP into the phone build | The address changes (a router lease, another network) and the phone silently stops checking in. Write both, `<LocalHostName>.local,<IP>` (`scutil --get LocalHostName`), and let the client try them in order, moving on after a failure. Show on the page which host each build has |
| A phone never checks in | iOS asks for Local Network permission on first contact and fails silently if denied. Add `NSLocalNetworkUsageDescription` (debug configs only) and `NSAllowsLocalNetworking`, and tell the user where to look in Settings |
| Commands broadcast to every app | Every command names exactly one target |
| The app's "pretend offline" switch also kills the debug connection | Give the client its own ephemeral URL session that the app's network layer doesn't touch |
| Phone build is Debug and unoptimised, so it feels slow | A device configuration based on Debug with `-O` keeps the debug code and runs at real speed |
| `-allowProvisioningUpdates` on every build | Without an Apple ID signed in to Xcode it fails the whole build. Try without it first, and retry with it only when the profile is missing |
| The server key passed on a command line or logged | Read it from the file inside the server process. `ps` and the log show command lines |
| "Log in as" offered for every user | Test accounts only, filtered by a marker the project defines |
| Extra tabs nobody asked for (a deploy tab on a "jump to a screen" request) | Build the request plus the guardrails, and offer the rest in one line |

## Worked example

This skill comes from a real console for a SwiftUI + Supabase app, about this size:

- `tools/dev-console/server.py`, about 600 lines of standard-library Python. It covers device listing, one
  build per kind with parallel installs, the signing check, the long poll, snapshots kept in memory, and
  Supabase admin calls (users, magic-link tokens, reports, failed pushes).
- `tools/dev-console/index.html`, about 800 lines with no framework. Its tabs are Build, App, Look, Screens,
  Account, Character (a live Rive viewer), Reports and Log.
- `Debug/DevConsole.swift`, about 300 lines, all inside `#if DEBUG`. It routes commands through
  NotificationCenter names and one `showForDebug(screen)` entry in the app model.

If the project you're in already has a console like this, extend it rather than starting a second one.

**Retrofitting the guards onto an existing console** (the most common case: a console grown feature by
feature, with one server that checks the client IP). Add, in this order: JSON-only POSTs and the `Host`
check (no app change, nothing breaks, since the page already sends JSON), then the pair (server and client
together, then rebuild the phones), then the `.local` host list. Run the checks in
[guardrails.md](guardrails.md) against a second copy on another port before restarting the one the user's
apps are checked in to. Splitting into two listeners can wait until something forwards into loopback.
