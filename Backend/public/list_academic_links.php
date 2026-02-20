<?php
$conn = new mysqli('127.0.0.1', 'root', '', 'thesisdb');
$res = $conn->query("SELECT * FROM studet_classes");
while($row = $res->fetch_assoc()) print_r($row);
