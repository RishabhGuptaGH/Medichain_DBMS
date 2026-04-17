package com.medichain.controller;

import com.medichain.dao.AuditDAO;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/audit")
@CrossOrigin(origins = "*")
public class AuditController {

    private final AuditDAO auditDAO;

    public AuditController(AuditDAO auditDAO) {
        this.auditDAO = auditDAO;
    }

    @GetMapping
    public ResponseEntity<?> getAll(
            @RequestParam(defaultValue = "50") int limit,
            @RequestParam(defaultValue = "0") int offset,
            @RequestParam(required = false) String action_type,
            @RequestParam(required = false) String table_name) {

        List<Map<String, Object>> logs;
        if (action_type != null && !action_type.isEmpty()) {
            logs = auditDAO.findByAction(action_type);
        } else if (table_name != null && !table_name.isEmpty()) {
            logs = auditDAO.findByTable(table_name);
        } else {
            logs = auditDAO.findAll(limit, offset);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("logs", logs);
        result.put("total", auditDAO.getTotalCount());
        return ResponseEntity.ok(result);
    }

    @GetMapping("/verify")
    public ResponseEntity<?> verifyChain() {
        return ResponseEntity.ok(auditDAO.verifyChain());
    }

    @GetMapping("/action-types")
    public ResponseEntity<?> getActionTypes() {
        return ResponseEntity.ok(auditDAO.getActionTypes());
    }

    @GetMapping("/login-attempts")
    public ResponseEntity<?> getLoginAttempts(@RequestParam(defaultValue = "50") int limit) {
        return ResponseEntity.ok(auditDAO.getLoginAttempts(limit));
    }
}
