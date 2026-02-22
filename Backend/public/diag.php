<?php
// We will try both thesisdb and thesessystem
$dbs = ['thesisdb', 'thesessystem'];
$output = "DATABASE DIAGNOSTICS\n====================\n\n";

foreach ($dbs as $db) {
    $output .= "Checking DB: $db\n";
    $conn = @new mysqli("127.0.0.1", "root", "", $db);
    if ($conn->connect_error) {
        $output .= "  - Connection failed: " . $conn->connect_error . "\n";
        continue;
    }
    
    $output .= "  - Connection SUCCESS.\n";
    
    // Students
    $res = $conn->query("SELECT std_id, student_id, user_id, name FROM students LIMIT 5");
    $output .= "  - Students (sample):\n";
    if ($res) {
        while ($row = $res->fetch_assoc()) {
            $output .= "    " . json_encode($row) . "\n";
        }
    } else {
        $output .= "    Table 'students' Error: " . $conn->error . "\n";
    }
    
    // Student Classes
    $res = $conn->query("SELECT * FROM studet_classes LIMIT 5");
    $output .= "  - Studet_classes (sample):\n";
    if ($res) {
        while ($row = $res->fetch_assoc()) {
            $output .= "    " . json_encode($row) . "\n";
        }
    } else {
        $output .= "    Table 'studet_classes' Error: " . $conn->error . "\n";
    }

    // Subject Class
    $res = $conn->query("SELECT * FROM subject_class LIMIT 5");
    $output .= "  - Subject_class (sample):\n";
    if ($res) {
        while ($row = $res->fetch_assoc()) {
            $output .= "    " . json_encode($row) . "\n";
        }
    } else {
        $output .= "    Table 'subject_class' Error: " . $conn->error . "\n";
    }
    
    $conn->close();
}

file_put_contents('diag_output.txt', $output);
echo "Diagnostics complete. Read diag_output.txt\n";
