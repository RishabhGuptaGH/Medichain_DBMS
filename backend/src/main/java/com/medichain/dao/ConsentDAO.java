package com.medichain.dao;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public class ConsentDAO {

    private final JdbcTemplate jdbc;

    public ConsentDAO(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String, Object>> findAll() {
        return jdbc.queryForList(
            "SELECT c.*, p.fname, p.lname, h.hospital_name " +
            "FROM CONSENT c " +
            "JOIN PATIENT p ON c.health_id = p.health_id " +
            "JOIN HOSPITAL h ON c.hospital_id = h.hospital_id " +
            "ORDER BY c.created_timestamp DESC"
        );
    }

    public List<Map<String, Object>> findByPatient(String healthId) {
        return jdbc.queryForList(
            "SELECT c.*, h.hospital_name FROM CONSENT c " +
            "JOIN HOSPITAL h ON c.hospital_id = h.hospital_id " +
            "WHERE c.health_id = ? ORDER BY c.created_timestamp DESC", healthId
        );
    }

    public Long create(Map<String, Object> consent) {
        jdbc.update(
            "INSERT INTO CONSENT (health_id, hospital_id, access_level, purpose, effective_date, expiration_date, status) " +
            "VALUES (?, ?, ?, ?, ?, ?, 'Active')",
            consent.get("health_id"), consent.get("hospital_id"), consent.get("access_level"),
            consent.get("purpose"), consent.get("effective_date"), consent.get("expiration_date")
        );
        return jdbc.queryForObject("SELECT LAST_INSERT_ID()", Long.class);
    }

    public int revoke(Long consentId) {
        return jdbc.update(
            "UPDATE CONSENT SET status = 'Revoked' WHERE consent_id = ? AND status = 'Active'",
            consentId
        );
    }

    public boolean checkConsent(String healthId, Long hospitalId) {
        Integer count = jdbc.queryForObject(
            "SELECT COUNT(*) FROM CONSENT " +
            "WHERE health_id = ? AND hospital_id = ? AND status = 'Active' " +
            "AND effective_date <= CURDATE() " +
            "AND (expiration_date IS NULL OR expiration_date >= CURDATE())",
            Integer.class, healthId, hospitalId
        );
        return count != null && count > 0;
    }

    // Emergency Access
    public Long createEmergencyAccess(Map<String, Object> access) {
        jdbc.update(
            "INSERT INTO EMERGENCY_ACCESS (health_id, doctor_id, emergency_type, justification, records_accessed) " +
            "VALUES (?, ?, ?, ?, ?)",
            access.get("health_id"), access.get("doctor_id"), access.get("emergency_type"),
            access.get("justification"), access.get("records_accessed")
        );
        return jdbc.queryForObject("SELECT LAST_INSERT_ID()", Long.class);
    }

    public List<Map<String, Object>> getEmergencyAccesses() {
        return jdbc.queryForList(
            "SELECT ea.*, p.fname, p.lname, d.name AS doctor_name " +
            "FROM EMERGENCY_ACCESS ea " +
            "JOIN PATIENT p ON ea.health_id = p.health_id " +
            "JOIN DOCTOR d ON ea.doctor_id = d.doctor_id " +
            "ORDER BY ea.access_time DESC"
        );
    }

    public int reviewEmergencyAccess(Long accessId, String reviewStatus, Long reviewedBy) {
        return jdbc.update(
            "UPDATE EMERGENCY_ACCESS SET review_status = ?, reviewed_by = ?, reviewed_at = NOW() " +
            "WHERE access_id = ?", reviewStatus, reviewedBy, accessId
        );
    }
}
