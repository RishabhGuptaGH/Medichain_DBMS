-- ============================================================
-- CONFLICTING DOCTOR UPDATES ON SAME PATIENT — Full Demo
-- Covers: Commit, Conflict, Rollback, Partial Rollback (Savepoint)
-- Run entire script at once in MySQL Workbench (Ctrl+Shift+Enter)
-- ============================================================

USE medichain;

-- ─── SETUP ───
INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender, blood_group,
                     emergency_contact_name, emergency_contact_phone, address_city)
VALUES ('TX-DOC-CONFLICT', 'Ravi', 'SharedPatient', '1992-08-14', 'M', 'B+',
        'OldContact', '9999900000', 'Pune');

SELECT '✦ STEP 1 — Initial Patient State' AS '';
SELECT health_id, fname, blood_group, emergency_contact_name, emergency_contact_phone, address_city
FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';


-- ═══════════════════════════════════════════════════════════════
-- PART A: TWO DOCTORS UPDATE SAME ROW — BOTH COMMIT SUCCESSFULLY
-- ═══════════════════════════════════════════════════════════════

-- ─── DOCTOR A (Cardiologist) — updates emergency contact ───
START TRANSACTION;

    UPDATE PATIENT
    SET emergency_contact_name  = 'Priya Sharma',
        emergency_contact_phone = '9876500001'
    WHERE health_id = 'TX-DOC-CONFLICT';

    SELECT '✦ STEP 2 — Doctor A txn (UNCOMMITTED): emergency contact changed' AS '';
    SELECT health_id, blood_group, emergency_contact_name, emergency_contact_phone
    FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';

COMMIT;

SELECT '✦ STEP 3 — Doctor A COMMITTED. Emergency contact saved.' AS '';
SELECT health_id, blood_group, emergency_contact_name, emergency_contact_phone
FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';


-- ─── DOCTOR B (Pathologist) — updates blood group on SAME row ───
-- In concurrent execution, this UPDATE would BLOCK until Doctor A commits.
-- MySQL row-level lock prevents both writing the same row simultaneously.
START TRANSACTION;

    SELECT '✦ STEP 4 — Doctor B reads row (sees Doctor A''s committed data)' AS '';
    SELECT health_id, blood_group, emergency_contact_name, emergency_contact_phone
    FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';

    UPDATE PATIENT
    SET blood_group = 'AB+'
    WHERE health_id = 'TX-DOC-CONFLICT';

    SELECT '✦ STEP 5 — Doctor B txn (UNCOMMITTED): blood group changed to AB+' AS '';
    SELECT health_id, blood_group, emergency_contact_name, emergency_contact_phone
    FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';

    -- Doctor B realizes the lab report was for a different patient — ROLLBACK!
ROLLBACK;

SELECT '✦ STEP 6 — Doctor B ROLLED BACK: blood group unchanged!' AS '';
SELECT health_id, fname, blood_group, emergency_contact_name, emergency_contact_phone
FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';
-- blood_group = B+ (original, Doctor B's change undone) | emergency_contact = Priya Sharma (Doctor A's commit preserved)


-- ═══════════════════════════════════════════════════════════════
-- PART B: DOCTOR C MAKES A WRONG UPDATE — FULL ROLLBACK
-- Shows: entire transaction is undone, DB returns to previous state
-- ═══════════════════════════════════════════════════════════════

START TRANSACTION;

    -- Doctor C mistakenly changes blood group AND emergency contact
    UPDATE PATIENT
    SET blood_group             = 'O-',
        emergency_contact_name  = 'WRONG PERSON',
        emergency_contact_phone = '0000000000'
    WHERE health_id = 'TX-DOC-CONFLICT';

    SELECT '✦ STEP 7 — Doctor C txn (UNCOMMITTED): WRONG data written' AS '';
    SELECT health_id, blood_group, emergency_contact_name, emergency_contact_phone
    FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';
    -- Shows O-, WRONG PERSON, 0000000000

ROLLBACK;

SELECT '✦ STEP 8 — Doctor C ROLLED BACK: All changes undone!' AS '';
SELECT health_id, blood_group, emergency_contact_name, emergency_contact_phone
FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';
-- Back to B+, Priya Sharma, 9876500001 — as if Doctor C never touched it


-- ═══════════════════════════════════════════════════════════════
-- PART C: DOCTOR D MAKES TWO CHANGES — KEEPS ONE, ROLLS BACK OTHER
-- Shows: SAVEPOINT allows partial rollback within a transaction
-- ═══════════════════════════════════════════════════════════════

START TRANSACTION;

    -- Change 1: Doctor D correctly updates address
    UPDATE PATIENT
    SET address_city = 'Mumbai'
    WHERE health_id = 'TX-DOC-CONFLICT';

    SELECT '✦ STEP 9 — Doctor D updates address to Mumbai (CORRECT)' AS '';
    SELECT health_id, blood_group, address_city, emergency_contact_name
    FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';

    -- Create savepoint AFTER the good change
    SAVEPOINT after_address_update;

    -- Change 2: Doctor D accidentally overwrites emergency contact
    UPDATE PATIENT
    SET emergency_contact_name  = 'DeletedContact',
        emergency_contact_phone = '1111111111'
    WHERE health_id = 'TX-DOC-CONFLICT';

    SELECT '✦ STEP 10 — Doctor D also changed emergency contact (MISTAKE!)' AS '';
    SELECT health_id, blood_group, address_city, emergency_contact_name, emergency_contact_phone
    FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';
    -- Shows Mumbai + DeletedContact — both changes active

    -- Undo ONLY the emergency contact mistake, keep the address change
    ROLLBACK TO after_address_update;

    SELECT '✦ STEP 11 — ROLLBACK TO SAVEPOINT: contact restored, address kept' AS '';
    SELECT health_id, blood_group, address_city, emergency_contact_name, emergency_contact_phone
    FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';
    -- address_city = Mumbai (kept), emergency_contact = Priya Sharma (restored)

COMMIT;

SELECT '✦ STEP 12 — Doctor D COMMITTED: only the address change persisted' AS '';
SELECT health_id, fname, blood_group, address_city, emergency_contact_name, emergency_contact_phone
FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';


-- ═══════════════════════════════════════════════════════════════
-- FINAL SUMMARY
-- ═══════════════════════════════════════════════════════════════

SELECT '✦ COMPLETE CHANGE LOG' AS '';
SELECT 'Doctor A (Cardiologist)' AS doctor, 'emergency_contact → Priya Sharma'  AS change, 'COMMITTED' AS result
UNION ALL
SELECT 'Doctor B (Pathologist)',            'blood_group → AB+ (attempted)',                  'ROLLED BACK'
UNION ALL
SELECT 'Doctor C (Made mistake)',           'blood_group + contact → WRONG values',         'ROLLED BACK'
UNION ALL
SELECT 'Doctor D (Partial fix)',            'address → Mumbai (kept), contact → wrong (undone via SAVEPOINT)', 'PARTIAL COMMIT';


-- ─── CLEANUP ───
DELETE FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';

-- ============================================================
-- WHAT THIS DEMONSTRATES:
--
-- PART A — CONFLICT + ROLLBACK (Isolation + Atomicity)
--   Two doctors update the SAME row. Doctor A commits successfully.
--   Doctor B realizes mistake and ROLLS BACK — original blood group preserved.
--
-- PART B — FULL ROLLBACK (Atomicity)
--   Doctor C's wrong update is completely undone.
--   DB returns to its previous consistent state.
--
-- PART C — PARTIAL ROLLBACK with SAVEPOINT (Atomicity)
--   Doctor D makes 2 changes, realizes one is wrong.
--   SAVEPOINT lets us undo ONLY the mistake and keep the good change.
--
-- All under MySQL REPEATABLE READ isolation + InnoDB row locks.
-- ============================================================
