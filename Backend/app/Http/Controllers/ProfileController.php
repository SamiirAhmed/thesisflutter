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
            SELECT u.user_id, u.username, u.status, u.role_id, r.role_name
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
            'full_name' => $baseUser->username,
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
                    s.std_id,
                    s.student_id,
                    s.nira,
                    sh.shiftName AS shift,
                    s.created_at AS entry_time,
                    s.grad_year,
                    s.grade,
                    s.gender,
                    s.pob,
                    s.mother     AS mother_name,
                    s.name       AS full_name,
                    s.tell       AS phone,
                    s.email,
                    IFNULL(p.tell1, 'N/A') AS emergency_contact_parent,
                    c.cl_name    AS class_name,
                    cp.campus    AS campus_name,
                    sem.semister_name AS semester,
                    f.name       AS faculty,
                    d.name       AS department,
                    adr.villages AS address,
                    sch.name     AS school_name
                FROM students s
                LEFT JOIN parents p     ON s.parent_no = p.parent_no
                LEFT JOIN studet_classes sc ON s.std_id = sc.std_id
                LEFT JOIN classes c     ON sc.cls_no = c.cls_no
                LEFT JOIN campuses cp   ON c.camp_no = cp.camp_no
                LEFT JOIN departments d ON c.dept_no = d.dept_no
                LEFT JOIN faculties f   ON d.faculty_no = f.faculty_no
                LEFT JOIN semesters sem ON sc.sem_no = sem.sem_no
                LEFT JOIN address adr   ON s.add_no = adr.add_no
                LEFT JOIN shifts sh     ON s.shift_no = sh.shift_no
                LEFT JOIN school sch    ON s.sch_no = sch.sch_no
                WHERE s.user_id = ?
                LIMIT 1
            ", [$userId]);

            if ($row) {
                $profile = array_merge($profile, (array)$row);
                $profile['emergency_contact'] = $row->phone ?: 'N/A';
                $profile['entry_time'] = ($row->entry_time && $row->entry_time !== 'N/A') ? date('F', strtotime($row->entry_time)) : 'N/A';
                $profile['semester'] = str_ireplace('Semister ', '', $row->semester ?? 'N/A');
                $profile['full_name'] = $row->full_name ?? $baseUser->username;
            }
        }

        // Teacher-specific data (table is named "teachers" in DB)
        if ($isTeacher) {
            $row = DB::selectOne("
                SELECT
                    t.teacher_id,
                    t.name AS full_name,
                    t.tell AS phone,
                    t.specialization,
                    d.name AS department,
                    f.name AS faculty
                FROM teachers t
                LEFT JOIN departments d ON t.dept_no = d.dept_no
                LEFT JOIN faculties f   ON d.faculty_no = f.faculty_no
                WHERE t.user_id = ?
                LIMIT 1
            ", [$userId]);

            if ($row) {
                $profile = array_merge($profile, (array)$row);
                $profile['full_name'] = $row->full_name ?? $baseUser->username;
            }
        }

        return response()->json([
            'success' => true,
            'profile' => $profile,
        ]);
    }
}
