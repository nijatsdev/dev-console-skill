# Guardrails

The console can sign people in and install apps, and it listens on the Wi-Fi. Put these in place before any
feature, and check each one with the commands at the end before telling the user it's done.

## Network

- **Two listeners.** The control listener binds `127.0.0.1:PORT` and serves the page and every action. The
  device listener binds `0.0.0.0:DEVICE_PORT` and serves only `GET /api/debug/poll` and
  `POST /api/debug/snapshot`, returning 404 for everything else. See [protocol.md](protocol.md).
- **Why not one server that checks the client IP:** `adb reverse`, `iproxy` and SSH tunnels deliver a
  phone's traffic from 127.0.0.1. Through a single server, any app on the phone would look like the Mac and
  could list users, mint sign-in tokens or start builds. Only ever reverse, forward or open the device port.
- **Check `Host`** on every control route. It must be `localhost:PORT` or `127.0.0.1:PORT`. That blocks DNS
  rebinding, where a web page in the Mac's browser resolves its own name to 127.0.0.1 and reads the
  console's answers.
- **POSTs need `Content-Type: application/json`**, or a custom header such as `X-Dev-Console: 1`. Reject
  anything else with 415. Browsers can't send either one across sites without a preflight, which the server
  never approves, so other sites can't make it build, send commands or sign someone in (CSRF). Send no CORS
  headers.
- **Pairing secret:** polls and snapshots must carry the `pair` value written into this Mac's debug builds
  (see [protocol.md](protocol.md)). Compare it with `hmac.compare_digest`. An Android adb broadcast
  receiver checks the same value. The secret keeps out other machines, not other apps on the same phone:
  any Android app can read another app's APK. So instance IDs must be random and never shown outside the
  page, and one-time tokens must be short-lived and used once.
- **Treat what apps report as untrusted.** State values are capped (~200 characters), snapshots are PNG-only
  and size-capped from known instances, and old app records expire. The page shows app-reported text with
  `textContent`/`createElement`, never `innerHTML`.

## Secrets

- The server key lives only in the git-ignored key file or an env var, read inside the server process.
- Never print it, log it, put it on a command line, send it to the page or send it to the phone.
- The phone gets one-time tokens only, as a command to the one picked app. A token sent over plain HTTP on
  the Wi-Fi is readable on that network for the few seconds before it's used. Prefer the emulator or USB
  path for log-ins on a shared network, and keep token lifetimes short.

## Release builds

- All debug client code sits inside `#if DEBUG` (the whole file), Android `src/debug/`, or `__DEV__`.
- The configuration for phones may be optimised (`-O`) but must still be a debug configuration.
- In Release, the local network usage string and the console host/pair build settings are empty. Where the
  project can give Debug and Release separate Info.plist values (build settings, `INFOPLIST_FILE` per
  configuration), keep `NSAllowsLocalNetworking` out of Release too. If it can't, say so in the notes.

## Accounts and data

- "Log in as" works for test accounts only, filtered on the server (see [backend-admin.md](backend-admin.md)).
- Overrides (screens, sky, outfit, offline) never write to the backend.
- Snapshots and anything else from phones stay in memory, never on disk.
- Actions that change backend data ask for one click to confirm and name what they change.

## Verify before calling it done

Run these and show the user the output (PORT = control, DPORT = device):

```bash
# 1. Control port is not reachable from the LAN: expect a connection failure (000)
curl -s -m 3 -o /dev/null -w "%{http_code}\n" "http://$(ipconfig getifaddr en0):PORT/"
# 2. Device port serves nothing but the check-in: expect 404
curl -s -o /dev/null -w "%{http_code}\n" "http://127.0.0.1:DPORT/api/debug/apps"
# 3. Wrong Host refused on the control port: expect 403
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: evil.example:PORT" http://127.0.0.1:PORT/api/debug/apps
# 4. Form-encoded POST refused: expect 415
curl -s -o /dev/null -w "%{http_code}\n" -d "target=x&action=y" http://127.0.0.1:PORT/api/debug/send
# 5. Poll without the pairing secret refused: expect 403
curl -s -o /dev/null -w "%{http_code}\n" "http://127.0.0.1:DPORT/api/debug/poll?id=t&since=-1"
# 6. Round trip: a fake app polls, a command reaches it
curl -s "http://127.0.0.1:DPORT/api/debug/poll?id=t&since=0&pair=$PAIR" &
curl -s -H "Content-Type: application/json" -d '{"target":"t","action":"ping"}' http://127.0.0.1:PORT/api/debug/send; wait
# 7. Key file ignored
git check-ignore -v tools/dev-console/.env.local
# 8. No debug code in Release: expect no output
xcodebuild -scheme S -configuration Release -destination generic/platform=iOS -derivedDataPath /tmp/rel build >/dev/null \
  && strings /tmp/rel/Build/Products/Release-iphoneos/App.app/App | grep -i "api/debug"
```

Android: check 8 becomes `unzip -p app-release.apk 'classes*.dex' | strings | grep -i api/debug`. Also run
`adb reverse --list` and confirm only DPORT is listed. Then build and run a debug build on one real phone and
one simulator or emulator, check both show up under "Live apps", and send one command to each.
