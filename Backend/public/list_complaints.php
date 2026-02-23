<?php
$host = "127.0.0.1"; $user = "root"; $pass = ""; $db = "thesisdb";
$conn = new mysqli($host, $user, $pass, $db);

echo "--- Complaints in DB ---\n";
$q = "SELECT cic.*, ci.issue_name, cl.cl_name 
      FROM class_issues_complaints cic
      JOIN class_issues ci ON cic.cl_issue_id = ci.cl_issue_id
      JOIN leaders l ON cic.lead_id = l.lead_id
      JOIN classes cl ON l.cls_no = cl.cls_no";
$res = $conn->query($q);
if ($res) {
    while($row = $res->fetch_assoc()) {
        echo "ID: " . $row['cl_is_co_no'] . " | Issue: " . $row['issue_name'] . " | Class: " . $row['cl_name'] . " | Desc: " . $row['description'] . "\n";
    }
} else {
    echo "Error: " . $conn->error;
}
?>
