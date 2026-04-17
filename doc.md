# MediChain Healthcare Data Exchange System

**DBMS Final Project — Spring 2026 — Group 100**
Saksham Verma | Rishabh Gupta | Supriyo Ghosh

---

## Prerequisites

- **Java 17+** — verify: `java -version`
- **Maven** — verify: `mvn -version`
- **MySQL 8.0** — running on `localhost:3306` with user `root` / password `password`

---

## First-Time Setup (From Scratch)

### 1. Create the Database

Open a terminal and run:

```bash
mysql -u root -ppassword < database/schema.sql
mysql -u root -ppassword < database/triggers.sql
mysql -u root -ppassword < database/procedures.sql
mysql -u root -ppassword < database/seed_data.sql
mysql -u root -ppassword < database/seed_data_1000.sql
```

This creates the `medichain` database with 28 tables, 12 triggers, 8 stored procedures, and ~2500+ rows of realistic data.

### 2. Start the Backend Server

```bash
cd "c:\Users\Rishg\OneDrive\Desktop\DBMS Final Project\backend"
mvn spring-boot:run
```

Wait until you see `Started MediChainApplication` (~10-15 seconds).

### 3. Open in Browser

Go to: **http://localhost:8080**

No separate frontend server needed — the frontend is served directly by Spring Boot.

---

## Login Credentials

Password for all accounts: **`password123`**

| Role    | Username       | What You See                        |
|---------|----------------|-------------------------------------|
| Admin   | `admin`        | Full admin dashboard with all data  |
| Doctor  | `dr.anil`      | Doctor portal (own patients/orders) |
| Patient | `rahul.verma`  | Patient portal (own health records) |

---

## How to Stop the Server

Press **Ctrl+C** in the terminal where `mvn spring-boot:run` is running.

If the terminal is closed, find and kill the process:

```bash
# Find the process using port 8080
netstat -ano | findstr 8080

# Kill it (replace <PID> with the number from above)
taskkill /PID <PID> /F
```

---

## How to Restart (After Stopping)

No need to re-run database scripts — data persists in MySQL.

```bash
cd "c:\Users\Rishg\OneDrive\Desktop\DBMS Final Project\backend"
mvn spring-boot:run
```

Then open **http://localhost:8080** in your browser.

---

## Full Reset (Nuke Everything & Start Fresh)

If you want to completely wipe the database and start over:

```bash
# Step 1: Stop the server (Ctrl+C or taskkill)

# Step 2: Drop and recreate the database
mysql -u root -ppassword -e "DROP DATABASE IF EXISTS medichain;"

# Step 3: Re-run all database scripts
cd "c:\Users\Rishg\OneDrive\Desktop\DBMS Final Project"
mysql -u root -ppassword < database/schema.sql
mysql -u root -ppassword < database/triggers.sql
mysql -u root -ppassword < database/procedures.sql
mysql -u root -ppassword < database/seed_data.sql
mysql -u root -ppassword < database/seed_data_1000.sql

# Step 4: Start the server again
cd backend
mvn spring-boot:run
```

---

## Key Features

- **Role-based login** with Admin / Doctor / Patient tabs
- **Dark mode toggle** (persists across sessions)
- **PDF export** of immutable audit log (Admin portal)
- **Patient lookup** for doctors to search any patient's medical history
- **Cross-role reflection** — actions by admin/doctor are instantly visible to the patient
- **Hash-chain audit log** — blockchain-style tamper-proof logging

---

## Database Triggers (12 Total)

### Audit Log Integrity (3 triggers)

| Trigger | Event | Purpose |
|---------|-------|---------|
| `trg_audit_log_hash_chain` | BEFORE INSERT on AUDIT_LOG | Generates SHA-256 hash chaining each new entry to the previous one (blockchain-style immutability) |
| `trg_audit_log_no_update` | BEFORE UPDATE on AUDIT_LOG | Prevents any modification to audit records |
| `trg_audit_log_no_delete` | BEFORE DELETE on AUDIT_LOG | Prevents deletion of audit records |

### Prescription Safety (3 triggers)

| Trigger | Event | Purpose |
|---------|-------|---------|
| `trg_prescription_allergy_check` | BEFORE INSERT on PRESCRIPTION_ITEM | Checks if the patient is allergic to the prescribed medication, blocks or requires override |
| `trg_prescription_drug_interaction` | BEFORE INSERT on PRESCRIPTION_ITEM | Checks for drug-drug interactions with patient's existing medications |
| `trg_drug_interaction_order` | BEFORE INSERT on PRESCRIPTION_ITEM | Ensures drug interaction severity ordering is valid |

### Clinical Safety (2 triggers)

| Trigger | Event | Purpose |
|---------|-------|---------|
| `trg_critical_lab_result` | AFTER INSERT on LAB_RESULT | If result is critical, auto-logs an alert in the audit trail |
| `trg_encounter_date_validation` | BEFORE INSERT on ENCOUNTER | Validates encounter date is not in the future and not before patient's DOB |

### Audit Trail Logging (4 triggers)

| Trigger | Event | Purpose |
|---------|-------|---------|
| `trg_emergency_access_audit` | AFTER INSERT on EMERGENCY_ACCESS | Auto-logs emergency access events to audit trail |
| `trg_patient_update_audit` | AFTER UPDATE on PATIENT | Logs any patient record modifications to audit trail |
| `trg_prescription_status_audit` | AFTER UPDATE on PRESCRIPTION | Logs prescription status changes (Active -> Completed, etc.) |
| `trg_consent_revoke` | AFTER UPDATE on CONSENT | Logs consent revocations to audit trail |
