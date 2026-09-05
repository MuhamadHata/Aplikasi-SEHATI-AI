// ==========================================
// KOMPONEN: Indikator Koneksi & Status Sync
// Menampilkan banner offline dan status sinkronisasi ke Supabase
// ==========================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../penyedia/penyedia_aktivitas.dart';

/// Banner tipis yang muncul di atas layar saat:
/// - Tidak ada koneksi internet (offline)
/// - Terjadi error sinkronisasi ke Supabase
///
/// Gunakan dengan [Column] atau [Stack] di atas konten utama layar.
class IndikatorKoneksi extends StatelessWidget {
  const IndikatorKoneksi({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, _) {
        // Tampilkan hanya saat offline atau ada error
        if (provider.isOnline && provider.lastSyncError == null) {
          return const SizedBox.shrink();
        }

        final isOffline = !provider.isOnline;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isOffline
              ? Colors.orange.shade800.withValues(alpha: 0.9)
              : Colors.red.shade700.withValues(alpha: 0.9),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Icon(
                  isOffline ? Icons.wifi_off_rounded : Icons.sync_problem_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOffline
                        ? 'Tidak ada koneksi — data disimpan lokal'
                        : 'Gagal sinkronisasi — akan dicoba ulang',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                if (isOffline)
                  const SizedBox.shrink()
                else
                  GestureDetector(
                    onTap: () {
                      // Trigger manual sync
                      provider.syncNow();
                    },
                    child: const Text(
                      'Coba Ulang',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget loading kecil untuk menampilkan status sync aktif
/// Gunakan di AppBar atau di pojok layar
class IndikatorSync extends StatelessWidget {
  const IndikatorSync({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, _) {
        if (!provider.isSyncing) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Menyimpan...',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
