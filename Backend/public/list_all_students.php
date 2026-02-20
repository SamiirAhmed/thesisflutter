<?php
$conn = new mysqli('127.0.0.1', 'root', '', 'thesisdb');
$res = $conn->query("SELECT std_id, user_id, name FROM students");
while($row = $res->fetch_assoc()) print_r($row);
