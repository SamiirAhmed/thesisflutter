<?php
$conn = new mysqli('127.0.0.1', 'root', '', 'thesisdb');
$std_id = 2;

echo "Checking student_classes for std_id $std_id...\n";
$res = $conn->query("SELECT * FROM studet_classes WHERE std_id=$std_id");
$row = $res->fetch_assoc();
if ($row) {
    print_r($row);
} else {
    echo "No record in studet_classes for std_id $std_id\n";
    
    echo "\nAll studet_classes:\n";
    $res = $conn->query("SELECT * FROM studet_classes LIMIT 5");
    while($r = $res->fetch_assoc()) print_r($r);
}
