# Backend admin actions

Some console actions need more power than the app has: listing users, signing a test user in, reading
reports or failed pushes. They use a **server key**, which stays on the Mac.

## Where the key lives

- In `tools/dev-console/.env.local` as `NAME=value`, or in an environment variable of the same name (the
  env var wins). Never in Info.plist, build settings, the page's HTML or JavaScript, or a tracked file.
- Add the exact path to `.gitignore` and prove it's ignored with
  `git check-ignore -v tools/dev-console/.env.local`. Commit an `.env.example` holding the key's name only.
- The server reads it inside its own process. Never put it on a command line (`ps` and the console's log
  show command lines), and never print or log it, not even partly.
- If the key is missing, endpoints answer `{"missing_key": true}` and the page explains where to put it. No
  stack traces.
- Admin routes live on the control listener (`127.0.0.1`, never reversed or forwarded), behind the same
  guards as every other control (see [guardrails.md](guardrails.md)). A route the phone can reach through
  `adb reverse` is a route every app on the phone can reach.

## What goes to the phone

Only a **one-time result**, delivered as a command to the one picked app:

| Backend | Server side (with the key) | App side (debug code) |
|---|---|---|
| Supabase | `POST /auth/v1/admin/generate_link {"type":"magiclink","email":…}` → `hashed_token` | `auth.verifyOTP(tokenHash:type: .magiclink)` |
| Firebase | Admin SDK `createCustomToken(uid)` (service account JSON on the Mac) | `Auth.auth().signIn(withCustomToken:)` |
| Own API | an admin-only endpoint that mints a short-lived sign-in code | exchange the code for a session |

The app never sees the key and can't make further admin calls.

## Test accounts only

- "Log in as" lists **test accounts only**. Pick a marker with the user (an email domain like
  `@example.test`, an `is_test` column, or an allowlist file next to the key) and filter on the server, not
  in the page.
- Add a tripwire: if the filter matches more accounts than the user said they have (or more than ~50), the
  server refuses to list any and says why. A pattern that catches too much usually means real users are
  caught too.
- If the backend holds real users, never list them, never sign in as them and never change them. If the
  sign-in method needs to change the account first (for example, giving a guest account a placeholder email
  so a magic link can be made), do it only to test accounts.
- Keep the account the app was on before "log in as" in a debug-only list, so a "switch back" control can
  return to it.

## Ops views

These read-only views are worth adding once the backend has the tables:

- **Reports / moderation queue:** open items oldest first, with the names of who reported and who sent, and
  a 10-minute signed link for any private media. "Mark reviewed" calls one narrow server function and
  validates the ID's format before calling.
- **Failed pushes / jobs:** counts in total and for the last 24 h, plus the latest few rows with their error.
  Use the backend's count-only request (PostgREST: `HEAD` with `Prefer: count=exact`, `Range: 0-0`) instead
  of fetching rows.

Any action that changes data asks for one confirming click and says what it changes.
