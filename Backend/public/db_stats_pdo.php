<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

function check($db) {
    try {
        $dsn = "mysql:host=127.0.0.1;dbname=$db;charset=utf8mb4";
        $options = [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION];
        $pdo = new PDO($dsn, 'root', '', $options);
        
        $stmt = $pdo->query("SELECT COUNT(*) FROM students");
        $students = $stmt->fetchColumn();
        
        $stmt = $pdo->query("SELECT COUNT(*) FROM subjects");
        $subjects = $stmt->fetchColumn();
        
        $stmt = $pdo->query("SELECT COUNT(*) FROM studet_classes");
        $sc = $stmt->fetchColumn();

        return "DB $db: Students: $students, Subjects: $subjects, StudentClasses: $sc\n";
    } catch (Throwable $e) {
        return "DB $db: Error " . $e->getMessage() . "\n";
    }
}

echo check('thesisdb') . "\n";
echo check('thesessystem') . "\n";
