-- Vietnamese Physiotherapy Configuration - Demographics & History
-- This script simplifies patient demographics and history forms

-- ============================================
-- 1. HIDE NON-ESSENTIAL DEMOGRAPHIC FIELDS (set uor = 0)
-- ============================================
UPDATE layout_options SET uor = 0 WHERE form_id = 'DEM' AND field_id IN (
    -- Personal fields to hide
    'suffix', 'birth_fname', 'birth_mname', 'birth_lname',
    'sexual_orientation', 'pubpid', 'ss', 'drivers_license',
    'genericname1', 'genericval1', 'genericname2', 'genericval2',
    'squad', 'pricelevel', 'billing_note', 'name_history',
    -- Contact fields to hide
    'county', 'mothersname', 'email_direct', 'additional_telecoms', 'additional_addresses',
    -- Provider/Choices fields to hide
    'provider_since_date', 'pharmacy_id',
    'hipaa_notice', 'hipaa_voice', 'hipaa_message',
    'hipaa_allowsms', 'hipaa_allowemail', 'allow_imm_reg_use',
    'allow_health_info_ex', 'allow_patient_portal', 'care_team_status',
    'care_team_facility', 'deceased_date', 'deceased_reason',
    'prevent_portal_apps', 'imm_reg_stat', 'imm_reg_stat_effdate',
    'publicity_code', 'publ_code_eff', 'prot_indicator', 'prot_indi_effdate',
    -- Employer fields to hide
    'occupation', 'em_name', 'em_street', 'em_street_line_2',
    'em_city', 'em_state', 'em_postal_code', 'em_country', 'industry',
    -- Insurance subscriber details to hide
    'guardiansname', 'guardiansname_relationship'
);

-- ============================================
-- 2. SET REQUIRED FIELDS FOR PT (uor = 2)
-- ============================================
UPDATE layout_options SET uor = 2 WHERE form_id = 'DEM' AND field_id IN (
    'fname', 'lname', 'DOB', 'sex', 'phone_cell', 'street', 'city'
);

-- ============================================
-- 3. RENAME FIELDS FOR PT CONTEXT
-- ============================================
UPDATE layout_options
SET title = 'Emergency Contact / Caregiver'
WHERE form_id = 'DEM' AND field_id = 'contact_relationship';

UPDATE layout_options
SET title = 'Emergency Phone'
WHERE form_id = 'DEM' AND field_id = 'phone_contact';

-- ============================================
-- 4. SIMPLIFY PATIENT HISTORY FORM
-- ============================================
UPDATE layout_options SET uor = 0 WHERE form_id = 'HIS' AND field_id IN (
    'coffee', 'tobacco', 'alcohol', 'recreational_drugs', 'counseling',
    'sleep_patterns', 'exercise_patterns', 'hazardous_activities',
    'relatives_cancer', 'relatives_diabetes', 'relatives_high_blood_pressure',
    'relatives_heart_problems', 'relatives_stroke', 'relatives_epilepsy',
    'relatives_mental_illness', 'relatives_suicide',
    'history_father', 'history_mother', 'history_siblings', 'history_offspring', 'history_spouse'
);

-- ============================================
-- 5. ADD PT-SPECIFIC HISTORY FIELDS
-- ============================================
INSERT INTO layout_options
    (form_id, field_id, group_id, title, seq, data_type, uor, fld_length, max_length, list_id, titlecols, datacols, default_value, edit_options, description, fld_rows)
SELECT 'HIS', 'previous_pt', '1', 'Previous PT Treatment', 10, 3, 1, 40, 0, '', 1, 3, '', '', '', 4
WHERE NOT EXISTS (SELECT 1 FROM layout_options WHERE form_id = 'HIS' AND field_id = 'previous_pt');

INSERT INTO layout_options
    (form_id, field_id, group_id, title, seq, data_type, uor, fld_length, max_length, list_id, titlecols, datacols, default_value, edit_options, description, fld_rows)
SELECT 'HIS', 'surgical_history', '1', 'Surgical History (Orthopedic)', 20, 3, 1, 40, 0, '', 1, 3, '', '', '', 4
WHERE NOT EXISTS (SELECT 1 FROM layout_options WHERE form_id = 'HIS' AND field_id = 'surgical_history');

INSERT INTO layout_options
    (form_id, field_id, group_id, title, seq, data_type, uor, fld_length, max_length, list_id, titlecols, datacols, default_value, edit_options, description, fld_rows)
SELECT 'HIS', 'activity_level', '1', 'Activity Level Before Injury', 30, 3, 1, 40, 0, '', 1, 3, '', '', '', 4
WHERE NOT EXISTS (SELECT 1 FROM layout_options WHERE form_id = 'HIS' AND field_id = 'activity_level');

INSERT INTO layout_options
    (form_id, field_id, group_id, title, seq, data_type, uor, fld_length, max_length, list_id, titlecols, datacols, default_value, edit_options, description, fld_rows)
SELECT 'HIS', 'work_status', '1', 'Current Work Status', 40, 3, 1, 40, 0, '', 1, 3, '', '', '', 4
WHERE NOT EXISTS (SELECT 1 FROM layout_options WHERE form_id = 'HIS' AND field_id = 'work_status');

INSERT INTO layout_options
    (form_id, field_id, group_id, title, seq, data_type, uor, fld_length, max_length, list_id, titlecols, datacols, default_value, edit_options, description, fld_rows)
SELECT 'HIS', 'functional_goals', '1', 'Patient Functional Goals', 50, 3, 1, 40, 0, '', 1, 3, '', '', '', 4
WHERE NOT EXISTS (SELECT 1 FROM layout_options WHERE form_id = 'HIS' AND field_id = 'functional_goals');

SELECT 'PT Demographics configured' AS status;
