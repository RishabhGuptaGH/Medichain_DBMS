package com.medichain.controller;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.servlet.http.HttpServletRequest;
import java.util.*;

@RestController
@RequestMapping("/api/patient-portal")
@CrossOrigin(origins = "*")
public class PatientPortalController {

    private final JdbcTemplate jdbc;

    public PatientPortalController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * Validates that the authenticated patient user owns the requested health_id.
     * Returns null if valid, or an error ResponseEntity if not.
     */
    private ResponseEntity<?> validateOwnership(HttpServletRequest request, String healthId) {
        Long userId = (Long) request.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(401).body(Map.of("error", "Authentication required"));
        }
        List<String> ids = jdbc.queryForList(
            "SELECT health_id FROM PATIENT_USER WHERE user_id = ?", String.class, userId);
        if (ids.isEmpty() || !ids.get(0).equals(healthId)) {
            return ResponseEntity.status(403).body(Map.of("error", "Access denied. You can only view your own records."));
        }
        return null;
    }

    // GET /api/patient-portal/dashboard?health_id=HID-001
    @GetMapping("/dashboard")
    public ResponseEntity<?> dashboard(@RequestParam String health_id, HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, health_id);
        if (ownerCheck != null) return ownerCheck;
        Map<String, Object> stats = new HashMap<>();

        stats.put("total_encounters", jdbc.queryForObject(
            "SELECT COUNT(*) FROM ENCOUNTER WHERE health_id = ?", Integer.class, health_id));

        stats.put("active_prescriptions", jdbc.queryForObject(
            "SELECT COUNT(*) FROM PRESCRIPTION pr JOIN ENCOUNTER e ON pr.encounter_id = e.encounter_id " +
            "WHERE e.health_id = ? AND pr.status = 'Active'", Integer.class, health_id));

        stats.put("pending_labs", jdbc.queryForObject(
            "SELECT COUNT(*) FROM LAB_ORDER lo JOIN ENCOUNTER e ON lo.encounter_id = e.encounter_id " +
            "WHERE e.health_id = ? AND lo.order_status IN ('Pending','In Progress')", Integer.class, health_id));

        stats.put("active_consents", jdbc.queryForObject(
            "SELECT COUNT(*) FROM CONSENT WHERE health_id = ? AND status = 'Active'", Integer.class, health_id));

        stats.put("allergies", jdbc.queryForObject(
            "SELECT COUNT(*) FROM PATIENT_ALLERGY WHERE health_id = ? AND status = 'Active'", Integer.class, health_id));

        stats.put("completed_labs", jdbc.queryForObject(
            "SELECT COUNT(*) FROM LAB_ORDER lo JOIN ENCOUNTER e ON lo.encounter_id = e.encounter_id " +
            "WHERE e.health_id = ? AND lo.order_status = 'Completed'", Integer.class, health_id));

        // Patient profile
        List<Map<String, Object>> profile = jdbc.queryForList(
            "SELECT p.*, TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age, " +
            "CASE WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 1 THEN 'Infant' " +
            "WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 13 THEN 'Child' " +
            "WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 18 THEN 'Teenager' " +
            "WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 65 THEN 'Adult' " +
            "ELSE 'Senior' END AS age_category FROM PATIENT p WHERE p.health_id = ?", health_id);
        if (!profile.isEmpty()) stats.put("profile", profile.get(0));

        // Active allergies
        stats.put("active_allergies", jdbc.queryForList(
            "SELECT * FROM PATIENT_ALLERGY WHERE health_id = ? AND status = 'Active'", health_id));

        // Recent encounters
        stats.put("recent_encounters", jdbc.queryForList(
            "SELECT e.encounter_id, e.encounter_type, e.encounter_date_time, h.hospital_name, " +
            "GROUP_CONCAT(DISTINCT d.name SEPARATOR ', ') AS doctors " +
            "FROM ENCOUNTER e " +
            "LEFT JOIN HOSPITAL h ON e.hospital_id = h.hospital_id " +
            "LEFT JOIN ENCOUNTER_DOCTOR ed ON e.encounter_id = ed.encounter_id " +
            "LEFT JOIN DOCTOR d ON ed.doctor_id = d.doctor_id " +
            "WHERE e.health_id = ? GROUP BY e.encounter_id ORDER BY e.encounter_date_time DESC LIMIT 5", health_id));

        return ResponseEntity.ok(stats);
    }

    // GET /api/patient-portal/profile?health_id=HID-001
    @GetMapping("/profile")
    public ResponseEntity<?> profile(@RequestParam String health_id, HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, health_id);
        if (ownerCheck != null) return ownerCheck;
        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT p.*, TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age FROM PATIENT p WHERE p.health_id = ?", health_id);
        if (rows.isEmpty()) return ResponseEntity.notFound().build();
        result.put("patient", rows.get(0));
        result.put("allergies", jdbc.queryForList(
            "SELECT * FROM PATIENT_ALLERGY WHERE health_id = ? AND status = 'Active'", health_id));
        return ResponseEntity.ok(result);
    }

    // GET /api/patient-portal/my-encounters?health_id=HID-001
    @GetMapping("/my-encounters")
    public ResponseEntity<?> myEncounters(@RequestParam String health_id, HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, health_id);
        if (ownerCheck != null) return ownerCheck;
        return ResponseEntity.ok(jdbc.queryForList(
            "SELECT e.*, h.hospital_name, " +
            "GROUP_CONCAT(DISTINCT d.name SEPARATOR ', ') AS doctors, " +
            "GROUP_CONCAT(DISTINCT CONCAT(dc.icd10_code, ': ', dic.description) SEPARATOR '; ') AS diagnoses " +
            "FROM ENCOUNTER e " +
            "LEFT JOIN HOSPITAL h ON e.hospital_id = h.hospital_id " +
            "LEFT JOIN ENCOUNTER_DOCTOR ed ON e.encounter_id = ed.encounter_id " +
            "LEFT JOIN DOCTOR d ON ed.doctor_id = d.doctor_id " +
            "LEFT JOIN ENCOUNTER_DIAGNOSIS dc ON e.encounter_id = dc.encounter_id " +
            "LEFT JOIN DIAGNOSIS_CODE dic ON dc.icd10_code = dic.icd10_code " +
            "WHERE e.health_id = ? GROUP BY e.encounter_id ORDER BY e.encounter_date_time DESC", health_id));
    }

    // GET /api/patient-portal/my-prescriptions?health_id=HID-001
    @GetMapping("/my-prescriptions")
    public ResponseEntity<?> myPrescriptions(@RequestParam String health_id, HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, health_id);
        if (ownerCheck != null) return ownerCheck;
        List<Map<String, Object>> prescriptions = jdbc.queryForList(
            "SELECT pr.*, d.name AS doctor_name, d.specialization " +
            "FROM PRESCRIPTION pr " +
            "JOIN ENCOUNTER e ON pr.encounter_id = e.encounter_id " +
            "JOIN DOCTOR d ON pr.doctor_id = d.doctor_id " +
            "WHERE e.health_id = ? ORDER BY pr.created_at DESC", health_id);

        // For each prescription, get items
        for (Map<String, Object> rx : prescriptions) {
            Long rxId = ((Number) rx.get("prescription_id")).longValue();
            rx.put("items", jdbc.queryForList(
                "SELECT pi.*, m.generic_name, m.brand_name, m.drug_class " +
                "FROM PRESCRIPTION_ITEM pi JOIN MEDICATION m ON pi.medication_id = m.medication_id " +
                "WHERE pi.prescription_id = ?", rxId));
        }
        return ResponseEntity.ok(prescriptions);
    }

    // GET /api/patient-portal/my-lab-results?health_id=HID-001
    @GetMapping("/my-lab-results")
    public ResponseEntity<?> myLabResults(@RequestParam String health_id, HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, health_id);
        if (ownerCheck != null) return ownerCheck;
        return ResponseEntity.ok(jdbc.queryForList(
            "SELECT lo.*, ltc.test_name, ltc.specimen_type, d.name AS doctor_name, " +
            "lr.result_id, lr.result_value, lr.result_unit, lr.reference_range, " +
            "lr.abnormal_flag, lr.critical_flag, lr.result_date " +
            "FROM LAB_ORDER lo " +
            "JOIN LAB_TEST_CATALOG ltc ON lo.test_code = ltc.test_code " +
            "JOIN ENCOUNTER e ON lo.encounter_id = e.encounter_id " +
            "JOIN DOCTOR d ON lo.doctor_id = d.doctor_id " +
            "LEFT JOIN LAB_RESULT lr ON lo.lab_order_id = lr.lab_order_id " +
            "WHERE e.health_id = ? ORDER BY lo.order_date_time DESC", health_id));
    }

    // GET /api/patient-portal/my-consents?health_id=HID-001
    @GetMapping("/my-consents")
    public ResponseEntity<?> myConsents(@RequestParam String health_id, HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, health_id);
        if (ownerCheck != null) return ownerCheck;

        return ResponseEntity.ok(jdbc.queryForList(
            "SELECT c.*, h.hospital_name FROM CONSENT c " +
            "JOIN HOSPITAL h ON c.hospital_id = h.hospital_id " +
            "WHERE c.health_id = ? ORDER BY c.created_timestamp DESC", health_id));
    }

    // PUT /api/patient-portal/revoke-consent/{consentId}?health_id=HID-001
    @PutMapping("/revoke-consent/{consentId}")
    public ResponseEntity<?> revokeMyConsent(@PathVariable Long consentId,
                                              @RequestParam String health_id,
                                              HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, health_id);
        if (ownerCheck != null) return ownerCheck;

        // Verify the consent belongs to this patient
        List<Map<String, Object>> consent = jdbc.queryForList(
            "SELECT * FROM CONSENT WHERE consent_id = ? AND health_id = ? AND status = 'Active'",
            consentId, health_id);
        if (consent.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Consent not found or already revoked"));
        }

        int rows = jdbc.update(
            "UPDATE CONSENT SET status = 'Revoked' WHERE consent_id = ? AND health_id = ? AND status = 'Active'",
            consentId, health_id);
        if (rows == 0) {
            return ResponseEntity.badRequest().body(Map.of("error", "Failed to revoke consent"));
        }
        return ResponseEntity.ok(Map.of("message", "Consent revoked successfully. Revocation is immediately effective."));
    }

    // POST /api/patient-portal/grant-consent
    @PostMapping("/grant-consent")
    public ResponseEntity<?> grantConsent(@RequestBody Map<String, Object> body,
                                           HttpServletRequest request) {
        String healthId = (String) body.get("health_id");
        ResponseEntity<?> ownerCheck = validateOwnership(request, healthId);
        if (ownerCheck != null) return ownerCheck;

        try {
            Long hospitalId = Long.valueOf(body.get("hospital_id").toString());
            jdbc.update(
                "INSERT INTO CONSENT (health_id, hospital_id, access_level, purpose, effective_date, expiration_date, status) " +
                "VALUES (?, ?, ?, ?, ?, ?, 'Active')",
                healthId, hospitalId, body.get("access_level"),
                body.get("purpose"), body.get("effective_date"), body.get("expiration_date"));
            Long id = jdbc.queryForObject("SELECT LAST_INSERT_ID()", Long.class);
            return ResponseEntity.ok(Map.of("message", "Consent granted successfully", "consent_id", id));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // GET /api/patient-portal/hospitals - List hospitals for consent grant form
    @GetMapping("/hospitals")
    public ResponseEntity<?> listHospitals(HttpServletRequest request) {
        return ResponseEntity.ok(jdbc.queryForList(
            "SELECT hospital_id, hospital_name, address_city FROM HOSPITAL ORDER BY hospital_name"));
    }

    // PUT /api/patient-portal/update-profile
    @PutMapping("/update-profile")
    public ResponseEntity<?> updateProfile(@RequestBody Map<String, Object> body,
                                            HttpServletRequest request) {
        String healthId = (String) body.get("health_id");
        ResponseEntity<?> ownerCheck = validateOwnership(request, healthId);
        if (ownerCheck != null) return ownerCheck;

        try {
            // Only allow updating contact/insurance fields - NOT clinical data
            int rows = jdbc.update(
                "UPDATE PATIENT SET address_street=?, address_city=?, address_state=?, postal_code=?, " +
                "emergency_contact_name=?, emergency_contact_phone=?, " +
                "insurance_provider=?, insurance_start=?, insurance_end=?, policy_type=? " +
                "WHERE health_id=?",
                body.get("address_street"), body.get("address_city"), body.get("address_state"),
                body.get("postal_code"), body.get("emergency_contact_name"), body.get("emergency_contact_phone"),
                body.get("insurance_provider"), body.get("insurance_start"), body.get("insurance_end"),
                body.get("policy_type"), healthId);

            if (rows == 0) return ResponseEntity.notFound().build();
            return ResponseEntity.ok(Map.of("message", "Profile updated successfully"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // GET /api/patient-portal/encounter/{id}?health_id=HID-001
    @GetMapping("/encounter/{id}")
    public ResponseEntity<?> getEncounterDetail(@PathVariable Long id, @RequestParam String health_id,
                                                 HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, health_id);
        if (ownerCheck != null) return ownerCheck;

        // Verify this encounter belongs to the patient
        List<Map<String, Object>> encRows = jdbc.queryForList(
            "SELECT e.*, p.fname, p.lname, h.hospital_name " +
            "FROM ENCOUNTER e JOIN PATIENT p ON e.health_id = p.health_id " +
            "LEFT JOIN HOSPITAL h ON e.hospital_id = h.hospital_id " +
            "WHERE e.encounter_id = ? AND e.health_id = ?", id, health_id);
        if (encRows.isEmpty()) return ResponseEntity.status(403).body(Map.of("error", "Access denied or encounter not found"));

        Map<String, Object> result = new HashMap<>(encRows.get(0));

        result.put("doctors", jdbc.queryForList(
            "SELECT ed.*, d.name, d.specialization FROM ENCOUNTER_DOCTOR ed " +
            "JOIN DOCTOR d ON ed.doctor_id = d.doctor_id WHERE ed.encounter_id = ?", id));

        result.put("vitals", jdbc.queryForList(
            "SELECT * FROM VITAL_SIGNS WHERE encounter_id = ? ORDER BY reading_timestamp DESC", id));

        result.put("diagnoses", jdbc.queryForList(
            "SELECT ed.*, dc.description, dc.category FROM ENCOUNTER_DIAGNOSIS ed " +
            "JOIN DIAGNOSIS_CODE dc ON ed.icd10_code = dc.icd10_code WHERE ed.encounter_id = ?", id));

        result.put("procedures", jdbc.queryForList(
            "SELECT ep.*, pc.description, pc.category, pc.base_cost FROM ENCOUNTER_PROCEDURE ep " +
            "JOIN PROCEDURE_CODE pc ON ep.cpt_code = pc.cpt_code WHERE ep.encounter_id = ?", id));

        return ResponseEntity.ok(result);
    }

    // PUT /api/patient-portal/update-consent/{consentId}
    @PutMapping("/update-consent/{consentId}")
    public ResponseEntity<?> updateConsent(@PathVariable Long consentId,
                                            @RequestBody Map<String, Object> body,
                                            HttpServletRequest request) {
        String healthId = (String) body.get("health_id");
        ResponseEntity<?> ownerCheck = validateOwnership(request, healthId);
        if (ownerCheck != null) return ownerCheck;

        // Verify consent belongs to this patient and is active
        List<Map<String, Object>> consent = jdbc.queryForList(
            "SELECT * FROM CONSENT WHERE consent_id = ? AND health_id = ? AND status = 'Active'",
            consentId, healthId);
        if (consent.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Consent not found, not active, or does not belong to you"));
        }

        try {
            int rows = jdbc.update(
                "UPDATE CONSENT SET access_level=?, purpose=?, expiration_date=? WHERE consent_id = ? AND health_id = ?",
                body.get("access_level"), body.get("purpose"), body.get("expiration_date"),
                consentId, healthId);
            if (rows == 0) return ResponseEntity.badRequest().body(Map.of("error", "Failed to update consent"));
            return ResponseEntity.ok(Map.of("message", "Consent updated successfully"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // GET /api/patient-portal/access-requests?health_id=HID-001
    @GetMapping("/access-requests")
    public ResponseEntity<?> getAccessRequests(@RequestParam String health_id, HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, health_id);
        if (ownerCheck != null) return ownerCheck;

        return ResponseEntity.ok(jdbc.queryForList(
            "SELECT ar.*, d.name AS doctor_name, d.specialization " +
            "FROM ACCESS_REQUEST ar JOIN DOCTOR d ON ar.doctor_id = d.doctor_id " +
            "WHERE ar.health_id = ? ORDER BY ar.request_time DESC", health_id));
    }

    // GET /api/patient-portal/pending-access-count?health_id=HID-001
    @GetMapping("/pending-access-count")
    public ResponseEntity<?> pendingAccessCount(@RequestParam String health_id, HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, health_id);
        if (ownerCheck != null) return ownerCheck;
        Integer count = jdbc.queryForObject(
            "SELECT COUNT(*) FROM ACCESS_REQUEST WHERE health_id = ? AND status = 'Pending'",
            Integer.class, health_id);
        return ResponseEntity.ok(Map.of("count", count != null ? count : 0));
    }

    // PUT /api/patient-portal/access-requests/{id}/respond?health_id=HID-001
    @PutMapping("/access-requests/{id}/respond")
    public ResponseEntity<?> respondToAccessRequest(@PathVariable Long id,
                                                     @RequestBody Map<String, Object> body,
                                                     HttpServletRequest request) {
        String healthId = (String) body.get("health_id");
        String action = (String) body.get("action"); // "approve" or "deny"
        ResponseEntity<?> ownerCheck = validateOwnership(request, healthId);
        if (ownerCheck != null) return ownerCheck;

        // Verify request belongs to this patient and is pending
        List<Map<String, Object>> req = jdbc.queryForList(
            "SELECT * FROM ACCESS_REQUEST WHERE request_id = ? AND health_id = ? AND status = 'Pending'",
            id, healthId);
        if (req.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Access request not found or already responded"));
        }

        String newStatus = "approve".equalsIgnoreCase(action) ? "Approved" : "Denied";

        jdbc.update(
            "UPDATE ACCESS_REQUEST SET status = ?, responded_at = NOW(), " +
            "expiration_date = " + ("Approved".equals(newStatus) ? "DATE_ADD(CURDATE(), INTERVAL 1 YEAR)" : "NULL") +
            " WHERE request_id = ?",
            newStatus, id);

        // Audit log
        Long doctorId = ((Number) req.get(0).get("doctor_id")).longValue();
        jdbc.update(
            "INSERT INTO AUDIT_LOG (user_id, action_type, table_name, record_id, notes, event_time) " +
            "VALUES (?, ?, 'ACCESS_REQUEST', ?, ?, NOW())",
            request.getAttribute("userId"),
            "Approved".equals(newStatus) ? "ACCESS_GRANTED" : "ACCESS_DENIED",
            String.valueOf(id),
            "Patient " + healthId + " " + newStatus.toLowerCase() + " access request from doctor " + doctorId);

        String msg = "Approved".equals(newStatus)
            ? "Access approved. The doctor can now view your medical records."
            : "Access denied. The doctor will not be able to view your records.";
        return ResponseEntity.ok(Map.of("message", msg));
    }

    // GET /api/patient-portal/my-audit-log?health_id=HID-001
    @GetMapping("/my-audit-log")
    public ResponseEntity<?> myAuditLog(@RequestParam String health_id, HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, health_id);
        if (ownerCheck != null) return ownerCheck;

        return ResponseEntity.ok(jdbc.queryForList(
            "SELECT al.log_id, al.action_type, al.table_name, al.event_time, al.notes, u.username " +
            "FROM AUDIT_LOG al LEFT JOIN APP_USER u ON al.user_id = u.user_id " +
            "WHERE al.record_id = ? OR al.notes LIKE CONCAT('%', ?, '%') " +
            "ORDER BY al.event_time DESC LIMIT 50",
            health_id, health_id));
    }
}
