import sys, re, os

sys.stdout.reconfigure(encoding='utf-8')

log_path = r'C:\Users\M HATTA\.gemini\antigravity-ide\brain\cc517330-4bee-4d04-96e7-f3e7b01ac9e0\.system_generated\tasks\task-105.log'

with open(log_path, encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print('='*72)
print('  SEHATI-AI YOLO Training v3 - Status Log')
print('='*72)

# Kumpulkan baris yang benar-benar informatif
seen = set()
for raw in lines:
    line = raw.replace('\r', '').strip()
    if not line or len(line) < 8:
        continue
    # Skip progress bar lines (mengandung \r ditengah atau box drawing chars)
    if '\r' in raw and 'it/s' in raw:
        continue
    # Ambil baris penting
    important = any(kw in line for kw in [
        'Download', 'Konversi', 'gambar', 'dikonversi', 'Total',
        'SEHATI-AI', 'FASE', 'Kelas', 'Dataset', 'Output', 'Model',
        '====', '----',
        'Epoch', 'box_loss', 'cls_loss', 'dfl_loss', 'mAP',
        'Precision', 'Recall', 'best.pt', 'Stopping', 'patience',
        'Phase', 'Train', 'Val', 'Ultralytics', 'CUDA', 'GPU',
        'Overriding', 'Transferred', 'Freezing layer',
        'AMP:', 'albumentations', 'optimizer', 'lr0',
        'train: New cache', 'val: New cache', 'WARNING',
        '[OK]', '[FASE', '[WARN',
    ])
    if important and line not in seen:
        seen.add(line)
        # Ganti karakter unicode yang bermasalah
        line = line.replace('\u2192', '->')
        line = line.replace('\u2705', 'OK')
        line = line.replace('\u274c', 'X')
        print(line)

# Cari epoch terbaru dari progress bar
last_epoch = None
for raw in lines:
    m = re.search(r'(\d+)/(\d+)\s+[\d\.]+G\s+[\d\.]+\s+[\d\.]+\s+[\d\.]+', raw)
    if m:
        last_epoch = (int(m.group(1)), int(m.group(2)))

# Cari baris epoch summary (setelah epoch selesai, berisi metrics)
epoch_summaries = []
for raw in lines:
    # Baris epoch summary dari YOLO: "      15/30      1.97G ..."
    m = re.match(r'\s*(\d+)/(\d+)\s+([\d\.]+G)\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)', raw.replace('\r',''))
    if m:
        ep, total, mem, box, cls, dfl = m.groups()
        epoch_summaries.append(f"  Epoch {ep:>3}/{total}  | box={box} cls={cls} dfl={dfl} | GPU={mem}")

if epoch_summaries:
    print()
    print('--- Ringkasan per Epoch (terakhir 10) ---')
    for s in epoch_summaries[-10:]:
        print(s)

print()
print('='*72)
if last_epoch:
    pct = last_epoch[0] / last_epoch[1] * 100
    print(f'  STATUS: Epoch {last_epoch[0]}/{last_epoch[1]} ({pct:.0f}% Phase 1 selesai)')
    if last_epoch[0] < last_epoch[1]:
        remaining = last_epoch[1] - last_epoch[0]
        print(f'  Sisa: {remaining} epoch lagi di Phase 1')
    else:
        print('  Phase 1 SELESAI - Lanjut Phase 2...')
print('='*72)
