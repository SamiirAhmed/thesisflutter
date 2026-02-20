<?php
$conn = new mysqli('127.0.0.1', 'root', '', 'thesisdb');

echo "Finding all students without academic records...\n";
$res = $conn->query("
    SELECT s.std_id, s.name 
    FROM students s 
    LEFT JOIN studet_classes sc ON s.std_id = sc.std_id 
    WHERE sc.std_id IS NULL
");

while($row = $res->fetch_assoc()) {
    $sid = $row['std_id'];
    $name = $row['name'];
    echo "Adding academic record for $name (ID: $sid)...\n";
    // Assigning to default class 1, sem 1, acy 1 for now
    $conn->query("INSERT INTO studet_classes (cls_no, std_id, sem_no, acy_no) VALUES (1, $sid, 1, 1)");
}

echo "\nDone fixing student data.\n";
