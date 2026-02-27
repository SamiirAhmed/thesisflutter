-- ══════════════════════════════════════════════════════
-- Campus Environment Seed Data
-- ══════════════════════════════════════════════════════

-- 1. Ensure the 'Compus Enviroment' category exists (matches existing DB spelling)
INSERT IGNORE INTO categories (cat_name) VALUES ('Compus Enviroment');

-- 2. Get the category number
SET @campus_cat = (SELECT cat_no FROM categories WHERE cat_name LIKE '%nviro%' LIMIT 1);

-- 3. Insert campus environment issue types
INSERT IGNORE INTO campus_enviroment (campuses_issues, cat_no) VALUES 
('Broken Gate',           @campus_cat),
('Water Leakage',         @campus_cat),
('Electricity Problem',   @campus_cat),
('Road/Pathway Damage',   @campus_cat),
('Waste/Trash Issue',     @campus_cat),
('Toilet/Bathroom Issue', @campus_cat),
('Garden/Tree Issue',     @campus_cat),
('Parking Problem',       @campus_cat),
('Security Concern',      @campus_cat),
('Lighting Problem',      @campus_cat),
('Other',                 @campus_cat);

-- 4. Verify
SELECT * FROM campus_enviroment;
SELECT * FROM categories WHERE cat_name LIKE '%nviro%';
