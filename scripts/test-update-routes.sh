#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
mkdir -p "$WORK_DIR/test-home"
xcrun swiftc -framework Cocoa "$ROOT_DIR/BLEUnlock/checkUpdate.swift" "$ROOT_DIR/tests/UpdateRouteTests.swift" -o "$WORK_DIR/update-route-tests"
CFFIXED_USER_HOME="$WORK_DIR/test-home" "$WORK_DIR/update-route-tests"
