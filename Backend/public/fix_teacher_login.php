<?php
$conn = new mysqli("127.0.0.1", "root", "", "thesisdb");
$username = 'TCH260004';
$res = $conn->query("SELECT * FROM users WHERE username = '$username'");
$user = $res->fetch_assoc();

if ($user) {
    echo "User Found:\n";
    print_r($user);
    
    // Check if password is '1234' plain text vs SHA256 of '1234'
    $plain = '1234';
    $hashed = hash('sha256', $plain);
    
    echo "\nCurrent Stored Password: " . $user['password_hash'] . "\n";
    echo "SHA256 of '1234': " . $hashed . "\n";
    
    if ($user['password_hash'] === $plain) {
        echo "\nWARNING: Password is stored as PLAIN TEXT. System expects SHA256.\n";
        echo "Fixing it now...\n";
        $conn->query("UPDATE users SET password_hash = '$hashed' WHERE username = '$username'");
        echo "Password updated to SHA256 hash.\n";
    }
} else {
    echo "User $username not found in database.\n";
}
