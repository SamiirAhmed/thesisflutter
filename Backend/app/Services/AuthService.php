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
     * Load visible modules for a role from DB.
     * Caps at 3 as per system requirement.
     */
    public function getModules(int $roleId): array
    {
        try {
            $rows = DB::select('CALL ' . self::PROC_MODULES . '(?)', [$roleId]);
            // Enforce max-3 categories — system requirement
            return array_slice(array_map(fn($r) => (array) $r, $rows), 0, 3);
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

    /**
     * Load teacher info from DB.
     *
     * NOTE: The DB table is named "tearchers" (with a typo).
     *       We use that exact spelling to match the real schema.
     *       Teacher does NOT have a specialization column;
     *       instead they have job_no → jobs.title.
     */
    public function getTeacherProfile(int $userId): ?array
    {
        try {
            $row = DB::selectOne("
                SELECT
                    t.teacher_id,
                    t.name           AS teacher_name,
                    t.tell           AS phone,
                    j.title          AS specialization,
                    d.name           AS department,
                    f.name           AS faculty
                FROM tearchers t
                LEFT JOIN jobs        j ON t.job_no      = j.job_no
                LEFT JOIN subject_class sc ON sc.teacher_no = t.teacher_no
                LEFT JOIN classes     cl  ON sc.cls_no     = cl.cls_no
                LEFT JOIN departments d   ON cl.dept_no    = d.dept_no
                LEFT JOIN faculties   f   ON d.faculty_no  = f.faculty_no
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
