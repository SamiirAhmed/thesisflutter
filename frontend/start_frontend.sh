#!/bin/bash
# ============================================================
#  Start Flutter Frontend App
#  Works from ANY location - no hardcoded paths!
# ============================================================
cd "$(dirname "$0")"
echo ""
echo "========================================"
echo "  Flutter Frontend - Getting Ready..."
echo "========================================"
echo ""
echo "[1/2] Getting Flutter packages..."
flutter pub get
echo ""
echo "[2/2] Running Flutter app..."
echo "  (Make sure an emulator or device is connected)"
echo ""
flutter run
