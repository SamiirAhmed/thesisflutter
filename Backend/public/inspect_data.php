<?php
$host = "127.0.0.1"; $user = "root"; $pass = ""; $db = "thesisdb";
$conn = new mysqli($host, $user, $pass, $db);

echo "--- class_issues (The Categories/Templates) ---\n";
$res = $conn->query("SELECT * FROM class_issues");
while($row = $res->fetch_assoc()) print_r($row);

echo "\n--- class_issues_complaints (The Actual Reported Issues) ---\n";
$res = $conn->query("SELECT * FROM class_issues_complaints");
while($row = $res->fetch_assoc()) print_r($row);

echo "\n--- Joins for All Complaints ---\n";
$q = "SELECT cic.cl_is_co_no, ci.issue_name, cic.description, cl.cl_name 
      FROM class_issues_complaints cic
      LEFT JOIN class_issues ci ON cic.cl_issue_id = ci.cl_issue_id
      LEFT JOIN leaders l ON cic.lead_id = l.lead_id
      LEFT JOIN classes cl ON l.cls_no = cl.cls_no";
$res = $conn->query($q);
while($row = $res->fetch_assoc()) print_r($row);
?>
