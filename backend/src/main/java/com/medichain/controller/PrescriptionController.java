package com.medichain.controller;

import com.medichain.dao.PrescriptionDAO;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/prescriptions")
@CrossOrigin(origins = "*")
public class PrescriptionController {

    private final PrescriptionDAO prescriptionDAO;

    public PrescriptionController(PrescriptionDAO prescriptionDAO) {
        this.prescriptionDAO = prescriptionDAO;
    }

    @GetMapping
    public ResponseEntity<?> getAll() {
        return ResponseEntity.ok(prescriptionDAO.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getOne(@PathVariable Long id) {
        Map<String, Object> rx = prescriptionDAO.findById(id);
        if (rx == null) return ResponseEntity.notFound().build();

        Map<String, Object> result = new HashMap<>(rx);
        result.put("items", prescriptionDAO.getItems(id));
        return ResponseEntity.ok(result);
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody Map<String, Object> body) {
        try {
            Long id = prescriptionDAO.create(body);
            return ResponseEntity.ok(Map.of("message", "Prescription created", "prescription_id", id));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/{id}/items")
    public ResponseEntity<?> addItem(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        try {
            body.put("prescription_id", id);
            prescriptionDAO.addItem(body);
            return ResponseEntity.ok(Map.of("message", "Medication added to prescription"));
        } catch (Exception e) {
            // Catch allergy trigger errors
            String msg = e.getMessage();
            if (msg != null && msg.contains("ALLERGY ALERT")) {
                return ResponseEntity.status(409).body(Map.of(
                        "error", "ALLERGY_ALERT",
                        "message", msg,
                        "requires_override", true
                ));
            }
            return ResponseEntity.badRequest().body(Map.of("error", msg));
        }
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<?> updateStatus(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        try {
            int rows = prescriptionDAO.updateStatus(id, (String) body.get("status"));
            if (rows == 0) return ResponseEntity.notFound().build();
            return ResponseEntity.ok(Map.of("message", "Prescription status updated"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    // Safety checks
    @GetMapping("/check-allergy")
    public ResponseEntity<?> checkAllergy(@RequestParam String health_id, @RequestParam Long medication_id) {
        List<Map<String, Object>> allergies = prescriptionDAO.checkAllergy(health_id, medication_id);
        Map<String, Object> result = new HashMap<>();
        result.put("has_allergy", !allergies.isEmpty());
        result.put("allergies", allergies);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/check-interactions")
    public ResponseEntity<?> checkInteractions(@RequestParam String health_id, @RequestParam Long medication_id) {
        List<Map<String, Object>> interactions = prescriptionDAO.checkDrugInteractions(health_id, medication_id);
        Map<String, Object> result = new HashMap<>();
        result.put("has_interactions", !interactions.isEmpty());
        result.put("interactions", interactions);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/medications")
    public ResponseEntity<?> getMedications() {
        return ResponseEntity.ok(prescriptionDAO.getMedications());
    }

    @GetMapping("/active-medications/{healthId}")
    public ResponseEntity<?> getActiveMedications(@PathVariable String healthId) {
        return ResponseEntity.ok(prescriptionDAO.getActivePatientMedications(healthId));
    }
}
