-- =====================================================
-- SEHATI-AI: Master Fix Database Script
-- Jalankan SEMUA perintah ini di Supabase SQL Editor
-- (Mencakup: Security Definer View, Riwayat Harian, RLS, Realtime)
-- =====================================================

-- ── 1. FIX SECURITY DEFINER VIEW (Advisor Warning) ──
ALTER VIEW IF EXISTS public.food_dataset_training SET (security_invoker = true);


-- ── 2. KELENGKAPAN KOLOM TABEL daily_summaries ──
ALTER TABLE IF EXISTS public.daily_summaries
  ADD COLUMN IF NOT EXISTS calorie_consumed INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS calories_consumed INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS calories_burned INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS steps INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS water_glasses INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS sleep_hours DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_smoker BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS food_logs JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS health_score INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_update TIMESTAMPTZ DEFAULT now();


-- ── 3. KELENGKAPAN KOLOM TABEL activity_history ──
ALTER TABLE IF EXISTS public.activity_history
  ADD COLUMN IF NOT EXISTS moving_duration_seconds INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS elevation_gain_m DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS elevation_loss DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS max_altitude DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS min_altitude DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS average_speed_kmh DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS route JSONB DEFAULT '[]'::jsonb;


-- ── 4. INDEX UNTUK PERFORMA & UPSERT RIWAYAT ──
-- Unique index penting untuk: .upsert(..., onConflict: 'user_id, date')
CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_summaries_user_date_unique
  ON public.daily_summaries(user_id, date);

CREATE INDEX IF NOT EXISTS idx_daily_summaries_user_date_desc
  ON public.daily_summaries(user_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_activity_history_user_date_desc
  ON public.activity_history(user_id, date DESC);


-- ── 5. ROW LEVEL SECURITY (RLS) POLICIES ──
ALTER TABLE public.daily_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_history ENABLE ROW LEVEL SECURITY;

-- Policies untuk daily_summaries
DROP POLICY IF EXISTS "Users can read own daily_summaries" ON public.daily_summaries;
CREATE POLICY "Users can read own daily_summaries"
  ON public.daily_summaries FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own daily_summaries" ON public.daily_summaries;
CREATE POLICY "Users can insert own daily_summaries"
  ON public.daily_summaries FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own daily_summaries" ON public.daily_summaries;
CREATE POLICY "Users can update own daily_summaries"
  ON public.daily_summaries FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own daily_summaries" ON public.daily_summaries;
CREATE POLICY "Users can delete own daily_summaries"
  ON public.daily_summaries FOR DELETE USING (auth.uid() = user_id);

-- Policies untuk activity_history
DROP POLICY IF EXISTS "Users can read own activity_history" ON public.activity_history;
CREATE POLICY "Users can read own activity_history"
  ON public.activity_history FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own activity_history" ON public.activity_history;
CREATE POLICY "Users can insert own activity_history"
  ON public.activity_history FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own activity_history" ON public.activity_history;
CREATE POLICY "Users can update own activity_history"
  ON public.activity_history FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own activity_history" ON public.activity_history;
CREATE POLICY "Users can delete own activity_history"
  ON public.activity_history FOR DELETE USING (auth.uid() = user_id);


-- ── 6. AKTIFKAN REALTIME & REPLICA IDENTITY ──
ALTER TABLE public.daily_summaries REPLICA IDENTITY FULL;
ALTER TABLE public.activity_history REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'daily_summaries'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.daily_summaries;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'activity_history'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.activity_history;
  END IF;
END $$;


-- ── 7. VERIFIKASI HASIL ──
-- Cek status Security Invoker pada view
SELECT relname AS view_name, reloptions 
FROM pg_class 
WHERE relname = 'food_dataset_training';

-- Cek kolom tabel daily_summaries
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'daily_summaries' AND table_schema = 'public'
ORDER BY ordinal_position;
