package com.medichain.controller;

import com.medichain.dao.AuditDAO;
import com.medichain.dao.EncounterDAO;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/encounters")
@CrossOrigin(origins = "*")
public class EncounterController {

    private final EncounterDAO encounterDAO;
    private final AuditDAO auditDAO;

    public EncounterController(EncounterDAO encounterDAO, AuditDAO auditDAO) {
        this.encounterDAO = encounterDAO;
        this.auditDAO = auditDAO;
    }

    @GetMapping
    public ResponseEntity<?> getAll(@RequestParam(required = false) String health_id) {
        if (health_id != null && !health_id.isEmpty()) {
            return ResponseEntity.ok(encounterDAO.findByPatient(health_id));
        }
        return ResponseEntity.ok(encounterDAO.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getOne(@PathVariable Long id) {
        Map<String, Object> enc = encounterDAO.findById(id);
        if (enc == null) return ResponseEntity.notFound().build();

        // Get related data
        Map<String, Object> result = new HashMap<>(enc);
        result.put("doctors", encounterDAO.getDoctors(id));
        result.put("vitals", encounterDAO.getVitals(id));
        result.put("diagnoses", encounterDAO.getDiagnoses(id));
        result.put("procedures", encounterDAO.getProcedures(id));

        return ResponseEntity.ok(result);
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody Map<String, Object> body) {
        try {
            Long id = encounterDAO.create(body);

            // Assign doctor if provided
            if (body.get("doctor_id") != null) {
                encounterDAO.assignDoctor(id, Long.valueOf(body.get("doctor_id").toString()),
                        (String) body.getOrDefault("doctor_role", "Attending Physician"), true);
            }

            auditDAO.logAction(null, "CREATE", "ENCOUNTER", id.toString(),
                    null, null, "Encounter created for patient " + body.get("health_id"));

            return ResponseEntity.ok(Map.of("message", "Encounter created", "encounter_id", id));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/{id}/doctors")
    public ResponseEntity<?> assignDoctor(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        try {
            encounterDAO.assignDoctor(id, Long.valueOf(body.get("doctor_id").toString()),
                    (String) body.get("role"),
                    Boolean.TRUE.equals(body.get("is_primary")));
            return ResponseEntity.ok(Map.of("message", "Doctor assigned to encounter"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/{id}/vitals")
    public ResponseEntity<?> addVitals(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        try {
            body.put("encounter_id", id);
            encounterDAO.addVitals(body);
            return ResponseEntity.ok(Map.of("message", "Vital signs recorded"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/{id}/diagnoses")
    public ResponseEntity<?> addDiagnosis(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        try {
            body.put("encounter_id", id);
            encounterDAO.addDiagnosis(body);
            return ResponseEntity.ok(Map.of("message", "Diagnosis added"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/{id}/procedures")
    public ResponseEntity<?> addProcedure(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        try {
            body.put("encounter_id", id);
            encounterDAO.addProcedure(body);
            return ResponseEntity.ok(Map.of("message", "Procedure recorded"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
