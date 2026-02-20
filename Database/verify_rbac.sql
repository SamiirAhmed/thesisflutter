-- Thesis Project: RBAC Verification Queries
-- Run these in phpMyAdmin to verify your current database state

-- 1. Verify roles exist
SELECT role_id, role_name, status FROM roles;

-- 2. Verify admin and faculty users exist with correct role name joining
SELECT u.username, r.role_name, u.status, u.Accees_channel
FROM users u
JOIN roles r ON r.role_id = u.role_id
WHERE u.username IN ('admin', 'faculty');

-- 3. Verify passwords match the expected SHA256 hashes
-- For 'admin' (password: password)
SELECT username, (password_hash = SHA2('password', 256)) AS password_ok 
FROM users WHERE username = 'admin';

-- For 'faculty' (password: faculty)
SELECT username, (password_hash = SHA2('faculty', 256)) AS password_ok 
FROM users WHERE username = 'faculty';
