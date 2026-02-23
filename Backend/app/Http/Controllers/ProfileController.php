<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\User;

/**
 * ProfileController
 *
 * Returns the authenticated user's full profile from the database.
 * Works for both students and teachers — role is determined from DB.
 *
 * Route: GET /api/v1/me
 * Middleware: auth:sanctum, status
 */
class ProfileController extends Controller
{
    public function me(Request $request)
    {
        $user   = $request->user();
        $userId = (int) $user->user_id;

        // Base user info
        $baseUser = DB::selectOne("
            SELECT u.user_id, u.full_name, u.username, u.status, u.role_id, r.role_name
            FROM   users u
            JOIN   roles r ON u.role_id = r.role_id
            WHERE  u.user_id = ?
            LIMIT  1
        ", [$userId]);

        if (!$baseUser) {
            return response()->json([
                'success' => false,
                'message' => 'User not found.',
            ], 404);
        }

        $roleId    = (int) $baseUser->role_id;
        $isStudent = $roleId === User::ROLE_STUDENT;
        $isTeacher = $roleId === User::ROLE_TEACHER;

        $profile = [
            'user_id'   => $baseUser->user_id,
            'full_name' => $baseUser->full_name ?? $baseUser->username,
            'username'  => $baseUser->username,
            'role_id'   => $roleId,
            'role_name' => $baseUser->role_name,
            'status'    => $baseUser->status,
            'is_leader' => $user->isLeader(),
        ];

        // Student-specific data
        if ($isStudent) {
            $row = DB::selectOne("
                SELECT
                    s.student_id,
                    s.name           AS full_name,
                    s.tell           AS phone,
                    c.cl_name        AS class_name,
                    sem.semister_name AS semester,
                    f.name           AS faculty,
                    d.name           AS department
                FROM students s
                LEFT JOIN studet_classes sc  ON s.std_id     = sc.std_id
                LEFT JOIN classes         c   ON sc.cls_no    = c.cls_no
                LEFT JOIN departments     d   ON c.dept_no    = d.dept_no
                LEFT JOIN faculties       f   ON d.faculty_no = f.faculty_no
                LEFT JOIN semesters       sem ON sc.sem_no    = sem.sem_no
                WHERE s.user_id = ?
                LIMIT 1
            ", [$userId]);

            if ($row) {
                $profile['full_name']  = $row->full_name  ?? $baseUser->username;
                $profile['student_id'] = $row->student_id ?? 'N/A';
                $profile['phone']      = $row->phone      ?? 'N/A';
                $profile['class_name'] = $row->class_name ?? 'N/A';
                $profile['semester']   = $row->semester   ?? 'N/A';
                $profile['faculty']    = $row->faculty    ?? 'N/A';
                $profile['department'] = $row->department ?? 'N/A';
            }
        }

        // Teacher-specific data (table is named "tearchers" in DB)
        if ($isTeacher) {
            $row = DB::selectOne("
                SELECT
                    t.teacher_id,
                    t.name           AS full_name,
                    t.tell           AS phone,
                    j.title          AS specialization,
                    d.name           AS department,
                    f.name           AS faculty
                FROM tearchers t
                LEFT JOIN jobs        j  ON t.job_no      = j.job_no
                LEFT JOIN subject_class sc ON sc.teacher_no = t.teacher_no
                LEFT JOIN classes     cl ON sc.cls_no      = cl.cls_no
                LEFT JOIN departments d  ON cl.dept_no     = d.dept_no
                LEFT JOIN faculties   f  ON d.faculty_no   = f.faculty_no
                WHERE t.user_id = ?
                LIMIT 1
            ", [$userId]);

            if ($row) {
                $profile['full_name']      = $row->full_name      ?? $baseUser->username;
                $profile['teacher_id']     = $row->teacher_id     ?? 'N/A';
                $profile['phone']          = $row->phone          ?? 'N/A';
                $profile['specialization'] = $row->specialization ?? 'N/A';
                $profile['department']     = $row->department     ?? 'N/A';
                $profile['faculty']        = $row->faculty        ?? 'N/A';
            }
        }

        return response()->json([
            'success' => true,
            'profile' => $profile,
        ]);
    }
}
