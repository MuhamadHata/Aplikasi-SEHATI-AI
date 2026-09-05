-- ====================================================================
-- SEHATI-AI: FIX DELETE USER CASCADE (SUPABASE SQL EDITOR)
-- Jalankan skrip ini di SQL Editor Supabase untuk memungkinkan penghapusan
-- user dari dashboard Authentication tanpa terhalang foreign key constraint.
-- ====================================================================

-- 1. TABEL: users (public.users)
DO $$
BEGIN
  -- Drop constraint lama jika ada
  ALTER TABLE IF EXISTS public.users
    DROP CONSTRAINT IF EXISTS users_id_fkey,
    DROP CONSTRAINT IF EXISTS fk_auth_user;

  -- Pasang constraint baru dengan ON DELETE CASCADE
  ALTER TABLE IF EXISTS public.users
    ADD CONSTRAINT users_id_fkey
    FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Constraint users_id_fkey: %', SQLERRM;
END $$;

-- 2. TABEL: daily_stats
DO $$
BEGIN
  ALTER TABLE IF EXISTS public.daily_stats
    DROP CONSTRAINT IF EXISTS daily_stats_user_id_fkey;

  ALTER TABLE IF EXISTS public.daily_stats
    ADD CONSTRAINT daily_stats_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Constraint daily_stats_user_id_fkey: %', SQLERRM;
END $$;

-- 3. TABEL: daily_summaries
DO $$
BEGIN
  ALTER TABLE IF EXISTS public.daily_summaries
    DROP CONSTRAINT IF EXISTS daily_summaries_user_id_fkey;

  ALTER TABLE IF EXISTS public.daily_summaries
    ADD CONSTRAINT daily_summaries_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Constraint daily_summaries_user_id_fkey: %', SQLERRM;
END $$;

-- 4. TABEL: activity_history
DO $$
BEGIN
  ALTER TABLE IF EXISTS public.activity_history
    DROP CONSTRAINT IF EXISTS activity_history_user_id_fkey;

  ALTER TABLE IF EXISTS public.activity_history
    ADD CONSTRAINT activity_history_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Constraint activity_history_user_id_fkey: %', SQLERRM;
END $$;

-- 5. TABEL: food_logs
DO $$
BEGIN
  ALTER TABLE IF EXISTS public.food_logs
    DROP CONSTRAINT IF EXISTS food_logs_user_id_fkey;

  ALTER TABLE IF EXISTS public.food_logs
    ADD CONSTRAINT food_logs_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Constraint food_logs_user_id_fkey: %', SQLERRM;
END $$;

-- 6. TABEL: sleep_logs
DO $$
BEGIN
  ALTER TABLE IF EXISTS public.sleep_logs
    DROP CONSTRAINT IF EXISTS sleep_logs_user_id_fkey;

  ALTER TABLE IF EXISTS public.sleep_logs
    ADD CONSTRAINT sleep_logs_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Constraint sleep_logs_user_id_fkey: %', SQLERRM;
END $$;

-- 7. TABEL: screen_time_logs
DO $$
BEGIN
  ALTER TABLE IF EXISTS public.screen_time_logs
    DROP CONSTRAINT IF EXISTS screen_time_logs_user_id_fkey;

  ALTER TABLE IF EXISTS public.screen_time_logs
    ADD CONSTRAINT screen_time_logs_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Constraint screen_time_logs_user_id_fkey: %', SQLERRM;
END $$;

-- 8. TABEL: push_tokens / fcm_tokens / notifications (jika ada)
DO $$
BEGIN
  ALTER TABLE IF EXISTS public.notifications
    DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;

  ALTER TABLE IF EXISTS public.notifications
    ADD CONSTRAINT notifications_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

  ALTER TABLE IF EXISTS public.fcm_tokens
    DROP CONSTRAINT IF EXISTS fcm_tokens_user_id_fkey;

  ALTER TABLE IF EXISTS public.fcm_tokens
    ADD CONSTRAINT fcm_tokens_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Constraint notifications/fcm_tokens: %', SQLERRM;
END $$;

-- 9. BERIKAN POLICY DELETE AGAR USER BISA HAPUS AKUN SENDIRI (JIKA DIBUTUHKAN)
DROP POLICY IF EXISTS "Users can delete own profile" ON public.users;
CREATE POLICY "Users can delete own profile"
  ON public.users FOR DELETE
  USING (auth.uid() = id);

-- SELESAI
SELECT 'Semua foreign key constraint berhasil di-update dengan ON DELETE CASCADE!' AS status;
