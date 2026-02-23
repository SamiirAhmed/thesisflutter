<?php
/**
 * api_login.php - Handles User Authentication and Management Tools.
 */

$host = "127.0.0.1";
$user = "root";
$pass = "";
$db   = "thesisdb";

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-USER-ID');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

mysqli_report(MYSQLI_REPORT_OFF);
$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed.']);
    exit;
}

// ── MANAGEMENT TOOLS (GET) ──────────────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['tool'])) {
    header('Content-Type: text/plain');
    $tool = $_GET['tool'];
    echo "--- MANAGEMENT TOOL: $tool ---\n\n";
    switch ($tool) {
        case 'check_pass':
            $res = $conn->query("SELECT username, password_hash FROM users WHERE username IN ('STU260001', 'admin')");
            while($row = $res->fetch_assoc()) echo $row['username'] . ": " . $row['password_hash'] . "\n";
            break;
        case 'list_roles':
            $res = $conn->query("SELECT * FROM roles");
            while($row = $res->fetch_assoc()) print_r($row);
            break;
        case 'all_users':
            echo "--- TEACHERS ---\n";
            $res = $conn->query("SELECT u.username, u.password_hash, t.teacher_id, u.Accees_channel FROM users u JOIN teachers t ON u.user_id = t.user_id");
            while($row = $res->fetch_assoc()) echo "ID: " . $row['teacher_id'] . " | User: " . $row['username'] . " | Pass: " . $row['password_hash'] . "\n";
            echo "\n--- STUDENTS ---\n";
            $res = $conn->query("SELECT s.student_id, u.username, u.password_hash, s.email FROM users u JOIN students s ON u.user_id = s.user_id");
            while($row = $res->fetch_assoc()) echo "ID: " . $row['student_id'] . " | User: " . $row['username'] . " | Pass: " . $row['password_hash'] . "\n";
            break;
        case 'make_hash':
            $pin = $_GET['pin'] ?? '123456';
            echo "PIN: $pin\nHASH: " . password_hash($pin, PASSWORD_BCRYPT);
            break;
        default:
            echo "Unknown tool.";
    }
    exit;
}

// ── LOGIN API (POST) ────────────────────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input  = json_decode(file_get_contents('php://input'), true);
    $userId = trim($input['user_id'] ?? '');
    $pin    = trim($input['pin'] ?? '');

    if ($userId === '' || $pin === '') {
        http_response_code(422);
        echo json_encode(['success' => false, 'message' => 'User ID and PIN required.']);
        exit;
    }

    try {
        $stmt = $conn->prepare("CALL login_proc(?, ?)");
        $stmt->bind_param("ss", $userId, $pin);
        $stmt->execute();
        $dbUser = $stmt->get_result()->fetch_assoc();
        $stmt->close();
        if ($conn->more_results()) $conn->next_result();

        if (!$dbUser || $pin !== ($dbUser['password_hash'] ?? '')) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Incorrect User ID or PIN.']);
            exit;
        }

        if (trim($dbUser['status'] ?? '') !== 'Active') {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Your account is inactive.']);
            exit;
        }

        $roleId = (int) $dbUser['role_id'];
        $isStudent = ($roleId === 1 || $roleId === 6);
        $isTeacher = ($roleId === 2);

        // RBAC
        $dashboard = null; $modules = []; $permissions = [];
        $stmt = $conn->prepare("CALL get_role_dashboard(?)");
        if ($stmt) { $stmt->bind_param("i", $roleId); $stmt->execute(); $dashboard = $stmt->get_result()->fetch_assoc(); $stmt->close(); if ($conn->more_results()) $conn->next_result(); }
        $stmt = $conn->prepare("CALL get_role_modules(?)");
        if ($stmt) { $stmt->bind_param("i", $roleId); $stmt->execute(); $modules = array_slice($stmt->get_result()->fetch_all(MYSQLI_ASSOC), 0, 3); $stmt->close(); if ($conn->more_results()) $conn->next_result(); }
        $stmt = $conn->prepare("CALL get_role_permissions(?)");
        if ($stmt) { $stmt->bind_param("i", $roleId); $stmt->execute(); $p = $stmt->get_result()->fetch_all(MYSQLI_ASSOC); $permissions = array_map(fn($x) => $x['permission_key'] ?? 'view', $p); $stmt->close(); if ($conn->more_results()) $conn->next_result(); }

        // Summary Data
        $studentSummary = null;
        if ($isStudent) {
            $std_stmt = $conn->prepare("SELECT s.name AS student_name, s.student_id, s.email, p.tell1 AS emergency_contact, c.cl_name AS class_name, sem.semister_name AS semester, f.name AS faculty, d.name AS department, sh.shiftName AS shift FROM students s LEFT JOIN parents p ON s.parent_no = p.parent_no LEFT JOIN studet_classes sc ON s.std_id = sc.std_id LEFT JOIN classes c ON sc.cls_no = c.cls_no LEFT JOIN departments d ON c.dept_no = d.dept_no LEFT JOIN faculties f ON d.faculty_no = f.faculty_no LEFT JOIN semesters sem ON sc.sem_no = sem.sem_no LEFT JOIN shifts sh ON s.shift_no = sh.shift_no WHERE s.user_id = ? LIMIT 1");
            $std_stmt->bind_param("i", $dbUser['user_id']); $std_stmt->execute(); $studentSummary = $std_stmt->get_result()->fetch_assoc(); $std_stmt->close(); if ($conn->more_results()) $conn->next_result();
        }

        $teacherProfile = null;
        if ($isTeacher) {
            $tch_stmt = $conn->prepare("SELECT t.teacher_id, t.name AS teacher_name, t.tell AS phone, t.specialization, d.name AS department, f.name AS faculty FROM teachers t LEFT JOIN departments d ON t.dept_no = d.dept_no LEFT JOIN faculties f ON d.faculty_no = f.faculty_no WHERE t.user_id = ? LIMIT 1");
            $tch_stmt->bind_param("i", $dbUser['user_id']); $tch_stmt->execute(); $teacherProfile = $tch_stmt->get_result()->fetch_assoc(); $tch_stmt->close();
        }

        $displayName = $isStudent ? ($studentSummary['student_name'] ?? $dbUser['username']) : ($teacherProfile['teacher_name'] ?? $dbUser['username']);

        // Check if leader
        $isLeader = false;
        $lead_stmt = $conn->prepare("SELECT 1 FROM leaders l JOIN students s ON l.std_id = s.std_id WHERE s.user_id = ? LIMIT 1");
        if ($lead_stmt) {
            $lead_stmt->bind_param("i", $dbUser['user_id']);
            $lead_stmt->execute();
            $isLeader = (bool) $lead_stmt->get_result()->fetch_assoc();
            $lead_stmt->close();
        }

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
                'is_leader'       => $isLeader,
                'debug_user_id'   => $dbUser['user_id'],
            ]
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Authentication error.']);
    }
    exit;
}

http_response_code(405);
echo json_encode(['success' => false, 'message' => 'Method not allowed.']);
