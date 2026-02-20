<?php
$conn = new mysqli('127.0.0.1', 'root', '', 'thesisdb');

echo "Updating roles table...\n";
$conn->query("UPDATE roles SET role_name='Student', description='University Student' WHERE role_id=1");
$conn->query("UPDATE roles SET role_name='Teacher', description='University Teacher' WHERE role_id=2");
echo "Done!\n";
