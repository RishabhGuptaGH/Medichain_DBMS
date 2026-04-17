-- ============================================================
-- MediChain - 25 SQL Queries (Varying Complexity)
-- ============================================================

USE medichain;

-- ============================================================
--                    SIMPLE QUERIES (1–5)
-- ============================================================

-- ————————————————————————————————————————————————————————————
-- Q1: List all patients with their full name, gender, and blood group.
-- Complexity: Simple SELECT with CONCAT
-- ————————————————————————————————————————————————————————————
SELECT health_id,
       CONCAT(fname, ' ', IFNULL(mname, ''), ' ', lname) AS full_name,
       gender,
       blood_group
FROM PATIENT;


-- ————————————————————————————————————————————————————————————
-- Q2: Find all medications that belong to the 'NSAID' drug class.
-- Complexity: Simple WHERE with LIKE
-- ————————————————————————————————————————————————————————————
SELECT medication_id, generic_name, brand_name, drug_class
FROM MEDICATION
WHERE drug_class LIKE '%NSAID%';


-- ————————————————————————————————————————————————————————————
-- Q3: List all emergency encounters ordered by date (most recent first).
-- Complexity: Simple WHERE + ORDER BY
-- ————————————————————————————————————————————————————————————
SELECT encounter_id, health_id, hospital_id, encounter_date_time, chief_complaint
FROM ENCOUNTER
WHERE encounter_type = 'Emergency'
ORDER BY encounter_date_time DESC;


-- ————————————————————————————————————————————————————————————
-- Q4: Count the number of patients in each blood group.
-- Complexity: Simple GROUP BY with aggregate
-- ————————————————————————————————————————————————————————————
SELECT blood_group, COUNT(*) AS patient_count
FROM PATIENT
GROUP BY blood_group
ORDER BY patient_count DESC;


-- ————————————————————————————————————————————————————————————
-- Q5: Find all 'Severe' or 'Life-threatening' drug interactions.
-- Complexity: Simple WHERE with IN
-- ————————————————————————————————————————————————————————————
SELECT di.medication_id_1, m1.generic_name AS drug_1,
       di.medication_id_2, m2.generic_name AS drug_2,
       di.severity, di.interaction_description
FROM DRUG_INTERACTION di
JOIN MEDICATION m1 ON di.medication_id_1 = m1.medication_id
JOIN MEDICATION m2 ON di.medication_id_2 = m2.medication_id
WHERE di.severity IN ('Severe', 'Life-threatening');


-- ============================================================
--                  MODERATE QUERIES (6–12)
-- ============================================================

-- ————————————————————————————————————————————————————————————
-- Q6: List each patient along with their active allergies.
-- Complexity: LEFT JOIN
-- ————————————————————————————————————————————————————————————
SELECT p.health_id,
       CONCAT(p.fname, ' ', p.lname) AS patient_name,
       IFNULL(pa.allergen, 'No known allergies') AS allergen,
       pa.severity
FROM PATIENT p
LEFT JOIN PATIENT_ALLERGY pa ON p.health_id = pa.health_id AND pa.status = 'Active'
ORDER BY p.health_id;


-- ————————————————————————————————————————————————————————————
-- Q7: Find hospitals that have more than 3 departments.
-- Complexity: JOIN + GROUP BY + HAVING
-- ————————————————————————————————————————————————————————————
SELECT h.hospital_id, h.hospital_name, COUNT(d.department_id) AS dept_count
FROM HOSPITAL h
JOIN DEPARTMENT d ON h.hospital_id = d.hospital_id
GROUP BY h.hospital_id, h.hospital_name
HAVING COUNT(d.department_id) > 3;


-- ————————————————————————————————————————————————————————————
-- Q8: List doctors who are affiliated with more than one hospital.
-- Complexity: JOIN + GROUP BY + HAVING
-- ————————————————————————————————————————————————————————————
SELECT d.doctor_id, d.name, COUNT(dh.hospital_id) AS hospital_count
FROM DOCTOR d
JOIN DOCTOR_HOSPITAL dh ON d.doctor_id = dh.doctor_id
WHERE dh.status = 'Active'
GROUP BY d.doctor_id, d.name
HAVING COUNT(dh.hospital_id) > 1;


-- ————————————————————————————————————————————————————————————
-- Q9: Find the total number of encounters per hospital with hospital name.
-- Complexity: JOIN + GROUP BY + ORDER BY
-- ————————————————————————————————————————————————————————————
SELECT h.hospital_name, COUNT(e.encounter_id) AS total_encounters
FROM HOSPITAL h
LEFT JOIN ENCOUNTER e ON h.hospital_id = e.hospital_id
GROUP BY h.hospital_id, h.hospital_name
ORDER BY total_encounters DESC;


-- ————————————————————————————————————————————————————————————
-- Q10: Find patients whose insurance has expired or will expire within 30 days.
-- Complexity: WHERE with date arithmetic
-- ————————————————————————————————————————————————————————————
SELECT health_id,
       CONCAT(fname, ' ', lname) AS patient_name,
       insurance_provider,
       insurance_end,
       CASE
           WHEN insurance_end < CURDATE() THEN 'Expired'
           ELSE 'Expiring Soon'
       END AS insurance_status
FROM PATIENT
WHERE insurance_end IS NOT NULL
  AND insurance_end <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)
ORDER BY insurance_end;


-- ————————————————————————————————————————————————————————————
-- Q11: Find all abnormal lab results with patient and test details.
-- Complexity: Multi-table JOIN (4 tables)
-- ————————————————————————————————————————————————————————————
SELECT CONCAT(p.fname, ' ', p.lname) AS patient_name,
       ltc.test_name,
       lr.result_value, lr.result_unit, lr.reference_range,
       lr.critical_flag,
       lr.result_date
FROM LAB_RESULT lr
JOIN LAB_ORDER lo ON lr.lab_order_id = lo.lab_order_id
JOIN LAB_TEST_CATALOG ltc ON lo.test_code = ltc.test_code
JOIN ENCOUNTER e ON lo.encounter_id = e.encounter_id
JOIN PATIENT p ON e.health_id = p.health_id
WHERE lr.abnormal_flag = TRUE
ORDER BY lr.critical_flag DESC, lr.result_date DESC;


-- ————————————————————————————————————————————————————————————
-- Q12: List all active prescriptions with medication names and doctor.
-- Complexity: Multi-table JOIN (3 tables)
-- ————————————————————————————————————————————————————————————
SELECT p.prescription_id,
       d.name AS doctor_name,
       m.generic_name, m.brand_name,
       pi.dosage_strength, pi.frequency,
       p.start_date, p.end_date
FROM PRESCRIPTION p
JOIN PRESCRIPTION_ITEM pi ON p.prescription_id = pi.prescription_id
JOIN MEDICATION m ON pi.medication_id = m.medication_id
JOIN DOCTOR d ON p.doctor_id = d.doctor_id
WHERE p.status = 'Active'
ORDER BY p.prescription_id;


-- ============================================================
--                  COMPLEX QUERIES (13–19)
-- ============================================================

-- ————————————————————————————————————————————————————————————
-- Q13: Find patients who have had encounters at multiple hospitals.
-- Complexity: Subquery in HAVING
-- ————————————————————————————————————————————————————————————
SELECT p.health_id,
       CONCAT(p.fname, ' ', p.lname) AS patient_name,
       COUNT(DISTINCT e.hospital_id) AS hospitals_visited
FROM PATIENT p
JOIN ENCOUNTER e ON p.health_id = e.health_id
GROUP BY p.health_id, p.fname, p.lname
HAVING COUNT(DISTINCT e.hospital_id) > 1;


-- ————————————————————————————————————————————————————————————
-- Q14: For each doctor, show their total encounters and the distinct
--      number of patients they have treated.
-- Complexity: Multi-table JOIN + multiple aggregates
-- ————————————————————————————————————————————————————————————
SELECT d.doctor_id,
       d.name AS doctor_name,
       d.specialization,
       COUNT(DISTINCT ed.encounter_id) AS total_encounters,
       COUNT(DISTINCT e.health_id) AS unique_patients
FROM DOCTOR d
JOIN ENCOUNTER_DOCTOR ed ON d.doctor_id = ed.doctor_id
JOIN ENCOUNTER e ON ed.encounter_id = e.encounter_id
GROUP BY d.doctor_id, d.name, d.specialization
ORDER BY total_encounters DESC;


-- ————————————————————————————————————————————————————————————
-- Q15: Find patients who have NEVER had an encounter (registered but no visits).
-- Complexity: LEFT JOIN with NULL check (anti-join)
-- ————————————————————————————————————————————————————————————
SELECT p.health_id,
       CONCAT(p.fname, ' ', p.lname) AS patient_name,
       p.address_city
FROM PATIENT p
LEFT JOIN ENCOUNTER e ON p.health_id = e.health_id
WHERE e.encounter_id IS NULL;


-- ————————————————————————————————————————————————————————————
-- Q16: Find the most commonly prescribed medication.
-- Complexity: JOIN + GROUP BY + ORDER BY + LIMIT
-- ————————————————————————————————————————————————————————————
SELECT m.generic_name, m.brand_name, m.drug_class,
       COUNT(*) AS times_prescribed
FROM PRESCRIPTION_ITEM pi
JOIN MEDICATION m ON pi.medication_id = m.medication_id
GROUP BY m.medication_id, m.generic_name, m.brand_name, m.drug_class
ORDER BY times_prescribed DESC
LIMIT 1;


-- ————————————————————————————————————————————————————————————
-- Q17: For each hospital, show the breakdown of encounter types as counts.
-- Complexity: Conditional aggregation with CASE (pivot)
-- ————————————————————————————————————————————————————————————
SELECT h.hospital_name,
       SUM(CASE WHEN e.encounter_type = 'Outpatient'  THEN 1 ELSE 0 END) AS outpatient,
       SUM(CASE WHEN e.encounter_type = 'Inpatient'   THEN 1 ELSE 0 END) AS inpatient,
       SUM(CASE WHEN e.encounter_type = 'Emergency'   THEN 1 ELSE 0 END) AS emergency,
       SUM(CASE WHEN e.encounter_type = 'Follow-up'   THEN 1 ELSE 0 END) AS follow_up,
       COUNT(e.encounter_id) AS total
FROM HOSPITAL h
LEFT JOIN ENCOUNTER e ON h.hospital_id = e.hospital_id
GROUP BY h.hospital_id, h.hospital_name
ORDER BY total DESC;


-- ————————————————————————————————————————————————————————————
-- Q18: List all patients along with the number of active prescriptions
--      and pending lab orders they currently have.
-- Complexity: Multiple LEFT JOINs with independent subqueries
-- ————————————————————————————————————————————————————————————
SELECT p.health_id,
       CONCAT(p.fname, ' ', p.lname) AS patient_name,
       IFNULL(rx.active_prescriptions, 0) AS active_prescriptions,
       IFNULL(lb.pending_labs, 0) AS pending_labs
FROM PATIENT p
LEFT JOIN (
    SELECT e.health_id, COUNT(DISTINCT pr.prescription_id) AS active_prescriptions
    FROM ENCOUNTER e
    JOIN PRESCRIPTION pr ON e.encounter_id = pr.encounter_id
    WHERE pr.status = 'Active'
    GROUP BY e.health_id
) rx ON p.health_id = rx.health_id
LEFT JOIN (
    SELECT e.health_id, COUNT(*) AS pending_labs
    FROM ENCOUNTER e
    JOIN LAB_ORDER lo ON e.encounter_id = lo.encounter_id
    WHERE lo.order_status = 'Pending'
    GROUP BY e.health_id
) lb ON p.health_id = lb.health_id
ORDER BY active_prescriptions DESC, pending_labs DESC;


-- ————————————————————————————————————————————————————————————
-- Q19: Find all patients currently prescribed medications that have
--      known drug interactions with each other.
-- Complexity: Self-join on PRESCRIPTION_ITEM + JOIN to DRUG_INTERACTION
-- ————————————————————————————————————————————————————————————
SELECT DISTINCT
       CONCAT(pat.fname, ' ', pat.lname) AS patient_name,
       m1.generic_name AS drug_1,
       m2.generic_name AS drug_2,
       di.severity,
       di.interaction_description
FROM PRESCRIPTION_ITEM pi1
JOIN PRESCRIPTION_ITEM pi2 ON pi1.prescription_id <> pi2.prescription_id
JOIN PRESCRIPTION pr1 ON pi1.prescription_id = pr1.prescription_id
JOIN PRESCRIPTION pr2 ON pi2.prescription_id = pr2.prescription_id
JOIN ENCOUNTER e1 ON pr1.encounter_id = e1.encounter_id
JOIN ENCOUNTER e2 ON pr2.encounter_id = e2.encounter_id
JOIN DRUG_INTERACTION di ON di.medication_id_1 = LEAST(pi1.medication_id, pi2.medication_id)
                        AND di.medication_id_2 = GREATEST(pi1.medication_id, pi2.medication_id)
JOIN MEDICATION m1 ON pi1.medication_id = m1.medication_id
JOIN MEDICATION m2 ON pi2.medication_id = m2.medication_id
JOIN PATIENT pat ON e1.health_id = pat.health_id
WHERE pr1.status = 'Active'
  AND pr2.status = 'Active'
  AND e1.health_id = e2.health_id;


-- ============================================================
--                  ADVANCED QUERIES (20–25)
-- ============================================================

-- ————————————————————————————————————————————————————————————
-- Q20: Rank doctors by the number of encounters they have handled,
--      with a dense rank.
-- Complexity: Window function - DENSE_RANK
-- ————————————————————————————————————————————————————————————
SELECT d.doctor_id,
       d.name AS doctor_name,
       d.specialization,
       COUNT(ed.encounter_id) AS encounter_count,
       DENSE_RANK() OVER (ORDER BY COUNT(ed.encounter_id) DESC) AS doctor_rank
FROM DOCTOR d
LEFT JOIN ENCOUNTER_DOCTOR ed ON d.doctor_id = ed.doctor_id
GROUP BY d.doctor_id, d.name, d.specialization;


-- ————————————————————————————————————————————————————————————
-- Q21: Show each patient's encounters with a running total of encounters
--      over time (cumulative count).
-- Complexity: Window function - ROW_NUMBER with partitioning
-- ————————————————————————————————————————————————————————————
SELECT p.health_id,
       CONCAT(p.fname, ' ', p.lname) AS patient_name,
       e.encounter_id,
       e.encounter_type,
       e.encounter_date_time,
       ROW_NUMBER() OVER (
           PARTITION BY p.health_id
           ORDER BY e.encounter_date_time
       ) AS visit_number
FROM PATIENT p
JOIN ENCOUNTER e ON p.health_id = e.health_id
ORDER BY p.health_id, e.encounter_date_time;


-- ————————————————————————————————————————————————————————————
-- Q22: CTE - Build a patient health summary showing their latest vital
--      signs, total encounters, and diagnosis count.
-- Complexity: CTE with multiple derived tables + JOINs
-- ————————————————————————————————————————————————————————————
WITH LatestVitals AS (
    SELECT v.encounter_id, v.bp_systolic, v.bp_diastolic, v.pulse,
           v.temperature, v.oxygen_saturation, v.weight,
           e.health_id,
           ROW_NUMBER() OVER (PARTITION BY e.health_id ORDER BY v.reading_timestamp DESC) AS rn
    FROM VITAL_SIGNS v
    JOIN ENCOUNTER e ON v.encounter_id = e.encounter_id
),
PatientStats AS (
    SELECT e.health_id,
           COUNT(DISTINCT e.encounter_id) AS total_encounters,
           COUNT(DISTINCT ed.icd10_code) AS unique_diagnoses
    FROM ENCOUNTER e
    LEFT JOIN ENCOUNTER_DIAGNOSIS ed ON e.encounter_id = ed.encounter_id
    GROUP BY e.health_id
)
SELECT p.health_id,
       CONCAT(p.fname, ' ', p.lname) AS patient_name,
       ps.total_encounters,
       ps.unique_diagnoses,
       lv.bp_systolic, lv.bp_diastolic, lv.pulse,
       lv.temperature, lv.oxygen_saturation
FROM PATIENT p
LEFT JOIN PatientStats ps ON p.health_id = ps.health_id
LEFT JOIN LatestVitals lv ON p.health_id = lv.health_id AND lv.rn = 1
ORDER BY ps.total_encounters DESC;


-- ————————————————————————————————————————————————————————————
-- Q23: Find hospitals where average patient oxygen saturation during
--      encounters was below 95% (identifying critical-care heavy facilities).
-- Complexity: Subquery + HAVING with AVG on nested JOIN
-- ————————————————————————————————————————————————————————————
SELECT h.hospital_name, h.facility_type,
       ROUND(AVG(v.oxygen_saturation), 1) AS avg_o2_sat,
       MIN(v.oxygen_saturation) AS min_o2_sat,
       COUNT(DISTINCT e.encounter_id) AS encounters_measured
FROM HOSPITAL h
JOIN ENCOUNTER e ON h.hospital_id = e.hospital_id
JOIN VITAL_SIGNS v ON e.encounter_id = v.encounter_id
WHERE v.oxygen_saturation IS NOT NULL
GROUP BY h.hospital_id, h.hospital_name, h.facility_type
HAVING AVG(v.oxygen_saturation) < 95
ORDER BY avg_o2_sat;


-- ————————————————————————————————————————————————————————————
-- Q24: Correlated subquery - For each doctor, find the patient they have
--      treated the most number of times.
-- Complexity: Correlated subquery + GROUP BY in subquery
-- ————————————————————————————————————————————————————————————
SELECT d.doctor_id,
       d.name AS doctor_name,
       top_patient.health_id,
       CONCAT(p.fname, ' ', p.lname) AS most_seen_patient,
       top_patient.visit_count
FROM DOCTOR d
JOIN (
    SELECT ed.doctor_id,
           e.health_id,
           COUNT(*) AS visit_count,
           ROW_NUMBER() OVER (PARTITION BY ed.doctor_id ORDER BY COUNT(*) DESC) AS rn
    FROM ENCOUNTER_DOCTOR ed
    JOIN ENCOUNTER e ON ed.encounter_id = e.encounter_id
    GROUP BY ed.doctor_id, e.health_id
) top_patient ON d.doctor_id = top_patient.doctor_id AND top_patient.rn = 1
JOIN PATIENT p ON top_patient.health_id = p.health_id
ORDER BY top_patient.visit_count DESC;


-- ————————————————————————————————————————————————————————————
-- Q25: Comprehensive audit trail report - Show all audit log entries
--      with decoded action types, linked user info, and hash chain
--      integrity verification.
-- Complexity: CTE + LEFT JOIN + LAG window function + CASE
-- ————————————————————————————————————————————————————————————
WITH AuditChain AS (
    SELECT al.log_id,
           al.action_type,
           al.table_name,
           al.record_id,
           al.event_time,
           al.notes,
           al.hash_value,
           al.prev_hash,
           LAG(al.hash_value) OVER (ORDER BY al.log_id) AS expected_prev_hash
    FROM AUDIT_LOG al
)
SELECT ac.log_id,
       CASE
           WHEN au.role = 'doctor'  THEN CONCAT('Dr. (', au.username, ')')
           WHEN au.role = 'admin'   THEN CONCAT('Admin (', au.username, ')')
           WHEN au.role = 'patient' THEN CONCAT('Patient (', au.username, ')')
           ELSE 'SYSTEM'
       END AS performed_by,
       ac.action_type,
       ac.table_name,
       ac.record_id,
       ac.event_time,
       LEFT(ac.notes, 80) AS notes_preview,
       CASE
           WHEN ac.log_id = (SELECT MIN(log_id) FROM AUDIT_LOG) THEN 'GENESIS'
           WHEN ac.prev_hash = ac.expected_prev_hash THEN 'VALID'
           WHEN ac.prev_hash IS NULL AND ac.expected_prev_hash IS NULL THEN 'VALID'
           ELSE 'BROKEN CHAIN'
       END AS chain_integrity
FROM AuditChain ac
LEFT JOIN AUDIT_LOG al ON ac.log_id = al.log_id
LEFT JOIN APP_USER au ON al.user_id = au.user_id
ORDER BY ac.log_id;
