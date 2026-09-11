import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../inti/tema/design_tokens.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_SlideData> _slides = [
    _SlideData(
      emoji: '🍱',
      title: 'Scan Makanan dengan AI',
      description:
          'Identifikasi makanan otomatis menggunakan kamera pintar. Hitung kalori, protein, karbohidrat secara real-time!',
      gradientColors: [
        AppColors.primaryLight.withValues(alpha: 0.4),
        AppColors.background
      ],
      accentColor: AppColors.primary,
    ),
    _SlideData(
      emoji: '✨',
      title: 'Analisis Kecantikan AI',
      description:
          'Deteksi kondisi kulit, level kelelahan wajah, dan dapatkan rekomendasi hidrasi personal khusus untuk Anda.',
      gradientColors: [
        AppColors.accentLight.withValues(alpha: 0.4),
        AppColors.background
      ],
      accentColor: AppColors.accent,
    ),
    _SlideData(
      emoji: '🏃',
      title: 'Pelacak Aktivitas Lengkap',
      description:
          'Pantau lari, jalan kaki, konsumsi air, dan statistik harian Anda dalam satu platform terintegrasi.',
      gradientColors: [
        AppColors.successLight.withValues(alpha: 0.4),
        AppColors.background
      ],
      accentColor: AppColors.success,
    ),
  ];

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
    }
  }

  void _goNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _slides.length,
            itemBuilder: (context, index) => _SlidePage(slide: _slides[index]),
          ),
          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: GestureDetector(
              onTap: _finishOnboarding,
              child: Text(
                'Lewati',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // Bottom area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: isActive ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? _slides[_currentPage].accentColor
                              : Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // Next button
                  GestureDetector(
                    onTap: _goNext,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.gradientPrimary,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _currentPage == _slides.length - 1
                              ? 'Mulai Sekarang 🚀'
                              : 'Lanjut →',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}

class _SlideData {
  final String emoji;
  final String title;
  final String description;
  final List<Color> gradientColors;
  final Color accentColor;

  const _SlideData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.gradientColors,
    required this.accentColor,
  });
}

class _SlidePage extends StatelessWidget {
  final _SlideData slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: slide.gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: slide.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                      color: slide.accentColor.withValues(alpha: 0.4),
                      width: 1.5),
                ),
                child: Center(
                  child:
                      Text(slide.emoji, style: const TextStyle(fontSize: 75)),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                slide.title,
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.3,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                slide.description,
                style: TextStyle(
                  fontSize: 17,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.6,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 160),
            ],
          ),
        ),
      ),
    );
  }
}
