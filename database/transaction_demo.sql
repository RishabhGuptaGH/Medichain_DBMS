-- ============================================================
-- MediChain - Database Transaction Demo
-- Demonstrates ACID properties with real SQL transactions
-- Run each section step-by-step in MySQL Workbench or CLI
-- ============================================================

USE medichain;

-- ============================================================
-- SETUP: Check current isolation level
-- ============================================================
SELECT @@transaction_isolation AS current_isolation_level;
-- Expected: REPEATABLE-READ (MySQL default)


-- ************************************************************
-- TEST 1: SUCCESSFUL TRANSACTION COMMIT
-- Goal: Insert data in a transaction, commit, verify it persists
-- ************************************************************

-- Step 1: Begin transaction
START TRANSACTION;

-- Step 2: Insert a test patient
INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender, address_city)
VALUES ('TX-COMMIT-001', 'Transaction', 'CommitTest', '2000-01-15', 'M', 'Mumbai');

-- Step 3: Verify data is visible WITHIN the transaction
SELECT health_id, fname, lname, address_city FROM PATIENT WHERE health_id = 'TX-COMMIT-001';
-- Expected: 1 row found (visible inside transaction before commit)

-- Step 4: COMMIT the transaction
COMMIT;

-- Step 5: Verify data PERSISTS after commit
SELECT health_id, fname, lname, address_city FROM PATIENT WHERE health_id = 'TX-COMMIT-001';
-- Expected: 1 row found - data is permanently saved
-- CONCLUSION: After COMMIT, the data is durable and persists in the database.

-- Cleanup
DELETE FROM PATIENT WHERE health_id = 'TX-COMMIT-001';


-- ************************************************************
-- TEST 2: TRANSACTION ROLLBACK ON ERROR
-- Goal: Insert data, then ROLLBACK, verify nothing was saved
-- Demonstrates ATOMICITY - all or nothing
-- ************************************************************

-- Step 1: Begin transaction
START TRANSACTION;

-- Step 2: Insert a test patient
INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender, address_city)
VALUES ('TX-ROLLBACK-001', 'Transaction', 'RollbackTest', '1995-06-20', 'F', 'Delhi');

-- Step 3: Verify data exists inside the transaction
SELECT health_id, fname, lname FROM PATIENT WHERE health_id = 'TX-ROLLBACK-001';
-- Expected: 1 row found (visible inside the transaction)

-- Step 4: Oh no! Something went wrong. ROLLBACK the transaction
ROLLBACK;

-- Step 5: Check if data exists after rollback
SELECT health_id, fname, lname FROM PATIENT WHERE health_id = 'TX-ROLLBACK-001';
-- Expected: 0 rows - the INSERT was completely undone!
-- CONCLUSION: ROLLBACK undoes ALL changes made during the transaction.
-- This demonstrates ATOMICITY - the transaction is all-or-nothing.


-- ************************************************************
-- TEST 3: ATOMIC MULTI-TABLE INSERT (COMMIT)
-- Goal: Insert across PATIENT + PATIENT_ALLERGY atomically
-- Both succeed together or neither is saved
-- ************************************************************

-- Step 1: Begin transaction
START TRANSACTION;

-- Step 2: Insert patient
INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender)
VALUES ('TX-MULTI-001', 'Atomic', 'MultiTable', '1990-03-10', 'M');

-- Step 3: Insert allergy for the same patient
INSERT INTO PATIENT_ALLERGY (health_id, allergen, severity, status)
VALUES ('TX-MULTI-001', 'Penicillin', 'Severe', 'Active');

-- Step 4: Insert another allergy
INSERT INTO PATIENT_ALLERGY (health_id, allergen, severity, status)
VALUES ('TX-MULTI-001', 'Aspirin', 'Moderate', 'Active');

-- Step 5: Verify both tables have data
SELECT 'PATIENT' AS table_name, COUNT(*) AS row_count FROM PATIENT WHERE health_id = 'TX-MULTI-001'
UNION ALL
SELECT 'PATIENT_ALLERGY', COUNT(*) FROM PATIENT_ALLERGY WHERE health_id = 'TX-MULTI-001';
-- Expected: PATIENT=1, PATIENT_ALLERGY=2

-- Step 6: COMMIT - both tables saved atomically
COMMIT;

-- Step 7: Verify after commit
SELECT p.health_id, p.fname, p.lname, pa.allergen, pa.severity
FROM PATIENT p
JOIN PATIENT_ALLERGY pa ON p.health_id = pa.health_id
WHERE p.health_id = 'TX-MULTI-001';
-- Expected: 2 rows showing patient with both allergies
-- CONCLUSION: Both tables were committed atomically in a single transaction.

-- Cleanup
DELETE FROM PATIENT_ALLERGY WHERE health_id = 'TX-MULTI-001';
DELETE FROM PATIENT WHERE health_id = 'TX-MULTI-001';


-- ************************************************************
-- TEST 4: MULTI-TABLE ROLLBACK ON CONSTRAINT VIOLATION
-- Goal: Insert patient, then violate FK constraint, rollback ALL
-- Demonstrates atomicity across multiple tables
-- ************************************************************

-- Step 1: Begin transaction
START TRANSACTION;

-- Step 2: Insert a valid patient
INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender)
VALUES ('TX-FKFAIL-001', 'Constraint', 'ViolationTest', '1988-07-25', 'F');

-- Step 3: Verify patient was inserted
SELECT health_id, fname FROM PATIENT WHERE health_id = 'TX-FKFAIL-001';
-- Expected: 1 row

-- Step 4: Try to insert an allergy for a NON-EXISTENT patient (FK violation!)
-- This will ERROR because 'NONEXISTENT-PATIENT' doesn't exist in PATIENT table
INSERT INTO PATIENT_ALLERGY (health_id, allergen, severity, status)
VALUES ('NONEXISTENT-PATIENT', 'Latex', 'Mild', 'Active');
-- Expected: ERROR 1452 - Cannot add or update a child row: a foreign key constraint fails

-- Step 5: The error occurred! ROLLBACK the ENTIRE transaction
ROLLBACK;

-- Step 6: Check if the VALID patient insert also got rolled back
SELECT health_id, fname FROM PATIENT WHERE health_id = 'TX-FKFAIL-001';
-- Expected: 0 rows! The valid INSERT was also rolled back!
-- CONCLUSION: When ANY part of a transaction fails and we ROLLBACK,
-- ALL previous operations in that transaction are undone.
-- This is ATOMICITY - all or nothing, even across multiple tables.


-- ************************************************************
-- TEST 5: DIRTY READ PREVENTION (ISOLATION)
-- Goal: Prove that uncommitted data is NOT visible to other sessions
-- NOTE: This test requires TWO separate MySQL sessions/connections!
-- ************************************************************

-- === SESSION A (Run in first MySQL window) ===

-- A-Step 1: Begin transaction
START TRANSACTION;

-- A-Step 2: Insert a patient but DO NOT commit
INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender)
VALUES ('TX-DIRTY-001', 'DirtyRead', 'TestPatient', '1985-01-01', 'M');

-- A-Step 3: Verify it's visible in THIS session
SELECT health_id, fname FROM PATIENT WHERE health_id = 'TX-DIRTY-001';
-- Expected: 1 row (visible to Session A)

-- >>> NOW SWITCH TO SESSION B (open a new MySQL connection) <<<

-- === SESSION B (Run in second MySQL window) ===

-- B-Step 1: Try to read the uncommitted data from Session A
SELECT health_id, fname FROM PATIENT WHERE health_id = 'TX-DIRTY-001';
-- Expected: 0 rows! Session B CANNOT see Session A's uncommitted data!
-- This proves DIRTY READS are PREVENTED under REPEATABLE READ isolation.

-- >>> SWITCH BACK TO SESSION A <<<

-- === SESSION A (Back in first window) ===

-- A-Step 4: Rollback
ROLLBACK;

-- CONCLUSION: Under MySQL's default REPEATABLE READ isolation level,
-- one transaction's uncommitted changes are INVISIBLE to other transactions.
-- This prevents "dirty reads" - reading data that may never be committed.


-- ************************************************************
-- TEST 6: LOST UPDATE PREVENTION (CONFLICTING TRANSACTIONS)
-- Goal: Two transactions try to update the same row
-- NOTE: This test requires TWO separate MySQL sessions!
-- ************************************************************

-- Setup: Create a test patient
INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender, address_city)
VALUES ('TX-CONFLICT-001', 'Conflict', 'TestPatient', '1990-05-05', 'F', 'Delhi');

-- Verify setup
SELECT health_id, fname, address_city FROM PATIENT WHERE health_id = 'TX-CONFLICT-001';
-- Expected: address_city = 'Delhi'

-- === SESSION A (First MySQL window) ===

-- A-Step 1: Begin transaction and read
START TRANSACTION;
SELECT address_city FROM PATIENT WHERE health_id = 'TX-CONFLICT-001';
-- Expected: 'Delhi'

-- A-Step 2: Update the city (this acquires a ROW LOCK)
UPDATE PATIENT SET address_city = 'Mumbai' WHERE health_id = 'TX-CONFLICT-001';
-- Row is now LOCKED by Session A

-- >>> NOW SWITCH TO SESSION B <<<

-- === SESSION B (Second MySQL window) ===

-- B-Step 1: Begin transaction and read
START TRANSACTION;
SELECT address_city FROM PATIENT WHERE health_id = 'TX-CONFLICT-001';
-- Expected: 'Delhi' (reads from MVCC snapshot, doesn't see A's uncommitted update)

-- B-Step 2: Try to update the same row
UPDATE PATIENT SET address_city = 'Kolkata' WHERE health_id = 'TX-CONFLICT-001';
-- THIS WILL BLOCK/WAIT! Session B is waiting for Session A to release the row lock!
-- (You'll see the query hanging/waiting...)

-- >>> SWITCH BACK TO SESSION A <<<

-- === SESSION A (First window) ===

-- A-Step 3: COMMIT Session A's changes
COMMIT;
-- This releases the row lock. Session B's UPDATE can now proceed.

-- >>> SWITCH BACK TO SESSION B <<<

-- === SESSION B (Second window) ===
-- Session B's UPDATE should now complete (it was waiting for the lock)

-- B-Step 3: COMMIT Session B's changes
COMMIT;

-- Check final value (run in either session)
SELECT health_id, address_city FROM PATIENT WHERE health_id = 'TX-CONFLICT-001';
-- Expected: 'Kolkata' (Session B's update was applied AFTER Session A's)
-- CONCLUSION: MySQL's row-level locking made Session B WAIT until Session A committed.
-- No update was lost. Both updates were applied sequentially.
-- Without transactions, a concurrent write could overwrite another's changes (lost update).

-- Cleanup
DELETE FROM PATIENT WHERE health_id = 'TX-CONFLICT-001';


-- ************************************************************
-- TEST 7: SAVEPOINT AND PARTIAL ROLLBACK
-- Goal: Rollback only PART of a transaction using SAVEPOINTs
-- ************************************************************

-- Step 1: Begin transaction
START TRANSACTION;

-- Step 2: Insert first patient
INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender)
VALUES ('TX-SP-001', 'Savepoint', 'Patient1', '2000-01-01', 'M');

-- Step 3: Create a SAVEPOINT after the first insert
SAVEPOINT after_first_insert;

-- Step 4: Insert second patient
INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender)
VALUES ('TX-SP-002', 'Savepoint', 'Patient2', '2000-02-02', 'F');

-- Step 5: Check - both patients exist
SELECT health_id, fname, lname FROM PATIENT WHERE health_id IN ('TX-SP-001', 'TX-SP-002');
-- Expected: 2 rows

-- Step 6: Oops, we only want Patient1. ROLLBACK TO the savepoint (undoes Patient2 only!)
ROLLBACK TO after_first_insert;

-- Step 7: Check - only Patient1 remains
SELECT health_id, fname, lname FROM PATIENT WHERE health_id IN ('TX-SP-001', 'TX-SP-002');
-- Expected: 1 row (only TX-SP-001)

-- Step 8: COMMIT - saves Patient1 only
COMMIT;

-- Step 9: Verify final state
SELECT health_id, fname, lname FROM PATIENT WHERE health_id IN ('TX-SP-001', 'TX-SP-002');
-- Expected: 1 row - TX-SP-001 is saved, TX-SP-002 was rolled back
-- CONCLUSION: SAVEPOINTs allow partial rollbacks within a transaction.
-- You can undo recent operations while keeping earlier ones.

-- Cleanup
DELETE FROM PATIENT WHERE health_id IN ('TX-SP-001', 'TX-SP-002');


-- ************************************************************
-- TEST 8: TRANSACTION WITH AUDIT LOG (TRIGGER INTERACTION)
-- Goal: Show that triggers fire WITHIN the transaction context
-- If we rollback, trigger-inserted rows are also rolled back
-- ************************************************************

-- Step 1: Note current max audit log ID
SELECT MAX(log_id) AS current_max_audit_id FROM AUDIT_LOG;

-- Step 2: Begin transaction
START TRANSACTION;

-- Step 3: Update a patient (this fires trg_patient_update_audit trigger)
UPDATE PATIENT SET address_city = 'TestCity_TxnDemo' WHERE health_id = 'HID-001';

-- Step 4: Check that the trigger created an audit log entry
SELECT log_id, action_type, table_name, notes FROM AUDIT_LOG
WHERE table_name = 'PATIENT' AND record_id = 'HID-001'
ORDER BY log_id DESC LIMIT 1;
-- Expected: Shows the audit entry created by the trigger INSIDE this transaction

-- Step 5: ROLLBACK - undo the patient update AND the trigger's audit entry
ROLLBACK;

-- Step 6: Verify patient city was NOT changed
SELECT health_id, address_city FROM PATIENT WHERE health_id = 'HID-001';
-- Expected: Original city (not 'TestCity_TxnDemo')

-- CONCLUSION: Triggers execute WITHIN the transaction context.
-- When we ROLLBACK, both the original UPDATE and the trigger's INSERT
-- into AUDIT_LOG are rolled back together. This maintains consistency.


-- ************************************************************
-- TEST 9: CONFLICTING DOCTOR UPDATES ON SAME PATIENT
-- Goal: Two doctors simultaneously modify the same patient's record
-- Doctor A updates emergency contact, Doctor B updates blood group
-- MySQL row-level locking serializes the conflicting writes
-- NOTE: This test requires TWO separate MySQL sessions!
-- ************************************************************

-- Setup: Create a test patient that both doctors will try to modify
INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender, blood_group,
                     emergency_contact_name, emergency_contact_phone, address_city)
VALUES ('TX-DOC-CONFLICT', 'Ravi', 'SharedPatient', '1992-08-14', 'M', 'B+',
        'OldContact', '9999900000', 'Pune');

-- Verify initial state
SELECT health_id, fname, blood_group, emergency_contact_name, emergency_contact_phone
FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';
-- Expected: blood_group='B+', emergency_contact_name='OldContact', phone='9999900000'


-- === SESSION A — Doctor A (Cardiologist) ===
-- Doctor A reviewed the patient and wants to update the emergency contact

-- A-Step 1: Begin transaction and read the patient record
START TRANSACTION;
SELECT health_id, fname, blood_group, emergency_contact_name, emergency_contact_phone
FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';
-- Doctor A sees: blood_group='B+', emergency_contact='OldContact'

-- A-Step 2: Doctor A updates the emergency contact info
UPDATE PATIENT
SET emergency_contact_name  = 'Priya Sharma',
    emergency_contact_phone = '9876500001'
WHERE health_id = 'TX-DOC-CONFLICT';
-- Row is now LOCKED by Session A's transaction
-- Doctor A has not committed yet...

-- >>> NOW SWITCH TO SESSION B (open a second MySQL connection) <<<


-- === SESSION B — Doctor B (Pathologist) ===
-- Doctor B got new lab results and wants to correct the blood group

-- B-Step 1: Begin transaction and read the patient record
START TRANSACTION;
SELECT health_id, fname, blood_group, emergency_contact_name, emergency_contact_phone
FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';
-- Doctor B sees: blood_group='B+', emergency_contact='OldContact'
-- (MVCC snapshot — Doctor A's uncommitted changes are INVISIBLE here)

-- B-Step 2: Doctor B tries to update the blood group on the SAME row
UPDATE PATIENT
SET blood_group = 'AB+'
WHERE health_id = 'TX-DOC-CONFLICT';
-- *** THIS QUERY WILL HANG / BLOCK! ***
-- Session B is WAITING for Session A to release the row lock.
-- MySQL prevents both doctors from writing to the same row at once.

-- >>> SWITCH BACK TO SESSION A <<<


-- === SESSION A — Doctor A commits ===

-- A-Step 3: Doctor A commits the emergency contact update
COMMIT;
-- Row lock is released. Session B's blocked UPDATE now proceeds.

-- >>> SWITCH BACK TO SESSION B <<<


-- === SESSION B — Doctor B's UPDATE resumes ===
-- Session B's UPDATE statement completes now (it was waiting for the lock)

-- B-Step 3: Doctor B verifies the change took effect inside the transaction
SELECT health_id, fname, blood_group, emergency_contact_name, emergency_contact_phone
FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';
-- Expected: blood_group = 'AB+' (changed), emergency_contact = 'Priya Sharma' (from Doctor A's commit)
-- The UPDATE DID execute — the row is modified inside this transaction

-- B-Step 4: Doctor B realizes the lab report was for a different patient — ROLLBACK!
ROLLBACK;


-- === VERIFY FINAL STATE (run in either session) ===
SELECT health_id, fname, blood_group, emergency_contact_name, emergency_contact_phone
FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';
-- Expected:
--   blood_group            = 'B+'           ← UNCHANGED (Doctor B rolled back)
--   emergency_contact_name = 'Priya Sharma' ← Doctor A's update (committed)
--   emergency_contact_phone= '9876500001'   ← Doctor A's update (committed)
--
-- Doctor A's COMMIT is preserved. Doctor B's ROLLBACK undid the blood group change.
-- The row-level lock ensured Doctor B waited for Doctor A to finish first,
-- and the ROLLBACK proved that uncommitted changes are safely discarded.
-- The database remains in a consistent state — no partial or lost updates.

-- Cleanup
DELETE FROM PATIENT WHERE health_id = 'TX-DOC-CONFLICT';


-- ************************************************************
-- SUMMARY OF ACID PROPERTIES DEMONSTRATED
-- ************************************************************
--
-- ATOMICITY (Tests 1-4, 7):
--   Transactions are all-or-nothing. COMMIT saves everything,
--   ROLLBACK undoes everything. Even across multiple tables.
--
-- CONSISTENCY (Test 4):
--   Constraint violations (FK, PK, CHECK) prevent invalid data.
--   The database moves from one valid state to another.
--
-- ISOLATION (Tests 5-6, 9):
--   Uncommitted data is invisible to other sessions (no dirty reads).
--   Row-level locking prevents conflicting concurrent updates.
--   Two doctors updating the same patient are serialized — no lost updates.
--   MySQL uses MVCC (Multi-Version Concurrency Control) for reads.
--
-- DURABILITY (Test 1):
--   Once COMMIT returns successfully, the data survives crashes.
--   The changes are written to the transaction log (redo log).
--
-- ============================================================
