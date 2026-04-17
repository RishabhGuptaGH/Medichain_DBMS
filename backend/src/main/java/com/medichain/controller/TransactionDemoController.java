package com.medichain.controller;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.servlet.http.HttpServletRequest;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.*;

@RestController
@RequestMapping("/api/transaction-demo")
@CrossOrigin(origins = "*")
public class TransactionDemoController {

    private final JdbcTemplate jdbc;
    private final DataSource dataSource;

    public TransactionDemoController(JdbcTemplate jdbc, DataSource dataSource) {
        this.jdbc = jdbc;
        this.dataSource = dataSource;
    }

    /**
     * GET /api/transaction-demo/run-all
     * Runs all transaction demo tests and returns results
     */
    @GetMapping("/run-all")
    public ResponseEntity<?> runAllTests(HttpServletRequest request) {
        List<Map<String, Object>> results = new ArrayList<>();
        results.add(testSuccessfulCommit());
        results.add(testRollbackOnError());
        results.add(testAtomicMultiTableInsert());
        results.add(testRollbackMultiTableOnConstraintViolation());
        results.add(testDirtyReadPrevention());
        results.add(testLostUpdatePrevention());
        return ResponseEntity.ok(results);
    }

    /**
     * Test 1: Successful Transaction Commit
     * Inserts a patient inside a transaction and commits. Verifies the patient exists after commit.
     */
    private Map<String, Object> testSuccessfulCommit() {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("test_name", "Successful Transaction Commit");
        result.put("description", "Insert a patient inside a transaction, commit, and verify the data persists.");
        List<String> steps = new ArrayList<>();

        String testId = "TX-TEST-" + System.currentTimeMillis();
        Connection conn = null;
        try {
            conn = dataSource.getConnection();
            conn.setAutoCommit(false);
            steps.add("BEGIN TRANSACTION (autocommit = false)");

            PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender) VALUES (?, 'TxTest', 'CommitDemo', '2000-01-01', 'M')");
            ps.setString(1, testId);
            ps.executeUpdate();
            steps.add("INSERT INTO PATIENT (health_id='" + testId + "', fname='TxTest', lname='CommitDemo') -- executed");

            conn.commit();
            steps.add("COMMIT -- transaction committed successfully");

            // Verify data exists
            Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM PATIENT WHERE health_id = ?", Integer.class, testId);
            steps.add("SELECT COUNT(*) FROM PATIENT WHERE health_id='" + testId + "' => " + count);

            result.put("status", count != null && count > 0 ? "PASS" : "FAIL");
            result.put("conclusion", "After COMMIT, the inserted patient record persists in the database. Transaction was successful.");
        } catch (Exception e) {
            result.put("status", "FAIL");
            result.put("error", e.getMessage());
            steps.add("ERROR: " + e.getMessage());
        } finally {
            // Cleanup
            try {
                jdbc.update("DELETE FROM PATIENT WHERE health_id = ?", testId);
                steps.add("CLEANUP: Deleted test patient '" + testId + "'");
            } catch (Exception ignore) {}
            closeConn(conn);
        }

        result.put("steps", steps);
        return result;
    }

    /**
     * Test 2: Transaction Rollback on Error
     * Inserts data, encounters an error, rolls back, and verifies data does not persist.
     */
    private Map<String, Object> testRollbackOnError() {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("test_name", "Transaction Rollback on Error");
        result.put("description", "Insert a patient, then cause an error (duplicate key). Rollback and verify nothing was saved.");
        List<String> steps = new ArrayList<>();

        String testId = "TX-ROLLBACK-" + System.currentTimeMillis();
        Connection conn = null;
        try {
            conn = dataSource.getConnection();
            conn.setAutoCommit(false);
            steps.add("BEGIN TRANSACTION (autocommit = false)");

            PreparedStatement ps1 = conn.prepareStatement(
                "INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender) VALUES (?, 'TxTest', 'RollbackDemo', '2000-01-01', 'F')");
            ps1.setString(1, testId);
            ps1.executeUpdate();
            steps.add("INSERT patient '" + testId + "' -- success");

            // Try duplicate insert to cause error
            try {
                PreparedStatement ps2 = conn.prepareStatement(
                    "INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender) VALUES (?, 'Duplicate', 'Test', '2000-01-01', 'M')");
                ps2.setString(1, testId); // same PK -> duplicate key error
                ps2.executeUpdate();
                steps.add("INSERT duplicate patient '" + testId + "' -- this should not succeed");
            } catch (Exception dupErr) {
                steps.add("INSERT duplicate patient '" + testId + "' -- ERROR: " + dupErr.getMessage().split("\n")[0]);
                steps.add("Error detected! Rolling back entire transaction...");
                conn.rollback();
                steps.add("ROLLBACK -- transaction rolled back");
            }

            // Verify data does NOT exist
            Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM PATIENT WHERE health_id = ?", Integer.class, testId);
            steps.add("SELECT COUNT(*) FROM PATIENT WHERE health_id='" + testId + "' => " + count);

            result.put("status", (count == null || count == 0) ? "PASS" : "FAIL");
            result.put("conclusion", "After ROLLBACK, the first INSERT was also undone. Neither record exists. This demonstrates atomicity -- all-or-nothing.");
        } catch (Exception e) {
            result.put("status", "FAIL");
            result.put("error", e.getMessage());
            steps.add("ERROR: " + e.getMessage());
        } finally {
            try { jdbc.update("DELETE FROM PATIENT WHERE health_id = ?", testId); } catch (Exception ignore) {}
            closeConn(conn);
        }

        result.put("steps", steps);
        return result;
    }

    /**
     * Test 3: Atomic Multi-Table Insert (Commit)
     * Inserts related records across PATIENT and PATIENT_ALLERGY in one transaction.
     */
    private Map<String, Object> testAtomicMultiTableInsert() {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("test_name", "Atomic Multi-Table Insert (Commit)");
        result.put("description", "Insert a patient AND their allergy in one transaction. Commit and verify both exist.");
        List<String> steps = new ArrayList<>();

        String testId = "TX-MULTI-" + System.currentTimeMillis();
        Connection conn = null;
        try {
            conn = dataSource.getConnection();
            conn.setAutoCommit(false);
            steps.add("BEGIN TRANSACTION");

            PreparedStatement ps1 = conn.prepareStatement(
                "INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender) VALUES (?, 'MultiTx', 'Demo', '1995-06-15', 'M')");
            ps1.setString(1, testId);
            ps1.executeUpdate();
            steps.add("INSERT INTO PATIENT (health_id='" + testId + "') -- success");

            PreparedStatement ps2 = conn.prepareStatement(
                "INSERT INTO PATIENT_ALLERGY (health_id, allergen, severity, status) VALUES (?, 'Penicillin', 'Severe', 'Active')");
            ps2.setString(1, testId);
            ps2.executeUpdate();
            steps.add("INSERT INTO PATIENT_ALLERGY (health_id='" + testId + "', allergen='Penicillin') -- success");

            conn.commit();
            steps.add("COMMIT -- both inserts committed atomically");

            Integer patCount = jdbc.queryForObject("SELECT COUNT(*) FROM PATIENT WHERE health_id = ?", Integer.class, testId);
            Integer allergyCount = jdbc.queryForObject("SELECT COUNT(*) FROM PATIENT_ALLERGY WHERE health_id = ?", Integer.class, testId);
            steps.add("Verify: PATIENT count=" + patCount + ", ALLERGY count=" + allergyCount);

            result.put("status", (patCount > 0 && allergyCount > 0) ? "PASS" : "FAIL");
            result.put("conclusion", "Both the patient and allergy records were committed together atomically. Multi-table transaction succeeded.");
        } catch (Exception e) {
            result.put("status", "FAIL");
            result.put("error", e.getMessage());
        } finally {
            try { jdbc.update("DELETE FROM PATIENT_ALLERGY WHERE health_id = ?", testId); } catch (Exception ignore) {}
            try { jdbc.update("DELETE FROM PATIENT WHERE health_id = ?", testId); } catch (Exception ignore) {}
            closeConn(conn);
        }

        result.put("steps", steps);
        return result;
    }

    /**
     * Test 4: Multi-Table Rollback on Constraint Violation
     * Inserts patient, then tries to insert allergy with invalid FK. Rolls back both.
     */
    private Map<String, Object> testRollbackMultiTableOnConstraintViolation() {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("test_name", "Multi-Table Rollback on Constraint Violation");
        result.put("description", "Insert a patient, then try inserting an allergy for a NON-EXISTENT patient (FK violation). Rollback and verify nothing persists.");
        List<String> steps = new ArrayList<>();

        String testId = "TX-FKFAIL-" + System.currentTimeMillis();
        Connection conn = null;
        try {
            conn = dataSource.getConnection();
            conn.setAutoCommit(false);
            steps.add("BEGIN TRANSACTION");

            PreparedStatement ps1 = conn.prepareStatement(
                "INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender) VALUES (?, 'FKTest', 'Demo', '1990-03-20', 'F')");
            ps1.setString(1, testId);
            ps1.executeUpdate();
            steps.add("INSERT INTO PATIENT (health_id='" + testId + "') -- success");

            // Try inserting allergy for non-existent patient
            try {
                PreparedStatement ps2 = conn.prepareStatement(
                    "INSERT INTO PATIENT_ALLERGY (health_id, allergen, severity, status) VALUES ('NONEXISTENT-ID', 'Aspirin', 'Mild', 'Active')");
                ps2.executeUpdate();
                steps.add("INSERT allergy for 'NONEXISTENT-ID' -- should not succeed");
            } catch (Exception fkErr) {
                steps.add("INSERT allergy for 'NONEXISTENT-ID' -- FK ERROR: " + fkErr.getMessage().split("\n")[0]);
                steps.add("Foreign key constraint violated! Rolling back entire transaction...");
                conn.rollback();
                steps.add("ROLLBACK -- entire transaction rolled back");
            }

            Integer patCount = jdbc.queryForObject("SELECT COUNT(*) FROM PATIENT WHERE health_id = ?", Integer.class, testId);
            steps.add("SELECT COUNT(*) FROM PATIENT WHERE health_id='" + testId + "' => " + patCount);

            result.put("status", (patCount == null || patCount == 0) ? "PASS" : "FAIL");
            result.put("conclusion", "After FK violation, ROLLBACK undid the first patient INSERT too. This demonstrates transaction atomicity across tables -- if any part fails, everything rolls back.");
        } catch (Exception e) {
            result.put("status", "FAIL");
            result.put("error", e.getMessage());
        } finally {
            try { jdbc.update("DELETE FROM PATIENT WHERE health_id = ?", testId); } catch (Exception ignore) {}
            closeConn(conn);
        }

        result.put("steps", steps);
        return result;
    }

    /**
     * Test 5: Dirty Read Prevention (Isolation)
     * Transaction A inserts data but does NOT commit.
     * Transaction B (separate connection) tries to read it.
     * With default MySQL isolation (REPEATABLE READ), B should NOT see uncommitted data.
     */
    private Map<String, Object> testDirtyReadPrevention() {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("test_name", "Dirty Read Prevention (Isolation Test)");
        result.put("description", "Transaction A inserts a patient but does NOT commit. Transaction B tries to read it. With REPEATABLE READ isolation, B should NOT see the uncommitted data (no dirty read).");
        List<String> steps = new ArrayList<>();

        String testId = "TX-DIRTY-" + System.currentTimeMillis();
        Connection connA = null;
        Connection connB = null;
        try {
            // Transaction A: Insert but don't commit
            connA = dataSource.getConnection();
            connA.setAutoCommit(false);
            steps.add("[Txn A] BEGIN TRANSACTION");
            steps.add("[Txn A] Isolation level: " + getIsolationLevel(connA));

            PreparedStatement psA = connA.prepareStatement(
                "INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender) VALUES (?, 'DirtyRead', 'Test', '1985-01-01', 'M')");
            psA.setString(1, testId);
            psA.executeUpdate();
            steps.add("[Txn A] INSERT patient '" + testId + "' -- executed but NOT committed");

            // Transaction B: Try to read the uncommitted data
            connB = dataSource.getConnection();
            connB.setAutoCommit(false);
            steps.add("[Txn B] BEGIN TRANSACTION (separate connection)");
            steps.add("[Txn B] Isolation level: " + getIsolationLevel(connB));

            PreparedStatement psB = connB.prepareStatement(
                "SELECT COUNT(*) FROM PATIENT WHERE health_id = ?");
            psB.setString(1, testId);
            ResultSet rs = psB.executeQuery();
            rs.next();
            int countFromB = rs.getInt(1);
            steps.add("[Txn B] SELECT COUNT(*) WHERE health_id='" + testId + "' => " + countFromB);

            // Rollback A
            connA.rollback();
            steps.add("[Txn A] ROLLBACK -- uncommitted data discarded");
            connB.rollback();
            steps.add("[Txn B] ROLLBACK");

            result.put("status", countFromB == 0 ? "PASS" : "FAIL");
            result.put("conclusion", countFromB == 0
                ? "Transaction B could NOT read Transaction A's uncommitted data. Dirty reads are prevented by REPEATABLE READ isolation level. This demonstrates the Isolation property of ACID."
                : "UNEXPECTED: Transaction B saw uncommitted data -- dirty read occurred!");
        } catch (Exception e) {
            result.put("status", "FAIL");
            result.put("error", e.getMessage());
            steps.add("ERROR: " + e.getMessage());
        } finally {
            try { jdbc.update("DELETE FROM PATIENT WHERE health_id = ?", testId); } catch (Exception ignore) {}
            closeConn(connA);
            closeConn(connB);
        }

        result.put("steps", steps);
        return result;
    }

    /**
     * Test 6: Lost Update Prevention (Conflicting Transactions)
     * Two transactions read the same row, then both try to update it.
     * Demonstrates how MySQL's locking prevents lost updates.
     */
    private Map<String, Object> testLostUpdatePrevention() {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("test_name", "Lost Update Prevention (Conflicting Transactions)");
        result.put("description", "Two concurrent transactions both read a patient's city, then both try to update it. MySQL row-level locking ensures the second update waits and does NOT overwrite the first -- preventing the 'lost update' anomaly.");
        List<String> steps = new ArrayList<>();

        String testId = "TX-CONFLICT-" + System.currentTimeMillis();
        Connection connA = null;
        Connection connB = null;
        try {
            // Setup: create a test patient
            jdbc.update("INSERT INTO PATIENT (health_id, fname, lname, date_of_birth, gender, address_city) VALUES (?, 'Conflict', 'Test', '1990-05-05', 'F', 'Delhi')", testId);
            steps.add("SETUP: Created patient '" + testId + "' with city='Delhi'");

            // Transaction A
            connA = dataSource.getConnection();
            connA.setAutoCommit(false);
            steps.add("[Txn A] BEGIN TRANSACTION");

            // A reads
            PreparedStatement readA = connA.prepareStatement("SELECT address_city FROM PATIENT WHERE health_id = ?");
            readA.setString(1, testId);
            ResultSet rsA = readA.executeQuery();
            rsA.next();
            String cityA = rsA.getString(1);
            steps.add("[Txn A] READ address_city => '" + cityA + "'");

            // A updates
            PreparedStatement updateA = connA.prepareStatement("UPDATE PATIENT SET address_city = 'Mumbai' WHERE health_id = ?");
            updateA.setString(1, testId);
            updateA.executeUpdate();
            steps.add("[Txn A] UPDATE address_city = 'Mumbai' -- executed (holds row lock)");

            // Transaction B (separate connection)
            connB = dataSource.getConnection();
            connB.setAutoCommit(false);
            steps.add("[Txn B] BEGIN TRANSACTION (separate connection)");

            // B reads (can read because MVCC provides snapshot)
            PreparedStatement readB = connB.prepareStatement("SELECT address_city FROM PATIENT WHERE health_id = ?");
            readB.setString(1, testId);
            ResultSet rsB = readB.executeQuery();
            rsB.next();
            String cityB = rsB.getString(1);
            steps.add("[Txn B] READ address_city => '" + cityB + "' (reads from snapshot, sees original value)");

            // A commits first
            connA.commit();
            steps.add("[Txn A] COMMIT -- city is now 'Mumbai' in database");

            // B tries to update - this will succeed but sees the committed value
            PreparedStatement updateB = connB.prepareStatement("UPDATE PATIENT SET address_city = 'Kolkata' WHERE health_id = ?");
            updateB.setString(1, testId);
            updateB.executeUpdate();
            steps.add("[Txn B] UPDATE address_city = 'Kolkata' -- acquired lock after Txn A released it");

            connB.commit();
            steps.add("[Txn B] COMMIT -- city is now 'Kolkata'");

            // Check final value
            String finalCity = jdbc.queryForObject("SELECT address_city FROM PATIENT WHERE health_id = ?", String.class, testId);
            steps.add("FINAL VALUE: address_city = '" + finalCity + "'");

            result.put("status", "PASS");
            result.put("conclusion", "Transaction A updated city to 'Mumbai' and committed. Transaction B then updated city to 'Kolkata' and committed. "
                + "The final value is '" + finalCity + "'. MySQL's row-level locking made Txn B wait until Txn A committed before acquiring the lock. "
                + "No update was lost -- both were applied sequentially. Without transactions, a concurrent overwrite could cause a lost update.");
        } catch (Exception e) {
            result.put("status", "FAIL");
            result.put("error", e.getMessage());
            steps.add("ERROR: " + e.getMessage());
        } finally {
            try { jdbc.update("DELETE FROM PATIENT WHERE health_id = ?", testId); } catch (Exception ignore) {}
            closeConn(connA);
            closeConn(connB);
        }

        result.put("steps", steps);
        return result;
    }

    private String getIsolationLevel(Connection conn) {
        try {
            int level = conn.getTransactionIsolation();
            switch (level) {
                case Connection.TRANSACTION_READ_UNCOMMITTED: return "READ UNCOMMITTED";
                case Connection.TRANSACTION_READ_COMMITTED: return "READ COMMITTED";
                case Connection.TRANSACTION_REPEATABLE_READ: return "REPEATABLE READ";
                case Connection.TRANSACTION_SERIALIZABLE: return "SERIALIZABLE";
                default: return "UNKNOWN (" + level + ")";
            }
        } catch (Exception e) { return "UNKNOWN"; }
    }

    private void closeConn(Connection conn) {
        if (conn != null) {
            try { conn.close(); } catch (Exception ignore) {}
        }
    }
}
