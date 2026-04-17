-- ============================================================
-- MediChain - Database Triggers
-- ============================================================

USE medichain;

-- ============================================================
-- 0. DRUG INTERACTION CANONICAL ORDER
--    Ensures medication_id_1 < medication_id_2
-- ============================================================

DELIMITER //

CREATE TRIGGER trg_drug_interaction_order
BEFORE INSERT ON DRUG_INTERACTION
FOR EACH ROW
BEGIN
    IF NEW.medication_id_1 >= NEW.medication_id_2 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'VALIDATION ERROR: medication_id_1 must be less than medication_id_2 for canonical ordering.';
    END IF;
END //

DELIMITER ;

-- ============================================================
-- 1. AUDIT LOG HASH CHAIN (Tamper-Evident)
--    Computes SHA-256 hash linking each entry to the previous
-- ============================================================

DELIMITER //

CREATE TRIGGER trg_audit_log_hash_chain
BEFORE INSERT ON AUDIT_LOG
FOR EACH ROW
BEGIN
    DECLARE v_prev_hash VARCHAR(255);

    -- Get the hash of the most recent audit log entry
    SELECT hash_value INTO v_prev_hash
    FROM AUDIT_LOG
    ORDER BY log_id DESC
    LIMIT 1;

    -- If no previous entry, use a genesis hash
    IF v_prev_hash IS NULL THEN
        SET v_prev_hash = 'GENESIS_BLOCK_MEDICHAIN';
    END IF;

    SET NEW.prev_hash = v_prev_hash;

    -- Compute hash: SHA2 of (prev_hash + action_type + table_name + event_time + user_id + notes)
    SET NEW.hash_value = SHA2(
        CONCAT(
            IFNULL(v_prev_hash, ''),
            IFNULL(NEW.action_type, ''),
            IFNULL(NEW.table_name, ''),
            IFNULL(CAST(NEW.event_time AS CHAR), ''),
            IFNULL(CAST(NEW.user_id AS CHAR), ''),
            IFNULL(NEW.notes, '')
        ), 256
    );
END //

-- ============================================================
-- 2. AUDIT LOG IMMUTABILITY - Block UPDATE
-- ============================================================

CREATE TRIGGER trg_audit_log_no_update
BEFORE UPDATE ON AUDIT_LOG
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'SECURITY VIOLATION: Audit log entries cannot be modified. This attempt has been detected.';
END //

-- ============================================================
-- 3. AUDIT LOG IMMUTABILITY - Block DELETE
-- ============================================================

CREATE TRIGGER trg_audit_log_no_delete
BEFORE DELETE ON AUDIT_LOG
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'SECURITY VIOLATION: Audit log entries cannot be deleted. This attempt has been detected.';
END //

-- ============================================================
-- 4. ALLERGY CHECK TRIGGER on PRESCRIPTION_ITEM
--    Prevents prescribing medication if patient has severe allergy
--    unless allergy_override = TRUE with justification
-- ============================================================

CREATE TRIGGER trg_prescription_allergy_check
BEFORE INSERT ON PRESCRIPTION_ITEM
FOR EACH ROW
BEGIN
    DECLARE v_health_id VARCHAR(50);
    DECLARE v_allergy_count INT DEFAULT 0;
    DECLARE v_med_name VARCHAR(255);

    -- Get the patient's health_id via the prescription -> encounter chain
    SELECT e.health_id INTO v_health_id
    FROM PRESCRIPTION p
    JOIN ENCOUNTER e ON p.encounter_id = e.encounter_id
    WHERE p.prescription_id = NEW.prescription_id;

    -- Get medication name for error message
    SELECT generic_name INTO v_med_name
    FROM MEDICATION
    WHERE medication_id = NEW.medication_id;

    -- Check for severe or life-threatening allergies matching the medication
    SELECT COUNT(*) INTO v_allergy_count
    FROM PATIENT_ALLERGY pa
    JOIN MEDICATION m ON m.medication_id = NEW.medication_id
    WHERE pa.health_id = v_health_id
      AND pa.status = 'Active'
      AND pa.severity IN ('Severe', 'Life-threatening')
      AND (
          LOWER(pa.allergen) LIKE CONCAT('%', LOWER(m.generic_name), '%')
          OR LOWER(pa.allergen) LIKE CONCAT('%', LOWER(m.drug_class), '%')
          OR LOWER(m.generic_name) LIKE CONCAT('%', LOWER(pa.allergen), '%')
          OR LOWER(m.drug_class) LIKE CONCAT('%', LOWER(pa.allergen), '%')
      );

    IF v_allergy_count > 0 AND (NEW.allergy_override IS NULL OR NEW.allergy_override = FALSE) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ALLERGY ALERT: Severe allergy detected. Override required.';
    END IF;

    -- If override is used, justification must be provided
    IF v_allergy_count > 0 AND NEW.allergy_override = TRUE AND (NEW.override_justification IS NULL OR NEW.override_justification = '') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ALLERGY OVERRIDE REJECTED: Justification required.';
    END IF;
END //

-- ============================================================
-- 5. DRUG INTERACTION CHECK on PRESCRIPTION_ITEM
--    Checks new medication against patient's active prescriptions
-- ============================================================

CREATE TRIGGER trg_prescription_drug_interaction
AFTER INSERT ON PRESCRIPTION_ITEM
FOR EACH ROW
BEGIN
    DECLARE v_health_id VARCHAR(50);
    DECLARE v_interaction_count INT DEFAULT 0;
    DECLARE v_encounter_id BIGINT;

    -- Get encounter and patient info
    SELECT p.encounter_id INTO v_encounter_id
    FROM PRESCRIPTION p
    WHERE p.prescription_id = NEW.prescription_id;

    SELECT e.health_id INTO v_health_id
    FROM ENCOUNTER e
    WHERE e.encounter_id = v_encounter_id;

    -- Log any drug interactions found with active prescriptions
    INSERT INTO AUDIT_LOG (user_id, action_type, table_name, record_id, notes, event_time)
    SELECT NULL, 'DRUG_INTERACTION_ALERT', 'PRESCRIPTION_ITEM',
           CAST(NEW.prescription_id AS CHAR),
           CONCAT('Interaction detected between medication ', NEW.medication_id,
                  ' and medication ',
                  CASE WHEN di.medication_id_1 = NEW.medication_id THEN di.medication_id_2 ELSE di.medication_id_1 END,
                  ' | Severity: ', di.severity,
                  ' | ', IFNULL(di.interaction_description, 'No description')),
           NOW()
    FROM PRESCRIPTION_ITEM pi2
    JOIN PRESCRIPTION p2 ON pi2.prescription_id = p2.prescription_id
    JOIN ENCOUNTER e2 ON p2.encounter_id = e2.encounter_id
    JOIN DRUG_INTERACTION di ON (
        (di.medication_id_1 = LEAST(NEW.medication_id, pi2.medication_id)
         AND di.medication_id_2 = GREATEST(NEW.medication_id, pi2.medication_id))
    )
    WHERE e2.health_id = v_health_id
      AND p2.status = 'Active'
      AND pi2.medication_id <> NEW.medication_id
      AND pi2.prescription_id <> NEW.prescription_id;
END //

-- ============================================================
-- 6. AUTO-EXPIRE CONSENTS
--    When consent is accessed, check and update expired consents
-- ============================================================

CREATE EVENT IF NOT EXISTS evt_expire_consents
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE CONSENT
    SET status = 'Expired'
    WHERE status = 'Active'
      AND expiration_date IS NOT NULL
      AND expiration_date < CURDATE();
END //

-- ============================================================
-- 7. CRITICAL LAB RESULT ALERT
--    Auto-logs when critical lab result is entered
-- ============================================================

CREATE TRIGGER trg_critical_lab_result
AFTER INSERT ON LAB_RESULT
FOR EACH ROW
BEGIN
    DECLARE v_test_name VARCHAR(255);
    DECLARE v_patient_id VARCHAR(50);
    DECLARE v_doctor_id BIGINT;

    IF NEW.critical_flag = TRUE THEN
        -- Get test and patient info
        SELECT ltc.test_name, e.health_id, lo.doctor_id
        INTO v_test_name, v_patient_id, v_doctor_id
        FROM LAB_ORDER lo
        JOIN LAB_TEST_CATALOG ltc ON lo.test_code = ltc.test_code
        JOIN ENCOUNTER e ON lo.encounter_id = e.encounter_id
        WHERE lo.lab_order_id = NEW.lab_order_id;

        -- Log critical result alert
        INSERT INTO AUDIT_LOG (user_id, action_type, table_name, record_id, notes, event_time)
        VALUES (NULL, 'CRITICAL_LAB_ALERT', 'LAB_RESULT', CAST(NEW.result_id AS CHAR),
                CONCAT('CRITICAL: Test "', v_test_name, '" for patient ', v_patient_id,
                       ' | Value: ', IFNULL(NEW.result_value, 'N/A'),
                       ' ', IFNULL(NEW.result_unit, ''),
                       ' | Ref: ', IFNULL(NEW.reference_range, 'N/A'),
                       ' | Ordering doctor: ', v_doctor_id,
                       ' - REQUIRES IMMEDIATE PHYSICIAN ACKNOWLEDGMENT'),
                NOW());

        -- Update lab order status to completed
        UPDATE LAB_ORDER
        SET order_status = 'Completed'
        WHERE lab_order_id = NEW.lab_order_id;
    END IF;
END //

-- ============================================================
-- 8. ENCOUNTER DATE VALIDATION
--    Ensures encounter date is not in the future
--    Ensures encounter date is after patient DOB
-- ============================================================

CREATE TRIGGER trg_encounter_date_validation
BEFORE INSERT ON ENCOUNTER
FOR EACH ROW
BEGIN
    DECLARE v_dob DATE;

    -- Check not in the future (allow 1 day tolerance for timezone)
    IF NEW.encounter_date_time > DATE_ADD(NOW(), INTERVAL 1 DAY) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'VALIDATION ERROR: Encounter date cannot be in the future.';
    END IF;

    -- Check after patient DOB
    SELECT date_of_birth INTO v_dob
    FROM PATIENT
    WHERE health_id = NEW.health_id;

    IF DATE(NEW.encounter_date_time) < v_dob THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'VALIDATION ERROR: Encounter date cannot be before patient date of birth.';
    END IF;
END //

-- ============================================================
-- 9. EMERGENCY ACCESS AUDIT
--    Logs every emergency access automatically
-- ============================================================

CREATE TRIGGER trg_emergency_access_audit
AFTER INSERT ON EMERGENCY_ACCESS
FOR EACH ROW
BEGIN
    INSERT INTO AUDIT_LOG (user_id, action_type, table_name, record_id, notes, event_time)
    VALUES (NULL, 'EMERGENCY_ACCESS', 'EMERGENCY_ACCESS', CAST(NEW.access_id AS CHAR),
            CONCAT('Emergency access to patient ', NEW.health_id,
                   ' by doctor ', NEW.doctor_id,
                   ' | Type: ', NEW.emergency_type,
                   ' | Justification: ', NEW.justification),
            NOW());
END //

-- ============================================================
-- 10. PATIENT RECORD MODIFICATION AUDIT
--     Tracks all changes to patient records
-- ============================================================

CREATE TRIGGER trg_patient_update_audit
AFTER UPDATE ON PATIENT
FOR EACH ROW
BEGIN
    INSERT INTO AUDIT_LOG (user_id, action_type, table_name, record_id, old_value, new_value, notes, event_time)
    VALUES (NULL, 'UPDATE', 'PATIENT', OLD.health_id,
            CONCAT('name:', OLD.fname, ' ', IFNULL(OLD.mname,''), ' ', OLD.lname,
                   '|gender:', OLD.gender,
                   '|blood_group:', IFNULL(OLD.blood_group,''),
                   '|city:', IFNULL(OLD.address_city,'')),
            CONCAT('name:', NEW.fname, ' ', IFNULL(NEW.mname,''), ' ', NEW.lname,
                   '|gender:', NEW.gender,
                   '|blood_group:', IFNULL(NEW.blood_group,''),
                   '|city:', IFNULL(NEW.address_city,'')),
            'Patient record modified',
            NOW());
END //

-- ============================================================
-- 11. PRESCRIPTION STATUS AUDIT
--     Logs prescription status changes
-- ============================================================

CREATE TRIGGER trg_prescription_status_audit
AFTER UPDATE ON PRESCRIPTION
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO AUDIT_LOG (user_id, action_type, table_name, record_id, old_value, new_value, notes, event_time)
        VALUES (NULL, 'STATUS_CHANGE', 'PRESCRIPTION', CAST(NEW.prescription_id AS CHAR),
                OLD.status, NEW.status,
                CONCAT('Prescription ', NEW.prescription_id, ' status changed from ', OLD.status, ' to ', NEW.status),
                NOW());
    END IF;
END //

-- ============================================================
-- 12. CONSENT REVOCATION - Immediate effect
-- ============================================================

CREATE TRIGGER trg_consent_revoke
BEFORE UPDATE ON CONSENT
FOR EACH ROW
BEGIN
    -- If status is being changed to Revoked, set revoked_date automatically
    IF NEW.status = 'Revoked' AND OLD.status <> 'Revoked' THEN
        SET NEW.revoked_date = CURDATE();

        INSERT INTO AUDIT_LOG (user_id, action_type, table_name, record_id, notes, event_time)
        VALUES (NULL, 'CONSENT_REVOKED', 'CONSENT', CAST(NEW.consent_id AS CHAR),
                CONCAT('Consent revoked for patient ', NEW.health_id,
                       ' at hospital ', NEW.hospital_id),
                NOW());
    END IF;
END //

DELIMITER ;
