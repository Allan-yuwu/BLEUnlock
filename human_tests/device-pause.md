# Device pause and resume

Status: **NOT RUN on a bound Apple Watch**. No automatic locking, password input, Bluetooth reset, permission changes, or replacement of the installed app was performed. The isolated local smoke build disables automatic lock/unlock and cannot prove these scenarios.

Record Mac model, macOS/watchOS versions, Watch model, permissions, starting RSSI thresholds and delays, and actual outcome for each row before calling hardware validation complete. Use a dedicated test account, save work, and keep a manual unlock path. Only run screen-lock/password-input cases after explicit user approval.

| ID | Steps | Expected | Actual |
| --- | --- | --- | --- |
| P1 | Bind Watch; start a weak-signal lock delay; pause before delay expires; move Mac away and wait beyond signal timeout | Neither delayed nor lost-signal lock fires | Not run |
| P2 | Pause a nearby Watch while an auto-unlock retry is pending | No queued password typing or screen wake from Watch | Not run |
| P3 | Resume while Watch is distant; then test RSSI between lock and unlock thresholds | No unlock from old signal or intermediate reading; lock delay / signal timeout remains effective | Not run |
| P4 | Resume and bring Watch within unlock threshold | Fresh reading rearms normal proximity behavior | Not run |
| P5 | Pause all devices, then sleep/wake and restart app | Manual pause persists; no automatic lock/unlock; Lock Screen Now and macOS timeout still work | Not run |
| P6 | Bind two devices; pause one; test unlock any/all and lock any/all | Only unpaused devices count; zero active devices causes no action | Not run |
| P7 | Resume one device with no fresh signal while another is close; select unlock all | No unlock until resumed device has a fresh close reading | Not run |
| P8 | Allow recognized UUID rotation while paused; reopen submenu | Pause transfers to new UUID, including after restart | Not run |
| P9 | Open submenu in English and Simplified Chinese; pause/resume repeatedly | Bound device names, actions and persistent pause summary remain clear; status says unknown | Not run |

Cleanup: restore manual pause, device bindings, RSSI settings and timeout settings to their starting values. Quit isolated test app; do not modify the installed production app or its Keychain.
