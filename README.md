# MediChain — Healthcare Data Exchange System

A full-stack healthcare data management platform built as a DBMS course project. It centralises patient records, enforces medication safety via triggers, and maintains a tamper-proof blockchain-style audit trail — all backed by a relational MySQL database.

**Live demo:** https://medichain-backend-2gb0.onrender.com

> First load may take ~30 seconds (free-tier cold start).

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Spring Boot 3.2.5, Java 17, Spring JDBC (raw SQL) |
| Database | MySQL 8.0 — 28 tables, 12 triggers, 8 stored procedures |
| Auth | JWT (JJWT 0.12.5) + BCrypt |
| Frontend | Vanilla JS/HTML/CSS, bundled and served by Spring Boot |
| Hosting | Render (backend) + Aiven (cloud MySQL) |

---

## Run Locally

**Prerequisites:** Java 17+, Maven, MySQL 8.0 running on `localhost:3306`

### 1. Database setup
```bash
mysql -u root -ppassword < database/schema.sql
mysql -u root -ppassword < database/triggers.sql
mysql -u root -ppassword < database/procedures.sql
mysql -u root -ppassword < database/seed_data.sql
mysql -u root -ppassword < database/seed_data_1000.sql
```

This creates the `medichain` database with ~1000+ rows of realistic seed data.

### 2. Start the server
```bash
cd backend
mvn spring-boot:run
```

Open **http://localhost:8080** — the frontend is served directly by Spring Boot, no separate dev server needed.

---

## Run Against Cloud Database (Shared Aiven MySQL)

Everyone on the team connects to the same Aiven MySQL instance. No local MySQL needed.

1. Copy `.env.example` to `.env` and fill in the Aiven credentials (get from a teammate or the project owner).
2. Run:

```bash
# Windows
run-cloud.bat

# Mac / Linux
source .env
export DB_URL="jdbc:mysql://$DB_HOST:$DB_PORT/$DB_NAME?sslMode=REQUIRED&serverTimezone=UTC"
cd backend && mvn spring-boot:run
```

Open **http://localhost:8080**. Everyone shares the same data.

> Only the project owner needs to run `setup-cloud.bat` once to initialise the schema and seed data on Aiven.

---

## Login Credentials

All demo accounts use the password **`password123`**

| Role | Username | Access |
|---|---|---|
| Admin | `admin` | Full dashboard — all patients, doctors, audit log |
| Doctor | `dr.anil` | Doctor portal — own patients and orders |
| Patient | `rahul.verma` | Patient portal — own health records |

---

## Database Design

The schema covers the full patient journey from registration through discharge:

- **Patient management** — health IDs, demographics, allergies, insurance
- **Encounters** — outpatient, inpatient, emergency; vital signs, diagnoses (ICD-10), procedures (CPT)
- **Prescriptions** — allergy check + drug interaction check enforced by triggers before insert
- **Lab orders & results** — critical result alerts auto-logged via trigger
- **Consent** — patients control who sees their records; revocations are immediate
- **Audit log** — every action hashed and chained (SHA-256); triggers block any update or delete

Key files:

```
database/
  schema.sql          — DDL for all 28 tables
  schema_cloud.sql    — Same DDL without CREATE DATABASE (for hosted providers)
  triggers.sql        — 12 triggers
  procedures.sql      — 8 stored procedures
  seed_data.sql       — Base seed (~50 rows)
  seed_data_1000.sql  — Extended seed (100 patients, 38 doctors, 327 encounters)
  queries_25.sql      — 25 analytical queries covering all major features
```

---

## Project Structure

```
backend/
  src/main/java/com/medichain/
    controller/     — REST endpoints (auth, patients, doctors, encounters, …)
    dao/            — JDBC data access layer
    JwtAuthFilter   — JWT validation + role-based route protection
  src/main/resources/
    application.properties
    static/         — Bundled frontend (index.html, app.js, style.css)
```

---

## Environment Variables (Cloud Deployment)

The backend reads these from the environment — set them in Render (or any host) dashboard:

| Variable | Description |
|---|---|
| `DB_URL` | Full JDBC URL, e.g. `jdbc:mysql://host:port/db?sslMode=REQUIRED&serverTimezone=UTC` |
| `DB_USERNAME` | Database username |
| `DB_PASSWORD` | Database password |

If unset, the app falls back to `localhost:3306/medichain` with `root` / `password`.

---

## Team — Group 100, Spring 2026

| Name | Roll | Role |
|---|---|---|
| Saksham Verma | 2024497 | Database Architect & Backend Developer |
| Rishabh Gupta | 2024461 | Application Lead & Security Lead |
| Supriyo Ghosh | 2024571 | Frontend Developer & Data Engineer |

Course: Database Management Systems — Instructor: Prof. Mukesh Mohania
