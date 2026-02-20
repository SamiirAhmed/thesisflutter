<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");

// 1. Create Teacher Role if not exists
$conn->query("INSERT IGNORE INTO roles (role_id, role_name) VALUES (2, 'Teacher')");

// 2. Insert Teacher User
$pass = hash('sha256', '1234');
$username = 'LEC260001';
$name = 'Dr. Ahmed Ali';

$conn->query("INSERT INTO users (role_id, full_name, username, password_hash, status) 
             VALUES (2, '$name', '$username', '$pass', 'Active')
             ON DUPLICATE KEY UPDATE password_hash = '$pass'");

$userId = $conn->insert_id;
if (!$userId) {
    $res = $conn->query("SELECT user_id FROM users WHERE username = '$username'");
    $userId = $res->fetch_assoc()['user_id'];
}

// 3. Insert Teacher Info (Note: check table name typo 'tearchers' vs 'teachers')
// Based on list_tables, it is 'teachers'
$conn->query("INSERT IGNORE INTO teachers (user_id, teacher_id, name, status) 
             VALUES ($userId, 'T-001', '$name', 'Active')");

echo "Teacher Account Created:\n";
echo "Username: $username\n";
echo "Password: 1234\n";
