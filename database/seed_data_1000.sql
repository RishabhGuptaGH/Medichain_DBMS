-- ============================================================
-- MediChain - Extended Seed Data (1000+ entries)
-- Run AFTER seed_data.sql
-- ============================================================

USE medichain;

DELIMITER //
CREATE PROCEDURE sp_generate_seed_data()
BEGIN
    -- --------------------------------------------------------
    -- Variable declarations
    -- --------------------------------------------------------
    DECLARE i INT DEFAULT 0;
    DECLARE v_health_id VARCHAR(50);
    DECLARE v_fname VARCHAR(100);
    DECLARE v_lname VARCHAR(100);
    DECLARE v_mname VARCHAR(100);
    DECLARE v_gender CHAR(1);
    DECLARE v_city VARCHAR(100);
    DECLARE v_state VARCHAR(100);
    DECLARE v_postal VARCHAR(20);
    DECLARE v_dob DATE;
    DECLARE v_blood VARCHAR(3);
    DECLARE v_insurance VARCHAR(255);
    DECLARE v_policy VARCHAR(100);

    DECLARE v_doc_id INT;
    DECLARE v_doc_name VARCHAR(255);
    DECLARE v_spec VARCHAR(100);
    DECLARE v_license VARCHAR(100);

    DECLARE v_hosp_id INT;
    DECLARE v_enc_id INT;
    DECLARE v_enc_date DATETIME;
    DECLARE v_enc_type VARCHAR(20);
    DECLARE v_patient_idx INT;
    DECLARE v_doctor_idx INT;
    DECLARE v_hospital_idx INT;

    DECLARE v_pres_id INT;
    DECLARE v_med_id INT;
    DECLARE v_lab_id INT;
    DECLARE v_test_code VARCHAR(50);

    DECLARE v_user_id INT;
    DECLARE v_username VARCHAR(100);
    DECLARE v_bcrypt_hash VARCHAR(255);

    DECLARE v_rand INT;
    DECLARE v_rand2 INT;
    DECLARE v_rand3 INT;
    DECLARE v_base_date DATE;
    DECLARE v_days_offset INT;
    DECLARE v_complaint TEXT;
    DECLARE v_notes TEXT;
    DECLARE v_plan TEXT;

    DECLARE v_bp_sys INT;
    DECLARE v_bp_dia INT;
    DECLARE v_pulse INT;
    DECLARE v_temp DECIMAL(4,1);
    DECLARE v_rr INT;
    DECLARE v_height DECIMAL(5,2);
    DECLARE v_weight DECIMAL(5,2);
    DECLARE v_o2 INT;

    SET v_bcrypt_hash = '$2a$10$PfHkCNRLyMy9ozeCiVJX/eFuOe620IGWClOPPNn5624NW0.VNdMQy';

    -- ========================================================
    -- 1. HOSPITALS (IDs 6-10) - 5 new hospitals
    -- ========================================================
    INSERT IGNORE INTO HOSPITAL (hospital_id, hospital_name, license_number, phone, email, bed_capacity, address_street, address_city, address_state, postal_code, facility_type) VALUES
    (6,  'Manipal Hospital Bangalore',   'LIC-MNP-001', '080-25021111', 'info@manipal-blr.com',     600, '98 HAL Airport Road',    'Bangalore',  'Karnataka',    '560017', 'General Hospital'),
    (7,  'CMC Vellore',                  'LIC-CMC-001', '0416-2281000','info@cmcvellore.ac.in',    2200, 'Ida Scudder Road',       'Vellore',    'Tamil Nadu',   '632004', 'Teaching Hospital'),
    (8,  'Narayana Health Kolkata',       'LIC-NHK-001', '033-40403040','info@narayana-kol.com',     450, '120 EM Bypass Road',     'Kolkata',    'West Bengal',  '700099', 'Specialty Hospital'),
    (9,  'Medanta The Medicity',         'LIC-MDT-001', '0124-4141414','info@medanta.org',          1250, 'CH Baktawar Singh Road', 'Gurugram',   'Haryana',      '122001', 'General Hospital'),
    (10, 'Tata Memorial Hospital',       'LIC-TMH-001', '022-24177000','info@tmc.gov.in',           629, 'Dr. Ernest Borges Road', 'Mumbai',     'Maharashtra',  '400012', 'Specialty Hospital');

    -- ========================================================
    -- 2. DEPARTMENTS for new hospitals
    -- ========================================================
    INSERT IGNORE INTO DEPARTMENT (hospital_id, department_name) VALUES
    (6, 'Emergency Medicine'), (6, 'Internal Medicine'), (6, 'Cardiology'), (6, 'Neurology'), (6, 'Orthopedics'),
    (7, 'Emergency Medicine'), (7, 'Internal Medicine'), (7, 'Cardiology'), (7, 'Neurology'), (7, 'Oncology'), (7, 'Pediatrics'), (7, 'Surgery'),
    (8, 'Cardiology'), (8, 'Cardiac Surgery'), (8, 'Internal Medicine'), (8, 'Pediatrics'),
    (9, 'Emergency Medicine'), (9, 'Internal Medicine'), (9, 'Cardiology'), (9, 'Neurology'), (9, 'Orthopedics'), (9, 'Oncology'), (9, 'Surgery'), (9, 'Radiology'),
    (10, 'Oncology'), (10, 'Surgery'), (10, 'Radiology'), (10, 'Pathology'), (10, 'Internal Medicine');

    -- ========================================================
    -- 3. DOCTORS (IDs 9-38) - 30 new doctors
    -- ========================================================
    INSERT IGNORE INTO DOCTOR (doctor_id, medical_license_number, name, phone_number, email, date_of_birth, specialization) VALUES
    (9,  'MCI-2013-1001', 'Dr. Aarav Sharma',       '9876543220', 'aarav.sharma@manipal.com',    '1981-02-14', 'Internal Medicine'),
    (10, 'MCI-2007-1002', 'Dr. Vivaan Gupta',       '9876543221', 'vivaan.gupta@cmc.ac.in',      '1976-08-30', 'Cardiology'),
    (11, 'MCI-2016-1003', 'Dr. Aditya Verma',       '9876543222', 'aditya.verma@narayana.com',   '1986-05-10', 'Pediatrics'),
    (12, 'MCI-2010-1004', 'Dr. Sai Reddy',          '9876543223', 'sai.reddy@medanta.org',       '1979-11-22', 'Orthopedics'),
    (13, 'MCI-2006-1005', 'Dr. Rohan Iyer',         '9876543224', 'rohan.iyer@tmc.gov.in',       '1974-03-08', 'Oncology'),
    (14, 'MCI-2011-1006', 'Dr. Ishaan Bhat',        '9876543225', 'ishaan.bhat@manipal.com',     '1983-07-17', 'Neurology'),
    (15, 'MCI-2009-1007', 'Dr. Kabir Singh',        '9876543226', 'kabir.singh@medanta.org',     '1977-12-01', 'Surgery'),
    (16, 'MCI-2014-1008', 'Dr. Ananya Das',         '9876543227', 'ananya.das@narayana.com',     '1984-09-25', 'Cardiology'),
    (17, 'MCI-2012-1009', 'Dr. Diya Pillai',        '9876543228', 'diya.pillai@cmc.ac.in',       '1982-01-05', 'Dermatology'),
    (18, 'MCI-2008-1010', 'Dr. Saanvi Menon',       '9876543229', 'saanvi.menon@manipal.com',    '1978-06-19', 'Emergency Medicine'),
    (19, 'MCI-2015-1011', 'Dr. Riya Joshi',         '9876543230', 'riya.joshi@medanta.org',      '1985-04-13', 'Internal Medicine'),
    (20, 'MCI-2007-1012', 'Dr. Aisha Chatterjee',   '9876543231', 'aisha.chatterjee@tmc.gov.in', '1975-10-28', 'Oncology'),
    (21, 'MCI-2017-1013', 'Dr. Kavya Rao',          '9876543232', 'kavya.rao@narayana.com',      '1987-08-07', 'Pediatrics'),
    (22, 'MCI-2010-1014', 'Dr. Arjun Mukherjee',    '9876543233', 'arjun.mukherjee@cmc.ac.in',   '1980-02-20', 'Surgery'),
    (23, 'MCI-2013-1015', 'Dr. Vikash Kumar',       '9876543234', 'vikash.kumar@manipal.com',    '1981-11-11', 'Pulmonology'),
    (24, 'MCI-2006-1016', 'Dr. Neha Banerjee',      '9876543235', 'neha.banerjee@medanta.org',   '1973-05-30', 'Endocrinology'),
    (25, 'MCI-2011-1017', 'Dr. Pradeep Nair',       '9876543236', 'pradeep.nair@tmc.gov.in',     '1979-09-15', 'Radiology'),
    (26, 'MCI-2009-1018', 'Dr. Sunita Patel',       '9876543237', 'sunita.patel@narayana.com',   '1977-04-02', 'Pathology'),
    (27, 'MCI-2016-1019', 'Dr. Rahul Sharma',       '9876543238', 'rahul.sharma2@manipal.com',   '1986-12-25', 'Emergency Medicine'),
    (28, 'MCI-2008-1020', 'Dr. Deepika Gupta',      '9876543239', 'deepika.gupta@cmc.ac.in',     '1976-07-14', 'Gynecology'),
    (29, 'MCI-2014-1021', 'Dr. Karthik Reddy',      '9876543240', 'karthik.reddy@medanta.org',   '1984-01-18', 'Cardiology'),
    (30, 'MCI-2012-1022', 'Dr. Meghna Iyer',        '9876543241', 'meghna.iyer@tmc.gov.in',      '1982-06-09', 'Oncology'),
    (31, 'MCI-2005-1023', 'Dr. Suresh Pillai',      '9876543242', 'suresh.pillai@narayana.com',  '1970-03-21', 'Internal Medicine'),
    (32, 'MCI-2018-1024', 'Dr. Tanvi Joshi',        '9876543243', 'tanvi.joshi@manipal.com',     '1988-10-05', 'Dermatology'),
    (33, 'MCI-2007-1025', 'Dr. Manish Bhat',        '9876543244', 'manish.bhat@cmc.ac.in',       '1975-08-16', 'Neurology'),
    (34, 'MCI-2015-1026', 'Dr. Pooja Menon',        '9876543245', 'pooja.menon@medanta.org',     '1985-02-28', 'Psychiatry'),
    (35, 'MCI-2010-1027', 'Dr. Amit Das',           '9876543246', 'amit.das@tmc.gov.in',         '1979-07-07', 'Surgery'),
    (36, 'MCI-2013-1028', 'Dr. Shruti Verma',       '9876543247', 'shruti.verma@narayana.com',   '1983-11-30', 'Pediatrics'),
    (37, 'MCI-2009-1029', 'Dr. Harish Singh',       '9876543248', 'harish.singh@manipal.com',    '1977-05-22', 'Orthopedics'),
    (38, 'MCI-2011-1030', 'Dr. Lakshmi Rao',        '9876543249', 'lakshmi.rao@cmc.ac.in',       '1981-09-03', 'Pulmonology');

    -- ========================================================
    -- 4. DOCTOR-HOSPITAL ASSOCIATIONS for new doctors
    -- ========================================================
    INSERT IGNORE INTO DOCTOR_HOSPITAL (doctor_id, hospital_id, join_date, status) VALUES
    (9,  6, '2018-03-01', 'Active'),
    (9,  9, '2021-06-15', 'Active'),
    (10, 7, '2012-01-10', 'Active'),
    (10, 8, '2019-04-01', 'Active'),
    (11, 8, '2020-07-15', 'Active'),
    (12, 9, '2016-02-20', 'Active'),
    (13, 10, '2011-08-01', 'Active'),
    (14, 6, '2017-05-10', 'Active'),
    (15, 9, '2014-09-01', 'Active'),
    (15, 7, '2020-01-15', 'Active'),
    (16, 8, '2019-11-01', 'Active'),
    (17, 7, '2016-06-20', 'Active'),
    (18, 6, '2015-03-15', 'Active'),
    (19, 9, '2019-08-01', 'Active'),
    (20, 10, '2012-04-10', 'Active'),
    (21, 8, '2021-02-01', 'Active'),
    (22, 7, '2015-10-15', 'Active'),
    (23, 6, '2018-07-01', 'Active'),
    (24, 9, '2013-12-01', 'Active'),
    (25, 10, '2016-05-20', 'Active'),
    (26, 8, '2014-01-10', 'Active'),
    (27, 6, '2020-09-01', 'Active'),
    (28, 7, '2013-03-15', 'Active'),
    (29, 9, '2019-06-01', 'Active'),
    (30, 10, '2017-11-10', 'Active'),
    (31, 8, '2010-05-01', 'Active'),
    (32, 6, '2022-01-15', 'Active'),
    (33, 7, '2012-08-20', 'Active'),
    (34, 9, '2020-04-01', 'Active'),
    (35, 10, '2015-07-15', 'Active'),
    (36, 8, '2018-12-01', 'Active'),
    (36, 7, '2021-05-10', 'Active'),
    (37, 6, '2014-02-15', 'Active'),
    (37, 9, '2019-10-01', 'Active'),
    (38, 7, '2016-09-20', 'Active');

    -- ========================================================
    -- 5. PATIENTS (HID-009 to HID-108) - 100 new patients
    -- ========================================================
    SET i = 9;
    WHILE i <= 108 DO
        SET v_health_id = CONCAT('HID-', LPAD(i, 3, '0'));

        -- Random gender
        SET v_rand = FLOOR(1 + RAND() * 3);
        SET v_gender = ELT(v_rand, 'M', 'F', 'O');

        -- First names based on gender
        IF v_gender = 'M' THEN
            SET v_rand = FLOOR(1 + RAND() * 25);
            SET v_fname = ELT(v_rand,
                'Aarav','Vivaan','Aditya','Arjun','Sai','Rohan','Ishaan','Kabir',
                'Vihaan','Reyansh','Ayaan','Krishna','Dhruv','Harsh','Karan',
                'Nikhil','Pranav','Raj','Sahil','Tarun','Yash','Amit','Deepak',
                'Gaurav','Manish');
        ELSEIF v_gender = 'F' THEN
            SET v_rand = FLOOR(1 + RAND() * 25);
            SET v_fname = ELT(v_rand,
                'Ananya','Diya','Saanvi','Priya','Riya','Aisha','Meera','Kavya',
                'Aadhya','Ira','Kiara','Myra','Navya','Pari','Sara',
                'Tara','Uma','Vidya','Zara','Nisha','Pooja','Shreya','Tanvi',
                'Neha','Divya');
        ELSE
            SET v_rand = FLOOR(1 + RAND() * 10);
            SET v_fname = ELT(v_rand,
                'Akira','Noor','Arin','Jaya','Kiran','Pat','Reese','Sasha','Teja','Veer');
        END IF;

        -- Middle name (40% chance)
        IF RAND() < 0.4 THEN
            SET v_rand = FLOOR(1 + RAND() * 8);
            SET v_mname = ELT(v_rand, 'Kumar','Devi','Kumari','Lal','Chand','Nath','Prasad','Ram');
        ELSE
            SET v_mname = NULL;
        END IF;

        -- Last name
        SET v_rand = FLOOR(1 + RAND() * 20);
        SET v_lname = ELT(v_rand,
            'Sharma','Verma','Gupta','Patel','Reddy','Nair','Joshi','Iyer',
            'Bhat','Singh','Kumar','Das','Chatterjee','Banerjee','Mukherjee',
            'Rao','Pillai','Menon','Yadav','Sinha');

        -- City, State, Postal
        SET v_rand = FLOOR(1 + RAND() * 15);
        SET v_city = ELT(v_rand,
            'Mumbai','Bangalore','Chennai','Kolkata','Hyderabad','Pune','Ahmedabad',
            'Jaipur','Lucknow','Chandigarh','Kochi','Bhopal','Indore','Nagpur','Coimbatore');
        SET v_state = ELT(v_rand,
            'Maharashtra','Karnataka','Tamil Nadu','West Bengal','Telangana','Maharashtra','Gujarat',
            'Rajasthan','Uttar Pradesh','Punjab','Kerala','Madhya Pradesh','Madhya Pradesh','Maharashtra','Tamil Nadu');
        SET v_postal = ELT(v_rand,
            '400001','560001','600001','700001','500001','411001','380001',
            '302001','226001','160001','682001','462001','452001','440001','641001');

        -- Date of birth: between 1955 and 2020
        SET v_dob = DATE_ADD('1955-01-01', INTERVAL FLOOR(RAND() * 23725) DAY);

        -- Blood group
        SET v_rand = FLOOR(1 + RAND() * 8);
        SET v_blood = ELT(v_rand, 'A+','A-','B+','B-','AB+','AB-','O+','O-');

        -- Insurance
        SET v_rand = FLOOR(1 + RAND() * 8);
        SET v_insurance = ELT(v_rand,
            'Star Health','ICICI Lombard','Max Bupa','New India Assurance',
            'Care Health','HDFC Ergo','Bajaj Allianz','Niva Bupa');
        SET v_rand = FLOOR(1 + RAND() * 4);
        SET v_policy = ELT(v_rand, 'Individual','Family Floater','Senior Citizen','Group');

        INSERT IGNORE INTO PATIENT (health_id, fname, mname, lname, address_street, address_city, address_state, postal_code,
                             date_of_birth, gender, blood_group, emergency_contact_name, emergency_contact_phone,
                             insurance_provider, insurance_start, insurance_end, policy_type)
        VALUES (
            v_health_id, v_fname, v_mname, v_lname,
            CONCAT(FLOOR(1 + RAND() * 200), ' ', ELT(FLOOR(1 + RAND() * 10),
                'MG Road','Gandhi Nagar','Nehru Street','Station Road','Civil Lines',
                'Park Avenue','Ring Road','Rajaji Street','Lajpat Nagar','Karol Bagh')),
            v_city, v_state, v_postal,
            v_dob, v_gender, v_blood,
            CONCAT(ELT(FLOOR(1 + RAND() * 6), 'Sunita','Ravi','Priya','Mohan','Geeta','Suresh'), ' ', v_lname),
            CONCAT('9', LPAD(FLOOR(RAND() * 1000000000), 9, '0')),
            v_insurance,
            DATE_ADD('2024-01-01', INTERVAL FLOOR(RAND() * 365) DAY),
            DATE_ADD('2026-01-01', INTERVAL FLOOR(RAND() * 730) DAY),
            v_policy
        );

        SET i = i + 1;
    END WHILE;

    -- ========================================================
    -- 6. PATIENT ALLERGIES (~30 new allergies)
    -- ========================================================
    SET i = 1;
    WHILE i <= 30 DO
        SET v_patient_idx = 9 + FLOOR(RAND() * 100);
        SET v_health_id = CONCAT('HID-', LPAD(v_patient_idx, 3, '0'));

        SET v_rand = FLOOR(1 + RAND() * 12);

        INSERT IGNORE INTO PATIENT_ALLERGY (health_id, allergen, reaction_description, severity, identified_date, status)
        VALUES (
            v_health_id,
            ELT(v_rand,
                'Penicillin','Sulfonamides','Aspirin','Ibuprofen','Latex','Peanuts',
                'Shellfish','Dust Mites','Pollen','Codeine','Morphine','Contrast Dye'),
            ELT(v_rand,
                'Rash and swelling','Skin eruption','GI bleeding','Bronchospasm','Contact dermatitis','Anaphylaxis',
                'Urticaria','Rhinitis and sneezing','Allergic rhinitis','Respiratory depression','Nausea and itching','Anaphylactoid reaction'),
            ELT(FLOOR(1 + RAND() * 4), 'Mild','Moderate','Severe','Life-threatening'),
            DATE_ADD('2018-01-01', INTERVAL FLOOR(RAND() * 2500) DAY),
            ELT(FLOOR(1 + RAND() * 3), 'Active','Active','Inactive')
        );

        SET i = i + 1;
    END WHILE;

    -- ========================================================
    -- 7. ENCOUNTERS (IDs 8-327) - 320 new encounters
    --    Using dates from 2023-01-01 to 2026-03-01
    -- ========================================================
    SET i = 8;
    WHILE i <= 327 DO
        -- Pick a patient: mix of old and new
        IF RAND() < 0.15 THEN
            SET v_patient_idx = FLOOR(1 + RAND() * 8);
        ELSE
            SET v_patient_idx = 9 + FLOOR(RAND() * 100);
        END IF;
        SET v_health_id = CONCAT('HID-', LPAD(v_patient_idx, 3, '0'));

        -- Pick a hospital (1-10)
        SET v_hospital_idx = FLOOR(1 + RAND() * 10);

        -- Random date between 2023-01-01 and 2026-03-01
        SET v_days_offset = FLOOR(RAND() * 1155);
        SET v_enc_date = DATE_ADD('2023-01-01', INTERVAL v_days_offset DAY);
        SET v_enc_date = DATE_ADD(v_enc_date, INTERVAL FLOOR(7 + RAND() * 14) HOUR);
        SET v_enc_date = DATE_ADD(v_enc_date, INTERVAL FLOOR(RAND() * 60) MINUTE);

        -- Encounter type
        SET v_rand = FLOOR(1 + RAND() * 10);
        IF v_rand <= 4 THEN
            SET v_enc_type = 'Outpatient';
        ELSEIF v_rand <= 6 THEN
            SET v_enc_type = 'Follow-up';
        ELSEIF v_rand <= 8 THEN
            SET v_enc_type = 'Emergency';
        ELSE
            SET v_enc_type = 'Inpatient';
        END IF;

        -- Chief complaint
        SET v_rand = FLOOR(1 + RAND() * 20);
        SET v_complaint = ELT(v_rand,
            'Persistent headache for 3 days',
            'High fever with body aches',
            'Chest tightness and shortness of breath',
            'Severe abdominal pain radiating to back',
            'Chronic lower back pain worsening',
            'Routine diabetes follow-up',
            'Skin rash and itching for a week',
            'Knee pain after fall',
            'Recurrent urinary symptoms',
            'Dizziness and fainting episodes',
            'Sore throat and difficulty swallowing',
            'Persistent cough with sputum',
            'Joint pain in multiple joints',
            'Eye redness and discharge',
            'Anxiety and sleep disturbance',
            'Follow-up for hypertension management',
            'Stomach pain after meals',
            'Numbness in hands and feet',
            'Annual health checkup',
            'Weight loss and fatigue');

        -- Exam notes
        SET v_rand2 = FLOOR(1 + RAND() * 10);
        SET v_notes = ELT(v_rand2,
            'Vitals within normal limits, general examination unremarkable',
            'Mild tenderness on palpation, no guarding or rigidity',
            'Bilateral clear lung fields, S1S2 normal, no murmurs',
            'Elevated temperature, pharyngeal erythema noted',
            'Limited range of motion, swelling in affected area',
            'Pupils equal and reactive, cranial nerves intact',
            'Mild wheezing on auscultation, no crepitations',
            'Abdominal distension, bowel sounds hyperactive',
            'Skin lesions noted on trunk, no lymphadenopathy',
            'Alert and oriented, neurological exam normal');

        -- Treatment plan
        SET v_rand3 = FLOOR(1 + RAND() * 10);
        SET v_plan = ELT(v_rand3,
            'Medications prescribed, follow-up in 1 week',
            'Lab tests ordered, continue current medications',
            'Refer to specialist, symptomatic management for now',
            'Admit for observation, IV fluids and monitoring',
            'Physical therapy recommended, pain management initiated',
            'Lifestyle modifications advised, dietary counseling',
            'Surgical consultation recommended, pre-op workup initiated',
            'Discharge with medications, follow-up in 2 weeks',
            'Imaging studies ordered, pending results for further plan',
            'Condition stable, continue current treatment plan');

        IF v_enc_type = 'Inpatient' THEN
            INSERT IGNORE INTO ENCOUNTER (encounter_id, health_id, hospital_id, encounter_date_time, encounter_type,
                                   admission_date_time, bed_number, chief_complaint, examination_notes, treatment_plan)
            VALUES (i, v_health_id, v_hospital_idx, v_enc_date, v_enc_type,
                    DATE_ADD(v_enc_date, INTERVAL 30 MINUTE),
                    CONCAT(ELT(FLOOR(1+RAND()*4), 'W1-','W2-','ICU-','W3-'), LPAD(FLOOR(RAND()*300), 3, '0')),
                    v_complaint, v_notes, v_plan);
        ELSE
            INSERT IGNORE INTO ENCOUNTER (encounter_id, health_id, hospital_id, encounter_date_time, encounter_type,
                                   chief_complaint, examination_notes, treatment_plan)
            VALUES (i, v_health_id, v_hospital_idx, v_enc_date, v_enc_type,
                    v_complaint, v_notes, v_plan);
        END IF;

        SET i = i + 1;
    END WHILE;

    -- ========================================================
    -- 8. ENCOUNTER-DOCTOR ASSIGNMENTS (one primary per encounter)
    --    ~350 assignments for encounters 8-327
    -- ========================================================
    SET i = 8;
    WHILE i <= 327 DO
        -- Primary doctor - pick from all 38 doctors
        SET v_doctor_idx = FLOOR(1 + RAND() * 38);

        INSERT IGNORE INTO ENCOUNTER_DOCTOR (encounter_id, doctor_id, role, assigned_time, is_primary)
        VALUES (i, v_doctor_idx,
                ELT(FLOOR(1+RAND()*4), 'Attending Physician','Primary Care','Treating Doctor','Duty Physician'),
                (SELECT encounter_date_time FROM ENCOUNTER WHERE encounter_id = i),
                TRUE);

        -- 30% chance of a second (consulting) doctor
        IF RAND() < 0.3 THEN
            SET v_rand = FLOOR(1 + RAND() * 38);
            -- Make sure we don't duplicate the primary doctor
            IF v_rand <> v_doctor_idx THEN
                INSERT IGNORE INTO ENCOUNTER_DOCTOR (encounter_id, doctor_id, role, assigned_time, is_primary)
                VALUES (i, v_rand,
                        ELT(FLOOR(1+RAND()*4), 'Consultant','Specialist','Assisting Physician','Second Opinion'),
                        (SELECT DATE_ADD(encounter_date_time, INTERVAL FLOOR(RAND()*120) MINUTE) FROM ENCOUNTER WHERE encounter_id = i),
                        FALSE);
            END IF;
        END IF;

        SET i = i + 1;
    END WHILE;

    -- ========================================================
    -- 9. VITAL SIGNS for encounters 8-327
    --    ~320 vitals readings
    -- ========================================================
    SET i = 8;
    WHILE i <= 327 DO
        SET v_bp_sys = 100 + FLOOR(RAND() * 60);
        SET v_bp_dia = 55 + FLOOR(RAND() * 45);
        SET v_pulse = 55 + FLOOR(RAND() * 55);
        SET v_temp = 36.0 + ROUND(RAND() * 3.0, 1);
        IF v_temp > 42.0 THEN SET v_temp = 39.5; END IF;
        SET v_rr = 12 + FLOOR(RAND() * 14);
        SET v_height = 140.00 + ROUND(RAND() * 50, 2);
        SET v_weight = 40.00 + ROUND(RAND() * 70, 2);
        SET v_o2 = 92 + FLOOR(RAND() * 9);
        IF v_o2 > 100 THEN SET v_o2 = 99; END IF;

        INSERT IGNORE INTO VITAL_SIGNS (encounter_id, reading_timestamp, bp_systolic, bp_diastolic,
                                        pulse, temperature, respiratory_rate, height, weight, oxygen_saturation)
        VALUES (i,
                (SELECT DATE_ADD(encounter_date_time, INTERVAL FLOOR(5+RAND()*20) MINUTE) FROM ENCOUNTER WHERE encounter_id = i),
                v_bp_sys, v_bp_dia, v_pulse, v_temp, v_rr, v_height, v_weight, v_o2);

        SET i = i + 1;
    END WHILE;

    -- ========================================================
    -- 10. ENCOUNTER DIAGNOSES (~300 diagnoses)
    -- ========================================================
    SET i = 8;
    WHILE i <= 327 DO
        SET v_rand = FLOOR(1 + RAND() * 10);

        INSERT IGNORE INTO ENCOUNTER_DIAGNOSIS (encounter_id, icd10_code, diagnosis_type, status, diagnosed_date)
        VALUES (
            i,
            ELT(v_rand, 'J06.9','I10','E11.9','J18.9','K21.0','M54.5','J45.20','N39.0','R50.9','G43.909'),
            ELT(FLOOR(1+RAND()*3), 'Primary','Secondary','Provisional'),
            ELT(FLOOR(1+RAND()*3), 'Active','Resolved','Ruled Out'),
            (SELECT DATE(encounter_date_time) FROM ENCOUNTER WHERE encounter_id = i)
        );

        -- 35% chance of secondary diagnosis
        IF RAND() < 0.35 THEN
            SET v_rand2 = FLOOR(1 + RAND() * 10);
            IF v_rand2 <> v_rand THEN
                INSERT IGNORE INTO ENCOUNTER_DIAGNOSIS (encounter_id, icd10_code, diagnosis_type, status, diagnosed_date)
                VALUES (
                    i,
                    ELT(v_rand2, 'J06.9','I10','E11.9','J18.9','K21.0','M54.5','J45.20','N39.0','R50.9','G43.909'),
                    'Secondary',
                    'Active',
                    (SELECT DATE(encounter_date_time) FROM ENCOUNTER WHERE encounter_id = i)
                );
            END IF;
        END IF;

        SET i = i + 1;
    END WHILE;

    -- ========================================================
    -- 11. ENCOUNTER PROCEDURES (~80 procedures)
    -- ========================================================
    SET i = 0;
    WHILE i < 80 DO
        SET v_enc_id = 8 + FLOOR(RAND() * 320);
        SET v_doctor_idx = FLOOR(1 + RAND() * 38);
        SET v_rand = FLOOR(1 + RAND() * 10);

        INSERT IGNORE INTO ENCOUNTER_PROCEDURE (encounter_id, cpt_code, sequence_number, procedure_date,
                                                performing_doctor_id, procedure_notes, complications)
        VALUES (
            v_enc_id,
            ELT(v_rand, '99213','99214','99215','99281','99285','36415','71046','93000','80053','85025'),
            1,
            (SELECT DATE(encounter_date_time) FROM ENCOUNTER WHERE encounter_id = v_enc_id),
            v_doctor_idx,
            ELT(FLOOR(1+RAND()*5),
                'Procedure completed without complications',
                'Patient tolerated procedure well',
                'Standard protocol followed, results pending',
                'Procedure performed under local anesthesia',
                'Routine procedure, no adverse events'),
            NULL
        );

        SET i = i + 1;
    END WHILE;

    -- ========================================================
    -- 12. PRESCRIPTIONS (~100 prescriptions with items)
    --     Starting from prescription_id = 6
    --     AVOID allergy conflicts:
    --       HID-001 allergic to Penicillin (med_id=1 Amoxicillin)
    --       HID-003 has NSAIDs allergy in existing data
    --       HID-002 allergic to Aspirin (med_id=12)
    --       HID-004 allergic to Ibuprofen (med_id=7)
    -- ========================================================
    SET v_pres_id = 6;
    SET i = 0;
    WHILE i < 100 DO
        -- Pick a random encounter from new ones
        SET v_enc_id = 8 + FLOOR(RAND() * 320);
        SET v_doctor_idx = FLOOR(1 + RAND() * 38);

        -- Get encounter date for prescription dates
        SET @enc_dt = NULL;
        SELECT DATE(encounter_date_time) INTO @enc_dt FROM ENCOUNTER WHERE encounter_id = v_enc_id;

        IF @enc_dt IS NOT NULL THEN
            INSERT IGNORE INTO PRESCRIPTION (prescription_id, encounter_id, doctor_id, prescription_date,
                                      start_date, end_date, status)
            VALUES (
                v_pres_id, v_enc_id, v_doctor_idx, @enc_dt,
                @enc_dt,
                DATE_ADD(@enc_dt, INTERVAL (FLOOR(7 + RAND() * 173)) DAY),
                ELT(FLOOR(1+RAND()*4), 'Active','Completed','Completed','Active')
            );

            -- Add 1-2 prescription items
            -- Use safe medications: 2 (Metformin), 3 (Lisinopril), 4 (Atorvastatin),
            -- 5 (Omeprazole), 6 (Amlodipine), 8 (Paracetamol), 9 (Ciprofloxacin), 10 (Salbutamol)
            SET v_rand = FLOOR(1 + RAND() * 8);
            SET v_med_id = ELT(v_rand, 2, 3, 4, 5, 6, 8, 9, 10);

            INSERT IGNORE INTO PRESCRIPTION_ITEM (prescription_id, medication_id, dosage_strength, dosage_form,
                                                  frequency, duration_days, quantity_dispensed, instructions)
            VALUES (
                v_pres_id, v_med_id,
                ELT(FLOOR(1+RAND()*5), '250mg','500mg','10mg','20mg','5mg'),
                ELT(FLOOR(1+RAND()*4), 'Tablet','Capsule','Syrup','Inhaler'),
                ELT(FLOOR(1+RAND()*5), 'Once daily','Twice daily','Three times daily','Every 8 hours','As needed'),
                FLOOR(5 + RAND() * 85),
                FLOOR(10 + RAND() * 170),
                ELT(FLOOR(1+RAND()*5),
                    'Take with food',
                    'Take on empty stomach',
                    'Take after meals with water',
                    'Do not crush or chew',
                    'Shake well before use')
            );

            -- 40% chance of a second item
            IF RAND() < 0.4 THEN
                SET v_rand = FLOOR(1 + RAND() * 8);
                SET v_rand2 = ELT(v_rand, 2, 3, 4, 5, 6, 8, 9, 10);
                IF v_rand2 <> v_med_id THEN
                    INSERT IGNORE INTO PRESCRIPTION_ITEM (prescription_id, medication_id, dosage_strength, dosage_form,
                                                          frequency, duration_days, quantity_dispensed, instructions)
                    VALUES (
                        v_pres_id, v_rand2,
                        ELT(FLOOR(1+RAND()*5), '250mg','500mg','10mg','20mg','5mg'),
                        ELT(FLOOR(1+RAND()*4), 'Tablet','Capsule','Syrup','Inhaler'),
                        ELT(FLOOR(1+RAND()*5), 'Once daily','Twice daily','Three times daily','Every 8 hours','As needed'),
                        FLOOR(5 + RAND() * 85),
                        FLOOR(10 + RAND() * 170),
                        ELT(FLOOR(1+RAND()*5),
                            'Take with food',
                            'Take on empty stomach',
                            'Take after meals with water',
                            'Do not crush or chew',
                            'Avoid alcohol')
                    );
                END IF;
            END IF;

            SET v_pres_id = v_pres_id + 1;
        END IF;

        SET i = i + 1;
    END WHILE;

    -- ========================================================
    -- 13. LAB ORDERS (~100 lab orders) and LAB RESULTS
    --     Starting from lab_order_id = 9
    -- ========================================================
    SET v_lab_id = 9;
    SET i = 0;
    WHILE i < 100 DO
        SET v_enc_id = 8 + FLOOR(RAND() * 320);
        SET v_doctor_idx = FLOOR(1 + RAND() * 38);

        SET v_rand = FLOOR(1 + RAND() * 10);
        SET v_test_code = ELT(v_rand, 'CBC','BMP','CMP','LFT','TSH','HBA1C','LIPID','UA','BG','PT_INR');

        SET @enc_dt2 = NULL;
        SELECT encounter_date_time INTO @enc_dt2 FROM ENCOUNTER WHERE encounter_id = v_enc_id;

        IF @enc_dt2 IS NOT NULL THEN
            INSERT IGNORE INTO LAB_ORDER (lab_order_id, encounter_id, doctor_id, test_code, order_date_time,
                                   priority, clinical_info, order_status, specimen_id, specimen_collected_at)
            VALUES (
                v_lab_id, v_enc_id, v_doctor_idx, v_test_code,
                DATE_ADD(@enc_dt2, INTERVAL FLOOR(15+RAND()*60) MINUTE),
                ELT(FLOOR(1+RAND()*3), 'Routine','Urgent','Stat'),
                ELT(FLOOR(1+RAND()*6),
                    'Routine screening',
                    'Follow-up monitoring',
                    'Evaluate current symptoms',
                    'Pre-operative assessment',
                    'Annual health check',
                    'Assess treatment response'),
                ELT(FLOOR(1+RAND()*3), 'Completed','Completed','In Progress'),
                CONCAT('SPEC-', DATE_FORMAT(@enc_dt2, '%Y%m%d'), '-', LPAD(v_lab_id, 3, '0')),
                DATE_ADD(@enc_dt2, INTERVAL FLOOR(30+RAND()*120) MINUTE)
            );

            -- Create lab result for ~85% of orders
            IF RAND() < 0.85 THEN
                SET v_rand2 = FLOOR(RAND() * 100);
                -- Determine abnormal/critical flags
                -- ~25% abnormal, ~5% critical (critical requires abnormal)
                IF v_rand2 < 5 THEN
                    -- Critical (must also be abnormal)
                    INSERT IGNORE INTO LAB_RESULT (lab_order_id, result_value, result_unit, reference_range,
                                           abnormal_flag, critical_flag, result_date, verified_by_doctor_id,
                                           physician_acknowledged, acknowledged_at)
                    VALUES (
                        v_lab_id,
                        ELT(FLOOR(1+RAND()*5), '22000','2.8','520','0.15','450'),
                        ELT(FLOOR(1+RAND()*5), 'cells/mcL','g/dL','mg/dL','mIU/L','mg/dL'),
                        ELT(FLOOR(1+RAND()*5), '4500-11000','12-17.5','<200','0.4-4.0','<150'),
                        TRUE, TRUE,
                        DATE_ADD(@enc_dt2, INTERVAL FLOOR(2+RAND()*6) HOUR),
                        v_doctor_idx, TRUE,
                        DATE_ADD(@enc_dt2, INTERVAL FLOOR(4+RAND()*8) HOUR)
                    );
                ELSEIF v_rand2 < 25 THEN
                    -- Abnormal but not critical
                    INSERT IGNORE INTO LAB_RESULT (lab_order_id, result_value, result_unit, reference_range,
                                           abnormal_flag, critical_flag, result_date, verified_by_doctor_id,
                                           physician_acknowledged, acknowledged_at)
                    VALUES (
                        v_lab_id,
                        ELT(FLOOR(1+RAND()*5), '14500','210','8.2','6.8','165'),
                        ELT(FLOOR(1+RAND()*5), 'cells/mcL','mg/dL','%','mmol/L','mg/dL'),
                        ELT(FLOOR(1+RAND()*5), '4500-11000','<200','4.0-5.6','3.5-5.0','<150'),
                        TRUE, FALSE,
                        DATE_ADD(@enc_dt2, INTERVAL FLOOR(2+RAND()*6) HOUR),
                        v_doctor_idx, TRUE,
                        DATE_ADD(@enc_dt2, INTERVAL FLOOR(4+RAND()*12) HOUR)
                    );
                ELSE
                    -- Normal
                    INSERT IGNORE INTO LAB_RESULT (lab_order_id, result_value, result_unit, reference_range,
                                           abnormal_flag, critical_flag, result_date, verified_by_doctor_id,
                                           physician_acknowledged, acknowledged_at)
                    VALUES (
                        v_lab_id,
                        ELT(FLOOR(1+RAND()*5), '7500','140','5.2','1.0','95'),
                        ELT(FLOOR(1+RAND()*5), 'cells/mcL','mEq/L','%','mg/dL','mg/dL'),
                        ELT(FLOOR(1+RAND()*5), '4500-11000','136-145','4.0-5.6','0.7-1.3','70-110'),
                        FALSE, FALSE,
                        DATE_ADD(@enc_dt2, INTERVAL FLOOR(2+RAND()*6) HOUR),
                        v_doctor_idx, TRUE,
                        DATE_ADD(@enc_dt2, INTERVAL FLOOR(6+RAND()*18) HOUR)
                    );
                END IF;
            END IF;

            SET v_lab_id = v_lab_id + 1;
        END IF;

        SET i = i + 1;
    END WHILE;

    -- ========================================================
    -- 14. CONSENTS (~50 new consents)
    -- ========================================================
    SET i = 0;
    WHILE i < 50 DO
        SET v_patient_idx = 9 + FLOOR(RAND() * 100);
        SET v_health_id = CONCAT('HID-', LPAD(v_patient_idx, 3, '0'));
        SET v_hospital_idx = FLOOR(1 + RAND() * 10);

        SET v_rand = FLOOR(1 + RAND() * 3);
        SET v_days_offset = FLOOR(RAND() * 900);

        INSERT IGNORE INTO CONSENT (health_id, hospital_id, access_level, purpose,
                                    effective_date, expiration_date, status)
        VALUES (
            v_health_id, v_hospital_idx,
            ELT(v_rand, 'Basic','Restricted','Full'),
            ELT(FLOOR(1+RAND()*5),
                'Ongoing treatment and care',
                'Specialist consultation',
                'Insurance processing and claims',
                'Research study participation',
                'Second opinion and referral'),
            DATE_ADD('2023-06-01', INTERVAL v_days_offset DAY),
            DATE_ADD('2025-06-01', INTERVAL v_days_offset + FLOOR(365+RAND()*730) DAY),
            ELT(FLOOR(1+RAND()*3), 'Active','Active','Expired')
        );

        SET i = i + 1;
    END WHILE;

    -- ========================================================
    -- 15. APP_USERS - 15 doctor users and 15 patient users
    --     Starting from next available user_id
    -- ========================================================

    -- Doctor users for doctors 9-23
    SET v_user_id = (SELECT IFNULL(MAX(user_id), 0) + 1 FROM APP_USER);
    SET v_doc_id = 9;
    WHILE v_doc_id <= 23 DO
        SET @dname = NULL;
        SELECT LOWER(REPLACE(REPLACE(name, 'Dr. ', ''), ' ', '.')) INTO @dname
        FROM DOCTOR WHERE doctor_id = v_doc_id;

        IF @dname IS NOT NULL THEN
            INSERT IGNORE INTO APP_USER (user_id, username, password_hash, role, status)
            VALUES (v_user_id, @dname, v_bcrypt_hash, 'doctor', 'Active');

            INSERT IGNORE INTO DOCTOR_USER (user_id, doctor_id)
            VALUES (v_user_id, v_doc_id);

            SET v_user_id = v_user_id + 1;
        END IF;

        SET v_doc_id = v_doc_id + 1;
    END WHILE;

    -- Patient users (next 15 user IDs for patients HID-009 to HID-023)
    SET i = 9;
    WHILE i <= 23 DO
        SET v_health_id = CONCAT('HID-', LPAD(i, 3, '0'));

        SET @pfname = NULL;
        SET @plname = NULL;
        SELECT LOWER(fname), LOWER(lname) INTO @pfname, @plname
        FROM PATIENT WHERE health_id = v_health_id;

        IF @pfname IS NOT NULL THEN
            SET v_username = CONCAT(@pfname, '.', @plname);

            INSERT IGNORE INTO APP_USER (user_id, username, password_hash, role, status)
            VALUES (v_user_id, v_username, v_bcrypt_hash, 'patient', 'Active');

            INSERT IGNORE INTO PATIENT_USER (user_id, health_id)
            VALUES (v_user_id, v_health_id);

            SET v_user_id = v_user_id + 1;
        END IF;

        SET i = i + 1;
    END WHILE;

    -- A few nurse and pharmacist users
    INSERT IGNORE INTO APP_USER (user_id, username, password_hash, role, status) VALUES
    (v_user_id,     'nurse.rekha',     v_bcrypt_hash, 'nurse',      'Active'),
    (v_user_id + 1, 'nurse.sunil',     v_bcrypt_hash, 'nurse',      'Active'),
    (v_user_id + 2, 'nurse.geeta',     v_bcrypt_hash, 'nurse',      'Active'),
    (v_user_id + 3, 'pharma.arun',     v_bcrypt_hash, 'pharmacist', 'Active'),
    (v_user_id + 4, 'pharma.kavitha',  v_bcrypt_hash, 'pharmacist', 'Active');

    SET v_user_id = v_user_id + 5;

    -- ========================================================
    -- 16. LOGIN ATTEMPTS (~50 entries)
    -- ========================================================
    SET i = 0;
    WHILE i < 50 DO
        SET v_rand = FLOOR(1 + RAND() * 20);
        SET v_username = ELT(v_rand,
            'admin','dr.anil','dr.priya','rahul.verma','ananya.singh',
            'dr.rajesh','dr.sneha','aarav.sharma','vivaan.gupta','aditya.verma',
            'sai.reddy','rohan.iyer','ishaan.bhat','kabir.singh','ananya.das',
            'unknown_user','hacker123','test_account','nurse.rekha','pharma.arun');

        SET v_days_offset = FLOOR(RAND() * 365);

        INSERT IGNORE INTO LOGIN_ATTEMPT (username, attempt_time, ip_address, device_type, success)
        VALUES (
            v_username,
            DATE_ADD('2025-03-01', INTERVAL v_days_offset DAY) + INTERVAL FLOOR(RAND()*24) HOUR + INTERVAL FLOOR(RAND()*60) MINUTE,
            CONCAT(
                FLOOR(10 + RAND() * 240), '.',
                FLOOR(RAND() * 256), '.',
                FLOOR(RAND() * 256), '.',
                FLOOR(1 + RAND() * 254)
            ),
            ELT(FLOOR(1+RAND()*5), 'Chrome/Windows','Safari/macOS','Firefox/Linux','Mobile/Android','Mobile/iOS'),
            IF(v_rand <= 15, TRUE, IF(RAND() < 0.3, TRUE, FALSE))
        );

        SET i = i + 1;
    END WHILE;

    -- ========================================================
    -- 17. ADDITIONAL AUDIT LOG ENTRIES
    --     (inserted via direct INSERT; hash chain trigger handles hashing)
    -- ========================================================
    INSERT INTO AUDIT_LOG (user_id, action_type, table_name, notes, event_time) VALUES
    (1, 'BULK_SEED', 'ALL', 'Extended seed data batch loaded - 100 patients', NOW()),
    (1, 'BULK_SEED', 'ALL', 'Extended seed data batch loaded - 30 doctors', NOW()),
    (1, 'BULK_SEED', 'ALL', 'Extended seed data batch loaded - 5 hospitals', NOW()),
    (1, 'BULK_SEED', 'ALL', 'Extended seed data batch loaded - 320 encounters', NOW()),
    (1, 'BULK_SEED', 'ALL', 'Extended seed data batch loaded - prescriptions and labs', NOW());

END //
DELIMITER ;

CALL sp_generate_seed_data();
DROP PROCEDURE IF EXISTS sp_generate_seed_data;
