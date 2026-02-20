<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");
$res = $conn->query("SELECT * FROM teachers WHERE teacher_id = 'TCH260001'");
print_r($res->fetch_assoc());
?>
