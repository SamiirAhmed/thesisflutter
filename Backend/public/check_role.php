<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");
$res = $conn->query("SELECT user_id, username, role_id FROM users WHERE username = 'TCH260005'");
if ($row = $res->fetch_assoc()) {
    echo json_encode($row);
} else {
    echo "User not found";
}
