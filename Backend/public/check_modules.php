<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");

echo "Modules for Role 1 (Student):\n";
$res = $conn->query("CALL get_role_modules(1)");
while($row = $res->fetch_assoc()) {
    print_r($row);
}
if ($conn->more_results()) $conn->next_result();

echo "\nModules for Role 2 (Teacher):\n";
$res = $conn->query("CALL get_role_modules(2)");
while($row = $res->fetch_assoc()) {
    print_r($row);
}
