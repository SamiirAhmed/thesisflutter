-- ==========================================
-- 1. MASTER DIAGNOSTIC QUERY
-- Run this to see exactly why login might fail
-- ==========================================

SELECT 
    u.username,
    r.role_name,
    u.status,
    u.Accees_channel,
    u.password_hash,
    -- Check if hash matches 'password' (for admin)
    CASE 
        WHEN u.username = 'admin' THEN (u.password_hash = SHA2('password', 256))
        WHEN u.username = 'faculty' THEN (u.password_hash = SHA2('faculty', 256))
        ELSE 'N/A'
    END as hash_valid,
    -- Check if role_id exists in roles table
    (SELECT COUNT(*) FROM roles WHERE role_id = u.role_id) as role_exists
FROM users u
LEFT JOIN roles r ON u.role_id = r.role_id
WHERE u.username IN ('admin', 'faculty');


-- ==========================================
-- 2. INDIVIDUAL VERIFICATIONS
-- ==========================================

-- Check Roles table directly
SELECT * FROM roles;

-- Check Users table directly
SELECT * FROM users;

-- Verify conversion of input to hash (test query)
SELECT SHA2('password', 256) as test_admin_hash;
SELECT SHA2('faculty', 256) as test_faculty_hash;
