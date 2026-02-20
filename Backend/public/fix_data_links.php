<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");
if ($conn->connect_error) die("Connection failed");

// 1. Ensure we have a Faculty and Department
$conn->query("INSERT IGNORE INTO faculties (faculty_no, name) VALUES (1, 'Kulliyadda IT')");
$conn->query("INSERT IGNORE INTO departments (dept_no, name, faculty_no) VALUES (1, 'Computer Science', 1)");

// 2. Ensure we have a Campus and Class
$conn->query("INSERT IGNORE INTO campuses (camp_no, campus) VALUES (1, 'Main Campus')");
$conn->query("INSERT IGNORE INTO classes (cls_no, cl_name, dept_no, camp_no) VALUES (1, 'CA201', 1, 1)");

// 3. Ensure we have a Semester and Academic Year
$conn->query("INSERT IGNORE INTO semesters (sem_no, semister_name) VALUES (1, 'Semester 1')");
$conn->query("INSERT IGNORE INTO academics (acy_no, start_date, end_date, active_year) VALUES (1, '2025-01-01', '2025-12-31', '2025-2026')");

// 4. Ensure STU260001 is in the students table
$userRes = $conn->query("SELECT user_id FROM users WHERE username = 'STU260001'");
$userData = $userRes->fetch_assoc();
if ($userData) {
    $uid = $userData['user_id'];
    $conn->query("INSERT IGNORE INTO students (user_id, student_id, name, status) VALUES ($uid, 'STU260001', 'Samiir Customer', 'Active')");
    
    // Get the std_id
    $stdRes = $conn->query("SELECT std_id FROM students WHERE user_id = $uid");
    $stdData = $stdRes->fetch_assoc();
    if ($stdData) {
        $sid = $stdData['std_id'];
        // 5. Link Student to Class
        $conn->query("INSERT IGNORE INTO studet_classes (cls_no, std_id, sem_no, acy_no) VALUES (1, $sid, 1, 1)");
    }
}

echo "Successfully linked student STU260001 to CA201, Semester 1, Computer Science.";
