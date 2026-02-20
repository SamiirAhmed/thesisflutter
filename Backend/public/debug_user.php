<?php
$conn = new mysqli('127.0.0.1', 'root', '', 'thesisdb');
if ($conn->connect_error) die("Conn failed");

$username = 'STU260002';
echo "Checking $username...\n";

$res = $conn->query("SELECT user_id, role_id FROM users WHERE username='$username'");
$user = $res->fetch_assoc();
if (!$user) die("User not found");

$uid = $user['user_id'];
echo "User ID: $uid, Role: " . $user['role_id'] . "\n";

$res = $conn->query("SELECT * FROM students WHERE user_id=$uid");
$student = $res->fetch_assoc();
if ($student) {
    print_r($student);
} else {
    echo "No student record found for user_id $uid\n";
    
    echo "\nAll students:\n";
    $res = $conn->query("SELECT * FROM students LIMIT 5");
    while($row = $res->fetch_assoc()) print_r($row);
}
