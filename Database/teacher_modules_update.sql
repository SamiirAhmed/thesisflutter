-- ============================================================================
-- teacher_modules_update.sql
--
-- Updates teacher (role_id = 7) module keys to use teacher-specific
-- identifiers that match the Flutter module card icon/color mapping.
--
-- Run once:
--   mysql -u root thesessystem < teacher_modules_update.sql
-- ============================================================================

USE thesessystem;

-- Remove old teacher module rows (if any)
DELETE FROM role_modules WHERE role_id = 7;

-- Re-insert with exact keys matched in the Flutter app
INSERT INTO role_modules (role_id, `key`, title, sort_order)
VALUES
  (7, 'course_appeal',  'Course Appeal',              1),
  (7, 'notifications',  'Coursework Notifications',   2),
  (7, 'report',         'Report',                     3);

-- Ensure teacher permissions are current
DELETE FROM role_permissions WHERE role_id = 7;

INSERT INTO role_permissions (role_id, permission_key)
VALUES
  (7, 'course_appeal.view'),
  (7, 'course_appeal.respond'),
  (7, 'notification.view'),
  (7, 'report.view'),
  (7, 'profile.view');

-- Verify
SELECT 'Teacher modules:' AS info;
SELECT role_id, `key`, title, sort_order
FROM role_modules
WHERE role_id = 7
ORDER BY sort_order;

SELECT 'Teacher permissions:' AS info;
SELECT role_id, permission_key
FROM role_permissions
WHERE role_id = 7
ORDER BY permission_key;
