<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");

// Update TCH260001 (Yahye Ali Isse) with very specific data
$conn->query("UPDATE teachers SET 
    specialization = 'Software Engineering & AI', 
    dept_no = 1,
    tell = '+252 61 7100001'
    WHERE teacher_id = 'TCH260001'");

echo "Updated TCH260001 with: Specialization=Software Engineering & AI, Dept=1, Phone=+252 61 7100001";
?>
