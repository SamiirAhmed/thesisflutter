<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");
$output = "";

$res = $conn->query("SELECT * FROM users WHERE username LIKE 'TCH%' OR user_id = 140184");
while($row = $res->fetch_assoc()) {
    $output .= "ID: " . $row['user_id'] . " | Role: " . $row['role_id'] . " | User: " . $row['username'] . " | Pass: " . $row['password_hash'] . "\n";
}

$res = $conn->query("SHOW CREATE PROCEDURE login_proc");
if ($res) {
    $row = $res->fetch_assoc();
    $output .= "\nPROCEDURE login_proc:\n" . $row['Create Procedure'] . "\n";
}

file_put_contents("search_results.txt", $output);
echo "Results written to search_results.txt\n";
