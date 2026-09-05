-- ============================================================
-- SEHATI-AI: Push Notification Setup
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- 1. Tabel untuk menyimpan FCM token per user
CREATE TABLE IF NOT EXISTS push_tokens (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token       TEXT NOT NULL,
  platform    TEXT NOT NULL DEFAULT 'android', -- android | ios
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, token)
);

-- Index untuk query cepat per user
CREATE INDEX IF NOT EXISTS idx_push_tokens_user_id ON push_tokens(user_id);

-- RLS: user hanya bisa akses token miliknya sendiri
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User manage own tokens" ON push_tokens
  FOR ALL USING (auth.uid() = user_id);

-- Service role bisa baca semua (untuk Edge Function)
CREATE POLICY "Service role read all" ON push_tokens
  FOR SELECT USING (auth.role() = 'service_role');


-- ============================================================
-- 2. Helper function untuk kirim push dari SQL/trigger
--    Memanggil Edge Function send-push-notification
-- ============================================================
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
      'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
    ),
    body    := jsonb_build_object(
      'user_id', p_user_id::TEXT,
      'title',   p_title,
      'body',    p_body,
      'data',    p_data
    )
  );
END;
$$;


-- ============================================================
-- 3. Contoh trigger: kirim notif saat ada pesan baru di tabel
--    'notifications' (opsional, sesuaikan dengan kebutuhan)
-- ============================================================

-- Tabel notifikasi (opsional — untuk riwayat notif in-app)
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
CREATE POLICY "User read own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

-- Trigger: otomatis push saat INSERT ke tabel notifications
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

CREATE TRIGGER push_on_new_notification
  AFTER INSERT ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION trigger_push_on_notification();


-- ============================================================
-- 4. Set konfigurasi URL & key (jalankan sekali)
--    Ganti dengan nilai asli dari Supabase dashboard
-- ============================================================
-- ALTER DATABASE postgres SET app.supabase_url = 'https://hckuwrzfkvhiddhejfth.supabase.co';
-- ALTER DATABASE postgres SET app.service_role_key = 'YOUR_SERVICE_ROLE_KEY';
