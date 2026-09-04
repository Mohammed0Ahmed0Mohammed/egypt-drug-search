#!/usr/bin/env bash
# CI script: lint + test + build for the Egyptian Drug Search Flutter app.
# Runs the same checks a CI pipeline would run.
set -euo pipefail

cd "$(dirname "$0")"

echo "=== 1. Flutter analyze (lint) ==="
flutter analyze

echo "=== 2. Flutter test ==="
flutter test

echo "=== 3. Flutter build (Linux desktop) ==="
flutter build linux --release

echo "=== ALL CHECKS PASSED ==="
