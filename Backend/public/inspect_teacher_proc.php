<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");

$res = $conn->query("SHOW CREATE PROCEDURE sp_create_teacher");
if ($res) {
    $row = $res->fetch_assoc();
    echo "PROCEDURE sp_create_teacher:\n" . $row['Create Procedure'] . "\n";
} else {
    echo "Could not find sp_create_teacher\n";
}

$res = $conn->query("SELECT * FROM departments LIMIT 5");
echo "\nExample Departments:\n";
while($row = $res->fetch_assoc()) {
    print_r($row);
}
