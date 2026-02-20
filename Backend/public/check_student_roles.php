<?php
$conn = new mysqli('127.0.0.1', 'root', '', 'thesisdb');
echo "Users with Student records:\n";
$res = $conn->query("SELECT u.user_id, u.username, u.role_id, s.name FROM users u JOIN students s ON u.user_id = s.user_id");
while($row = $res->fetch_assoc()) print_r($row);
