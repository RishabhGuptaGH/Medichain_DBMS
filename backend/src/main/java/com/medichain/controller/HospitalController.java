package com.medichain.controller;

import com.medichain.dao.HospitalDAO;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/hospitals")
@CrossOrigin(origins = "*")
public class HospitalController {

    private final HospitalDAO hospitalDAO;

    public HospitalController(HospitalDAO hospitalDAO) {
        this.hospitalDAO = hospitalDAO;
    }

    @GetMapping
    public ResponseEntity<?> getAll() {
        return ResponseEntity.ok(hospitalDAO.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getOne(@PathVariable Long id) {
        Map<String, Object> hospital = hospitalDAO.findById(id);
        if (hospital == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(hospital);
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody Map<String, Object> body) {
        try {
            hospitalDAO.create(body);
            return ResponseEntity.ok(Map.of("message", "Hospital registered successfully"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        try {
            int rows = hospitalDAO.update(id, body);
            if (rows == 0) return ResponseEntity.notFound().build();
            return ResponseEntity.ok(Map.of("message", "Hospital updated successfully"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/{id}/departments")
    public ResponseEntity<?> getDepartments(@PathVariable Long id) {
        return ResponseEntity.ok(hospitalDAO.getDepartments(id));
    }

    @PostMapping("/{id}/departments")
    public ResponseEntity<?> addDepartment(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        try {
            hospitalDAO.addDepartment(id, (String) body.get("department_name"));
            return ResponseEntity.ok(Map.of("message", "Department added"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
