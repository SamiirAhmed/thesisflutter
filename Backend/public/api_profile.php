<?php
/**
 * api_profile.php
 * 
 * Returns the full profile of the authenticated user (student or teacher).
 * Also includes debug tools (accessible via GET ?tool=...).
 */

$host = "127.0.0.1";
$user = "root";
$pass = "";
$db   = "thesisdb";

// ── DEBUG TOOLS (GET REQUESTS) ───────────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['tool'])) {
    $conn = new mysqli($host, $user, $pass, $db);
    $tool = $_GET['tool'];
    echo "<pre>";
    
    switch ($tool) {
        case 'debug_query':
            $userId = $_GET['uid'] ?? 8;
            $stmt = $conn->prepare("SELECT s.name AS full_name, c.cl_name AS class_name FROM students s LEFT JOIN studet_classes sc ON s.std_id = sc.std_id LEFT JOIN classes c ON sc.cls_no = c.cls_no WHERE s.user_id = ? LIMIT 1");
            $stmt->bind_param("i", $userId); $stmt->execute(); 
            print_r($stmt->get_result()->fetch_assoc());
            break;
            
        case 'test_user':
            $userId = $_GET['uid'] ?? 8;
            $stmt = $conn->prepare("SELECT u.user_id, u.username, r.role_name FROM users u JOIN roles r ON u.role_id = r.role_id WHERE u.user_id = ?");
            $stmt->bind_param("i", $userId); $stmt->execute();
            print_r($stmt->get_result()->fetch_assoc());
            break;
            
        default:
            echo "Unknown tool. Available: debug_query, test_user";
    }
    echo "</pre>";
    exit;
}

// ── PROFILE API (GET REQUESTS) ──────────────────────────────────────────────
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-USER-ID');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$userId = $_SERVER['HTTP_X_USER_ID'] ?? '';
if ($userId === '') {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit;
}

mysqli_report(MYSQLI_REPORT_OFF);

try {
    $conn = new mysqli($host, $user, $pass, $db);
    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database connection failed.']);
        exit;
    }

    $stmt = $conn->prepare("SELECT u.user_id, u.username, u.status, u.role_id, r.role_name FROM users u JOIN roles r ON u.role_id = r.role_id WHERE u.user_id = ? LIMIT 1");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $baseUser = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$baseUser) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'User not found.']);
        exit;
    }

    if (trim($baseUser['status']) !== 'Active') {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Your account is inactive. Please contact the administrator.']);
        exit;
    }

    $roleId = (int) $baseUser['role_id'];
    $profile = [
        'user_id'       => $baseUser['user_id'],
        'username'      => $baseUser['username'],
        'role_id'       => $roleId,
        'role_name'     => $baseUser['role_name'],
        'status'        => $baseUser['status'],
    ];

    if ($roleId === 1) {
        $stmt = $conn->prepare("SELECT s.std_id, s.student_id, s.nira, sh.shiftName AS study_mode, s.created_at AS entry_time, s.grad_year, s.grade, s.gender, s.pob, s.mother AS mother_name, s.name AS full_name, s.tell AS phone, s.email, s.parent_no AS emergency_contact, c.cl_name AS class_name, cp.campus AS campus_name, sem.semister_name AS semester, f.name AS faculty, d.name AS department, adr.villages AS address, sch.name AS previous_school FROM students s LEFT JOIN studet_classes sc ON s.std_id = sc.std_id LEFT JOIN classes c ON sc.cls_no = c.cls_no LEFT JOIN campuses cp ON c.camp_no = cp.camp_no LEFT JOIN departments d ON c.dept_no = d.dept_no LEFT JOIN faculties f ON d.faculty_no = f.faculty_no LEFT JOIN semesters sem ON sc.sem_no = sem.sem_no LEFT JOIN address adr ON s.add_no = adr.add_no LEFT JOIN school sch ON s.sch_no = sch.sch_no LEFT JOIN shifts sh ON s.shift_no = sh.shift_no WHERE s.user_id = ? LIMIT 1");
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $row = $stmt->get_result()->fetch_assoc();
        $stmt->close();
        if ($row) {
            $profile = array_merge($profile, $row);
            $profile['entry_time'] = ($row['entry_time'] && $row['entry_time'] !== 'N/A') ? date('F', strtotime($row['entry_time'])) : 'N/A';
            $profile['shift'] = $row['study_mode'];
            $profile['semester'] = str_ireplace('Semister ', '', $row['semester'] ?? 'N/A');
        }
    }

    if ($roleId === 2) {
        $stmt = $conn->prepare("SELECT t.teacher_id, t.name AS full_name, t.tell AS phone, t.specialization, d.name AS department, f.name AS faculty FROM teachers t LEFT JOIN departments d ON t.dept_no = d.dept_no LEFT JOIN faculties f ON d.faculty_no = f.faculty_no WHERE t.user_id = ? LIMIT 1");
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $row = $stmt->get_result()->fetch_assoc();
        $stmt->close();
        if ($row) $profile = array_merge($profile, $row);
    }

    echo json_encode(['success' => true, 'profile' => $profile]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error.']);
}
