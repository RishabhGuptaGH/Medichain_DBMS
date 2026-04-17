# MediChain — Free Cloud Database Hosting

This guide lets anyone on the internet connect to the same MediChain
database from their own machine. You pay nothing; they install nothing
except Java + Maven and the project source.

## Architecture

```
  ┌──────────────────────────┐         ┌──────────────────────────┐
  │   Your classmate's PC    │         │   Another classmate      │
  │  run-cloud.bat  ────┐    │         │   run-cloud.bat  ────┐   │
  │  localhost:8080     │    │         │   localhost:8080     │   │
  └─────────────────────┼────┘         └──────────────────────┼───┘
                        │                                     │
                        └──────────────┬──────────────────────┘
                                       ▼
                         ┌──────────────────────────┐
                         │  Free-tier MySQL 8 host  │
                         │   (Aiven / Clever / …)   │
                         └──────────────────────────┘
```

Each person runs the Spring Boot backend locally on port 8080 and opens
the frontend at `http://localhost:8080`. All backends talk to one shared
MySQL database in the cloud.

## Recommended provider — Aiven for MySQL (Free plan)

Aiven's **Free** MySQL plan gives you a real MySQL 8 server (supports
your triggers, stored procedures, CHECK constraints, InnoDB) with no
credit card required. It is shared-tenant and ~1 GB, which is plenty
for seed_data.sql.

Alternatives if Aiven's free plan is unavailable in your region:
- **Clever Cloud** — Dev MySQL plan, free, 256 MB, 5 concurrent connections.
- **FreeSQLDatabase.com** — 5 MB free, good for smoke tests only.
- **db4free.net** — free MySQL 8 sandbox (slow, community-run).
- **Railway** — $5 free trial credit, then paid.

All of the below works with any real MySQL 8 host; only the signup
steps differ.

## Step 1 — Create the database

### Using Aiven
1. Go to <https://aiven.io/> and sign up (GitHub login works).
2. **Create service → MySQL → Free plan → pick a region close to you → name it `medichain-db`**.
3. Wait ~2 minutes for provisioning.
4. On the service page, copy the **Connection information**:
   - Host
   - Port
   - User (`avnadmin`)
   - Password
   - Database name (`defaultdb`)
5. Under **Allowed IP addresses**, add `0.0.0.0/0` so teammates can
   connect from anywhere. (For a real product you'd restrict this —
   but for a student demo it's fine.)

### Using Clever Cloud
1. Sign up at <https://www.clever-cloud.com/>.
2. **Create → Add-on → MySQL → DEV plan (free)**.
3. On the add-on page open **Information** and copy host, port, database,
   user, password.

## Step 2 — Configure your project

In the project root, copy the template and fill in the values you just
copied:

```bash
copy .env.example .env
notepad .env
```

Example filled-in `.env` for Aiven:

```
DB_HOST=medichain-db-yourname.aivencloud.com
DB_PORT=15432
DB_NAME=defaultdb
DB_USERNAME=avnadmin
DB_PASSWORD=<your-aiven-password-here>
```

> `.env` contains a live password. Add it to `.gitignore` (already done
> below) and share it with teammates through a private channel, not git.

## Step 3 — Initialise the remote schema (run ONCE)

One person — the project owner — runs this. Everyone else just points at
the already-populated DB.

Requirements on your machine:
- MySQL client (`mysql.exe`) on your PATH. If you have MySQL Workbench
  or the server installed, the client is usually at
  `C:\Program Files\MySQL\MySQL Server 8.0\bin`.

Then:

```bash
setup-cloud.bat
```

This runs, against the remote server:
1. `database/schema_cloud.sql` — creates all tables (no `CREATE DATABASE`
   since the provider pre-creates it).
2. `database/triggers.sql` — all triggers.
3. `database/procedures.sql` — all stored procedures.
4. `database/seed_data.sql` — 1000-row seed data.

## Step 4 — Run the app

Every user (you and your teammates) does:

```bash
run-cloud.bat
```

This reads `.env`, builds `jdbc:mysql://$DB_HOST:$DB_PORT/$DB_NAME?useSSL=true…`,
exports it as `DB_URL`/`DB_USERNAME`/`DB_PASSWORD`, and starts Spring
Boot. [application.properties](backend/src/main/resources/application.properties)
already reads those three env vars and falls back to localhost only if
they are unset.

Open <http://localhost:8080> and log in. Every user sees the same data
because the backend they just started is talking to the shared cloud DB.

## Sharing with others

Give your teammates:
1. The project source (zip or git repo).
2. The `.env` file (over a private channel — Slack DM, secure note, etc.).

They only need Java 17 + Maven. They run `run-cloud.bat`. They do not
need MySQL installed locally and they do not run `setup-cloud.bat`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Public Key Retrieval is not allowed` | Already handled — JDBC URL includes `allowPublicKeyRetrieval=true`. |
| `SSL connection required` | Already handled — URL forces `useSSL=true&requireSSL=true`. |
| `Unknown database 'medichain'` | Your provider's DB name is not `medichain`. Set `DB_NAME` in `.env` to the provider's default (often `defaultdb`). |
| `Access denied for user …` | Double-check `DB_USERNAME`/`DB_PASSWORD` and that your current IP is in the provider's allow list. |
| `mysql: command not found` (Step 3) | Install MySQL CLI or run the `.sql` files from MySQL Workbench's **File → Run SQL Script** against the remote connection. |
| Schema already applied, need to reset | Drop all tables on the provider's console, then re-run `setup-cloud.bat`. |
