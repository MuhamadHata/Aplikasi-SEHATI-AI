import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../inti/tema/design_tokens.dart';
/// Overlay futuristik untuk animasi pemindaian AI pada kamera / gambar.
///
/// Menampilkan:
/// 1. Laser scanning beam dengan gradient trail bercahaya (glowing sweep).
/// 2. Gelombang radar konsentris (radar pulse) di tengah.
/// 3. Corner brackets bercahaya yang berdenyut lembut.
/// 4. HUD Glassmorphism pill di bagian atas dengan dual-ring spinner & tahapan teks AI dinamis.
class AiScanOverlay extends StatefulWidget {
  final Color primaryColor;
  final Color? secondaryColor;
  final List<String> statusSteps;
  final String title;

  const AiScanOverlay({
    super.key,
    this.primaryColor = AppColors.primary,
    this.secondaryColor,
    this.statusSteps = const [
      'Memindai visual objek...',
      'Menganalisis karakteristik...',
      'Menghitung estimasi AI...',
      'Menyusun rekomendasi personal...',
    ],
    this.title = 'AI Vision Engine',
  });

  @override
  State<AiScanOverlay> createState() => _AiScanOverlayState();
}

class _AiScanOverlayState extends State<AiScanOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _scanLineController;
  late final Animation<double> _scanLineAnimation;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  late final AnimationController _radarController;
  late final Animation<double> _radarAnimation;

  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();

    // Controller untuk garis laser bolak-balik
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scanLineAnimation = CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOutSine,
    );

    // Controller denyut sudut dan glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Controller gelombang radar konsentris
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _radarAnimation = CurvedAnimation(
      parent: _radarController,
      curve: Curves.easeOutCubic,
    );

    // Berganti pesan status secara bertahap
    _scanLineController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (mounted && widget.statusSteps.isNotEmpty) {
          setState(() {
            _currentStepIndex =
                (_currentStepIndex + 1) % widget.statusSteps.length;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.primaryColor;
    final secondary =
        widget.secondaryColor ?? activeColor.withValues(alpha: 0.7);

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;

        return Stack(
          children: [
            // ── 1. Gelombang radar konsentris di tengah ──
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _radarAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RadarWavePainter(
                      progress: _radarAnimation.value,
                      color: activeColor,
                    ),
                  );
                },
              ),
            ),

            // ── 2. Laser beam glow & trail ──
            AnimatedBuilder(
              animation: _scanLineAnimation,
              builder: (context, child) {
                final topPos = _scanLineAnimation.value * (height - 40) + 20;

                return Positioned(
                  top: topPos - 30,
                  left: 12,
                  right: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Gradient trail di atas garis
                      Container(
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              activeColor.withValues(alpha: 0.18),
                              activeColor.withValues(alpha: 0.45),
                            ],
                          ),
                        ),
                      ),
                      // Garis laser utama dengan neon glow
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: activeColor,
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: secondary,
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      // Gradient trail di bawah garis
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              activeColor.withValues(alpha: 0.25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ── 3. Corner Brackets bercahaya ──
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _GlowCornerBracketsPainter(
                      color: activeColor,
                      opacity: _pulseAnimation.value,
                    ),
                  );
                },
              ),
            ),

            // ── 4. Floating HUD Glassmorphism Pill di atas ──
            Positioned(
              top: 18,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: activeColor.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dual-ring animated spinner
                      _DualRingSpinner(
                        primaryColor: activeColor,
                        secondaryColor: secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: activeColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: activeColor,
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.title.toUpperCase(),
                                  style: TextStyle(
                                    color: activeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              transitionBuilder: (child, anim) {
                                return FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, 0.2),
                                      end: Offset.zero,
                                    ).animate(anim),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                widget.statusSteps.isNotEmpty
                                    ? widget.statusSteps[_currentStepIndex]
                                    : 'Sedang menganalisis...',
                                key: ValueKey<int>(_currentStepIndex),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Tombol atau bar proses AI yang elegan saat pemrosesan berlangsung.
class AiProcessingButton extends StatefulWidget {
  final Color primaryColor;
  final Color? secondaryColor;
  final String label;

  const AiProcessingButton({
    super.key,
    this.primaryColor = AppColors.primary,
    this.secondaryColor,
    this.label = 'Menganalisis dengan SEHATI AI...',
  });

  @override
  State<AiProcessingButton> createState() => _AiProcessingButtonState();
}

class _AiProcessingButtonState extends State<AiProcessingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.primaryColor;
    final secondary =
        widget.secondaryColor ?? activeColor.withValues(alpha: 0.8);

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E293B),
              ],
            ),
            border: Border.all(
              color: activeColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shimmer overlay beam
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      final val = _shimmerController.value;
                      return LinearGradient(
                        begin: Alignment(-1.5 + (val * 3.0), -0.5),
                        end: Alignment(-0.5 + (val * 3.0), 0.5),
                        colors: [
                          Colors.transparent,
                          activeColor.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.35),
                          activeColor.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcOver,
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
              // Content Row
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DualRingSpinner(
                      primaryColor: activeColor,
                      secondaryColor: secondary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        letterSpacing: 0.2,
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
  }
}

/// Dual-ring futuristic glowing spinner
class _DualRingSpinner extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final double size;

  const _DualRingSpinner({
    required this.primaryColor,
    required this.secondaryColor,
    this.size = 24,
  });

  @override
  State<_DualRingSpinner> createState() => _DualRingSpinnerState();
}

class _DualRingSpinnerState extends State<_DualRingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _DualRingPainter(
            rotation: _controller.value * 2 * math.pi,
            primaryColor: widget.primaryColor,
            secondaryColor: widget.secondaryColor,
          ),
        );
      },
    );
  }
}

class _DualRingPainter extends CustomPainter {
  final double rotation;
  final Color primaryColor;
  final Color secondaryColor;

  _DualRingPainter({
    required this.rotation,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = size.width / 3.2;

    // Outer ring (clockwise)
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        transform: GradientRotation(rotation),
        colors: [
          primaryColor.withValues(alpha: 0.1),
          primaryColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      rotation,
      math.pi * 1.5,
      false,
      outerPaint,
    );

    // Inner ring (counter-clockwise)
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        transform: GradientRotation(-rotation * 1.5),
        colors: [
          secondaryColor.withValues(alpha: 0.1),
          secondaryColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      -rotation * 1.5,
      math.pi * 1.2,
      false,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DualRingPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}

/// Gelombang konsentris memancar dari tengah
class _RadarWavePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadarWavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.45;

    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + (i / 3.0)) % 1.0;
      final radius = waveProgress * maxRadius;
      final alpha = (1.0 - waveProgress) * 0.35;

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Corner bracket pembingkai sudut bernuansa futuristik
class _GlowCornerBracketsPainter extends CustomPainter {
  final Color color;
  final double opacity;

  _GlowCornerBracketsPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.4)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 32.0;
    const padding = 20.0;

    const left = padding;
    const top = padding;
    final right = size.width - padding;
    final bottom = size.height - padding;

    // Helper draw corner
    void drawCorner(Offset p1, Offset corner, Offset p2) {
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(corner.dx, corner.dy)
        ..lineTo(p2.dx, p2.dy);
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }

    // Top-Left
    drawCorner(
      const Offset(left, top + cornerLength),
      const Offset(left, top),
      const Offset(left + cornerLength, top),
    );

    // Top-Right
    drawCorner(
      Offset(right - cornerLength, top),
      Offset(right, top),
      Offset(right, top + cornerLength),
    );

    // Bottom-Left
    drawCorner(
      Offset(left, bottom - cornerLength),
      Offset(left, bottom),
      Offset(left + cornerLength, bottom),
    );

    // Bottom-Right
    drawCorner(
      Offset(right - cornerLength, bottom),
      Offset(right, bottom),
      Offset(right, bottom - cornerLength),
    );
  }

  @override
  bool shouldRepaint(covariant _GlowCornerBracketsPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
