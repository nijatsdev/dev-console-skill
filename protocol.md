# Check-in and poll protocol

One HTTP long poll. No websockets, Bonjour service or push needed. It works the same from a simulator
(`127.0.0.1`), from a phone on the same Wi-Fi, and from an Android emulator (`10.0.2.2`) or a USB device
(`adb reverse tcp:PORT tcp:PORT`, then `127.0.0.1`).

## Identity

- **instance id:** one per running copy of the app. On an iOS simulator it's `SIMULATOR_UDID` from the
  process environment. On a phone it's `identifierForVendor`, and on Android a random UUID kept in debug-only
  prefs. It must be stable across launches so the page's pick survives a relaunch.
- **pair:** a random secret the server generates once (kept next to the server in a git-ignored file) and
  writes into each debug build it makes, as a build setting into Info.plist or as a `BuildConfig` field. The
  server ignores polls without it. That stops another machine on the Wi-Fi from guessing an instance ID and
  receiving its commands, which can include one-time sign-in tokens.

## Endpoints

| Method and path | Who may call | Purpose |
|---|---|---|
| `GET /api/debug/poll?id&since&pair&<state…>` | LAN | check in and wait for commands |
| `POST /api/debug/snapshot?id&pair` (body: PNG) | LAN | the app sends back its screen |
| `GET /api/debug/apps` | localhost | apps seen in the last 40 s, with their state |
| `POST /api/debug/send {target, action, value}` | localhost | queue a command for one app |
| `GET /api/debug/snapshot?id` | localhost | latest PNG from that app |

## Poll semantics

1. The app calls `poll` with `since=-1` on launch.
2. The server records the app (`id`, every state key, `seen = now`) and wakes any page waiting on it.
3. If `since < 0` (fresh start) or `since > last_id` (the server restarted, so its counter began again), the
   server answers at once with `{"next": last_id, "commands": []}`. Clicks made before the app was running
   never replay.
4. Otherwise it waits on a condition variable, up to **25 s**, for commands with `id > since` whose targets
   include this app. It answers as soon as one exists, or with an empty list at the deadline.
5. The app runs the commands in order, sets `since = next` and polls again straight away.
6. If a call fails, the app waits **3 s** and tries again, without telling the user. Set the client request
   timeout (~40 s) longer than the server's hold.
7. The server keeps only the last ~200 commands. An app counts as live while `now - seen < 40 s`.

State keys are short strings the page shows as chips: `kind` (phone/simulator/emulator), `device`, `user`,
`screen` or `phase`, and the current value of each override. A command's result can come back the same way,
as a state key like `lastResult` that the next poll carries.

## Commands

`{"id": int, "action": string, "value": string | null}`. Rules:

- Actions are plain names (`screen`, `sky`, `offline`, `login`, `snapshot`). The app ignores names it
  doesn't know, so an old build never breaks when the page gains new controls.
- `value: "real"` or empty means "go back to the real thing".
- Overrides stay on the device. They never write to the backend or into the user's saved data.
- UI jumps go through one debug entry in the app's navigation model. When a sheet lives on another tab, the
  app switches tab first and waits ~0.6 s before presenting.

## Server sketch (Python, standard library)

```python
class Remote:
    LIVE_FOR = 40
    def __init__(self):
        self.cond, self.commands, self.last_id, self.apps = threading.Condition(), [], 0, {}

    def poll(self, q):                      # q: dict of query params, pair already checked
        app = q["id"]; since = int(q.get("since", "-1"))
        with self.cond:
            self.apps[app] = {**{k: v[:200] for k, v in q.items() if k not in ("since", "pair")}, "seen": time.time()}
            self.cond.notify_all()
            if since < 0 or since > self.last_id:
                return {"next": self.last_id, "commands": []}
            deadline = time.time() + 25
            while True:
                mine = [c for c in self.commands if c["id"] > since and app in c["targets"]]
                if mine or time.time() >= deadline:
                    return {"next": self.last_id,
                            "commands": [{k: c[k] for k in ("id", "action", "value")} for c in mine]}
                self.cond.wait(deadline - time.time())

    def send(self, target, action, value):  # localhost only, exactly one target
        with self.cond:
            self.last_id += 1
            self.commands = (self.commands + [{"id": self.last_id, "targets": [target],
                                               "action": action, "value": value}])[-200:]
            self.cond.notify_all()
            return self.last_id
```

Use `ThreadingHTTPServer` with `daemon_threads = True`, because each waiting poll holds a thread. Drop app
records that haven't been seen for an hour so a stream of fake IDs can't grow memory without limit.

## Client sketch (Swift)

```swift
#if DEBUG
@MainActor final class DevConsole {
    static let shared = DevConsole()
    private var task: Task<Void, Never>?
    private let session: URLSession = {            // its own session: the app's "offline" switch can't touch it
        let c = URLSessionConfiguration.ephemeral
        c.timeoutIntervalForRequest = 40; c.waitsForConnectivity = false
        return URLSession(configuration: c)
    }()
    private let id = ProcessInfo.processInfo.environment["SIMULATOR_UDID"]
        ?? UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    private var host: String? {
        #if targetEnvironment(simulator)
        "127.0.0.1"
        #else
        (Bundle.main.object(forInfoDictionaryKey: "DevConsoleHost") as? String).flatMap { $0.isEmpty ? nil : $0 }
        #endif
    }

    func start(state: @escaping () -> [String: String], run: @escaping (Command) async -> Void) {
        guard task == nil, let host else { return }
        task = Task {
            var since = -1
            while !Task.isCancelled {
                do {
                    let reply = try await poll(host: host, since: since, state: state())
                    since = reply.next
                    for c in reply.commands { await run(c) }
                } catch { try? await Task.sleep(for: .seconds(3)) }
            }
        }
    }
    struct Command: Decodable { let id: Int; let action: String; let value: String? }
    private struct Reply: Decodable { let next: Int; let commands: [Command] }
    private func poll(host: String, since: Int, state: [String: String]) async throws -> Reply { /* GET, decode */ }
}
#endif
```

Info.plist for debug configurations only: `DevConsoleHost = $(DEV_CONSOLE_HOST)`, `DevConsolePair =
$(DEV_CONSOLE_PAIR)`, `NSAppTransportSecurity › NSAllowsLocalNetworking = YES`, and
`NSLocalNetworkUsageDescription` set from a build setting that is empty in Release.

Android: put the client in `src/debug/java/…` so release never compiles it. Allow cleartext for the dev
host only, with a `network_security_config.xml` in `src/debug/res/xml/`. React Native/Expo: guard with
`if (__DEV__)` and keep the module in a file that release bundles tree-shake out.

## Snapshot

The app draws every visible window of its scene into one image (`drawHierarchy(in:afterScreenUpdates:)`,
8-bit, scale 2) and POSTs the PNG. The server takes it only from an instance that has checked in with the
right `pair`, only if it starts with the PNG signature and only up to a size limit (~15 MB). It keeps it
in memory only, never on disk. The page asks for the newest one after a click and shows it once its time is
later than the click.
