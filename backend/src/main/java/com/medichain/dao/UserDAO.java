package com.medichain.dao;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public class UserDAO {

    private final JdbcTemplate jdbc;

    public UserDAO(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public Map<String, Object> findByUsername(String username) {
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT * FROM APP_USER WHERE username = ?", username
        );
        return rows.isEmpty() ? null : rows.get(0);
    }

    public Map<String, Object> findById(Long userId) {
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT * FROM APP_USER WHERE user_id = ?", userId
        );
        return rows.isEmpty() ? null : rows.get(0);
    }

    public Long createUser(String username, String passwordHash, String role) {
        jdbc.update(
            "INSERT INTO APP_USER (username, password_hash, role, status) VALUES (?, ?, ?, 'Active')",
            username, passwordHash, role
        );
        return jdbc.queryForObject("SELECT LAST_INSERT_ID()", Long.class);
    }

    public void linkPatientUser(Long userId, String healthId) {
        jdbc.update(
            "INSERT INTO PATIENT_USER (user_id, health_id) VALUES (?, ?)", userId, healthId
        );
    }

    public void linkDoctorUser(Long userId, Long doctorId) {
        jdbc.update(
            "INSERT INTO DOCTOR_USER (user_id, doctor_id) VALUES (?, ?)", userId, doctorId
        );
    }

    public void linkAdminUser(Long userId) {
        jdbc.update("INSERT INTO ADMIN_USER (user_id) VALUES (?)", userId);
    }

    public void updateLastLogin(Long userId) {
        jdbc.update("UPDATE APP_USER SET last_login = NOW() WHERE user_id = ?", userId);
    }

    public String getHealthIdForUser(Long userId) {
        List<String> ids = jdbc.queryForList(
            "SELECT health_id FROM PATIENT_USER WHERE user_id = ?", String.class, userId
        );
        return ids.isEmpty() ? null : ids.get(0);
    }

    public Long getDoctorIdForUser(Long userId) {
        List<Long> ids = jdbc.queryForList(
            "SELECT doctor_id FROM DOCTOR_USER WHERE user_id = ?", Long.class, userId
        );
        return ids.isEmpty() ? null : ids.get(0);
    }

    public List<Map<String, Object>> findAllUsers() {
        return jdbc.queryForList(
            "SELECT user_id, username, role, status, created_date, last_login FROM APP_USER ORDER BY created_date DESC"
        );
    }
}
