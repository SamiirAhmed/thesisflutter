<?php
/**
 * api_class_issues.php - Direct access to categories and issues
 */

$host = "127.0.0.1";
$user = "root";
$pass = "";
$db   = "thesisdb"; // Matching api_login.php

error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept, Authorization, X-USER-ID');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed.']);
    exit;
}

$action = $_GET['action'] ?? '';

// 1. GET CATEGORIES (For Dropdown)
if ($action === 'get_categories') {
    $res = $conn->query("SELECT cat_no, cat_name FROM categories ORDER BY cat_name ASC");
    $categories = [];
    while($row = $res->fetch_assoc()) {
        $categories[] = [
            'cat_no'   => (int)$row['cat_no'],
            'cat_name' => $row['cat_name']
        ];
    }
    echo json_encode(['success' => true, 'data' => $categories]);
    exit;
}

// 2. SUBMIT COMPLAINT
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $action === 'submit_issue') {
    $input = json_decode(file_get_contents('php://input'), true);
    $catNo = $input['cat_no'] ?? 0;
    $desc  = $input['description'] ?? '';
    $userId = $_SERVER['HTTP_X_USER_ID'] ?? '';

    if (!$catNo || !$desc || !$userId) {
        echo json_encode(['success' => false, 'message' => 'Missing data.']);
        exit;
    }

    // A. Find Leader ID for this user (Optionally for a specific class)
    $clsNo = $input['cls_no'] ?? 0;
    $q = "SELECT l.lead_id FROM leaders l JOIN students s ON l.std_id = s.std_id WHERE s.user_id = ?";
    if ($clsNo > 0) {
        $q .= " AND l.cls_no = " . (int)$clsNo;
    }
    $q .= " LIMIT 1";

    $stmt = $conn->prepare($q);
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $leader = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$leader) {
        echo json_encode(['success' => false, 'message' => 'User is not a Class Leader for this class.']);
        exit;
    }

    $leadId = $leader['lead_id'];

    // B. Link Category to class_issues (ensure one exists)
    $stmt = $conn->prepare("SELECT cl_issue_id FROM class_issues WHERE cat_no = ? LIMIT 1");
    $stmt->bind_param("i", $catNo);
    $stmt->execute();
    $issue = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if ($issue) {
        $clIssueId = $issue['cl_issue_id'];
    } else {
        // Create it
        $stmt = $conn->prepare("INSERT INTO class_issues (issue_name, cat_no) SELECT cat_name, cat_no FROM categories WHERE cat_no = ?");
        $stmt->bind_param("i", $catNo);
        $stmt->execute();
        $clIssueId = $conn->insert_id;
        $stmt->close();
    }

    // C. Insert Complaint
    $stmt = $conn->prepare("INSERT INTO class_issues_complaints (cl_issue_id, description, lead_id) VALUES (?, ?, ?)");
    $stmt->bind_param("isi", $clIssueId, $desc, $leadId);
    if ($stmt->execute()) {
        $complaintId = $conn->insert_id;
        // Add Initial Tracking
        $conn->query("INSERT INTO class_issue_tracking (cl_is_co_no, new_status, changed_by_user_id, note) VALUES ($complaintId, 'Pending', $userId, 'Submitted')");
        echo json_encode(['success' => true, 'message' => 'Issue reported successfully!']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Execute failed: ' . $stmt->error]);
    }
    exit;
}

// 2.5 GET MY CLASSES (If Leader)
if ($action === 'get_my_classes') {
    $userId = $_SERVER['HTTP_X_USER_ID'] ?? '0';
    $q = "SELECT l.cls_no, c.cl_name 
          FROM leaders l 
          JOIN students s ON l.std_id = s.std_id 
          JOIN classes c ON l.cls_no = c.cls_no 
          WHERE s.user_id = $userId";
    $res = $conn->query($q);
    $data = [];
    if ($res) {
        while($row = $res->fetch_assoc()) {
            $data[] = [
                'cls_no' => (int)$row['cls_no'],
                'cl_name' => $row['cl_name']
            ];
        }
    }
    echo json_encode(['success' => true, 'data' => $data]);
    exit;
}

// 3. GET LIST (For ListView)
if ($action === 'get_my_issues') {
    $userId = $_SERVER['HTTP_X_USER_ID'] ?? '0';

    // Query to show ALL complaints from ALL classes
    $q = "SELECT cic.cl_is_co_no as id, 
                 IFNULL(c.cat_name, IFNULL(ci.issue_name, 'Classroom Issue')) as issue_name, 
                 cic.description, 
                 IFNULL(cl.cl_name, 'Unknown Class') as class_name, 
                 cic.created_at as submitted_at,
                 IFNULL((SELECT new_status FROM class_issue_tracking WHERE cl_is_co_no = cic.cl_is_co_no ORDER BY created_at DESC LIMIT 1), 'Pending') as status
          FROM class_issues_complaints cic
          LEFT JOIN class_issues ci ON cic.cl_issue_id = ci.cl_issue_id
          LEFT JOIN categories c ON ci.cat_no = c.cat_no
          LEFT JOIN leaders l ON cic.lead_id = l.lead_id
          LEFT JOIN classes cl ON l.cls_no = cl.cls_no
          GROUP BY cic.cl_is_co_no
          ORDER BY cic.created_at DESC";
          
    $res = $conn->query($q);
    $data = [];
    if ($res) {
        while($row = $res->fetch_assoc()) {
            $row['id'] = (int)$row['id'];
            $data[] = $row;
        }
    }

    echo json_encode(['success' => true, 'data' => $data]);
    exit;
}

// 4. GET TRACKING
if ($action === 'get_tracking') {
    $complaintId = $_GET['id'] ?? 0;
    $res = $conn->query("SELECT cit_no, old_status, new_status, note, created_at as changed_date FROM class_issue_tracking WHERE cl_is_co_no = $complaintId ORDER BY created_at ASC");
    $data = [];
    while($row = $res->fetch_assoc()) {
        $row['cit_no'] = (int)$row['cit_no'];
        $data[] = $row;
    }
    echo json_encode(['success' => true, 'data' => $data]);
    exit;
}

// 5. UPDATE STATUS (For Admin/Staff use)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $action === 'update_status') {
    $input = json_decode(file_get_contents('php://input'), true);
    $complaintId = $input['id'] ?? 0;
    $newStatus = $input['status'] ?? '';
    $userId = $_SERVER['HTTP_X_USER_ID'] ?? 0;
    $note = $input['note'] ?? 'Status updated.';

    // A. Find the current status to set as old_status
    $res = $conn->query("SELECT new_status FROM class_issue_tracking WHERE cl_is_co_no = $complaintId ORDER BY created_at DESC LIMIT 1");
    $current = $res->fetch_assoc();
    $oldStatus = $current ? $current['new_status'] : null;

    // B. Insert new tracking record
    $stmt = $conn->prepare("INSERT INTO class_issue_tracking (cl_is_co_no, old_status, new_status, changed_by_user_id, note) VALUES (?, ?, ?, ?, ?)");
    $stmt->bind_param("issis", $complaintId, $oldStatus, $newStatus, $userId, $note);
    
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Status updated from ' . ($oldStatus ?? 'NULL') . ' to ' . $newStatus]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Update failed: ' . $conn->error]);
    }
    exit;
}
