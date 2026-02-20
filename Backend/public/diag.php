<?php
require __DIR__.'/../vendor/autoload.php';
$app = require_once __DIR__.'/../bootstrap/app.php';

use Illuminate\Support\Facades\DB;

header('Content-Type: application/json');

try {
    // 1. Check Connection
    DB::connection()->getPdo();
    $dbName = DB::connection()->getDatabaseName();
    
    // 2. Check Tables
    $tables = DB::select('SHOW TABLES');
    
    // 3. Check Procedures
    $procs = DB::select("SHOW PROCEDURE STATUS WHERE Db = ?", [$dbName]);
    
    echo json_encode([
        'success' => true,
        'database' => $dbName,
        'tables' => $tables,
        'procedures' => array_map(function($p) { return $p->Name; }, $procs)
    ]);
} catch (\Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
