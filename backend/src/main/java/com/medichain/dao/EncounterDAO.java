package com.medichain.dao;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public class EncounterDAO {

    private final JdbcTemplate jdbc;

    public EncounterDAO(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String, Object>> findAll() {
        return jdbc.queryForList(
            "SELECT e.*, p.fname, p.lname, p.health_id, h.hospital_name, " +
            "GROUP_CONCAT(DISTINCT d.name SEPARATOR ', ') AS doctors " +
            "FROM ENCOUNTER e " +
            "JOIN PATIENT p ON e.health_id = p.health_id " +
            "LEFT JOIN HOSPITAL h ON e.hospital_id = h.hospital_id " +
            "LEFT JOIN ENCOUNTER_DOCTOR ed ON e.encounter_id = ed.encounter_id " +
            "LEFT JOIN DOCTOR d ON ed.doctor_id = d.doctor_id " +
            "GROUP BY e.encounter_id ORDER BY e.encounter_date_time DESC"
        );
    }

    public Map<String, Object> findById(Long id) {
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT e.*, p.fname, p.lname, h.hospital_name " +
            "FROM ENCOUNTER e " +
            "JOIN PATIENT p ON e.health_id = p.health_id " +
            "LEFT JOIN HOSPITAL h ON e.hospital_id = h.hospital_id " +
            "WHERE e.encounter_id = ?", id
        );
        return rows.isEmpty() ? null : rows.get(0);
    }

    public List<Map<String, Object>> findByPatient(String healthId) {
        return jdbc.queryForList(
            "SELECT e.*, h.hospital_name, " +
            "GROUP_CONCAT(DISTINCT d.name SEPARATOR ', ') AS doctors " +
            "FROM ENCOUNTER e " +
            "LEFT JOIN HOSPITAL h ON e.hospital_id = h.hospital_id " +
            "LEFT JOIN ENCOUNTER_DOCTOR ed ON e.encounter_id = ed.encounter_id " +
            "LEFT JOIN DOCTOR d ON ed.doctor_id = d.doctor_id " +
            "WHERE e.health_id = ? GROUP BY e.encounter_id ORDER BY e.encounter_date_time DESC",
            healthId
        );
    }

    public Long create(Map<String, Object> enc) {
        jdbc.update(
            "INSERT INTO ENCOUNTER (health_id, hospital_id, encounter_date_time, encounter_type, " +
            "admission_date_time, discharge_date_time, bed_number, chief_complaint, examination_notes, treatment_plan) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            enc.get("health_id"), enc.get("hospital_id"), enc.get("encounter_date_time"),
            enc.get("encounter_type"), enc.get("admission_date_time"), enc.get("discharge_date_time"),
            enc.get("bed_number"), enc.get("chief_complaint"), enc.get("examination_notes"),
            enc.get("treatment_plan")
        );
        return jdbc.queryForObject("SELECT LAST_INSERT_ID()", Long.class);
    }

    public void assignDoctor(Long encounterId, Long doctorId, String role, boolean isPrimary) {
        jdbc.update(
            "INSERT INTO ENCOUNTER_DOCTOR (encounter_id, doctor_id, role, assigned_time, is_primary) " +
            "VALUES (?, ?, ?, NOW(), ?)",
            encounterId, doctorId, role, isPrimary
        );
    }

    // Vital Signs
    public void addVitals(Map<String, Object> vitals) {
        jdbc.update(
            "INSERT INTO VITAL_SIGNS (encounter_id, reading_timestamp, bp_systolic, bp_diastolic, " +
            "pulse, temperature, respiratory_rate, height, weight, oxygen_saturation) " +
            "VALUES (?, NOW(), ?, ?, ?, ?, ?, ?, ?, ?)",
            vitals.get("encounter_id"), vitals.get("bp_systolic"), vitals.get("bp_diastolic"),
            vitals.get("pulse"), vitals.get("temperature"), vitals.get("respiratory_rate"),
            vitals.get("height"), vitals.get("weight"), vitals.get("oxygen_saturation")
        );
    }

    public List<Map<String, Object>> getVitals(Long encounterId) {
        return jdbc.queryForList(
            "SELECT * FROM VITAL_SIGNS WHERE encounter_id = ? ORDER BY reading_timestamp DESC",
            encounterId
        );
    }

    // Diagnoses
    public void addDiagnosis(Map<String, Object> diag) {
        jdbc.update(
            "INSERT INTO ENCOUNTER_DIAGNOSIS (encounter_id, icd10_code, diagnosis_type, status, diagnosed_date) " +
            "VALUES (?, ?, ?, ?, CURDATE())",
            diag.get("encounter_id"), diag.get("icd10_code"), diag.get("diagnosis_type"),
            diag.getOrDefault("status", "Active")
        );
    }

    public List<Map<String, Object>> getDiagnoses(Long encounterId) {
        return jdbc.queryForList(
            "SELECT ed.*, dc.description, dc.category FROM ENCOUNTER_DIAGNOSIS ed " +
            "JOIN DIAGNOSIS_CODE dc ON ed.icd10_code = dc.icd10_code " +
            "WHERE ed.encounter_id = ?", encounterId
        );
    }

    // Procedures
    public void addProcedure(Map<String, Object> proc) {
        jdbc.update(
            "INSERT INTO ENCOUNTER_PROCEDURE (encounter_id, cpt_code, sequence_number, procedure_date, " +
            "performing_doctor_id, procedure_notes, complications) VALUES (?, ?, ?, CURDATE(), ?, ?, ?)",
            proc.get("encounter_id"), proc.get("cpt_code"), proc.get("sequence_number"),
            proc.get("performing_doctor_id"), proc.get("procedure_notes"), proc.get("complications")
        );
    }

    public List<Map<String, Object>> getProcedures(Long encounterId) {
        return jdbc.queryForList(
            "SELECT ep.*, pc.description, pc.category, pc.base_cost FROM ENCOUNTER_PROCEDURE ep " +
            "JOIN PROCEDURE_CODE pc ON ep.cpt_code = pc.cpt_code " +
            "WHERE ep.encounter_id = ?", encounterId
        );
    }

    // Encounter doctors
    public List<Map<String, Object>> getDoctors(Long encounterId) {
        return jdbc.queryForList(
            "SELECT ed.*, d.name, d.specialization FROM ENCOUNTER_DOCTOR ed " +
            "JOIN DOCTOR d ON ed.doctor_id = d.doctor_id " +
            "WHERE ed.encounter_id = ?", encounterId
        );
    }
}
