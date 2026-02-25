@echo off
REM ============================================================
REM  Start Flutter Frontend App
REM  Works from ANY location - no hardcoded paths!
REM ============================================================
cd /d "%~dp0"
echo.
echo ========================================
echo   Flutter Frontend - Getting Ready...
echo ========================================
echo.
echo [1/2] Getting Flutter packages...
call flutter pub get
echo.
echo [2/2] Running Flutter app...
echo   (Make sure an emulator or device is connected)
echo.
flutter run
pause
