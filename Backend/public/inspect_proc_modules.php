<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");
$res = $conn->query("SHOW CREATE PROCEDURE get_role_modules");
if ($row = $res->fetch_assoc()) {
    echo $row['Create Procedure'];
}
