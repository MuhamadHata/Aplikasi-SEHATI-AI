import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

const Map<String, String> kLocalExerciseVideos = {};

String? getLocalVideoPath(String exerciseName) {
  final key = exerciseName.toLowerCase().trim();
  if (kLocalExerciseVideos.containsKey(key)) return kLocalExerciseVideos[key];
  for (final k in kLocalExerciseVideos.keys) {
    if (key.contains(k) || k.contains(key)) return kLocalExerciseVideos[k];
  }
  return null;
}

const Map<String, String> kLocalExerciseGifs = {
  'crunch': 'assets/exercises/gifs/crunch.gif',
  'jumping jack': 'assets/exercises/gifs/jumping jack.gif',
  'plank': 'assets/exercises/gifs/plank.gif',
  'push up': 'assets/exercises/gifs/push_up.gif',
  'push_up': 'assets/exercises/gifs/push_up.gif',
  'pushup': 'assets/exercises/gifs/push_up.gif',
  'squat': 'assets/exercises/gifs/squat.gif',
  'stretch': 'assets/exercises/gifs/stretch.gif',
  'default': 'assets/exercises/gifs/default.gif',
};

/// Map of exercise/category name (lowercase) → local JPG/PNG asset path.
const Map<String, String> kLocalExerciseImages = {
  // Specific exercise covers
  'crunch': 'assets/exercises/images/crunch.jpg',
  'plank': 'assets/exercises/images/plank.jpg',
  'push up': 'assets/exercises/images/push_up.jpg',
  'push_up': 'assets/exercises/images/push_up.jpg',
  'pushup': 'assets/exercises/images/push_up.jpg',
  'squat': 'assets/exercises/images/squat.jpg',
  'stretch': 'assets/exercises/images/stretch.jpg',
  'jump': 'assets/exercises/images/jump.jpg',
  'jumping jack': 'assets/exercises/images/jump.jpg',

  // Workout category covers (from AI-generated images)
  'kardio': 'assets/exercises/images/cover_kardio.jpg',
  'cardio': 'assets/exercises/images/cover_kardio.jpg',
  'hiit': 'assets/exercises/images/cover_hiit.jpg',
  'kekuatan': 'assets/exercises/images/cover_kekuatan.jpg',
  'kekuatan otot': 'assets/exercises/images/cover_kekuatan.jpg',
  'strength': 'assets/exercises/images/cover_kekuatan.jpg',
  'yoga': 'assets/exercises/images/cover_yoga.jpg',
  'fleksibilitas': 'assets/exercises/images/cover_yoga.jpg',
  'flexibility': 'assets/exercises/images/cover_yoga.jpg',
  'kalistenik': 'assets/exercises/images/cover_kalistenik.jpg',
  'calisthenics': 'assets/exercises/images/cover_kalistenik.jpg',
  'isometrik': 'assets/exercises/images/cover_isometrik.jpg',
  'isometric': 'assets/exercises/images/cover_isometrik.jpg',
  'pliometrik': 'assets/exercises/images/cover_pliometrik.jpg',
  'plyometric': 'assets/exercises/images/cover_pliometrik.jpg',

  'default': 'assets/exercises/images/default.jpg',
};

/// Returns the local JPG asset path for the given exercise/category, or default.jpg if not available.
String? getLocalImagePath(String exerciseName) {
  final cleanName = exerciseName.toLowerCase().trim();
  // Exact match first
  if (kLocalExerciseImages.containsKey(cleanName)) {
    return kLocalExerciseImages[cleanName];
  }
  // Partial match (e.g., "Fokus Kardio" → "kardio")
  for (final k in kLocalExerciseImages.keys) {
    if (k == 'default') continue;
    if (cleanName.contains(k) || k.contains(cleanName)) {
      return kLocalExerciseImages[k];
    }
  }
  return kLocalExerciseImages['default'];
}

/// Map of exercise name (lowercase) → network GIF URLs from latihanfisik.com.
/// These are used as fallback when no local GIF asset is available.
const Map<String, String> kNetworkExerciseGifs = {
  'mountain climber':
      'https://latihanfisik.com/wp-content/uploads/2024/09/mountain-climber-animasi.gif',
  'burpee':
      'https://latihanfisik.com/wp-content/uploads/2024/09/burpee-animasi.gif',
  'high knee':
      'https://latihanfisik.com/wp-content/uploads/2024/10/animasi-high-knee.gif',
  'high knees':
      'https://latihanfisik.com/wp-content/uploads/2024/10/animasi-high-knee.gif',
  'bicycle crunch':
      'https://latihanfisik.com/wp-content/uploads/2024/09/bicycle-crunch-animasi.gif',
  'flutter kick':
      'https://latihanfisik.com/wp-content/uploads/2024/09/flutter-kick-animasi.gif',
  'flutter kicks':
      'https://latihanfisik.com/wp-content/uploads/2024/09/flutter-kick-animasi.gif',
  'jumping lunge':
      'https://latihanfisik.com/wp-content/uploads/2024/09/jumping-lunge-animasi.gif',
  'butt kicks':
      'https://latihanfisik.com/wp-content/uploads/2024/12/animasi-butt-kicks.gif',
  'butt kick':
      'https://latihanfisik.com/wp-content/uploads/2024/12/animasi-butt-kicks.gif',
  'lari':
      'https://latihanfisik.com/wp-content/uploads/2024/08/lari-animasi.gif',
  'run': 'https://latihanfisik.com/wp-content/uploads/2024/08/lari-animasi.gif',
  'running':
      'https://latihanfisik.com/wp-content/uploads/2024/08/lari-animasi.gif',
  'jalan kaki':
      'https://latihanfisik.com/wp-content/uploads/2024/08/jalan-kaki-animasi.gif',
  'walk':
      'https://latihanfisik.com/wp-content/uploads/2024/08/jalan-kaki-animasi.gif',
  'walking':
      'https://latihanfisik.com/wp-content/uploads/2024/08/jalan-kaki-animasi.gif',
  'dips':
      'https://latihanfisik.com/wp-content/uploads/2025/02/animasi-dips.gif',
  'glute bridge':
      'https://latihanfisik.com/wp-content/uploads/2024/08/glute-bridge-animasi.gif',
  'pull up':
      'https://latihanfisik.com/wp-content/uploads/2024/08/pullup-animasi.gif',
  'pull-up':
      'https://latihanfisik.com/wp-content/uploads/2024/08/pullup-animasi.gif',
  'pullup':
      'https://latihanfisik.com/wp-content/uploads/2024/08/pullup-animasi.gif',
  'squat jump':
      'https://latihanfisik.com/wp-content/uploads/2024/09/squat-jump-animasi.gif',
  'leg raise':
      'https://latihanfisik.com/wp-content/uploads/2024/12/animasi-leg-raise.gif',
  'deadlift':
      'https://latihanfisik.com/wp-content/uploads/2025/02/animasi-deadlift.gif',
  'side bridge':
      'https://latihanfisik.com/wp-content/uploads/2025/08/side-bridge-animasi.gif',
  'plank side':
      'https://latihanfisik.com/wp-content/uploads/2025/08/side-bridge-animasi.gif',
};

/// Returns the local GIF asset path for the given exercise, or null.
String? getLocalGifPath(String exerciseName) {
  final key = exerciseName.toLowerCase().trim();
  // Check local assets first
  if (kLocalExerciseGifs.containsKey(key)) return kLocalExerciseGifs[key];
  for (final k in kLocalExerciseGifs.keys) {
    if (k == 'default') continue;
    if (key.contains(k) || k.contains(key)) return kLocalExerciseGifs[k];
  }
  // Check network GIF URLs (returned with 'networkGif:' prefix)
  if (kNetworkExerciseGifs.containsKey(key)) {
    return 'networkGif:${kNetworkExerciseGifs[key]}';
  }
  for (final k in kNetworkExerciseGifs.keys) {
    if (key.contains(k) || k.contains(key)) {
      return 'networkGif:${kNetworkExerciseGifs[k]}';
    }
  }
  return kLocalExerciseGifs['default'];
}

/// Returns just the network GIF URL for an exercise, or null.
String? getNetworkGifUrl(String exerciseName) {
  final key = exerciseName.toLowerCase().trim();
  if (kNetworkExerciseGifs.containsKey(key)) return kNetworkExerciseGifs[key];
  for (final k in kNetworkExerciseGifs.keys) {
    if (key.contains(k) || k.contains(key)) return kNetworkExerciseGifs[k];
  }
  return null;
}

// ─── LocalVideoPlayer ─────────────────────────────────────────────────────────
/// Plays a local asset MP4, looping, auto-play on init.
class LocalVideoPlayer extends StatefulWidget {
  final String assetPath;
  final double height;
  final bool autoPlay;
  final Widget Function(BuildContext) fallbackBuilder;

  const LocalVideoPlayer({
    super.key,
    required this.assetPath,
    this.height = 170,
    this.autoPlay = true,
    required this.fallbackBuilder,
  });

  @override
  State<LocalVideoPlayer> createState() => _LocalVideoPlayerState();
}

class _LocalVideoPlayerState extends State<LocalVideoPlayer> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      // Copy asset to temp file to fix Android ExoPlayer space-in-filename bug
      final byteData = await rootBundle.load(widget.assetPath);
      final filename = widget.assetPath.split('/').last.replaceAll(' ', '_');
      final dir = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/$filename');

      // Write only if it doesn't exist to save time on subsequent loads
      if (!await tempFile.exists()) {
        await tempFile.writeAsBytes(byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      }

      final ctrl = VideoPlayerController.file(tempFile);
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      if (widget.autoPlay) {
        ctrl.setLooping(true);
        ctrl.play();
      }
      setState(() {
        _ctrl = ctrl;
        _initialized = true;
      });
    } catch (e) {
      debugPrint('[LocalVideoPlayer] init failed: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallbackBuilder(context);
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    return AspectRatio(
      aspectRatio: _ctrl!.value.aspectRatio,
      child: VideoPlayer(_ctrl!),
    );
  }
}
