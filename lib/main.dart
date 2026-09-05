import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'inti/tema/tema_aplikasi.dart';
import 'inti/tema/design_tokens.dart';
import 'layar/layar_pembuka.dart';
import 'layar/layar_pengantar.dart';
import 'layar/layar_autentikasi.dart';
import 'layar/layar_beranda.dart';
import 'layar/layar_chatbot_konsultasi.dart';
import 'layar/layar_sehati_ai.dart';
import 'layar/layar_pindai_makanan.dart';
import 'layar/layar_pindai_kecantikan.dart';
import 'layar/layar_latihan_ai.dart';
import 'layar/layar_preferensi_latihan.dart';
import 'layar/layar_pindai_diabetes.dart';
import 'layar/layar_aktivitas.dart';
import 'layar/layar_riwayat_aktivitas.dart';
import 'layar/layar_program.dart';
import 'layar/layar_profil.dart';
import 'layar/layar_pengaturan_profil.dart';
import 'layar/layar_direktori_latihan.dart';
import 'layar/layar_kesehatan_bulanan.dart';
import 'layar/layar_kalkulator_langkah.dart';
import 'layar/layar_referensi.dart';
import 'layar/layar_aging_score.dart';
import 'layar/layar_gula_darah.dart';
import 'layar/layar_input_manual_makanan.dart';
import 'layar/layar_gait_analysis.dart';
import 'layar/layar_tes_mbti.dart';
import 'layar/layar_tren_kesehatan.dart';
import 'layar/widget_kalender_kehamilan.dart';
import 'layar/layar_nubi_demo.dart';
import 'layar/layar_tentang.dart';
import 'package:provider/provider.dart';
import 'penyedia/penyedia_aktivitas.dart';
import 'penyedia/penyedia_gula_darah.dart';
import 'penyedia/penyedia_tema.dart';
import 'inti/layanan/layanan_gemini.dart';
import 'inti/layanan/layanan_notifikasi.dart';
import 'inti/layanan/konfigurasi_layanan_latar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-load theme BEFORE runApp to avoid flash of wrong theme
  final prefs = await SharedPreferences.getInstance();
  final savedDark = prefs.getBool('isDarkMode') ?? false;

  try {
    await Supabase.initialize(
      url: 'https://hckuwrzfkvhiddhejfth.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhja3V3cnpma3ZoaWRkaGVqZnRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NzUwNTAsImV4cCI6MjA5MDA1MTA1MH0.LdDwFktdWB8nDLbfZTZhmF_YU52alScU5T0e7yJRTGc',
    );
    // Don't await non-critical services if they might hang
    NotificationService().init();
    GeminiService.instance.initialize();

    // Inisialisasi background service secara aman (autoStart: false, tidak crash saat peluncuran)
    await BackgroundServiceConfig.initialize();
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: savedDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => BloodGlucoseProvider()),
        ChangeNotifierProvider(
            create: (_) => ThemeProvider(initialDark: savedDark)),
      ],
      child: const SehatiAIApp(),
    ),
  );
}

class SehatiAIApp extends StatelessWidget {
  const SehatiAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'SEHATI-AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/splash',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/splash':
                return _fadeRoute(const SplashScreen(), settings);
              case '/onboarding':
                return _fadeRoute(const OnboardingScreen(), settings);
              case '/auth':
                return _fadeRoute(const AuthScreen(), settings);
              case '/setup-profile':
                return _fadeRoute(const SetupProfileScreen(), settings);
              case '/home':
                return _fadeRoute(const MainScaffold(), settings);
              case '/food-scan':
                return MaterialPageRoute(
                    builder: (_) => const FoodScanScreen(), settings: settings);
              case '/ai-chat':
                return MaterialPageRoute(
                    builder: (_) => const ConsultationChatScreen(),
                    settings: settings);
              case '/beauty-scan':
                return MaterialPageRoute(
                    builder: (_) => const BeautyScanScreen(), settings: settings);
              case '/workout-ai':
                return MaterialPageRoute(
                    builder: (_) => const WorkoutAIScreen(), settings: settings);
              case '/workout-preferences':
                return MaterialPageRoute(
                    builder: (_) => const WorkoutPreferencesScreen(), settings: settings);
              case '/diabetes-scan':
                return MaterialPageRoute(
                    builder: (_) => const DiabetesScanScreen(), settings: settings);
              case '/activity-history':
                return MaterialPageRoute(
                    builder: (_) => const ActivityHistoryScreen(), settings: settings);
              case '/exercise-directory':
                return MaterialPageRoute(
                    builder: (_) => const ExerciseDirectoryScreen(), settings: settings);
              case '/monthly-health':
                return MaterialPageRoute(
                    builder: (_) => const MonthlyHealthScreen(), settings: settings);
              case '/step-calculator':
                return MaterialPageRoute(
                    builder: (_) => const StepCalorieCalculatorScreen(), settings: settings);
              case '/references':
                return MaterialPageRoute(
                    builder: (_) => const ReferencesScreen(), settings: settings);
              case '/aging-score':
                return MaterialPageRoute(
                    builder: (_) => const LifestyleAgingScoreScreen(), settings: settings);
              case '/blood-glucose':
                return MaterialPageRoute(
                    builder: (_) => const BloodGlucoseScreen(), settings: settings);
              case '/input-manual-makanan':
                return MaterialPageRoute(
                    builder: (_) => const ManualFoodSearchScreen(), settings: settings);
              case '/gait-analysis':
                return MaterialPageRoute(
                    builder: (_) => const GaitAnalysisScreen(), settings: settings);
              case '/tes-mbti':
                return MaterialPageRoute(
                    builder: (_) => const MBTITestScreen(), settings: settings);
              case '/health-trends':
                return MaterialPageRoute(
                    builder: (_) => const HealthTrajectoryScreen(), settings: settings);
              case '/pregnancy-calendar':
                return MaterialPageRoute(
                    builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Kalender Kehamilan',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                          body: const PregnancyCalendarTab(),
                        ),
                    settings: settings);
              case '/nubi-demo':
                return MaterialPageRoute(
                    builder: (_) => const NubiDemoScreen(), settings: settings);
              case '/about':
                return MaterialPageRoute(
                    builder: (_) => const LayarTentang(), settings: settings);
              default:
                return _fadeRoute(const SplashScreen(), settings);
            }
          },
        );
      },
    );
  }

  PageRouteBuilder _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // Tab order: Home, Activity, SEHATI-AI (center), Program, Profile
  final List<Widget> _tabs = const [
    HomeScreen(),
    ActivityScreen(),
    SehatiAIScreen(),
    ProgramScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: _SehhatiBottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  BOTTOM NAVIGATION — Vektor 24x24, tanpa emoji, tinggi 64dp
//  Spesifikasi: height 56–64dp di luar home indicator,
//  icon 24x24 dp, label 12sp, aktif/semi-aktif分明
// ═══════════════════════════════════════════════════════════════════════════════

class _SehhatiBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SehhatiBottomNav({required this.currentIndex, required this.onTap});

  // Ikon vektor 24x24 — Material Icons (bukan emoji)
  static const _items = [
    _NavItem(
      icon: Icons.home_outlined,
      iconActive: Icons.home,
      label: 'Beranda',
    ),
    _NavItem(
      icon: Icons.directions_run_outlined,
      iconActive: Icons.directions_run,
      label: 'Aktivitas',
    ),
    _NavItem(
      icon: Icons.auto_awesome,
      iconActive: Icons.auto_awesome,
      label: 'SEHATI-AI',
      isCenter: true,
    ),
    _NavItem(
      icon: Icons.flag_outlined,
      iconActive: Icons.flag,
      label: 'Program',
    ),
    _NavItem(
      icon: Icons.person_outline,
      iconActive: Icons.person,
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Bottom nav container with responsive SafeArea
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final isActive = currentIndex == i;

              if (item.isCenter) {
                return _CenterNavButton(
                  isActive: isActive,
                  onTap: () => onTap(i),
                );
              }

              return _SideNavButton(
                icon: item.icon,
                iconActive: item.iconActive,
                label: item.label,
                isActive: isActive,
                onTap: () => onTap(i),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData iconActive;
  final String label;
  final bool isCenter;
  const _NavItem({
    required this.icon,
    required this.iconActive,
    required this.label,
    this.isCenter = false,
  });
}

// ── Center button (SEHATI-AI) ────────────────────────────────────────────────

class _CenterNavButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _CenterNavButton({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final grad = isActive
        ? (ext?.gradientPrimary ?? AppColors.gradientPrimary)
        : [
            theme.colorScheme.surfaceContainerHighest,
            theme.colorScheme.surface,
          ];

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Elevated circle button 52x52
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: grad,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.dividerColor.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              isActive ? Icons.auto_awesome : Icons.auto_awesome,
              size: 26,
              color: isActive ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          // Label dengan indicator panah
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SEHATI-AI',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'Poppins',
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodySmall?.color,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 4),
              if (isActive)
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Side navigation buttons ─────────────────────────────────────────────────

class _SideNavButton extends StatelessWidget {
  final IconData icon;
  final IconData iconActive;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SideNavButton({
    required this.icon,
    required this.iconActive,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container dengan highlight
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isActive ? iconActive : icon,
              size: 24,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.iconTheme.color?.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 2),
          // Label 11sp
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Poppins',
              fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodySmall?.color,
            ),
            child: Text(label),
          ),
          const SizedBox(height: 2),
          if (isActive)
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
