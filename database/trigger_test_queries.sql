-- ============================================================
-- MediChain - 5 Simple Queries That Hit Database Triggers
-- ============================================================

USE medichain;

-- ============================================================
-- QUERY 1: Hits trg_drug_interaction_order (BEFORE INSERT on DRUG_INTERACTION)
-- Purpose:  Tries to insert a drug interaction with medication_id_1 > medication_id_2,
--           violating the canonical ordering rule.
-- Expected: FAILS with "medication_id_1 must be less than medication_id_2"
-- ============================================================

INSERT INTO DRUG_INTERACTION (medication_id_1, medication_id_2, severity, interaction_description, recommendation)
VALUES (10, 3, 'Moderate', 'Test interaction', 'Monitor closely');


-- ============================================================
-- QUERY 2: Hits trg_audit_log_no_update (BEFORE UPDATE on AUDIT_LOG)
-- Purpose:  Tries to modify an existing audit log entry.
-- Expected: FAILS with "Audit log entries cannot be modified"
-- ============================================================

UPDATE AUDIT_LOG
SET notes = 'Tampered entry'
WHERE log_id = 1;


-- ============================================================
-- QUERY 3: Hits trg_patient_update_audit (AFTER UPDATE on PATIENT)
-- Purpose:  Updates a patient's city. The trigger automatically logs
--           old and new values into AUDIT_LOG.
-- Expected: SUCCEEDS — patient updated, and a new AUDIT_LOG row is created.
-- ============================================================

UPDATE PATIENT
SET address_city = 'Bangalore'
WHERE health_id = 'HID-003';

-- Verify the audit log entry was created:
SELECT log_id, action_type, table_name, record_id, old_value, new_value
FROM AUDIT_LOG
WHERE table_name = 'PATIENT' AND record_id = 'HID-003'
ORDER BY log_id DESC
LIMIT 1;


-- ============================================================
-- QUERY 4: Hits trg_encounter_date_validation (BEFORE INSERT on ENCOUNTER)
-- Purpose:  Tries to create an encounter with a date far in the future.
-- Expected: FAILS with "Encounter date cannot be in the future"
-- ============================================================

INSERT INTO ENCOUNTER (health_id, hospital_id, encounter_date_time, encounter_type, chief_complaint)
VALUES ('HID-002', 2, '2030-06-15 10:00:00', 'Outpatient', 'Routine checkup');


-- ============================================================
-- QUERY 5: Hits trg_consent_revoke (BEFORE UPDATE on CONSENT)
-- Purpose:  Revokes an active consent. The trigger auto-sets revoked_date
--           to today and logs the revocation in AUDIT_LOG.
-- Expected: SUCCEEDS — consent revoked, revoked_date auto-filled, audit log entry created.
-- ============================================================

UPDATE CONSENT
SET status = 'Revoked'
WHERE health_id = 'HID-001' AND hospital_id = 2;

-- Verify revoked_date was set automatically:
SELECT consent_id, health_id, hospital_id, status, revoked_date
FROM CONSENT
WHERE health_id = 'HID-001' AND hospital_id = 2;

-- Verify the audit log entry:
SELECT log_id, action_type, table_name, notes
FROM AUDIT_LOG
WHERE action_type = 'CONSENT_REVOKED'
ORDER BY log_id DESC
LIMIT 1;
