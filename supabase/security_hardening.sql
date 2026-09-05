-- =====================================================
-- SEHATI-AI SUPABASE SECURITY HARDENING
-- Jalankan di Supabase SQL Editor
-- =====================================================

-- =====================================================
-- 1. AKTIFKAN RLS SEMUA TABEL
-- =====================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE food_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE sleep_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE screen_time_logs ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 2. HAPUS POLICY LAMA (jika ada) SEBELUM BUAT BARU
-- =====================================================
DROP POLICY IF EXISTS "Users can read own daily_summaries" ON daily_summaries;
DROP POLICY IF EXISTS "Users can insert own daily_summaries" ON daily_summaries;
DROP POLICY IF EXISTS "Users can update own daily_summaries" ON daily_summaries;
DROP POLICY IF EXISTS "Users can read own activity_history" ON activity_history;
DROP POLICY IF EXISTS "Users can insert own activity_history" ON activity_history;
DROP POLICY IF EXISTS "Users can update own activity_history" ON activity_history;

-- =====================================================
-- 3. TABEL: users
-- =====================================================
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users cannot delete profile" ON users;

CREATE POLICY "Users can view own profile"
  ON users FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Tidak ada DELETE — data user tidak boleh dihapus sembarangan

-- =====================================================
-- 4. TABEL: daily_stats
-- =====================================================
DROP POLICY IF EXISTS "Users can view own daily_stats" ON daily_stats;
DROP POLICY IF EXISTS "Users can insert own daily_stats" ON daily_stats;
DROP POLICY IF EXISTS "Users can update own daily_stats" ON daily_stats;

CREATE POLICY "Users can view own daily_stats"
  ON daily_stats FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily_stats"
  ON daily_stats FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily_stats"
  ON daily_stats FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- 5. TABEL: daily_summaries
-- =====================================================
CREATE POLICY "Users can view own daily_summaries"
  ON daily_summaries FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily_summaries"
  ON daily_summaries FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily_summaries"
  ON daily_summaries FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- 6. TABEL: activity_history
-- =====================================================
CREATE POLICY "Users can view own activity_history"
  ON activity_history FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own activity_history"
  ON activity_history FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own activity_history"
  ON activity_history FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- 7. TABEL: food_logs
-- =====================================================
DROP POLICY IF EXISTS "Users can view own food_logs" ON food_logs;
DROP POLICY IF EXISTS "Users can insert own food_logs" ON food_logs;
DROP POLICY IF EXISTS "Users can update own food_logs" ON food_logs;

CREATE POLICY "Users can view own food_logs"
  ON food_logs FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own food_logs"
  ON food_logs FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own food_logs"
  ON food_logs FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- 8. TABEL: sleep_logs
-- =====================================================
DROP POLICY IF EXISTS "Users can view own sleep_logs" ON sleep_logs;
DROP POLICY IF EXISTS "Users can insert own sleep_logs" ON sleep_logs;
DROP POLICY IF EXISTS "Users can update own sleep_logs" ON sleep_logs;

CREATE POLICY "Users can view own sleep_logs"
  ON sleep_logs FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sleep_logs"
  ON sleep_logs FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sleep_logs"
  ON sleep_logs FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- 9. TABEL: screen_time_logs
-- =====================================================
DROP POLICY IF EXISTS "Users can view own screen_time_logs" ON screen_time_logs;
DROP POLICY IF EXISTS "Users can insert own screen_time_logs" ON screen_time_logs;
DROP POLICY IF EXISTS "Users can update own screen_time_logs" ON screen_time_logs;

CREATE POLICY "Users can view own screen_time_logs"
  ON screen_time_logs FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own screen_time_logs"
  ON screen_time_logs FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own screen_time_logs"
  ON screen_time_logs FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- 10. INDEX untuk performa query
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_daily_stats_user_date
  ON daily_stats(user_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_daily_summaries_user_date
  ON daily_summaries(user_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_activity_history_user_date
  ON activity_history(user_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_food_logs_user_date
  ON food_logs(user_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_sleep_logs_user_date
  ON sleep_logs(user_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_screen_time_logs_user_date
  ON screen_time_logs(user_id, log_date DESC);

-- =====================================================
-- 11. RATE LIMITING via pg_cron (opsional)
-- Batasi insert food_logs max 100 per user per hari
-- =====================================================
CREATE OR REPLACE FUNCTION check_food_log_limit()
RETURNS TRIGGER AS $$
DECLARE
  log_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO log_count
  FROM food_logs
  WHERE user_id = NEW.user_id
    AND date = NEW.date;

  IF log_count >= 100 THEN
    RAISE EXCEPTION 'Batas maksimal 100 log makanan per hari tercapai.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_food_log_limit ON food_logs;
CREATE TRIGGER trg_food_log_limit
  BEFORE INSERT ON food_logs
  FOR EACH ROW EXECUTE FUNCTION check_food_log_limit();

-- =====================================================
-- 12. VALIDASI DATA — cegah data tidak valid masuk
-- =====================================================
ALTER TABLE daily_stats
  ADD CONSTRAINT IF NOT EXISTS chk_water_glasses
    CHECK (water_glasses >= 0 AND water_glasses <= 50),
  ADD CONSTRAINT IF NOT EXISTS chk_passive_steps
    CHECK (passive_steps >= 0 AND passive_steps <= 100000),
  ADD CONSTRAINT IF NOT EXISTS chk_calorie_consumed
    CHECK (calorie_consumed >= 0 AND calorie_consumed <= 20000);

ALTER TABLE daily_summaries
  ADD CONSTRAINT IF NOT EXISTS chk_summary_steps
    CHECK (steps >= 0 AND steps <= 100000),
  ADD CONSTRAINT IF NOT EXISTS chk_summary_water
    CHECK (water_glasses >= 0 AND water_glasses <= 50),
  ADD CONSTRAINT IF NOT EXISTS chk_summary_calories
    CHECK (calories_consumed >= 0 AND calories_consumed <= 20000);

-- =====================================================
-- 13. VERIFIKASI — cek semua RLS sudah aktif
-- =====================================================
SELECT
  schemaname,
  tablename,
  rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'users', 'daily_stats', 'daily_summaries',
    'activity_history', 'food_logs', 'sleep_logs', 'screen_time_logs'
  )
ORDER BY tablename;
