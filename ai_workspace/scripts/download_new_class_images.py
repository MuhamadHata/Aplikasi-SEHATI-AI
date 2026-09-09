"""
SEHATI-AI — Download Gambar untuk Kelas Baru (30 kelas tambahan)
=================================================================
Fix untuk Telkomsel yang memblokir DuckDuckGo via SSL interception.
Solusi: Pakai `ddgs` (package baru) dengan verify=False + fallback Bing.

Syarat (sudah terinstall):
  pip install ddgs Pillow requests tqdm

Jalankan:
  python ai_workspace/scripts/download_new_class_images.py
"""

import os
import sys
import ssl
import time
import hashlib
import warnings
from pathlib import Path
from io import BytesIO

# Fix encoding Windows PowerShell (CP1252 tidak support Unicode)
if sys.stdout.encoding and sys.stdout.encoding.lower() != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

# Suppress SSL warnings
warnings.filterwarnings("ignore", message="Unverified HTTPS request")

try:
    from ddgs import DDGS
    _USE_NEW_DDGS = True
except ImportError:
    try:
        from duckduckgo_search import DDGS
        _USE_NEW_DDGS = False
    except ImportError:
        print("[ERROR] Jalankan: pip install ddgs")
        raise SystemExit(1)

try:
    from PIL import Image
    import requests
    from tqdm import tqdm
except ImportError:
    print("[ERROR] Jalankan: pip install Pillow requests tqdm")
    raise SystemExit(1)

# ─── Konfigurasi ─────────────────────────────────────────────────────────────
BASE_DIR = Path(__file__).parent.parent.parent
DATASET_DIR = BASE_DIR / "ai_workspace" / "datasets_clean" / "food_detection"
TRAIN_IMG = DATASET_DIR / "train" / "images"
TRAIN_LBL = DATASET_DIR / "train" / "labels"
VALID_IMG = DATASET_DIR / "valid" / "images"
VALID_LBL = DATASET_DIR / "valid" / "labels"

VALID_RATIO = 0.15
IMAGES_PER_CLASS = 60

# ─── Daftar kelas baru + query ────────────────────────────────────────────────
NEW_CLASSES = {
    "Pisang Goreng": ["pisang goreng crispy Indonesia", "goreng pisang tepung renyah", "pisang goreng pontianak"],
    "Onde Onde": ["onde-onde jajanan pasar Indonesia", "onde onde wijen bulat", "onde onde kacang hijau"],
    "Lumpia": ["lumpia semarang goreng", "lumpia basah rebung", "spring roll Indonesia"],
    "Cireng": ["cireng aci goreng Bandung", "cireng bumbu rujak", "jajanan cireng crispy"],
    "Batagor": ["batagor baso tahu goreng Bandung", "batagor saus kacang", "batagor crispy"],
    "Siomay": ["siomay bandung bumbu kacang", "siomay tahu kentang", "siomai Indonesia"],
    "Pempek": ["pempek palembang kapal selam", "pempek lenjer kuah cuko", "mpek-mpek goreng"],
    "Tahu Bulat": ["tahu bulat goreng jajanan", "tahu bundar mengembang", "tahu bulat kriuk"],
    "Cilok": ["cilok aci dicolok", "cilok bumbu kacang jajanan", "cilok tusuk bulat"],
    "Kue Cubit": ["kue cubit setengah matang", "kue cubit topping coklat keju", "kue cubit mini Jakarta"],
    "Kroket": ["kroket kentang goreng Indonesia", "croquette daging ayam", "kroket goreng tepung roti"],
    "Es Teh Manis": ["es teh manis gelas Indonesia", "iced sweet tea Indonesia", "es teh manis warung"],
    "Es Jeruk": ["es jeruk peras segar", "jus jeruk dingin gelas", "fresh orange juice Indonesia"],
    "Kopi Susu": ["kopi susu manis gelas Indonesia", "coffee milk latte Indonesia", "kopi susu kekinian"],
    "Wedang Jahe": ["wedang jahe hangat Indonesia", "minuman jahe tradisional", "wedang ronde jahe"],
    "Es Dawet": ["es dawet cendol jawa", "es cendol santan gula merah", "dawet ayu banjarnegara"],
    "Susu Kedelai": ["susu kedelai putih gelas", "soy milk Indonesia", "susu kedelai hangat"],
    "Jus Buah": ["jus buah segar Indonesia", "fresh fruit juice gelas", "jus alpukat mangga Indonesia"],
    "Laksa": ["laksa betawi kuah santan", "mie laksa Indonesia", "laksa kuning santan kelapa"],
    "Ketoprak": ["ketoprak Jakarta lontong tahu", "ketoprak bumbu kacang bihun", "ketoprak jajanan betawi"],
    "Nasi Bakar": ["nasi bakar daun pisang Indonesia", "nasi bakar ayam ikan", "nasi bakar bumbu kuning"],
    "Nasi Tim": ["nasi tim ayam porridge", "nasi tim lembek mangkuk", "nasi tim anak Indonesia"],
    "Kolak": ["kolak pisang ubi santan", "kolak biji salak", "kolak manis berbuka"],
    "Gado Gado": ["gado gado sayur bumbu kacang", "gado-gado Jakarta lengkap", "peanut sauce vegetable salad Indonesia"],
    "Pisang": ["pisang ambon kuning segar", "pisang mas kepok Indonesia", "bunch of banana fresh"],
    "Semangka": ["semangka merah segar potongan", "watermelon slice Indonesia", "buah semangka daging merah"],
    "Mangga": ["mangga harum manis Indonesia", "mango slice segar", "buah mangga manalagi"],
    "Pepaya": ["pepaya california oranye", "buah pepaya potong segar", "papaya fruit Indonesia"],
    "Ubi Goreng": ["ubi goreng singkong goreng", "fried cassava Indonesia", "ubi jalar goreng crispy"],
    "Nugget Ayam": ["nugget ayam goreng crispy", "chicken nugget Indonesia", "nuget goreng anak"],
}

# ─── Request session dengan SSL verify=False (bypass Telkomsel interception) ──
_session = requests.Session()
_session.verify = False
_session.headers.update({
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/125.0.0.0 Safari/537.36"
    )
})


def _image_hash(img_bytes: bytes) -> str:
    return hashlib.md5(img_bytes).hexdigest()


def _make_placeholder_label(label_path: Path) -> None:
    label_path.write_text("", encoding="utf-8")


def _fetch_ddgs(query: str, n: int) -> list[str]:
    """Coba ambil URL gambar dari DDGS dengan verify=False."""
    urls = []
    try:
        # ddgs versi baru mendukung proxy/verify via env atau constructor
        # Coba dengan verify=False jika tersedia
        try:
            with DDGS(verify=False) as d:
                results = list(d.images(query, max_results=n * 2, type_image="photo", size="medium"))
                urls = [r.get("image", "") for r in results if r.get("image")]
        except TypeError:
            # Versi lama tidak punya parameter verify
            with DDGS() as d:
                results = list(d.images(query, max_results=n * 2, type_image="photo", size="medium"))
                urls = [r.get("image", "") for r in results if r.get("image")]
    except Exception as ex:
        print(f"  [DDG] gagal: {type(ex).__name__}")
    return urls


def _fetch_bing(query: str, n: int) -> list[str]:
    """Fallback: scraping Bing Image Search (tidak perlu API key)."""
    urls = []
    try:
        search_url = (
            f"https://www.bing.com/images/search"
            f"?q={requests.utils.quote(query)}&count={n * 2}&mmasync=1"
        )
        resp = _session.get(search_url, timeout=15)
        if resp.status_code == 200:
            import re
            # Cari URL gambar dalam respons HTML Bing
            found = re.findall(r'"murl":"(https?://[^"]+)"', resp.text)
            urls = found[:n * 2]
    except Exception as ex:
        print(f"  [Bing] gagal: {type(ex).__name__}")
    return urls


def _download_image(url: str) -> bytes | None:
    """Download satu gambar, toleran terhadap error SSL."""
    try:
        resp = _session.get(url, timeout=10)
        if resp.status_code == 200 and len(resp.content) > 1024:
            return resp.content
    except Exception:
        pass
    return None


def download_images_for_class(
    class_name: str,
    queries: list[str],
    train_img_dir: Path,
    valid_img_dir: Path,
    train_lbl_dir: Path,
    valid_lbl_dir: Path,
    n_per_class: int = IMAGES_PER_CLASS,
    valid_ratio: float = VALID_RATIO,
) -> int:
    safe_name = class_name.lower().replace(" ", "_")
    seen_hashes: set[str] = set()
    saved = 0
    valid_count = max(1, int(n_per_class * valid_ratio))
    train_count = n_per_class - valid_count

    for query in queries:
        if saved >= n_per_class:
            break

        # Coba DDG dulu, fallback ke Bing
        urls = _fetch_ddgs(query, n_per_class)
        if not urls:
            print(f"  [DDG blocked, coba Bing] query: {query[:40]}")
            urls = _fetch_bing(query, n_per_class)

        for url in urls:
            if saved >= n_per_class:
                break
            if not url or not url.startswith("http"):
                continue

            img_bytes = _download_image(url)
            if not img_bytes:
                continue

            h = _image_hash(img_bytes)
            if h in seen_hashes:
                continue

            try:
                img = Image.open(BytesIO(img_bytes)).convert("RGB")
                w, h_px = img.size
                if w < 80 or h_px < 80:
                    continue  # terlalu kecil
                seen_hashes.add(h)

                if saved < train_count:
                    out_img = train_img_dir / f"{safe_name}_{saved:04d}.jpg"
                    out_lbl = train_lbl_dir / f"{safe_name}_{saved:04d}.txt"
                else:
                    out_img = valid_img_dir / f"{safe_name}_{saved:04d}.jpg"
                    out_lbl = valid_lbl_dir / f"{safe_name}_{saved:04d}.txt"

                img.save(out_img, "JPEG", quality=85)
                _make_placeholder_label(out_lbl)
                saved += 1
            except Exception:
                continue

        time.sleep(0.3)

    return saved


def main():
    print("=" * 65)
    print("SEHATI-AI — Download Gambar Kelas Baru (bypass Telkomsel)")
    print("=" * 65)
    print(f"Kelas  : {len(NEW_CLASSES)}")
    print(f"Target : {IMAGES_PER_CLASS} gambar/kelas")
    print(f"Train  : {TRAIN_IMG}")
    print(f"Valid  : {VALID_IMG}")
    print(f"SSL    : verify=False (bypass Telkomsel interception)")
    print()

    for d in [TRAIN_IMG, TRAIN_LBL, VALID_IMG, VALID_LBL]:
        d.mkdir(parents=True, exist_ok=True)

    results: dict[str, int] = {}
    total = 0

    for class_name, queries in tqdm(NEW_CLASSES.items(), desc="Progress"):
        print(f"\n[{class_name}] ...")
        count = download_images_for_class(
            class_name=class_name,
            queries=queries,
            train_img_dir=TRAIN_IMG,
            valid_img_dir=VALID_IMG,
            train_lbl_dir=TRAIN_LBL,
            valid_lbl_dir=VALID_LBL,
        )
        results[class_name] = count
        total += count
        print(f"  -> {count} gambar disimpan")

    print("\n" + "=" * 65)
    print("RINGKASAN")
    print("=" * 65)
    for cls, cnt in results.items():
        status = "[OK]" if cnt >= int(IMAGES_PER_CLASS * 0.5) else "[!!]"
        print(f"  {status} {cls}: {cnt} gambar")

    print(f"\nTotal: {total} gambar baru ditambahkan")
    print()
    print("LANGKAH SELANJUTNYA:")
    print("  1. Anotasi gambar di Roboflow (https://roboflow.com) — GRATIS")
    print("     Upload folder train/valid, auto-annotate, export format YOLOv8")
    print("  2. Letakkan label .txt ke folder labels/")
    print("  3. Jalankan training GPU:")
    print("     python sehati_ai_backend/finetune_food_detection.py")
    print("=" * 65)


if __name__ == "__main__":
    main()
