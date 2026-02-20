<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");
$res = $conn->query("CALL get_role_modules(2)");
$modules = [];
while($row = $res->fetch_assoc()) {
    $modules[] = $row;
}
echo json_encode($modules);
