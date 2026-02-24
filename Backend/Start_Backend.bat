@echo off
cd /d D:\xamp\htdocs\thesisflutter\Backend
echo Starting Laravel Backend Server...
php artisan serve --host=0.0.0.0 --port=8000
pause
