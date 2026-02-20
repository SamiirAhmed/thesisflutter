<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");
$res = $conn->query("SHOW TABLES");
while($row = $res->fetch_row()) {
    echo $row[0] . "\n";
}
