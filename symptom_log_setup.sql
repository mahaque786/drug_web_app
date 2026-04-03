-- ============================================================
-- Symptom Logger — Supabase setup
-- Run this in the Supabase SQL editor for your project.
-- Source: comprehensive_master_symptom_library.json v1.0.0
-- ============================================================

-- 1. Create the symptom_logs table
CREATE TABLE IF NOT EXISTS public.symptom_logs (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    logged_at           timestamptz NOT NULL DEFAULT now(),

    -- Symptom identity (from comprehensive_master_symptom_library.json)
    symptom_id          text        NOT NULL,   -- e.g. "SYM0001"
    symptom_name        text        NOT NULL,   -- e.g. "Fever"
    system_key          text        NOT NULL,   -- e.g. "general_constitutional"

    -- Core structured response fields (Likert / categorical)
    presence            text        NOT NULL CHECK (presence IN ('present', 'absent', 'unsure')),
    severity            smallint    CHECK (severity BETWEEN 0 AND 4),
    frequency           smallint    CHECK (frequency BETWEEN 0 AND 4),
    functional_impact   smallint    CHECK (functional_impact BETWEEN 0 AND 4),
    onset               text        CHECK (onset IS NULL OR onset IN ('sudden', 'gradual', 'episodic', 'unknown')),
    laterality          text        CHECK (laterality IS NULL OR laterality IN (
                                        'left', 'right', 'bilateral', 'midline', 'diffuse', 'not_applicable')),

    -- Common free-text response fields
    duration            text,
    location            text,
    quality             text,
    triggers            text,
    relieving_factors   text,
    associated_symptoms text,
    notes               text,

    -- Profile-specific fields stored as JSONB
    -- (e.g. radiation, color, amount, odor, timing, appearance, spread_pattern,
    --  itch_or_pain, trigger_context, exertional_context, positional_context,
    --  time_pattern, safety_impact, meal_relation, stool_or_emesis_character,
    --  cycle_relation, pregnancy_context, sexual_context, age_context,
    --  feeding_context, developmental_context, quantity, medication_context)
    details             jsonb       NOT NULL DEFAULT '{}'::jsonb
);

-- 2. Indexes for common query patterns
CREATE INDEX IF NOT EXISTS symptom_logs_logged_at_idx
    ON public.symptom_logs (logged_at DESC);

CREATE INDEX IF NOT EXISTS symptom_logs_symptom_id_idx
    ON public.symptom_logs (symptom_id);

CREATE INDEX IF NOT EXISTS symptom_logs_system_key_idx
    ON public.symptom_logs (system_key);

CREATE INDEX IF NOT EXISTS symptom_logs_presence_idx
    ON public.symptom_logs (presence);

-- 3. Enable Row Level Security
ALTER TABLE public.symptom_logs ENABLE ROW LEVEL SECURITY;

-- 4. Allow anonymous read access
CREATE POLICY "Allow anonymous read"
    ON public.symptom_logs
    FOR SELECT
    USING (true);

-- 5. Allow anonymous inserts (so the browser can save symptom logs)
CREATE POLICY "Allow anonymous insert"
    ON public.symptom_logs
    FOR INSERT
    WITH CHECK (true);

-- ============================================================
-- Optional: per-user privacy using Supabase Auth
-- If you add authentication later, replace the policies above
-- with the following and remove the anonymous policies:
--
-- CREATE POLICY "Users can read own records"
--     ON public.symptom_logs FOR SELECT
--     USING (auth.uid() = user_id);
--
-- CREATE POLICY "Users can insert own records"
--     ON public.symptom_logs FOR INSERT
--     WITH CHECK (auth.uid() = user_id);
--
-- And add a user_id column:
--   ALTER TABLE public.symptom_logs
--     ADD COLUMN user_id uuid REFERENCES auth.users(id);
-- ============================================================

-- ============================================================
-- Column reference
-- ============================================================
-- id                 — auto-generated UUID primary key
-- logged_at          — timestamp when the entry was submitted (auto-set to now())
-- symptom_id         — canonical ID from the library  (e.g. "SYM0001")
-- symptom_name       — human-readable display name    (e.g. "Fever")
-- system_key         — body-system key                (e.g. "general_constitutional")
-- presence           — present | absent | unsure
-- severity           — 0 None · 1 Mild · 2 Moderate · 3 Severe · 4 Very severe
-- frequency          — 0 Never · 1 Rarely · 2 Sometimes · 3 Often · 4 Constantly
-- functional_impact  — 0 Not at all · 1 A little · 2 Somewhat · 3 A lot · 4 Extremely
-- onset              — sudden | gradual | episodic | unknown
-- laterality         — left | right | bilateral | midline | diffuse | not_applicable
-- duration           — free text  (e.g. "lasts 10 min, started 3 weeks ago")
-- location           — free text  (e.g. "left lower abdomen")
-- quality            — free text  (e.g. "sharp, throbbing")
-- triggers           — free text  (e.g. "movement, stress")
-- relieving_factors  — free text  (e.g. "rest, ice")
-- associated_symptoms— free text  (other symptoms occurring at the same time)
-- notes              — free text  (any additional patient notes)
-- details            — JSONB for profile-specific fields not listed above
-- ============================================================
