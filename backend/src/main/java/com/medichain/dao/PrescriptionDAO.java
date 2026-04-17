package com.medichain.dao;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public class PrescriptionDAO {

    private final JdbcTemplate jdbc;

    public PrescriptionDAO(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String, Object>> findAll() {
        return jdbc.queryForList(
            "SELECT pr.*, d.name AS doctor_name, p.fname, p.lname, p.health_id " +
            "FROM PRESCRIPTION pr " +
            "JOIN DOCTOR d ON pr.doctor_id = d.doctor_id " +
            "JOIN ENCOUNTER e ON pr.encounter_id = e.encounter_id " +
            "JOIN PATIENT p ON e.health_id = p.health_id " +
            "ORDER BY pr.created_at DESC"
        );
    }

    public Map<String, Object> findById(Long id) {
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT pr.*, d.name AS doctor_name, p.fname, p.lname, p.health_id " +
            "FROM PRESCRIPTION pr " +
            "JOIN DOCTOR d ON pr.doctor_id = d.doctor_id " +
            "JOIN ENCOUNTER e ON pr.encounter_id = e.encounter_id " +
            "JOIN PATIENT p ON e.health_id = p.health_id " +
            "WHERE pr.prescription_id = ?", id
        );
        return rows.isEmpty() ? null : rows.get(0);
    }

    public Long create(Map<String, Object> rx) {
        jdbc.update(
            "INSERT INTO PRESCRIPTION (encounter_id, doctor_id, prescription_date, start_date, end_date, status, override_reason) " +
            "VALUES (?, ?, CURDATE(), ?, ?, 'Active', ?)",
            rx.get("encounter_id"), rx.get("doctor_id"), rx.get("start_date"),
            rx.get("end_date"), rx.get("override_reason")
        );
        return jdbc.queryForObject("SELECT LAST_INSERT_ID()", Long.class);
    }

    public void addItem(Map<String, Object> item) {
        jdbc.update(
            "INSERT INTO PRESCRIPTION_ITEM (prescription_id, medication_id, dosage_strength, dosage_form, " +
            "frequency, duration_days, quantity_dispensed, instructions, allergy_override, interaction_override, override_justification) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            item.get("prescription_id"), item.get("medication_id"), item.get("dosage_strength"),
            item.get("dosage_form"), item.get("frequency"), item.get("duration_days"),
            item.get("quantity_dispensed"), item.get("instructions"),
            item.getOrDefault("allergy_override", false),
            item.getOrDefault("interaction_override", false),
            item.get("override_justification")
        );
    }

    public List<Map<String, Object>> getItems(Long prescriptionId) {
        return jdbc.queryForList(
            "SELECT pi.*, m.generic_name, m.brand_name, m.drug_class " +
            "FROM PRESCRIPTION_ITEM pi " +
            "JOIN MEDICATION m ON pi.medication_id = m.medication_id " +
            "WHERE pi.prescription_id = ?", prescriptionId
        );
    }

    public int updateStatus(Long id, String status) {
        return jdbc.update(
            "UPDATE PRESCRIPTION SET status = ? WHERE prescription_id = ?", status, id
        );
    }

    // Get all active medications for a patient (for drug interaction display)
    public List<Map<String, Object>> getActivePatientMedications(String healthId) {
        return jdbc.queryForList(
            "SELECT DISTINCT m.medication_id, m.generic_name, m.brand_name, m.drug_class, " +
            "pi.dosage_strength, pi.frequency " +
            "FROM PRESCRIPTION_ITEM pi " +
            "JOIN PRESCRIPTION pr ON pi.prescription_id = pr.prescription_id " +
            "JOIN ENCOUNTER e ON pr.encounter_id = e.encounter_id " +
            "JOIN MEDICATION m ON pi.medication_id = m.medication_id " +
            "WHERE e.health_id = ? AND pr.status = 'Active'",
            healthId
        );
    }

    // Check drug interactions for a medication against patient's active meds
    public List<Map<String, Object>> checkDrugInteractions(String healthId, Long medicationId) {
        return jdbc.queryForList(
            "SELECT di.*, " +
            "m1.generic_name AS drug1_name, m2.generic_name AS drug2_name " +
            "FROM DRUG_INTERACTION di " +
            "JOIN MEDICATION m1 ON di.medication_id_1 = m1.medication_id " +
            "JOIN MEDICATION m2 ON di.medication_id_2 = m2.medication_id " +
            "WHERE (di.medication_id_1 = ? OR di.medication_id_2 = ?) " +
            "AND (di.medication_id_1 IN (" +
            "  SELECT pi.medication_id FROM PRESCRIPTION_ITEM pi " +
            "  JOIN PRESCRIPTION pr ON pi.prescription_id = pr.prescription_id " +
            "  JOIN ENCOUNTER e ON pr.encounter_id = e.encounter_id " +
            "  WHERE e.health_id = ? AND pr.status = 'Active'" +
            ") OR di.medication_id_2 IN (" +
            "  SELECT pi.medication_id FROM PRESCRIPTION_ITEM pi " +
            "  JOIN PRESCRIPTION pr ON pi.prescription_id = pr.prescription_id " +
            "  JOIN ENCOUNTER e ON pr.encounter_id = e.encounter_id " +
            "  WHERE e.health_id = ? AND pr.status = 'Active'" +
            "))",
            medicationId, medicationId, healthId, healthId
        );
    }

    // Check allergy for a patient against a medication
    public List<Map<String, Object>> checkAllergy(String healthId, Long medicationId) {
        return jdbc.queryForList(
            "SELECT pa.*, m.generic_name, m.drug_class " +
            "FROM PATIENT_ALLERGY pa " +
            "JOIN MEDICATION m ON m.medication_id = ? " +
            "WHERE pa.health_id = ? AND pa.status = 'Active' " +
            "AND pa.severity IN ('Severe', 'Life-threatening') " +
            "AND (LOWER(pa.allergen) LIKE CONCAT('%', LOWER(m.generic_name), '%') " +
            "     OR LOWER(pa.allergen) LIKE CONCAT('%', LOWER(m.drug_class), '%') " +
            "     OR LOWER(m.generic_name) LIKE CONCAT('%', LOWER(pa.allergen), '%') " +
            "     OR LOWER(m.drug_class) LIKE CONCAT('%', LOWER(pa.allergen), '%'))",
            medicationId, healthId
        );
    }

    public List<Map<String, Object>> getMedications() {
        return jdbc.queryForList("SELECT * FROM MEDICATION ORDER BY generic_name");
    }
}
