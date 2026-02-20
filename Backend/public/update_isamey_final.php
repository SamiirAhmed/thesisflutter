<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");

// Update Isamey (user_id 18 or 17? Let's update both just in case)
$specialization = "Artificial Intelligence";
$department_id = 1; // Computer Science
$phone = "+252 61 5123456";

$conn->query("UPDATE teachers SET 
    specialization = '$specialization', 
    dept_no = $department_id,
    tell = '$phone' 
    WHERE teacher_id = 'TCH260005'");

if ($conn->affected_rows > 0) {
    echo "Isamey profile updated successfully.";
} else {
    echo "No changes made.";
}
?>
