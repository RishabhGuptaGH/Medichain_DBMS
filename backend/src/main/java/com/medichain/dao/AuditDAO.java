package com.medichain.dao;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public class AuditDAO {

    private final JdbcTemplate jdbc;

    public AuditDAO(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String, Object>> findAll(int limit, int offset) {
        return jdbc.queryForList(
            "SELECT al.*, u.username FROM AUDIT_LOG al " +
            "LEFT JOIN APP_USER u ON al.user_id = u.user_id " +
            "ORDER BY al.event_time DESC LIMIT ? OFFSET ?",
            limit, offset
        );
    }

    public List<Map<String, Object>> findByAction(String actionType) {
        return jdbc.queryForList(
            "SELECT al.*, u.username FROM AUDIT_LOG al " +
            "LEFT JOIN APP_USER u ON al.user_id = u.user_id " +
            "WHERE al.action_type = ? ORDER BY al.event_time DESC",
            actionType
        );
    }

    public List<Map<String, Object>> findByTable(String tableName) {
        return jdbc.queryForList(
            "SELECT al.*, u.username FROM AUDIT_LOG al " +
            "LEFT JOIN APP_USER u ON al.user_id = u.user_id " +
            "WHERE al.table_name = ? ORDER BY al.event_time DESC",
            tableName
        );
    }

    public void logAction(Long userId, String actionType, String tableName,
                          String recordId, String oldVal, String newVal, String notes) {
        jdbc.update(
            "INSERT INTO AUDIT_LOG (user_id, action_type, table_name, record_id, old_value, new_value, notes, event_time) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?, NOW())",
            userId, actionType, tableName, recordId, oldVal, newVal, notes
        );
    }

    // Verify audit chain integrity using the stored procedure
    public Map<String, Object> verifyChain() {
        Map<String, Object> result = new HashMap<>();
        try {
            jdbc.execute("CALL sp_verify_audit_chain(@valid, @broken_at)");
            Boolean valid = jdbc.queryForObject("SELECT @valid", Boolean.class);
            Long brokenAt = jdbc.queryForObject("SELECT @broken_at", Long.class);
            result.put("valid", valid != null ? valid : true);
            result.put("broken_at_log_id", brokenAt);
            result.put("message", (valid != null && valid) ?
                "Audit chain integrity verified - no tampering detected" :
                "ALERT: Audit chain integrity compromised at log_id " + brokenAt);
        } catch (Exception e) {
            result.put("valid", false);
            result.put("message", "Error verifying chain: " + e.getMessage());
        }
        return result;
    }

    public int getTotalCount() {
        Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM AUDIT_LOG", Integer.class);
        return count != null ? count : 0;
    }

    // Get distinct action types for filtering
    public List<String> getActionTypes() {
        return jdbc.queryForList(
            "SELECT DISTINCT action_type FROM AUDIT_LOG ORDER BY action_type", String.class
        );
    }

    // Login attempts
    public void logLoginAttempt(String username, String ipAddress, String deviceType, boolean success) {
        jdbc.update(
            "INSERT INTO LOGIN_ATTEMPT (username, ip_address, device_type, success) VALUES (?, ?, ?, ?)",
            username, ipAddress, deviceType, success
        );
    }

    public List<Map<String, Object>> getLoginAttempts(int limit) {
        return jdbc.queryForList(
            "SELECT * FROM LOGIN_ATTEMPT ORDER BY attempt_time DESC LIMIT ?", limit
        );
    }
}
