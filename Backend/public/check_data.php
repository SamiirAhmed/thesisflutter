<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");
$res = $conn->query("SELECT * FROM classes LIMIT 1");
$class = $res->fetch_assoc();
$res = $conn->query("SELECT * FROM semesters LIMIT 1");
$sem = $res->fetch_assoc();
$res = $conn->query("SELECT * FROM academics LIMIT 1");
$acy = $res->fetch_assoc();
$res = $conn->query("SELECT * FROM students WHERE student_id = 'STU260001'");
$std = $res->fetch_assoc();

echo json_encode(['class' => $class, 'sem' => $sem, 'acy' => $acy, 'std' => $std]);
