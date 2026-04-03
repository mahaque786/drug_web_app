-- ============================================================
-- Socratic Questioning — Supabase setup
-- Run this in the Supabase SQL editor for your project.
-- ============================================================

-- 1. Create the thought_records table
CREATE TABLE IF NOT EXISTS public.thought_records (
    id          uuid            PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at  timestamptz     NOT NULL DEFAULT now(),
    mode        text            NOT NULL CHECK (mode IN ('anxiety', 'negative_thought')),
    situation   text            NOT NULL,
    automatic_thought text      NOT NULL,
    responses   jsonb           NOT NULL DEFAULT '{}'::jsonb
);

-- 2. Index for fast retrieval in reverse-chronological order
CREATE INDEX IF NOT EXISTS thought_records_created_at_idx
    ON public.thought_records (created_at DESC);

-- 3. Enable Row Level Security
ALTER TABLE public.thought_records ENABLE ROW LEVEL SECURITY;

-- 4. Allow anonymous read access (public thought log)
--    If you want records to be private per-user, see the note below.
CREATE POLICY "Allow anonymous read"
    ON public.thought_records
    FOR SELECT
    USING (true);

-- 5. Allow anonymous inserts (so the browser can save records)
CREATE POLICY "Allow anonymous insert"
    ON public.thought_records
    FOR INSERT
    WITH CHECK (true);

-- ============================================================
-- Optional: per-user privacy using Supabase Auth
-- If you add authentication later, replace the policies above
-- with the following and remove the anonymous policies:
--
-- CREATE POLICY "Users can read own records"
--     ON public.thought_records FOR SELECT
--     USING (auth.uid() = user_id);
--
-- CREATE POLICY "Users can insert own records"
--     ON public.thought_records FOR INSERT
--     WITH CHECK (auth.uid() = user_id);
--
-- And add a user_id column:
--   ALTER TABLE public.thought_records
--     ADD COLUMN user_id uuid REFERENCES auth.users(id);
-- ============================================================
