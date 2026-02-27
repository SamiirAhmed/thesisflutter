@echo off
cd /d "d:\xamp\htdocs\thesisflutter\Backend"
powershell -ExecutionPolicy Bypass -File "d:\xamp\htdocs\thesisflutter\Sync_IP.ps1"
php artisan serve --host=0.0.0.0 --port=8000
