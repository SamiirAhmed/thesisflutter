<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");

// Add missing columns
$conn->query("ALTER TABLE teachers ADD COLUMN specialization VARCHAR(100) DEFAULT NULL AFTER tell");
$conn->query("ALTER TABLE teachers ADD COLUMN dept_no INT DEFAULT NULL AFTER specialization");

echo "Checking if columns added...\n";
$res = $conn->query("DESCRIBE teachers");
while($row = $res->fetch_assoc()) {
    echo $row['Field'] . " ";
}
?>
