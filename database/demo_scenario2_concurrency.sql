-- ============================================================
-- MEDICHAIN — TASK 6 DEMO: SCENARIO 2
-- Isolation & Concurrency (Row-Level Lock / Lost Update Prevention)
--
-- Story: City General Hospital has exactly 10 beds available.
--   Two nurses simultaneously admit patients — both decrement
--   bed_capacity by 1. Without transactions this causes a
--   "lost update": both read 10, both write 9, one admission
--   vanishes. With InnoDB row-level locking, Nurse B's UPDATE
--   BLOCKS until Nurse A commits, then runs on the updated row.
--   Final result: 8 — both admissions counted, nothing lost.
--
-- Database: MySQL 8.0
-- Run in: TWO separate terminal/Workbench connections side-by-side
-- ============================================================

USE medichain;

-- ─────────────────────────────────────────────────────────────
-- SETUP  (run once in either terminal before the demo)
-- ─────────────────────────────────────────────────────────────

INSERT INTO HOSPITAL (hospital_name, license_number, bed_capacity, facility_type, address_city)
VALUES ('City General Hospital', 'LIC-DEMO-CGH-01', 10, 'General Hospital', 'Mumbai');

SET @hid = (SELECT hospital_id FROM HOSPITAL WHERE license_number = 'LIC-DEMO-CGH-01');

SELECT '[ SETUP ] Hospital created with 10 beds available.' AS '';
SELECT hospital_id, hospital_name, bed_capacity AS beds_available
FROM   HOSPITAL
WHERE  hospital_id = @hid;
-- Expected: beds_available = 10


-- ─────────────────────────────────────────────────────────────
--   *** OPEN TWO TERMINALS (or two Workbench connections) ***
--   Run the blocks below in alternating order as indicated.
--   The @hid variable must be set in BOTH sessions:
--
--   SET @hid = (SELECT hospital_id FROM HOSPITAL
--               WHERE license_number = 'LIC-DEMO-CGH-01');
-- ─────────────────────────────────────────────────────────────


-- ╔═══════════════════════════════════════════════════════════╗
-- ║  TERMINAL A — Nurse Priya (admitting Patient #1)         ║
-- ╚═══════════════════════════════════════════════════════════╝

-- [A-1] Set session variable (run this in Terminal A first)
SET @hid = (SELECT hospital_id FROM HOSPITAL WHERE license_number = 'LIC-DEMO-CGH-01');

-- [A-2] Nurse Priya reads current availability
SELECT hospital_name, bed_capacity AS beds_available
FROM   HOSPITAL
WHERE  hospital_id = @hid;
-- Expected: 10

-- [A-3] Nurse Priya starts her transaction and UPDATES the row
--        This acquires an EXCLUSIVE ROW LOCK on this hospital row.
START TRANSACTION;

UPDATE HOSPITAL
SET    bed_capacity = bed_capacity - 1
WHERE  hospital_id = @hid;

SELECT '[ A ] Priya updated: beds = 9 (UNCOMMITTED — row is now LOCKED)' AS '';
SELECT hospital_name, bed_capacity AS beds_available
FROM   HOSPITAL
WHERE  hospital_id = @hid;
-- Expected: 9 (visible only inside Priya's transaction)

-- >>> DO NOT COMMIT YET — switch to Terminal B <<<


-- ╔═══════════════════════════════════════════════════════════╗
-- ║  TERMINAL B — Nurse Anjali (admitting Patient #2)        ║
-- ╚═══════════════════════════════════════════════════════════╝

-- [B-1] Set session variable in Terminal B
SET @hid = (SELECT hospital_id FROM HOSPITAL WHERE license_number = 'LIC-DEMO-CGH-01');

-- [B-2] Nurse Anjali reads current availability
--        MVCC gives her the last COMMITTED value — still 10
SELECT hospital_name, bed_capacity AS beds_available
FROM   HOSPITAL
WHERE  hospital_id = @hid;
-- Expected: 10  (Priya's uncommitted change is INVISIBLE — no dirty read)

-- [B-3] Nurse Anjali starts her transaction and tries to UPDATE
--        *** THIS QUERY WILL HANG — IT IS WAITING FOR PRIYA'S LOCK ***
START TRANSACTION;

UPDATE HOSPITAL
SET    bed_capacity = bed_capacity - 1
WHERE  hospital_id = @hid;

-- <<< CURSOR FREEZES HERE — waiting for Terminal A to release the lock >>>
-- Leave this running. Switch back to Terminal A.


-- ╔═══════════════════════════════════════════════════════════╗
-- ║  TERMINAL A — Priya commits                              ║
-- ╚═══════════════════════════════════════════════════════════╝

-- [A-4] Priya commits — releases the row lock
COMMIT;

SELECT '[ A ] Priya COMMITTED. Row lock released. Bed count = 9 in DB.' AS '';

-- >>> Anjali's UPDATE in Terminal B should NOW unblock <<<


-- ╔═══════════════════════════════════════════════════════════╗
-- ║  TERMINAL B — Anjali's UPDATE unblocks, she commits      ║
-- ╚═══════════════════════════════════════════════════════════╝

-- [B-4] Terminal B's UPDATE finally completes (it ran on Priya's committed value of 9)
--        Anjali sees the post-lock result inside her transaction:
SELECT hospital_name, bed_capacity AS beds_available
FROM   HOSPITAL
WHERE  hospital_id = @hid;
-- Expected: 8  (Anjali's decrement applied to Priya's committed 9)

-- [B-5] Anjali commits
COMMIT;

SELECT '[ B ] Anjali COMMITTED. Final bed count = 8.' AS '';


-- ╔═══════════════════════════════════════════════════════════╗
-- ║  FINAL VERIFICATION  (run in either terminal)            ║
-- ╚═══════════════════════════════════════════════════════════╝

SELECT '[ RESULT ] Final state after both admissions:' AS '';
SELECT hospital_name,
       bed_capacity                       AS beds_now,
       10 - bed_capacity                  AS patients_admitted,
       10                                 AS beds_started_with
FROM   HOSPITAL
WHERE  hospital_id = @hid;
-- Expected: beds_now = 8, patients_admitted = 2
-- Both admissions are accounted for. Zero lost updates.


-- ─────────────────────────────────────────────────────────────
-- CONTRAST: What happens WITHOUT row-level locking (hypothetical)
-- ─────────────────────────────────────────────────────────────
--
--   Time  Priya (A)                       Anjali (B)
--   ----  ----------------------------    ----------------------------
--   t1    READ bed_capacity → 10
--   t2                                    READ bed_capacity → 10
--   t3    WRITE bed_capacity = 10 - 1 = 9
--   t4                                    WRITE bed_capacity = 10 - 1 = 9
--   t5    Final value in DB: 9  ← WRONG — Priya's admission is lost!
--
--   Two patients admitted; DB says only 1 bed used.
--   This is the "Lost Update" anomaly — a data integrity disaster.


-- ─────────────────────────────────────────────────────────────
-- WHAT HAPPENED UNDER THE HOOD
-- ─────────────────────────────────────────────────────────────
--
-- InnoDB storage engine uses two mechanisms simultaneously:
--
-- 1. MVCC (Multi-Version Concurrency Control) for READS:
--    Every transaction sees a consistent snapshot of committed data
--    taken at transaction start. Anjali's SELECT at [B-2] returns 10
--    even though Priya's UPDATE is in-flight — no dirty read.
--
-- 2. Exclusive Row Lock (X-lock) for WRITES:
--    Priya's UPDATE on hospital_id=N acquires an X-lock on that row.
--    Anjali's UPDATE on the same row blocks at the lock queue.
--    Lock is held until Priya's COMMIT; then Anjali gets the lock
--    and her UPDATE runs against the freshly committed value (9).
--
-- Isolation level: REPEATABLE READ (MySQL default).
-- Lock type: IX-lock on table, X-lock on the specific row.
-- Lock timeout: innodb_lock_wait_timeout = 50 seconds (default).
--   If Priya never commits, Anjali gets ERROR 1205 (Lock wait timeout)
--   and her transaction is automatically rolled back.
--
-- End result: updates are SERIALIZED — one after the other — even
-- though both nurses clicked "Admit Patient" at the same moment.
-- ─────────────────────────────────────────────────────────────


-- ─────────────────────────────────────────────────────────────
-- CLEANUP  (run in either terminal after the demo)
-- ─────────────────────────────────────────────────────────────

DELETE FROM HOSPITAL WHERE license_number = 'LIC-DEMO-CGH-01';
SELECT '[ CLEANUP ] Demo hospital removed.' AS '';
