<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ProfileController;

/*
|--------------------------------------------------------------------------
| API Routes — University Student Appeal & Complaint System
| Version: v1
| Base URL: http://localhost:8000/api/v1  (or 10.0.2.2:8000 from emulator)
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->group(function () {

    // ── Public health-check ──────────────────────────────────────────────────
    Route::get('/test', fn() => response()->json([
        'success' => true,
        'message' => 'API v1 is running.',
        'timestamp' => now()->toIso8601String(),
    ]));

    // ── Authentication (no guard required) ──────────────────────────────────
    Route::prefix('auth')->group(function () {
        Route::post('/login',  [AuthController::class, 'login']);
    });

    // ── Protected routes (Sanctum + active account required) ────────────────
    Route::middleware(['auth:sanctum', 'status'])->group(function () {

        // Profile
        Route::get('/me',                [ProfileController::class, 'me']);

        // Classroom Issues
        Route::prefix('class-issues')->group(function () {
            Route::get('/types',       [\App\Http\Controllers\class_issue\ClassIssueController::class, 'getIssueTypes']);
            Route::get('/my-classes',  [\App\Http\Controllers\class_issue\ClassIssueController::class, 'getMyClasses']);
            Route::post('/submit',     [\App\Http\Controllers\class_issue\ClassIssueController::class, 'submitIssue']);
            Route::get('/my-issues',   [\App\Http\Controllers\class_issue\ClassIssueController::class, 'getMyClassIssues']);
            Route::get('/tracking/{id}', [\App\Http\Controllers\class_issue\ClassIssueController::class, 'getIssueTracking']);
            Route::post('/update-status', [\App\Http\Controllers\class_issue\ClassIssueController::class, 'updateStatus']);
        });

        // Exam Appeals
        Route::prefix('exam')->group(function () {
            Route::get('/subjects',    [\App\Http\Controllers\Exam\ExamController::class, 'getSubjects']);
            Route::post('/submit',     [\App\Http\Controllers\Exam\ExamController::class, 'submitAppeal']);
            Route::get('/track',       [\App\Http\Controllers\Exam\ExamController::class, 'trackAppeal']);
        });

        // Logout — revokes current token only (channel-aware)
        Route::post('/auth/logout',      [AuthController::class, 'logout']);


    });
});
