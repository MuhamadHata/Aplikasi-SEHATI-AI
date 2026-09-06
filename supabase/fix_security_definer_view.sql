-- =====================================================
-- SEHATI-AI: Fix Security Definer View
-- Jalankan di Supabase SQL Editor
-- =====================================================

-- Mengubah view agar menggunakan security_invoker = true
-- Ini memastikan view mematuhi hak akses dan RLS dari pengguna yang menjalankan query (bukan pemilik view/postgres).
ALTER VIEW public.food_dataset_training SET (security_invoker = true);

-- Verifikasi opsi view
SELECT relname, reloptions 
FROM pg_class 
WHERE relname = 'food_dataset_training';
