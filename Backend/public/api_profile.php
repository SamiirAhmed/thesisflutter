<?php
/**
 * api_profile.php
 * 
 * Returns the full profile of the authenticated user (student or teacher).
 * The Flutter app sends the user_id via the X-USER-ID header.
 * All data is read directly from the database — nothing is hardcoded.
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

// Read user_id from header
$userId = $_SERVER['HTTP_X_USER_ID'] ?? '';
if ($userId === '') {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized: missing user identifier.']);
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

    // Load base user + role
    $stmt = $conn->prepare("
        SELECT u.user_id, u.username, u.status, u.role_id, r.role_name
        FROM users u
        JOIN roles r ON u.role_id = r.role_id
        WHERE u.user_id = ?
        LIMIT 1
    ");
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Profile service unavailable.']);
        exit;
    }
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $baseUser = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$baseUser) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'User not found.']);
        exit;
    }

    $roleId = (int) $baseUser['role_id'];
    $profile = [
        'user_id'   => $baseUser['user_id'],
        'username'  => $baseUser['username'],
        'role_id'   => $roleId,
        'role_name' => $baseUser['role_name'],
        'status'    => $baseUser['status'],
    ];

    // ── Student profile ─────────────────────────────────────────────────────
    if ($roleId === 1) {
        $stmt = $conn->prepare("
            SELECT
                s.std_id,
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
        ");
        if ($stmt) {
            $stmt->bind_param("i", $userId);
            $stmt->execute();
            $row = $stmt->get_result()->fetch_assoc();
            $stmt->close();
            if ($row) {
                $profile['full_name']  = $row['full_name']  ?? $baseUser['username'];
                $profile['student_id'] = $row['student_id'] ?? 'N/A';
                $profile['phone']      = $row['phone']      ?? 'N/A';
                $profile['class_name'] = $row['class_name'] ?? 'N/A';
                $profile['semester']   = $row['semester']   ?? 'N/A';
                $profile['faculty']    = $row['faculty']    ?? 'N/A';
                $profile['department'] = $row['department'] ?? 'N/A';
            }
        }
    }

    // ── Teacher profile ──────────────────────────────────────────────────────
    if ($roleId === 2) {
        $stmt = $conn->prepare("
            SELECT
                t.teacher_id,
                t.name           AS full_name,
                t.tell           AS phone,
                t.specialization,
                d.name           AS department,
                f.name           AS faculty
            FROM teachers t
            LEFT JOIN departments d ON t.dept_no    = d.dept_no
            LEFT JOIN faculties   f ON d.faculty_no = f.faculty_no
            WHERE t.user_id = ?
            LIMIT 1
        ");
        if ($stmt) {
            $stmt->bind_param("i", $userId);
            $stmt->execute();
            $row = $stmt->get_result()->fetch_assoc();
            $stmt->close();
            if ($row) {
                $profile['full_name']      = $row['full_name']      ?? $baseUser['username'];
                $profile['teacher_id']     = $row['teacher_id']     ?? 'N/A';
                $profile['phone']          = $row['phone']          ?? 'N/A';
                $profile['specialization'] = $row['specialization'] ?? 'N/A';
                $profile['department']     = $row['department']     ?? 'N/A';
                $profile['faculty']        = $row['faculty']        ?? 'N/A';
            }
        }
    }

    echo json_encode(['success' => true, 'profile' => $profile]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'An error occurred while loading profile.']);
}
