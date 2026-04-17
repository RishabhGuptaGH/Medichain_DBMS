-- ============================================================
-- MediChain - Sample Seed Data
-- ============================================================

USE medichain;

-- ============================================================
-- DIAGNOSIS CODES (ICD-10)
-- ============================================================
INSERT INTO DIAGNOSIS_CODE (icd10_code, description, category) VALUES
('J06.9', 'Acute upper respiratory infection, unspecified', 'Respiratory'),
('I10',   'Essential (primary) hypertension', 'Cardiovascular'),
('E11.9', 'Type 2 diabetes mellitus without complications', 'Endocrine'),
('J18.9', 'Pneumonia, unspecified organism', 'Respiratory'),
('K21.0', 'Gastro-esophageal reflux disease with esophagitis', 'Digestive'),
('M54.5', 'Low back pain', 'Musculoskeletal'),
('J45.20','Mild intermittent asthma, uncomplicated', 'Respiratory'),
('N39.0', 'Urinary tract infection, site not specified', 'Genitourinary'),
('R50.9', 'Fever, unspecified', 'General'),
('G43.909','Migraine, unspecified, not intractable', 'Neurological');

-- ============================================================
-- PROCEDURE CODES (CPT)
-- ============================================================
INSERT INTO PROCEDURE_CODE (cpt_code, description, category, base_cost) VALUES
('99213', 'Office visit, established patient, low complexity', 'E&M', 150.00),
('99214', 'Office visit, established patient, moderate complexity', 'E&M', 250.00),
('99215', 'Office visit, established patient, high complexity', 'E&M', 350.00),
('99281', 'Emergency department visit, minor', 'Emergency', 200.00),
('99285', 'Emergency department visit, high severity', 'Emergency', 800.00),
('36415', 'Collection of venous blood by venipuncture', 'Lab', 25.00),
('71046', 'Chest X-ray, 2 views', 'Radiology', 120.00),
('93000', 'Electrocardiogram, routine, 12 leads', 'Cardiology', 75.00),
('80053', 'Comprehensive metabolic panel', 'Lab', 45.00),
('85025', 'Complete blood count with differential', 'Lab', 30.00);

-- ============================================================
-- MEDICATIONS
-- ============================================================
INSERT INTO MEDICATION (medication_id, generic_name, brand_name, drug_class, manufacturer) VALUES
(1, 'Amoxicillin', 'Amoxil', 'Penicillin Antibiotic', 'GSK'),
(2, 'Metformin', 'Glucophage', 'Biguanide', 'Bristol-Myers Squibb'),
(3, 'Lisinopril', 'Zestril', 'ACE Inhibitor', 'AstraZeneca'),
(4, 'Atorvastatin', 'Lipitor', 'Statin', 'Pfizer'),
(5, 'Omeprazole', 'Prilosec', 'Proton Pump Inhibitor', 'AstraZeneca'),
(6, 'Amlodipine', 'Norvasc', 'Calcium Channel Blocker', 'Pfizer'),
(7, 'Ibuprofen', 'Advil', 'NSAID', 'Pfizer'),
(8, 'Paracetamol', 'Tylenol', 'Analgesic', 'Johnson & Johnson'),
(9, 'Ciprofloxacin', 'Cipro', 'Fluoroquinolone Antibiotic', 'Bayer'),
(10, 'Salbutamol', 'Ventolin', 'Beta-2 Agonist', 'GSK'),
(11, 'Warfarin', 'Coumadin', 'Anticoagulant', 'Bristol-Myers Squibb'),
(12, 'Aspirin', 'Bayer Aspirin', 'NSAID/Antiplatelet', 'Bayer');

-- ============================================================
-- DRUG INTERACTIONS
-- ============================================================
INSERT INTO DRUG_INTERACTION (medication_id_1, medication_id_2, severity, interaction_description, recommendation) VALUES
(3, 7, 'Moderate', 'NSAIDs may reduce the antihypertensive effect of ACE inhibitors and increase risk of renal impairment', 'Monitor blood pressure and renal function closely'),
(4, 5, 'Mild', 'Omeprazole may slightly increase atorvastatin levels', 'Generally safe, monitor for statin side effects'),
(7, 11, 'Severe', 'Ibuprofen significantly increases bleeding risk with warfarin', 'Avoid combination if possible; use paracetamol instead'),
(7, 12, 'Severe', 'Concurrent use of ibuprofen and aspirin increases GI bleeding risk', 'Avoid combination; use paracetamol for pain'),
(11, 12, 'Life-threatening', 'Aspirin combined with warfarin dramatically increases hemorrhage risk', 'CONTRAINDICATED unless specifically indicated with close INR monitoring'),
(3, 6, 'Mild', 'Additive hypotensive effect with ACE inhibitor and calcium channel blocker', 'Common therapeutic combination, monitor BP');

-- ============================================================
-- LAB TEST CATALOG
-- ============================================================
INSERT INTO LAB_TEST_CATALOG (test_code, test_name, specimen_type, collection_procedure) VALUES
('CBC', 'Complete Blood Count', 'Whole Blood (EDTA)', 'Collect in purple-top EDTA tube'),
('BMP', 'Basic Metabolic Panel', 'Serum', 'Collect in red or gold-top tube, fasting preferred'),
('CMP', 'Comprehensive Metabolic Panel', 'Serum', 'Collect in red or gold-top tube, fasting preferred'),
('LFT', 'Liver Function Tests', 'Serum', 'Collect in red or gold-top tube'),
('TSH', 'Thyroid Stimulating Hormone', 'Serum', 'No special preparation needed'),
('HBA1C', 'Hemoglobin A1c', 'Whole Blood (EDTA)', 'No fasting required'),
('LIPID', 'Lipid Panel', 'Serum', '12-hour fasting required'),
('UA', 'Urinalysis', 'Urine', 'Clean-catch midstream urine sample'),
('BG', 'Blood Glucose (Fasting)', 'Plasma', 'Minimum 8-hour fast required'),
('PT_INR', 'Prothrombin Time / INR', 'Citrated Plasma', 'Collect in blue-top citrate tube');

-- ============================================================
-- HOSPITALS
-- ============================================================
INSERT INTO HOSPITAL (hospital_id, hospital_name, license_number, phone, email, bed_capacity, address_street, address_city, address_state, postal_code, facility_type) VALUES
(1, 'Apollo General Hospital',   'LIC-APL-001', '011-26825000', 'info@apollo.com',   500, 'Sarita Vihar', 'New Delhi', 'Delhi', '110076', 'General Hospital'),
(2, 'AIIMS Delhi',               'LIC-AIIMS-001', '011-26588500', 'info@aiims.edu',   2500, 'Ansari Nagar', 'New Delhi', 'Delhi', '110029', 'Teaching Hospital'),
(3, 'Fortis Heart Institute',    'LIC-FRT-001', '011-47134000', 'info@fortis.com',    300, 'Okhla Road', 'New Delhi', 'Delhi', '110025', 'Specialty Hospital'),
(4, 'Max Super Speciality',      'LIC-MAX-001', '011-26515050', 'info@maxhealthcare.com', 400, 'Saket', 'New Delhi', 'Delhi', '110017', 'General Hospital'),
(5, 'Safdarjung Hospital',       'LIC-SFJ-001', '011-26707437', 'info@safdarjung.nic.in', 1800, 'Ring Road', 'New Delhi', 'Delhi', '110029', 'Trauma Center');

-- ============================================================
-- DEPARTMENTS
-- ============================================================
INSERT INTO DEPARTMENT (hospital_id, department_name) VALUES
(1, 'Emergency Medicine'), (1, 'Cardiology'), (1, 'Orthopedics'), (1, 'Pediatrics'), (1, 'Pharmacy'),
(2, 'Emergency Medicine'), (2, 'Cardiology'), (2, 'Neurology'), (2, 'Oncology'), (2, 'Surgery'),
(3, 'Cardiology'), (3, 'Cardiac Surgery'),
(4, 'Emergency Medicine'), (4, 'Internal Medicine'), (4, 'Radiology'), (4, 'Pathology'),
(5, 'Emergency Medicine'), (5, 'Surgery'), (5, 'Orthopedics');

-- ============================================================
-- DOCTORS
-- ============================================================
INSERT INTO DOCTOR (doctor_id, medical_license_number, name, phone_number, email, date_of_birth, specialization) VALUES
(1, 'MCI-2010-4521', 'Dr. Anil Sharma',     '9876543210', 'anil.sharma@apollo.com',   '1975-03-15', 'Internal Medicine'),
(2, 'MCI-2008-3312', 'Dr. Priya Patel',      '9876543211', 'priya.patel@aiims.edu',    '1980-07-22', 'Cardiology'),
(3, 'MCI-2012-5678', 'Dr. Rajesh Kumar',     '9876543212', 'rajesh.kumar@fortis.com',  '1978-11-05', 'Orthopedics'),
(4, 'MCI-2015-9012', 'Dr. Sneha Gupta',      '9876543213', 'sneha.gupta@max.com',      '1985-01-30', 'Pediatrics'),
(5, 'MCI-2005-1234', 'Dr. Vikram Singh',     '9876543214', 'vikram.singh@aiims.edu',   '1970-09-18', 'Neurology'),
(6, 'MCI-2011-7890', 'Dr. Meera Reddy',      '9876543215', 'meera.reddy@apollo.com',   '1982-04-12', 'Emergency Medicine'),
(7, 'MCI-2009-2345', 'Dr. Arjun Nair',       '9876543216', 'arjun.nair@safdarjung.com','1977-06-25', 'Surgery'),
(8, 'MCI-2014-6789', 'Dr. Kavitha Iyer',     '9876543217', 'kavitha.iyer@max.com',     '1983-12-08', 'Oncology');

-- ============================================================
-- DOCTOR-HOSPITAL ASSOCIATIONS
-- ============================================================
INSERT INTO DOCTOR_HOSPITAL (doctor_id, hospital_id, join_date, status) VALUES
(1, 1, '2015-01-10', 'Active'),
(2, 2, '2012-06-01', 'Active'),
(2, 3, '2018-03-15', 'Active'),
(3, 3, '2016-09-20', 'Active'),
(3, 5, '2020-01-01', 'Active'),
(4, 4, '2019-04-15', 'Active'),
(5, 2, '2010-08-01', 'Active'),
(6, 1, '2017-02-28', 'Active'),
(6, 5, '2021-06-01', 'Active'),
(7, 5, '2014-11-10', 'Active'),
(8, 4, '2020-07-01', 'Active'),
(8, 2, '2022-01-15', 'Active');

-- ============================================================
-- PATIENTS
-- ============================================================
INSERT INTO PATIENT (health_id, fname, mname, lname, address_street, address_city, address_state, postal_code, date_of_birth, gender, blood_group, emergency_contact_name, emergency_contact_phone, insurance_provider, insurance_start, insurance_end, policy_type) VALUES
('HID-001', 'Rahul',   NULL,    'Verma',   '12 MG Road',        'New Delhi', 'Delhi',       '110001', '1990-05-15', 'M', 'B+',  'Sunita Verma',   '9988776655', 'Star Health',       '2024-01-01', '2026-12-31', 'Family Floater'),
('HID-002', 'Ananya',  'Devi',  'Singh',   '45 Park Street',    'Mumbai',    'Maharashtra', '400001', '1985-11-20', 'F', 'O+',  'Ravi Singh',     '9877665544', 'ICICI Lombard',     '2024-06-01', '2026-05-31', 'Individual'),
('HID-003', 'Arjun',   NULL,    'Reddy',   '78 Jubilee Hills',  'Hyderabad', 'Telangana',   '500033', '2000-02-28', 'M', 'A+',  'Lakshmi Reddy',  '9766554433', 'Max Bupa',          '2025-01-01', '2027-12-31', 'Individual'),
('HID-004', 'Meera',   'Kumari','Joshi',   '23 Civil Lines',    'Jaipur',    'Rajasthan',   '302001', '1972-08-10', 'F', 'AB+', 'Suresh Joshi',   '9655443322', 'New India Assurance','2024-04-01', '2026-03-31', 'Senior Citizen'),
('HID-005', 'Sanjay',  NULL,    'Patel',   '56 SG Highway',     'Ahmedabad', 'Gujarat',     '380015', '1995-12-03', 'M', 'O-',  'Deepa Patel',    '9544332211', 'Star Health',       '2025-01-01', '2026-12-31', 'Individual'),
('HID-006', 'Pooja',   NULL,    'Nair',    '89 MG Road',        'Kochi',     'Kerala',      '682011', '2018-07-22', 'F', 'B-',  'Suresh Nair',    '9433221100', 'Care Health',       '2025-06-01', '2027-05-31', 'Family Floater'),
('HID-007', 'Ravi',    'Kumar', 'Yadav',   '34 Mall Road',      'Lucknow',   'UP',          '226001', '1960-03-05', 'M', 'A-',  'Kamla Yadav',    '9322110099', 'HDFC Ergo',         '2024-01-01', '2025-12-31', 'Senior Citizen'),
('HID-008', 'Priyanka',NULL,    'Das',     '67 Salt Lake',      'Kolkata',   'West Bengal', '700091', '1998-09-14', 'F', 'AB-', 'Tapas Das',      '9211009988', 'Bajaj Allianz',     '2025-03-01', '2027-02-28', 'Individual');

-- ============================================================
-- PATIENT ALLERGIES
-- ============================================================
INSERT INTO PATIENT_ALLERGY (health_id, allergen, reaction_description, severity, identified_date, status) VALUES
('HID-001', 'Penicillin',  'Severe rash and anaphylaxis risk', 'Severe', '2015-03-20', 'Active'),
('HID-001', 'Sulfa drugs', 'Mild skin rash', 'Mild', '2018-06-15', 'Active'),
('HID-002', 'Aspirin',     'GI bleeding', 'Severe', '2020-01-10', 'Active'),
('HID-004', 'Ibuprofen',   'Bronchospasm', 'Life-threatening', '2019-08-22', 'Active'),
('HID-005', 'Latex',       'Contact dermatitis', 'Moderate', '2022-04-05', 'Active'),
('HID-007', 'Codeine',     'Respiratory depression', 'Severe', '2017-11-30', 'Active');

-- ============================================================
-- APP USERS (password is 'password123' hashed with bcrypt)
-- BCrypt hash generated from Spring Security BCryptPasswordEncoder
-- ============================================================
INSERT INTO APP_USER (user_id, username, password_hash, role, status) VALUES
(1, 'admin',        '$2a$10$PfHkCNRLyMy9ozeCiVJX/eFuOe620IGWClOPPNn5624NW0.VNdMQy', 'admin',   'Active'),
(2, 'dr.anil',      '$2a$10$PfHkCNRLyMy9ozeCiVJX/eFuOe620IGWClOPPNn5624NW0.VNdMQy', 'doctor',  'Active'),
(3, 'dr.priya',     '$2a$10$PfHkCNRLyMy9ozeCiVJX/eFuOe620IGWClOPPNn5624NW0.VNdMQy', 'doctor',  'Active'),
(4, 'rahul.verma',  '$2a$10$PfHkCNRLyMy9ozeCiVJX/eFuOe620IGWClOPPNn5624NW0.VNdMQy', 'patient', 'Active'),
(5, 'ananya.singh', '$2a$10$PfHkCNRLyMy9ozeCiVJX/eFuOe620IGWClOPPNn5624NW0.VNdMQy', 'patient', 'Active'),
(6, 'dr.rajesh',    '$2a$10$PfHkCNRLyMy9ozeCiVJX/eFuOe620IGWClOPPNn5624NW0.VNdMQy', 'doctor',  'Active'),
(7, 'dr.sneha',     '$2a$10$PfHkCNRLyMy9ozeCiVJX/eFuOe620IGWClOPPNn5624NW0.VNdMQy', 'doctor',  'Active');

INSERT INTO ADMIN_USER (user_id) VALUES (1);
INSERT INTO DOCTOR_USER (user_id, doctor_id) VALUES (2, 1), (3, 2), (6, 3), (7, 4);
INSERT INTO PATIENT_USER (user_id, health_id) VALUES (4, 'HID-001'), (5, 'HID-002');

-- ============================================================
-- ENCOUNTERS
-- ============================================================
INSERT INTO ENCOUNTER (encounter_id, health_id, hospital_id, encounter_date_time, encounter_type, chief_complaint, examination_notes, treatment_plan) VALUES
(1, 'HID-001', 1, '2025-12-01 09:30:00', 'Outpatient', 'Persistent cough and fever for 3 days', 'Bilateral rhonchi on auscultation, temp 101F', 'Antibiotics and rest for 5 days, follow-up if no improvement'),
(2, 'HID-002', 2, '2025-12-05 14:00:00', 'Outpatient', 'Routine hypertension follow-up', 'BP 145/92, otherwise stable', 'Continue current medications, lifestyle modifications'),
(3, 'HID-003', 3, '2025-12-10 11:00:00', 'Outpatient', 'Chest pain on exertion', 'ECG normal sinus rhythm, mild tachycardia', 'Stress test ordered, lifestyle changes advised'),
(4, 'HID-004', 4, '2025-12-15 08:00:00', 'Emergency', 'Severe abdominal pain', 'Tenderness in RLQ, elevated WBC', 'Emergency surgical evaluation'),
(5, 'HID-001', 1, '2025-12-20 10:00:00', 'Follow-up', 'Follow-up for respiratory infection', 'Lungs clear, afebrile', 'Discontinue antibiotics, recovery confirmed');

INSERT INTO ENCOUNTER (encounter_id, health_id, hospital_id, encounter_date_time, encounter_type, admission_date_time, bed_number, chief_complaint, treatment_plan) VALUES
(6, 'HID-005', 5, '2026-01-05 22:30:00', 'Inpatient', '2026-01-05 23:00:00', 'ICU-12', 'Road traffic accident with multiple fractures', 'Surgical fixation of fractures, ICU monitoring'),
(7, 'HID-007', 2, '2026-01-10 09:00:00', 'Inpatient', '2026-01-10 09:30:00', 'W3-204', 'Uncontrolled diabetes with ketoacidosis', 'Insulin drip, fluid resuscitation, close monitoring');

-- ============================================================
-- ENCOUNTER-DOCTOR ASSIGNMENTS
-- ============================================================
INSERT INTO ENCOUNTER_DOCTOR (encounter_id, doctor_id, role, is_primary) VALUES
(1, 1, 'Attending Physician', TRUE),
(2, 2, 'Attending Physician', TRUE),
(3, 2, 'Attending Physician', TRUE),
(4, 4, 'Attending Physician', TRUE),
(4, 7, 'Consulting Surgeon', FALSE),
(5, 1, 'Attending Physician', TRUE),
(6, 3, 'Orthopedic Surgeon', TRUE),
(6, 6, 'Emergency Physician', FALSE),
(7, 1, 'Attending Physician', TRUE),
(7, 5, 'Consultant Neurologist', FALSE);

-- ============================================================
-- VITAL SIGNS
-- ============================================================
INSERT INTO VITAL_SIGNS (encounter_id, reading_timestamp, bp_systolic, bp_diastolic, pulse, temperature, respiratory_rate, height, weight, oxygen_saturation) VALUES
(1, '2025-12-01 09:35:00', 130, 85, 92, 38.8, 20, 175.00, 72.00, 96),
(2, '2025-12-05 14:10:00', 145, 92, 78, 36.8, 16, 160.00, 65.00, 98),
(3, '2025-12-10 11:10:00', 128, 80, 100, 36.9, 18, 180.00, 82.00, 97),
(4, '2025-12-15 08:10:00', 110, 70, 110, 38.2, 22, 155.00, 58.00, 95),
(5, '2025-12-20 10:05:00', 120, 78, 72, 36.6, 16, 175.00, 72.00, 98),
(6, '2026-01-05 22:45:00', 90,  55, 120, 37.0, 24, 170.00, 68.00, 92),
(7, '2026-01-10 09:15:00', 150, 95, 105, 37.5, 22, 168.00, 80.00, 94);

-- ============================================================
-- DIAGNOSES
-- ============================================================
INSERT INTO ENCOUNTER_DIAGNOSIS (encounter_id, icd10_code, diagnosis_type, status, diagnosed_date) VALUES
(1, 'J06.9',  'Primary',   'Active',   '2025-12-01'),
(1, 'R50.9',  'Secondary', 'Active',   '2025-12-01'),
(2, 'I10',    'Primary',   'Active',   '2025-12-05'),
(3, 'I10',    'Provisional','Active',  '2025-12-10'),
(4, 'K21.0',  'Primary',   'Active',   '2025-12-15'),
(5, 'J06.9',  'Primary',   'Resolved', '2025-12-20'),
(6, 'M54.5',  'Primary',   'Active',   '2026-01-05'),
(7, 'E11.9',  'Primary',   'Active',   '2026-01-10');

-- ============================================================
-- PRESCRIPTIONS AND ITEMS
-- ============================================================
INSERT INTO PRESCRIPTION (prescription_id, encounter_id, doctor_id, prescription_date, start_date, end_date, status) VALUES
(1, 1, 1, '2025-12-01', '2025-12-01', '2025-12-06', 'Completed'),
(2, 2, 2, '2025-12-05', '2025-12-05', '2026-06-05', 'Active'),
(3, 3, 2, '2025-12-10', '2025-12-10', '2026-03-10', 'Active'),
(4, 5, 1, '2025-12-20', '2025-12-20', NULL, 'Discontinued'),
(5, 7, 1, '2026-01-10', '2026-01-10', '2026-04-10', 'Active');

-- NOTE: HID-001 (Rahul) is allergic to Penicillin (Severe),
-- so prescribing Amoxicillin (penicillin antibiotic) would trigger the allergy alert.
-- Using Ciprofloxacin instead for encounter 1.
INSERT INTO PRESCRIPTION_ITEM (prescription_id, medication_id, dosage_strength, dosage_form, frequency, duration_days, quantity_dispensed, instructions) VALUES
(1, 9,  '500mg', 'Tablet', 'Twice daily', 5, 10, 'Take with water after meals'),
(1, 8,  '500mg', 'Tablet', 'Every 6 hours as needed', 5, 20, 'For fever, do not exceed 4g/day'),
(2, 3,  '10mg',  'Tablet', 'Once daily', 180, 180, 'Take in the morning'),
(2, 6,  '5mg',   'Tablet', 'Once daily', 180, 180, 'Take at bedtime'),
(3, 4,  '20mg',  'Tablet', 'Once daily at night', 90, 90, 'Take at bedtime with food'),
(5, 2,  '500mg', 'Tablet', 'Twice daily', 90, 180, 'Take with meals');

-- ============================================================
-- LAB ORDERS AND RESULTS
-- ============================================================
INSERT INTO LAB_ORDER (lab_order_id, encounter_id, doctor_id, test_code, priority, clinical_info, order_status, specimen_id, order_date_time) VALUES
(1, 1, 1, 'CBC',   'Urgent', 'Fever with cough, rule out infection', 'Completed', 'SPEC-20251201-001', '2025-12-01 09:45:00'),
(2, 2, 2, 'BMP',   'Routine', 'Hypertension follow-up', 'Completed', 'SPEC-20251205-001', '2025-12-05 14:30:00'),
(3, 2, 2, 'LIPID', 'Routine', 'Annual lipid screening', 'Completed', 'SPEC-20251205-002', '2025-12-05 14:30:00'),
(4, 3, 2, 'CMP',   'Routine', 'Chest pain workup', 'Completed', 'SPEC-20251210-001', '2025-12-10 11:30:00'),
(5, 4, 4, 'CBC',   'Stat',   'Acute abdomen, rule out appendicitis', 'Completed', 'SPEC-20251215-001', '2025-12-15 08:15:00'),
(6, 6, 3, 'CBC',   'Stat',   'Trauma patient, assess blood loss', 'Completed', 'SPEC-20260105-001', '2026-01-05 23:00:00'),
(7, 7, 1, 'HBA1C', 'Urgent', 'DKA admission', 'Completed', 'SPEC-20260110-001', '2026-01-10 09:30:00'),
(8, 7, 1, 'BG',    'Stat',   'DKA monitoring', 'Pending', 'SPEC-20260110-002', '2026-01-10 09:30:00');

INSERT INTO LAB_RESULT (lab_order_id, result_value, result_unit, reference_range, abnormal_flag, critical_flag, result_date, verified_by_doctor_id) VALUES
(1, '15200', 'cells/mcL', '4500-11000', TRUE, FALSE, '2025-12-01 11:00:00', 1),
(2, '142', 'mEq/L', '136-145', FALSE, FALSE, '2025-12-05 16:00:00', 2),
(3, '245', 'mg/dL', '<200', TRUE, FALSE, '2025-12-05 16:30:00', 2),
(4, '1.2', 'mg/dL', '0.7-1.3', FALSE, FALSE, '2025-12-10 13:00:00', 2),
(5, '18500', 'cells/mcL', '4500-11000', TRUE, TRUE, '2025-12-15 08:45:00', 4),
(6, '7.2', 'g/dL', '12-17.5', TRUE, TRUE, '2026-01-05 23:30:00', 3),
(7, '11.8', '%', '4.0-5.6', TRUE, TRUE, '2026-01-10 10:30:00', 1);

-- ============================================================
-- CONSENTS
-- ============================================================
INSERT INTO CONSENT (health_id, hospital_id, access_level, purpose, effective_date, expiration_date, status) VALUES
('HID-001', 1, 'Full',       'Ongoing treatment',     '2025-01-01', '2027-12-31', 'Active'),
('HID-001', 2, 'Restricted', 'Second opinion',        '2025-06-01', '2026-06-01', 'Active'),
('HID-002', 2, 'Full',       'Ongoing treatment',     '2025-01-01', '2027-12-31', 'Active'),
('HID-002', 3, 'Basic',      'Insurance processing',  '2025-01-01', '2025-12-31', 'Expired'),
('HID-003', 3, 'Full',       'Ongoing treatment',     '2025-06-01', '2027-05-31', 'Active'),
('HID-004', 4, 'Full',       'Ongoing treatment',     '2025-01-01', '2027-12-31', 'Active'),
('HID-005', 5, 'Full',       'Emergency treatment',   '2026-01-05', '2027-01-05', 'Active'),
('HID-007', 2, 'Full',       'Ongoing treatment',     '2025-06-01', '2027-05-31', 'Active');

-- ============================================================
-- INITIAL AUDIT LOG ENTRIES
-- ============================================================
INSERT INTO AUDIT_LOG (user_id, action_type, table_name, notes, event_time) VALUES
(1, 'SYSTEM_INIT', 'ALL', 'MediChain database initialized with seed data', NOW());
