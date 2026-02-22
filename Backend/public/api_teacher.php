<?php
/**
 * api_teacher.php - Returns full teacher profile.
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
    if ($roleId !== 2) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Access denied. Only teachers allowed.']);
        exit;
    }

    if (trim($baseUser['status']) !== 'Active') {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Account is inactive.']);
        exit;
    }

    // Full Teacher Data
    $stmt = $conn->prepare("SELECT t.teacher_id, t.name AS full_name, t.tell AS phone, t.specialization, d.name AS department, f.name AS faculty FROM teachers t LEFT JOIN departments d ON t.dept_no = d.dept_no LEFT JOIN faculties f ON d.faculty_no = f.faculty_no WHERE t.user_id = ? LIMIT 1");
    $stmt->bind_param("i", $userId); $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc(); $stmt->close();

    $profile = array_merge($baseUser, $row ?: []);

    echo json_encode(['success' => true, 'profile' => $profile]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error.']);
}
