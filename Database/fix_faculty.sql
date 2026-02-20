-- Final Verification for Faculty Account (Simple & Secure)

-- 1. Ensure the 'Faculty' role exists
INSERT IGNORE INTO roles (role_name, description, status) 
VALUES ('Faculty', 'Faculty Office User', 'Active');

-- 2. Ensure the 'faculty' user exists with exact credentials
-- Username: faculty
-- Password: faculty
INSERT INTO users (role_id, username, password_hash, status, Accees_channel, created_at, updated_at)
SELECT role_id, 'faculty', SHA2('faculty', 256), 'Active', 'WEB', NOW(), NOW()
FROM roles WHERE role_name = 'Faculty'
ON DUPLICATE KEY UPDATE 
    role_id = VALUES(role_id),
    password_hash = VALUES(password_hash),
    status = 'Active',
    Accees_channel = 'WEB';

-- 3. Verification Query
SELECT u.username, r.role_name, u.status, u.Accees_channel 
FROM users u JOIN roles r ON u.role_id = r.role_id 
WHERE u.username = 'faculty';
