<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

function check($db) {
    try {
        $c = @new mysqli('127.0.0.1', 'root', '', $db);
        if ($c->connect_error) return "DB $db: Connection failed.\n";
        
        $res = $c->query("SELECT COUNT(*) as c FROM students");
        $students = $res ? $res->fetch_assoc()['c'] : "Error";
        
        $res = $c->query("SELECT COUNT(*) as c FROM subjects");
        $subjects = $res ? $res->fetch_assoc()['c'] : "Error";
        
        $res = $c->query("SELECT COUNT(*) as c FROM studet_classes");
        $sc = $res ? $res->fetch_assoc()['c'] : "Error";

        return "DB $db: Students: $students, Subjects: $subjects, StudentClasses: $sc\n";
    } catch (Throwable $e) {
        return "DB $db: Exception " . $e->getMessage() . "\n";
    }
}

echo check('thesisdb');
echo check('thesessystem');
