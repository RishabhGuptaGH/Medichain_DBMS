package com.medichain.controller;

import com.medichain.dao.AuditDAO;
import com.medichain.dao.PatientDAO;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/patients")
@CrossOrigin(origins = "*")
public class PatientController {

    private final PatientDAO patientDAO;
    private final AuditDAO auditDAO;

    public PatientController(PatientDAO patientDAO, AuditDAO auditDAO) {
        this.patientDAO = patientDAO;
        this.auditDAO = auditDAO;
    }

    @GetMapping
    public ResponseEntity<?> getAll(@RequestParam(required = false) String search) {
        if (search != null && !search.isEmpty()) {
            return ResponseEntity.ok(patientDAO.search(search));
        }
        return ResponseEntity.ok(patientDAO.findAll());
    }

    @GetMapping("/{healthId}")
    public ResponseEntity<?> getOne(@PathVariable String healthId) {
        Map<String, Object> patient = patientDAO.findById(healthId);
        if (patient == null) {
            return ResponseEntity.notFound().build();
        }

        auditDAO.logAction(null, "VIEW", "PATIENT", healthId, null, null,
                "Patient record accessed: " + healthId);

        return ResponseEntity.ok(patient);
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody Map<String, Object> body) {
        try {
            patientDAO.create(body);
            auditDAO.logAction(null, "CREATE", "PATIENT", (String) body.get("health_id"),
                    null, null, "New patient registered: " + body.get("health_id"));
            return ResponseEntity.ok(Map.of("message", "Patient registered successfully",
                    "health_id", body.get("health_id")));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PutMapping("/{healthId}")
    public ResponseEntity<?> update(@PathVariable String healthId, @RequestBody Map<String, Object> body) {
        try {
            int rows = patientDAO.update(healthId, body);
            if (rows == 0) return ResponseEntity.notFound().build();
            return ResponseEntity.ok(Map.of("message", "Patient updated successfully"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @DeleteMapping("/{healthId}")
    public ResponseEntity<?> delete(@PathVariable String healthId) {
        try {
            int rows = patientDAO.delete(healthId);
            if (rows == 0) return ResponseEntity.notFound().build();
            auditDAO.logAction(null, "DELETE", "PATIENT", healthId, null, null,
                    "Patient deleted: " + healthId);
            return ResponseEntity.ok(Map.of("message", "Patient deleted"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // Allergies
    @GetMapping("/{healthId}/allergies")
    public ResponseEntity<?> getAllergies(@PathVariable String healthId) {
        return ResponseEntity.ok(patientDAO.getAllergies(healthId));
    }

    @PostMapping("/{healthId}/allergies")
    public ResponseEntity<?> addAllergy(@PathVariable String healthId, @RequestBody Map<String, Object> body) {
        try {
            body.put("health_id", healthId);
            patientDAO.addAllergy(body);
            return ResponseEntity.ok(Map.of("message", "Allergy added successfully"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
