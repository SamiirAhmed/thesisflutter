<?php
$conn = new mysqli('127.0.0.1', 'root', '', 'thesisdb');
$res = $conn->query("SELECT role_id, COUNT(*) as count FROM users GROUP BY role_id");
while($row = $res->fetch_assoc()) print_r($row);
