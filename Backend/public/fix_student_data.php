<?php
$conn = new mysqli('127.0.0.1', 'root', '', 'thesisdb');

// 1. Fix data join for Maida Hashi
$std_id = 2; // Maida Hashi's std_id
$check = $conn->query("SELECT * FROM studet_classes WHERE std_id=$std_id");
if ($check->num_rows == 0) {
    echo "Adding academic record for Maida Hashi...\n";
    $conn->query("INSERT INTO studet_classes (cls_no, std_id, sem_no, acy_no) VALUES (1, $std_id, 1, 1)");
    echo "Success!\n";
} else {
    echo "Maida Hashi already has an academic record.\n";
}

// 2. Fix api_login.php to return correct name
// I will do this via file edit tool later.

echo "\nDone data fixes.\n";
