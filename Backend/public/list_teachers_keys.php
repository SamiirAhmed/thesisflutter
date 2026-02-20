<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");
$res = $conn->query("SELECT * FROM teachers LIMIT 1");
$row = $res->fetch_assoc();
print_r(array_keys($row));
?>
