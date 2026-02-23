<?php
$host = "127.0.0.1"; $user = "root"; $pass = ""; $db = "thesisdb";
$conn = new mysqli($host, $user, $pass, $db);

echo "--- Leaders Table ---\n";
$res = $conn->query("SELECT l.lead_id, l.std_id, s.std_name, l.cls_no, c.cl_name 
                    FROM leaders l 
                    JOIN students s ON l.std_id = s.std_id 
                    JOIN classes c ON l.cls_no = c.cls_no");
while($row = $res->fetch_assoc()) print_r($row);

echo "\n--- Recent Complaints ---\n";
$res = $conn->query("SELECT cic.cl_is_co_no, cic.lead_id, cl.cl_name, cic.description 
                    FROM class_issues_complaints cic
                    JOIN leaders l ON cic.lead_id = l.lead_id
                    JOIN classes cl ON l.cls_no = cl.cls_no
                    ORDER BY cic.cl_is_co_no DESC LIMIT 5");
while($row = $res->fetch_assoc()) print_r($row);
?>
