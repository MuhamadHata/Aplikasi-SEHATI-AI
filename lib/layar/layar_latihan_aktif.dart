import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../inti/tema/design_tokens.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import '../../inti/tema/ikon_mapper.dart';
import '../../inti/model/catatan_aktivitas.dart';
import '../../inti/layanan/cache_gif_latihan.dart';
import '../../inti/layanan/layanan_media_latihan.dart';
import 'pemutar_youtube_latihan.dart';
import 'pemutar_video_lokal.dart';
import 'layar_ringkasan_latihan.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final Map<String, dynamic> workoutData;
  final double userWeightKg;

  const ActiveWorkoutScreen({
    super.key,
    required this.workoutData,
    this.userWeightKg = 65.0,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _SetRowData {
  int reps;
  bool completed = false;

  _SetRowData({required this.reps});
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen>
    with TickerProviderStateMixin {
  late List<dynamic> _exercises;
  int _currentIndex = 0;
  bool _isFinished = false;

  // Timer mode
  bool _isPlaying = false;
  int _timeRemaining = 0;
  Timer? _exTimer;

  // Rest
  bool _isResting = false;
  int _restSeconds = 0;
  Timer? _restTimer;

  // Rep mode
  bool _isRepMode = false;
  late List<_SetRowData> _setRows;
  int _activeSet = 0;

  // Session elapsed
  int _elapsed = 0; // seconds — always counting
  Timer? _elapsedTimer;

  // Calorie tracking
  final List<ExerciseSetRecord> _history = [];
  double _totalCal = 0.0;

  // GIF URL resolved per exercise
  String? _currentGifUrl;
  bool _gifLoading = false;

  // TTS
  final FlutterTts _tts = FlutterTts();

  // ─── Init ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initTts();
    _exercises = widget.workoutData['exercises'] ?? [];

    // Always-running elapsed timer
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });

    // Pre-warm GIF cache in background
    if (_exercises.isNotEmpty) {
      ExerciseGifCache.preWarm(
        _exercises
            .map((e) => (e['name'] ?? '') as String)
            .where((n) => n.isNotEmpty)
            .toList(),
      );
    }

    if (_exercises.isNotEmpty) {
      _loadExercise(0);
    } else {
      setState(() => _isFinished = true);
    }
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('id-ID');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
    } catch (e) {
      debugPrint('TTS Init Error: $e');
    }
  }

  void _speak(String t) {
    try {
      _tts.speak(t);
    } catch (e) {
      debugPrint('TTS Speak Error: $e');
    }
  }

  // ─── GIF / Video Resolution ──────────────────────────────────────
  Future<void> _resolveGif(String exerciseName) async {
    setState(() {
      _currentGifUrl = null;
      _gifLoading = true;
    });

    // Priority 1 — local MP4 video
    final videoPath = getLocalVideoPath(exerciseName);
    if (videoPath != null) {
      setState(() {
        _currentGifUrl = 'asset:$videoPath';
        _gifLoading = false;
      });
      return;
    }

    // Priority 2 — local GIF asset (or network GIF URL from latihanfisik.com)
    final gifPath = getLocalGifPath(exerciseName);
    if (gifPath != null) {
      setState(() {
        // gifPath may be 'localGif:assets/...' or 'networkGif:https://...' or just 'assets/...'
        if (gifPath.startsWith('networkGif:') ||
            gifPath.startsWith('localGif:')) {
          _currentGifUrl = gifPath;
        } else {
          _currentGifUrl = 'localGif:$gifPath';
        }
        _gifLoading = false;
      });
      return;
    }

    // Priority 3 — local DB network GIF URL
    final localUrl = ExerciseMediaService.localGifUrl(exerciseName);
    if (localUrl != null &&
        localUrl.isNotEmpty &&
        !localUrl.contains('/search')) {
      setState(() {
        _currentGifUrl = localUrl;
        _gifLoading = false;
      });
      return;
    }

    // Priority 4 — ExerciseDB RapidAPI
    final apiUrl = await ExerciseGifCache.getGifUrl(exerciseName);
    if (mounted) {
      setState(() {
        _currentGifUrl = apiUrl;
        _gifLoading = false;
      });
    }
  }

  // ─── Load Exercise ──────────────────────────────────────────────────────
  void _loadExercise(int i) {
    if (i >= _exercises.length) {
      _finishWorkout();
      return;
    }
    final ex = _exercises[i];
    final int dur = ex['durationSeconds'] as int? ?? 0;
    final int sets = ex['sets'] as int? ?? 3;
    final int reps = ex['reps'] as int? ?? 12;
    final bool repMode = dur == 0;

    setState(() {
      _currentIndex = i;
      _isRepMode = repMode;
      _setRows =
          List.generate(sets > 0 ? sets : 1, (_) => _SetRowData(reps: reps));
      _activeSet = 0;
      _timeRemaining = dur;
      _isPlaying = false;
      _isResting = true;
      _restSeconds = i == 0 ? 3 : 20;
    });

    _resolveGif(ex['name'] ?? '');
    _speak(i == 0
        ? 'Bersiap untuk ${ex['name'] ?? ''}.'
        : 'Istirahat. Selanjutnya: ${ex['name'] ?? ''}.');

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _startRestTimer();
    });
  }

  // ─── Rest Timer ─────────────────────────────────────────────────────────
  void _startRestTimer() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_restSeconds <= 0) {
        t.cancel();
        setState(() => _isResting = false);
        _speak('Mulai!');
        if (!_isRepMode) _startTimer();
        return;
      }
      setState(() => _restSeconds--);
      if (_restSeconds <= 3 && _restSeconds > 0) _speak('$_restSeconds');
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _restSeconds = 0;
      _isResting = false;
    });
    _speak('Mulai!');
    if (!_isRepMode) _startTimer();
  }

  // ─── Timer Mode ─────────────────────────────────────────────────────────
  void _startTimer() {
    _exTimer?.cancel();
    setState(() => _isPlaying = true);
    final total = _exercises[_currentIndex]['durationSeconds'] ?? 30;

    _exTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_timeRemaining <= 0) {
        t.cancel();
        _recordTimer(total);
        _speak('Waktu Habis.');
        _loadExercise(_currentIndex + 1);
        return;
      }
      setState(() => _timeRemaining--);
      if (_timeRemaining == 3) _speak('Tiga');
      if (_timeRemaining == 2) _speak('Dua');
      if (_timeRemaining == 1) _speak('Satu');
    });
  }

  void _pauseResume() {
    if (_isPlaying) {
      _exTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      _startTimer();
    }
  }

  void _recordTimer(int dur) {
    final ex = _exercises[_currentIndex];
    final cal = calculateCaloriesMet(
      exerciseName: ex['name'] ?? '',
      durationSeconds: dur.toDouble(),
      weightKg: widget.userWeightKg,
    );
    final rec = ExerciseSetRecord(
      exerciseName: ex['name'] ?? '',
      exerciseNameId: ex['name_id'] ?? ex['name'] ?? '',
      setNumber: 1,
      repsCompleted: 0,
      durationSeconds: dur,
      caloriesBurned: cal,
      completedAt: DateTime.now(),
    );
    setState(() {
      _history.add(rec);
      _totalCal += cal;
    });
  }

  // ─── Rep Mode ───────────────────────────────────────────────────────────
  void _confirmSet(int idx) {
    if (_setRows[idx].completed) return;
    HapticFeedback.mediumImpact();
    final ex = _exercises[_currentIndex];
    final cal = calculateCaloriesForReps(
      exerciseName: ex['name'] ?? '',
      repsCompleted: _setRows[idx].reps,
      weightKg: widget.userWeightKg,
    );
    final rec = ExerciseSetRecord(
      exerciseName: ex['name'] ?? '',
      exerciseNameId: ex['name_id'] ?? ex['name'] ?? '',
      setNumber: idx + 1,
      repsCompleted: _setRows[idx].reps,
      durationSeconds: 0,
      caloriesBurned: cal,
      completedAt: DateTime.now(),
    );
    setState(() {
      _setRows[idx].completed = true;
      _history.add(rec);
      _totalCal += cal;
      final next = _setRows.indexWhere((s) => !s.completed, idx + 1);
      if (next >= 0) _activeSet = next;
    });
    _speak('Set ${idx + 1} selesai!');

    if (_setRows.every((s) => s.completed)) {
      _speak('Semua set selesai!');
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted && _setRows.every((s) => s.completed)) {
          _loadExercise(_currentIndex + 1);
        }
      });
    }
  }

  void _addSet() => setState(() => _setRows
      .add(_SetRowData(reps: _setRows.isNotEmpty ? _setRows.last.reps : 12)));

  // ─── Navigation ─────────────────────────────────────────────────────────
  void _skipNext() {
    _exTimer?.cancel();
    _restTimer?.cancel();
    _loadExercise(_currentIndex + 1);
  }

  void _skipPrev() {
    if (_currentIndex > 0) {
      _exTimer?.cancel();
      _restTimer?.cancel();
      _loadExercise(_currentIndex - 1);
    }
  }

  // ─── Finish ─────────────────────────────────────────────────────────────
  void _finishWorkout() {
    setState(() {
      _isFinished = true;
      _isPlaying = false;
    });
    _exTimer?.cancel();
    _restTimer?.cancel();
    _elapsedTimer?.cancel();
    _speak('Latihan selesai! Anda luar biasa.');
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => WorkoutSummaryScreen(
        workoutData: {
          ...widget.workoutData,
          'caloriesBurned': _totalCal.round()
        },
        totalDurationSeconds: _elapsed,
        sessionHistory: _history,
        totalCalories: _totalCal,
      ),
    ));
  }

  void _confirmExit() {
    _exTimer?.cancel();
    _restTimer?.cancel();
    setState(() => _isPlaying = false);
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('⚠️ Akhiri Latihan?',
            style: TextStyle(
                color: ext?.warning ?? AppColors.warning,
                fontWeight: FontWeight.bold)),
        content: const Text('Progress tidak akan tersimpan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Lanjutkan',
                  style: TextStyle(color: theme.colorScheme.primary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child:
                const Text('Ya, Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _exTimer?.cancel();
    _restTimer?.cancel();
    _elapsedTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    if (_exercises.isEmpty || _isFinished) {
      return Scaffold(
        body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Latihan Selesai!',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: onSurface)),
          const SizedBox(height: 12),
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              child:
                  const Text('Kembali', style: TextStyle(color: Colors.white))),
        ])),
      );
    }

    if (_isResting) return _buildRest(theme, primary);

    final ex = _exercises[_currentIndex];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (d, _) {
        if (!d) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(theme, primary, onSurface),
              // GIF area — fixed height so it never overflows
              _buildGifArea(ex, primary, theme),
              // Exercise name + set badge in a single clipped row
              _buildExerciseHeader(ex, primary, onSurface, theme),
              // Main content — scrollable
              Expanded(
                child: _isRepMode
                    ? _buildRepTable(theme, primary, onSurface)
                    : _buildTimerControls(theme, primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Top Bar ─────────────────────────────────────────────────────────────
  Widget _buildTopBar(ThemeData theme, Color primary, Color onSurface) {
    final total = _exercises.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: onSurface, size: 22),
            onPressed: _confirmExit,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${_currentIndex + 1}/$total',
                        style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    const Spacer(),
                    // ⏱ Elapsed timer — always visible
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 13,
                              color: onSurface.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(_fmt(_elapsed),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: onSurface.withValues(alpha: 0.85))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 🔥 Calories
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 3),
                          Text('${_totalCal.toStringAsFixed(0)} kal',
                              style: const TextStyle(
                                  color: Color(0xFFFF6B35),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / total,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── GIF Area ─────────────────────────────────────────────────────────────
  Widget _buildGifArea(
      Map<String, dynamic> ex, Color primary, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 170,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Always white background so GIF illustrations blend properly
              Container(color: Colors.white),
              // GIF / emoji
              _buildGifContent(ex, primary, theme),
              // YouTube button overlay
              Positioned(
                bottom: 8,
                right: 8,
                child: _YoutubeBtn(exerciseName: ex['name'] ?? ''),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGifContent(
      Map<String, dynamic> ex, Color primary, ThemeData theme) {
    final emoji = (ex['emoji'] as String?) ?? '🏃';
    final exerciseName = (ex['name'] ?? '') as String;

    if (_gifLoading) {
      return Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(IkonMapper.dariEmoji(emoji), size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              color: primary,
              backgroundColor: primary.withValues(alpha: 0.1),
              minHeight: 3,
            ),
          ),
        ],
      ));
    }

    final url = _currentGifUrl;

    // 1. Local MP4 asset — auto-plays, muted, looped
    if (url != null && url.startsWith('asset:')) {
      return LocalVideoPlayer(
        key: ValueKey(url),
        assetPath: url.substring('asset:'.length),
        height: 170,
        fallbackBuilder: (_) => _buildEmojiPlaceholder(emoji, primary),
      );
    }

    // 2. Local GIF asset — animated GIF auto-plays
    if (url != null && url.startsWith('localGif:')) {
      return Image.asset(
        url.substring('localGif:'.length),
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _buildEmojiPlaceholder(emoji, primary),
      );
    }

    // 3. Network GIF from latihanfisik.com (prefix: 'networkGif:')
    if (url != null && url.startsWith('networkGif:')) {
      return Image.network(
        url.substring('networkGif:'.length),
        fit: BoxFit.contain,
        gaplessPlayback: true,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Center(child: Icon(IkonMapper.dariEmoji(emoji), size: 48, color: Theme.of(context).colorScheme.primary)),
        errorBuilder: (_, __, ___) => _buildEmojiPlaceholder(emoji, primary),
      );
    }

    // 4. Network GIF — auto-plays animated GIF
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Center(child: Icon(IkonMapper.dariEmoji(emoji), size: 48, color: Theme.of(context).colorScheme.primary)),
        errorBuilder: (_, __, ___) {
          final localGif = getLocalGifPath(exerciseName);
          if (localGif != null && !localGif.startsWith('networkGif:')) {
            return Image.asset(localGif,
                fit: BoxFit.contain, gaplessPlayback: true);
          }
          return _buildEmojiPlaceholder(emoji, primary);
        },
      );
    }

    return _buildEmojiPlaceholder(emoji, primary);
  }

  Widget _buildEmojiPlaceholder(String emoji, Color primary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(IkonMapper.dariEmoji(emoji), size: 60, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ─── Exercise header ──────────────────────────────────────────────────────
  Widget _buildExerciseHeader(Map<String, dynamic> ex, Color primary,
      Color onSurface, ThemeData theme) {
    final name = ex['name_id'] ?? ex['name'] ?? '';
    final completedSets =
        _isRepMode ? _setRows.where((s) => s.completed).length : 0;
    final totalSets = _isRepMode ? _setRows.length : 0;
    final phase = ex['phase'] as String?;

    Color? phaseColor;
    String? phaseText;
    if (phase == 'warmup') {
      phaseColor = const Color(0xFFF59E0B);
      phaseText = '🟡 Fase 1: Pemanasan';
    } else if (phase == 'cooldown') {
      phaseColor = const Color(0xFF10B981);
      phaseText = '🟢 Fase 3: Pendinginan';
    } else if (phase == 'main') {
      phaseColor = primary;
      phaseText = '🔵 Fase 2: Latihan Inti';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (phaseText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: phaseColor!.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  phaseText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: phaseColor,
                  ),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: onSurface),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              if (_isRepMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$completedSets / $totalSets set',
                      style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Rep Table ────────────────────────────────────────────────────────────
  Widget _buildRepTable(ThemeData theme, Color primary, Color onSurface) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                    width: 34,
                    child: Text('Set',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey))),
                Expanded(
                    child: Text('Sebelumnya',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey))),
                SizedBox(
                    width: 106,
                    child: Center(
                        child: Text('Reps',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey)))),
                SizedBox(width: 34),
              ],
            ),
          ),
          const Divider(height: 1),
          // Set rows
          for (int i = 0; i < _setRows.length; i++)
            _SetRowWidget(
              index: i,
              data: _setRows[i],
              isActive: i == _activeSet && !_setRows[i].completed,
              theme: theme,
              primary: primary,
              onRepsChanged: (v) => setState(() => _setRows[i].reps = v),
              onConfirm: () => _confirmSet(i),
            ),
          const SizedBox(height: 10),
          // + Add Set
          OutlinedButton(
            onPressed: _addSet,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: primary.withValues(alpha: 0.3)),
            ),
            child: Text('+ Tambah Set',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: primary)),
          ),
          const SizedBox(height: 10),
          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _currentIndex > 0 ? _skipPrev : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('‹ Sebelumnya',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _skipNext,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Berikutnya ›',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Timer Controls ───────────────────────────────────────────────────────
  Widget _buildTimerControls(ThemeData theme, Color primary) {
    final ex = _exercises[_currentIndex];
    final total = (ex['durationSeconds'] as int? ?? 30).toDouble();
    final progress =
        total > 0 ? (1 - _timeRemaining / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_fmt(_timeRemaining),
            style: TextStyle(
                fontSize: 68,
                fontWeight: FontWeight.w900,
                fontFamily: 'Courier',
                color: primary,
                letterSpacing: 4)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(primary),
              minHeight: 7,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded),
              color: _currentIndex > 0 ? primary : Colors.grey,
              iconSize: 44,
              onPressed: _currentIndex > 0 ? _skipPrev : null,
            ),
            const SizedBox(width: 16),
            FloatingActionButton(
              elevation: 3,
              backgroundColor: primary,
              onPressed: _pauseResume,
              child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded),
              color: primary,
              iconSize: 44,
              onPressed: _skipNext,
            ),
          ],
        ),
      ],
    );
  }

  // ─── Rest Screen ──────────────────────────────────────────────────────────
  Widget _buildRest(ThemeData theme, Color primary) {
    final nextName = _currentIndex < _exercises.length
        ? (_exercises[_currentIndex]['name_id'] ??
            _exercises[_currentIndex]['name'] ??
            '')
        : '';

    return Scaffold(
      backgroundColor: primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Text(_currentIndex == 0 ? 'BERSIAP' : 'ISTIRAHAT',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4)),
            const SizedBox(height: 6),
            Text(_fmt(_restSeconds),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 80,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Courier')),
            if (nextName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Selanjutnya: $nextName',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _skipRest,
              child: const Text('Lewati Istirahat',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            const Spacer(),
            // Session stats
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _RestStat(label: 'Sesi', value: _fmt(_elapsed)),
                  _RestStat(label: 'Set', value: '${_history.length}'),
                  _RestStat(
                      label: 'Kalori',
                      value: '${_totalCal.toStringAsFixed(0)} kal'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Set Row Widget ────────────────────────────────────────────────────────────
class _SetRowWidget extends StatefulWidget {
  final int index;
  final _SetRowData data;
  final bool isActive;
  final ThemeData theme;
  final Color primary;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback onConfirm;

  const _SetRowWidget({
    required this.index,
    required this.data,
    required this.isActive,
    required this.theme,
    required this.primary,
    required this.onRepsChanged,
    required this.onConfirm,
  });

  @override
  State<_SetRowWidget> createState() => _SetRowWidgetState();
}

class _SetRowWidgetState extends State<_SetRowWidget> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.data.reps}');
  }

  @override
  void didUpdateWidget(_SetRowWidget old) {
    super.didUpdateWidget(old);
    if (!widget.data.completed && _ctrl.text != '${widget.data.reps}') {
      _ctrl.text = '${widget.data.reps}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.data.completed;
    final active = widget.isActive;
    final bg = done
        ? const Color(0xFF34D399).withValues(alpha: 0.07)
        : active
            ? widget.primary.withValues(alpha: 0.05)
            : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(
              color: widget.theme.dividerColor.withValues(alpha: 0.08)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(
          children: [
            // Set number
            SizedBox(
              width: 34,
              child: Text('${widget.index + 1}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: done
                        ? const Color(0xFF34D399)
                        : active
                            ? widget.primary
                            : widget.theme.textTheme.bodyMedium?.color,
                  )),
            ),
            // Previous
            Expanded(
              child: Text('—',
                  style: TextStyle(
                      fontSize: 13,
                      color: widget.theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.4))),
            ),
            // Reps: − / field / +  (106px total)
            SizedBox(
              width: 106,
              child: done
                  ? Center(
                      child: Text('${widget.data.reps} reps',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF34D399))))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RepsBtn(
                          icon: Icons.remove,
                          onTap: () {
                            if (widget.data.reps > 1) {
                              widget.onRepsChanged(widget.data.reps - 1);
                            }
                          },
                          theme: widget.theme,
                        ),
                        SizedBox(
                          width: 36,
                          child: TextField(
                            controller: _ctrl,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: widget.theme.colorScheme.onSurface),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null && n > 0) widget.onRepsChanged(n);
                            },
                          ),
                        ),
                        _RepsBtn(
                          icon: Icons.add,
                          onTap: () =>
                              widget.onRepsChanged(widget.data.reps + 1),
                          theme: widget.theme,
                        ),
                      ],
                    ),
            ),
            // Checkmark
            GestureDetector(
              onTap: done ? null : widget.onConfirm,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? const Color(0xFF34D399)
                      : widget.primary.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.check,
                    size: 17,
                    color: done
                        ? Colors.white
                        : widget.primary.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepsBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ThemeData theme;

  const _RepsBtn(
      {required this.icon, required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 15),
      ),
    );
  }
}

// ─── YouTube external search button ──────────────────────────────────────────
class _YoutubeBtn extends StatefulWidget {
  final String exerciseName;
  const _YoutubeBtn({required this.exerciseName});

  @override
  State<_YoutubeBtn> createState() => _YoutubeBtnState();
}

class _YoutubeBtnState extends State<_YoutubeBtn> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        setState(() => _loading = true);
        await openYouTubeSearch(widget.exerciseName);
        if (mounted) setState(() => _loading = false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: _loading
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_fill, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text('Tonton Tutorial',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}

class _RestStat extends StatelessWidget {
  final String label;
  final String value;
  const _RestStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }
}
