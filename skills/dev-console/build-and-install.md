# Build and install on many devices

## Shape of a run

- `POST /api/run {"ids": [...], "launch": true}` starts one **job** (refuse with 409 while one runs).
- The job groups the picked devices by kind and **builds each kind once**: a device configuration for
  phones, Debug for simulators. Then it installs and launches on every device of that kind **in parallel**
  (`ThreadPoolExecutor`).
- The job holds log lines plus a state per device: `waiting → building → (signing) → installing → opening →
  running | installed | failed`, each with a short note. The page polls `GET /api/job?since=<line>` about
  once a second.
- Wrap the whole job in `try/finally` so the job always ends up `done` and the page never spins forever.
- The build tools print a lot. Pass on lines with `error:` and xcodebuild's `** BUILD … **` lines, and keep the
  full output for working out why it failed. Give every subprocess a timeout.

## iOS commands

| Step | Command |
|---|---|
| List phones | `xcrun devicectl list devices --json-output <file>`, then keep `hardwareProperties.reality == "physical"`, platform iOS. `connectionProperties.pairingState` shows whether it's paired |
| List simulators | `xcrun simctl list devices booted -j` |
| Build for phones | `xcodebuild -project X.xcodeproj -scheme S -configuration <DeviceConfig> -destination generic/platform=iOS -derivedDataPath build-device build DEV_CONSOLE_HOST=<host> DEV_CONSOLE_PAIR=<secret>` |
| Build for simulators | same, with `-configuration Debug -destination "generic/platform=iOS Simulator" -derivedDataPath build` |
| Install on a phone | `xcrun devicectl device install app --device <udid> <path.app>` |
| Install on a simulator | `xcrun simctl install <udid> <path.app>` |
| Launch on a phone | `xcrun devicectl device process launch --terminate-existing --device <udid> <bundle-id>` |
| Launch on a simulator | `xcrun simctl launch --terminate-running-process <udid> <bundle-id>` |

Phone and simulator builds can have different bundle IDs (a free personal team can't use an ID that's
taken elsewhere). Keep a small spec per kind: config, derived data path, products folder, destination,
bundle ID.

## Signing (free Apple team)

- Free team profiles last **7 days** and then disappear from the Mac. Free teams also have small weekly
  limits on new app IDs and devices.
- **First try without `-allowProvisioningUpdates`**. With no Apple ID signed in to Xcode that flag fails the
  whole build, while the profile already on the Mac signs a generic build fine.
- If the output contains `No profiles for`, retry once **with** `-allowProvisioningUpdates`, then read the
  profiles again.
- If an install fails with `0xe8008012`, this phone isn't in the profile. Build once for that phone with
  `-destination id=<udid> -allowProvisioningUpdates -allowProvisioningDeviceRegistration`, then install again.
- **Signing banner:** decode each `*.mobileprovision` in `~/Library/Developer/Xcode/UserData/Provisioning
  Profiles` and `~/Library/MobileDevice/Provisioning Profiles` with `security cms -D -i <file>`, then
  `plistlib.loads`. Match `Entitlements.application-identifier` (after the team prefix) against the app's
  and every extension's bundle ID. Take the latest `ExpirationDate` for each bundle and the earliest across
  bundles. The state is `missing`, `expired`, `soon` (under 2 days) or `ok`. Cache it for 60 s and show it
  above the device list. Always read the real dates. An estimate from the install time drifts as soon as Xcode refreshes a
  profile on its own.

## Plain-language failure reasons

Match the full output and return one sentence the page can show. The common ones:

| Output contains | Tell the user |
|---|---|
| `No Accounts` / `No account for team` | Xcode isn't signed in to your Apple ID: Xcode › Settings › Apple Accounts, then build again |
| `No profiles for` (after the retry) | The signing profile ran out and Xcode couldn't make a new one (see log) |
| `maximum number` | Your free team used its app or device slots this week: delete an older test app, or wait |
| `Unable to find a destination` | Xcode hasn't finished installing an iOS platform: open Xcode once |
| `0xe8008012` | This phone isn't in the signing profile (handled automatically, see above) |
| launch output contains `locked` | Unlock the phone, then tap the app |
| anything else with `error:` | `Build error: <first error, first 160 characters>` |

Keep this list in one function and add to it whenever a new failure shows up.

## Android notes

| Step | Command |
|---|---|
| List devices and emulators | `adb devices -l` (emulators show as `emulator-5554`) |
| Build once | `./gradlew :app:assembleDebug -PdevConsoleHost=<host> -PdevConsolePair=<secret>` → `app/build/outputs/apk/debug/*.apk` |
| Install | `adb -s <serial> install -r <apk>` (in parallel per serial) |
| Launch | `adb -s <serial> shell am start -n <appId>/<.MainActivity>` |
| Reach the Mac | the **device port** only (see the two listeners in protocol.md). Emulator: `10.0.2.2:DEVICE_PORT`. USB or wireless debugging: `adb -s <serial> reverse tcp:DEVICE_PORT tcp:DEVICE_PORT`, then `127.0.0.1`. Wi-Fi only: the Mac's `.local` name or IP. Never reverse the control port, because every app on the phone could then use it |

Common failures: `INSTALL_FAILED_UPDATE_INCOMPATIBLE` means a build with a different signature is installed
(uninstall it first and say so). `unauthorized` means the user must accept USB debugging on the phone.
`INSTALL_FAILED_INSUFFICIENT_STORAGE` speaks for itself.

## Expo / React Native

Use the native commands above on the output of `npx expo run:ios|android` or `expo prebuild`, or use EAS
builds. Expo's dev client already does reload and the dev menu. The console only adds installing on many
devices at once and the project's own commands.
