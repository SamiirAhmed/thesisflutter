<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");

$name = "Isamey";
$tell = "123456";
$email = "isamey@example.com";
$gender = "Male";
$hire_date = date('Y-m-d');
$status = "Active";
$channel = "APP";

$stmt = $conn->prepare("CALL sp_create_teacher(?, ?, ?, ?, ?, ?, ?, @uid, @tno, @tid, @plain)");
$stmt->bind_param("sssssss", $name, $tell, $email, $gender, $hire_date, $status, $channel);
$stmt->execute();

$res = $conn->query("SELECT @uid as user_id, @tid as teacher_id, @plain as plain_password");
$data = $res->fetch_assoc();

if ($data) {
    $uid = $data['user_id'];
    $tid = $data['teacher_id'];
    
    // The user specifically asked for password "kukalo"
    $new_pass = "kukalo";
    $hash = hash('sha256', $new_pass);
    
    $conn->query("UPDATE users SET password_hash = '$hash' WHERE user_id = $uid");
    $conn->query("UPDATE teacher_initial_credentials SET plain_password = '$new_pass' WHERE user_id = $uid");
    
    echo json_encode([
        'success' => true,
        'name' => $name,
        'user_id' => $uid,
        'teacher_id' => $tid,
        'password' => $new_pass
    ]);
} else {
    echo json_encode(['success' => false, 'error' => $conn->error]);
}
