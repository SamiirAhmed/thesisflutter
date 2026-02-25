<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Models\User;

/**
 * AuthService
 *
 * All database-driven authentication and RBAC logic.
 * Stored procedure names are defined as constants — change in one place only.
 */
class AuthService
{
    // ── Stored procedure names (configurable in one place) ─────────────────
    const PROC_LOGIN       = 'login_proc';
    const PROC_DASHBOARD   = 'get_role_dashboard';
    const PROC_MODULES     = 'get_role_modules';
    const PROC_PERMISSIONS = 'get_role_permissions';

    /**
     * Authenticate via stored procedure.
     * Returns the user row as an object, or null on failure.
     */
    public function authenticate(string $identifier, string $pin): ?object
    {
        try {
            $rows = DB::select('CALL ' . self::PROC_LOGIN . '(?, ?)', [$identifier, $pin]);
            return !empty($rows) ? (object) $rows[0] : null;
        } catch (\Exception $e) {
            Log::error('AuthService::authenticate — ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Load the default dashboard for a role from DB.
     */
    public function getDashboard(int $roleId): array
    {
        try {
            $rows = DB::select('CALL ' . self::PROC_DASHBOARD . '(?)', [$roleId]);
            if (!empty($rows)) {
                return (array) $rows[0];
            }
        } catch (\Exception $e) {
            Log::error('AuthService::getDashboard — ' . $e->getMessage());
        }

        // Safe fallback — never hardcode route logic above this line
        return ['key' => 'dashboard', 'title' => 'Dashboard', 'route' => '/dashboard'];
    }

    /**
     * Load visible modules directly from the categories table.
     * Fetches all available categories to drive the dashboard cards.
     */
    public function getModules(int $roleId): array
    {
        try {
            $cats = DB::table('categories')
                ->orderBy('cat_no')
                ->get();

            if ($cats->isEmpty()) {
                return [];
            }

            $iconMap = [
                'exam appeal'        => 'assignment_rounded',
                'class issue'        => 'apartment_rounded',
                'compus enviroment'  => 'home_work_rounded',
                'campus environment' => 'home_work_rounded',
                'report'             => 'analytics_rounded',
                'settings'           => 'settings_suggest_rounded',
            ];

            return $cats->map(function ($cat) use ($iconMap) {
                $name = $cat->cat_name;
                $lower = strtolower(trim($name));
                
                // Deterministic keys and routes based on name
                $baseKey = str_replace(' ', '_', $lower);
                
                return [
                    'key'       => $baseKey,
                    'title'     => $name,
                    'route'     => '/' . $baseKey,
                    'sub_title' => 'Submit and track ' . strtolower($name),
                    'icon_name' => $iconMap[$lower] ?? 'grid_view_rounded',
                ];
            })->toArray();
        } catch (\Exception $e) {
            Log::error('AuthService::getModules — ' . $e->getMessage());
            return [];
        }
    }

    /**
     * Load permission keys for a role from DB.
     * Returns a flat string array, e.g. ["course_appeal.view", "report.view"].
     */
    public function getPermissions(int $roleId): array
    {
        try {
            $rows = DB::select('CALL ' . self::PROC_PERMISSIONS . '(?)', [$roleId]);
            return array_map(
                fn($r) => $r->permission_key ?? $r->name ?? 'view',
                $rows
            );
        } catch (\Exception $e) {
            Log::error('AuthService::getPermissions — ' . $e->getMessage());
            return [];
        }
    }

    /**
     * Load student academic summary from DB joins.
     * Returns null if the user is not a student or has no class enrolled.
     *
     * Table names match the actual DB schema:
     *   students, studet_classes, classes, departments, faculties, semesters
     */
    public function getStudentSummary(int $userId): ?array
    {
        try {
            $row = DB::selectOne("
                SELECT
                    s.student_id,
                    s.name            AS student_name,
                    s.tell            AS phone,
                    c.cl_name         AS class_name,
                    sem.semister_name AS semester,
                    f.name            AS faculty,
                    d.name            AS department
                FROM students s
                LEFT JOIN studet_classes sc  ON s.std_id     = sc.std_id
                LEFT JOIN classes         c   ON sc.cls_no    = c.cls_no
                LEFT JOIN departments     d   ON c.dept_no    = d.dept_no
                LEFT JOIN faculties       f   ON d.faculty_no = f.faculty_no
                LEFT JOIN semesters       sem ON sc.sem_no    = sem.sem_no
                WHERE s.user_id = ?
                LIMIT 1
            ", [$userId]);

            return $row ? (array) $row : null;
        } catch (\Exception $e) {
            Log::error('AuthService::getStudentSummary — ' . $e->getMessage());
            return null;
        }
    }

    public function getTeacherProfile(int $userId): ?array
    {
        try {
            $row = DB::selectOne("
                SELECT
                    t.teacher_id,
                    t.name           AS teacher_name,
                    t.tell           AS phone,
                    t.specialization,
                    d.name           AS department,
                    f.name           AS faculty
                FROM teachers t
                LEFT JOIN departments d   ON t.dept_no    = d.dept_no
                LEFT JOIN faculties   f   ON d.faculty_no = f.faculty_no
                WHERE t.user_id = ?
                LIMIT 1
            ", [$userId]);

            return $row ? (array) $row : null;
        } catch (\Exception $e) {
            Log::error('AuthService::getTeacherProfile — ' . $e->getMessage());
            return null;
        }
    }
}
