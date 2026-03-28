# Supabase setup for the medication logger

## 1. Create a Supabase project

Go to [supabase.com](https://supabase.com), create a free project, and note your
**Project URL** and **anon (public) key** from **Settings → API**.

## 2. Create the table

Run this SQL in the Supabase SQL Editor:

```sql
CREATE TABLE medication_logs (
  id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  timestamp       TIMESTAMPTZ NOT NULL DEFAULT now(),
  medication_name TEXT        NOT NULL,
  dose            NUMERIC     NOT NULL CHECK (dose > 0),
  reason          TEXT        NOT NULL
);

-- Row Level Security – allow anonymous reads and inserts
ALTER TABLE medication_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous read"
  ON medication_logs FOR SELECT USING (true);

CREATE POLICY "Allow anonymous insert"
  ON medication_logs FOR INSERT WITH CHECK (true);
```

## 3. Configure the front-end

Open `logger.html` and set the two constants near the top of the `<script>` block:

```js
const SUPABASE_URL      = 'https://<your-project>.supabase.co';
const SUPABASE_ANON_KEY = '<your-anon-key>';
```

## 4. Migrating existing data

If you have entries in the old Google Sheet, export them as CSV and import via
the Supabase dashboard (**Table Editor → Import data**), or insert them manually:

```sql
INSERT INTO medication_logs (timestamp, medication_name, dose, reason)
VALUES
  ('2025-01-15T08:30:00Z', 'Lorazepam (tablet)', 0.5, 'Anxiety'),
  ('2025-01-15T22:00:00Z', 'Temazepam (capsule)', 15, 'Insomnia');
```

## REST API used by the front-end

| Operation | Endpoint |
|-----------|----------|
| Fetch logs | `GET /rest/v1/medication_logs?select=*&order=timestamp.desc` |
| Add log    | `POST /rest/v1/medication_logs` with JSON body `{ medication_name, dose, reason }` |

Both require the `apikey` and `Authorization: Bearer <anon_key>` headers.
