# 🎓 University Student Appeal & Complaint System

A full-stack application for university students to submit exam appeals and class complaints.

- **Backend:** Laravel (PHP)
- **Frontend:** Flutter (Dart)
- **Database:** MySQL

> ⚡ **This project works with ANY code editor** — VS Code, IntelliJ IDEA, Android Studio, Sublime Text, Notepad++, or even just the command line!

---

## 📋 Prerequisites

Before you start, make sure you have these installed:

| Tool | Version | Download |
|------|---------|----------|
| **PHP** | 8.1+ | [php.net](https://www.php.net/downloads) or via XAMPP |
| **Composer** | 2.x | [getcomposer.org](https://getcomposer.org/) |
| **Flutter** | 3.x+ | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| **MySQL** | 5.7+ | [mysql.com](https://dev.mysql.com/downloads/) or via XAMPP |
| **XAMPP** (optional) | Latest | [apachefriends.org](https://www.apachefriends.org/) |

### Verify Installation
Open a terminal/command prompt and run:
```bash
php --version
composer --version
flutter --version
mysql --version
```

---

## 🚀 Quick Start (Any Editor)

### Option 1: One-Click Start (Windows)
Just **double-click** the `Start_All.bat` file in the project root!
This will start both the backend and frontend automatically.

### Option 2: Manual Start (Any OS)

#### Step 1: Setup Database
1. Start MySQL (via XAMPP or standalone)
2. Create a database called `thesispro`
3. Import the database from the `Database/` folder

#### Step 2: Start Backend
**Windows:**
```cmd
cd Backend
Start_Backend.bat
```
**Linux/Mac:**
```bash
cd Backend
chmod +x start_backend.sh
./start_backend.sh
```
**Or manually (any OS):**
```bash
cd Backend
composer install
php artisan serve --host=0.0.0.0 --port=8000
```
The backend will be available at `http://localhost:8000`

#### Step 3: Start Frontend
**Windows:**
```cmd
cd frontend
Start_Frontend.bat
```
**Linux/Mac:**
```bash
cd frontend
chmod +x start_frontend.sh
./start_frontend.sh
```
**Or manually (any OS):**
```bash
cd frontend
flutter pub get
flutter run
```

---

## 📁 Project Structure

```
thesisflutter/
├── Backend/                 # Laravel Backend API
│   ├── app/                 # Application code
│   │   ├── Http/Controllers # API Controllers
│   │   ├── Models/          # Database Models
│   │   └── Services/        # Business Logic
│   ├── config/              # Laravel configuration
│   ├── database/            # Migrations & Seeds
│   ├── routes/              # API Routes
│   ├── .env                 # Environment config (DB credentials, etc.)
│   ├── Start_Backend.bat    # Windows: Start backend server
│   └── start_backend.sh     # Linux/Mac: Start backend server
│
├── frontend/                # Flutter Mobile App
│   ├── lib/                 # Dart source code
│   │   ├── screens/         # App screens (Login, Dashboard, etc.)
│   │   ├── services/        # API service layer
│   │   ├── widgets/         # Reusable UI widgets
│   │   └── main.dart        # App entry point
│   ├── assets/              # Images and other assets
│   ├── android/             # Android-specific config
│   ├── pubspec.yaml         # Flutter dependencies
│   ├── Start_Frontend.bat   # Windows: Start Flutter app
│   └── start_frontend.sh    # Linux/Mac: Start Flutter app
│
├── Database/                # Database SQL files
├── Start_All.bat            # Windows: Start everything at once
└── README.md                # This file
```

---

## ⚙️ Configuration

### Backend (.env)
The backend configuration is in `Backend/.env`. Key settings:
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=thesispro
DB_USERNAME=root
DB_PASSWORD=
```

### Frontend (API URL)
The Flutter app connects to the backend via `frontend/lib/services/api_service.dart`.

**For Android Emulator:** The app uses `http://10.0.2.2:8000` automatically (maps to your PC's localhost).

**For Real Device:** Update the `_pcLanUrl` in `api_service.dart` with your PC's local IP:
```dart
static const String _pcLanUrl = 'http://YOUR_PC_IP:8000';
```
To find your PC's IP, run: `ipconfig` (Windows) or `ifconfig` (Linux/Mac).

---

## 🔧 Using With Different Editors

### VS Code
1. Open the `thesisflutter` folder
2. Use the integrated terminal to run commands
3. Install the **Dart** and **Flutter** extensions for better editing

### Android Studio / IntelliJ IDEA
1. Open the `frontend` folder as a Flutter project
2. Open a separate terminal for the backend
3. Run backend: `cd Backend && php artisan serve --host=0.0.0.0 --port=8000`

### Sublime Text / Notepad++ / Any Other Editor
1. Edit files with your preferred editor
2. Use a separate terminal/command prompt window
3. Run the `.bat` scripts (Windows) or `.sh` scripts (Linux/Mac)

### Command Line Only (No Editor)
```bash
# Terminal 1 - Backend
cd Backend
php artisan serve --host=0.0.0.0 --port=8000

# Terminal 2 - Frontend
cd frontend
flutter pub get
flutter run
```

---

## ❓ Troubleshooting

### "Connection timed out after 5s"
1. Make sure the backend server is running (`php artisan serve --host=0.0.0.0 --port=8000`)
2. Make sure MySQL is running with the `thesispro` database
3. If using a real device, check that `_pcLanUrl` in `api_service.dart` has the correct PC IP
4. Check Windows Firewall allows port 8000

### "composer install" fails
- Make sure PHP is in your system PATH
- Run `php --version` to verify

### "flutter pub get" fails
- Make sure Flutter is in your system PATH
- Run `flutter doctor` to check setup

### Backend shows PHP errors
- Check `Backend/.env` has correct database credentials
- Run `cd Backend && php artisan config:clear`

---

## 📜 License

This project is part of a university thesis.