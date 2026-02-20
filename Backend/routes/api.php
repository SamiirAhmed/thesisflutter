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

        // Logout — revokes current token only (channel-aware)
        Route::post('/auth/logout',      [AuthController::class, 'logout']);

        // ── Appeals (permission-gated) ────────────────────────────────────
        Route::middleware('perm:course_appeal.view')
            ->get('/appeals', fn() => response()->json([
                'success' => true,
                'message' => 'Appeals endpoint — coming soon.',
                'data'    => [],
            ]));

        // ── Reports (permission-gated) ────────────────────────────────────
        Route::middleware('perm:report.view')
            ->get('/reports', fn() => response()->json([
                'success' => true,
                'message' => 'Reports endpoint — coming soon.',
                'data'    => [],
            ]));
    });
});
