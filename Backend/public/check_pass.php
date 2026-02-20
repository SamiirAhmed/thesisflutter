<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");
$res = $conn->query("SELECT username, password_hash FROM users WHERE username IN ('STU260001', 'admin')");
while($row = $res->fetch_assoc()) {
    echo $row['username'] . ": " . $row['password_hash'] . "\n";
}
