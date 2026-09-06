import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../penyedia/penyedia_aktivitas.dart';
import '../../inti/model/data_palsu.dart';
import '../../komponen/progres_lingkaran.dart';
import '../../komponen/kartu_statistik.dart';
import '../../komponen/kartu_artikel.dart';
import '../../komponen/kutipan_sumber.dart';
import '../../inti/model/model.dart';
import '../../inti/model/catatan_aktivitas.dart';
import '../../inti/tema/design_tokens.dart';
import '../../komponen/kartu_maskot_nubi.dart';
import '../../inti/ml/gait_quality_index.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  HOME SCREEN — Beranda SEHATI-AI
//  Semua spacing mengikuti grid 8pt, tipografi mengikuti skala, warna pakai token
// ═══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Article> _articles = MockData.articles;
  int _campaignIndex = 0;
  Timer? _campaignTimer;

  @override
  void initState() {
    super.initState();
    _campaignTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() => _campaignIndex = (_campaignIndex + 1) % _campaigns.length);
      }
    });
  }

  void _showSleepLoggerModal(BuildContext context, ActivityProvider ap) {
    final last = ap.lastSleepRecord;
    int bedtimeMin = last?.bedtimeMinute ?? (22 * 60);
    int wakeMin = last?.wakeMinute ?? (5 * 60 + 30);

    String fmt(int totalMin) {
      final h = (totalMin ~/ 60).toString().padLeft(2, '0');
      final m = (totalMin % 60).toString().padLeft(2, '0');
      return '$h:$m';
    }

    double calcDur(int bed, int wake) {
      if (wake > bed) return (wake - bed) / 60.0;
      return ((1440 - bed) + wake) / 60.0;
    }

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) {
          final dur = calcDur(bedtimeMin, wakeMin);
          final durH = dur.floor();
          final durM = ((dur - durH) * 60).round();
          final isOk = dur >= 7.0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx2).viewInsets.bottom +
                  MediaQuery.of(ctx2).padding.bottom +
                  24,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Catat Jam Tidur',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  'Pilih jam mulai tidur dan bangun untuk evaluasi pemulihan sel tubuh.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx2).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final h = bedtimeMin ~/ 60;
                          final m = bedtimeMin % 60;
                          final picked = await showTimePicker(
                            context: ctx2,
                            initialTime: TimeOfDay(hour: h, minute: m),
                            helpText: 'Pilih Waktu Mulai Tidur',
                          );
                          if (picked != null) {
                            setSt(() => bedtimeMin = picked.hour * 60 + picked.minute);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mulai Tidur 🌙', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                fmt(bedtimeMin),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final h = wakeMin ~/ 60;
                          final m = wakeMin % 60;
                          final picked = await showTimePicker(
                            context: ctx2,
                            initialTime: TimeOfDay(hour: h, minute: m),
                            helpText: 'Pilih Waktu Bangun',
                          );
                          if (picked != null) {
                            setSt(() => wakeMin = picked.hour * 60 + picked.minute);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bangun Tidur ☀️', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                fmt(wakeMin),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isOk ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(isOk ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                          color: isOk ? Colors.green : Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Total Durasi: $durH jam ${durM > 0 ? '$durM mnt' : ''} • ${isOk ? 'Ideal (≥7 jam) 👍' : 'Kurang (<7 jam) ⚠️'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOk ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ap.addSleepRecord(bedtimeMin, wakeMin);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Jam tidur berhasil dicatat: $durH jam $durM mnt!'),
                            backgroundColor: const Color(0xFF0F52BA),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Simpan Catatan Tidur', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F52BA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static const _campaigns = [
    _CampaignData(
      icon: Icons.water_drop_outlined,
      title: 'Hidrasi Cukup',
      tip: 'Minum 8 gelas air/hari mencegah batu ginjal, menjaga konsentrasi, dan membantu metabolisme tubuh.',
      citations: ['WHO Healthy Diet, 2024', 'Kemenkes RI Germas, 2020'],
      gradientLight: [Color(0xFFBAE6FD), Color(0xFFE0F2FE)],
      gradientDark: [Color(0xFF082F49), Color(0xFF0C4A6E)],
    ),
    _CampaignData(
      icon: Icons.directions_walk_outlined,
      title: 'Gerak Aktif Setiap Hari',
      tip: '150 menit per minggu aktivitas fisik sedang (jalan cepat, bersepeda) menurunkan risiko penyakit jantung hingga 35%.',
      citations: ['WHO PA Guidelines, 2020', 'Kemenkes RI Pedoman AktFisik, 2020'],
      gradientLight: [Color(0xFFA7F3D0), Color(0xFFD1FAE5)],
      gradientDark: [Color(0xFF064E3B), Color(0xFF065F46)],
    ),
    _CampaignData(
      icon: Icons.dark_mode_outlined,
      title: 'Tidur Berkualitas',
      tip: '7–9 jam tidur per malam menjaga imunitas, kesehatan mental, dan mencegah risiko diabetes tipe 2 & hipertensi.',
      citations: ['WHO Mental Health, 2021', 'Kemenkes RI Germas Tidur, 2021'],
      gradientLight: [Color(0xFFDDD6FE), Color(0xFFEDE9FE)],
      gradientDark: [Color(0xFF2E1065), Color(0xFF4C1D95)],
    ),
    _CampaignData(
      icon: Icons.restaurant_outlined,
      title: 'Makan Seimbang',
      tip: 'Konsumsi sayur dan buah ≥400g per hari. Ikuti panduan Isi Piringku: ½ piring sayur-buah, ¼ protein, ¼ karbohidrat.',
      citations: ['Kemenkes RI Isi Piringku, 2020', 'WHO Healthy Diet, 2023'],
      gradientLight: [Color(0xFFFDE68A), Color(0xFFFEF3C7)],
      gradientDark: [Color(0xFF451A03), Color(0xFF78350F)],
    ),
    _CampaignData(
      icon: Icons.medication,
      title: 'Bebas Rokok & Asap',
      tip: 'Merokok meningkatkan risiko kanker paru 15–30×. Berhenti merokok memperbaiki kondisi paru hanya dalam 12 jam.',
      citations: ['Kemenkes RI Tobacco Control, 2023', 'WHO Tobacco Fact Sheet, 2023'],
      gradientLight: [Color(0xFFFECDD3), Color(0xFFFFE4E6)],
      gradientDark: [Color(0xFF4C0519), Color(0xFF881337)],
    ),
  ];

  @override
  void dispose() {
    _campaignTimer?.cancel();
    _campaignTimer = null;
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 17) return 'Selamat Siang';
    return 'Selamat Malam';
  }

  void _showManualFoodDialog(BuildContext context) {
    final activity = context.read<ActivityProvider>();
    final nameController = TextEditingController();
    final calController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catat Makanan',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/input-manual-makanan');
              },
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Cari Database 1000+ Makanan',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('atau input cepat',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Makanan/Minuman',
                hintText: 'Misal: Nasi Goreng',
              ),
            ),
            const SizedBox(height: AppTokens.small),
            TextField(
              controller: calController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kalori (kkal)',
                hintText: 'Misal: 450',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final cal = int.tryParse(calController.text) ?? 0;
              if (name.isNotEmpty && cal > 0) {
                final success = activity.addFoodLog(name, cal);
                Navigator.pop(ctx);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal mencatat (sedang waktu puasa)')),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showCalorieDetails(
    BuildContext context,
    double bmi,
    int consumed,
    int burned,
    int targetBmr,
    int remaining,
  ) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Consumer<ActivityProvider>(
          builder: (ctx, activity, child) {
            final foodLogs = activity.foodLogs;
            final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
            final exerciseLogs = activity.history
                .where(
                    (r) => DateFormat('yyyy-MM-dd').format(r.date) == todayStr)
                .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (sheetCtx, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                          children: [
                            Text(
                              DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                                  .format(DateTime.now()),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: AppTypography.h2Weight,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(height: AppTokens.large),
                            // Health Score Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(ComponentSpec.cardRadius),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 80,
                                        height: 80,
                                        child: CircularProgressIndicator(
                                          value: activity.healthScore / 100,
                                          strokeWidth: 8,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.1),
                                          valueColor: AlwaysStoppedAnimation(
                                              Theme.of(context).colorScheme.primary),
                                        ),
                                      ),
                                      Text(
                                        '${activity.healthScore}',
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '/100 Poin',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).hintColor,
                                          ),
                                        ),
                                        Text(
                                          activity.healthScoreLabel,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTokens.large),
                            const _SectionHeader(
                              title: 'Statistik & Target',
                              icon: Icons.analytics_outlined,
                            ),
                            const SizedBox(height: AppTokens.medium),
                            _TargetRow(
                              label: 'Kalori Masuk',
                              icon: Icons.restaurant,
                              achieved: activity.calorieConsumed,
                              target: activity.calorieTarget,
                              unit: 'kkal',
                              color: Colors.orange,
                            ),
                            _TargetRow(
                              label: 'Kalori Terbakar',
                              icon: Icons.local_fire_department,
                              achieved: activity.caloriesBurned,
                              target: 300,
                              unit: 'kkal',
                              color: Colors.red,
                            ),
                            _TargetRow(
                              label: 'Langkah Kaki',
                              icon: Icons.directions_walk,
                              achieved: activity.steps,
                              target: activity.stepTarget,
                              unit: 'langkah',
                              color: Colors.blue,
                            ),
                            _TargetRow(
                              label: 'Air Minum',
                              icon: Icons.water_drop,
                              achieved: activity.waterGlasses,
                              target: activity.waterTarget,
                              unit: 'gelas',
                              color: Colors.cyan,
                            ),
                            const SizedBox(height: AppTokens.large),
                            const _SectionHeader(
                              title: 'Olahraga Hari Ini',
                              icon: Icons.fitness_center_outlined,
                            ),
                            const SizedBox(height: AppTokens.small),
                            if (exerciseLogs.isEmpty)
                              const _EmptyState(
                                  text: 'Belum ada olahraga hari ini',
                                  icon: Icons.directions_walk)
                            else
                              ...exerciseLogs.map((r) => _ActivityListTile(
                                    title: r.type,
                                    subtitle:
                                        '${(r.durationSeconds / 60).round()} min • ${r.distanceKm > 0 ? '${r.distanceKm.toStringAsFixed(2)} km' : '${r.steps} langkah'}',
                                    value: '${r.calories} kkal',
                                    icon: r.type.contains('Lari')
                                        ? Icons.directions_run
                                        : (r.type.contains('Jalan')
                                            ? Icons.directions_walk
                                            : Icons.fitness_center),
                                  )),
                            const SizedBox(height: AppTokens.large),
                            const _SectionHeader(
                              title: 'Makanan & Minuman',
                              icon: Icons.restaurant_menu_outlined,
                            ),
                            const SizedBox(height: AppTokens.small),
                            if (foodLogs.isEmpty)
                              const _EmptyState(
                                  text: 'Belum ada makanan tercatat',
                                  icon: Icons.restaurant_menu)
                            else
                              ...foodLogs.map((f) => _ActivityListTile(
                                    title: f.foodName,
                                    subtitle: f.time,
                                    value: '${f.calories} kkal',
                                    icon: Icons.restaurant,
                                  )),
                            const SizedBox(height: AppTokens.large),
                            ElevatedButton(
                              onPressed: () {
                                if (mounted) {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/monthly-health');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, ComponentSpec.btnHeight),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(ComponentSpec.btnRadiusClean)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Lihat Laporan Bulanan',
                                style: TextStyle(
                                    fontSize: AppTypography.buttonSize,
                                    fontWeight: AppTypography.buttonWeight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Consumer<ActivityProvider>(
          builder: (context, activity, child) {
            final now = DateTime.now();
            List<Widget> messages = [];

            // Evaluasi Air
            final waterMilestones = {9: 1, 12: 3, 15: 5, 18: 7, 21: 8};
            for (var entry in waterMilestones.entries) {
              if (now.hour >= entry.key) {
                final expected =
                    (activity.waterTarget * (entry.value / 8.0)).ceil();
                if (activity.waterGlasses < expected) {
                  messages.add(_buildNotificationTile(
                    context,
                    'Kurang Minum Air',
                    'Waktu sudah jam ${entry.key}:00, tapi kamu baru minum ${activity.waterGlasses} dari $expected gelas.',
                    Theme.of(context).extension<AppThemeExtension>()?.info ??
                        AppColors.info,
                  ));
                  break;
                }
              }
            }

            // Evaluasi Olahraga
            if (activity.caloriesBurned == 0 && now.hour >= 18) {
              messages.add(_buildNotificationTile(
                context,
                'Belum Olahraga Penuh',
                'Hari sudah sore/malam dan kamu belum melakukan aktivitas olahraga hari ini.',
                Theme.of(context).extension<AppThemeExtension>()?.warning ??
                    AppColors.warning,
              ));
            } else if (activity.caloriesBurned == 0 && now.hour >= 9) {
              messages.add(_buildNotificationTile(
                context,
                'Yuk Gerak Sejenak!',
                'Belum ada aktivitas tercatat hari ini. Coba sempatkan 10-15 menit untuk badan lebih segar.',
                Theme.of(context).extension<AppThemeExtension>()?.warning ??
                    AppColors.warning,
              ));
            }

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppTokens.medium,
                  right: AppTokens.medium,
                  top: AppTokens.medium,
                  bottom: MediaQuery.of(context).padding.bottom + AppTokens.medium,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifikasi',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: AppTypography.h2Weight,
                          ),
                    ),
                    const SizedBox(height: AppTokens.medium),
                    if (messages.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Kamu Hebat! Semua target tercapai sejauh ini.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: AppTypography.body2Weight,
                                ),
                          ),
                        ),
                      )
                    else
                      ...messages,
                    const SizedBox(height: AppTokens.medium),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ComponentSpec.btnRadiusClean)),
                        ),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: AppTypography.buttonWeight),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationTile(BuildContext context, String title, String subtitle, Color defaultColor) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: defaultColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(ComponentSpec.cardRadius - 2),
            ),
            child: Icon(
              Icons.warning_amber_outlined,
              size: 22,
              color: defaultColor,
            ),
          ),
          title: Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleMedium?.color)),
          subtitle: Text(subtitle,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color)),
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(height: AppTokens.medium),
      ],
    );
  }

  void _showDailyDetail(
    BuildContext context,
    DailySummary summary,
    ActivityProvider activity,
    NumberFormat formatter,
  ) {
    final dateParse = DateFormat('yyyy-MM-dd').parse(summary.date);
    final labelDate =
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dateParse);

    // Health score
    final waterScore = (summary.waterGlasses / 8).clamp(0.0, 1.0);
    final stepsScore = (summary.steps / 10000).clamp(0.0, 1.0);
    final overallScore = ((waterScore + stepsScore) / 2 * 100).round();

    String status;
    Color statusColor;
    if (overallScore >= 75) {
      status = 'Hari yang Aktif!';
      statusColor = AppColors.success;
    } else if (overallScore >= 50) {
      status = 'Cukup Aktif';
      statusColor = AppColors.warning;
    } else {
      status = 'Kurang Aktif';
      statusColor = AppColors.error;
    }

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (ctx, scroll) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      labelDate,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: AppTypography.h2Weight,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                    ),
                    const SizedBox(height: AppTokens.medium),
                    // Health score banner
                    Container(
                      padding: const EdgeInsets.all(ComponentSpec.cardPadding),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(ComponentSpec.cardRadius),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '$overallScore',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                          ),
                          const SizedBox(width: AppTokens.small),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '/100 Poin',
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: AppTypography.captionSize,
                                ),
                              ),
                              Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: AppTypography.h3Weight,
                                  fontSize: AppTypography.h3Size,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTokens.medium),
                    Text(
                      'Statistik Harian',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: AppTypography.h3Weight,
                          ),
                    ),
                    const SizedBox(height: AppTokens.small),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDailyDetailTile(
                            context: context,
                            icon: Icons.directions_walk_rounded,
                            iconColor: const Color(0xFF6366F1),
                            label: 'Langkah Kaki',
                            value: '${formatter.format(summary.steps)} lgh',
                            target: 'Target 10.000',
                            progress: (summary.steps / 10000).clamp(0.0, 1.0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDailyDetailTile(
                            context: context,
                            icon: Icons.local_fire_department_rounded,
                            iconColor: const Color(0xFFF97316),
                            label: 'Kalori Terbakar',
                            value: '${formatter.format(summary.caloriesBurned)} kkal',
                            target: 'Target 300 kkal',
                            progress: (summary.caloriesBurned / 300).clamp(0.0, 1.0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDailyDetailTile(
                            context: context,
                            icon: Icons.water_drop_rounded,
                            iconColor: const Color(0xFF0EA5E9),
                            label: 'Air Minum',
                            value: '${summary.waterGlasses} gelas',
                            target: 'Target 8 gelas',
                            progress: (summary.waterGlasses / 8).clamp(0.0, 1.0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDailyDetailTile(
                            context: context,
                            icon: Icons.restaurant_rounded,
                            iconColor: const Color(0xFF10B981),
                            label: 'Kalori Masuk',
                            value: '${formatter.format(summary.caloriesConsumed)} kkal',
                            target: 'Target 2.100 kkal',
                            progress: (summary.caloriesConsumed / 2100).clamp(0.0, 1.0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.medium),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/monthly-health');
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ComponentSpec.btnRadiusClean)),
                        ),
                        child: Text(
                          'Lihat Laporan Bulanan',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: AppTypography.buttonWeight,
                            fontSize: AppTypography.buttonSize,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyDetailTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String target,
    required double progress,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: iconColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(iconColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            target,
            style: TextStyle(
              fontSize: 9.5,
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMetricRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
  }) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(icon, size: 11, color: iconColor),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.75),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: Theme.of(context).textTheme.titleSmall?.color,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2.5),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.65),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ActivityProvider>();
    final formatter = NumberFormat('#,###', 'id_ID');

    final calorieConsumed = activity.calorieConsumed;
    final calorieTarget = activity.calorieTarget;
    final waterConsumed = activity.waterGlasses;
    final waterTarget = activity.waterTarget;
    final stepsToday = activity.steps;
    final stepsTarget = activity.stepTarget;
    final calBurned = activity.caloriesBurned;
    final bmi = activity.bmi;
    final currentDate = activity.currentDateFormatted;

    final totalAllowed = calorieTarget + calBurned;
    final remainingCal = (totalAllowed - calorieConsumed) > 0
        ? (totalAllowed - calorieConsumed)
        : 0;

    final calProgress = (calorieConsumed / totalAllowed).clamp(0.0, 1.0);
    final waterProgress = (waterConsumed / waterTarget).clamp(0.0, 1.0);
    final stepsProgress = (stepsToday / stepsTarget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ActivityProvider>().refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.05),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 55, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: AppTypography.body2Weight,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      activity.userName,
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'Poppins',
                                            color: Theme.of(context).textTheme.titleLarge?.color,
                                            letterSpacing: -0.5,
                                            height: 1.2,
                                          ) ??
                                          const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'Poppins',
                                            letterSpacing: -0.5,
                                            height: 1.2,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (activity.mbti != null && activity.mbti!.trim().isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => Navigator.pushNamed(context, '/tes-mbti'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context).colorScheme.primary,
                                              Theme.of(context).colorScheme.secondary,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              '🧠 ',
                                              style: TextStyle(fontSize: 10),
                                            ),
                                            Text(
                                              activity.mbti!.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                fontFamily: 'Poppins',
                                                color: Colors.white,
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(ComponentSpec.cardRadius - 2),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Image.asset(
                                'assets/images/logo_brin.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showNotifications(context),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(ComponentSpec.cardRadius - 2),
                                    ),
                                    child: Icon(
                                      Icons.notifications_outlined,
                                      size: 22,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.secondary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.surface,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.small),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: AppTypography.body2Weight,
                              ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (Theme.of(context)
                                    .extension<AppThemeExtension>()
                                    ?.success ??
                                AppColors.success)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                            border: Border.all(
                              color: (Theme.of(context)
                                      .extension<AppThemeExtension>()
                                      ?.success ??
                                  AppColors.success)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'BMI ${bmi.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: AppTypography.captionSize,
                              color: Theme.of(context)
                                  .extension<AppThemeExtension>()
                                  ?.success ??
                                  AppColors.success,
                              fontWeight: AppTypography.captionWeight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Calorie Ring Card
                  GestureDetector(
                    onTap: () => _showCalorieDetails(
                      context,
                      bmi,
                      calorieConsumed,
                      calBurned,
                      calorieTarget,
                      remainingCal,
                    ),
                    child: _GradientCard(
                      colors: Theme.of(context)
                              .extension<AppThemeExtension>()
                              ?.gradientCard ??
                          AppColors.gradientCard,
                      child: Row(
                        children: [
                          RingProgress(
                            size: 130,
                            strokeWidth: 14,
                            progress: calProgress,
                            color: Theme.of(context).colorScheme.primary,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$calorieConsumed',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).textTheme.titleLarge?.color,
                                      ),
                                ),
                                Text(
                                  'kkal',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kalori Hari Ini',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: AppTypography.h3Weight,
                                      ),
                                ),
                                const SizedBox(height: AppTokens.medium),
                                _CalStat(
                                  color: Theme.of(context)
                                          .extension<AppThemeExtension>()
                                          ?.success ??
                                      AppColors.success,
                                  label: 'Tersisa',
                                  value: '$remainingCal kkal',
                                ),
                                _CalStat(
                                  color: Theme.of(context).colorScheme.secondary,
                                  label: 'Masuk',
                                  value: '$calorieConsumed kkal',
                                ),
                                _CalStat(
                                  color: Theme.of(context)
                                          .extension<AppThemeExtension>()
                                          ?.warning ??
                                      AppColors.warning,
                                  label: 'Terbakar',
                                  value: '$calBurned kkal',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.medium),
                  // Stats row
                  Row(
                    children: [
                      StatCard(
                        icon: Icons.water_drop_rounded,
                        label: 'Air Minum',
                        value: '$waterConsumed/$waterTarget',
                        unit: 'gls',
                        gradientColors: Theme.of(context).brightness == Brightness.dark
                            ? [
                                const Color(0xFF0369A1),
                                const Color(0xFF0284C7),
                              ]
                            : const [
                                Color(0xFF0284C7),
                                Color(0xFF38BDF8),
                              ],
                      ),
                      StatCard(
                        icon: Icons.directions_walk_rounded,
                        label: 'Langkah',
                        value: formatter.format(stepsToday),
                        unit: 'steps',
                        gradientColors: Theme.of(context).brightness == Brightness.dark
                            ? [
                                const Color(0xFF1E3A8A),
                                const Color(0xFF2563EB),
                              ]
                            : const [
                                Color(0xFF2563EB),
                                Color(0xFF60A5FA),
                              ],
                      ),
                      StatCard(
                        icon: Icons.local_fire_department_rounded,
                        label: 'Terbakar',
                        value: calBurned.toString(),
                        unit: 'kkal',
                        gradientColors: Theme.of(context).brightness == Brightness.dark
                            ? [
                                const Color(0xFF9A3412),
                                const Color(0xFFEA580C),
                              ]
                            : const [
                                Color(0xFFEA580C),
                                Color(0xFFFB923C),
                              ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.medium),

                  // ── 1. Catat Jam Tidur Card (Image 1) ──
                  _SleepLogQuickCard(
                    onTap: () => _showSleepLoggerModal(context, activity),
                  ),
                  const SizedBox(height: 14),

                  // ── 2. Kesehatan Komposit Card (Image 1) ──
                  _CompositeHealthCard(
                    compositeScore: activity.currentCompositeScore,
                    trend: activity.compositeTrend,
                    points: activity.healthTrajectoryPoints,
                    onTap: () => Navigator.pushNamed(context, '/health-trends'),
                  ),
                  const SizedBox(height: 14),

                  // ── 3. Widget Asisten SEHATI-AI Nubi (Berganti Otomatis) ──
                  const NubiMascotCard(),
                  const SizedBox(height: AppTokens.medium),

                  // Water section
                  const _SectionHeader(
                    title: 'Konsumsi Air',
                    icon: Icons.water_drop_outlined,
                  ),
                  _GradientCard(
                    colors: Theme.of(context)
                            .extension<AppThemeExtension>()
                            ?.gradientCard ??
                        AppColors.gradientCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '$waterConsumed gelas',
                                        style: TextStyle(
                                          fontSize: AppTypography.h1Size,
                                          fontWeight: AppTypography.h1Weight,
                                          color: Theme.of(context)
                                              .extension<AppThemeExtension>()
                                              ?.info ??
                                          AppColors.info,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'dari $waterTarget gelas/hari',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontWeight: AppTypography.body2Weight,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTokens.small),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                                    child: LinearProgressIndicator(
                                      value: waterProgress,
                                      backgroundColor: Theme.of(context)
                                          .dividerColor
                                          .withValues(alpha: 0.1),
                                      valueColor: AlwaysStoppedAnimation(
                                        Theme.of(context)
                                                .extension<AppThemeExtension>()
                                                ?.info ??
                                            AppColors.info,
                                      ),
                                      minHeight: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(ComponentSpec.cardRadius - 2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => activity.removeWater(),
                                    icon: const Icon(Icons.remove, size: 20),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Kurangi',
                                  ),
                                  Container(
                                    width: 1,
                                    height: 20,
                                    color: Theme.of(context)
                                        .dividerColor
                                        .withValues(alpha: 0.2),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      if (!activity.addWater()) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Batas minum tercapai atau sedang waktu puasa'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.add, size: 20),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Tambah',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.small),
                        Text(
                          'Tap + untuk menambah, - untuk mengurangi',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.medium),
                  // Steps section
                  const _SectionHeader(
                    title: 'Langkah Kaki',
                    icon: Icons.directions_walk_outlined,
                  ),
                  _GradientCard(
                    colors: Theme.of(context)
                            .extension<AppThemeExtension>()
                            ?.gradientCard ??
                        AppColors.gradientCard,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatter.format(stepsToday),
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontWeight: AppTypography.h1Weight,
                                    color: Theme.of(context)
                                        .extension<AppThemeExtension>()
                                        ?.success ??
                                    AppColors.success,
                                    fontFamily: 'Poppins',
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '/ ${formatter.format(stepsTarget)} langkah',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: AppTypography.body2Weight,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.small),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                          child: LinearProgressIndicator(
                            value: stepsProgress,
                            backgroundColor: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(
                              Theme.of(context)
                                      .extension<AppThemeExtension>()
                                      ?.success ??
                                  AppColors.success,
                            ),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: AppTokens.small),
                        Text(
                          '${(stepsProgress * 100).round()}% dari target harian',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  activity.requestActivityPermissions();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Pedometer di-refresh'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Refresh'),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/step-calculator'),
                                icon: const Icon(Icons.calculate, size: 18),
                                label: const Text('Kalkulator'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.medium),
                  // SEHATI-AI Quick Access
                  const _SectionHeader(
                    title: 'SEHATI-AI',
                    icon: Icons.auto_awesome_outlined,
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _AIQuickCard(
                          icon: Icons.edit_outlined,
                          label: 'Catat\nManual',
                          gradient: Theme.of(context).brightness == Brightness.dark
                              ? [
                                const Color(0xFF1E293B),
                                const Color(0xFF334155),
                              ]
                              : const [Color(0xFFE2E8F0), Color(0xFFF1F5F9)],
                          onTap: () => _showManualFoodDialog(context),
                        ),
                        const SizedBox(width: 10),
                        _AIQuickCard(
                          icon: Icons.camera_alt_outlined,
                          label: 'Scan\nMakanan',
                          gradient: Theme.of(context).brightness == Brightness.dark
                              ? [
                                const Color(0xFF451A03),
                                const Color(0xFF78350F),
                              ]
                              : const [Color(0xFFFDE68A), Color(0xFFFEF3C7)],
                          onTap: () => Navigator.pushNamed(context, '/food-scan'),
                        ),
                        const SizedBox(width: 10),
                        _AIQuickCard(
                          icon: Icons.water_drop_outlined,
                          label: 'Gula\nDarah',
                          gradient: Theme.of(context).brightness == Brightness.dark
                              ? [
                                const Color(0xFF4C0519),
                                const Color(0xFF881337),
                              ]
                              : const [Color(0xFFFFE4E6), Color(0xFFFECDD3)],
                          onTap: () => Navigator.pushNamed(context, '/blood-glucose'),
                        ),
                        const SizedBox(width: 10),
                        _AIQuickCard(
                          icon: Icons.photo_camera_outlined,
                          label: 'Beauty\nScan',
                          gradient: Theme.of(context).brightness == Brightness.dark
                              ? [
                                const Color(0xFF4C0519),
                                const Color(0xFF881337),
                              ]
                              : const [Color(0xFFFECDD3), Color(0xFFFFE4E6)],
                          onTap: () => Navigator.pushNamed(context, '/beauty-scan'),
                        ),
                        const SizedBox(width: 10),
                        _AIQuickCard(
                          icon: Icons.fitness_center_outlined,
                          label: 'AI\nWorkout',
                          gradient: Theme.of(context).brightness == Brightness.dark
                              ? [
                                const Color(0xFF064E3B),
                                const Color(0xFF065F46),
                              ]
                              : const [Color(0xFFA7F3D0), Color(0xFFD1FAE5)],
                          onTap: () {
                            final provider = context.read<ActivityProvider>();
                            if (provider.hasWorkoutPreferences) {
                              Navigator.pushNamed(context, '/workout-ai');
                            } else {
                              Navigator.pushNamed(
                                  context, '/workout-preferences');
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        _AIQuickCard(
                          icon: Icons.bloodtype_outlined,
                          label: 'SEHATI-AI\nDiabetes',
                          gradient: Theme.of(context).brightness == Brightness.dark
                              ? [
                                const Color(0xFF082F49),
                                const Color(0xFF0C4A6E),
                              ]
                              : const [Color(0xFFBAE6FD), Color(0xFFE0F2FE)],
                          onTap: () => Navigator.pushNamed(context, '/diabetes-scan'),
                        ),
                        const SizedBox(width: 10),
                        _AIQuickCard(
                          icon: Icons.trending_up_rounded,
                          label: 'Tren\nKesehatan',
                          gradient: Theme.of(context).brightness == Brightness.dark
                              ? [
                                const Color(0xFF1E1B4B),
                                const Color(0xFF312E81),
                              ]
                              : const [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                          onTap: () => Navigator.pushNamed(context, '/health-trends'),
                        ),
                        const SizedBox(width: 10),
                        _AIQuickCard(
                          icon: Icons.directions_walk_rounded,
                          label: 'Gait\nAnalysis',
                          gradient: Theme.of(context).brightness == Brightness.dark
                              ? [
                                const Color(0xFF0C4A6E),
                                const Color(0xFF0369A1),
                              ]
                              : const [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                          onTap: () => Navigator.pushNamed(context, '/gait-analysis'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.medium),
                  // Articles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionHeader(
                        title: 'Artikel Kesehatan',
                        icon: Icons.menu_book_outlined,
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: AppTypography.buttonSize,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: AppTypography.buttonWeight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.small),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _articles.length,
                      itemBuilder: (context, i) =>
                          ArticleCard(article: _articles[i]),
                    ),
                  ),
                  const SizedBox(height: AppTokens.medium),
                  // History section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionHeader(
                        title: 'Riwayat Harian',
                        icon: Icons.calendar_today_outlined,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/monthly-health'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                          ),
                          child: Text(
                            'Laporan Bulanan',
                            style: TextStyle(
                              fontSize: AppTypography.captionSize,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: AppTypography.captionWeight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.small),
                  activity.dailySummariesWithToday.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppTokens.medium),
                          child: Text(
                            'Belum ada riwayat harian.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: AppTypography.body2Weight,
                                ),
                          ),
                        )
                      : SizedBox(
                          height: 195,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: activity.dailySummariesWithToday.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final summary = activity.dailySummariesWithToday[i];
                              final dateParse =
                                  DateFormat('yyyy-MM-dd').parse(summary.date);
                              final labelDate = DateFormat('dd MMM', 'id_ID')
                                  .format(dateParse);
                              final todayKey =
                                  DateFormat('yyyy-MM-dd').format(DateTime.now());
                              final dayName = summary.date == todayKey
                                  ? 'Hari Ini'
                                  : DateFormat('EEEE', 'id_ID')
                                      .format(dateParse);

                              final String statusText;
                              final Color statusColor;
                              if (summary.steps >= 6000 || summary.caloriesBurned >= 200) {
                                statusText = 'Aktif';
                                statusColor = const Color(0xFF10B981);
                              } else if (summary.steps >= 2000 || summary.caloriesBurned >= 80) {
                                statusText = 'Cukup';
                                statusColor = const Color(0xFF3B82F6);
                              } else {
                                statusText = 'Santai';
                                statusColor = const Color(0xFFF59E0B);
                              }

                              return GestureDetector(
                                onTap: () => _showDailyDetail(
                                    context, summary, activity, formatter),
                                child: Container(
                                  width: 215,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withValues(alpha: 0.09),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                labelDate,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'Poppins',
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.color,
                                                ),
                                              ),
                                              Text(
                                                dayName,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color
                                                      ?.withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: statusColor.withValues(alpha: 0.25),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              statusText,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Divider(
                                        height: 1,
                                        color: Theme.of(context)
                                            .dividerColor
                                            .withValues(alpha: 0.07),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDailyMetricRow(
                                        context: context,
                                        icon: Icons.directions_walk_rounded,
                                        iconColor: const Color(0xFF6366F1),
                                        label: 'Langkah',
                                        value: formatter.format(summary.steps),
                                        unit: 'langkah',
                                      ),
                                      const SizedBox(height: 5),
                                      _buildDailyMetricRow(
                                        context: context,
                                        icon: Icons.local_fire_department_rounded,
                                        iconColor: const Color(0xFFF97316),
                                        label: 'Terbakar',
                                        value: formatter.format(summary.caloriesBurned),
                                        unit: 'kkal',
                                      ),
                                      const SizedBox(height: 5),
                                      _buildDailyMetricRow(
                                        context: context,
                                        icon: Icons.water_drop_rounded,
                                        iconColor: const Color(0xFF0EA5E9),
                                        label: 'Air Minum',
                                        value: '${summary.waterGlasses}',
                                        unit: 'gelas',
                                      ),
                                      const SizedBox(height: 5),
                                      _buildDailyMetricRow(
                                        context: context,
                                        icon: Icons.restaurant_rounded,
                                        iconColor: const Color(0xFF10B981),
                                        label: 'Asupan',
                                        value: formatter.format(summary.caloriesConsumed),
                                        unit: 'kkal',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: AppTokens.medium),
                  // Campaign Hidup Sehat
                  _HealthCampaignBanner(
                    campaigns: _campaigns,
                    currentIndex: _campaignIndex,
                    onDotTap: (i) => setState(() => _campaignIndex = i),
                  ),
                  const SizedBox(height: AppTokens.medium),
                  // Fasting Mode Panel
                  if (activity.fastingMode != 'none') ...[
                    _FastingModePanel(activity: activity),
                    const SizedBox(height: AppTokens.medium),
                  ],
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  DATA & WIDGET HELPER
// ═══════════════════════════════════════════════════════════════════════════════

class _CampaignData {
  final IconData icon;
  final String title;
  final String tip;
  final List<String> citations;
  final List<Color> gradientLight;
  final List<Color> gradientDark;

  const _CampaignData({
    required this.icon,
    required this.title,
    required this.tip,
    required this.citations,
    required this.gradientLight,
    required this.gradientDark,
  });
}

class _HealthCampaignBanner extends StatelessWidget {
  final List<_CampaignData> campaigns;
  final int currentIndex;
  final void Function(int) onDotTap;

  const _HealthCampaignBanner({
    required this.campaigns,
    required this.currentIndex,
    required this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final camp = campaigns[currentIndex];
    final colors = isDark ? camp.gradientDark : camp.gradientLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Campaign Hidup Sehat',
          icon: Icons.eco_outlined,
        ),
        AnimatedSwitcher(
          duration: AppTokens.smallAnim, // 200ms — sesuai spesifikasi mikro
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                      begin: const Offset(0.05, 0), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          ),
          child: Container(
            key: ValueKey(currentIndex),
            padding: const EdgeInsets.all(ComponentSpec.cardPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              border: Border.all(color: colors.first.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(camp.icon, size: 24, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        camp.title,
                        style: TextStyle(
                          fontSize: AppTypography.body1Size,
                          fontWeight: AppTypography.buttonWeight,
                          color: theme.colorScheme.onSurface,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.small),
                Text(
                  camp.tip,
                  style: TextStyle(
                    fontSize: AppTypography.body2Size,
                    height: AppTypography.body2Lh,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: AppTokens.small),
                CitationWidget(sources: camp.citations),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTokens.small),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            campaigns.length,
            (i) => GestureDetector(
              onTap: () => onDotTap(i),
              child: AnimatedContainer(
                duration: AppTokens.smallAnim,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == currentIndex ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == currentIndex
                      ? theme.colorScheme.primary
                      : theme.dividerColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FastingModePanel extends StatelessWidget {
  final ActivityProvider activity;

  const _FastingModePanel({required this.activity});

  String _formatCountdown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '$h jam $m mnt';
    return '$m mnt';
  }

  DateTime _todayAt(int minuteOfDay) {
    final now = DateTime.now();
    return DateTime(
        now.year, now.month, now.day, minuteOfDay ~/ 60, minuteOfDay % 60);
  }

  Duration _timeToMinute(int targetMinute) {
    final now = DateTime.now();
    var target = _todayAt(targetMinute);
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target.difference(now);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRamadan = activity.fastingMode == 'ramadan';
    final isIF = activity.fastingMode == 'if';
    final isFasting = activity.isFastingNow;
    final phaseLabel = activity.fastingPhaseLabel;
    final canDrink = activity.canDrinkWaterNow;

    final headerColor = isRamadan
        ? (isDark ? const Color(0xFF5B21B6) : const Color(0xFF7C3AED))
        : (isDark ? const Color(0xFF065F46) : const Color(0xFF059669));
    final bgColors = isRamadan
        ? (isDark
            ? [const Color(0xFF1E0B3A), const Color(0xFF2E1065)]
            : [const Color(0xFFEDE9FE), const Color(0xFFF5F3FF)])
        : (isDark
            ? [const Color(0xFF022C22), const Color(0xFF064E3B)]
            : [const Color(0xFFD1FAE5), const Color(0xFFECFDF5)]);

    final int nextTargetMinute;
    final String nextLabel;
    if (isRamadan) {
      if (isFasting) {
        nextTargetMinute = activity.ramadanIftarMinute;
        nextLabel = 'Buka puasa';
      } else {
        nextTargetMinute = activity.ramadanSuhoorEndMinute;
        nextLabel = 'Imsak/Sahur selesai';
      }
    } else {
      if (isFasting) {
        nextTargetMinute = activity.ifEatStartMinute;
        nextLabel = 'Mulai makan';
      } else {
        nextTargetMinute = activity.ifEatEndMinute;
        nextLabel = 'Selesai jendela makan';
      }
    }

    final countdown = _timeToMinute(nextTargetMinute);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: headerColor.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(ComponentSpec.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRamadan ? Icons.calendar_today : Icons.timer_outlined,
                size: 22,
                color: headerColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRamadan ? 'Mode Puasa Ramadan' : 'Intermittent Fasting',
                      style: TextStyle(
                        fontSize: AppTypography.body1Size,
                        fontWeight: AppTypography.buttonWeight,
                        color: headerColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      phaseLabel,
                      style: TextStyle(
                        fontSize: AppTypography.captionSize,
                        fontWeight: AppTypography.captionWeight,
                        color: headerColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.small),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.small, vertical: AppTokens.micro),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 18, color: headerColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextLabel,
                        style: TextStyle(
                          fontSize: AppTypography.captionSize,
                          color: headerColor.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        _formatCountdown(countdown),
                        style: TextStyle(
                          fontSize: AppTypography.h2Size,
                          fontWeight: AppTypography.h2Weight,
                          color: headerColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.small),
          Container(
            padding: const EdgeInsets.all(ComponentSpec.inputPaddingV),
            decoration: BoxDecoration(
              color: canDrink
                  ? const Color(0xFF0EA5E9).withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              border: Border.all(
                color: canDrink
                    ? const Color(0xFF0EA5E9).withValues(alpha: 0.25)
                    : Colors.grey.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  canDrink ? Icons.water_drop : Icons.block,
                  size: 20,
                  color: canDrink ? const Color(0xFF0EA5E9) : theme.hintColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    canDrink
                        ? (isIF
                            ? 'Air putih boleh diminum saat puasa IF. Tetap terhidrasi.'
                            : 'Waktu minum: manfaatkan jendela makan untuk hidrasi cukup.')
                        : 'Sedang berpuasa Ramadan – air minum tersedia saat berbuka.',
                    style: TextStyle(
                      fontSize: AppTypography.captionSize,
                      height: AppTypography.captionLh,
                      color: canDrink ? const Color(0xFF0EA5E9) : theme.hintColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.small),
          Text(
            isFasting
                ? 'Olahraga ringan (30–60 mnt sebelum buka) aman & efektif membakar lemak saat puasa.'
                : 'Jendela makan: konsumsi protein & serat cukup untuk energi optimal.',
            style: TextStyle(
              fontSize: AppTypography.captionSize,
              height: AppTypography.captionLh,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: AppTokens.micro),
          CitationWidget(
            sources: isRamadan
                ? ['MUI & Kemenkes RI, 2022', 'WHO Nutrition, 2021']
                : ['Kemenkes RI Germas, 2020', 'Patterson et al., 2015'],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.h3Weight,
                letterSpacing: -0.2,
              ),
        ),
      ],
    );
  }
}

class _GradientCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;

  const _GradientCard({required this.colors, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(ComponentSpec.cardRadius),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor
              .withValues(alpha: isDark ? 0.15 : 0.08),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      padding: const EdgeInsets.all(ComponentSpec.cardPadding),
      child: child,
    );
  }
}

class _CalStat extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _CalStat({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.small),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.captionSize,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.body2Size,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AIQuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _AIQuickCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Derive readable text color
    final Color aiTextColor;
    if (isDark) {
      aiTextColor = Colors.white.withValues(alpha: 0.9);
    } else {
      final hsl = HSLColor.fromColor(gradient.first);
      aiTextColor = hsl.lightness > 0.5
          ? hsl
              .withLightness(0.22)
              .withSaturation((hsl.saturation * 0.85).clamp(0.0, 1.0))
              .toColor()
          : gradient.last.withValues(alpha: 0.9);
    }

    return SizedBox(
      width: 95,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(ComponentSpec.cardRadius),
            border: Border.all(
              color: gradient.last.withValues(alpha: isDark ? 0.4 : 0.25),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: gradient.last.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: aiTextColor,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.captionSize,
                  fontWeight: AppTypography.captionWeight,
                  color: aiTextColor,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _TargetRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final int achieved;
  final int target;
  final String unit;
  final Color color;

  const _TargetRow({
    required this.label,
    required this.icon,
    required this.achieved,
    required this.target,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (achieved / target).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.medium),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: AppTokens.small),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: AppTypography.body1Size,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$achieved / $target $unit',
                style: TextStyle(
                  fontSize: AppTypography.body2Size,
                  fontWeight: FontWeight.w700,
                  color: progress >= 1.0 ? AppColors.success : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.small),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? AppColors.success : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  final IconData icon;

  const _EmptyState({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ComponentSpec.cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(ComponentSpec.cardRadius),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: AppTokens.small),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: AppTypography.captionSize,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;

  const _ActivityListTile({
      required this.title,
      required this.subtitle,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.small),
      padding: const EdgeInsets.all(ComponentSpec.cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(ComponentSpec.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: AppTypography.body1Size),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: AppTypography.captionSize),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
                fontSize: AppTypography.body2Size),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Catat Jam Tidur Quick Card
// ─────────────────────────────────────────────────────────────────────────────
class _SleepLogQuickCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SleepLogQuickCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todaySleep = context.watch<ActivityProvider>().todaySleepRecord;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: todaySleep != null
                    ? const Color(0xFFFEF3C7)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: todaySleep != null
                      ? const Color(0xFFFDE68A)
                      : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Center(
                child: Text(
                  todaySleep != null ? '😴' : '🌙',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Catat Jam Tidur',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (todaySleep == null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'Belum Diisi',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    todaySleep != null
                        ? '${todaySleep.durationHours.toStringAsFixed(1)} jam tidur • Ketuk untuk perbarui'
                        : 'Belum diisi • Ketuk untuk mencatat jam tidur semalam',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: todaySleep != null
                  ? const Color(0xFF0EA5E9)
                  : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kesehatan Komposit Card (Matching User Screenshot Image 1)
// ─────────────────────────────────────────────────────────────────────────────
class _CompositeHealthCard extends StatelessWidget {
  final double compositeScore;
  final TrajectoryTrend trend;
  final List<HealthTrajectoryPoint> points;
  final VoidCallback onTap;

  const _CompositeHealthCard({
    required this.compositeScore,
    required this.trend,
    required this.points,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String trendLabel;
    final Color trendColor;
    switch (trend) {
      case TrajectoryTrend.improving:
        trendLabel = '▲ Membaik';
        trendColor = const Color(0xFF059669);
        break;
      case TrajectoryTrend.declining:
        trendLabel = '▼ Menurun';
        trendColor = const Color(0xFFE11D48);
        break;
      default:
        trendLabel = '→ Stabil';
        trendColor = const Color(0xFFD97706);
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: const Center(
                    child: Text('📊', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kesehatan Komposit',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Skor Holistik & Tren Regresi Linier',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF0EA5E9),
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Score & Sparkline Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Score & Trend Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${compositeScore.round()}',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Poppins',
                              color: Color(0xFF0284C7),
                              letterSpacing: -1,
                            ),
                          ),
                          TextSpan(
                            text: ' /100',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: trendColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: trendColor.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        trendLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: trendColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),

                // Sparkline Chart
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: CustomPaint(
                      painter: _MiniSparklinePainter(
                        points: points,
                        lineColor: const Color(0xFF0284C7),
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniSparklinePainter extends CustomPainter {
  final List<HealthTrajectoryPoint> points;
  final Color lineColor;
  final bool isDark;

  const _MiniSparklinePainter({
    required this.points,
    required this.lineColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final values = points.map((p) => p.compositeScore).toList();
    double minV = values.reduce((a, b) => a < b ? a : b);
    double maxV = values.reduce((a, b) => a > b ? a : b);
    if ((maxV - minV) < 5) {
      maxV += 5;
      minV = (minV - 5).clamp(0, 100);
    }
    final range = maxV - minV;

    final path = Path();
    final fillPath = Path();
    final dx = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = i * dx;
      final normY = 1.0 - ((values[i] - minV) / range);
      final y = (normY * (size.height - 10)) + 5;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == values.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();

        // Active point indicator
        final dotPaint = Paint()..color = lineColor;
        final glowPaint = Paint()..color = lineColor.withValues(alpha: 0.35);
        canvas.drawCircle(Offset(x, y), 5.5, glowPaint);
        canvas.drawCircle(Offset(x, y), 3, dotPaint);
      }
    }

    // Fill gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final strokePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) => true;
}

