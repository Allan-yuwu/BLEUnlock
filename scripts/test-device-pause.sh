#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
xcrun swiftc "$ROOT_DIR/BLEUnlock/DeviceParticipation.swift" "$ROOT_DIR/tests/DeviceParticipationTests.swift" -o "$TEST_DIR/device-pause-tests"
"$TEST_DIR/device-pause-tests"
