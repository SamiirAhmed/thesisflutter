<?php
$host = "127.0.0.1";
$user = "root";
$pass = "";
$db   = "thesisdb";
$userId = 8; // Maida Hashi

$conn = new mysqli($host, $user, $pass, $db);
$stmt = $conn->prepare("
    SELECT u.user_id, u.username, u.status, u.role_id, r.role_name
    FROM users u
    JOIN roles r ON u.role_id = r.role_id
    WHERE u.user_id = ?
    LIMIT 1
");
$stmt->bind_param("i", $userId);
$stmt->execute();
$baseUser = $stmt->get_result()->fetch_assoc();
$stmt->close();

echo "Base User: "; print_r($baseUser);

$roleId = (int) $baseUser['role_id'];
echo "Role ID: $roleId\n";

if ($roleId === 1) {
    echo "Entering Student block...\n";
    $stmt = $conn->prepare("
        SELECT
            s.std_id,
            s.student_id,
            s.name           AS full_name,
            s.phone          AS phone,
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
    if (!$stmt) echo "Stmt Error: " . $conn->error;
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    echo "Student Row: "; print_r($row);
    $stmt->close();
}
