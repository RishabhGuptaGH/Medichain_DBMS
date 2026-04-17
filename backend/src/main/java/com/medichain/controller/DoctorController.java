package com.medichain.controller;

import com.medichain.dao.DoctorDAO;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/doctors")
@CrossOrigin(origins = "*")
public class DoctorController {

    private final DoctorDAO doctorDAO;

    public DoctorController(DoctorDAO doctorDAO) {
        this.doctorDAO = doctorDAO;
    }

    @GetMapping
    public ResponseEntity<?> getAll() {
        return ResponseEntity.ok(doctorDAO.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getOne(@PathVariable Long id) {
        Map<String, Object> doctor = doctorDAO.findById(id);
        if (doctor == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(doctor);
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody Map<String, Object> body) {
        try {
            doctorDAO.create(body);
            return ResponseEntity.ok(Map.of("message", "Doctor registered successfully"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        try {
            int rows = doctorDAO.update(id, body);
            if (rows == 0) return ResponseEntity.notFound().build();
            return ResponseEntity.ok(Map.of("message", "Doctor updated successfully"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/{id}/hospitals")
    public ResponseEntity<?> getHospitals(@PathVariable Long id) {
        return ResponseEntity.ok(doctorDAO.getHospitals(id));
    }

    @PostMapping("/{id}/hospitals")
    public ResponseEntity<?> assignHospital(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        try {
            doctorDAO.assignToHospital(id, Long.valueOf(body.get("hospital_id").toString()),
                    (String) body.get("join_date"));
            return ResponseEntity.ok(Map.of("message", "Doctor assigned to hospital"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
