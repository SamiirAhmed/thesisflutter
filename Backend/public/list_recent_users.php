<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");
$res = $conn->query("SELECT * FROM users ORDER BY user_id DESC LIMIT 10");
while($row = $res->fetch_assoc()) {
    echo "ID: " . $row['user_id'] . " | Role: " . $row['role_id'] . " | User: " . $row['username'] . " | Pass: " . $row['password_hash'] . "\n";
}
