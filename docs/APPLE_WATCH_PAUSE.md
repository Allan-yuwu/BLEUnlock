# Apple Watch pause: feasibility and validation

## Supported scope

This patch provides **manual per-device pause/resume**, not automatic wear or charging detection. All bound devices are listed, so the user selects the actual Watch without relying on a renameable Bluetooth name. A checkmark and Resume label indicate manual pause. Paused devices are excluded from both lock and unlock any/all aggregation. No active device means neither action. Other devices and macOS native locking retain their own behavior.

The pause UUID set is stored in `manuallyPausedDevices` in the app preferences. Pauses survive app relaunch and sleep/wake; the existing recognized UUID-remapping path transfers the pause to the new identity. No expiry is implied. Rebinding the same UUID retains pause. An unrecognized identity change still needs user selection; device identity is not inferred from charging behavior.

Resume invalidates old timers and RSSI, waits for fresh measurements, and permits unlock only after the unlock threshold is met. The resumed device still counts in unlock-all while waiting, preventing another nearby device from prematurely satisfying all-close. Waiting devices are not considered away until a real reading / timeout establishes that. A fresh weak reading may start the original lock delay; no reading uses signal timeout. Pausing cancels queued unlock retries and invalidates queued automatic lock actions; manual Lock Screen Now remains independent.

## Verified source limits

- Apple's [SRWristDetection](https://developer.apple.com/documentation/sensorkit/srwristdetection) exposes wrist state through SensorKit. Apple's [SensorKit entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.sensorkit.reader.allow) requires a preapproved research study. This is not a generally available solution for the existing Mac-only app.
- Apple's [WKInterfaceDevice batteryState](https://developer.apple.com/documentation/watchkit/wkinterfacedevice/batterystate) and [charging states](https://developer.apple.com/documentation/watchkit/wkinterfacedevicebatterystate) describe information available to watchOS code, including full-on-charger. Their existence does not establish a Mac API or a background transport to this app.
- Source inspection of `BLE.swift` finds RSSI/presence tracking, manufacturer/model reads and advertisement bytes, but no authenticated wear/charging source. No claim is made that undocumented advertisements reliably expose either state on the user's Watch. Weak RSSI, loss of signal and lack of motion are not evidence of removal.

A future automatic feature needs a separately verified source, identity binding, stale-data behavior, and actual on-wrist/off-wrist/charging/background tests on the user's watchOS. A companion watch app may provide charging information, but background delivery and wrist-state availability remain unverified. This patch does not request SensorKit/Health permissions or add a watch app.

## Validation

See `scripts/test-device-pause.sh` for standalone Swift regression checks of the production aggregation policy and state transitions. These tests have no Bluetooth, Keychain or screen-lock side effects. Hardware scenarios are explicitly tracked in [manual test matrix](../human_tests/device-pause.md).

The original iCloud worktree build compiled but ad-hoc signing failed because iCloud attached Finder/resource-fork metadata to the generated bundle. Verification was rerun from an identical source copy under `/tmp/bleunlock-watch-verification`, with extended attributes removed only from that disposable copy. No production app was modified.

### Recorded results (2026-11-23)

- Pure Swift policy regression: 31 checks passed; no hardware side effects.
- `git diff --check`, shell syntax, project plist and Base/Chinese string parsing: passed.
- Two Review/Fix/Test rounds: first fixed fresh-weak-signal premature unlock and queued automatic action cancellation (preserving the system wake recovery job); second fixed waiting devices bypassing unlock-all, startup/wake freshness, UUID pause transfer, and debug symbols packaged as executable content.
- Full Xcode Debug build with repository macOS 10.13 setting: blocked by Xcode 27.2 SDK rejecting deployment targets below 12.0. Project minimum remains unchanged.
- Full Xcode Debug and Release builds with **command-line-only** `MACOSX_DEPLOYMENT_TARGET=12.0`, `CODE_SIGNING_ALLOWED=NO`: passed. These prove current SDK compilation only, not macOS 10.13 runtime compatibility or signed Release readiness.
- Local CLT build uses `arm64-apple-macosx10.13`; it emits existing SDK availability/deprecation warnings. Final gate passed: ad-hoc signature verification, DMG SHA-256/readonly mount/code-signature verification, and isolated 5-second startup smoke.
- Apple Watch hardware/permission/actual lock/unlock integration and visual menu acceptance: not run; see manual matrix. No production install, tag or release.
