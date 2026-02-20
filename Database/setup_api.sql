-- ============================================================================
-- setup_api.sql
-- Creates all stored procedures and RBAC tables needed by the Laravel API.
-- Run once:  mysql -u root thesessystem < setup_api.sql
-- ============================================================================

USE thesessystem;

-- ── 1) RBAC support tables ─────────────────────────────────────────────────

-- Dashboard routing per role
CREATE TABLE IF NOT EXISTS role_dashboards (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  role_id    INT NOT NULL,
  `key`      VARCHAR(50)  NOT NULL DEFAULT 'dashboard',
  title      VARCHAR(100) NOT NULL DEFAULT 'Dashboard',
  route      VARCHAR(100) NOT NULL DEFAULT '/dashboard',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_role_dashboard (role_id)
);

-- Visible modules per role (max 3 per the system design)
CREATE TABLE IF NOT EXISTS role_modules (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  role_id    INT NOT NULL,
  `key`      VARCHAR(50)  NOT NULL,
  title      VARCHAR(100) NOT NULL,
  sort_order INT DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Fine-grained permissions per role
CREATE TABLE IF NOT EXISTS role_permissions (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  role_id        INT NOT NULL,
  permission_key VARCHAR(100) NOT NULL,
  created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_role_perm (role_id, permission_key)
);

-- ── 2) Seed RBAC data ─────────────────────────────────────────────────────

-- Student (role_id = 6) dashboard
INSERT IGNORE INTO role_dashboards (role_id, `key`, title, route)
VALUES (6, 'student_dashboard', 'Student Dashboard', '/student-dashboard');

-- Teacher (role_id = 7) dashboard
INSERT IGNORE INTO role_dashboards (role_id, `key`, title, route)
VALUES (7, 'teacher_dashboard', 'Teacher Dashboard', '/teacher-dashboard');

-- Student modules (exactly 3 from categories)
INSERT IGNORE INTO role_modules (role_id, `key`, title, sort_order)
VALUES
  (6, 'appeals',    'Course Appeal',     1),
  (6, 'complaints', 'Complaints',        2),
  (6, 'results',    'Exam Results',      3);

-- Teacher modules (exactly 3 as per requirements)
INSERT IGNORE INTO role_modules (role_id, `key`, title, sort_order)
VALUES
  (7, 'appeals',       'Course Appeal',               1),
  (7, 'notifications', 'Coursework Notifications',    2),
  (7, 'reports',       'Reports',                     3);

-- Student permissions
INSERT IGNORE INTO role_permissions (role_id, permission_key) VALUES
  (6, 'course_appeal.view'),
  (6, 'course_appeal.create'),
  (6, 'complaint.view'),
  (6, 'complaint.create'),
  (6, 'exam_result.view'),
  (6, 'profile.view');

-- Teacher permissions
INSERT IGNORE INTO role_permissions (role_id, permission_key) VALUES
  (7, 'course_appeal.view'),
  (7, 'course_appeal.respond'),
  (7, 'notification.view'),
  (7, 'report.view'),
  (7, 'profile.view');

-- ── 3) Stored Procedures ──────────────────────────────────────────────────

-- Login procedure
DROP PROCEDURE IF EXISTS login_proc;
DELIMITER $$
CREATE PROCEDURE login_proc(
  IN p_username VARCHAR(80),
  IN p_password VARCHAR(255)
)
BEGIN
  SELECT
    u.user_id,
    u.role_id,
    r.role_name,
    u.full_name,
    u.username,
    u.password_hash,
    u.phone,
    u.email,
    u.status,
    u.Accees_channel
  FROM users u
  LEFT JOIN roles r ON u.role_id = r.role_id
  WHERE u.username = p_username
    AND u.password_hash = SHA2(p_password, 256)
  LIMIT 1;
END$$
DELIMITER ;

-- Get dashboard for a role
DROP PROCEDURE IF EXISTS get_role_dashboard;
DELIMITER $$
CREATE PROCEDURE get_role_dashboard(IN p_role_id INT)
BEGIN
  SELECT `key`, title, route
  FROM role_dashboards
  WHERE role_id = p_role_id
  LIMIT 1;
END$$
DELIMITER ;

-- Get modules for a role (max 3, ordered)
DROP PROCEDURE IF EXISTS get_role_modules;
DELIMITER $$
CREATE PROCEDURE get_role_modules(IN p_role_id INT)
BEGIN
  SELECT `key`, title
  FROM role_modules
  WHERE role_id = p_role_id
  ORDER BY sort_order
  LIMIT 3;
END$$
DELIMITER ;

-- Get permissions for a role
DROP PROCEDURE IF EXISTS get_role_permissions;
DELIMITER $$
CREATE PROCEDURE get_role_permissions(IN p_role_id INT)
BEGIN
  SELECT permission_key
  FROM role_permissions
  WHERE role_id = p_role_id
  ORDER BY permission_key;
END$$
DELIMITER ;
