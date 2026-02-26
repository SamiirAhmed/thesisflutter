@echo off
setlocal
REM ============================================================
REM  Thesis App - Ultimate Manager
REM  Everything in 1 file (Start, Stop, IP Update, Startup)
REM ============================================================

cd /d "%~dp0"
title Thesis App Manager

:menu
cls
echo ============================================================
echo   THESIS APP - ULTIMATE MANAGER (All-in-One)
echo ============================================================
echo.
echo   [1] START APP (Silent/Background)
echo   [2] START APP (Visible Terminals - Debug)
echo   [3] STOP APP (Kill all background services)
echo   [4] SETUP WINDOWS STARTUP (Auto-start on Login)
echo   [5] UPDATE IP ONLY (Sync ApiService.dart)
echo   [6] EXIT
echo.
set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto start_silent
if "%choice%"=="2" goto start_visible
if "%choice%"=="3" goto stop_app
if "%choice%"=="4" goto setup_startup
if "%choice%"=="5" goto update_ip_manual
if "%choice%"=="6" exit
goto menu

:start_silent
echo.
echo Updating IP and starting in background...
powershell -Command "$ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch '127.0.0.1' -and $_.IPAddress -notmatch '^169\.254\.' -and $_.InterfaceAlias -notmatch 'Loopback' -and $_.InterfaceAlias -notmatch 'vEthernet' } | Select-Object -ExpandProperty IPAddress -First 1; if($ip){ $path='frontend/lib/services/api_service.dart'; if(Test-Path $path){ $c = Get-Content $path -Raw; $c = $c -replace 'static const String _pcLanUrl = .*', ('static const String _pcLanUrl = ''http://' + $ip + ':8000'';'); Set-Content -Path $path -Value $c -Encoding UTF8; echo 'IP synced: ' $ip } }"
echo.
echo Launching Laravel and Flutter silently...
powershell -WindowStyle Hidden -Command "Start-Process php -ArgumentList 'artisan serve --host=0.0.0.0 --port=8000' -WorkingDirectory '%~dp0Backend' -WindowStyle Hidden; Start-Process dart -ArgumentList 'run' -WorkingDirectory '%~dp0frontend' -WindowStyle Hidden"
echo Done! App is running in the background.
timeout /t 3 > nul
goto menu

:start_visible
echo.
echo Starting Laravel and Flutter in visible terminal windows...
start "Laravel Backend" cmd /k "cd /d "%~dp0Backend" && php artisan serve --host=0.0.0.0 --port=8000"
timeout /t 3 > nul
start "Flutter Frontend" cmd /k "cd /d "%~dp0frontend" && flutter pub get && flutter run"
goto menu

:stop_app
echo.
echo Stopping all Thesis App services...
taskkill /F /IM php.exe /T 2>nul
taskkill /F /IM dart.exe /T 2>nul
echo Done! Services stopped.
timeout /t 3 > nul
goto menu

:setup_startup
echo.
echo Creating shortcut in Windows Startup folder...
powershell -Command "$s = New-Object -ComObject WScript.Shell; $L = $s.CreateShortcut(\"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Thesis_App.lnk\"); $L.TargetPath = 'cmd.exe'; $L.Arguments = '/c \"%~f0\" 1'; $L.WorkingDirectory = '%~dp0'; $L.WindowStyle = 7; $L.Save(); echo 'Successfully added to Windows Startup!'"
timeout /t 3 > nul
goto menu

:update_ip_manual
echo.
echo Updating IP configuration...
powershell -Command "$ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch '127.0.0.1' -and $_.IPAddress -notmatch '^169\.254\.' -and $_.InterfaceAlias -notmatch 'Loopback' -and $_.InterfaceAlias -notmatch 'vEthernet' } | Select-Object -ExpandProperty IPAddress -First 1; if($ip){ $path='frontend/lib/services/api_service.dart'; if(Test-Path $path){ $c = Get-Content $path -Raw; $c = $c -replace 'static const String _pcLanUrl = .*', ('static const String _pcLanUrl = ''http://' + $ip + ':8000'';'); Set-Content -Path $path -Value $c -Encoding UTF8; echo 'IP updated to: ' $ip } }"
pause
goto menu

REM This part handles the auto-start call
if "%1"=="1" (
    powershell -Command "$ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch '127.0.0.1' -and $_.IPAddress -notmatch '^169\.254\.' -and $_.InterfaceAlias -notmatch 'Loopback' -and $_.InterfaceAlias -notmatch 'vEthernet' } | Select-Object -ExpandProperty IPAddress -First 1; if($ip){ $path='frontend/lib/services/api_service.dart'; if(Test-Path $path){ $c = Get-Content $path -Raw; $c = $c -replace 'static const String _pcLanUrl = .*', ('static const String _pcLanUrl = ''http://' + $ip + ':8000'';'); Set-Content -Path $path -Value $c -Encoding UTF8 } }"
    powershell -WindowStyle Hidden -Command "Start-Process php -ArgumentList 'artisan serve --host=0.0.0.0 --port=8000' -WorkingDirectory '%~dp0Backend' -WindowStyle Hidden; Start-Process dart -ArgumentList 'run' -WorkingDirectory '%~dp0frontend' -WindowStyle Hidden"
    exit
)
