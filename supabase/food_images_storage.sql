-- =====================================================
-- SEHATI-AI: Food Images Storage Bucket
-- Jalankan di Supabase SQL Editor
-- =====================================================

-- 1. Buat bucket food-images (public agar image_url bisa diakses langsung)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'food-images',
  'food-images',
  true,
  5242880,  -- 5 MB per file
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- 2. Policy storage (DROP dulu agar idempotent)
DROP POLICY IF EXISTS "Users can upload own food images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own food images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can read food images" ON storage.objects;

CREATE POLICY "Users can upload own food images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'food-images'
    AND auth.uid()::text = (storage.foldername(name))[2]
  );

CREATE POLICY "Users can update own food images"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'food-images'
    AND auth.uid()::text = (storage.foldername(name))[2]
  );

CREATE POLICY "Anyone can read food images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'food-images');

-- 3. Verifikasi
SELECT id, name, public, file_size_limit FROM storage.buckets WHERE id = 'food-images';
