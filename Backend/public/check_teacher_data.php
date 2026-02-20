<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");
$res = $conn->query("SELECT * FROM teachers WHERE user_id = 140186");
if ($row = $res->fetch_assoc()) {
    echo json_encode($row);
} else {
    echo "Teacher not found";
}
