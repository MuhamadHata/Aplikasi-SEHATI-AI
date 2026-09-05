-- ============================================================
-- TABEL: CATATAN KADAR GULA DARAH (BLOOD GLUCOSE)
-- SEHATI-AI Database Schema
-- ============================================================

CREATE TABLE IF NOT EXISTS public.catatan_gula_darah (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    nilai NUMERIC(5,1) NOT NULL,
    kondisi TEXT NOT NULL DEFAULT 'sewaktu', -- 'puasa', 'sebelum_makan', 'setelah_makan', 'sebelum_tidur', 'sewaktu'
    faktor_pengaruh JSONB DEFAULT '[]'::jsonb, -- e.g. ["karbo_tinggi", "jalan_kaki"]
    waktu TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    catatan TEXT,
    status TEXT NOT NULL DEFAULT 'normal', -- 'hipoglikemia', 'normal', 'prediabetes', 'tinggi', 'sangatTinggi'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indeks performa query
CREATE INDEX IF NOT EXISTS idx_catatan_gula_darah_user_waktu 
ON public.catatan_gula_darah (user_id, waktu DESC);

-- Aktifkan Row Level Security (RLS)
ALTER TABLE public.catatan_gula_darah ENABLE ROW LEVEL SECURITY;

-- Kebijakan RLS (Hanya pemilik akun yang dapat mengakses dan memodifikasi datanya)
CREATE POLICY "Pengguna dapat melihat catatan gula darah sendiri"
ON public.catatan_gula_darah
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Pengguna dapat menambah catatan gula darah sendiri"
ON public.catatan_gula_darah
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Pengguna dapat memperbarui catatan gula darah sendiri"
ON public.catatan_gula_darah
FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Pengguna dapat menghapus catatan gula darah sendiri"
ON public.catatan_gula_darah
FOR DELETE
USING (auth.uid() = user_id);
