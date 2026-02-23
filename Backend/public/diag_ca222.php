<?php
$host = "127.0.0.1"; $user = "root"; $pass = ""; $db = "thesisdb";
$conn = new mysqli($host, $user, $pass, $db);

echo "--- Complaints with Class Info ---\n";
$q = "SELECT cic.cl_is_co_no, cic.description, cl.cl_name, l.cls_no, s.std_name as leader_name
      FROM class_issues_complaints cic
      JOIN leaders l ON cic.lead_id = l.lead_id
      JOIN students s ON l.std_id = s.std_id
      LEFT JOIN classes cl ON l.cls_no = cl.cls_no";
$res = $conn->query($q);
if ($res) {
    while($row = $res->fetch_assoc()) print_r($row);
} else {
    echo "Query Error: " . $conn->error;
}

echo "\n--- Current User Class Check (User ID 29? or check all) ---\n";
$res = $conn->query("SELECT s.user_id, s.std_name, sc.cls_no, cl.cl_name 
                    FROM students s 
                    LEFT JOIN studet_classes sc ON s.std_id = sc.std_id
                    LEFT JOIN classes cl ON sc.cls_no = cl.cls_no");
while($row = $res->fetch_assoc()) print_r($row);
?>
