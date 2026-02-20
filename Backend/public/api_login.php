<?php
/**
 * api_login.php
 * 
 * Handles authentication for the University Appeal & Complaint Management System.
 * Validates students and teachers directly from the database.
 * Enforces Active/Inactive status. Restricts access to students and teachers only.
 */

$host = "127.0.0.1";
$user = "root";
$pass = "";
$db   = "thesisdb";

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$input  = json_decode(file_get_contents('php://input'), true);
$userId = trim($input['user_id'] ?? '');
$pin    = trim($input['pin'] ?? '');

if ($userId === '' || $pin === '') {
    http_response_code(422);
    echo json_encode(['success' => false, 'message' => 'Please enter your User ID and PIN.']);
    exit;
}

mysqli_report(MYSQLI_REPORT_OFF);

try {
    $conn = new mysqli($host, $user, $pass, $db);
    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database connection failed. Please try again later.']);
        exit;
    }

    // ── Step 1: Authenticate via stored procedure ─────────────────────────────
    $stmt = $conn->prepare("CALL login_proc(?, ?)");
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Authentication service unavailable. Contact admin.']);
        exit;
    }

    $stmt->bind_param("ss", $userId, $pin);
    $stmt->execute();
    $result = $stmt->get_result();
    $dbUser = $result ? $result->fetch_assoc() : null;
    $stmt->close();
    if ($conn->more_results()) $conn->next_result();

    // ── Step 2: Validate credentials ─────────────────────────────────────────
    if (!$dbUser) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Incorrect User ID or PIN. Please check and try again.']);
        exit;
    }

    // ── Step 3: Role restriction — only students (1) and teachers (2) ─────────
    $roleId   = (int) ($dbUser['role_id'] ?? 0);
    $roleName = strtolower($dbUser['role_name'] ?? '');

    $isStudent = ($roleId === 1 || $roleName === 'student');
    $isTeacher = ($roleId === 2 || $roleName === 'teacher');

    if (!$isStudent && !$isTeacher) {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'Access denied. This app can be used only by students and teachers.'
        ]);
        exit;
    }

    // ── Step 4: Active / Inactive status check ────────────────────────────────
    $status = strtoupper($dbUser['status'] ?? '');
    if ($status !== 'ACTIVE') {
        http_response_code(403);
        echo json_encode([
            'success' => false,
            'message' => 'Your account is currently ' . ucfirst(strtolower($status ?: 'Inactive')) . '. Please contact the university administration to activate your account.'
        ]);
        exit;
    }

    // ── Step 5: Load RBAC — Dashboard, Modules (max 3), Permissions ──────────
    $dashboard   = null;
    $modules     = [];
    $permissions = [];

    // Dashboard
    $stmt = $conn->prepare("CALL get_role_dashboard(?)");
    if ($stmt) {
        $stmt->bind_param("i", $roleId);
        $stmt->execute();
        $dashboard = $stmt->get_result()->fetch_assoc();
        $stmt->close();
        if ($conn->more_results()) $conn->next_result();
    }

    // Modules — limit to 3 as per requirement
    $stmt = $conn->prepare("CALL get_role_modules(?)");
    if ($stmt) {
        $stmt->bind_param("i", $roleId);
        $stmt->execute();
        $allModules = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $modules    = array_slice($allModules, 0, 3); // Strictly max 3 categories
        $stmt->close();
        if ($conn->more_results()) $conn->next_result();
    }

    // Permissions
    $stmt = $conn->prepare("CALL get_role_permissions(?)");
    if ($stmt) {
        $stmt->bind_param("i", $roleId);
        $stmt->execute();
        $permsRaw    = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $permissions = array_map(fn($p) => $p['permission_key'] ?? $p['name'] ?? 'view', $permsRaw);
        $stmt->close();
        if ($conn->more_results()) $conn->next_result();
    }

    // ── Step 6: Student-specific summary (from database only) ────────────────
    $studentSummary = null;
    $studentProfile = null;

    if ($isStudent) {
        $std_stmt = $conn->prepare("
            SELECT
                s.std_id,
                s.student_id,
                s.name      AS student_name,
                c.cl_name   AS class_name,
                sem.semister_name AS semester,
                f.name      AS faculty,
                d.name      AS department
            FROM students s
            LEFT JOIN studet_classes sc ON s.std_id = sc.std_id
            LEFT JOIN classes         c  ON sc.cls_no = c.cls_no
            LEFT JOIN departments     d  ON c.dept_no = d.dept_no
            LEFT JOIN faculties       f  ON d.faculty_no = f.faculty_no
            LEFT JOIN semesters       sem ON sc.sem_no = sem.sem_no
            WHERE s.user_id = ?
            LIMIT 1
        ");
        if ($std_stmt) {
            $std_stmt->bind_param("i", $dbUser['user_id']);
            $std_stmt->execute();
            $studentRow = $std_stmt->get_result()->fetch_assoc();
            $std_stmt->close();

            if ($studentRow) {
                $studentSummary = [
                    'student_name' => $studentRow['student_name'] ?? 'N/A',
                    'student_id'   => $studentRow['student_id']   ?? 'N/A',
                    'class_name'   => $studentRow['class_name']   ?? 'N/A',
                    'semester'     => $studentRow['semester']     ?? 'N/A',
                    'faculty'      => $studentRow['faculty']      ?? 'N/A',
                    'department'   => $studentRow['department']   ?? 'N/A',
                ];
            }
        }
    }

    // ── Step 7: Teacher-specific profile ─────────────────────────────────────
    $teacherProfile = null;
    if ($isTeacher) {
        $tch_stmt = $conn->prepare("
            SELECT
                t.teacher_id,
                t.name         AS teacher_name,
                t.tell         AS phone,
                t.specialization,
                d.name         AS department,
                f.name         AS faculty
            FROM teachers t
            LEFT JOIN departments d ON t.dept_no = d.dept_no
            LEFT JOIN faculties   f ON d.faculty_no = f.faculty_no
            WHERE t.user_id = ?
            LIMIT 1
        ");
        if ($tch_stmt) {
            $tch_stmt->bind_param("i", $dbUser['user_id']);
            $tch_stmt->execute();
            $teacherProfile = $tch_stmt->get_result()->fetch_assoc();
            $tch_stmt->close();
        }
    }

    // Determine the display name
    $displayName = $isStudent
        ? ($studentSummary ? $studentSummary['student_name'] : $dbUser['username'])
        : ($teacherProfile ? $teacherProfile['teacher_name'] ?? $dbUser['username'] : $dbUser['username']);

    // ── Step 8: Build response ────────────────────────────────────────────────
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'token'   => bin2hex(random_bytes(20)),
        'data'    => [
            'user_id'         => $dbUser['user_id'],
            'username'        => $dbUser['username'],
            'name'            => $displayName,
            'role_id'         => $roleId,
            'role_name'       => $isStudent ? 'Student' : 'Teacher',
            'status'          => $dbUser['status'],
            'student_summary' => $studentSummary,
            'teacher_profile' => $teacherProfile,
            'dashboard'       => $dashboard ?: ['key' => 'main', 'title' => 'Dashboard', 'route' => '/dashboard'],
            'modules'         => $modules,
            'permissions'     => $permissions,
        ]
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'An unexpected error occurred. Please try again.']);
}
