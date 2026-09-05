-- ============================================================
-- SEHATI-AI: Fix Sistem Notifikasi — Jalankan di Supabase SQL Editor
-- Urutan: Jalankan dari atas ke bawah SATU PER SATU
-- ============================================================


-- ─────────────────────────────────────────────────────────────
-- STEP 1: Aktifkan extension yang diperlukan
-- ─────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS pg_net;    -- Untuk net.http_post()
CREATE EXTENSION IF NOT EXISTS pg_cron;  -- Untuk cron job otomatis


-- ─────────────────────────────────────────────────────────────
-- STEP 2: Pastikan tabel push_tokens ada
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS push_tokens (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token       TEXT NOT NULL,
  platform    TEXT NOT NULL DEFAULT 'android',
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, token)
);

CREATE INDEX IF NOT EXISTS idx_push_tokens_user_id ON push_tokens(user_id);
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;


-- ─────────────────────────────────────────────────────────────
-- STEP 3: Fix RLS Policy pada push_tokens
-- Policy lama "FOR ALL USING" tidak cover INSERT dengan benar
-- ─────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "User manage own tokens" ON push_tokens;
DROP POLICY IF EXISTS "Service role read all" ON push_tokens;
DROP POLICY IF EXISTS "User insert own token" ON push_tokens;
DROP POLICY IF EXISTS "User update own token" ON push_tokens;
DROP POLICY IF EXISTS "User delete own token" ON push_tokens;
DROP POLICY IF EXISTS "User read own token" ON push_tokens;
DROP POLICY IF EXISTS "Service role read all tokens" ON push_tokens;

-- User bisa INSERT token miliknya sendiri
CREATE POLICY "User insert own token" ON push_tokens
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- User bisa UPDATE token miliknya sendiri
CREATE POLICY "User update own token" ON push_tokens
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- User bisa DELETE token miliknya sendiri
CREATE POLICY "User delete own token" ON push_tokens
  FOR DELETE USING (auth.uid() = user_id);

-- User bisa READ token miliknya sendiri
CREATE POLICY "User read own token" ON push_tokens
  FOR SELECT USING (auth.uid() = user_id);

-- Service role bisa READ semua (untuk Edge Function)
CREATE POLICY "Service role read all tokens" ON push_tokens
  FOR SELECT USING (auth.role() = 'service_role');


-- ─────────────────────────────────────────────────────────────
-- STEP 4: Pastikan tabel notifications ada
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id         BIGSERIAL PRIMARY KEY,
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  data       JSONB DEFAULT '{}',
  is_read    BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "User read own notifications" ON notifications;
DROP POLICY IF EXISTS "User insert own notifications" ON notifications;

CREATE POLICY "User read own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

-- Service role bisa INSERT (untuk trigger dari server)
CREATE POLICY "Service role insert notifications" ON notifications
  FOR INSERT WITH CHECK (auth.role() = 'service_role');


-- ─────────────────────────────────────────────────────────────
-- STEP 5: SKIP — ALTER DATABASE tidak diizinkan di Supabase SQL Editor
-- Key akan di-embed langsung di fungsi SECURITY DEFINER pada STEP 6
-- ─────────────────────────────────────────────────────────────


-- ─────────────────────────────────────────────────────────────
-- STEP 6: Fix fungsi notify_user() — key di-embed langsung (SECURITY DEFINER)
-- Aman karena fungsi berjalan di server, tidak bisa diakses client biasa
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION notify_user(
  p_user_id UUID,
  p_title   TEXT,
  p_body    TEXT,
  p_data    JSONB DEFAULT '{}'::JSONB
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM net.http_post(
    url     := 'https://hckuwrzfkvhiddhejfth.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhja3V3cnpma3ZoaWRkaGVqZnRoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDQ3NTA1MCwiZXhwIjoyMDkwMDUxMDUwfQ.jv3sIfCJaAVoOS713rP5EYo1usKnUmwk_I7e61qLEvg'
    ),
    body    := jsonb_build_object(
      'user_id', p_user_id::TEXT,
      'title',   p_title,
      'body',    p_body,
      'data',    p_data
    )
  );
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'notify_user error untuk user %: %', p_user_id, SQLERRM;
END;
$$;


-- ─────────────────────────────────────────────────────────────
-- STEP 7: Trigger push saat INSERT ke tabel notifications
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION trigger_push_on_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM notify_user(NEW.user_id, NEW.title, NEW.body, NEW.data);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS push_on_new_notification ON notifications;
CREATE TRIGGER push_on_new_notification
  AFTER INSERT ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION trigger_push_on_notification();


-- ─────────────────────────────────────────────────────────────
-- STEP 8: Setup Cron Jobs Otomatis
-- CATATAN: Waktu dalam UTC! WIB = UTC+7 (kurangi 7 jam)
-- Contoh: 15:00 WIB = 08:00 UTC
-- ─────────────────────────────────────────────────────────────

-- Hapus jadwal lama jika ada
SELECT cron.unschedule('sehati-water-9am')   WHERE EXISTS (SELECT FROM cron.job WHERE jobname = 'sehati-water-9am');
SELECT cron.unschedule('sehati-water-12pm')  WHERE EXISTS (SELECT FROM cron.job WHERE jobname = 'sehati-water-12pm');
SELECT cron.unschedule('sehati-water-3pm')   WHERE EXISTS (SELECT FROM cron.job WHERE jobname = 'sehati-water-3pm');
SELECT cron.unschedule('sehati-water-6pm')   WHERE EXISTS (SELECT FROM cron.job WHERE jobname = 'sehati-water-6pm');
SELECT cron.unschedule('sehati-water-9pm')   WHERE EXISTS (SELECT FROM cron.job WHERE jobname = 'sehati-water-9pm');
SELECT cron.unschedule('sehati-steps')       WHERE EXISTS (SELECT FROM cron.job WHERE jobname = 'sehati-steps');
SELECT cron.unschedule('sehati-summary')     WHERE EXISTS (SELECT FROM cron.job WHERE jobname = 'sehati-summary');
SELECT cron.unschedule('sehati-exercise')    WHERE EXISTS (SELECT FROM cron.job WHERE jobname = 'sehati-exercise');

-- Pengingat minum air (setiap 3 jam, mulai jam 9 WIB = 02 UTC)
SELECT cron.schedule('sehati-water-9am',  '0 2  * * *', 'SELECT cron_water_reminder()');  -- 09:00 WIB
SELECT cron.schedule('sehati-water-12pm', '0 5  * * *', 'SELECT cron_water_reminder()');  -- 12:00 WIB
SELECT cron.schedule('sehati-water-3pm',  '0 8  * * *', 'SELECT cron_water_reminder()');  -- 15:00 WIB
SELECT cron.schedule('sehati-water-6pm',  '0 11 * * *', 'SELECT cron_water_reminder()');  -- 18:00 WIB
SELECT cron.schedule('sehati-water-9pm',  '0 14 * * *', 'SELECT cron_water_reminder()');  -- 21:00 WIB

-- Pengingat langkah sore jam 15:00 WIB = 08:00 UTC
SELECT cron.schedule('sehati-steps', '0 8 * * *', 'SELECT cron_step_reminder()');

-- Ringkasan harian jam 21:00 WIB = 14:00 UTC
SELECT cron.schedule('sehati-summary', '0 14 * * *', 'SELECT cron_daily_summary()');

-- Pengingat olahraga jam 15:00 WIB = 08:00 UTC
SELECT cron.schedule('sehati-exercise', '30 8 * * *', 'SELECT cron_exercise_reminder()');


-- ─────────────────────────────────────────────────────────────
-- STEP 9: TEST — Insert manual untuk cek apakah push terkirim
-- Ganti USER_ID dengan UUID user yang sedang login
-- ─────────────────────────────────────────────────────────────
-- INSERT INTO notifications (user_id, title, body)
-- VALUES (
--   '79d37554-a797-4298-a675-ec19e1e9dad0',
--   '🧪 Test Push dari Server',
--   'Jika ini muncul di HP kamu, sistem notifikasi sudah berjalan!'
-- );

-- ─────────────────────────────────────────────────────────────
-- Cek semua cron job yang terdaftar
-- ─────────────────────────────────────────────────────────────
-- SELECT * FROM cron.job WHERE jobname LIKE 'sehati%';
