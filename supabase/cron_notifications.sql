-- ============================================================
-- SEHATI-AI: Cron Jobs Push Notification Otomatis
-- Jalankan di Supabase SQL Editor
-- ============================================================

-- ── 1. Fungsi: Pengingat Minum Air ───────────────────────────
CREATE OR REPLACE FUNCTION cron_water_reminder()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  rec RECORD;
  msg TEXT;
BEGIN
  FOR rec IN
    SELECT
      ds.user_id,
      ds.water_glasses,
      COALESCE(u.water_target, 8) AS water_target
    FROM daily_stats ds
    LEFT JOIN users u ON u.id = ds.user_id
    WHERE ds.date = CURRENT_DATE
      AND ds.water_glasses < COALESCE(u.water_target, 8)
  LOOP
    IF rec.water_glasses = 0 THEN
      msg := 'Kamu belum minum air hari ini! Yuk mulai hidrasi 💧';
    ELSE
      msg := 'Baru ' || rec.water_glasses || ' dari ' || rec.water_target || ' gelas. Ayo kejar targetmu! 💧';
    END IF;

    INSERT INTO notifications (user_id, title, body)
    VALUES (rec.user_id, '💧 Pengingat Minum Air', msg);
  END LOOP;
END;
$$;

-- ── 2. Fungsi: Pengingat Langkah Kaki ────────────────────────
CREATE OR REPLACE FUNCTION cron_step_reminder()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  rec RECORD;
  msg TEXT;
BEGIN
  FOR rec IN
    SELECT
      ds.user_id,
      ds.passive_steps,
      COALESCE(u.step_target, 10000) AS step_target
    FROM daily_stats ds
    LEFT JOIN users u ON u.id = ds.user_id
    WHERE ds.date = CURRENT_DATE
      AND ds.passive_steps < (COALESCE(u.step_target, 10000) / 2)
  LOOP
    msg := 'Baru ' || rec.passive_steps || ' langkah hari ini. Yuk jalan kaki sebentar! 👟';

    INSERT INTO notifications (user_id, title, body)
    VALUES (rec.user_id, '👟 Yuk Bergerak!', msg);
  END LOOP;
END;
$$;

-- ── 3. Fungsi: Ringkasan Malam Hari ──────────────────────────
CREATE OR REPLACE FUNCTION cron_daily_summary()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  rec RECORD;
  step_pct INT;
  water_pct INT;
  msg TEXT;
BEGIN
  FOR rec IN
    SELECT
      ds.user_id,
      ds.passive_steps,
      ds.water_glasses,
      ds.calorie_consumed,
      COALESCE(u.step_target, 10000)  AS step_target,
      COALESCE(u.water_target, 8)     AS water_target
    FROM daily_stats ds
    LEFT JOIN users u ON u.id = ds.user_id
    WHERE ds.date = CURRENT_DATE
  LOOP
    step_pct  := LEAST(ROUND((rec.passive_steps::NUMERIC / rec.step_target) * 100), 100);
    water_pct := LEAST(ROUND((rec.water_glasses::NUMERIC / rec.water_target) * 100), 100);

    msg := '👟 ' || rec.passive_steps || ' langkah (' || step_pct || '%) • '
        || '💧 ' || rec.water_glasses || '/' || rec.water_target || ' gelas (' || water_pct || '%) • '
        || '🔥 ' || rec.calorie_consumed || ' kkal';

    INSERT INTO notifications (user_id, title, body)
    VALUES (rec.user_id, '📊 Ringkasan Hari Ini', msg);
  END LOOP;
END;
$$;

-- ── 4. Fungsi: Milestone Langkah ─────────────────────────────
CREATE OR REPLACE FUNCTION cron_step_milestone()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  rec       RECORD;
  milestone INT;
  title     TEXT;
  msg       TEXT;
BEGIN
  FOR rec IN
    SELECT user_id, passive_steps
    FROM daily_stats
    WHERE date = CURRENT_DATE
  LOOP
    -- Cek milestone yang belum pernah dinotif hari ini
    FOREACH milestone IN ARRAY ARRAY[2500, 5000, 7500, 10000, 15000, 20000]
    LOOP
      IF rec.passive_steps >= milestone THEN
        -- Cek apakah milestone ini sudah dinotif hari ini
        IF NOT EXISTS (
          SELECT 1 FROM notifications
          WHERE user_id = rec.user_id
            AND DATE(created_at) = CURRENT_DATE
            AND body LIKE '%' || milestone || ' langkah%'
        ) THEN
          IF milestone = 10000 THEN
            title := '🏆 Target Harian Tercapai!';
            msg   := '10.000 langkah hari ini — luar biasa! Pertahankan!';
          ELSIF milestone = 5000 THEN
            title := '⭐ Setengah Target!';
            msg   := '5.000 langkah — kamu sudah di tengah jalan!';
          ELSIF milestone >= 15000 THEN
            title := '🔥 Melampaui Target!';
            msg   := milestone || ' langkah — kamu luar biasa hari ini!';
          ELSE
            title := '🎉 Pencapaian Langkah!';
            msg   := milestone || ' langkah tercapai! Terus semangat!';
          END IF;

          INSERT INTO notifications (user_id, title, body)
          VALUES (rec.user_id, title, msg);

          EXIT; -- Satu milestone per cek
        END IF;
      END IF;
    END LOOP;
  END LOOP;
END;
$$;

-- ── 5. Fungsi: Pengingat Olahraga ────────────────────────────
CREATE OR REPLACE FUNCTION cron_exercise_reminder()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    -- User yang belum ada aktivitas hari ini di activity_history
    SELECT DISTINCT u.id AS user_id
    FROM users u
    WHERE NOT EXISTS (
      SELECT 1 FROM activity_history ah
      WHERE ah.user_id = u.id
        AND DATE(ah.date) = CURRENT_DATE
    )
  LOOP
    INSERT INTO notifications (user_id, title, body)
    VALUES (
      rec.user_id,
      '🏃 Waktunya Olahraga!',
      'Kamu belum berolahraga hari ini. Yuk gerak 20 menit untuk jaga kesehatan!'
    );
  END LOOP;
END;
$$;
