<?php
// Standalone DB Test - No Laravel/Composer required
$host = "127.0.0.1";
$user = "root";
$pass = "";
$db = "thesisdb";

header('Content-Type: application/json');

try {
    $conn = new mysqli($host, $user, $pass, $db);
    
    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }
    
    // Check tables
    $tables = [];
    $result = $conn->query("SHOW TABLES");
    while($row = $result->fetch_array()) {
        $tables[] = $row[0];
    }
    
    // Check Procedures
    $procs = [];
    $result = $conn->query("SHOW PROCEDURE STATUS WHERE Db = '$db'");
    while($row = $result->fetch_assoc()) {
        $procs[] = $row['Name'];
    }
    
    echo json_encode([
        'success' => true,
        'database' => $db,
        'tables' => $tables,
        'procedures' => $procs,
        'php_version' => PHP_VERSION
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'php_version' => PHP_VERSION
    ]);
}
