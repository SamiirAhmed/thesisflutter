<?php
$host = "127.0.0.1";
$user = "root";
$pass = "";
$db = "thesisdb";
header('Content-Type: application/json');

try {
    $conn = new mysqli($host, $user, $pass, $db);
    if ($conn->connect_error) die(json_encode(['error' => $conn->connect_error]));

    // Check specific user STU260001
    $res = $conn->query("SELECT user_id, username FROM users WHERE username = 'STU260001'");
    $userData = $res->fetch_assoc();
    
    if (!$userData) die(json_encode(['error' => 'User STU260001 not found']));
    
    $uid = $userData['user_id'];
    
    // Check student record
    $res = $conn->query("SELECT * FROM students WHERE user_id = $uid");
    $studentData = $res->fetch_assoc();
    
    // Check student classes
    $std_id = $studentData['std_id'] ?? 0;
    $res = $conn->query("SELECT * FROM studet_classes WHERE std_id = $std_id");
    $classLinks = $res->fetch_all(MYSQLI_ASSOC);
    
    echo json_encode([
        'user' => $userData,
        'student' => $studentData,
        'class_links' => $classLinks,
        'query_test' => ($std_id > 0)
    ]);
} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
