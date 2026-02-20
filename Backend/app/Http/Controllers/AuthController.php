<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use App\Services\AuthService;
use App\Models\User;

/**
 * AuthController
 *
 * Handles login and logout for the University Portal mobile app.
 * All validation is database-driven — no role/permission logic is hardcoded here.
 */
class AuthController extends Controller
{
    public function __construct(private AuthService $authService) {}

    // ── POST /api/v1/auth/login ────────────────────────────────────────────────
    public function login(Request $request)
    {
        // 1. Validate request fields
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|string',
            'pin'     => 'required|string',
            'channel' => 'required|in:APP,WEB',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $identifier = trim($request->user_id);
        $pin        = $request->pin;
        $channel    = strtoupper($request->channel);

        // 2. Authenticate via stored procedure (DB-driven — no hardcoding)
        $dbUser = $this->authService->authenticate($identifier, $pin);

        if (!$dbUser) {
            return response()->json([
                'success' => false,
                'message' => 'Incorrect User ID or PIN. Please check and try again.',
            ], 401);
        }

        $roleId   = (int) ($dbUser->role_id ?? 0);
        $roleName = trim($dbUser->role_name ?? '');

        // 3. Account status check — must be "Active"
        $status = $dbUser->status ?? '';
        if (strtolower($status) !== 'active') {
            return response()->json([
                'success' => false,
                'message' => 'Your account is ' . ucfirst(strtolower($status ?: 'Inactive'))
                    . '. Please contact the university administration.',
            ], 403);
        }

        // 4. Role restriction — only Student and Teacher for the mobile app
        //    Role IDs from DB: Student=6, Teacher=7
        $isStudent = ($roleId === User::ROLE_STUDENT || strtolower($roleName) === 'student');
        $isTeacher = ($roleId === User::ROLE_TEACHER || strtolower($roleName) === 'teacher');

        if (!$isStudent && !$isTeacher) {
            return response()->json([
                'success' => false,
                'message' => 'This app can be used only by students and teachers.',
            ], 403);
        }

        // 5. Access channel check from DB column (column spelled "Accees_channel")
        $dbChannel = strtoupper(
            $dbUser->Accees_channel
            ?? $dbUser->access_channel
            ?? $dbUser->Accees_channel
            ?? 'BOTH'
        );

        // Empty string or null defaults to BOTH
        if (empty($dbChannel)) {
            $dbChannel = 'BOTH';
        }

        $allowed = match ($dbChannel) {
            'APP'  => ['APP'],
            'WEB'  => ['WEB'],
            'BOTH' => ['APP', 'WEB'],
            default => ['APP', 'WEB'],
        };

        if (!in_array($channel, $allowed, true)) {
            $channelLabel = $channel === 'APP' ? 'mobile app' : 'web portal';
            return response()->json([
                'success' => false,
                'message' => "Your account is not allowed to access the {$channelLabel}. "
                    . "Please use the " . ($channel === 'APP' ? 'web portal' : 'mobile app') . '.',
            ], 403);
        }

        // 6. Load RBAC data from DB (dashboard, modules, permissions)
        $dashboard   = $this->authService->getDashboard($roleId);
        $modules     = $this->authService->getModules($roleId);
        $permissions = $this->authService->getPermissions($roleId);

        // 7. Load role-specific profile data
        $studentSummary = $isStudent
            ? $this->authService->getStudentSummary((int) $dbUser->user_id)
            : null;

        $teacherProfile = $isTeacher
            ? $this->authService->getTeacherProfile((int) $dbUser->user_id)
            : null;

        // 8. Find the Laravel User for Sanctum token issuance
        $user = User::where('user_id', $dbUser->user_id)->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User record not found. Please contact administration.',
            ], 500);
        }

        // Sync live fields from DB result onto the model instance
        $user->forceFill([
            'role_id'   => $roleId,
            'status'    => $status,
        ]);
        // Store role_name transiently (not a DB column on users, comes from roles table)
        $user->role_name = $roleName;

        // 9. Token policy — one active token per channel
        //    Revoke only tokens that belong to this channel, keep others intact.
        $user->tokens()
            ->where('name', $channel)
            ->delete();

        // Issue new Sanctum token with permission abilities
        $token = $user->createToken($channel, $permissions)->plainTextToken;

        // 10. Build success response
        $displayName = $teacherProfile['teacher_name']
            ?? $studentSummary['student_name']
            ?? $dbUser->full_name
            ?? $dbUser->username
            ?? $identifier;

        return response()->json([
            'success' => true,
            'message' => 'Login successful.',
            'token'   => $token,
            'data'    => [
                'user_id'         => (int) $dbUser->user_id,
                'username'        => $dbUser->username ?? $identifier,
                'name'            => $displayName,
                'role_id'         => $roleId,
                'role_name'       => $isStudent ? 'Student' : 'Teacher',
                'status'          => $status,
                'access_channel'  => $dbChannel,
                'student_summary' => $studentSummary,
                'teacher_profile' => $teacherProfile,
                'dashboard'       => $dashboard,
                'modules'         => $modules,
                'permissions'     => $permissions,
            ],
        ]);
    }

    // ── POST /api/v1/auth/logout ───────────────────────────────────────────────
    public function logout(Request $request)
    {
        // Revoke only the current token (channel-aware)
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully.',
        ]);
    }
}
