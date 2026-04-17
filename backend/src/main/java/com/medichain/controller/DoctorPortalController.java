package com.medichain.controller;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.servlet.http.HttpServletRequest;
import java.util.*;

@RestController
@RequestMapping("/api/doctor-portal")
@CrossOrigin(origins = "*")
public class DoctorPortalController {

    private final JdbcTemplate jdbc;

    public DoctorPortalController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * Validates that the authenticated doctor user owns the requested doctor_id.
     * Returns null if valid, or an error ResponseEntity if not.
     */
    private ResponseEntity<?> validateOwnership(HttpServletRequest request, Long doctorId) {
        Long userId = (Long) request.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(401).body(Map.of("error", "Authentication required"));
        }
        List<Long> ids = jdbc.queryForList(
            "SELECT doctor_id FROM DOCTOR_USER WHERE user_id = ?", Long.class, userId);
        if (ids.isEmpty() || !ids.get(0).equals(doctorId)) {
            return ResponseEntity.status(403).body(Map.of("error", "Access denied. You can only view your own portal data."));
        }
        return null;
    }

    // GET /api/doctor-portal/dashboard?doctor_id=1
    @GetMapping("/dashboard")
    public ResponseEntity<?> dashboard(@RequestParam Long doctor_id, HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, doctor_id);
        if (ownerCheck != null) return ownerCheck;
        Map<String, Object> stats = new HashMap<>();

        // Count distinct patients this doctor has seen
        stats.put("my_patients", jdbc.queryForObject(
            "SELECT COUNT(DISTINCT e.health_id) FROM ENCOUNTER e " +
            "JOIN ENCOUNTER_DOCTOR ed ON e.encounter_id = ed.encounter_id " +
            "WHERE ed.doctor_id = ?", Integer.class, doctor_id));

        stats.put("my_encounters", jdbc.queryForObject(
            "SELECT COUNT(*) FROM ENCOUNTER_DOCTOR WHERE doctor_id = ?", Integer.class, doctor_id));

        stats.put("active_prescriptions", jdbc.queryForObject(
            "SELECT COUNT(*) FROM PRESCRIPTION WHERE doctor_id = ? AND status = 'Active'", Integer.class, doctor_id));

        stats.put("pending_labs", jdbc.queryForObject(
            "SELECT COUNT(*) FROM LAB_ORDER WHERE doctor_id = ? AND order_status IN ('Pending','In Progress')", Integer.class, doctor_id));

        stats.put("completed_labs", jdbc.queryForObject(
            "SELECT COUNT(*) FROM LAB_ORDER WHERE doctor_id = ? AND order_status = 'Completed'", Integer.class, doctor_id));

        stats.put("critical_alerts", jdbc.queryForObject(
            "SELECT COUNT(*) FROM LAB_RESULT lr JOIN LAB_ORDER lo ON lr.lab_order_id = lo.lab_order_id " +
            "WHERE lo.doctor_id = ? AND lr.critical_flag = TRUE AND lr.physician_acknowledged = FALSE", Integer.class, doctor_id));

        // Recent encounters
        stats.put("recent_encounters", jdbc.queryForList(
            "SELECT e.encounter_id, e.encounter_type, e.encounter_date_time, " +
            "p.fname, p.lname, p.health_id, h.hospital_name " +
            "FROM ENCOUNTER e " +
            "JOIN ENCOUNTER_DOCTOR ed ON e.encounter_id = ed.encounter_id " +
            "JOIN PATIENT p ON e.health_id = p.health_id " +
            "LEFT JOIN HOSPITAL h ON e.hospital_id = h.hospital_id " +
            "WHERE ed.doctor_id = ? ORDER BY e.encounter_date_time DESC LIMIT 10", doctor_id));

        return ResponseEntity.ok(stats);
    }

    // GET /api/doctor-portal/my-patients?doctor_id=1
    @GetMapping("/my-patients")
    public ResponseEntity<?> myPatients(@RequestParam Long doctor_id, HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, doctor_id);
        if (ownerCheck != null) return ownerCheck;
        return ResponseEntity.ok(jdbc.queryForList(
            "SELECT DISTINCT p.*, TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age " +
            "FROM PATIENT p " +
            "JOIN ENCOUNTER e ON p.health_id = e.health_id " +
            "JOIN ENCOUNTER_DOCTOR ed ON e.encounter_id = ed.encounter_id " +
            "WHERE ed.doctor_id = ? ORDER BY p.fname", doctor_id));
    }

    // GET /api/doctor-portal/my-encounters?doctor_id=1
    @GetMapping("/my-encounters")
    public ResponseEntity<?> myEncounters(@RequestParam Long doctor_id, HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, doctor_id);
        if (ownerCheck != null) return ownerCheck;
        return ResponseEntity.ok(jdbc.queryForList(
            "SELECT e.*, p.fname, p.lname, p.health_id, h.hospital_name, " +
            "ed.role, ed.is_primary " +
            "FROM ENCOUNTER e " +
            "JOIN ENCOUNTER_DOCTOR ed ON e.encounter_id = ed.encounter_id " +
            "JOIN PATIENT p ON e.health_id = p.health_id " +
            "LEFT JOIN HOSPITAL h ON e.hospital_id = h.hospital_id " +
            "WHERE ed.doctor_id = ? ORDER BY e.encounter_date_time DESC", doctor_id));
    }

    // GET /api/doctor-portal/my-prescriptions?doctor_id=1
    @GetMapping("/my-prescriptions")
    public ResponseEntity<?> myPrescriptions(@RequestParam Long doctor_id, HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, doctor_id);
        if (ownerCheck != null) return ownerCheck;
        return ResponseEntity.ok(jdbc.queryForList(
            "SELECT pr.*, p.fname, p.lname, p.health_id " +
            "FROM PRESCRIPTION pr " +
            "JOIN ENCOUNTER e ON pr.encounter_id = e.encounter_id " +
            "JOIN PATIENT p ON e.health_id = p.health_id " +
            "WHERE pr.doctor_id = ? ORDER BY pr.created_at DESC", doctor_id));
    }

    // GET /api/doctor-portal/my-lab-orders?doctor_id=1
    @GetMapping("/my-lab-orders")
    public ResponseEntity<?> myLabOrders(@RequestParam Long doctor_id, HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, doctor_id);
        if (ownerCheck != null) return ownerCheck;
        return ResponseEntity.ok(jdbc.queryForList(
            "SELECT lo.*, ltc.test_name, p.fname, p.lname, p.health_id, " +
            "lr.result_value, lr.result_unit, lr.abnormal_flag, lr.critical_flag, lr.physician_acknowledged " +
            "FROM LAB_ORDER lo " +
            "JOIN LAB_TEST_CATALOG ltc ON lo.test_code = ltc.test_code " +
            "JOIN ENCOUNTER e ON lo.encounter_id = e.encounter_id " +
            "JOIN PATIENT p ON e.health_id = p.health_id " +
            "LEFT JOIN LAB_RESULT lr ON lo.lab_order_id = lr.lab_order_id " +
            "WHERE lo.doctor_id = ? ORDER BY lo.order_date_time DESC", doctor_id));
    }

    // GET /api/doctor-portal/patient-history?health_id=HID-001&doctor_id=1
    // Full medical history lookup for any patient - requires consent check
    @GetMapping("/patient-history")
    public ResponseEntity<?> patientHistory(@RequestParam String health_id, @RequestParam Long doctor_id,
                                             HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, doctor_id);
        if (ownerCheck != null) return ownerCheck;
        Map<String, Object> result = new HashMap<>();

        // Check if doctor has an active consent or emergency access for this patient
        boolean hasConsent = checkDoctorAccess(health_id, doctor_id);
        if (!hasConsent) {
            return ResponseEntity.status(403).body(Map.of(
                "error", "Access denied. No active consent or emergency access found for this patient's data. " +
                         "Please obtain patient consent or use Emergency Access for urgent cases."
            ));
        }

        // Patient profile
        List<Map<String, Object>> profile = jdbc.queryForList(
            "SELECT p.*, TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age, " +
            "CASE WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 1 THEN 'Infant' " +
            "WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 13 THEN 'Child' " +
            "WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 18 THEN 'Teenager' " +
            "WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 65 THEN 'Adult' " +
            "ELSE 'Senior' END AS age_category FROM PATIENT p WHERE p.health_id = ?", health_id);
        if (profile.isEmpty()) return ResponseEntity.notFound().build();
        result.put("patient", profile.get(0));

        // Allergies
        result.put("allergies", jdbc.queryForList(
            "SELECT * FROM PATIENT_ALLERGY WHERE health_id = ? AND status = 'Active'", health_id));

        // All encounters with doctors and diagnoses
        result.put("encounters", jdbc.queryForList(
            "SELECT e.encounter_id, e.encounter_type, e.encounter_date_time, e.chief_complaint, " +
            "e.treatment_plan, h.hospital_name, " +
            "GROUP_CONCAT(DISTINCT d.name SEPARATOR ', ') AS doctors, " +
            "GROUP_CONCAT(DISTINCT CONCAT(dc.icd10_code, ': ', dic.description) SEPARATOR '; ') AS diagnoses " +
            "FROM ENCOUNTER e " +
            "LEFT JOIN HOSPITAL h ON e.hospital_id = h.hospital_id " +
            "LEFT JOIN ENCOUNTER_DOCTOR ed ON e.encounter_id = ed.encounter_id " +
            "LEFT JOIN DOCTOR d ON ed.doctor_id = d.doctor_id " +
            "LEFT JOIN ENCOUNTER_DIAGNOSIS dc ON e.encounter_id = dc.encounter_id " +
            "LEFT JOIN DIAGNOSIS_CODE dic ON dc.icd10_code = dic.icd10_code " +
            "WHERE e.health_id = ? GROUP BY e.encounter_id ORDER BY e.encounter_date_time DESC", health_id));

        // Prescriptions with items
        List<Map<String, Object>> prescriptions = jdbc.queryForList(
            "SELECT pr.*, d.name AS doctor_name, d.specialization " +
            "FROM PRESCRIPTION pr " +
            "JOIN ENCOUNTER e ON pr.encounter_id = e.encounter_id " +
            "JOIN DOCTOR d ON pr.doctor_id = d.doctor_id " +
            "WHERE e.health_id = ? ORDER BY pr.created_at DESC", health_id);
        for (Map<String, Object> rx : prescriptions) {
            Long rxId = ((Number) rx.get("prescription_id")).longValue();
            rx.put("items", jdbc.queryForList(
                "SELECT pi.*, m.generic_name, m.brand_name, m.drug_class " +
                "FROM PRESCRIPTION_ITEM pi JOIN MEDICATION m ON pi.medication_id = m.medication_id " +
                "WHERE pi.prescription_id = ?", rxId));
        }
        result.put("prescriptions", prescriptions);

        // Lab results
        result.put("lab_results", jdbc.queryForList(
            "SELECT lo.*, ltc.test_name, ltc.specimen_type, d.name AS doctor_name, " +
            "lr.result_value, lr.result_unit, lr.reference_range, " +
            "lr.abnormal_flag, lr.critical_flag, lr.result_date " +
            "FROM LAB_ORDER lo " +
            "JOIN LAB_TEST_CATALOG ltc ON lo.test_code = ltc.test_code " +
            "JOIN ENCOUNTER e ON lo.encounter_id = e.encounter_id " +
            "JOIN DOCTOR d ON lo.doctor_id = d.doctor_id " +
            "LEFT JOIN LAB_RESULT lr ON lo.lab_order_id = lr.lab_order_id " +
            "WHERE e.health_id = ? ORDER BY lo.order_date_time DESC", health_id));

        // Vital signs (latest per encounter)
        result.put("vitals", jdbc.queryForList(
            "SELECT vs.*, e.encounter_type, e.encounter_date_time " +
            "FROM VITAL_SIGNS vs " +
            "JOIN ENCOUNTER e ON vs.encounter_id = e.encounter_id " +
            "WHERE e.health_id = ? ORDER BY vs.reading_timestamp DESC LIMIT 10", health_id));

        return ResponseEntity.ok(result);
    }

    // GET /api/doctor-portal/patient-detail/{health_id}?doctor_id=1
    // View details of a patient the doctor has treated
    @GetMapping("/patient-detail/{health_id}")
    public ResponseEntity<?> patientDetail(@PathVariable String health_id, @RequestParam Long doctor_id,
                                            HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, doctor_id);
        if (ownerCheck != null) return ownerCheck;

        // Verify doctor has treated this patient
        Integer encounterCount = jdbc.queryForObject(
            "SELECT COUNT(*) FROM ENCOUNTER e JOIN ENCOUNTER_DOCTOR ed ON e.encounter_id = ed.encounter_id " +
            "WHERE e.health_id = ? AND ed.doctor_id = ?", Integer.class, health_id, doctor_id);
        if (encounterCount == null || encounterCount == 0) {
            return ResponseEntity.status(403).body(Map.of("error", "You have not treated this patient."));
        }

        Map<String, Object> result = new HashMap<>();
        List<Map<String, Object>> profile = jdbc.queryForList(
            "SELECT p.*, TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age, " +
            "CASE WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 1 THEN 'Infant' " +
            "WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 13 THEN 'Child' " +
            "WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 18 THEN 'Teenager' " +
            "WHEN TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) < 65 THEN 'Adult' " +
            "ELSE 'Senior' END AS age_category FROM PATIENT p WHERE p.health_id = ?", health_id);
        if (profile.isEmpty()) return ResponseEntity.notFound().build();
        result.put("patient", profile.get(0));
        result.put("allergies", jdbc.queryForList(
            "SELECT * FROM PATIENT_ALLERGY WHERE health_id = ? AND status = 'Active'", health_id));
        return ResponseEntity.ok(result);
    }

    // GET /api/doctor-portal/search-patients?q=...&doctor_id=1
    // Search all patients - returns limited info for unknown patients
    @GetMapping("/search-patients")
    public ResponseEntity<?> searchPatients(@RequestParam String q, @RequestParam Long doctor_id,
                                             HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, doctor_id);
        if (ownerCheck != null) return ownerCheck;

        String like = "%" + q + "%";
        List<Map<String, Object>> patients = jdbc.queryForList(
            "SELECT p.health_id, p.fname, p.lname, p.gender, " +
            "TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE()) AS age, p.blood_group " +
            "FROM PATIENT p WHERE p.health_id LIKE ? OR p.fname LIKE ? OR p.lname LIKE ?",
            like, like, like);

        // For each patient, indicate access level
        for (Map<String, Object> p : patients) {
            String hid = (String) p.get("health_id");
            boolean hasAccess = checkDoctorAccess(hid, doctor_id);
            boolean hasTreated = jdbc.queryForObject(
                "SELECT COUNT(*) FROM ENCOUNTER e JOIN ENCOUNTER_DOCTOR ed ON e.encounter_id = ed.encounter_id " +
                "WHERE e.health_id = ? AND ed.doctor_id = ?", Integer.class, hid, doctor_id) > 0;
            boolean hasPending = false;
            try {
                Integer pendingRequest = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM ACCESS_REQUEST WHERE health_id = ? AND doctor_id = ? AND status = 'Pending'",
                    Integer.class, hid, doctor_id);
                hasPending = pendingRequest != null && pendingRequest > 0;
            } catch (Exception ignored) {}
            p.put("has_full_access", hasAccess);
            p.put("has_treated", hasTreated);
            p.put("has_pending_request", hasPending);
        }
        return ResponseEntity.ok(patients);
    }

    // POST /api/doctor-portal/emergency-access
    @PostMapping("/emergency-access")
    public ResponseEntity<?> requestEmergencyAccess(@RequestBody Map<String, Object> body,
                                                      HttpServletRequest request) {
        String healthId = (String) body.get("health_id");
        Long doctorId = Long.valueOf(body.get("doctor_id").toString());
        String emergencyType = (String) body.get("emergency_type");
        String justification = (String) body.get("justification");

        ResponseEntity<?> ownerCheck = validateOwnership(request, doctorId);
        if (ownerCheck != null) return ownerCheck;

        if (healthId == null || emergencyType == null || justification == null || justification.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Health ID, emergency type, and justification are required"));
        }

        // Verify patient exists
        Integer patientExists = jdbc.queryForObject(
            "SELECT COUNT(*) FROM PATIENT WHERE health_id = ?", Integer.class, healthId);
        if (patientExists == null || patientExists == 0) {
            return ResponseEntity.badRequest().body(Map.of("error", "Patient not found"));
        }

        // Check if there's already an active emergency access
        Integer existing = jdbc.queryForObject(
            "SELECT COUNT(*) FROM EMERGENCY_ACCESS WHERE health_id = ? AND doctor_id = ? " +
            "AND access_time >= DATE_SUB(NOW(), INTERVAL 24 HOUR) AND review_status != 'Flagged'",
            Integer.class, healthId, doctorId);
        if (existing != null && existing > 0) {
            return ResponseEntity.ok(Map.of("message", "Emergency access already active", "already_active", true));
        }

        try {
            jdbc.update(
                "INSERT INTO EMERGENCY_ACCESS (health_id, doctor_id, emergency_type, justification, duration_minutes) " +
                "VALUES (?, ?, ?, ?, 1440)",
                healthId, doctorId, emergencyType, justification);
            Long accessId = jdbc.queryForObject("SELECT LAST_INSERT_ID()", Long.class);
            return ResponseEntity.ok(Map.of(
                "message", "Emergency access granted for 24 hours. This access will be reviewed by administration.",
                "access_id", accessId));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // POST /api/doctor-portal/request-access
    @PostMapping("/request-access")
    public ResponseEntity<?> requestRegularAccess(@RequestBody Map<String, Object> body,
                                                   HttpServletRequest request) {
        String healthId = (String) body.get("health_id");
        Long doctorId = Long.valueOf(body.get("doctor_id").toString());
        String reason = (String) body.get("reason");

        ResponseEntity<?> ownerCheck = validateOwnership(request, doctorId);
        if (ownerCheck != null) return ownerCheck;

        if (healthId == null || reason == null || reason.trim().length() < 10) {
            return ResponseEntity.badRequest().body(Map.of("error", "Health ID and reason (min 10 characters) are required"));
        }

        // Verify patient exists
        Integer patientExists = jdbc.queryForObject(
            "SELECT COUNT(*) FROM PATIENT WHERE health_id = ?", Integer.class, healthId);
        if (patientExists == null || patientExists == 0) {
            return ResponseEntity.badRequest().body(Map.of("error", "Patient not found"));
        }

        // Check if there's already a pending request
        Integer existing = jdbc.queryForObject(
            "SELECT COUNT(*) FROM ACCESS_REQUEST WHERE health_id = ? AND doctor_id = ? AND status = 'Pending'",
            Integer.class, healthId, doctorId);
        if (existing != null && existing > 0) {
            return ResponseEntity.ok(Map.of("message", "Access request already pending. Waiting for patient approval.", "already_pending", true));
        }

        // Check if already has approved access
        Integer approved = jdbc.queryForObject(
            "SELECT COUNT(*) FROM ACCESS_REQUEST WHERE health_id = ? AND doctor_id = ? AND status = 'Approved' " +
            "AND (expiration_date IS NULL OR expiration_date >= CURDATE())",
            Integer.class, healthId, doctorId);
        if (approved != null && approved > 0) {
            return ResponseEntity.ok(Map.of("message", "You already have approved access to this patient.", "already_approved", true));
        }

        try {
            jdbc.update(
                "INSERT INTO ACCESS_REQUEST (health_id, doctor_id, request_reason, access_level) VALUES (?, ?, ?, 'Full')",
                healthId, doctorId, reason);
            Long requestId = jdbc.queryForObject("SELECT LAST_INSERT_ID()", Long.class);

            // Log to audit
            jdbc.update(
                "INSERT INTO AUDIT_LOG (user_id, action_type, table_name, record_id, notes, event_time) " +
                "VALUES (?, 'ACCESS_REQUEST', 'ACCESS_REQUEST', ?, ?, NOW())",
                request.getAttribute("userId"),
                String.valueOf(requestId),
                "Doctor " + doctorId + " requested regular access to patient " + healthId + " | Reason: " + reason);

            return ResponseEntity.ok(Map.of(
                "message", "Access request sent to patient. You will be able to view their records once they approve.",
                "request_id", requestId));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // GET /api/doctor-portal/my-access-requests?doctor_id=1
    @GetMapping("/my-access-requests")
    public ResponseEntity<?> myAccessRequests(@RequestParam Long doctor_id, HttpServletRequest request) {
        ResponseEntity<?> ownerCheck = validateOwnership(request, doctor_id);
        if (ownerCheck != null) return ownerCheck;
        return ResponseEntity.ok(jdbc.queryForList(
            "SELECT ar.*, p.fname, p.lname FROM ACCESS_REQUEST ar " +
            "JOIN PATIENT p ON ar.health_id = p.health_id " +
            "WHERE ar.doctor_id = ? ORDER BY ar.request_time DESC", doctor_id));
    }

    // Helper: Check if doctor has consent or emergency access to patient data
    private boolean checkDoctorAccess(String healthId, Long doctorId) {
        // Check if doctor has treated this patient (has encounter-doctor relationship)
        Integer encounterCount = jdbc.queryForObject(
            "SELECT COUNT(*) FROM ENCOUNTER e " +
            "JOIN ENCOUNTER_DOCTOR ed ON e.encounter_id = ed.encounter_id " +
            "WHERE e.health_id = ? AND ed.doctor_id = ?", Integer.class, healthId, doctorId);

        if (encounterCount != null && encounterCount > 0) {
            // Doctor has treated this patient - verify there's an active consent
            Integer consentCount = jdbc.queryForObject(
                "SELECT COUNT(*) FROM CONSENT c " +
                "JOIN ENCOUNTER e ON e.health_id = c.health_id " +
                "JOIN ENCOUNTER_DOCTOR ed ON e.encounter_id = ed.encounter_id " +
                "WHERE e.health_id = ? AND ed.doctor_id = ? " +
                "AND c.status = 'Active' AND c.effective_date <= CURDATE() " +
                "AND (c.expiration_date IS NULL OR c.expiration_date >= CURDATE())",
                Integer.class, healthId, doctorId);

            if (consentCount != null && consentCount > 0) return true;
        }

        // Check approved regular access requests
        try {
            Integer accessRequestCount = jdbc.queryForObject(
                "SELECT COUNT(*) FROM ACCESS_REQUEST " +
                "WHERE health_id = ? AND doctor_id = ? AND status = 'Approved' " +
                "AND (expiration_date IS NULL OR expiration_date >= CURDATE())",
                Integer.class, healthId, doctorId);
            if (accessRequestCount != null && accessRequestCount > 0) return true;
        } catch (Exception ignored) {}

        // Check emergency access
        Integer emergencyCount = jdbc.queryForObject(
            "SELECT COUNT(*) FROM EMERGENCY_ACCESS " +
            "WHERE health_id = ? AND doctor_id = ? " +
            "AND access_time >= DATE_SUB(NOW(), INTERVAL 24 HOUR) " +
            "AND review_status != 'Flagged'",
            Integer.class, healthId, doctorId);

        return emergencyCount != null && emergencyCount > 0;
    }
}
