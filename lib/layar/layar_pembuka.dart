import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../inti/tema/design_tokens.dart';
import '../inti/layanan/layanan_notifikasi.dart';

/// Splash screen dengan animasi yang sesuai spesifikasi:
/// - Logo: 96x96 dp (AppTypography.logoSplashWidth/Height)
/// - Judul SEHATI-AI: 36sp Bold 900, letter-spacing 1.5
/// - Tagline: Body 2 (13sp Regular)
/// - Animasi micro 150ms untuk transisi, page route 350ms
/// - Safe area insets: otomatis dari Scaffold
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _taglineAnim;
  bool _showBrin = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Animasi sesuai spesifikasi:
    // - Logo muncul: 150ms (microAnim scale + opacity kombinasi)
    // - Text muncul: selang 150ms setelah logo
    // - Total duration 2800ms untuk transisi ke halaman berikutnya
    _controller = AnimationController(
      vsync: this,
      duration: AppTokens.microAnim * 10, // 1500ms total untuk keseluruhan animasi
    );

    // Scale: logo membesar dari 0 ke 1 dengan elasticOut
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Opacity logo
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Tagline muncul setelah logo stabil
    _taglineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // BRIN -> SEHATI-AI sequence (diperlambat agar nyaman dibaca dan diamati)
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showBrin = false);
    });

    // Navigasi ke halaman berikutnya setelah 5500ms (BRIN 2.5s + SEHATI-AI 3.0s)
    Future.delayed(const Duration(milliseconds: 5500), () async {
      if (!mounted) return;

      try {
        final prefs = await SharedPreferences.getInstance();
        final bool onboardingDone = prefs.getBool('onboarding_completed') ?? false;
        final user = Supabase.instance.client.auth.currentUser;

        try {
          await NotificationService().requestPermission();
        } catch (e) {
          debugPrint('Notification permission error: $e');
        }

        if (mounted) {
          if (user != null) {
            try {
              final data = await Supabase.instance.client
                  .from('users')
                  .select('profile_completed')
                  .eq('id', user.id)
                  .maybeSingle()
                  .timeout(const Duration(seconds: 5));
              final isCompleted =
                  data != null && data['profile_completed'] == true;
              if (mounted) {
                if (isCompleted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (route) => false);
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/setup-profile', (route) => false);
                }
              }
            } catch (e) {
              debugPrint('Profile check error or timeout: $e');
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (route) => false);
              }
            }
          } else if (onboardingDone) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/auth', (route) => false);
          } else {
            Navigator.pushNamedAndRemoveUntil(
                context, '/onboarding', (route) => false);
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/auth', (route) => false);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Background gradient lembut
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                      theme.scaffoldBackgroundColor,
                      theme.scaffoldBackgroundColor,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Decorative circle (aman di kanan atas, di luar gesture boundary)
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  ),
                ),
              ),

              // Logo — BRIN kemudian SEHATI-AI
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo container (96x96dp)
                    Opacity(
                      opacity: _opacityAnim.value,
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: Column(
                          children: [
                            AnimatedSwitcher(
                              duration: AppTokens.microAnim * 4, // 600ms
                              child: _showBrin
                                  ? Image.asset(
                                      'assets/images/logo BRIN.png',
                                      key: const ValueKey('brin'),
                                      width: 140,
                                      height: 80,
                                      fit: BoxFit.contain,
                                    )
                                  : Container(
                                      key: const ValueKey('sehati'),
                                      width: AppTypography.logoSplashWidth,
                                      height: AppTypography.logoSplashHeight,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F52BA),
                                        borderRadius: BorderRadius.circular(
                                          ComponentSpec.cardRadius,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0F52BA)
                                                .withValues(alpha: 0.35),
                                            blurRadius: 24,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(
                                                ComponentSpec.cardRadius),
                                        child: Image.asset(
                                          'assets/images/app_icon.png',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) =>
                                                  const Icon(
                                            Icons.favorite_rounded,
                                            size: 48,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: AppTokens.medium),
                            // SEHATI-AI text (hanya muncul setelah transition)
                            AnimatedSwitcher(
                              duration: AppTokens.smallAnim, // 200ms
                              child: _showBrin
                                  ? const SizedBox.shrink(key: ValueKey('empty'))
                                  : RichText(
                                      key: const ValueKey('sehati_text'),
                                      text: const TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'SEHATI',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize:
                                                  AppTypography.logoTextSize,
                                              fontWeight:
                                                  AppTypography.logoTextWeight,
                                              color: AppColors.textPrimary,
                                              letterSpacing:
                                                  AppTypography.logoTextLetterSpacing,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '-AI',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize:
                                                  AppTypography.logoTextSize,
                                              fontWeight:
                                                  AppTypography.logoTextWeight,
                                              color: Color(0xFF0F52BA),
                                              letterSpacing:
                                                  AppTypography.logoTextLetterSpacing,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.medium),
                    // Tagline & Teks Pendukung (Dinamis antara BRIN dan SEHATI-AI)
                    Opacity(
                      opacity: _taglineAnim.value,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: _showBrin
                            ? Column(
                                key: const ValueKey('brin_text'),
                                children: [
                                  const Text(
                                    'KOLABORASI RISET & INOVASI',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      color: Color(0xFF0F52BA),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'BADAN RISET',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Text(
                                    'DAN INOVASI NASIONAL',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                key: const ValueKey('sehati_tagline'),
                                children: [
                                  Text(
                                    'Sistem Evaluasi Holistik Aktivitas Fisik',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: AppTypography.body2Weight,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'dan Nutrisi Terintegrasi dengan AI',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: AppTypography.body2Weight,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F52BA).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF0F52BA).withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'Platform Kesehatan Masa Depan',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F52BA),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // Version badge di bawah (dalam safe area)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'v1.0.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
