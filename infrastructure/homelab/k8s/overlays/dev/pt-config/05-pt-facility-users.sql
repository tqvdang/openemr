-- Vietnamese Physiotherapy Configuration - Facility & Users
-- Facility: Rehab Well
-- Admin Users: Hoang Tran, Ben Dell

-- ============================================
-- 1. UPDATE FACILITY NAME
-- ============================================
UPDATE facility
SET name = 'Rehab Well',
    facility_npi = ''
WHERE id = 1 OR id = (SELECT MIN(id) FROM (SELECT id FROM facility) AS f);

-- Also update in globals if exists
INSERT INTO globals (gl_name, gl_index, gl_value) VALUES
    ('openemr_name', 0, 'Rehab Well PT')
ON DUPLICATE KEY UPDATE gl_value = VALUES(gl_value);

-- ============================================
-- 2. CREATE ADMIN USER: HOANG TRAN
-- ============================================
-- Note: Password will need to be set via OpenEMR admin interface
-- Default password: TempPass2026! (should be changed on first login)

INSERT INTO users (username, password, authorized, info, source, fname, lname, mname, federaltaxid,
    federaldrugid, upin, facility, see_auth, active, npi, title, specialty, billname,
    email, url, assistant, organization, vaession, state_license_number,
    default_warehouse, irnpool, calendar, abook_type)
SELECT 'hoang_tran',
    '$2y$10$JNhgK1/pKzM1.FCdgDQveuVy.wqYKv3QeESq8zMqI.9E0b3yL5k6i',  -- hashed placeholder
    1, NULL, NULL, 'Hoang', 'Tran', NULL, NULL, NULL, NULL,
    (SELECT id FROM facility WHERE name = 'Rehab Well' LIMIT 1),
    'all', 1, NULL, 'PT', 'Physical Therapy', NULL, 'hoang.tran@rehabwell.vn',
    NULL, NULL, 'Rehab Well', NULL, NULL, NULL, NULL, 1, NULL
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'hoang_tran');

-- ============================================
-- 3. CREATE ADMIN USER: BEN DELL
-- ============================================
INSERT INTO users (username, password, authorized, info, source, fname, lname, mname, federaltaxid,
    federaldrugid, upin, facility, see_auth, active, npi, title, specialty, billname,
    email, url, assistant, organization, vaession, state_license_number,
    default_warehouse, irnpool, calendar, abook_type)
SELECT 'ben_dell',
    '$2y$10$JNhgK1/pKzM1.FCdgDQveuVy.wqYKv3QeESq8zMqI.9E0b3yL5k6i',  -- hashed placeholder
    1, NULL, NULL, 'Ben', 'Dell', NULL, NULL, NULL, NULL,
    (SELECT id FROM facility WHERE name = 'Rehab Well' LIMIT 1),
    'all', 1, NULL, 'Admin', 'Administration', NULL, 'ben.dell@rehabwell.vn',
    NULL, NULL, 'Rehab Well', NULL, NULL, NULL, NULL, 1, NULL
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'ben_dell');

-- ============================================
-- 4. ASSIGN ADMIN ACL TO NEW USERS
-- ============================================
-- Get admin ARO group ID and assign users
-- This creates the ACL associations for admin access

-- Note: The actual ACL assignment is complex in OpenEMR's gACL system
-- Users will need to be manually assigned to 'admin' group via:
-- Admin -> Users -> [User] -> Additional Info -> Access Control

SELECT 'Facility and users configured - Passwords must be set via Admin interface' AS status;
