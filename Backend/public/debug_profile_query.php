<?php
$conn = new mysqli('127.0.0.1', 'root', '', 'thesisdb');
$userId = 8;

$stmt = $conn->prepare("
            SELECT
                s.std_id,
                s.student_id,
                s.name           AS full_name,
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
$stmt->bind_param("i", $userId);
$stmt->execute();
$res = $stmt->get_result();
$row = $res->fetch_assoc();
print_r($row);
if (!$row) echo "No row found for user_id $userId";
