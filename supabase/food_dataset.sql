-- =====================================================
-- SEHATI-AI: Food Dataset Table
-- Jalankan di Supabase SQL Editor
-- =====================================================

-- 1. Buat tabel food_dataset
CREATE TABLE IF NOT EXISTS food_dataset (
  id BIGSERIAL PRIMARY KEY,
  food_hash TEXT UNIQUE NOT NULL,       -- SHA256 nama ternormalisasi
  food_name TEXT NOT NULL,
  serving TEXT NOT NULL,
  calories INTEGER NOT NULL,
  protein REAL NOT NULL DEFAULT 0,
  carbs REAL NOT NULL DEFAULT 0,
  fat REAL NOT NULL DEFAULT 0,
  fiber REAL NOT NULL DEFAULT 0,
  sugar_grams REAL NOT NULL DEFAULT 0,
  caffeine_mg INTEGER NOT NULL DEFAULT 0,
  category TEXT NOT NULL DEFAULT 'Makanan',
  emoji TEXT NOT NULL DEFAULT '🍽️',
  ingredients JSONB NOT NULL DEFAULT '[]',
  image_url TEXT,                        -- URL gambar di Supabase Storage
  image_hash TEXT,                       -- SHA256 bytes gambar
  confirm_count INTEGER NOT NULL DEFAULT 1,
  scan_count INTEGER NOT NULL DEFAULT 1,
  source TEXT NOT NULL DEFAULT 'user_confirmed',
  contributed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Index untuk performa
CREATE INDEX IF NOT EXISTS idx_food_dataset_name
  ON food_dataset(food_name);
CREATE INDEX IF NOT EXISTS idx_food_dataset_hash
  ON food_dataset(food_hash);
CREATE INDEX IF NOT EXISTS idx_food_dataset_confirm
  ON food_dataset(confirm_count DESC);
CREATE INDEX IF NOT EXISTS idx_food_dataset_source
  ON food_dataset(source);

-- 3. RLS
ALTER TABLE food_dataset ENABLE ROW LEVEL SECURITY;

-- Semua user bisa baca dataset (untuk lookup saat scan)
CREATE POLICY "Anyone can read food_dataset"
  ON food_dataset FOR SELECT USING (true);

-- User hanya bisa insert/update data miliknya
CREATE POLICY "Users can insert food_dataset"
  ON food_dataset FOR INSERT
  WITH CHECK (auth.uid() = contributed_by);

CREATE POLICY "Users can update own food_dataset"
  ON food_dataset FOR UPDATE
  USING (auth.uid() = contributed_by);

-- 4. Aktifkan Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE food_dataset;

-- 5. Trigger updated_at
CREATE OR REPLACE FUNCTION update_food_dataset_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_food_dataset_updated_at
  BEFORE UPDATE ON food_dataset
  FOR EACH ROW EXECUTE FUNCTION update_food_dataset_updated_at();

-- 6. View untuk export dataset training (hanya data terverifikasi)
CREATE OR REPLACE VIEW food_dataset_training AS
SELECT
  food_hash,
  food_name,
  serving,
  calories,
  protein,
  carbs,
  fat,
  fiber,
  sugar_grams,
  caffeine_mg,
  category,
  emoji,
  ingredients,
  image_url,
  confirm_count,
  scan_count,
  source,
  updated_at
FROM food_dataset
WHERE source IN ('user_confirmed', 'user_corrected')
  AND confirm_count >= 1
ORDER BY confirm_count DESC, scan_count DESC;

-- 7. Verifikasi
SELECT COUNT(*) as total_entries FROM food_dataset;
