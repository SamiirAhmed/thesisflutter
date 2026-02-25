@echo off
REM ============================================================
REM  Start Both Backend + Frontend
REM  Works from ANY code editor - just double-click!
REM ============================================================
cd /d "%~dp0"
echo.
echo ========================================
echo   Starting Full Application...
echo   Backend: Laravel (port 8000)
echo   Frontend: Flutter
echo ========================================
echo.

REM Start backend in a separate terminal window
echo [1/2] Starting Backend Server...
start "Laravel Backend" cmd /k "cd /d "%~dp0Backend" && php artisan serve --host=0.0.0.0 --port=8000"

REM Wait a moment for the backend to start
timeout /t 3 /nobreak > nul

REM Start frontend in a separate terminal window
echo [2/2] Starting Flutter Frontend...
start "Flutter Frontend" cmd /k "cd /d "%~dp0frontend" && flutter pub get && flutter run"

echo.
echo ========================================
echo   Both servers are starting!
echo   Backend: http://localhost:8000
echo   Check the new terminal windows.
echo ========================================
echo.
pause
