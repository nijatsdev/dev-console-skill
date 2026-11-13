# Guardrails

The console can sign people in and install apps, and it listens on the Wi-Fi. Put these in place before any
feature, and check each one with the commands at the end before telling the user it's done.

## Network

- **Bind `0.0.0.0`** so phones can reach it. Only `GET /api/debug/poll` and `POST /api/debug/snapshot`
  answer non-local addresses. Everything else returns 403 unless `client_address[0]` is `127.0.0.1` or `::1`.
- **Check `Host`** on every localhost route. It must be `localhost:PORT` or `127.0.0.1:PORT`. That blocks DNS
  rebinding, where a web page in the Mac's browser resolves its own name to 127.0.0.1 and reads the
  console's answers.
- **POSTs need `Content-Type: application/json`**, or a custom header such as `X-Dev-Console: 1`. Reject
  anything else with 415. Browsers can't send either one across sites without a preflight, which the server
  never approves, so other sites can't make it build, send commands or sign someone in (CSRF). Send no CORS
  headers.
- **Pairing secret:** polls and snapshots must carry the `pair` value written into this Mac's debug builds
  (see [protocol.md](protocol.md)). Compare it with `hmac.compare_digest`.
- **Limit what the LAN can send:** state values are capped (~200 characters), snapshots are PNG-only and
  size-capped from known instances, and old app records expire.

## Secrets

- The server key lives only in the git-ignored key file or an env var, read inside the server process.
- Never print it, log it, put it on a command line, send it to the page or send it to the phone.
- The phone gets one-time tokens only, as a command to the one picked app.

## Release builds

- All debug client code sits inside `#if DEBUG` (the whole file), Android `src/debug/`, or `__DEV__`.
- The configuration for phones may be optimised (`-O`) but must still be a debug configuration.
- In Release, the local network usage string and the console host/pair build settings are empty, and ATS
  local-networking stays limited to debug configurations if the project can split it.

## Accounts and data

- "Log in as" works for test accounts only, filtered on the server (see [backend-admin.md](backend-admin.md)).
- Overrides (screens, sky, outfit, offline) never write to the backend.
- Snapshots and anything else from phones stay in memory, never on disk.
- Actions that change backend data ask for one click to confirm and name what they change.

## Verify before calling it done

Run these and show the user the output:

```bash
# 1. Controls refuse the LAN (use the Mac's own LAN address, not localhost): expect 403
curl -s -o /dev/null -w "%{http_code}\n" "http://$(ipconfig getifaddr en0):PORT/api/debug/apps"
# 2. Wrong Host refused: expect 403
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: evil.example:PORT" http://127.0.0.1:PORT/api/debug/apps
# 3. Form-encoded POST refused: expect 415
curl -s -o /dev/null -w "%{http_code}\n" -d "target=x&action=y" http://127.0.0.1:PORT/api/debug/send
# 4. Poll without the pairing secret refused: expect 403
curl -s -o /dev/null -w "%{http_code}\n" "http://127.0.0.1:PORT/api/debug/poll?id=t&since=-1"
# 5. Round trip: a fake app polls, a command reaches it
curl -s "http://127.0.0.1:PORT/api/debug/poll?id=t&since=0&pair=$PAIR" &
curl -s -H "Content-Type: application/json" -d '{"target":"t","action":"ping"}' http://127.0.0.1:PORT/api/debug/send; wait
# 6. Key file ignored
git check-ignore -v tools/dev-console/.env.local
# 7. No debug code in Release: expect no output
xcodebuild -scheme S -configuration Release -destination generic/platform=iOS -derivedDataPath /tmp/rel build >/dev/null \
  && strings /tmp/rel/Build/Products/Release-iphoneos/App.app/App | grep -i "api/debug"
```

Android version of check 7: `unzip -p app-release.apk 'classes*.dex' | strings | grep -i api/debug`.
Then build and run a debug build on one real phone and one simulator, check both show up under "Live apps",
and send one command to each.
