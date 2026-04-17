-- ============================================================
-- MediChain - Stored Procedures & Functions
-- ============================================================

USE medichain;

DELIMITER //

-- ============================================================
-- 1. Calculate Patient Age
-- ============================================================
CREATE FUNCTION fn_patient_age(p_health_id VARCHAR(50))
RETURNS INT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_dob DATE;
    DECLARE v_age INT;

    SELECT date_of_birth INTO v_dob
    FROM PATIENT WHERE health_id = p_health_id;

    IF v_dob IS NULL THEN RETURN NULL; END IF;

    SET v_age = TIMESTAMPDIFF(YEAR, v_dob, CURDATE());
    RETURN v_age;
END //

-- ============================================================
-- 2. Get Patient Age Category
-- ============================================================
CREATE FUNCTION fn_age_category(p_health_id VARCHAR(50))
RETURNS VARCHAR(20)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_age INT;
    SET v_age = fn_patient_age(p_health_id);

    IF v_age IS NULL THEN RETURN 'Unknown'; END IF;
    IF v_age < 1 THEN RETURN 'Infant';
    ELSEIF v_age < 13 THEN RETURN 'Child';
    ELSEIF v_age < 18 THEN RETURN 'Teenager';
    ELSEIF v_age < 65 THEN RETURN 'Adult';
    ELSE RETURN 'Senior';
    END IF;
END //

-- ============================================================
-- 3. Verify Audit Chain Integrity
-- ============================================================
CREATE PROCEDURE sp_verify_audit_chain(OUT p_valid BOOLEAN, OUT p_broken_at BIGINT)
BEGIN
    DECLARE v_log_id BIGINT;
    DECLARE v_expected_hash VARCHAR(255);
    DECLARE v_stored_hash VARCHAR(255);
    DECLARE v_prev_hash VARCHAR(255);
    DECLARE v_action VARCHAR(50);
    DECLARE v_table_name VARCHAR(100);
    DECLARE v_event_time DATETIME;
    DECLARE v_user_id BIGINT;
    DECLARE v_notes TEXT;
    DECLARE v_stored_prev VARCHAR(255);
    DECLARE v_last_hash VARCHAR(255) DEFAULT 'GENESIS_BLOCK_MEDICHAIN';
    DECLARE v_done INT DEFAULT 0;

    DECLARE cur CURSOR FOR
        SELECT log_id, action_type, table_name, event_time, user_id, notes, hash_value, prev_hash
        FROM AUDIT_LOG ORDER BY log_id ASC;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    SET p_valid = TRUE;
    SET p_broken_at = NULL;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_log_id, v_action, v_table_name, v_event_time, v_user_id, v_notes, v_stored_hash, v_stored_prev;
        IF v_done THEN LEAVE read_loop; END IF;

        -- Check prev_hash matches last hash
        IF v_stored_prev <> v_last_hash THEN
            SET p_valid = FALSE;
            SET p_broken_at = v_log_id;
            LEAVE read_loop;
        END IF;

        -- Recompute hash
        SET v_expected_hash = SHA2(
            CONCAT(
                IFNULL(v_last_hash, ''),
                IFNULL(v_action, ''),
                IFNULL(v_table_name, ''),
                IFNULL(CAST(v_event_time AS CHAR), ''),
                IFNULL(CAST(v_user_id AS CHAR), ''),
                IFNULL(v_notes, '')
            ), 256
        );

        IF v_expected_hash <> v_stored_hash THEN
            SET p_valid = FALSE;
            SET p_broken_at = v_log_id;
            LEAVE read_loop;
        END IF;

        SET v_last_hash = v_stored_hash;
    END LOOP;
    CLOSE cur;
END //

-- ============================================================
-- 4. Check Consent Before Record Access
-- ============================================================
CREATE FUNCTION fn_check_consent(
    p_health_id VARCHAR(50),
    p_hospital_id BIGINT,
    p_purpose VARCHAR(100)
) RETURNS BOOLEAN
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_count INT;

    SELECT COUNT(*) INTO v_count
    FROM CONSENT
    WHERE health_id = p_health_id
      AND hospital_id = p_hospital_id
      AND status = 'Active'
      AND effective_date <= CURDATE()
      AND (expiration_date IS NULL OR expiration_date >= CURDATE());

    RETURN v_count > 0;
END //

-- ============================================================
-- 5. Register Emergency Access (Transaction)
-- ============================================================
CREATE PROCEDURE sp_emergency_access(
    IN p_health_id VARCHAR(50),
    IN p_doctor_id BIGINT,
    IN p_emergency_type VARCHAR(100),
    IN p_justification TEXT,
    OUT p_access_id BIGINT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Insert emergency access record
    INSERT INTO EMERGENCY_ACCESS (health_id, doctor_id, emergency_type, justification, access_time)
    VALUES (p_health_id, p_doctor_id, p_emergency_type, p_justification, NOW());

    SET p_access_id = LAST_INSERT_ID();

    COMMIT;
END //

-- ============================================================
-- 6. Create Full Prescription (Transaction)
--    Atomically creates prescription + items
-- ============================================================
CREATE PROCEDURE sp_create_prescription(
    IN p_encounter_id BIGINT,
    IN p_doctor_id BIGINT,
    IN p_start_date DATE,
    IN p_end_date DATE,
    OUT p_prescription_id BIGINT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO PRESCRIPTION (encounter_id, doctor_id, prescription_date, start_date, end_date, status)
    VALUES (p_encounter_id, p_doctor_id, CURDATE(), p_start_date, p_end_date, 'Active');

    SET p_prescription_id = LAST_INSERT_ID();

    -- Log to audit
    INSERT INTO AUDIT_LOG (action_type, table_name, record_id, notes, event_time)
    VALUES ('CREATE', 'PRESCRIPTION', CAST(p_prescription_id AS CHAR),
            CONCAT('Prescription created by doctor ', p_doctor_id, ' for encounter ', p_encounter_id),
            NOW());

    COMMIT;
END //

-- ============================================================
-- 7. Create Lab Order with Specimen (Transaction)
-- ============================================================
CREATE PROCEDURE sp_create_lab_order(
    IN p_encounter_id BIGINT,
    IN p_doctor_id BIGINT,
    IN p_test_code VARCHAR(50),
    IN p_priority VARCHAR(10),
    IN p_clinical_info TEXT,
    OUT p_order_id BIGINT
)
BEGIN
    DECLARE v_specimen_id VARCHAR(50);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Generate specimen ID
    SET v_specimen_id = CONCAT('SPEC-', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'), '-', FLOOR(RAND() * 10000));

    INSERT INTO LAB_ORDER (encounter_id, doctor_id, test_code, priority, clinical_info, specimen_id, order_date_time)
    VALUES (p_encounter_id, p_doctor_id, p_test_code, p_priority, p_clinical_info, v_specimen_id, NOW());

    SET p_order_id = LAST_INSERT_ID();

    -- Audit log
    INSERT INTO AUDIT_LOG (action_type, table_name, record_id, notes, event_time)
    VALUES ('CREATE', 'LAB_ORDER', CAST(p_order_id AS CHAR),
            CONCAT('Lab order for test ', p_test_code, ' by doctor ', p_doctor_id),
            NOW());

    COMMIT;
END //

-- ============================================================
-- 8. Get Patient Complete Medical Summary
-- ============================================================
CREATE PROCEDURE sp_patient_summary(IN p_health_id VARCHAR(50))
BEGIN
    -- Patient demographics
    SELECT p.*,
           fn_patient_age(p.health_id) AS age,
           fn_age_category(p.health_id) AS age_category
    FROM PATIENT p
    WHERE p.health_id = p_health_id;

    -- Active allergies
    SELECT * FROM PATIENT_ALLERGY
    WHERE health_id = p_health_id AND status = 'Active';

    -- Recent encounters (last 10)
    SELECT e.*, h.hospital_name
    FROM ENCOUNTER e
    LEFT JOIN HOSPITAL h ON e.hospital_id = h.hospital_id
    WHERE e.health_id = p_health_id
    ORDER BY e.encounter_date_time DESC
    LIMIT 10;

    -- Active prescriptions
    SELECT pr.*, m.generic_name, m.brand_name, pi.dosage_strength, pi.frequency
    FROM PRESCRIPTION pr
    JOIN PRESCRIPTION_ITEM pi ON pr.prescription_id = pi.prescription_id
    JOIN MEDICATION m ON pi.medication_id = m.medication_id
    WHERE pr.encounter_id IN (
        SELECT encounter_id FROM ENCOUNTER WHERE health_id = p_health_id
    )
    AND pr.status = 'Active';

    -- Recent lab results (last 10)
    SELECT lr.*, lo.test_code, ltc.test_name, lo.order_date_time
    FROM LAB_RESULT lr
    JOIN LAB_ORDER lo ON lr.lab_order_id = lo.lab_order_id
    JOIN LAB_TEST_CATALOG ltc ON lo.test_code = ltc.test_code
    WHERE lo.encounter_id IN (
        SELECT encounter_id FROM ENCOUNTER WHERE health_id = p_health_id
    )
    ORDER BY lr.result_date DESC
    LIMIT 10;
END //

DELIMITER ;
