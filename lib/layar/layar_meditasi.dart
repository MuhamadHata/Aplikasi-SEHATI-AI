import 'package:flutter/material.dart';
import '../../inti/tema/design_tokens.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:video_player/video_player.dart';

class MeditationScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const MeditationScreen({super.key, required this.data});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  VideoPlayerController? _audioController;

  final FlutterTts _flutterTts = FlutterTts();

  bool _isPlaying = false;
  int _timeRemaining = 0;
  Timer? _timer;

  // States info
  String _currentInstruction = "Sentuh Mulai untuk bersiap";

  @override
  void initState() {
    super.initState();
    _initTts();
    _initAudio();

    // Parse duration string to seconds
    final durStr = widget.data['duration']?.toString() ?? '5 menit';
    final match = RegExp(r'\d+').firstMatch(durStr);
    int minutes = 5;
    if (match != null) {
      minutes = int.parse(match.group(0)!);
    }
    _timeRemaining = minutes * 60;

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // 4 seconds inhale
    );

    _breathingAnimation = Tween<double>(begin: 0.6, end: 1.2).animate(
      CurvedAnimation(
          parent: _breathingController, curve: Curves.easeInOutSine),
    );
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("id-ID");
    await _flutterTts.setSpeechRate(0.4); // Slower for meditation
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(0.9); // Deeper, calmer voice
  }

  void _initAudio() {
    // Musik Zen/Nature sebagai background
    _audioController = VideoPlayerController.networkUrl(
      Uri.parse(
          'https://files.freemusicarchive.org/storage-freemusicarchive-org/music/Music_for_Video/Ketsa/Bringing_The_Soft/Ketsa_-_01_-_Bringing_The_Soft.mp3'),
    )..initialize().then((_) {
        _audioController?.setLooping(true);
        _audioController?.setVolume(0.3); // Sangat lembut untuk background
        setState(() {});
      });
  }

  void _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _togglePlay() {
    if (_isPlaying) {
      // Pause
      _timer?.cancel();
      _breathingController.stop();
      _flutterTts.stop();
      _audioController?.pause();
      setState(() {
        _isPlaying = false;
        _currentInstruction = "Sesi Dijeda";
      });
    } else {
      // Play
      setState(() {
        _isPlaying = true;
      });
      _startBreathingCycle();
      _audioController?.play();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeRemaining > 0) {
          setState(() {
            _timeRemaining--;
          });
        } else {
          _finishSession();
        }
      });
    }
  }

  void _startBreathingCycle() async {
    if (!_isPlaying) return;

    setState(() {
      _currentInstruction = "Tarik Napas...";
    });
    _speak("Tarik napas panjang...");

    _breathingController.duration = const Duration(seconds: 4);
    await _breathingController.forward();
    if (!_isPlaying) return;

    setState(() {
      _currentInstruction = "Tahan...";
    });
    // Quiet hold for 2s, maybe a subtle sound effect in the future
    await Future.delayed(const Duration(seconds: 2));
    if (!_isPlaying) return;

    setState(() {
      _currentInstruction = "Hembuskan perlahan...";
    });
    _speak("Hembuskan perlahan...");

    _breathingController.duration = const Duration(seconds: 4);
    await _breathingController.reverse();
    if (!_isPlaying) return;

    // Hold empty for 2s
    setState(() {
      _currentInstruction = "Rileks...";
    });
    await Future.delayed(const Duration(seconds: 2));

    // Loop
    if (_isPlaying && _timeRemaining > 0) {
      _startBreathingCycle();
    }
  }

  void _finishSession() {
    _timer?.cancel();
    _breathingController.stop();
    _audioController?.pause();
    setState(() {
      _isPlaying = false;
      _timeRemaining = 0;
      _currentInstruction = "Sesi Selesai. Tetap damai.";
    });
    _speak(
        "Sesi meditasi selesai. Terima kasih telah meluangkan waktu untuk diri sendiri.");
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    _flutterTts.stop();
    _audioController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor, // Light, calm meditation bg
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Meditasi',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 680;
            final outerSize = isCompact ? 180.0 : 250.0;
            final midSize = isCompact ? 140.0 : 200.0;
            final innerSize = isCompact ? 110.0 : 150.0;
            final emojiSize = isCompact ? 48.0 : 67.0;
            final timerSize = isCompact ? 38.0 : 51.0;
            final btnSize = isCompact ? 72.0 : 90.0;
            final btnIconSize = isCompact ? 40.0 : 50.0;
            final spacing = isCompact ? 14.0 : 32.0;

            return Column(
              children: [
                SizedBox(height: isCompact ? 8 : 16),
                Text(
                  widget.data['title'] ?? 'Latihan Pernapasan',
                  style: TextStyle(
                    fontSize: isCompact ? 22 : 27,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'Poppins',
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    widget.data['desc'] ?? 'Tenangkan pikiran dan tubuh.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 16,
                      color: theme.textTheme.bodyMedium?.color,
                      height: 1.4,
                    ),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow/ring
                        AnimatedBuilder(
                          animation: _breathingAnimation,
                          builder: (context, child) {
                            return Container(
                              width: outerSize * _breathingAnimation.value,
                              height: outerSize * _breathingAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ext?.info.withValues(alpha: 0.15) ??
                                    const Color(0xFF4FC3F7).withValues(alpha: 0.15),
                              ),
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: _breathingAnimation,
                          builder: (context, child) {
                            return Container(
                              width: midSize * _breathingAnimation.value,
                              height: midSize * _breathingAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ext?.info.withValues(alpha: 0.25) ??
                                    const Color(0xFF4FC3F7).withValues(alpha: 0.25),
                              ),
                            );
                          },
                        ),
                        // Inner core
                        Container(
                          width: innerSize,
                          height: innerSize,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  ext?.info.withValues(alpha: 0.7) ??
                                      const Color(0xFF81D4FA),
                                  ext?.info ?? const Color(0xFF29B6F6)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color: ext?.info ?? const Color(0xFF29B6F6),
                                    blurRadius: 30,
                                    spreadRadius: 5)
                              ]),
                          child: Center(
                            child: Text(
                              widget.data['emoji'] ?? '🧘',
                              style: TextStyle(fontSize: emojiSize),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Text Instruction
                AnimatedSwitcher(
                  duration: const Duration(seconds: 1),
                  child: Text(
                    _currentInstruction,
                    key: ValueKey(_currentInstruction),
                    style: TextStyle(
                      fontSize: isCompact ? 20 : 25,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                      fontFamily: 'Poppins',
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                SizedBox(height: spacing),

                // Timer Display
                Text(
                  _formatTime(_timeRemaining),
                  style: TextStyle(
                    fontSize: timerSize,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'Courier',
                    letterSpacing: 2,
                  ),
                ),

                SizedBox(height: spacing),

                // Play/Pause Control
                GestureDetector(
                  onTap: _togglePlay,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: btnSize,
                    height: btnSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isPlaying
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.primary,
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Icon(
                      _timeRemaining == 0
                          ? Icons.replay_rounded
                          : (_isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded),
                      size: btnIconSize,
                      color: _isPlaying ? theme.colorScheme.primary : Colors.white,
                    ),
                  ),
                ),

                SizedBox(height: isCompact ? 16 : 36),
              ],
            );
          },
        ),
      ),
    );
  }
}
