# 1.15.3 release preparation evidence

## Confirmed locally

- 42 manual-pause/action/aggregation assertions passed.
- Update-route tests passed: only Allan-yuwu GitHub release/asset URLs are accepted for pending updates; old upstream pending cache is cleared. Test preferences were isolated under a temporary home.
- Installer fixture executes the actual script against a real signed DMG, at a temporary destination containing spaces, through a local curl wrapper. It validates SHA-256, version, preserved bundle ID and signatures; corrupted and wrong-version payloads are rejected without replacing the installed fixture. No production app is quit or replaced.
- In-app updater harness installed and relaunched synthetic version 9.9.9 in its temporary app, preserving the expected app identity. It did not update the user's production app.
- CLT gate passed: compile, ad-hoc sign, SHA-256/DMG readonly mount/signature checks, isolated 5-second startup. Existing toolchain warnings remain. iCloud metadata workaround uses an identical source copy under `/tmp` only.
- Complete Xcode Release configuration compiled with the local SDK's temporary `MACOSX_DEPLOYMENT_TARGET=12.0` override. This local fixture is **not** the public distribution and does not establish 10.13 runtime compatibility. Public binaries are built by GitHub's macos-26 runner using the repository target.
- Workflow YAML, embedded shell syntax, installer shell syntax, plist metadata and whitespace checks passed.

## Bound-device performance (root agent evidence)

The installed 1.15.3 app was monitored for 60 seconds with one real bound Apple Watch. Thirty samples gave average CPU 0.00%, maximum CPU 0.10%, average RSS 33.97 MB and maximum RSS 41.97 MB. The run observed Bluetooth powered-on / connected / active-mode operation. Automatic locking/unlocking were disabled during the run; original preference keys were explicitly restored and checked, then the app restarted.

This proves only that controlled background performance case. It does not prove actual password entry/automatic unlock, multiple devices, watch charging detection, long-term stability, or all Mac/watchOS versions. Raw logs with device identifiers are not committed.

Two Review/Fix/Test rounds were completed: the first checked fork routing, cache migration and draft/public separation; the second corrected Actions read permissions, master-head race protection, published-release immutability and offline installer failure coverage. Root independently reviewed the source/workflow diff.

## Still required remotely

- PR/master CI at the exact release SHA; the workflow independently verifies a successful master CI run.
- Dispatch on master with authorized v1.15.3 input; draft creation/upload/authenticated checksum re-download, then public publish and anonymous installer verification.
- Record workflow run, tag commit, final asset SHA-256 and actual public availability. Local checks are not proof that the remote workflow or public URL succeeded.

No tag, merge or public release was performed by this source-preparation agent.
