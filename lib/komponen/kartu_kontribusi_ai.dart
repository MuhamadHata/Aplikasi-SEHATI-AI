import 'package:flutter/material.dart';
import '../inti/tema/design_tokens.dart';
import '../inti/layanan/layanan_feedback_ai.dart';

// ═══════════════════════════════════════════════════════════════════════════
// KartuKontribusiAI — Widget gamifikasi kontribusi fine-tuning
//
// Menampilkan:
// - Jumlah total koreksi AI yang pernah dikirim user
// - Badge level: Pemula / Kontributor / Pakar / Master AI
// - Progress bar menuju level berikutnya
// ═══════════════════════════════════════════════════════════════════════════
class KartuKontribusiAI extends StatefulWidget {
  /// Tampilkan versi compact (untuk beranda) atau full (untuk profil)
  final bool compact;

  const KartuKontribusiAI({super.key, this.compact = false});

  @override
  State<KartuKontribusiAI> createState() => _KartuKontribusiAIState();
}

class _KartuKontribusiAIState extends State<KartuKontribusiAI> {
  Map<String, int> _stats = {'total': 0, 'corrections': 0, 'confirmations': 0};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await AIFeedbackService.instance.getMyStats();
    if (mounted) setState(() { _stats = s; _loading = false; });
  }

  // ── Badge level berdasarkan total koreksi ─────────────────────────────
  _BadgeInfo _badgeFor(int corrections) {
    if (corrections >= 50) {
      return _BadgeInfo(Icons.health_and_safety_rounded, 'Master AI', const Color(0xFFFFD700), 50, null);
    } else if (corrections >= 20) {
      return _BadgeInfo(Icons.health_and_safety_rounded, 'Pakar', const Color(0xFF6C63FF), 20, 50);
    } else if (corrections >= 6) {
      return _BadgeInfo(Icons.health_and_safety_rounded, 'Kontributor', AppColors.primary, 6, 20);
    } else {
      return _BadgeInfo(Icons.health_and_safety_rounded, 'Pemula', AppColors.success, 0, 6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corrections = _stats['corrections'] ?? 0;
    final badge = _badgeFor(corrections);

    if (widget.compact) return _buildCompact(theme, corrections, badge);
    return _buildFull(theme, corrections, badge);
  }

  // ── Versi compact (untuk beranda, dalam card kecil) ───────────────────
  Widget _buildCompact(ThemeData theme, int corrections, _BadgeInfo badge) {
    return GestureDetector(
      onTap: _load,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: badge.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: badge.color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(badge.icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$corrections Koreksi AI',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: badge.color,
                  ),
                ),
                Text(
                  badge.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Versi full (untuk halaman profil) ────────────────────────────────
  Widget _buildFull(ThemeData theme, int corrections, _BadgeInfo badge) {
    final onSurface = theme.colorScheme.onSurface;
    final progress = badge.nextLevel != null
        ? (corrections - badge.currentLevel) /
            (badge.nextLevel! - badge.currentLevel)
        : 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badge.color.withValues(alpha: 0.12),
            badge.color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badge.color.withValues(alpha: 0.2)),
      ),
      child: _loading
          ? const Center(
              child: SizedBox(
                height: 30,
                width: 30,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: badge.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(badge.icon, size: 24, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kontribusi AI Saya',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: onSurface,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            badge.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: badge.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Total koreksi badge
                    Column(
                      children: [
                        Text(
                          '$corrections',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: badge.color,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          'koreksi',
                          style: TextStyle(
                            fontSize: 11,
                            color: onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Stats row ───────────────────────────────────────────
                Row(
                  children: [
                    _StatItem(
                      label: 'Total Feedback',
                      value: '${_stats['total']}',
                      color: badge.color,
                    ),
                    _StatItem(
                      label: 'Koreksi',
                      value: '${_stats['corrections']}',
                      color: AppColors.warning,
                    ),
                    _StatItem(
                      label: 'Konfirmasi',
                      value: '${_stats['confirmations']}',
                      color: AppColors.success,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Progress ke level berikutnya ────────────────────────
                if (badge.nextLevel != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Menuju level berikutnya',
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '$corrections / ${badge.nextLevel}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: badge.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: badge.color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(badge.color),
                      minHeight: 6,
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🏆', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 6),
                        Text(
                          'Level Tertinggi! Terima kasih atas kontribusimu!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB8860B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // ── Penjelasan singkat ──────────────────────────────────
                Text(
                  '💡 Setiap koreksi Anda membantu AI SEHATI-AI belajar lebih akurat '
                  'untuk semua pengguna melalui fine-tuning model.',
                  style: TextStyle(
                    fontSize: 11,
                    color: onSurface.withValues(alpha: 0.5),
                    height: 1.5,
                  ),
                ),
              ],
            ),
    );
  }
}

class _BadgeInfo {
  final IconData icon;
  final String label;
  final Color color;
  final int currentLevel;
  final int? nextLevel;
  const _BadgeInfo(this.icon, this.label, this.color, this.currentLevel, this.nextLevel);
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
