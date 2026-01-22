-- Vietnamese Physiotherapy Configuration - Global Settings
-- This script configures OpenEMR for PT-focused usage

-- ============================================
-- 1. DISABLE UNNECESSARY MEDICAL MODULES
-- ============================================
INSERT INTO globals (gl_name, gl_index, gl_value) VALUES
    ('disable_prescriptions', 0, '1'),
    ('erx_enable', 0, '0'),
    ('lab_exchange_enable', 0, '0'),
    ('immunizations_enable', 0, '0'),
    ('enable_cdr', 0, '0'),
    ('enable_cdr_crw', 0, '0'),
    ('enable_cdr_prw', 0, '0'),
    ('enable_allergy_check', 0, '0'),
    ('enable_amc', 0, '0'),
    ('enable_amc_prompting', 0, '0'),
    ('enable_eligibility_requests', 0, '0'),
    ('growth_chart_enable', 0, '0'),
    ('enable_cqm', 0, '0'),
    ('portal_onsite_two_enable', 0, '0')
ON DUPLICATE KEY UPDATE gl_value = VALUES(gl_value);

-- ============================================
-- 2. HIDE MENUS AND SIMPLIFY UI
-- ============================================
INSERT INTO globals (gl_name, gl_index, gl_value) VALUES
    ('disable_pat_trkr', 0, '1'),
    ('disable_rcb', 0, '1'),
    ('gbl_nav_area_width', 0, '140'),
    ('hide_billing_widget', 0, '1'),
    ('simplified_prescriptions', 0, '1'),
    ('simplified_demographics', 0, '1'),
    ('simplified_copay', 0, '1'),
    ('enable_fees_in_left_menu', 0, '0'),
    ('enable_edihistory_in_left_menu', 0, '0'),
    ('enable_batch_payment', 0, '0'),
    ('enable_posting', 0, '0'),
    ('use_charges_panel', 0, '0'),
    ('disable_chart_tracker', 0, '1'),
    ('enable_follow_up_encounters', 0, '0'),
    ('enable_group_therapy', 0, '0'),
    ('enable_compact_mode', 0, '1'),
    ('disable_eligibility_log', 0, '1'),
    ('enable_scanner', 0, '0'),
    ('enable_hylafax', 0, '0'),
    ('full_new_patient_form', 0, '0'),
    ('appt_recurrences_widget', 0, '0'),
    ('state_custom_addlist_widget', 0, '0'),
    ('gbl_edit_patient_form', 0, '1'),
    ('patient_search_results_style', 0, '1'),
    ('recent_patient_count', 0, '10')
ON DUPLICATE KEY UPDATE gl_value = VALUES(gl_value);

-- ============================================
-- 3. HIDE ENCOUNTER COMPLEXITY
-- ============================================
INSERT INTO globals (gl_name, gl_index, gl_value) VALUES
    ('enc_enable_issues', 0, 'hide_both'),
    ('enc_enable_discharge_disposition', 0, 'hide_both'),
    ('enc_enable_referring_provider', 0, 'hide_both'),
    ('enc_enable_ordering_provider', 0, 'hide_both')
ON DUPLICATE KEY UPDATE gl_value = VALUES(gl_value);

SELECT 'PT Globals configured' AS status;
