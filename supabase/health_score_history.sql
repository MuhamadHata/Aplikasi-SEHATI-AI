-- =====================================================
-- SEHATI-AI: Health Score History Column
-- Jalankan di Supabase SQL Editor
-- =====================================================

-- 1. Tambah kolom health_score ke tabel daily_summaries
ALTER TABLE daily_summaries
  ADD COLUMN IF NOT EXISTS health_score INTEGER DEFAULT NULL;

-- 2. Verifikasi
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'daily_summaries'
  AND column_name = 'health_score';
