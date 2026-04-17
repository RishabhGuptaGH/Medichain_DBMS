-- ============================================================
-- MediChain Schema (cloud variant)
-- Identical to schema.sql WITHOUT `CREATE DATABASE` / `USE` so it
-- can be applied to a cloud-hosted DB whose name is fixed by the
-- provider (Aiven, Clever Cloud, Railway, FreeSQLDatabase, etc.).
-- The mysql client is invoked with the target db on the command
-- line, so no USE statement is needed.
-- ============================================================

-- ============================================================
-- CATALOG / REFERENCE TABLES
-- ============================================================

CREATE TABLE DIAGNOSIS_CODE (
    icd10_code VARCHAR(20) PRIMARY KEY,
    description TEXT NOT NULL,
    category VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE PROCEDURE_CODE (
    cpt_code VARCHAR(20) PRIMARY KEY,
    description TEXT NOT NULL,
    category VARCHAR(100),
    base_cost DECIMAL(10,2),
    CONSTRAINT chk_proc_cost CHECK (base_cost IS NULL OR base_cost >= 0)
) ENGINE=InnoDB;

CREATE TABLE MEDICATION (
    medication_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    generic_name VARCHAR(255) NOT NULL,
    brand_name VARCHAR(255),
    drug_class VARCHAR(100),
    manufacturer VARCHAR(255),
    UNIQUE KEY uq_medication (generic_name, brand_name)
) ENGINE=InnoDB;

CREATE TABLE LAB_TEST_CATALOG (
    test_code VARCHAR(50) PRIMARY KEY,
    test_name VARCHAR(255) NOT NULL,
    specimen_type VARCHAR(100),
    collection_procedure TEXT
) ENGINE=InnoDB;

CREATE TABLE DRUG_INTERACTION (
    medication_id_1 BIGINT NOT NULL,
    medication_id_2 BIGINT NOT NULL,
    interaction_description TEXT,
    severity ENUM('Mild','Moderate','Severe','Life-threatening') NOT NULL,
    recommendation TEXT,
    PRIMARY KEY (medication_id_1, medication_id_2),
    FOREIGN KEY (medication_id_1) REFERENCES MEDICATION(medication_id) ON UPDATE CASCADE,
    FOREIGN KEY (medication_id_2) REFERENCES MEDICATION(medication_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- CORE ENTITY TABLES
-- ============================================================

CREATE TABLE PATIENT (
    health_id VARCHAR(50) PRIMARY KEY,
    fname VARCHAR(100) NOT NULL,
    mname VARCHAR(100),
    lname VARCHAR(100) NOT NULL,
    address_street VARCHAR(255),
    address_city VARCHAR(100),
    address_state VARCHAR(100),
    postal_code VARCHAR(20),
    date_of_birth DATE NOT NULL,
    gender ENUM('M','F','O') NOT NULL,
    blood_group ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-'),
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    insurance_provider VARCHAR(255),
    insurance_start DATE,
    insurance_end DATE,
    policy_type VARCHAR(100),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_insurance_dates CHECK (
        insurance_end IS NULL OR insurance_start IS NULL OR insurance_end >= insurance_start
    )
) ENGINE=InnoDB;

CREATE TABLE PATIENT_ALLERGY (
    allergy_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    health_id VARCHAR(50) NOT NULL,
    allergen VARCHAR(255) NOT NULL,
    reaction_description TEXT,
    severity ENUM('Mild','Moderate','Severe','Life-threatening') NOT NULL DEFAULT 'Moderate',
    identified_date DATE,
    status ENUM('Active','Inactive','Resolved') NOT NULL DEFAULT 'Active',
    FOREIGN KEY (health_id) REFERENCES PATIENT(health_id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE HOSPITAL (
    hospital_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    hospital_name VARCHAR(255) NOT NULL,
    license_number VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    email VARCHAR(100),
    bed_capacity INT,
    address_street VARCHAR(255),
    address_city VARCHAR(100),
    address_state VARCHAR(100),
    postal_code VARCHAR(20),
    facility_type ENUM('General Hospital','Specialty Hospital','Teaching Hospital','Trauma Center','Primary Health Center') DEFAULT 'General Hospital',
    CONSTRAINT chk_bed_cap CHECK (bed_capacity IS NULL OR bed_capacity >= 0)
) ENGINE=InnoDB;

CREATE TABLE DEPARTMENT (
    department_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    hospital_id BIGINT NOT NULL,
    department_name VARCHAR(100) NOT NULL,
    UNIQUE KEY uq_dept (hospital_id, department_name),
    FOREIGN KEY (hospital_id) REFERENCES HOSPITAL(hospital_id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE DOCTOR (
    doctor_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    medical_license_number VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    email VARCHAR(100),
    date_of_birth DATE,
    specialization VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE DOCTOR_HOSPITAL (
    doctor_id BIGINT NOT NULL,
    hospital_id BIGINT NOT NULL,
    join_date DATE NOT NULL,
    end_date DATE,
    status ENUM('Active','Inactive','On Leave') DEFAULT 'Active',
    PRIMARY KEY (doctor_id, hospital_id),
    CONSTRAINT chk_dh_dates CHECK (end_date IS NULL OR end_date >= join_date),
    FOREIGN KEY (doctor_id) REFERENCES DOCTOR(doctor_id) ON UPDATE CASCADE,
    FOREIGN KEY (hospital_id) REFERENCES HOSPITAL(hospital_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- CLINICAL ENCOUNTER TABLES
-- ============================================================

CREATE TABLE ENCOUNTER (
    encounter_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    health_id VARCHAR(50) NOT NULL,
    hospital_id BIGINT,
    encounter_date_time DATETIME NOT NULL,
    encounter_type ENUM('Outpatient','Inpatient','Emergency','Follow-up') NOT NULL,
    admission_date_time DATETIME,
    discharge_date_time DATETIME,
    bed_number VARCHAR(20),
    chief_complaint TEXT,
    examination_notes TEXT,
    treatment_plan TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_discharge CHECK (
        discharge_date_time IS NULL OR admission_date_time IS NULL OR discharge_date_time >= admission_date_time
    ),
    CONSTRAINT chk_inpatient_admission CHECK (
        encounter_type <> 'Inpatient' OR admission_date_time IS NOT NULL
    ),
    CONSTRAINT chk_inpatient_bed CHECK (
        encounter_type <> 'Inpatient' OR bed_number IS NOT NULL
    ),
    FOREIGN KEY (health_id) REFERENCES PATIENT(health_id) ON UPDATE CASCADE,
    FOREIGN KEY (hospital_id) REFERENCES HOSPITAL(hospital_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE ENCOUNTER_DOCTOR (
    encounter_id BIGINT NOT NULL,
    doctor_id BIGINT NOT NULL,
    role VARCHAR(50),
    assigned_time DATETIME,
    is_primary BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (encounter_id, doctor_id),
    FOREIGN KEY (encounter_id) REFERENCES ENCOUNTER(encounter_id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES DOCTOR(doctor_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE VITAL_SIGNS (
    encounter_id BIGINT NOT NULL,
    reading_timestamp DATETIME NOT NULL,
    bp_systolic INT,
    bp_diastolic INT,
    pulse INT,
    temperature DECIMAL(4,1),
    respiratory_rate INT,
    height DECIMAL(5,2),
    weight DECIMAL(5,2),
    oxygen_saturation INT,
    PRIMARY KEY (encounter_id, reading_timestamp),
    CONSTRAINT chk_bp_sys CHECK (bp_systolic IS NULL OR (bp_systolic BETWEEN 50 AND 250)),
    CONSTRAINT chk_bp_dia CHECK (bp_diastolic IS NULL OR (bp_diastolic BETWEEN 30 AND 150)),
    CONSTRAINT chk_pulse CHECK (pulse IS NULL OR (pulse BETWEEN 20 AND 250)),
    CONSTRAINT chk_temp CHECK (temperature IS NULL OR (temperature BETWEEN 30.0 AND 45.0)),
    CONSTRAINT chk_rr CHECK (respiratory_rate IS NULL OR (respiratory_rate BETWEEN 5 AND 60)),
    CONSTRAINT chk_height CHECK (height IS NULL OR (height BETWEEN 30 AND 250)),
    CONSTRAINT chk_weight CHECK (weight IS NULL OR (weight BETWEEN 1 AND 500)),
    CONSTRAINT chk_o2 CHECK (oxygen_saturation IS NULL OR (oxygen_saturation BETWEEN 50 AND 100)),
    FOREIGN KEY (encounter_id) REFERENCES ENCOUNTER(encounter_id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE ENCOUNTER_DIAGNOSIS (
    encounter_id BIGINT NOT NULL,
    icd10_code VARCHAR(20) NOT NULL,
    diagnosis_type ENUM('Primary','Secondary','Provisional') NOT NULL,
    status ENUM('Active','Resolved','Ruled Out') NOT NULL DEFAULT 'Active',
    diagnosed_date DATE,
    PRIMARY KEY (encounter_id, icd10_code),
    FOREIGN KEY (encounter_id) REFERENCES ENCOUNTER(encounter_id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (icd10_code) REFERENCES DIAGNOSIS_CODE(icd10_code) ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE ENCOUNTER_PROCEDURE (
    encounter_id BIGINT NOT NULL,
    cpt_code VARCHAR(20) NOT NULL,
    sequence_number INT NOT NULL,
    procedure_date DATE,
    performing_doctor_id BIGINT,
    procedure_notes TEXT,
    complications TEXT,
    PRIMARY KEY (encounter_id, cpt_code, sequence_number),
    CONSTRAINT chk_seq CHECK (sequence_number >= 1),
    FOREIGN KEY (encounter_id) REFERENCES ENCOUNTER(encounter_id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (cpt_code) REFERENCES PROCEDURE_CODE(cpt_code) ON UPDATE CASCADE,
    FOREIGN KEY (performing_doctor_id) REFERENCES DOCTOR(doctor_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- PRESCRIPTION TABLES
-- ============================================================

CREATE TABLE PRESCRIPTION (
    prescription_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    encounter_id BIGINT NOT NULL,
    doctor_id BIGINT NOT NULL,
    prescription_date DATE,
    start_date DATE,
    end_date DATE,
    status ENUM('Active','Completed','Discontinued','Cancelled') DEFAULT 'Active',
    override_reason TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_rx_dates CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date),
    FOREIGN KEY (encounter_id) REFERENCES ENCOUNTER(encounter_id) ON UPDATE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES DOCTOR(doctor_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE PRESCRIPTION_ITEM (
    prescription_id BIGINT NOT NULL,
    medication_id BIGINT NOT NULL,
    dosage_strength VARCHAR(50),
    dosage_form VARCHAR(50),
    frequency VARCHAR(100),
    duration_days INT,
    quantity_dispensed INT,
    instructions TEXT,
    allergy_override BOOLEAN DEFAULT FALSE,
    interaction_override BOOLEAN DEFAULT FALSE,
    override_justification TEXT,
    PRIMARY KEY (prescription_id, medication_id),
    CONSTRAINT chk_duration CHECK (duration_days IS NULL OR duration_days >= 0),
    CONSTRAINT chk_qty CHECK (quantity_dispensed IS NULL OR quantity_dispensed >= 0),
    FOREIGN KEY (prescription_id) REFERENCES PRESCRIPTION(prescription_id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES MEDICATION(medication_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- LABORATORY TABLES
-- ============================================================

CREATE TABLE LAB_ORDER (
    lab_order_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    encounter_id BIGINT NOT NULL,
    doctor_id BIGINT NOT NULL,
    test_code VARCHAR(50) NOT NULL,
    order_date_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    priority ENUM('Routine','Urgent','Stat') NOT NULL DEFAULT 'Routine',
    clinical_info TEXT,
    order_status ENUM('Pending','In Progress','Completed','Cancelled') DEFAULT 'Pending',
    specimen_id VARCHAR(50),
    specimen_collected_at DATETIME,
    FOREIGN KEY (encounter_id) REFERENCES ENCOUNTER(encounter_id) ON UPDATE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES DOCTOR(doctor_id) ON UPDATE CASCADE,
    FOREIGN KEY (test_code) REFERENCES LAB_TEST_CATALOG(test_code) ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE LAB_RESULT (
    result_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    lab_order_id BIGINT NOT NULL,
    result_value VARCHAR(100),
    result_unit VARCHAR(50),
    reference_range VARCHAR(100),
    abnormal_flag BOOLEAN DEFAULT FALSE,
    critical_flag BOOLEAN DEFAULT FALSE,
    result_date DATETIME,
    verified_by_doctor_id BIGINT,
    physician_acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_at DATETIME,
    CONSTRAINT chk_critical CHECK (NOT critical_flag OR abnormal_flag),
    FOREIGN KEY (lab_order_id) REFERENCES LAB_ORDER(lab_order_id) ON UPDATE CASCADE,
    FOREIGN KEY (verified_by_doctor_id) REFERENCES DOCTOR(doctor_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- CONSENT AND ACCESS CONTROL
-- ============================================================

CREATE TABLE CONSENT (
    consent_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    health_id VARCHAR(50) NOT NULL,
    hospital_id BIGINT NOT NULL,
    access_level ENUM('Basic','Restricted','Full') NOT NULL,
    purpose TEXT,
    effective_date DATE NOT NULL,
    expiration_date DATE,
    revoked_date DATE,
    status ENUM('Active','Expired','Revoked') DEFAULT 'Active',
    created_timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_consent_exp CHECK (expiration_date IS NULL OR expiration_date >= effective_date),
    CONSTRAINT chk_consent_rev CHECK (revoked_date IS NULL OR revoked_date >= effective_date),
    CONSTRAINT chk_consent_status CHECK (status <> 'Revoked' OR revoked_date IS NOT NULL),
    FOREIGN KEY (health_id) REFERENCES PATIENT(health_id) ON UPDATE CASCADE,
    FOREIGN KEY (hospital_id) REFERENCES HOSPITAL(hospital_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE EMERGENCY_ACCESS (
    access_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    health_id VARCHAR(50) NOT NULL,
    doctor_id BIGINT NOT NULL,
    access_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    emergency_type VARCHAR(100) NOT NULL,
    justification TEXT NOT NULL,
    records_accessed TEXT,
    duration_minutes INT,
    review_status ENUM('Pending Review','Approved','Flagged') DEFAULT 'Pending Review',
    reviewed_by BIGINT,
    reviewed_at DATETIME,
    FOREIGN KEY (health_id) REFERENCES PATIENT(health_id) ON UPDATE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES DOCTOR(doctor_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE ACCESS_REQUEST (
    request_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    health_id VARCHAR(50) NOT NULL,
    doctor_id BIGINT NOT NULL,
    request_reason TEXT NOT NULL,
    access_level ENUM('Basic','Restricted','Full') NOT NULL DEFAULT 'Full',
    request_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('Pending','Approved','Denied') DEFAULT 'Pending',
    responded_at DATETIME,
    expiration_date DATE,
    FOREIGN KEY (health_id) REFERENCES PATIENT(health_id) ON UPDATE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES DOCTOR(doctor_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- USER AND AUTH TABLES
-- ============================================================

CREATE TABLE APP_USER (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('patient','doctor','admin','nurse','pharmacist') NOT NULL DEFAULT 'patient',
    status ENUM('Active','Inactive','Locked') DEFAULT 'Active',
    created_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login DATETIME
) ENGINE=InnoDB;

CREATE TABLE PATIENT_USER (
    user_id BIGINT PRIMARY KEY,
    health_id VARCHAR(50) NOT NULL UNIQUE,
    FOREIGN KEY (user_id) REFERENCES APP_USER(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (health_id) REFERENCES PATIENT(health_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE DOCTOR_USER (
    user_id BIGINT PRIMARY KEY,
    doctor_id BIGINT NOT NULL UNIQUE,
    FOREIGN KEY (user_id) REFERENCES APP_USER(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES DOCTOR(doctor_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE ADMIN_USER (
    user_id BIGINT PRIMARY KEY,
    FOREIGN KEY (user_id) REFERENCES APP_USER(user_id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- AUDIT LOG TABLE
-- ============================================================

CREATE TABLE AUDIT_LOG (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT,
    action_type VARCHAR(50) NOT NULL,
    table_name VARCHAR(100),
    record_id VARCHAR(100),
    old_value TEXT,
    new_value TEXT,
    event_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    workstation VARCHAR(100),
    notes TEXT,
    hash_value VARCHAR(255),
    prev_hash VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES APP_USER(user_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- LOGIN ATTEMPT LOG
-- ============================================================

CREATE TABLE LOGIN_ATTEMPT (
    attempt_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100),
    attempt_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    device_type VARCHAR(100),
    success BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB;
