import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  DESIGN TOKENS — semua nilai tanh apa perhitungan runtime.
//  Dikutip dari Spesifikasi Design System SEHATI-AI (8pt Grid)
// ═══════════════════════════════════════════════════════════════════════════════

class AppTokens {
  // ── Spacing Scale (8pt Grid, deviasi 4pt untuk mikro) ─────────────────────
  static const double micro    = 4.0;   //  4 dp — ikon→teks kecil, padding badge
  static const double small    = 8.0;   //  8 dp — antar elemen bersaudara
  static const double medium   = 16.0;  // 16 dp — margin L-R layar, padding kartu
  static const double large    = 24.0;  // 24 dp — gap antar section
  static const double xlarge   = 32.0;  // 32 dp — vertical gap sebelum tombol penutup
  static const double xxlarge  = 48.0;  // 48 dp — jarak vertikal besar

  // ── Border Radius ───────────────────────────────────────────────────────────
  static const double radiusXs  = 4.0;   // badge / chip kecil
  static const double radiusSm  = 8.0;   // input field, tombol clean, snackbar
  static const double radiusMd  = 12.0;  // kartu
  static const double radiusLg  = 16.0;  // kartu (large), bottom sheet top
  static const double radiusPill = 24.0; // pill button / chip pill

  // ── Touch Target Minimum (unused visual) ────────────────────────────────────
  static const double touchMin = 48.0;   // 48x48 dp — semua elemen interaktif

  // ── Elevation / Surface Depth (Dark Mode) ───────────────────────────────────
  // Gunakan perbedaan brightness, bukan shadow (smear prevention OLED)
  static const int surfaceDepth1 = 1;
  static const int surfaceDepth2 = 2;
  static const int surfaceDepth3 = 3;

  // ── Divider ─────────────────────────────────────────────────────────────────
  static const double dividerThickness = 1.0; // 1dp (0.5pt di iOS retina)
  static const double dividerInset = 16.0;    // inset kiri sejajar teks

  // ── Animation Durations ─────────────────────────────────────────────────────
  static const Duration microAnim   = Duration(milliseconds: 150);  // tombol/switch
  static const Duration smallAnim   = Duration(milliseconds: 200);  // toggle,	input focus
  static const Duration modalAnim   = Duration(milliseconds: 280);  // modal/overlay
  static const Duration pageAnim    = Duration(milliseconds: 350);  // page route
  static const Duration sheetAnim   = Duration(milliseconds: 300);  // bottom sheet

  // ── Easing ──────────────────────────────────────────────────────────────────
  static const Cubic easeOut = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Cubic easeIn  = Cubic(0.4, 0.0, 1.0, 1.0);
  static const Cubic easeOutCubic = Cubic(0.2, 0.0, 0.0, 1.0);

  // ── Safe Area / Gesture Boundary ────────────────────────────────────────────
  static const double gestureBoundary = 18.0; // 16–20 dp dari tepi kiri-kanan
}

// ═══════════════════════════════════════════════════════════════════════════════
//  COLOR TOKENS — Semantic (bukan hardcoded hex di layar)
//  Skema 60-30-10: 60% netral latar, 30% kontainer, 10% aksen
// ═══════════════════════════════════════════════════════════════════════════════

class AppColors {
  // ── Brand ───────────────────────────────────────────────────────────────────
  // Primary: Indigo (calm, trustworthy, modern)
  static const Color primary         = Color(0xFF6366F1); // Indigo 500
  static const Color primaryVariant  = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryTint    = Color(0xFFEEF2FF); // Indigo 50

  // Accent: Rose (energy, vitality)
  static const Color accent          = Color(0xFFF43F5E); // Rose 500
  static const Color accentVariant  = Color(0xFFBE123C); // Rose 600
  static const Color accentTint     = Color(0xFFFFE4E6); // Rose 100

  // ── Semantic Status ─────────────────────────────────────────────────────────
  static const Color success         = Color(0xFF10B981); // Emerald 500
  static const Color successLight     = Color(0xFFD1FAE5); // Emerald 100
  static const Color warning         = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight     = Color(0xFFFEF3C7); // Amber 100
  static const Color info            = Color(0xFF0EA5E9); // Sky 500
  static const Color infoLight       = Color(0xFFE0F2FE); // Sky 100
  static const Color error           = Color(0xFFEF4444); // Red 500 (standar error)
  static const Color errorLight      = Color(0xFFFEE2E2); // Red 100

  // ── Form Field Colors ───────────────────────────────────────────────────────
  static const Color inputBorderDefault = Color(0xFFD1D5DB); // abu border tidak fokus
  static const Color inputBorderFocused = Color(0xFF6366F1); // primary saat fokus
  static const Color inputBorderError   = Color(0xFFEF4444); // merah error
  static const Color inputBorderSuccess = Color(0xFF10B981); // hijau success

  // ── Background / Surface (LIGHT) ────────────────────────────────────────────
  // 60% Dominan: background utama
  static const Color surfaceBg        = Color(0xFFF8FAFC); // Slate 50
  // 30% Kontainer: kartu, kolom input,BottomSheet
  static const Color surfaceContainer = Color(0xFFFFFFFF); // pure white
  static const Color surfaceSecondary = Color(0xFFF1F5F9); // Slate 100
  static const Color surfaceTertiary  = Color(0xFFE2E8F0); // Slate 200 — divider/ border
  static const Color background        = surfaceBg;        // alias untuk kompatibilitas
  static const Color border            = surfaceTertiary;  // alias untuk kompatibilitas
  static const Color surface           = surfaceBg;        // alias: nama lama

  // Kompatibilitas: property lama yang masih dipakai di beberapa file
  static const Color primaryLight      = primaryTint;
  static const Color accentLight       = accentTint;
  static const Color surfaceLight      = surfaceSecondary;

  // ── Text (Light) ────────────────────────────────────────────────────────────
  // WCAG AA ≥ 4.5:1 di atas white
  static const Color textPrimary      = Color(0xFF0F172A); // Slate 900 — off-black
  static const Color textSecondary    = Color(0xFF475569); // Slate 600
  static const Color textMuted        = Color(0xFF64748B); // Slate 500 — caption

  // ── Gradient Palettes ───────────────────────────────────────────────────────
  static const List<Color> gradientPrimary  = [Color(0xFF818CF8), Color(0xFF6366F1)];
  static const List<Color> gradientAccent   = [Color(0xFFFB7185), Color(0xFFF43F5E)];
  static const List<Color> gradientHealth   = [Color(0xFF34D399), Color(0xFF10B981)];
  static const List<Color> gradientHydration = [Color(0xFF38BDF8), Color(0xFF0EA5E9)];
  static const List<Color> gradientEnergy   = [Color(0xFFFBBF24), Color(0xFFF97316)];
  static const List<Color> gradientSunset   = [Color(0xFFFDBA74), Color(0xFFF43F5E)];
  static const List<Color> gradientOcean    = [Color(0xFF7DD3FC), Color(0xFF3B82F6)];
  static const List<Color> gradientCard     = [Color(0xFFFFFFFF), Color(0xFFF8FAFC)];

  // Skeleton shimmer
  static const Color skeletonBase   = Color(0xFFE5E7EB);
  static const Color skeletonHighlight = Color(0xFFF3F4F6);

  // ── Dark Mode ───────────────────────────────────────────────────────────────
  // Dark: gunakan abu gelap #121212 atau #1F2937, JANGAN #000000 (OLED smear)
  static const Color darkBg           = Color(0xFF0F172A); // Slate 900 → latar luar
  static const Color darkSurface      = Color(0xFF1E293B); // Slate 800 → kontainer
  static const Color darkSurfaceAlt   = Color(0xFF1F2937); // alternate surface
  static const Color darkCard         = Color(0xFF1E293B);
  static const Color darkBorder       = Color(0xFF334155); // Slate 700
  static const Color darkTextPrimary  = Color(0xFFF8FAFC); // Slate 50  — off-white
  static const Color darkTextSecondary = Color(0xFFCBD5E1); // Slate 300
  static const Color darkTextMuted    = Color(0xFF94A3B8); // Slate 400 — caption
  // Indigo 300 di dark: kontras ~7.4:1 di Slate 900 (WCAG AAA)
  static const Color darkPrimaryBright = Color(0xFFA5B4FC);
  static const List<Color> darkGradientCard = [Color(0xFF1E293B), Color(0xFF0F172A)];

  // Disabled state — semua mode
  static const Color disabled = Color(0xFFD1D5DB); // abu netral
  static const double disabledOpacity = 0.5;

  // ── Toast / Snackbar ────────────────────────────────────────────────────────
  static const Color toastBackground = Color(0xFF334155); // Slate 700 (dark) /
                                                     // atau white di light
}

// ═══════════════════════════════════════════════════════════════════════════════
//  TYPOGRAPHY SCALE — Dynamic Type (sp/pt, native font, line-height presisi)
//  Skala: Display > H1 > H2 > H3 > Body1 > Body2 > Caption
// ═══════════════════════════════════════════════════════════════════════════════

class AppTypography {
  // ── Display Title — Halaman Onboarding & Hero ──────────────────────────────
  static const double displayTitleSize   = 32.0; // sp/pt
  static const FontWeight displayTitleWeight = FontWeight.w700;
  static const double displayTitleLh    = 1.20;  // 120%

  // ── Heading 1 — Judul utama layar (AppBar Title) ──────────────────────────
  static const double h1Size            = 24.0;
  static const FontWeight h1Weight      = FontWeight.w700;
  static const double h1Lh             = 1.25;

  // ── Heading 2 — Judul seksi (Section Header) ───────────────────────────────
  static const double h2Size            = 20.0;
  static const FontWeight h2Weight      = FontWeight.w600;
  static const double h2Lh             = 1.30;

  // ── Heading 3 — Judul di dalam kartu / Modal ──────────────────────────────
  static const double h3Size            = 16.0;
  static const FontWeight h3Weight      = FontWeight.w600;
  static const double h3Lh             = 1.35;

  // ── Body 1 — Paragraf utama, isi teks, label tombol ───────────────────────
  static const double body1Size         = 14.0;
  static const FontWeight body1Weight   = FontWeight.w400;
  static const double body1Lh          = 1.50;

  // ── Body 2 — Deskripsi sekunder, helper text ───────────────────────────────
  static const double body2Size         = 13.0;
  static const FontWeight body2Weight   = FontWeight.w400;
  static const double body2Lh          = 1.40;

  // ── Caption & Badge — Label status, timestamp, footnote ────────────────────
  static const double captionSize       = 12.0;
  static const FontWeight captionWeight = FontWeight.w500;
  static const double captionLh        = 1.20;

  // ── Button Text ─────────────────────────────────────────────────────────────
  static const double buttonSize        = 14.0;
  static const FontWeight buttonWeight  = FontWeight.w600;
  static const double buttonLetterSpacing = 0.3;

  // ── AppBar Title specific ───────────────────────────────────────────────────
  static const double appBarTitleSize   = 17.0;
  static const FontWeight appBarTitleWeight = FontWeight.w700;

  // ── Bottom Nav Label ────────────────────────────────────────────────────────
  static const double bottomNavLabelSize = 12.0;
  static const FontWeight bottomNavLabelWeight = FontWeight.w500;
  static const FontWeight bottomNavActiveWeight = FontWeight.w700;

  // ── Icon Sizes ──────────────────────────────────────────────────────────────
  static const double iconDefault = 24.0;   // 24x24 dp — standar
  static const double iconMicro   = 16.0;   // 16x16 dp — mikro
  static const double iconSmall   = 20.0;   // 20x20 dp — input ikon

  // ── Logo splash ─────────────────────────────────────────────────────────────
  static const double logoSplashWidth  = 96.0;
  static const double logoSplashHeight = 96.0;
  static const double logoTextSize     = 36.0;
  static const FontWeight logoTextWeight = FontWeight.w900;
  static const double logoTextLetterSpacing = 1.5;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  COMPONENT SPECS
// ═══════════════════════════════════════════════════════════════════════════════

class ComponentSpec {
  // ── Primary Button ─────────────────────────────────────────────────────────
  static const double btnHeight         = 50.0;  // 48–52dp
  static const double btnRadiusClean    = 10.0;  // 8–12dp
  static const double btnRadiusPill     = 24.0;  // pill
  static const double btnPaddingH       = 20.0;  // 16–24dp horizontal

  // ── Secondary / Outlined Button ────────────────────────────────────────────
  static const double btnOutlinedWidth  = 1.5;

  // ── Text Field ──────────────────────────────────────────────────────────────
  static const double inputHeight       = 52.0;  // 48–56dp
  static const double inputRadius       = 10.0;  // 8dp
  static const double inputPaddingH     = 16.0;
  static const double inputPaddingV     = 14.0;
  static const double iconSize          = 22.0;  // 20–24dp
  static const double inputFontSize     = 14.0;

  // ── Selection Controls ──────────────────────────────────────────────────────
  static const double checkboxSize      = 22.0;  // 20–24dp visual
  static const double checkboxLabelGap  = 12.0;

  // ── Switch ──────────────────────────────────────────────────────────────────
  static const double switchTrackW      = 48.0;
  static const double switchTrackH      = 26.0;
  static const double switchThumbSize   = 20.0;

  // ── Chip ────────────────────────────────────────────────────────────────────
  static const double chipHeight        = 32.0;
  static const double chipRadius        = 16.0;  // pill
  static const double chipPaddingH      = 12.0;
  static const double chipFontSize      = 12.0;

  // ── Bottom Navigation ──────────────────────────────────────────────────────
  static const double bottomNavHeight   = 64.0;  // 56–64dp (di luar home indicator)

  // ── Card ────────────────────────────────────────────────────────────────────
  static const double cardRadius        = 14.0;  // 12–16dp
  static const double cardPadding       = 16.0;  // internal
  static const double cardMargin        = 12.0;  // antar kartu

  // ── Bottom Sheet / Modal ────────────────────────────────────────────────────
  static const double sheetTopRadius    = 20.0;  // 16–24dp
  static const double sheetMaxHeightPct = 0.80;  // 80% layar
  static const double overlayOpacity    = 0.50;  // 40–60% black

  // ── Toast / Snackbar ────────────────────────────────────────────────────────
  static const double toastMargin       = 20.0;  // 16–24dp dari bottom nav
  static const double toastHeight       = 48.0;  // min
  static const double toastRadius       = 10.0;  // 8–12dp

  // ── Badge ───────────────────────────────────────────────────────────────────
  static const double badgeDotSize      = 8.0;
  static const double badgeNumberH      = 18.0;  // 16–20dp
  static const double badgeOffset       = 4.0;   // -4dp offset

  // ── Skeleton ────────────────────────────────────────────────────────────────
  static const double skeletonRadius   = 8.0;
  static const int    skeletonShimmerMs = 1500;

  // ── Divider ─────────────────────────────────────────────────────────────────
  static const double dividerThick     = 1.0;
  static const double dividerInset     = 16.0;  // kiri sejajar teks

  // ── Ripple / Press feedback ─────────────────────────────────────────────────
  static const double pressOpacity      = 0.75;  // 70–80% opacity di iOS
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Theme Extension — gradient & warna aksen tambahan
// ═══════════════════════════════════════════════════════════════════════════════

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final List<Color> gradientPrimary;
  final List<Color> gradientAccent;
  final List<Color> gradientCard;
  final Color success;
  final Color info;
  final Color warning;

  const AppThemeExtension({
    required this.gradientPrimary,
    required this.gradientAccent,
    required this.gradientCard,
    required this.success,
    required this.info,
    required this.warning,
  });

  @override
  AppThemeExtension copyWith({
    List<Color>? gradientPrimary,
    List<Color>? gradientAccent,
    List<Color>? gradientCard,
    Color? success,
    Color? info,
    Color? warning,
  }) {
    return AppThemeExtension(
      gradientPrimary: gradientPrimary ?? this.gradientPrimary,
      gradientAccent: gradientAccent ?? this.gradientAccent,
      gradientCard: gradientCard ?? this.gradientCard,
      success: success ?? this.success,
      info: info ?? this.info,
      warning: warning ?? this.warning,
    );
  }

  static List<Color> _lerpGradient(List<Color> a, List<Color> b, double t) {
    if (a.length != b.length) {
      return t < 0.5 ? a : b;
    }
    return List.generate(
      a.length,
      (i) => Color.lerp(a[i], b[i], t) ?? (t < 0.5 ? a[i] : b[i]),
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      gradientPrimary: _lerpGradient(gradientPrimary, other.gradientPrimary, t),
      gradientAccent: _lerpGradient(gradientAccent, other.gradientAccent, t),
      gradientCard: _lerpGradient(gradientCard, other.gradientCard, t),
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  RESPONSIVE & INSET HELPERS (Adaptive UI)
// ═══════════════════════════════════════════════════════════════════════════════

extension SehatiResponsiveX on BuildContext {
  /// Bottom system inset (misal navigation bar Android 3-button atau gesture bar)
  double get bottomInset => MediaQuery.of(this).padding.bottom;

  /// Top system inset (status bar / notch)
  double get topInset => MediaQuery.of(this).padding.top;

  /// Lebar layar perangkat
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Tinggi layar perangkat
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Perangkat layar sempit (< 360dp)
  bool get isCompactWidth => screenWidth < 360;

  /// Perangkat layar pendek (< 680dp)
  bool get isCompactHeight => screenHeight < 680;
}

