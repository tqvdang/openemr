-- Vietnamese Physiotherapy Configuration - Forms & Issue Types
-- This script registers PT forms and simplifies issue types

-- ============================================
-- 1. REGISTER VIETNAMESE PT FORMS
-- ============================================
INSERT INTO registry (name, state, directory, sql_run, unpackaged, category, nickname, patient_encounter, therapy_group_encounter, aco_spec)
SELECT 'Vietnamese PT Assessment', 1, 'vietnamese_pt_assessment', 1, 1, 'Clinical', 'PT Assessment', 1, 0, 'encounters|notes'
WHERE NOT EXISTS (SELECT 1 FROM registry WHERE directory = 'vietnamese_pt_assessment');

INSERT INTO registry (name, state, directory, sql_run, unpackaged, category, nickname, patient_encounter, therapy_group_encounter, aco_spec)
SELECT 'Vietnamese PT Exercise Prescription', 1, 'vietnamese_pt_exercise', 1, 1, 'Clinical', 'PT Exercise', 1, 0, 'encounters|notes'
WHERE NOT EXISTS (SELECT 1 FROM registry WHERE directory = 'vietnamese_pt_exercise');

INSERT INTO registry (name, state, directory, sql_run, unpackaged, category, nickname, patient_encounter, therapy_group_encounter, aco_spec)
SELECT 'Vietnamese PT Treatment Plan', 1, 'vietnamese_pt_treatment_plan', 1, 1, 'Clinical', 'PT Treatment', 1, 0, 'encounters|notes'
WHERE NOT EXISTS (SELECT 1 FROM registry WHERE directory = 'vietnamese_pt_treatment_plan');

INSERT INTO registry (name, state, directory, sql_run, unpackaged, category, nickname, patient_encounter, therapy_group_encounter, aco_spec)
SELECT 'Vietnamese PT Outcome Measures', 1, 'vietnamese_pt_outcome', 1, 1, 'Clinical', 'PT Outcome', 1, 0, 'encounters|notes'
WHERE NOT EXISTS (SELECT 1 FROM registry WHERE directory = 'vietnamese_pt_outcome');

-- ============================================
-- 2. DISABLE NON-PT FORMS (Keep only essential)
-- ============================================
-- First disable all forms
UPDATE registry SET state = 0 WHERE state = 1;

-- Then enable only PT-relevant forms
UPDATE registry SET state = 1 WHERE directory IN (
    'vietnamese_pt_assessment',
    'vietnamese_pt_exercise',
    'vietnamese_pt_treatment_plan',
    'vietnamese_pt_outcome',
    'vitals',
    'soap',
    'note',
    'newpatient'
);

-- ============================================
-- 3. SIMPLIFY ISSUE TYPES FOR PT
-- ============================================
-- Disable irrelevant issue types
UPDATE issue_types SET active = 0 WHERE type IN (
    'dental',
    'contraceptive',
    'ippf_gcac',
    'medical_device'
);

-- Rename medical_problem to PT Diagnoses
UPDATE issue_types
SET singular = 'PT Diagnosis', plural = 'PT Diagnoses'
WHERE type = 'medical_problem' AND category = 'default';

SELECT 'PT Forms configured' AS status;
