package com.medichain.dao;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.util.*;

@Repository
public class LabDAO {

    private final JdbcTemplate jdbc;

    public LabDAO(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String, Object>> findAllOrders() {
        return jdbc.queryForList(
            "SELECT lo.*, ltc.test_name, d.name AS doctor_name, " +
            "p.fname, p.lname, p.health_id " +
            "FROM LAB_ORDER lo " +
            "JOIN LAB_TEST_CATALOG ltc ON lo.test_code = ltc.test_code " +
            "JOIN DOCTOR d ON lo.doctor_id = d.doctor_id " +
            "JOIN ENCOUNTER e ON lo.encounter_id = e.encounter_id " +
            "JOIN PATIENT p ON e.health_id = p.health_id " +
            "ORDER BY lo.order_date_time DESC"
        );
    }

    public Map<String, Object> findOrderById(Long id) {
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT lo.*, ltc.test_name, ltc.specimen_type, d.name AS doctor_name, " +
            "p.fname, p.lname, p.health_id " +
            "FROM LAB_ORDER lo " +
            "JOIN LAB_TEST_CATALOG ltc ON lo.test_code = ltc.test_code " +
            "JOIN DOCTOR d ON lo.doctor_id = d.doctor_id " +
            "JOIN ENCOUNTER e ON lo.encounter_id = e.encounter_id " +
            "JOIN PATIENT p ON e.health_id = p.health_id " +
            "WHERE lo.lab_order_id = ?", id
        );
        return rows.isEmpty() ? null : rows.get(0);
    }

    public Long createOrder(Map<String, Object> order) {
        jdbc.update(
            "INSERT INTO LAB_ORDER (encounter_id, doctor_id, test_code, priority, clinical_info, " +
            "specimen_id, order_date_time) " +
            "VALUES (?, ?, ?, ?, ?, CONCAT('SPEC-', DATE_FORMAT(NOW(),'%Y%m%d%H%i%s'), '-', FLOOR(RAND()*10000)), NOW())",
            order.get("encounter_id"), order.get("doctor_id"), order.get("test_code"),
            order.getOrDefault("priority", "Routine"), order.get("clinical_info")
        );
        return jdbc.queryForObject("SELECT LAST_INSERT_ID()", Long.class);
    }

    public int updateOrderStatus(Long id, String status) {
        return jdbc.update(
            "UPDATE LAB_ORDER SET order_status = ? WHERE lab_order_id = ?", status, id
        );
    }

    public void collectSpecimen(Long orderId) {
        jdbc.update(
            "UPDATE LAB_ORDER SET order_status = 'In Progress', specimen_collected_at = NOW() " +
            "WHERE lab_order_id = ?", orderId
        );
    }

    // Results
    public Long addResult(Map<String, Object> result) {
        jdbc.update(
            "INSERT INTO LAB_RESULT (lab_order_id, result_value, result_unit, reference_range, " +
            "abnormal_flag, critical_flag, result_date, verified_by_doctor_id) " +
            "VALUES (?, ?, ?, ?, ?, ?, NOW(), ?)",
            result.get("lab_order_id"), result.get("result_value"), result.get("result_unit"),
            result.get("reference_range"),
            result.getOrDefault("abnormal_flag", false),
            result.getOrDefault("critical_flag", false),
            result.get("verified_by_doctor_id")
        );

        Long resultId = jdbc.queryForObject("SELECT LAST_INSERT_ID()", Long.class);

        // Update order status to Completed
        jdbc.update(
            "UPDATE LAB_ORDER SET order_status = 'Completed' WHERE lab_order_id = ?",
            result.get("lab_order_id")
        );

        return resultId;
    }

    public List<Map<String, Object>> getResults(Long orderId) {
        return jdbc.queryForList(
            "SELECT lr.*, d.name AS verified_by " +
            "FROM LAB_RESULT lr " +
            "LEFT JOIN DOCTOR d ON lr.verified_by_doctor_id = d.doctor_id " +
            "WHERE lr.lab_order_id = ?", orderId
        );
    }

    public int acknowledgeResult(Long resultId, Long doctorId) {
        return jdbc.update(
            "UPDATE LAB_RESULT SET physician_acknowledged = TRUE, acknowledged_at = NOW() " +
            "WHERE result_id = ?", resultId
        );
    }

    public List<Map<String, Object>> getTestCatalog() {
        return jdbc.queryForList("SELECT * FROM LAB_TEST_CATALOG ORDER BY test_name");
    }

    // Get critical unacknowledged results
    public List<Map<String, Object>> getCriticalUnacknowledged() {
        return jdbc.queryForList(
            "SELECT lr.*, lo.test_code, ltc.test_name, lo.doctor_id, d.name AS doctor_name, " +
            "p.fname, p.lname, p.health_id " +
            "FROM LAB_RESULT lr " +
            "JOIN LAB_ORDER lo ON lr.lab_order_id = lo.lab_order_id " +
            "JOIN LAB_TEST_CATALOG ltc ON lo.test_code = ltc.test_code " +
            "JOIN DOCTOR d ON lo.doctor_id = d.doctor_id " +
            "JOIN ENCOUNTER e ON lo.encounter_id = e.encounter_id " +
            "JOIN PATIENT p ON e.health_id = p.health_id " +
            "WHERE lr.critical_flag = TRUE AND lr.physician_acknowledged = FALSE " +
            "ORDER BY lr.result_date ASC"
        );
    }
}
