<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");
$res = $conn->query("SELECT * FROM users WHERE username LIKE 'TCH%' OR username LIKE 'LEC%' OR user_id > 140000");
while($row = $res->fetch_assoc()) {
    echo "ID: " . $row['user_id'] . " | Role: " . $row['role_id'] . " | User: " . $row['username'] . " | Pass: " . $row['password_hash'] . "\n";
}
echo "\nChecking login_proc behavior...\n";
$res = $conn->query("SHOW CREATE PROCEDURE login_proc");
if ($res) {
    print_r($res->fetch_assoc());
}
