package com.medichain.controller;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/dashboard")
@CrossOrigin(origins = "*")
public class DashboardController {

    private final JdbcTemplate jdbc;

    public DashboardController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @GetMapping("/stats")
    public ResponseEntity<?> getStats() {
        Map<String, Object> stats = new HashMap<>();

        stats.put("total_patients", jdbc.queryForObject("SELECT COUNT(*) FROM PATIENT", Integer.class));
        stats.put("total_doctors", jdbc.queryForObject("SELECT COUNT(*) FROM DOCTOR", Integer.class));
        stats.put("total_hospitals", jdbc.queryForObject("SELECT COUNT(*) FROM HOSPITAL", Integer.class));
        stats.put("total_encounters", jdbc.queryForObject("SELECT COUNT(*) FROM ENCOUNTER", Integer.class));
        stats.put("active_prescriptions", jdbc.queryForObject(
                "SELECT COUNT(*) FROM PRESCRIPTION WHERE status = 'Active'", Integer.class));
        stats.put("pending_lab_orders", jdbc.queryForObject(
                "SELECT COUNT(*) FROM LAB_ORDER WHERE order_status IN ('Pending','In Progress')", Integer.class));
        stats.put("active_consents", jdbc.queryForObject(
                "SELECT COUNT(*) FROM CONSENT WHERE status = 'Active'", Integer.class));
        stats.put("audit_log_count", jdbc.queryForObject("SELECT COUNT(*) FROM AUDIT_LOG", Integer.class));
        stats.put("critical_alerts", jdbc.queryForObject(
                "SELECT COUNT(*) FROM LAB_RESULT WHERE critical_flag = TRUE AND physician_acknowledged = FALSE", Integer.class));
        stats.put("pending_emergency_reviews", jdbc.queryForObject(
                "SELECT COUNT(*) FROM EMERGENCY_ACCESS WHERE review_status = 'Pending Review'", Integer.class));

        // Recent encounters
        stats.put("recent_encounters", jdbc.queryForList(
                "SELECT e.encounter_id, e.encounter_type, e.encounter_date_time, " +
                "p.fname, p.lname, p.health_id, h.hospital_name " +
                "FROM ENCOUNTER e " +
                "JOIN PATIENT p ON e.health_id = p.health_id " +
                "LEFT JOIN HOSPITAL h ON e.hospital_id = h.hospital_id " +
                "ORDER BY e.encounter_date_time DESC LIMIT 5"
        ));

        // Diagnosis codes
        stats.put("diagnosis_codes", jdbc.queryForList("SELECT * FROM DIAGNOSIS_CODE ORDER BY icd10_code"));
        stats.put("procedure_codes", jdbc.queryForList("SELECT * FROM PROCEDURE_CODE ORDER BY cpt_code"));

        return ResponseEntity.ok(stats);
    }
}
