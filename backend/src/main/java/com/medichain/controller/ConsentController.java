package com.medichain.controller;

import com.medichain.dao.ConsentDAO;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/consent")
@CrossOrigin(origins = "*")
public class ConsentController {

    private final ConsentDAO consentDAO;

    public ConsentController(ConsentDAO consentDAO) {
        this.consentDAO = consentDAO;
    }

    @GetMapping
    public ResponseEntity<?> getAll(@RequestParam(required = false) String health_id) {
        if (health_id != null && !health_id.isEmpty()) {
            return ResponseEntity.ok(consentDAO.findByPatient(health_id));
        }
        return ResponseEntity.ok(consentDAO.findAll());
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody Map<String, Object> body) {
        try {
            Long id = consentDAO.create(body);
            return ResponseEntity.ok(Map.of("message", "Consent granted", "consent_id", id));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PutMapping("/{id}/revoke")
    public ResponseEntity<?> revoke(@PathVariable Long id) {
        try {
            int rows = consentDAO.revoke(id);
            if (rows == 0) return ResponseEntity.badRequest().body(Map.of("error", "Consent not found or already revoked"));
            return ResponseEntity.ok(Map.of("message", "Consent revoked successfully"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/check")
    public ResponseEntity<?> checkConsent(@RequestParam String health_id, @RequestParam Long hospital_id) {
        boolean hasConsent = consentDAO.checkConsent(health_id, hospital_id);
        return ResponseEntity.ok(Map.of("has_consent", hasConsent));
    }

    // Emergency Access
    @PostMapping("/emergency-access")
    public ResponseEntity<?> emergencyAccess(@RequestBody Map<String, Object> body) {
        try {
            // Validate required fields
            if (body.get("justification") == null || body.get("justification").toString().isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "Justification is required for emergency access"));
            }
            Long id = consentDAO.createEmergencyAccess(body);
            return ResponseEntity.ok(Map.of(
                    "message", "Emergency access granted. This access has been logged and will be reviewed.",
                    "access_id", id
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/emergency-access")
    public ResponseEntity<?> getEmergencyAccesses() {
        return ResponseEntity.ok(consentDAO.getEmergencyAccesses());
    }

    @PutMapping("/emergency-access/{id}/review")
    public ResponseEntity<?> reviewEmergencyAccess(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        try {
            consentDAO.reviewEmergencyAccess(id, (String) body.get("review_status"),
                    Long.valueOf(body.get("reviewed_by").toString()));
            return ResponseEntity.ok(Map.of("message", "Emergency access reviewed"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
