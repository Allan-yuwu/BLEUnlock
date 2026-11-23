#!/usr/bin/env bash
# Exercise the actual installer with real local DMG/signature checks, offline.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DMG_PATH="${1:?usage: test-install-script.sh signed.dmg vX.Y.Z}"
RELEASE_TAG="${2:?release tag is required}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/bleunlock-install-test.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT
mkdir -p "${WORK_DIR}/bin" "${WORK_DIR}/assets" "${WORK_DIR}/installed app"
ASSET_NAME="BLEUnlock-${RELEASE_TAG}.dmg"
cp "${DMG_PATH}" "${WORK_DIR}/assets/${ASSET_NAME}"
(cd "${WORK_DIR}/assets" && shasum -a 256 "${ASSET_NAME}" > "${ASSET_NAME}.sha256")
cat > "${WORK_DIR}/bin/curl" <<'CURL'
#!/usr/bin/env bash
set -euo pipefail
output=""; url=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) output="$2"; shift 2 ;;
    https://*) url="$1"; shift ;;
    *) shift ;;
  esac
done
[[ -n "$output" && "$url" == "https://github.com/Allan-yuwu/BLEUnlock/releases/download/${TEST_RELEASE_TAG}/"* ]] || exit 91
cp "${TEST_ASSET_DIR}/${url##*/}" "$output"
CURL
cat > "${WORK_DIR}/bin/osascript" <<'BLOCK'
#!/usr/bin/env bash
touch "${TEST_ASSET_DIR}/quit-attempt"
echo 'Temporary installer test must not quit a production app.' >&2
exit 92
BLOCK
chmod +x "${WORK_DIR}/bin/curl" "${WORK_DIR}/bin/osascript"
export TEST_RELEASE_TAG="${RELEASE_TAG}" TEST_ASSET_DIR="${WORK_DIR}/assets"
PATH="${WORK_DIR}/bin:${PATH}" bash "${ROOT_DIR}/install.sh" \
  --version "${RELEASE_TAG}" --install-dir "${WORK_DIR}/installed app" --no-launch
[[ ! -e "${WORK_DIR}/assets/quit-attempt" ]]
codesign --verify --deep --strict "${WORK_DIR}/installed app/BLEUnlock.app"
[[ "$(defaults read "${WORK_DIR}/installed app/BLEUnlock.app/Contents/Info" CFBundleShortVersionString)" == "${RELEASE_TAG#v}" ]]
# A correctly signed package with the wrong app version must also be rejected.
cp "${DMG_PATH}" "${WORK_DIR}/assets/BLEUnlock-v0.0.1.dmg"
(cd "${WORK_DIR}/assets" && shasum -a 256 BLEUnlock-v0.0.1.dmg > BLEUnlock-v0.0.1.dmg.sha256)
if TEST_RELEASE_TAG=v0.0.1 PATH="${WORK_DIR}/bin:${PATH}" bash "${ROOT_DIR}/install.sh" \
  --version v0.0.1 --install-dir "${WORK_DIR}/installed app" --no-launch > "${WORK_DIR}/wrong-version.log" 2>&1; then
  echo 'Wrong app version was unexpectedly accepted.' >&2
  exit 1
fi
grep -q 'expected version 0.0.1' "${WORK_DIR}/wrong-version.log"
# A corrupted download must fail before an installed app is replaced.
printf 'corrupt' >> "${WORK_DIR}/assets/${ASSET_NAME}"
if PATH="${WORK_DIR}/bin:${PATH}" bash "${ROOT_DIR}/install.sh" \
  --version "${RELEASE_TAG}" --install-dir "${WORK_DIR}/installed app" --no-launch > "${WORK_DIR}/corrupt.log" 2>&1; then
  echo 'Corrupted payload was unexpectedly accepted.' >&2
  exit 1
fi
codesign --verify --deep --strict "${WORK_DIR}/installed app/BLEUnlock.app"
echo 'PASS: installer used fork route, installed verified artifact in a path with spaces, and rejected wrong-version/corrupted payloads without replacing it.'
