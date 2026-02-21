<?php
/**
 * api_login.php
 * 
 * Handles authentication for the University Appeal & Complaint Management System.
 * Also includes management tools (accessible via GET ?tool=...).
 */

$host = "127.0.0.1";
$user = "root";
$pass = "";
$db   = "thesisdb";

// ── MANAGEMENT TOOLS (GET REQUESTS) ──────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['tool'])) {
    $conn = new mysqli($host, $user, $pass, $db);
    $tool = $_GET['tool'];
    echo "<pre>";
    
    switch ($tool) {
        case 'check_pass':
            $res = $conn->query("SELECT username, password_hash FROM users WHERE username IN ('STU260001', 'admin')");
            while($row = $res->fetch_assoc()) echo $row['username'] . ": " . $row['password_hash'] . "\n";
            break;
            
        case 'list_roles':
            $res = $conn->query("SELECT * FROM roles");
            while($row = $res->fetch_assoc()) print_r($row);
            break;
            
        case 'fix_roles':
            $conn->query("UPDATE roles SET role_name='Student', description='University Student' WHERE role_id=1");
            $conn->query("UPDATE roles SET role_name='Teacher', description='University Teacher' WHERE role_id=2");
            echo "Roles updated.\n";
            break;
            
        case 'count_users':
            $res = $conn->query("SELECT role_id, COUNT(*) as count FROM users GROUP BY role_id");
            while($row = $res->fetch_assoc()) print_r($row);
            break;
            
        default:
            echo "Unknown tool. Available: check_pass, list_roles, fix_roles, count_users";
    }
    echo "</pre>";
    exit;
}

// ── AUTHENTICATION API (POST REQUESTS) ───────────────────────────────────────
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

    if (!$dbUser) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Incorrect User ID or PIN. Please check and try again.']);
        exit;
    }

    $roleId   = (int) ($dbUser['role_id'] ?? 0);
    $roleName = strtolower($dbUser['role_name'] ?? '');
    $isStudent = ($roleId === 1 || $roleName === 'student');
    $isTeacher = ($roleId === 2 || $roleName === 'teacher');

    if (!$isStudent && !$isTeacher) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Access denied. Only students and teachers allowed.']);
        exit;
    }

    $check_stmt = $conn->prepare("SELECT status FROM users WHERE user_id = ?");
    if ($check_stmt) {
        $check_stmt->bind_param("i", $dbUser['user_id']);
        $check_stmt->execute();
        $status_row = $check_stmt->get_result()->fetch_assoc();
        $check_stmt->close();
        $statusRaw = trim($status_row['status'] ?? 'InActive');
        if ($statusRaw !== 'Active') {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Your account is inactive. Please contact the administrator.']);
            exit;
        }
    }

    // RBAC
    $dashboard = null; $modules = []; $permissions = [];
    $stmt = $conn->prepare("CALL get_role_dashboard(?)");
    if ($stmt) { $stmt->bind_param("i", $roleId); $stmt->execute(); $dashboard = $stmt->get_result()->fetch_assoc(); $stmt->close(); if ($conn->more_results()) $conn->next_result(); }
    $stmt = $conn->prepare("CALL get_role_modules(?)");
    if ($stmt) { $stmt->bind_param("i", $roleId); $stmt->execute(); $m = $stmt->get_result()->fetch_all(MYSQLI_ASSOC); $modules = array_slice($m, 0, 3); $stmt->close(); if ($conn->more_results()) $conn->next_result(); }
    $stmt = $conn->prepare("CALL get_role_permissions(?)");
    if ($stmt) { $stmt->bind_param("i", $roleId); $stmt->execute(); $p = $stmt->get_result()->fetch_all(MYSQLI_ASSOC); $permissions = array_map(fn($x) => $x['permission_key'] ?? $x['name'] ?? 'view', $p); $stmt->close(); if ($conn->more_results()) $conn->next_result(); }

    $studentSummary = null;
    if ($isStudent) {
        $std_stmt = $conn->prepare("
            SELECT 
                s.name AS student_name, 
                s.student_id, 
                c.cl_name AS class_name, 
                sem.semister_name AS semester, 
                f.name AS faculty, 
                d.name AS department,
                sh.shiftName AS shift
            FROM students s 
            LEFT JOIN studet_classes sc ON s.std_id = sc.std_id 
            LEFT JOIN classes c ON sc.cls_no = c.cls_no 
            LEFT JOIN departments d ON c.dept_no = d.dept_no 
            LEFT JOIN faculties f ON d.faculty_no = f.faculty_no 
            LEFT JOIN semesters sem ON sc.sem_no = sem.sem_no 
            LEFT JOIN shifts sh ON s.shift_no = sh.shift_no
            WHERE s.user_id = ? 
            LIMIT 1
        ");
        if ($std_stmt) { $std_stmt->bind_param("i", $dbUser['user_id']); $std_stmt->execute(); $studentRow = $std_stmt->get_result()->fetch_assoc(); $std_stmt->close(); if ($studentRow) { $studentSummary = $studentRow; } }
    }

    $teacherProfile = null;
    if ($isTeacher) {
        $tch_stmt = $conn->prepare("SELECT t.teacher_id, t.name AS teacher_name, t.tell AS phone, t.specialization, d.name AS department, f.name AS faculty FROM teachers t LEFT JOIN departments d ON t.dept_no = d.dept_no LEFT JOIN faculties f ON d.faculty_no = f.faculty_no WHERE t.user_id = ? LIMIT 1");
        if ($tch_stmt) { $tch_stmt->bind_param("i", $dbUser['user_id']); $tch_stmt->execute(); $teacherProfile = $tch_stmt->get_result()->fetch_assoc(); $tch_stmt->close(); }
    }

    $displayName = $isStudent ? ($studentSummary['student_name'] ?? $dbUser['username']) : ($teacherProfile['teacher_name'] ?? $dbUser['username']);

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
    echo json_encode(['success' => false, 'message' => 'An error occurred.']);
}
