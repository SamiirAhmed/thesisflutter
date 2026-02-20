<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");

// Update TCH260001 (Yahye Ali Isse)
$conn->query("UPDATE teachers SET 
    specialization = 'Software Engineering', 
    dept_no = 1 
    WHERE teacher_id = 'TCH260001'");

// Update TCH260002 (if exists)
$conn->query("UPDATE teachers SET 
    specialization = 'Database Management', 
    dept_no = 1 
    WHERE teacher_id = 'TCH260002'");

// Update TCH260003
$conn->query("UPDATE teachers SET 
    specialization = 'Information Security', 
    dept_no = 4 
    WHERE teacher_id = 'TCH260003'");

// Update Isamey (TCH260005) - already done but let's be sure
$conn->query("UPDATE teachers SET 
    specialization = 'Artificial Intelligence', 
    dept_no = 1 
    WHERE teacher_id = 'TCH260005'");

echo "Teacher profiles updated with real academic information.";
?>
