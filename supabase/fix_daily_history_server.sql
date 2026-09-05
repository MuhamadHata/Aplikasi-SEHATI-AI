-- =====================================================
-- SEHATI-AI: Fix Daily History Server Storage
-- Jalankan di Supabase SQL Editor
-- =====================================================

-- Pastikan kolom yang dibutuhkan ada di daily_summaries
ALTER TABLE daily_summaries
  ADD COLUMN IF NOT EXISTS calorie_consumed INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS calories_burned INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS steps INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS water_glasses INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS sleep_hours DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_smoker BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS food_logs JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS last_update TIMESTAMPTZ DEFAULT now();

-- Pastikan activity_history memiliki kolom yang lengkap  
ALTER TABLE activity_history
  ADD COLUMN IF NOT EXISTS moving_duration_seconds INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS elevation_gain_m DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS elevation_loss DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS max_altitude DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS min_altitude DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS average_speed_kmh DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS route JSONB DEFAULT '[]'::jsonb;

-- Index untuk performa query riwayat
CREATE INDEX IF NOT EXISTS idx_activity_history_user_date_desc
  ON activity_history(user_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_daily_summaries_user_date_desc
  ON daily_summaries(user_id, date DESC);

-- Policy DELETE untuk activity_history (agar pengguna bisa hapus riwayat sendiri)
DROP POLICY IF EXISTS "Users can delete own activity_history" ON activity_history;
CREATE POLICY "Users can delete own activity_history"
  ON activity_history FOR DELETE USING (auth.uid() = user_id);

-- Policy DELETE untuk daily_summaries
DROP POLICY IF EXISTS "Users can delete own daily_summaries" ON daily_summaries;
CREATE POLICY "Users can delete own daily_summaries"
  ON daily_summaries FOR DELETE USING (auth.uid() = user_id);

-- Verifikasi struktur tabel
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('activity_history', 'daily_summaries')
  AND table_schema = 'public'
ORDER BY table_name, ordinal_position;
