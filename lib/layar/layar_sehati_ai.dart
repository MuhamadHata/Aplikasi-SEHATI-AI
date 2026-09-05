import 'package:flutter/material.dart';
import '../../inti/tema/design_tokens.dart';
import 'layar_chatbot_konsultasi.dart';

class SehatiAIScreen extends StatelessWidget {
  const SehatiAIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.05),
                    theme.scaffoldBackgroundColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 55, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.gradientPrimary,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(Icons.auto_awesome_rounded, size: 26, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SEHATI-AI Hub',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: theme.textTheme.titleLarge?.color,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              'Teknologi AI untuk kesehatan Anda',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Image.asset(
                          'assets/images/logo_brin.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // AI Banner — NUBI (3D Pop-Out Effect)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.gradientPrimary,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.30),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 18, 120, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome_rounded,
                                      size: 13, color: Colors.amber),
                                  SizedBox(width: 5),
                                  Text(
                                    'Asisten Sehati AI',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Nubi Siap Membantu!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Konsultasi kesehatan, analisis gaya hidup, & panduan nutrisi cerdas.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.92),
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Mascot popping out of the card
                      Positioned(
                        right: 8,
                        bottom: -4,
                        child: SizedBox(
                          width: 125,
                          height: 155,
                          child: Image.asset(
                            'assets/images/maskot_nubi_doctor.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.smart_toy_rounded,
                              size: 70,
                              color: Colors.white,
                            ),
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
                _AIFeatureCard(
                  imageAsset: 'assets/images/fitur/fitur_chatbot_ai.png',
                  icon: Icons.medical_services_outlined,
                  title: 'SEHATI-AI Care Chatbot',
                  description:
                      'Konsultasi awal tentang gejala, penyakit, dan keresahan kesehatan secara interaktif.',
                  badge: 'CHAT',
                  badgeColor: theme.colorScheme.primary,
                  gradientColors: ext?.gradientCard ?? AppColors.gradientCard,
                  accentColor: theme.colorScheme.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConsultationChatScreen(),
                      ),
                    );
                  },
                  stats: '24/7 Konsul',
                ),
                const SizedBox(height: 14),
                _AIFeatureCard(
                  imageAsset: 'assets/images/fitur/fitur_food_ai.png',
                  icon: Icons.restaurant_rounded,
                  title: 'SEHATI-AI Food',
                  description:
                      'Identifikasi makanan & estimasi kalori otomatis menggunakan kamera.',
                  badge: 'POPULER',
                  badgeColor: ext?.success ?? AppColors.success,
                  gradientColors: ext?.gradientCard ?? AppColors.gradientCard,
                  accentColor: theme.colorScheme.primary,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      useSafeArea: true,
                      isScrollControlled: true,
                      builder: (_) => Container(
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: SafeArea(
                          top: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                              const SizedBox(height: 16),
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: const Color(0xFF0F52BA).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.restaurant_rounded, size: 20, color: Color(0xFF0F52BA)),
                                ),
                                const SizedBox(width: 10),
                                Text('SEHATI-AI Food', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Poppins', color: theme.colorScheme.onSurface)),
                              ]),
                              const SizedBox(height: 6),
                              Text('Pilih cara mencatat makananmu:', style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/food-scan');
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: const Color(0xFF0F52BA), borderRadius: BorderRadius.circular(16)),
                                  child: Row(children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                                      child: const Icon(Icons.camera_alt_rounded, size: 28, color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Scan Makanan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                                      Text('Foto makanan & AI kenali otomatis', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                    ])),
                                    const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                                  ]),
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/input-manual-makanan');
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
                                  ),
                                  child: Row(children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: const Color(0xFF0F52BA).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                      child: const Icon(Icons.edit_rounded, size: 28, color: Color(0xFF0F52BA)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('Input Manual', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                                      Text('Cari dari database 1000+ makanan', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13)),
                                    ])),
                                    Icon(Icons.chevron_right_rounded, color: theme.dividerColor),
                                  ]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  stats: '98% Akurasi',
                ),
                const SizedBox(height: 14),
                _AIFeatureCard(
                  imageAsset: 'assets/images/fitur/fitur_beauty_ai.png',
                  icon: Icons.face_retouching_natural_rounded,
                  title: 'SEHATI-AI Beauty',
                  description:
                      'Analisis kondisi kulit, hidrasi, dan tingkat kelelahan wajah.',
                  badge: 'BARU',
                  badgeColor: theme.colorScheme.secondary,
                  gradientColors: ext?.gradientCard ?? AppColors.gradientCard,
                  accentColor: theme.colorScheme.secondary,
                  route: '/beauty-scan',
                  stats: 'Multi-analisis',
                ),
                const SizedBox(height: 14),
                _AIFeatureCard(
                  imageAsset: 'assets/images/fitur/fitur_workout_ai.png',
                  icon: Icons.fitness_center_rounded,
                  title: 'SEHATI-AI Workout',
                  description:
                      'Program latihan personal berdasarkan profil dan tujuan kesehatanmu.',
                  badge: 'AI',
                  badgeColor: ext?.warning ?? AppColors.warning,
                  gradientColors: ext?.gradientCard ?? AppColors.gradientCard,
                  accentColor: ext?.success ?? AppColors.success,
                  onTap: () {
                    Navigator.pushNamed(context, '/workout-ai');
                  },
                  stats: 'Personalized',
                ),
                const SizedBox(height: 14),
                _AIFeatureCard(
                  imageAsset: 'assets/images/fitur/fitur_diabetes_ai.png',
                  icon: Icons.shield_outlined,
                  title: 'SEHATI-AI Diabetes',
                  description:
                      'Analisis risiko diabetes berdasarkan data medis & faktor keturunan.',
                  badge: 'SKRINING',
                  badgeColor: AppColors.error,
                  gradientColors: ext?.gradientCard ?? AppColors.gradientCard,
                  accentColor: AppColors.error,
                  route: '/diabetes-scan',
                  stats: 'Akurasi Tinggi',
                ),
                const SizedBox(height: 14),
                _AIFeatureCard(
                  imageAsset: 'assets/images/fitur/fitur_glucose_ai.png',
                  icon: Icons.bloodtype_outlined,
                  title: 'SEHATI-AI Gula Darah',
                  description:
                      'Pemantauan kadar glukosa, glycemic variability, dan analisis cerdas pola makan.',
                  badge: 'MEDIS',
                  badgeColor: const Color(0xFFE11D48),
                  gradientColors: ext?.gradientCard ?? AppColors.gradientCard,
                  accentColor: const Color(0xFFE11D48),
                  route: '/blood-glucose',
                  stats: 'Glycemic Advisor',
                ),
                const SizedBox(height: 14),
                _AIFeatureCard(
                  imageAsset: 'assets/images/fitur/fitur_mbti_ai.png',
                  icon: Icons.psychology_outlined,
                  title: 'SEHATI-AI Tes MBTI & Mental',
                  description:
                      'Asesmen kepribadian 16 tipe MBTI dan pengaruhnya terhadap kesehatan mental & stres.',
                  badge: 'PSIKOLOGI',
                  badgeColor: const Color(0xFF7C3AED),
                  gradientColors: ext?.gradientCard ?? AppColors.gradientCard,
                  accentColor: const Color(0xFF7C3AED),
                  route: '/tes-mbti',
                  stats: '16 Tipe',
                ),
                const SizedBox(height: 24),
                // Security note
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.1)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 28, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data Aman & Privat',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: theme.textTheme.titleMedium?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Semua analisis diproses langsung di perangkat. Data tidak dikirim ke server.',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textTheme.bodySmall?.color,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AIFeatureCard extends StatelessWidget {
  final String? imageAsset;
  final IconData? icon;
  final String title;
  final String description;
  final String badge;
  final Color badgeColor;
  final List<Color> gradientColors;
  final Color accentColor;
  final String? route;
  final VoidCallback? onTap;
  final String stats;

  const _AIFeatureCard({
    this.imageAsset,
    this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeColor,
    required this.gradientColors,
    required this.accentColor,
    this.route,
    this.onTap,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () {
            if (route != null) Navigator.pushNamed(context, route!);
          },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageAsset != null
                    ? Image.asset(
                        imageAsset!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(icon ?? Icons.auto_awesome_rounded,
                              size: 36, color: accentColor),
                        ),
                      )
                    : Center(
                        child: icon != null
                            ? Icon(icon, size: 36, color: accentColor)
                            : const Text('✨',
                                style: TextStyle(fontSize: 34)),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stats,
                        style: TextStyle(
                          fontSize: 13,
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Mulai →',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
