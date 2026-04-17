package com.medichain.controller;

import com.medichain.dao.LabDAO;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/lab")
@CrossOrigin(origins = "*")
public class LabController {

    private final LabDAO labDAO;

    public LabController(LabDAO labDAO) {
        this.labDAO = labDAO;
    }

    @GetMapping("/orders")
    public ResponseEntity<?> getAllOrders() {
        return ResponseEntity.ok(labDAO.findAllOrders());
    }

    @GetMapping("/orders/{id}")
    public ResponseEntity<?> getOrder(@PathVariable Long id) {
        Map<String, Object> order = labDAO.findOrderById(id);
        if (order == null) return ResponseEntity.notFound().build();

        Map<String, Object> result = new HashMap<>(order);
        result.put("results", labDAO.getResults(id));
        return ResponseEntity.ok(result);
    }

    @PostMapping("/orders")
    public ResponseEntity<?> createOrder(@RequestBody Map<String, Object> body) {
        try {
            Long id = labDAO.createOrder(body);
            return ResponseEntity.ok(Map.of("message", "Lab order created", "lab_order_id", id));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PutMapping("/orders/{id}/status")
    public ResponseEntity<?> updateOrderStatus(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        try {
            labDAO.updateOrderStatus(id, (String) body.get("status"));
            return ResponseEntity.ok(Map.of("message", "Order status updated"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PutMapping("/orders/{id}/collect")
    public ResponseEntity<?> collectSpecimen(@PathVariable Long id) {
        try {
            labDAO.collectSpecimen(id);
            return ResponseEntity.ok(Map.of("message", "Specimen collected"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/results")
    public ResponseEntity<?> addResult(@RequestBody Map<String, Object> body) {
        try {
            Long id = labDAO.addResult(body);
            return ResponseEntity.ok(Map.of("message", "Lab result recorded", "result_id", id));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PutMapping("/results/{id}/acknowledge")
    public ResponseEntity<?> acknowledgeResult(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        try {
            labDAO.acknowledgeResult(id, Long.valueOf(body.get("doctor_id").toString()));
            return ResponseEntity.ok(Map.of("message", "Result acknowledged"));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/critical")
    public ResponseEntity<?> getCritical() {
        return ResponseEntity.ok(labDAO.getCriticalUnacknowledged());
    }

    @GetMapping("/catalog")
    public ResponseEntity<?> getCatalog() {
        return ResponseEntity.ok(labDAO.getTestCatalog());
    }
}
