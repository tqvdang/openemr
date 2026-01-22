-- Vietnamese Physiotherapy Configuration - Calendar & Appointments
-- This script sets up PT-specific appointment types

-- ============================================
-- 1. DISABLE MEDICAL-SPECIFIC APPOINTMENT CATEGORIES
-- ============================================
UPDATE openemr_postcalendar_categories
SET pc_active = 0
WHERE pc_catid IN (12, 13, 14);  -- Health Assessment, Preventive Care, Ophthalmological

UPDATE openemr_postcalendar_categories
SET pc_active = 0
WHERE pc_catname = 'Office Visit' AND pc_cattype = 0;

-- ============================================
-- 2. ADD PT-SPECIFIC APPOINTMENT CATEGORIES
-- ============================================
INSERT INTO openemr_postcalendar_categories
    (pc_catname, pc_catcolor, pc_catdesc, pc_cattype, pc_active, pc_duration, pc_end_all_day)
SELECT 'PT Initial Evaluation', '#98FB98', 'Initial PT assessment', 0, 1, 45, 0
WHERE NOT EXISTS (SELECT 1 FROM openemr_postcalendar_categories WHERE pc_catname = 'PT Initial Evaluation');

INSERT INTO openemr_postcalendar_categories
    (pc_catname, pc_catcolor, pc_catdesc, pc_cattype, pc_active, pc_duration, pc_end_all_day)
SELECT 'PT Follow-up', '#87CEEB', 'Follow-up PT session', 0, 1, 30, 0
WHERE NOT EXISTS (SELECT 1 FROM openemr_postcalendar_categories WHERE pc_catname = 'PT Follow-up');

INSERT INTO openemr_postcalendar_categories
    (pc_catname, pc_catcolor, pc_catdesc, pc_cattype, pc_active, pc_duration, pc_end_all_day)
SELECT 'PT Exercise Session', '#DDA0DD', 'Supervised exercise', 0, 1, 45, 0
WHERE NOT EXISTS (SELECT 1 FROM openemr_postcalendar_categories WHERE pc_catname = 'PT Exercise Session');

INSERT INTO openemr_postcalendar_categories
    (pc_catname, pc_catcolor, pc_catdesc, pc_cattype, pc_active, pc_duration, pc_end_all_day)
SELECT 'PT Re-evaluation', '#FFB347', 'Progress re-evaluation', 0, 1, 30, 0
WHERE NOT EXISTS (SELECT 1 FROM openemr_postcalendar_categories WHERE pc_catname = 'PT Re-evaluation');

-- ============================================
-- 3. UPDATE EXISTING APPOINTMENT DURATIONS
-- ============================================
UPDATE openemr_postcalendar_categories
SET pc_duration = 45
WHERE pc_catname = 'New Patient' AND pc_cattype = 0;

UPDATE openemr_postcalendar_categories
SET pc_duration = 30
WHERE pc_catname = 'Established Patient' AND pc_cattype = 0;

-- ============================================
-- 4. ADD PT ENCOUNTER TYPES
-- ============================================
INSERT INTO list_options (list_id, option_id, title, seq, is_default, activity)
SELECT 'encounter-types', 'pt_initial', 'PT Initial Evaluation', 10, 0, 1
WHERE NOT EXISTS (SELECT 1 FROM list_options WHERE list_id = 'encounter-types' AND option_id = 'pt_initial');

INSERT INTO list_options (list_id, option_id, title, seq, is_default, activity)
SELECT 'encounter-types', 'pt_followup', 'PT Follow-up', 20, 0, 1
WHERE NOT EXISTS (SELECT 1 FROM list_options WHERE list_id = 'encounter-types' AND option_id = 'pt_followup');

INSERT INTO list_options (list_id, option_id, title, seq, is_default, activity)
SELECT 'encounter-types', 'pt_reeval', 'PT Re-evaluation', 30, 0, 1
WHERE NOT EXISTS (SELECT 1 FROM list_options WHERE list_id = 'encounter-types' AND option_id = 'pt_reeval');

INSERT INTO list_options (list_id, option_id, title, seq, is_default, activity)
SELECT 'encounter-types', 'pt_discharge', 'PT Discharge', 40, 0, 1
WHERE NOT EXISTS (SELECT 1 FROM list_options WHERE list_id = 'encounter-types' AND option_id = 'pt_discharge');

SELECT 'PT Calendar configured' AS status;
