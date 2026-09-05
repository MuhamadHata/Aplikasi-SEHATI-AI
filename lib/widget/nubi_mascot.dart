import 'package:flutter/material.dart';
import 'dart:math' as math;

// ============================================================
// NUBI MASCOT ANIMATIONS
// Karakter: Nubi - maskot kesehatan anime chibi
// Setiap pose punya animasi yang sesuai dengan tujuannya
// ============================================================

enum NubiPose {
  meditate, // meditasi - floating + glow pulsing
  run, // berlari - bouncing + sparkle
  sleep, // tidur - gentle rock + zzz floating
  study, // belajar - subtle bob + pen writing
  success, // sukses - thumbs up + scale bounce
  wave, // melambaikan tangan - swing + sparkle
  doctor, // dokter - head bob + heartbeat icon
  drink, // minum - tilt + ripple
  eat, // makan - bite bob + shine
  fit, // fitness - bicep curl up-down
}

class NubiMascot extends StatefulWidget {
  final NubiPose pose;
  final double size;
  final bool autoPlay;
  final bool showEffects;

  const NubiMascot({
    super.key,
    required this.pose,
    this.size = 200,
    this.autoPlay = true,
    this.showEffects = true,
  });

  @override
  State<NubiMascot> createState() => _NubiMascotState();
}

class _NubiMascotState extends State<NubiMascot> with TickerProviderStateMixin {
  // Primary animation controller
  late AnimationController _primaryController;
  // Secondary animation for layered effects
  late AnimationController _secondaryController;
  // Particle/decoration animation
  late AnimationController _particleController;

  // Animations
  late Animation<double> _floatAnim;
  late Animation<double> _rotateAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _particleAnim;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _setupAnimations();
    if (widget.autoPlay) _startAnimations();
  }

  @override
  void didUpdateWidget(covariant NubiMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pose != widget.pose) {
      _primaryController.duration = _getPrimaryDuration();
      _secondaryController.duration = _getSecondaryDuration();
      _setupAnimations();
      if (widget.autoPlay) {
        _startAnimations();
      } else {
        _primaryController.stop();
        _secondaryController.stop();
        _particleController.stop();
      }
    } else if (oldWidget.autoPlay != widget.autoPlay) {
      if (widget.autoPlay) {
        _startAnimations();
      } else {
        _primaryController.stop();
        _secondaryController.stop();
        _particleController.stop();
      }
    }
  }

  void _initControllers() {
    _primaryController = AnimationController(
      vsync: this,
      duration: _getPrimaryDuration(),
    );
    _secondaryController = AnimationController(
      vsync: this,
      duration: _getSecondaryDuration(),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  Duration _getPrimaryDuration() {
    switch (widget.pose) {
      case NubiPose.meditate:
        return const Duration(milliseconds: 3000);
      case NubiPose.run:
        return const Duration(milliseconds: 600);
      case NubiPose.sleep:
        return const Duration(milliseconds: 4000);
      case NubiPose.study:
        return const Duration(milliseconds: 2000);
      case NubiPose.success:
        return const Duration(milliseconds: 800);
      case NubiPose.wave:
        return const Duration(milliseconds: 1000);
      case NubiPose.doctor:
        return const Duration(milliseconds: 2500);
      case NubiPose.drink:
        return const Duration(milliseconds: 2200);
      case NubiPose.eat:
        return const Duration(milliseconds: 1500);
      case NubiPose.fit:
        return const Duration(milliseconds: 900);
    }
  }

  Duration _getSecondaryDuration() {
    switch (widget.pose) {
      case NubiPose.meditate:
        return const Duration(milliseconds: 2000);
      case NubiPose.run:
        return const Duration(milliseconds: 400);
      default:
        return const Duration(milliseconds: 1500);
    }
  }

  void _setupAnimations() {
    switch (widget.pose) {
      case NubiPose.meditate:
        _floatAnim = Tween<double>(begin: 0, end: -12).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
          CurvedAnimation(
              parent: _secondaryController, curve: Curves.easeInOut),
        );
        _scaleAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _rotateAnim = ConstantTween<double>(0.0).animate(_primaryController);
        _particleAnim = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
        );
        break;

      case NubiPose.run:
        _floatAnim = Tween<double>(begin: 0, end: -8).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _rotateAnim = Tween<double>(begin: -0.03, end: 0.03).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _scaleAnim = ConstantTween<double>(1.0).animate(_primaryController);
        _glowAnim = ConstantTween<double>(0.0).animate(_primaryController);
        _particleAnim = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _particleController, curve: Curves.linear),
        );
        break;

      case NubiPose.sleep:
        _floatAnim = Tween<double>(begin: 0, end: -5).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _rotateAnim = Tween<double>(begin: -0.02, end: 0.02).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _scaleAnim = Tween<double>(begin: 1.0, end: 1.02).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _glowAnim = Tween<double>(begin: 0.1, end: 0.5).animate(
          CurvedAnimation(
              parent: _secondaryController, curve: Curves.easeInOut),
        );
        _particleAnim = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
        );
        break;

      case NubiPose.study:
        _floatAnim = Tween<double>(begin: 0, end: -4).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _rotateAnim = Tween<double>(begin: -0.01, end: 0.01).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _scaleAnim = ConstantTween<double>(1.0).animate(_primaryController);
        _glowAnim = Tween<double>(begin: 0.2, end: 0.6).animate(
          CurvedAnimation(
              parent: _secondaryController, curve: Curves.easeInOut),
        );
        _particleAnim = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _particleController, curve: Curves.linear),
        );
        break;

      case NubiPose.success:
        _scaleAnim = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.05), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _floatAnim = Tween<double>(begin: 0, end: -10).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _rotateAnim = ConstantTween<double>(0.0).animate(_primaryController);
        _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _secondaryController, curve: Curves.easeOut),
        );
        _particleAnim = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
        );
        break;

      case NubiPose.wave:
        _floatAnim = Tween<double>(begin: 0, end: -6).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _rotateAnim = Tween<double>(begin: -0.04, end: 0.04).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _scaleAnim = ConstantTween<double>(1.0).animate(_primaryController);
        _glowAnim = Tween<double>(begin: 0.0, end: 0.8).animate(
          CurvedAnimation(
              parent: _secondaryController, curve: Curves.easeInOut),
        );
        _particleAnim = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
        );
        break;

      case NubiPose.doctor:
        _floatAnim = Tween<double>(begin: 0, end: -6).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _rotateAnim = ConstantTween<double>(0.0).animate(_primaryController);
        _scaleAnim = Tween<double>(begin: 1.0, end: 1.02).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
          CurvedAnimation(
              parent: _secondaryController, curve: Curves.easeInOut),
        );
        _particleAnim = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
        );
        break;

      case NubiPose.drink:
        _rotateAnim = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.08), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 0.08, end: 0.08), weight: 3),
          TweenSequenceItem(tween: Tween(begin: 0.08, end: 0.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 3),
        ]).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _floatAnim = Tween<double>(begin: 0, end: -4).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _scaleAnim = ConstantTween<double>(1.0).animate(_primaryController);
        _glowAnim = Tween<double>(begin: 0.1, end: 0.6).animate(
          CurvedAnimation(
              parent: _secondaryController, curve: Curves.easeInOut),
        );
        _particleAnim = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _particleController, curve: Curves.linear),
        );
        break;

      case NubiPose.eat:
        _floatAnim = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -5.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -3.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -3.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _rotateAnim = ConstantTween<double>(0.0).animate(_primaryController);
        _scaleAnim = ConstantTween<double>(1.0).animate(_primaryController);
        _glowAnim = Tween<double>(begin: 0.2, end: 0.7).animate(
          CurvedAnimation(
              parent: _secondaryController, curve: Curves.easeInOut),
        );
        _particleAnim = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
        );
        break;

      case NubiPose.fit:
        _floatAnim = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _scaleAnim = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _primaryController, curve: Curves.easeInOut),
        );
        _rotateAnim = ConstantTween<double>(0.0).animate(_primaryController);
        _glowAnim = Tween<double>(begin: 0.2, end: 0.9).animate(
          CurvedAnimation(
              parent: _secondaryController, curve: Curves.easeInOut),
        );
        _particleAnim = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
        );
        break;
    }
  }

  void _startAnimations() {
    _primaryController.repeat(reverse: true);
    _secondaryController.repeat(reverse: true);
    _particleController.repeat();
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  String get _imagePath {
    switch (widget.pose) {
      case NubiPose.meditate:
        return 'assets/images/maskot_nubi_meditate.png';
      case NubiPose.run:
        return 'assets/images/maskot_nubi_run.png';
      case NubiPose.sleep:
        return 'assets/images/maskot_nubi_sleep.png';
      case NubiPose.study:
        return 'assets/images/maskot_nubi_study.png';
      case NubiPose.success:
        return 'assets/images/maskot_nubi_success.png';
      case NubiPose.wave:
        return 'assets/images/maskot_nubi_wave.png';
      case NubiPose.doctor:
        return 'assets/images/maskot_nubi_doctor.png';
      case NubiPose.drink:
        return 'assets/images/maskot_nubi_drink.png';
      case NubiPose.eat:
        return 'assets/images/maskot_nubi_eat.png';
      case NubiPose.fit:
        return 'assets/images/maskot_nubi_fit.png';
    }
  }

  Color get _glowColor {
    // Warna glow disesuaikan dengan skema warna karakter Nubi asli
    // (biru teal / cyan sebagai warna dominan karakter)
    switch (widget.pose) {
      case NubiPose.meditate:
        return const Color(0xFF00BCD4); // cyan teal — ketenangan
      case NubiPose.run:
        return const Color(0xFF4CAF50); // hijau energi — lari
      case NubiPose.sleep:
        return const Color(0xFF9C27B0); // ungu malam — tidur
      case NubiPose.study:
        return const Color(0xFF2196F3); // biru belajar — studi
      case NubiPose.success:
        return const Color(0xFFFFB300); // amber emas — sukses
      case NubiPose.wave:
        return const Color(0xFF00BCD4); // cyan teal — sapaan
      case NubiPose.doctor:
        return const Color(0xFFE53935); // merah medis — dokter
      case NubiPose.drink:
        return const Color(0xFF29B6F6); // light blue — air
      case NubiPose.eat:
        return const Color(0xFFFF7043); // orange salmon — makan
      case NubiPose.fit:
        return const Color(0xFF66BB6A); // hijau segar — fitness
    }
  }

  Widget _buildParticleOverlay() {
    switch (widget.pose) {
      case NubiPose.meditate:
        return _MeditateParticles(
            animation: _particleAnim, glowAnim: _glowAnim);
      case NubiPose.run:
        return _RunSparkles(animation: _particleAnim);
      case NubiPose.sleep:
        return _SleepZzz(animation: _particleAnim);
      case NubiPose.study:
        return _StudyStars(animation: _particleAnim);
      case NubiPose.success:
        return _SuccessConfetti(animation: _particleAnim);
      case NubiPose.wave:
        return _WaveSparkles(animation: _particleAnim);
      case NubiPose.doctor:
        return _HeartbeatPulse(glowAnim: _glowAnim);
      case NubiPose.drink:
        return _WaterDroplets(animation: _particleAnim);
      case NubiPose.eat:
        return _FoodShine(animation: _particleAnim);
      case NubiPose.fit:
        return _FitEnergy(animation: _particleAnim, glowAnim: _glowAnim);
    }
  }

  Widget _buildMascotContent() {
    // Menggunakan gambar PNG statik berkualitas tinggi sesuai permintaan
    return Image.asset(
      _imagePath,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _primaryController,
        _secondaryController,
        _particleController,
      ]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size * 1.5,
          height: widget.size * 1.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow background — diperkecil dan lebih subtle agar tidak mendominasi
              if (widget.showEffects && _glowAnim.value > 0)
                Container(
                  width: widget.size * 0.9,
                  height: widget.size * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _glowColor.withValues(alpha: _glowAnim.value * 0.25),
                        _glowColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),

              // Particle overlay (behind character)
              if (widget.showEffects)
                Positioned.fill(child: _buildParticleOverlay()),

              // Character image or video with animations
              // Lingkaran putih di belakang karakter agar warna tidak nyatu dengan background
              Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: Transform.rotate(
                  angle: _rotateAnim.value,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: widget.size * 0.8,
                          height: widget.size * 0.8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        _buildMascotContent(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// PARTICLE WIDGETS
// ============================================================

class _MeditateParticles extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> glowAnim;
  const _MeditateParticles({required this.animation, required this.glowAnim});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter:
          _MeditatePainter(progress: animation.value, glow: glowAnim.value),
    );
  }
}

class _MeditatePainter extends CustomPainter {
  final double progress;
  final double glow;
  _MeditatePainter({required this.progress, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Orbiting energy dots
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      final angle = (progress * math.pi * 2) + (i * math.pi / 3);
      final r = size.width * 0.38;
      final x = cx + math.cos(angle) * r;
      final y = cy + math.sin(angle) * r * 0.4;
      final opacity =
          (math.sin(angle + progress * math.pi) * 0.4 + 0.6).clamp(0.2, 1.0);
      paint.color = const Color(0xFF7FFFD4).withValues(alpha: opacity * glow);
      canvas.drawCircle(Offset(x, y), 4, paint);
    }

    // Gentle aura rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF7FFFD4).withValues(alpha: 0.15 * glow);
    for (int i = 0; i < 3; i++) {
      final scale = 0.5 + (i * 0.15) + (progress * 0.08);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy + 10),
          width: size.width * scale,
          height: size.height * scale * 0.3,
        ),
        ringPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MeditatePainter old) => true;
}

// ---

class _RunSparkles extends StatelessWidget {
  final Animation<double> animation;
  const _RunSparkles({required this.animation});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklesPainter(
          progress: animation.value, color: const Color(0xFFFFD700)),
    );
  }
}

class _SparklesPainter extends CustomPainter {
  final double progress;
  final Color color;
  _SparklesPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final rng = math.Random(42);
    for (int i = 0; i < 8; i++) {
      final offset = (progress + i / 8) % 1.0;
      final x = rng.nextDouble() * size.width;
      final y = size.height * 0.2 + rng.nextDouble() * size.height * 0.5;
      final opacity = (1.0 - offset).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: opacity);
      _drawStar(canvas, Offset(x, y), 5 * (1 - offset * 0.5), paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final outer = Offset(center.dx + math.cos(angle) * size,
          center.dy + math.sin(angle) * size);
      final inner1 = Offset(
          center.dx + math.cos(angle + math.pi / 4) * size * 0.3,
          center.dy + math.sin(angle + math.pi / 4) * size * 0.3);
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner1.dx, inner1.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklesPainter old) => true;
}

// ---

class _SleepZzz extends StatelessWidget {
  final Animation<double> animation;
  const _SleepZzz({required this.animation});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ZzzPainter(progress: animation.value));
  }
}

class _ZzzPainter extends CustomPainter {
  final double progress;
  _ZzzPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    TextStyle textStyle(int i) => TextStyle(
          color: const Color(0xFF87CEEB).withValues(
              alpha: ((1.0 - (progress + i * 0.33) % 1.0)).clamp(0.0, 0.9)),
          fontSize: 14.0 + i * 5,
          fontWeight: FontWeight.bold,
        );

    for (int i = 0; i < 3; i++) {
      final p = (progress + i * 0.33) % 1.0;
      final x = size.width * 0.62 + i * 12.0;
      final y = size.height * 0.2 - p * size.height * 0.25;
      final tp = TextPainter(
        text: TextSpan(text: 'z', style: textStyle(i)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(_ZzzPainter old) => true;
}

// ---

class _StudyStars extends StatelessWidget {
  final Animation<double> animation;
  const _StudyStars({required this.animation});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StudyStarsPainter(progress: animation.value));
  }
}

class _StudyStarsPainter extends CustomPainter {
  final double progress;
  _StudyStarsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.amber;
    final positions = [
      Offset(size.width * 0.15, size.height * 0.25),
      Offset(size.width * 0.82, size.height * 0.22),
      Offset(size.width * 0.75, size.height * 0.45),
      Offset(size.width * 0.12, size.height * 0.50),
    ];
    for (int i = 0; i < positions.length; i++) {
      final pulse =
          math.sin(progress * math.pi * 2 + i * math.pi / 2) * 0.5 + 0.5;
      paint.color = Colors.amber.withValues(alpha: 0.3 + pulse * 0.6);
      canvas.drawCircle(positions[i], 3 + pulse * 2, paint);
    }
  }

  @override
  bool shouldRepaint(_StudyStarsPainter old) => true;
}

// ---

class _SuccessConfetti extends StatelessWidget {
  final Animation<double> animation;
  const _SuccessConfetti({required this.animation});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ConfettiPainter(progress: animation.value));
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter({required this.progress});

  final colors = const [
    Color(0xFFFFD700),
    Color(0xFFFF69B4),
    Color(0xFF00CED1),
    Color(0xFF98FB98),
    Color(0xFFFFA500),
    Color(0xFF9370DB),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(99);
    for (int i = 0; i < 20; i++) {
      final startX = rng.nextDouble() * size.width;
      final p = (progress + i / 20) % 1.0;
      final y = p * size.height;
      final x = startX + math.sin(p * math.pi * 3 + i) * 20;
      final paint = Paint()
        ..color = colors[i % colors.length]
            .withValues(alpha: (1.0 - p).clamp(0.0, 0.9));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p * math.pi * 4);
      canvas.drawRect(const Rect.fromLTWH(-3, -3, 6, 6), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

// ---

class _WaveSparkles extends StatelessWidget {
  final Animation<double> animation;
  const _WaveSparkles({required this.animation});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        painter: _WaveSparklesPainter(progress: animation.value));
  }
}

class _WaveSparklesPainter extends CustomPainter {
  final double progress;
  _WaveSparklesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF98FB98);
    for (int i = 0; i < 5; i++) {
      final angle = (progress * math.pi * 2) + (i * math.pi * 2 / 5);
      final r = size.width * 0.35;
      final x = size.width * 0.5 + math.cos(angle) * r;
      final y = size.height * 0.4 + math.sin(angle) * r * 0.5;
      final scale = math.sin(progress * math.pi * 2 + i) * 0.5 + 0.5;
      paint.color =
          const Color(0xFF98FB98).withValues(alpha: 0.3 + scale * 0.5);
      _drawDiamond(canvas, Offset(x, y), 4 + scale * 4, paint);
    }
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.5, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.5, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WaveSparklesPainter old) => true;
}

// ---

class _HeartbeatPulse extends StatelessWidget {
  final Animation<double> glowAnim;
  const _HeartbeatPulse({required this.glowAnim});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _HeartbeatPainter(pulse: glowAnim.value));
  }
}

class _HeartbeatPainter extends CustomPainter {
  final double pulse;
  _HeartbeatPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    // ECG-like line at bottom
    final paint = Paint()
      ..color = const Color(0xFFFF6B6B).withValues(alpha: 0.5 + pulse * 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final y = size.height * 0.82;
    final startX = size.width * 0.1;
    final w = size.width * 0.8;
    path.moveTo(startX, y);
    path.lineTo(startX + w * 0.3, y);
    path.lineTo(startX + w * 0.38, y - 15 * pulse);
    path.lineTo(startX + w * 0.42, y + 8 * pulse);
    path.lineTo(startX + w * 0.46, y - 25 * pulse);
    path.lineTo(startX + w * 0.50, y + 5 * pulse);
    path.lineTo(startX + w * 0.54, y);
    path.lineTo(startX + w, y);
    canvas.drawPath(path, paint);

    // Pulsing heart icon
    final heartPaint = Paint()
      ..color = const Color(0xFFFF6B6B).withValues(alpha: pulse * 0.6)
      ..style = PaintingStyle.fill;
    final cx = size.width * 0.5;
    final cy = size.height * 0.18;
    final s = 8 * pulse;
    canvas.drawCircle(Offset(cx - s * 0.5, cy), s, heartPaint);
    canvas.drawCircle(Offset(cx + s * 0.5, cy), s, heartPaint);
    final triPath = Path()
      ..moveTo(cx - s * 1.1, cy + s * 0.3)
      ..lineTo(cx + s * 1.1, cy + s * 0.3)
      ..lineTo(cx, cy + s * 2.0)
      ..close();
    canvas.drawPath(triPath, heartPaint);
  }

  @override
  bool shouldRepaint(_HeartbeatPainter old) => true;
}

// ---

class _WaterDroplets extends StatelessWidget {
  final Animation<double> animation;
  const _WaterDroplets({required this.animation});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        painter: _WaterDropletsPainter(progress: animation.value));
  }
}

class _WaterDropletsPainter extends CustomPainter {
  final double progress;
  _WaterDropletsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF87CEEB)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final p = (progress + i / 5) % 1.0;
      final x = size.width * (0.55 + (i % 3) * 0.08);
      final y = size.height * 0.25 + p * size.height * 0.3;
      paint.color =
          const Color(0xFF87CEEB).withValues(alpha: (1.0 - p).clamp(0.0, 0.8));
      _drawDroplet(canvas, Offset(x, y), 5 * (1 - p * 0.5), paint);
    }
  }

  void _drawDroplet(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size * 1.5)
      ..quadraticBezierTo(
          center.dx + size, center.dy, center.dx, center.dy + size)
      ..quadraticBezierTo(
          center.dx - size, center.dy, center.dx, center.dy - size * 1.5)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WaterDropletsPainter old) => true;
}

// ---

class _FoodShine extends StatelessWidget {
  final Animation<double> animation;
  const _FoodShine({required this.animation});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _FoodShinePainter(progress: animation.value));
  }
}

class _FoodShinePainter extends CustomPainter {
  final double progress;
  _FoodShinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    // Shine lines from apple area
    for (int i = 0; i < 4; i++) {
      final angle = -math.pi / 4 + (i * math.pi / 8);
      final pulse = math.sin(progress * math.pi * 2 + i) * 0.5 + 0.5;
      paint.color = Colors.orange.withValues(alpha: pulse * 0.5);
      final cx = size.width * 0.32;
      final cy = size.height * 0.42;
      canvas.drawLine(
        Offset(cx + math.cos(angle) * 15, cy + math.sin(angle) * 15),
        Offset(cx + math.cos(angle) * (25 + pulse * 10),
            cy + math.sin(angle) * (25 + pulse * 10)),
        Paint()
          ..color = Colors.orange.withValues(alpha: pulse * 0.5)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_FoodShinePainter old) => true;
}

// ---

class _FitEnergy extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> glowAnim;
  const _FitEnergy({required this.animation, required this.glowAnim});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter:
          _FitEnergyPainter(progress: animation.value, glow: glowAnim.value),
    );
  }
}

class _FitEnergyPainter extends CustomPainter {
  final double progress;
  final double glow;
  _FitEnergyPainter({required this.progress, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // Energy burst lines from dumbbell area
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final pulse = math.sin(progress * math.pi * 2 + i * 0.5) * 0.5 + 0.5;
      final length = 15 + pulse * 20;
      final cx = size.width * 0.5;
      final cy = size.height * 0.42;
      paint
        ..color = const Color(0xFF90EE90).withValues(alpha: pulse * 0.6)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(cx + math.cos(angle) * 55, cy + math.sin(angle) * 30),
        Offset(cx + math.cos(angle) * (55 + length),
            cy + math.sin(angle) * (30 + length * 0.5)),
        paint,
      );
    }

    // Sweat drops
    for (int i = 0; i < 3; i++) {
      final p = (progress + i / 3) % 1.0;
      final x = size.width * (0.18 + i * 0.07);
      final y = size.height * 0.25 + p * size.height * 0.2;
      final dropPaint = Paint()
        ..color =
            const Color(0xFF87CEEB).withValues(alpha: (1 - p).clamp(0.0, 0.7))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 3, dropPaint);
    }
  }

  @override
  bool shouldRepaint(_FitEnergyPainter old) => true;
}
