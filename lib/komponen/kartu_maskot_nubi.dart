import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../penyedia/penyedia_aktivitas.dart';
import '../widget/nubi_mascot.dart';

/// Kartu asisten Nubi — mendeteksi kemajuan langkah, air, kalori, tidur, dan tren
/// serta berganti otomatis (auto-rotating carousel) dengan animasi halus.
class NubiMascotCard extends StatefulWidget {
  const NubiMascotCard({super.key});

  @override
  State<NubiMascotCard> createState() => _NubiMascotCardState();
}

class _NubiMascotCardState extends State<NubiMascotCard>
    with SingleTickerProviderStateMixin {
  Timer? _cycleTimer;
  int _currentIndex = 0;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    // Animasi mengambang lembut untuk maskot Nubi
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Otomatis berganti setiap 5 detik
    _startCycleTimer();
  }

  void _startCycleTimer() {
    _cycleTimer?.cancel();
    _cycleTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          _currentIndex++;
        });
      }
    });
  }

  void _nextCard(int total) {
    _startCycleTimer();
    setState(() {
      _currentIndex = (_currentIndex + 1) % total;
    });
  }

  void _prevCard(int total) {
    _startCycleTimer();
    setState(() {
      _currentIndex = (_currentIndex - 1 + total) % total;
    });
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  /// Membuat daftar lengkap pengingat kesehatan yang dinamis dan berotasi
  List<_MascotReminder> _buildReminders(ActivityProvider provider) {
    final steps = provider.steps;
    final stepTarget = provider.stepTarget > 0 ? provider.stepTarget : 10000;
    final water = provider.waterGlasses;
    final waterTarget = provider.waterTarget > 0 ? provider.waterTarget : 8;
    final calorieConsumed = provider.calorieConsumed;
    final calorieTarget = provider.calorieTarget > 0 ? provider.calorieTarget : 2000;
    final compositeScore = provider.currentCompositeScore;
    final sleep = provider.todaySleepRecord;
    final sleepDuration = sleep?.durationHours ?? 0.0;

    final stepProgress = (steps / stepTarget).clamp(0.0, 1.0);
    final waterProgress = (water / waterTarget).clamp(0.0, 1.0);
    final calorieProgress = (calorieConsumed / calorieTarget).clamp(0.0, 1.0);
    final sleepProgress = (sleepDuration / 8.0).clamp(0.0, 1.0);
    final compositeProgress = (compositeScore / 100.0).clamp(0.0, 1.0);

    return [
      // 1. Air Minum (Hidrasi)
      _MascotReminder(
        category: 'Air Minum',
        text: water < waterTarget
            ? 'Nubi ingatkan: jangan lupa minum air! Baru $water dari $waterTarget gelas. Tubuh butuh hidrasi agar segar! 💧'
            : 'Hebat! Target hidrasimu ($water/$waterTarget gelas) tercapai hari ini. Tubuhmu sangat terhidrasi! 🌊',
        pose: 'assets/images/maskot_nubi_drink.png',
        color: const Color(0xFF0284C7), // Sky Blue
        icon: Icons.water_drop_rounded,
        progress: waterProgress,
        progressLabel: '$water / $waterTarget gelas',
        percentage: '${(waterProgress * 100).round()}%',
        nubiPose: NubiPose.drink,
      ),

      // 2. Langkah Kaki (Aktivitas)
      _MascotReminder(
        category: 'Langkah Kaki',
        text: steps < stepTarget
            ? 'Yuk melangkah lagi! Baru $steps dari $stepTarget langkah nih. Sedikit lagi capai target harian! 🏃'
            : 'Luar biasa! Target langkah harian tercapai ($steps langkah). Pertahankan kebiasaan aktif ini! 🎉',
        pose: 'assets/images/maskot_nubi_run.png',
        color: const Color(0xFFF43F5E), // Rose 500
        icon: Icons.directions_walk_rounded,
        progress: stepProgress,
        progressLabel: '$steps / $stepTarget langkah',
        percentage: '${(stepProgress * 100).round()}%',
        nubiPose: NubiPose.run,
      ),

      // 3. Nutrisi & Kalori
      _MascotReminder(
        category: 'Nutrisi & Makanan',
        text: calorieConsumed == 0
            ? 'Belum ada makanan tercatat hari ini. Jangan lupa catat sarapan atau makan siangmu ya! 🍱'
            : (calorieConsumed <= calorieTarget
                ? 'Asupan kalorimu ($calorieConsumed kkal) terkontrol dengan baik hari ini. Mantap! 🥗'
                : 'Asupan kalori ($calorieConsumed kkal) melebihi target ($calorieTarget kkal). Imbangi dengan olahraga ya! 🚴'),
        pose: 'assets/images/maskot_nubi_eat.png',
        color: const Color(0xFFF59E0B), // Amber 500
        icon: Icons.restaurant_rounded,
        progress: calorieProgress,
        progressLabel: '$calorieConsumed / $calorieTarget kkal',
        percentage: '${(calorieProgress * 100).round()}%',
        nubiPose: NubiPose.eat,
      ),

      // 4. Jam Tidur & Istirahat
      _MascotReminder(
        category: 'Jam Tidur',
        text: sleep == null
            ? 'Belum ada catatan tidur semalam. Yuk catat jam tidurmu untuk evaluasi pemulihan sel tubuh! 🌙'
            : (sleep.durationHours >= 7.0
                ? 'Kualitas tidur semalam (${sleep.durationHours.toStringAsFixed(1)} jam) sangat baik! Sel tubuhmu beregenerasi optimal. ✨'
                : 'Tidur semalam (${sleep.durationHours.toStringAsFixed(1)} jam) kurang dari 7 jam. Yuk tidur lebih awal malam ini! 😴'),
        pose: 'assets/images/maskot_nubi_sleep.png',
        color: const Color(0xFF8B5CF6), // Purple 500
        icon: Icons.bedtime_rounded,
        progress: sleepProgress,
        progressLabel: sleep == null
            ? 'Belum diisi (Target 8.0 jam)'
            : '${sleepDuration.toStringAsFixed(1)} / 8.0 jam tidur',
        percentage: '${(sleepProgress * 100).round()}%',
        nubiPose: NubiPose.sleep,
      ),

      // 5. Tren Kesehatan Komposit & AI
      _MascotReminder(
        category: 'Tren Kesehatan',
        text: 'Skor kesehatan kompositmu berada di ${compositeScore.round()}/100. Ketuk kartu di atas untuk melihat proyeksi tren 31 hari! 📊',
        pose: 'assets/images/maskot_nubi_doctor.png',
        color: const Color(0xFF0F52BA), // Sapphire
        icon: Icons.insights_rounded,
        progress: compositeProgress,
        progressLabel: 'Skor Komposit ${compositeScore.round()}/100',
        percentage: '${(compositeProgress * 100).round()}%',
        nubiPose: NubiPose.doctor,
      ),

      // 6. Relaksasi & Kelola Stres CERDIK
      const _MascotReminder(
        category: 'Kelola Stres',
        text: 'Tarik napas dalam 4 detik, tahan 7 detik, dan hembuskan perlahan 8 detik. Pikiran tenang membuat tubuh lebih bugar! 🧘',
        pose: 'assets/images/maskot_nubi_meditate.png',
        color: Color(0xFF10B981), // Emerald 500
        icon: Icons.spa_rounded,
        progress: 1.0,
        progressLabel: 'Metode 4-7-8 Relaks',
        percentage: '100%',
        nubiPose: NubiPose.meditate,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final reminders = _buildReminders(provider);
        final activeIndex = _currentIndex % reminders.length;
        final reminder = reminders[activeIndex];

        return GestureDetector(
          onTap: () => _nextCard(reminders.length),
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < -100) {
                _nextCard(reminders.length);
              } else if (details.primaryVelocity! > 100) {
                _prevCard(reminders.length);
              }
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey<int>(activeIndex),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          reminder.color.withValues(alpha: 0.16),
                          reminder.color.withValues(alpha: 0.05),
                        ]
                      : [
                          reminder.color.withValues(alpha: 0.10),
                          reminder.color.withValues(alpha: 0.02),
                        ],
                ),
                border: Border.all(
                  color: reminder.color.withValues(alpha: 0.25),
                  width: 1.2,
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: reminder.color.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main text and progress column
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 125, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header Chips & Dots Indicator
                        Row(
                          children: [
                            // Nubi Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: reminder.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        reminder.color.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(reminder.icon,
                                      size: 13, color: reminder.color),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Nubi',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: reminder.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Asisten SEHATI-AI Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Asisten SEHATI-AI',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Message Text
                        Text(
                          reminder.text,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Linear progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: reminder.progress,
                            minHeight: 6,
                            backgroundColor:
                                reminder.color.withValues(alpha: 0.18),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                reminder.color),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Progress label & percentage
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              reminder.progressLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: reminder.color,
                              ),
                            ),
                            Text(
                              reminder.percentage,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: reminder.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Carousel Dots Indicator (Top Right)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(reminders.length, (dotIdx) {
                        final isActive = dotIdx == activeIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: isActive ? 14 : 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isActive
                                ? reminder.color
                                : (isDark ? Colors.white24 : Colors.black12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Mascot Image with gentle floating animation
                  Positioned(
                    right: -2,
                    bottom: -10,
                    child: AnimatedBuilder(
                      animation: _floatAnimation,
                      builder: (_, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: 125,
                        height: 135,
                        child: Image.asset(
                          reminder.pose,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => NubiMascot(
                            pose: reminder.nubiPose,
                            size: 95,
                            autoPlay: true,
                            showEffects: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Versi mini Nubi untuk dipakai di chatbot header
class NubiChatAvatar extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final bool animated;

  const NubiChatAvatar({
    super.key,
    this.size = 48,
    this.backgroundColor,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (backgroundColor ?? primary).withValues(alpha: 0.2),
            (backgroundColor ?? primary).withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: (backgroundColor ?? primary).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: animated
            ? OverflowBox(
                minWidth: size * 1.5,
                maxWidth: size * 1.5,
                minHeight: size * 1.5,
                maxHeight: size * 1.5,
                child: NubiMascot(
                  pose: NubiPose.doctor,
                  size: size,
                  autoPlay: true,
                  showEffects: false,
                ),
              )
            : Image.asset(
                'assets/images/maskot_nubi_doctor.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(Icons.smart_toy_rounded,
                      size: size * 0.5, color: primary),
                ),
              ),
      ),
    );
  }
}

/// Widget Nubi "floating button" yang dapat ditampilkan di layar chatbot (Static Version)
class NubiFloatingHint extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;
  const NubiFloatingHint({super.key, required this.message, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NubiChatAvatar(size: 32, animated: false),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MascotReminder {
  final String category;
  final String text;
  final String pose;
  final Color color;
  final IconData icon;
  final double progress;
  final String progressLabel;
  final String percentage;
  final NubiPose nubiPose;

  const _MascotReminder({
    required this.category,
    required this.text,
    required this.pose,
    required this.color,
    required this.icon,
    required this.progress,
    required this.progressLabel,
    required this.percentage,
    required this.nubiPose,
  });
}
