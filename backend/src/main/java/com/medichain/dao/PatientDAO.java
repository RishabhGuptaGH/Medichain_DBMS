package com.medichain.dao;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public class PatientDAO {

    private final JdbcTemplate jdbc;

    public PatientDAO(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String, Object>> findAll() {
        return jdbc.queryForList(
            "SELECT p.*, " +
            "TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age " +
            "FROM PATIENT p ORDER BY p.created_at DESC"
        );
    }

    public Map<String, Object> findById(String healthId) {
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT p.*, " +
            "TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age, " +
            "CASE " +
            "  WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 1 THEN 'Infant' " +
            "  WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 13 THEN 'Child' " +
            "  WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 18 THEN 'Teenager' " +
            "  WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 65 THEN 'Adult' " +
            "  ELSE 'Senior' END AS age_category " +
            "FROM PATIENT p WHERE p.health_id = ?", healthId
        );
        return rows.isEmpty() ? null : rows.get(0);
    }

    public void create(Map<String, Object> patient) {
        jdbc.update(
            "INSERT INTO PATIENT (health_id, fname, mname, lname, address_street, address_city, " +
            "address_state, postal_code, date_of_birth, gender, blood_group, " +
            "emergency_contact_name, emergency_contact_phone, " +
            "insurance_provider, insurance_start, insurance_end, policy_type) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            patient.get("health_id"), patient.get("fname"), patient.get("mname"), patient.get("lname"),
            patient.get("address_street"), patient.get("address_city"), patient.get("address_state"),
            patient.get("postal_code"), patient.get("date_of_birth"), patient.get("gender"),
            patient.get("blood_group"), patient.get("emergency_contact_name"),
            patient.get("emergency_contact_phone"), patient.get("insurance_provider"),
            patient.get("insurance_start"), patient.get("insurance_end"), patient.get("policy_type")
        );
    }

    public int update(String healthId, Map<String, Object> patient) {
        return jdbc.update(
            "UPDATE PATIENT SET fname=?, mname=?, lname=?, address_street=?, address_city=?, " +
            "address_state=?, postal_code=?, date_of_birth=?, gender=?, blood_group=?, " +
            "emergency_contact_name=?, emergency_contact_phone=?, " +
            "insurance_provider=?, insurance_start=?, insurance_end=?, policy_type=? " +
            "WHERE health_id=?",
            patient.get("fname"), patient.get("mname"), patient.get("lname"),
            patient.get("address_street"), patient.get("address_city"), patient.get("address_state"),
            patient.get("postal_code"), patient.get("date_of_birth"), patient.get("gender"),
            patient.get("blood_group"), patient.get("emergency_contact_name"),
            patient.get("emergency_contact_phone"), patient.get("insurance_provider"),
            patient.get("insurance_start"), patient.get("insurance_end"), patient.get("policy_type"),
            healthId
        );
    }

    public int delete(String healthId) {
        return jdbc.update("DELETE FROM PATIENT WHERE health_id = ?", healthId);
    }

    // Patient allergies
    public List<Map<String, Object>> getAllergies(String healthId) {
        return jdbc.queryForList(
            "SELECT * FROM PATIENT_ALLERGY WHERE health_id = ? AND status = 'Active'", healthId
        );
    }

    public void addAllergy(Map<String, Object> allergy) {
        jdbc.update(
            "INSERT INTO PATIENT_ALLERGY (health_id, allergen, reaction_description, severity, identified_date, status) " +
            "VALUES (?, ?, ?, ?, ?, ?)",
            allergy.get("health_id"), allergy.get("allergen"), allergy.get("reaction_description"),
            allergy.get("severity"), allergy.get("identified_date"),
            allergy.getOrDefault("status", "Active")
        );
    }

    public List<Map<String, Object>> search(String query) {
        String like = "%" + query + "%";
        return jdbc.queryForList(
            "SELECT *, TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) AS age FROM PATIENT " +
            "WHERE health_id LIKE ? OR fname LIKE ? OR lname LIKE ? OR address_city LIKE ?",
            like, like, like, like
        );
    }
}
