package com.medichain.dao;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public class DoctorDAO {

    private final JdbcTemplate jdbc;

    public DoctorDAO(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String, Object>> findAll() {
        return jdbc.queryForList(
            "SELECT d.*, GROUP_CONCAT(DISTINCT h.hospital_name SEPARATOR ', ') AS hospitals " +
            "FROM DOCTOR d " +
            "LEFT JOIN DOCTOR_HOSPITAL dh ON d.doctor_id = dh.doctor_id AND dh.status = 'Active' " +
            "LEFT JOIN HOSPITAL h ON dh.hospital_id = h.hospital_id " +
            "GROUP BY d.doctor_id ORDER BY d.name"
        );
    }

    public Map<String, Object> findById(Long id) {
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT * FROM DOCTOR WHERE doctor_id = ?", id
        );
        return rows.isEmpty() ? null : rows.get(0);
    }

    public void create(Map<String, Object> doctor) {
        jdbc.update(
            "INSERT INTO DOCTOR (medical_license_number, name, phone_number, email, date_of_birth, specialization) " +
            "VALUES (?, ?, ?, ?, ?, ?)",
            doctor.get("medical_license_number"), doctor.get("name"), doctor.get("phone_number"),
            doctor.get("email"), doctor.get("date_of_birth"), doctor.get("specialization")
        );
    }

    public int update(Long id, Map<String, Object> doctor) {
        return jdbc.update(
            "UPDATE DOCTOR SET medical_license_number=?, name=?, phone_number=?, email=?, " +
            "date_of_birth=?, specialization=? WHERE doctor_id=?",
            doctor.get("medical_license_number"), doctor.get("name"), doctor.get("phone_number"),
            doctor.get("email"), doctor.get("date_of_birth"), doctor.get("specialization"), id
        );
    }

    public List<Map<String, Object>> getHospitals(Long doctorId) {
        return jdbc.queryForList(
            "SELECT h.*, dh.join_date, dh.status FROM DOCTOR_HOSPITAL dh " +
            "JOIN HOSPITAL h ON dh.hospital_id = h.hospital_id " +
            "WHERE dh.doctor_id = ?", doctorId
        );
    }

    public void assignToHospital(Long doctorId, Long hospitalId, String joinDate) {
        jdbc.update(
            "INSERT INTO DOCTOR_HOSPITAL (doctor_id, hospital_id, join_date, status) VALUES (?, ?, ?, 'Active') " +
            "ON DUPLICATE KEY UPDATE status = 'Active', join_date = VALUES(join_date)",
            doctorId, hospitalId, joinDate
        );
    }
}
