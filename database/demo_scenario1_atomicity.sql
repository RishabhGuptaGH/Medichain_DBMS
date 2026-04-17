-- ============================================================
-- MEDICHAIN — TASK 6 DEMO: SCENARIO 1
-- Atomicity & Consistency (The ROLLBACK)
--
-- Story: Dr. Kapoor starts an Outpatient Encounter for a patient
--   and immediately writes a Prescription. He accidentally sets
--   the end date BEFORE the start date. The PRESCRIPTION INSERT
--   fails (CHECK constraint chk_rx_dates). We ROLLBACK the whole
--   transaction — proving the Encounter was also undone.
--
-- Database: MySQL 8.0
-- Run in: MySQL Workbench or CLI, block by block
-- Requires: seed data loaded (uses doctor_id=1, hospital_id=1)
-- ============================================================

USE medichain;


-- ─────────────────────────────────────────────────────────────
-- SETUP  (run once before the demo)
-- ─────────────────────────────────────────────────────────────

INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender, address_city)
VALUES ('DEMO-ATOM-01', 'Arjun', 'Mehta', '1990-03-15', 'M', 'Delhi');

SELECT '[ SETUP ] Patient DEMO-ATOM-01 created. Seed doctor_id=1 and hospital_id=1 assumed.' AS '';
SELECT health_id, fname, lname, date_of_birth FROM PATIENT WHERE health_id = 'DEMO-ATOM-01';


-- ─────────────────────────────────────────────────────────────
-- STEP 1 — Prove the DB is clean before we start
-- ─────────────────────────────────────────────────────────────

SELECT '[ PRE-CHECK ] No encounter exists for DEMO-ATOM-01 yet.' AS '';
SELECT COUNT(*) AS encounter_count FROM ENCOUNTER WHERE health_id = 'DEMO-ATOM-01';
-- Expected: 0


-- ─────────────────────────────────────────────────────────────
-- STEP 2 — Begin the transaction
-- ─────────────────────────────────────────────────────────────

START TRANSACTION;

SELECT '[ TX STARTED ] Transaction is open. autocommit is suspended.' AS '';


-- ─────────────────────────────────────────────────────────────
-- STEP 3 — INSERT the Encounter  (this SUCCEEDS)
-- ─────────────────────────────────────────────────────────────

INSERT INTO ENCOUNTER (health_id, hospital_id, encounter_date_time, encounter_type, chief_complaint)
VALUES ('DEMO-ATOM-01', 1, NOW(), 'Outpatient', 'High fever and persistent cough');

SET @enc_id = LAST_INSERT_ID();

SELECT '[ STEP 3 ] Encounter INSERT succeeded. Visible INSIDE this transaction:' AS '';
SELECT encounter_id, health_id, encounter_type, chief_complaint
FROM   ENCOUNTER
WHERE  encounter_id = @enc_id;
-- Expected: 1 row — the encounter exists inside the transaction


-- ─────────────────────────────────────────────────────────────
-- STEP 4 — INSERT the Prescription with end_date < start_date
--           This VIOLATES check constraint chk_rx_dates and FAILS
--
--   chk_rx_dates: end_date >= start_date  (when both are non-null)
--   We pass:      start_date = '2026-06-01',  end_date = '2026-05-01'
--   Expected ERROR 3819: Check constraint 'chk_rx_dates' is violated.
-- ─────────────────────────────────────────────────────────────

SELECT '[ STEP 4 ] Attempting to INSERT Prescription — end_date BEFORE start_date...' AS '';

INSERT INTO PRESCRIPTION (encounter_id, doctor_id, prescription_date, start_date, end_date, status)
VALUES (@enc_id, 1, CURDATE(), '2026-06-01', '2026-05-01', 'Active');

-- *** ERROR 3819 fires here ***
-- The Prescription INSERT fails.
-- The Encounter from Step 3 is still "pending" — the transaction is still open.


-- ─────────────────────────────────────────────────────────────
-- STEP 5 — Demonstrate that the Encounter is STILL visible
--           (the transaction is still open, just the last statement failed)
-- ─────────────────────────────────────────────────────────────

SELECT '[ STEP 5 ] Error occurred. Encounter still visible INSIDE the open transaction:' AS '';
SELECT encounter_id, health_id, encounter_type
FROM   ENCOUNTER
WHERE  encounter_id = @enc_id;
-- Still 1 row — the encounter is stuck in limbo inside the uncommitted transaction


-- ─────────────────────────────────────────────────────────────
-- STEP 6 — ROLLBACK the entire transaction
-- ─────────────────────────────────────────────────────────────

ROLLBACK;

SELECT '[ STEP 6 ] ROLLBACK issued. All work inside this transaction is UNDONE.' AS '';


-- ─────────────────────────────────────────────────────────────
-- STEP 7 — PROOF: Both the Encounter AND the Prescription are gone
-- ─────────────────────────────────────────────────────────────

SELECT '[ PROOF ] Encounter count after ROLLBACK:' AS '';
SELECT COUNT(*) AS encounter_count FROM ENCOUNTER WHERE health_id = 'DEMO-ATOM-01';
-- Expected: 0  — the Encounter was rolled back even though it had succeeded

SELECT COUNT(*) AS prescription_count
FROM   PRESCRIPTION p
JOIN   ENCOUNTER    e ON p.encounter_id = e.encounter_id
WHERE  e.health_id = 'DEMO-ATOM-01';
-- Expected: 0


-- ─────────────────────────────────────────────────────────────
-- CLEANUP
-- ─────────────────────────────────────────────────────────────

DELETE FROM PATIENT WHERE health_id = 'DEMO-ATOM-01';
SELECT '[ CLEANUP ] Demo patient removed.' AS '';


-- ─────────────────────────────────────────────────────────────
-- WHAT HAPPENED UNDER THE HOOD
-- ─────────────────────────────────────────────────────────────
--
-- InnoDB writes every change to an UNDO LOG before touching live data.
-- START TRANSACTION marks a "before" snapshot in the undo log.
--
-- Step 3 (Encounter INSERT):
--   InnoDB writes the row to the buffer pool + undo log. Visible to
--   THIS session only — other sessions see nothing (MVCC isolation).
--
-- Step 4 (Prescription INSERT with bad dates):
--   MySQL evaluates chk_rx_dates BEFORE writing: end_date < start_date → FAIL.
--   The row is never written. The transaction stays open; MySQL does NOT
--   auto-rollback on a CHECK violation (unlike FK violations in strict mode).
--
-- Step 6 (ROLLBACK):
--   InnoDB replays the undo log in reverse, physically removing the
--   Encounter row from the buffer pool. The redo log is discarded.
--   Both tables return to their state at START TRANSACTION.
--
-- This is ATOMICITY: the Encounter + Prescription are one logical unit.
-- Either BOTH land in the database, or NEITHER does. No partial state.
--
-- CONSISTENCY: the CHECK constraint and the ROLLBACK together ensure
-- the DB never holds an Encounter with a broken linked Prescription.
-- Every committed state satisfies all declared schema constraints.
-- ─────────────────────────────────────────────────────────────
