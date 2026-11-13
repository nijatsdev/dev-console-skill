# First run: ask, once

The first time you build a console for a project, a few choices really differ between apps, and a wrong
guess is costly: a deploy tab nobody wanted, or no "log in as" for someone who needed it. Ask about those in
**one round, with at most four questions**, before writing any code. Everything else has a good default.

## When to ask, and when not to

- **Ask** when there's no console yet and the request is open ("make me a dev console", "set up a debug
  page for this app").
- **Skip the round** when the request already answers it ("add a screen jumper", "put my phones and the
  simulator on one Build button"), when a console already exists (extend it as it is), or when the user said
  to just build it. Then decide from the request and the project, and say in one line what you chose.
- **Never ask about the guardrails.** Two listeners, the Host check, JSON-only POSTs, the pairing secret and
  the key rules are always on (see [guardrails.md](guardrails.md)).
- **Don't ask** about ports, folder, language or server structure. Use the defaults, which are easy to change
  later.

## Read the project first

Each question has a recommended answer, taken from what the project shows. Find these before asking:

| Look for | Where | It suggests |
|---|---|---|
| Backend and its admin API | Supabase/Firebase config, `.env*` names (not values), API clients | Accounts and admin modules, question 4 |
| Phone targets, signing team | `DEVELOPMENT_TEAM`, a personal/free team, provisioning settings; Android `applicationId` | Deploy module, question 2 |
| Debug switches already in the app | a Debug section in Settings, `#if DEBUG` toggles, launch arguments | State overrides and screen jumper |
| Navigation shape | tab enum, router, sheet/route names | Screen jumper values |
| Design tokens | colour assets, a theme/palette file, `Color` extensions, custom fonts, Tailwind/theme config | "Match your app" in question 3 |
| Agents already at work | `CLAUDE.md`, `AGENTS.md`, `.claude/` | Agent access module |

## The questions

Use the agent's own question tool when it has one (multiple choice, the user clicks), with the recommended
option first and marked "(Recommended)". Put what you found into the question itself, so each one stands on
its own: "Found Supabase and a paid Apple team. What should the console do?"

### 1. What should it do? (choose several)

- Build and install on phones and simulators at once
- Jump to any screen or sheet
- Override state on one device (time of day, theme, offline, feature flags)
- Switch test accounts and log in as a test user
- Snapshots of the app's screen
- Admin views (reports to review, failed pushes, queue counts)
- Agent access (`/api/actions`, the `dc` script; see [agent-access.md](agent-access.md))

Preselect from the project: a backend suggests accounts and admin, phone targets suggest deploy, existing
debug toggles suggest overrides.

### 2. Which devices?

- Simulators/emulators only
- Phones too, over Wi-Fi (needs the pairing secret and the `name.local,IP` host list)
- Phones over USB only (Android: `adb reverse` on the device port only)
- Android emulators as well

Add, when iOS phones are in: is the Apple team **free** (profiles last 7 days: add the signing banner and the
renewal retry) or **paid**?

### 3. How should it look?

- **Match the app:** the app's own colours, fonts and corner shapes, taken from its design tokens. Recommend
  this when the project has clear tokens: people leave the console open beside the app all day.
- **Clean default:** a neutral, system-style page (system font, light and dark from `prefers-color-scheme`).
  Quickest, and right when the app has no design system yet.
- **Compact dark:** dense rows and small type, for a second screen.

When the question tool can show previews, give each option a small preview: a mock of the device list and one
tab in that style (a few lines of HTML or an ASCII sketch). People choose a look by eye, not by its name.

### 4. Backend admin (only when a backend was found)

- Which actions: log in as a test user, review reports, see failed pushes, queue counts, none
- How test accounts are recognised: an email domain, a flag column, an allow-list, or anonymous users only.
  "Log in as" offers only those (see [backend-admin.md](backend-admin.md)).

## After the answers

- Build exactly what was chosen, plus the guardrails. Name the modules left out in one closing line, as
  things you can add later.
- Write the choices at the top of `tools/dev-console/server.py` (a short comment: modules, devices, look,
  test-account rule), so the next agent extends the console in the same spirit instead of asking again.
- If the user chose "match the app", read the actual token values from the project. Don't approximate them
  by eye from a screenshot.
