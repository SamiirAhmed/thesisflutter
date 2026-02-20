<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");
$res = $conn->query("SELECT * FROM teachers ORDER BY teacher_no DESC LIMIT 3");
while($row = $res->fetch_assoc()) {
    print_r($row);
}
