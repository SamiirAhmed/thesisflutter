<?php
/**
 * api_student.php - Returns full student profile.
 */

$host = "127.0.0.1";
$user = "root";
$pass = "";
$db   = "thesisdb";

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
    echo json_encode(['success' => false, 'message' => 'Unauthorized.']);
    exit;
}

mysqli_report(MYSQLI_REPORT_OFF);
$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed.']);
    exit;
}

try {
    // Basic user info
    $stmt = $conn->prepare("SELECT u.user_id, u.username, u.status, u.role_id, r.role_name FROM users u JOIN roles r ON u.role_id = r.role_id WHERE u.user_id = ? LIMIT 1");
    $stmt->bind_param("i", $userId); $stmt->execute();
    $baseUser = $stmt->get_result()->fetch_assoc(); $stmt->close();

    if (!$baseUser) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'User not found.']);
        exit;
    }

    $roleId = (int)$baseUser['role_id'];
    if ($roleId !== 1 && $roleId !== 6) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Access denied. Only students allowed.']);
        exit;
    }

    if (trim($baseUser['status']) !== 'Active') {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Account is inactive.']);
        exit;
    }

    // Full Student Data
    $stmt = $conn->prepare("SELECT s.std_id, s.student_id, s.nira, sh.shiftName AS study_mode, s.created_at AS entry_time, s.grad_year, s.grade, s.gender, s.pob, s.mother AS mother_name, s.name AS full_name, s.tell AS phone, s.email, IFNULL(p.tell1, 'N/A') AS emergency_contact_parent, c.cl_name AS class_name, cp.campus AS campus_name, sem.semister_name AS semester, f.name AS faculty, d.name AS department, adr.villages AS address FROM students s LEFT JOIN parents p ON s.parent_no = p.parent_no LEFT JOIN studet_classes sc ON s.std_id = sc.std_id LEFT JOIN classes c ON sc.cls_no = c.cls_no LEFT JOIN campuses cp ON c.camp_no = cp.camp_no LEFT JOIN departments d ON c.dept_no = d.dept_no LEFT JOIN faculties f ON d.faculty_no = f.faculty_no LEFT JOIN semesters sem ON sc.sem_no = sem.sem_no LEFT JOIN address adr ON s.add_no = adr.add_no LEFT JOIN shifts sh ON s.shift_no = sh.shift_no WHERE s.user_id = ? LIMIT 1");
    $stmt->bind_param("i", $userId); $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc(); $stmt->close();

    $profile = array_merge($baseUser, $row ?: []);
    if ($row) {
        $profile['emergency_contact'] = $row['phone'] ?: 'N/A';
        $profile['entry_time'] = ($row['entry_time'] && $row['entry_time'] !== 'N/A') ? date('F', strtotime($row['entry_time'])) : 'N/A';
        $profile['semester'] = str_ireplace('Semister ', '', $row['semester'] ?? 'N/A');
    }

    echo json_encode(['success' => true, 'profile' => $profile]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error.']);
}
