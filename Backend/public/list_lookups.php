<?php
$conn = new mysqli('127.0.0.1', 'root', '', 'thesisdb');
echo "Classes:\n";
$res = $conn->query("SELECT cls_no, cl_name FROM classes");
while($r = $res->fetch_assoc()) print_r($r);

echo "\nSemesters:\n";
$res = $conn->query("SELECT sem_no, semister_name FROM semesters");
while($r = $res->fetch_assoc()) print_r($r);

echo "\nAcademic Years:\n";
$res = $conn->query("SELECT acy_no, name FROM acadamic_years");
while($r = $res->fetch_assoc()) print_r($r);
