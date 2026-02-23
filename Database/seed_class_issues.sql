-- 1. Insert Categories if they don't exist
INSERT IGNORE INTO categories (cat_name) VALUES ('Classroom Equipment');

-- 2. Insert Issue Types (categories)
INSERT IGNORE INTO class_issues (issue_name, cat_no) VALUES 
('Projector', 1),
('Fan', 1),
('Cooling system', 1),
('Speaker', 1),
('Classroom capacity', 1);

-- 3. Make student with user_id = 4 (Samiir Ahmed) a leader
-- First find his std_id
SET @std_id = (SELECT std_id FROM students WHERE user_id = 4 LIMIT 1);
-- Find a class to assign him to
SET @cls_no = (SELECT cls_no FROM classes LIMIT 1);

-- Insert into leaders if he's not already one
INSERT IGNORE INTO leaders (cls_no, std_id) VALUES (@cls_no, @std_id);
