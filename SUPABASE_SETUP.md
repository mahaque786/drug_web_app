# Supabase Database Setup

This document contains the SQL statements needed to create the required tables in your Supabase project.

## 1. Medication Logs (`medication_logs`)

Stores every dose logged via the **Dose Logger** page.

```sql
CREATE TABLE medication_logs (
  id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  timestamp        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  medication_name  TEXT        NOT NULL,
  dose             NUMERIC     NOT NULL,
  reason           TEXT        NOT NULL
);

-- Row Level Security
ALTER TABLE medication_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anon select" ON medication_logs FOR SELECT USING (true);
CREATE POLICY "Allow anon insert" ON medication_logs FOR INSERT WITH CHECK (true);
```

## 2. Blood Pressure Logs (`blood_pressure_logs`)

Stores every reading logged via the **Blood Pressure** section of the logger page.

```sql
CREATE TABLE blood_pressure_logs (
  id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  timestamp  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  systolic   INTEGER     NOT NULL,
  diastolic  INTEGER     NOT NULL,
  pulse      INTEGER,
  notes      TEXT
);

-- Row Level Security
ALTER TABLE blood_pressure_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anon select" ON blood_pressure_logs FOR SELECT USING (true);
CREATE POLICY "Allow anon insert" ON blood_pressure_logs FOR INSERT WITH CHECK (true);
```

## Notes

- Run these statements in the **SQL Editor** of your Supabase project dashboard.
- The `anon` key used in the front-end code is already embedded in `logger.html`. If you regenerate it, update `SUPABASE_ANON_KEY` in that file.
- Row Level Security is enabled by default on all new Supabase tables; the policies above grant read and insert access to anonymous (unauthenticated) users, which is the intended behaviour for this app.
