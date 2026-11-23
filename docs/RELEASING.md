# Allan-yuwu/BLEUnlock 发布流程

## 仓库和身份

- 本 fork 的 `master`、PR、版本 tag、GitHub Release、安装脚本、About 和应用更新均指向 `Allan-yuwu/BLEUnlock`。
- 上游为 `bifrost-proxy/BLEUnlock`，原始项目为 `ts1/BLEUnlock`；保留 MIT 许可证和原作者归属。上游只作为代码来源，不向其发行渠道写入。
- **本 fork 仅发布 GitHub Release，不提供或更新 Homebrew Tap，不需要 TAP_PUSH_TOKEN。**
- 保留主应用 `com.bifrost-proxy.BLEUnlock`、Launcher 和旧身份迁移、偏好、钥匙串与 Application Scripts 目录，避免现有用户丢失设置。仓库地址改变不等于应用身份改变。

## 发布前

1. 用户明确授权公开发布版本号。本次为 `1.15.3`，不是自动发布日常开发分支。
2. 变更通过本 fork 的 PR 合入 `master`，CI 全绿，工作区干净。
3. `CHANGELOG.md` 与 `CHANGELOG.cn.md` 都有精确 `## 1.15.3` 标题；Xcode `MARKETING_VERSION` 与目标版本一致。
4. 验证 `scripts/test-device-pause.sh`、`scripts/test-update-routes.sh`、`scripts/build-local.sh --verify`；使用已签名完整 Release DMG 执行 `scripts/test-install-script.sh path/to/BLEUnlock-v1.15.3.dmg v1.15.3`。该脚本离线拦截下载，执行真实 checksum / mount / signature / copy 检查到临时目录，不触碰 `/Applications`。
5. 阅读 `human_tests/device-pause.md` 与实际验证记录。构建成功不能证明所有 Watch / macOS 组合可靠；发行说明必须标注手动操作、不自动检测佩戴/充电。

## 签名与安全说明

本次 1.15.3 使用 **ad-hoc 签名、未 Apple 公证**。签名完整性和 SHA-256 不能证明开发者身份或无恶意代码。GitHub 上可下载不代表 Apple 官方认证，首次启动可能被 Gatekeeper 阻止。面向用户只需清楚说明这个限制及手动暂停的真实行为；不要称其为 Apple 官方软件。

未来如配置 Developer ID 与公证凭据，workflow 可使用 `MACOS_CERT_P12_BASE64`、`MACOS_CERT_PASSWORD`、`KEYCHAIN_PASSWORD`、`MACOS_SIGNING_IDENTITY` 以及 `APPLE_ID`、`APPLE_TEAM_ID`、`APPLE_APP_PASSWORD`。缺少证书时明确使用 ad-hoc；不能把跳过公证写成公证成功。不要提交任何凭据。

## Dispatch、Tag 与 workflow

推荐在本 fork 的 Actions → Release → Run workflow 中选择 **master**，输入 `v1.15.3`。root 先等该 master 的 CI 成功，再手动启动；workflow 也会查询该 SHA 在 master 的 CI 成功记录。Dispatch checkout master、校验元数据、完整构建和本地验收全部通过后，再次核验远端 master SHA 未在长构建期间前移后，使用仓库 `GITHUB_TOKEN` 创建 annotated tag 与 tag ref，再继续发布。不会从任意功能分支创建 tag，也不会移动已有 tag；GITHUB_TOKEN 创建的 tag 不递归触发额外 workflow。

仍支持从已验收 master 手动推送已有 tag 触发；已有 tag 必须与实际 checkout 对应，且提交已经通过 master CI。版本号仍须用户明确授权。

`.github/workflows/release.yml` 使用仓库自己的 `github.token`，并拒绝在 `Allan-yuwu/BLEUnlock` 之外发布：

1. 校验双语 Changelog、版本、dispatch master／已有 tag 与 HEAD，以及当前 master SHA 的 CI 成功记录。
2. 完整 Xcode Release 构建；签名并检查版本、Bundle ID。
3. 生成 DMG / SHA-256，挂载检查签名；按实际凭据决定是否公证，再更新最终 checksum。
4. 对已校验的本地 DMG 运行实际安装脚本的离线临时目录测试。
5. 本地验收后按需创建 annotated tag；创建 **draft Release**，上传 DMG / checksum，经认证重新下载 draft 产物并检查 SHA-256 与本地产物一致。draft 没有匿名下载地址，不能此时宣称公开可用。
6. 将已验证 draft 公开并设为 Latest。
7. 不提供 GitHub 凭据，通过正式公开下载 URL 运行 `install.sh --version v1.15.3 --no-launch`，安装到 runner 临时目录并复验版本、Bundle ID、签名。
8. 本次新公开的 Release 验收失败时，workflow 保持失败，并尝试撤销 Latest、将 Release 转回 draft。既有公开 Release 只报告验收失败，不修改其状态或附件。公开与撤回之间有短暂可见窗口；必须检查撤回结果，不能掩盖失败。

同一 tag 若仍是 draft 可以安全重跑上传；已经公开的 Release 不覆盖资产、不转回 draft、不重复公开，只验证既有公开下载与安装。已有 tag 若与当前 master 不一致，dispatch 会拒绝，不能移动 tag，应使用新的 patch 版本或通过既有 tag push 路径验收。

## 对外下载与验收

- [本 fork Releases](https://github.com/Allan-yuwu/BLEUnlock/releases) 应存在 `BLEUnlock-v1.15.3.dmg` 与 `.sha256`，不是只有源码归档。
- 验收 checksum、只读挂载、签名、版本 `1.15.3` 与原 Bundle ID；验证 App About、通知链接和检查更新都指向本 fork。
- 安装脚本使用：

```sh
curl -fsSL https://raw.githubusercontent.com/Allan-yuwu/BLEUnlock/master/install.sh | bash
```

临时目录验收必须指定 `--install-dir` 和 `--no-launch`；该模式不会退出现有 `/Applications` 应用。未指定时脚本覆盖正式应用，必须属于用户已授权安装范围。应用更新会校验下载产物后替换重启，旧上游待更新缓存会被清除；相同版本不会再次提示更新。

## 失败处理

- 构建/元数据/签名/上传阶段失败：draft 保留供诊断，不公开；修复后按 tag 是否已公开决定重跑或使用新版本。
- 公开验收失败：检查 workflow 的撤回步骤和实际 Release 状态；撤回也失败时必须向用户报告公开链接和失败原因，由维护者处理，不宣称完成。
- 已公开版本有严重问题：在用户授权范围内撤销 Latest 或转为 draft；不移动公开 tag、不重写既有发布历史。新的修复通过 PR 和新版本发布。

根目录 `release` 是历史脚本，不是本 fork 当前正式入口；`.github/workflows/test-build.yml` 是 master 的打包烟测，不替代目标 tag 的发行门禁。
