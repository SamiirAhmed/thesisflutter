#!/bin/bash
# ============================================================
#  Start Laravel Backend Server
#  Works from ANY location - no hardcoded paths!
# ============================================================
cd "$(dirname "$0")"
echo ""
echo "========================================"
echo "  Starting Laravel Backend Server..."
echo "  URL: http://0.0.0.0:8000"
echo "  Press Ctrl+C to stop the server."
echo "========================================"
echo ""
php artisan serve --host=0.0.0.0 --port=8000
