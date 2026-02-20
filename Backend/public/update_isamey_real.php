<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");

// Update Isamey with real info
$specialization = "AI & Machine Learning";
$department_id = 1; // Computer Science
$phone = "+252 61 5123456";

$conn->query("UPDATE teachers SET 
    specialization = '$specialization', 
    dept_no = $department_id,
    phone = '$phone' 
    WHERE user_id = 140186");

if ($conn->affected_rows > 0) {
    echo "Isamey profile updated with real information.";
} else {
    echo "No changes made or teacher not found.";
}
