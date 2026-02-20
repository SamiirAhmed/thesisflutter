<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");

echo "Departments:\n";
$res = $conn->query("SELECT * FROM departments");
while($row = $res->fetch_assoc()) print_r($row);

echo "\nFaculties:\n";
$res = $conn->query("SELECT * FROM faculties");
while($row = $res->fetch_assoc()) print_r($row);
?>
