package com.medichain.dao;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public class HospitalDAO {

    private final JdbcTemplate jdbc;

    public HospitalDAO(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String, Object>> findAll() {
        return jdbc.queryForList("SELECT * FROM HOSPITAL ORDER BY hospital_name");
    }

    public Map<String, Object> findById(Long id) {
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT * FROM HOSPITAL WHERE hospital_id = ?", id
        );
        return rows.isEmpty() ? null : rows.get(0);
    }

    public void create(Map<String, Object> hospital) {
        jdbc.update(
            "INSERT INTO HOSPITAL (hospital_name, license_number, phone, email, bed_capacity, " +
            "address_street, address_city, address_state, postal_code, facility_type) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            hospital.get("hospital_name"), hospital.get("license_number"), hospital.get("phone"),
            hospital.get("email"), hospital.get("bed_capacity"), hospital.get("address_street"),
            hospital.get("address_city"), hospital.get("address_state"), hospital.get("postal_code"),
            hospital.get("facility_type")
        );
    }

    public int update(Long id, Map<String, Object> hospital) {
        return jdbc.update(
            "UPDATE HOSPITAL SET hospital_name=?, license_number=?, phone=?, email=?, bed_capacity=?, " +
            "address_street=?, address_city=?, address_state=?, postal_code=?, facility_type=? " +
            "WHERE hospital_id=?",
            hospital.get("hospital_name"), hospital.get("license_number"), hospital.get("phone"),
            hospital.get("email"), hospital.get("bed_capacity"), hospital.get("address_street"),
            hospital.get("address_city"), hospital.get("address_state"), hospital.get("postal_code"),
            hospital.get("facility_type"), id
        );
    }

    public List<Map<String, Object>> getDepartments(Long hospitalId) {
        return jdbc.queryForList(
            "SELECT * FROM DEPARTMENT WHERE hospital_id = ? ORDER BY department_name", hospitalId
        );
    }

    public void addDepartment(Long hospitalId, String name) {
        jdbc.update(
            "INSERT INTO DEPARTMENT (hospital_id, department_name) VALUES (?, ?)",
            hospitalId, name
        );
    }
}
