<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");
$conn->query("DROP PROCEDURE IF EXISTS get_role_modules");

$sql = "
CREATE PROCEDURE `get_role_modules`(IN p_role_id INT)
BEGIN
    IF p_role_id = 2 THEN
        -- Teacher Modules
        SELECT 'course_appeal' as `key`, 'Course Appeal' as title, '/appeals' as route, 'Manage student appeals' as sub_title, 'assignment_turned_in' as icon_name
        UNION ALL
        SELECT 'coursework_notifications' as `key`, 'Coursework Notifications' as title, '/notifications' as route, 'Recent notifications' as sub_title, 'notifications_active' as icon_name
        UNION ALL
        SELECT 'report' as `key`, 'Reports' as title, '/reports' as route, 'View performance' as sub_title, 'bar_chart' as icon_name;
    ELSE
        -- Updated Student Modules
        SELECT 'exam_appeal' as `key`, 'Exam Appeal' as title, '/exam_appeal' as route, 'Submit and track exam appeals' as sub_title, 'assignment_turned_in_rounded' as icon_name
        UNION ALL
        SELECT 'class_issue' as `key`, 'Class Issue' as title, '/class_issue' as route, 'Report classroom concerns' as sub_title, 'class_rounded' as icon_name
        UNION ALL
        SELECT 'campus_env' as `key`, 'Campus Environment' as title, '/campus_env' as route, 'General facilities issues' as sub_title, 'apartment_rounded' as icon_name;
    END IF;
END
";

if ($conn->query($sql)) {
    echo "Stored procedure get_role_modules updated successfully!";
} else {
    echo "Error updating stored procedure: " . $conn->error;
}
