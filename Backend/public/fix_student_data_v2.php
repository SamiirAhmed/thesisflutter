<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
$conn = new mysqli('127.0.0.1', 'root', '', 'thesisdb');

$std_id = 2; 

$res = $conn->query("SELECT * FROM studet_classes WHERE std_id=$std_id");
if ($res === false) {
    die("Query failed: " . $conn->error);
}

if ($res->num_rows > 0) {
    echo "Exists: ";
    print_r($res->fetch_assoc());
} else {
    echo "Inserting for std_id $std_id...\n";
    $ok = $conn->query("INSERT INTO studet_classes (cls_no, std_id, sem_no, acy_no) VALUES (1, $std_id, 1, 1)");
    if ($ok) {
        echo "Inserted successfully!";
    } else {
        echo "Insert failed: " . $conn->error;
    }
}
