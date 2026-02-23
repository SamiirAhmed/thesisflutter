<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';

use App\Models\User;
use App\Models\ClassLeader;
use Illuminate\Support\Facades\DB;

$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$leaders = ClassLeader::all();
echo "Total Leaders: " . $leaders->count() . "\n";
foreach($leaders as $l) {
    echo "Lead ID: {$l->lead_id}, Std ID: {$l->std_id}, Class: {$l->cls_no}\n";
}

$students = DB::table('students')->select('std_id', 'user_id', 'name')->get();
echo "\nStudents:\n";
foreach($students as $s) {
    $isL = ClassLeader::where('std_id', $s->std_id)->exists();
    echo "Std ID: {$s->std_id}, User ID: {$s->user_id}, Name: {$s->name} " . ($isL ? "[LEADER]" : "") . "\n";
}
