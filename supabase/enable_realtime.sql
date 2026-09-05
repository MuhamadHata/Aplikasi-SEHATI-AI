-- Jalankan di Supabase SQL Editor untuk mengaktifkan Realtime
-- pada tabel daily_summaries dan activity_history

-- 1. Aktifkan Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE daily_summaries;
ALTER PUBLICATION supabase_realtime ADD TABLE activity_history;

-- 2. RLS policy daily_summaries
CREATE POLICY IF NOT EXISTS "Users can read own daily_summaries"
  ON daily_summaries FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can insert own daily_summaries"
  ON daily_summaries FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can update own daily_summaries"
  ON daily_summaries FOR UPDATE USING (auth.uid() = user_id);

-- 3. RLS policy activity_history
CREATE POLICY IF NOT EXISTS "Users can read own activity_history"
  ON activity_history FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can insert own activity_history"
  ON activity_history FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can update own activity_history"
  ON activity_history FOR UPDATE USING (auth.uid() = user_id);
