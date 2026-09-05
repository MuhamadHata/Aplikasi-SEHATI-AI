import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../inti/layanan/cache_gif_latihan.dart';
import '../inti/layanan/layanan_media_latihan.dart';
import 'pemutar_video_lokal.dart';

// YouTube search fallback per exercise
const Map<String, String> _kYouTubeQueries = {
  'push up': 'cara melakukan push up yang benar',
  'incline push up': 'cara melakukan incline push up',
  'dumbbell bench press': 'cara melakukan dumbbell bench press',
  'dumbbell fly': 'cara melakukan dumbbell fly dada',
  'pull up': 'cara melakukan pull up yang benar',
  'dumbbell row': 'cara melakukan dumbbell row punggung',
  'superman': 'cara melakukan superman exercise punggung',
  'deadlift': 'cara melakukan deadlift',
  'shoulder press': 'cara melakukan shoulder press yang benar',
  'lateral raise': 'cara melakukan lateral raise bahu',
  'front raise': 'cara melakukan front raise bahu',
  'bicep curl': 'cara melakukan bicep curl',
  'hammer curl': 'cara melakukan hammer curl',
  'tricep dip': 'cara melakukan tricep dip',
  'triceps pushdown': 'cara melakukan triceps pushdown',
  'crunch': 'cara melakukan crunch perut yang benar',
  'bicycle crunch': 'cara melakukan bicycle crunch abs',
  'plank': 'cara melakukan plank yang benar',
  'leg raise': 'cara melakukan leg raise abs',
  'mountain climber': 'cara melakukan mountain climber exercise',
  'squat': 'cara melakukan squat yang benar',
  'lunge': 'cara melakukan lunge kaki yang benar',
  'leg press': 'cara melakukan leg press mesin',
  'calf raise': 'cara melakukan calf raise betis',
  'wall sit': 'cara melakukan wall sit isometrik',
  'glute bridge': 'cara melakukan glute bridge pantat',
  'hip thrust': 'cara melakukan hip thrust glutes',
  'donkey kick': 'cara melakukan donkey kick pantat',
  'jumping jack': 'cara melakukan jumping jack cardio',
  'burpee': 'cara melakukan burpee cardio',
  'high knees': 'cara melakukan high knees cardio',
  'jump rope': 'cara melakukan skipping tali',
  'box jump': 'cara melakukan box jump',
};

String _youtubeSearchUrl(String exerciseName) {
  final lower = exerciseName.toLowerCase().trim();
  String q = _kYouTubeQueries[lower] ?? '';
  if (q.isEmpty) {
    for (final k in _kYouTubeQueries.keys) {
      if (lower.contains(k) || k.contains(lower)) {
        q = _kYouTubeQueries[k]!;
        break;
      }
    }
  }
  if (q.isEmpty) q = 'cara melakukan $lower olahraga';
  return 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(q)}';
}

Future<void> openYouTubeSearch(String exerciseName) async {
  final uri = Uri.parse(_youtubeSearchUrl(exerciseName));
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// ─── ExerciseYouTubePlayer ────────────────────────────────────────────────────
// Loads exercise GIF from:
//   1. localAssetPath (downloaded file in assets/)
//   2. mediaUrl       (passed from AI enrichment)
//   3. ExerciseDB API (fetched via ExerciseGifCache, uses RapidAPI key)
//   4. Animated emoji placeholder
class ExerciseYouTubePlayer extends StatefulWidget {
  final String exerciseName;
  final double height;
  final String? mediaUrl;
  final String? localAssetPath;
  final String emoji;
  // backward compat
  final String? videoId;
  final bool isCover;

  const ExerciseYouTubePlayer({
    super.key,
    required this.exerciseName,
    this.height = 220,
    this.mediaUrl,
    this.localAssetPath,
    this.emoji = '🏃',
    this.videoId,
    this.isCover = false,
  });

  @override
  State<ExerciseYouTubePlayer> createState() => _ExerciseYouTubePlayerState();
}

class _ExerciseYouTubePlayerState extends State<ExerciseYouTubePlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _isOpeningYT = false;
  String? _resolvedUrl;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_pulseCtrl);

    _resolveUrl();
  }

  Future<void> _resolveUrl() async {
    // 1. Explicit local asset from props
    if (widget.localAssetPath != null && widget.localAssetPath!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _resolvedUrl = widget.localAssetPath;
          _resolved = true;
        });
      }
      return;
    }

    // 2. Explicit mediaUrl from AI payload
    if (widget.mediaUrl != null && widget.mediaUrl!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _resolvedUrl = widget.mediaUrl;
          _resolved = true;
        });
      }
      return;
    }

    // 3. Local MP4 video asset mapping
    final localVideo = getLocalVideoPath(widget.exerciseName);
    if (localVideo != null && !widget.isCover) {
      if (mounted) {
        setState(() {
          _resolvedUrl = 'asset:$localVideo';
          _resolved = true;
        });
      }
      return;
    }

    // 4. Local Image (Cover) if requested
    if (widget.isCover) {
      final localImage = getLocalImagePath(widget.exerciseName);
      if (localImage != null) {
        if (mounted) {
          setState(() {
            _resolvedUrl = 'localImage:$localImage';
            _resolved = true;
          });
        }
        return;
      }
    }

    // 5. Local GIF asset mapping
    final localGif = getLocalGifPath(widget.exerciseName);
    if (localGif != null) {
      if (mounted) {
        setState(() {
          _resolvedUrl = 'localGif:$localGif';
          _resolved = true;
        });
      }
      return;
    }

    // 5. Local DB base URL
    final localDbUrl = ExerciseMediaService.localGifUrl(widget.exerciseName);
    if (localDbUrl != null &&
        localDbUrl.isNotEmpty &&
        !localDbUrl.contains('/search')) {
      if (mounted) {
        setState(() {
          _resolvedUrl = localDbUrl;
          _resolved = true;
        });
      }
      return;
    }

    // 6. ExerciseDB API via cache
    final apiUrl = await ExerciseGifCache.getGifUrl(widget.exerciseName);
    if (mounted) {
      setState(() {
        _resolvedUrl = apiUrl;
        _resolved = true;
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _openYouTube() async {
    setState(() => _isOpeningYT = true);
    await openYouTubeSearch(widget.exerciseName);
    if (mounted) setState(() => _isOpeningYT = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: widget.height == double.infinity ? null : widget.height,
        constraints: widget.height == double.infinity
            ? const BoxConstraints(minHeight: 160, maxHeight: 280)
            : null,
        // Always white background so illustration GIFs blend in dark mode too
        color: widget.isCover
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Colors.white,
        child: Stack(
          children: [
            Positioned.fill(child: _buildMedia(theme, primary)),
            Positioned(
              bottom: 8,
              right: 8,
              child:
                  _YouTubeButton(isLoading: _isOpeningYT, onTap: _openYouTube),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(ThemeData theme, Color primary) {
    // Local asset
    if (widget.localAssetPath != null && widget.localAssetPath!.isNotEmpty) {
      return Image.asset(
        widget.localAssetPath!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            _buildNetworkOrPlaceholder(theme, primary),
      );
    }
    return _buildNetworkOrPlaceholder(theme, primary);
  }

  Widget _buildNetworkOrPlaceholder(ThemeData theme, Color primary) {
    if (!_resolved) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                color: primary,
                backgroundColor: primary.withValues(alpha: 0.1),
                minHeight: 3,
              ),
            ),
          ],
        ),
      );
    }

    final url = _resolvedUrl;
    if (url != null && url.isNotEmpty) {
      // Local MP4
      if (url.startsWith('asset:')) {
        return LocalVideoPlayer(
          key: ValueKey(url),
          assetPath: url.substring('asset:'.length),
          height: widget.height,
          fallbackBuilder: (_) => _buildPlaceholder(theme, primary),
        );
      }

      // Local GIF
      if (url.startsWith('localGif:')) {
        return Image.asset(
          url.substring('localGif:'.length),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _buildPlaceholder(theme, primary),
        );
      }

      // Local Image (Cover)
      if (url.startsWith('localImage:')) {
        return Image.asset(
          url.substring('localImage:'.length),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(theme, primary),
        );
      }

      // Network GIF from latihanfisik.com (prefix 'networkGif:')
      if (url.startsWith('networkGif:')) {
        return Image.network(
          url.substring('networkGif:'.length),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Center(
                  child:
                      Text(widget.emoji, style: const TextStyle(fontSize: 48))),
          errorBuilder: (_, __, ___) => _buildPlaceholder(theme, primary),
        );
      }

      // Direct local asset
      if (url.startsWith('assets/')) {
        return Image.asset(url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildPlaceholder(theme, primary));
      }

      // Network URL
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        fadeInDuration: const Duration(milliseconds: 300),
        placeholder: (_, __) => Center(
            child: Text(widget.emoji, style: const TextStyle(fontSize: 48))),
        errorWidget: (_, __, ___) => _buildPlaceholder(theme, primary),
      );
    }

    return _buildPlaceholder(theme, primary);
  }

  Widget _buildPlaceholder(ThemeData theme, Color primary) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) =>
          Transform.scale(scale: _pulseAnim.value, child: child),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  primary.withValues(alpha: 0.18),
                  primary.withValues(alpha: 0.0),
                ]),
              ),
              child: Center(
                  child:
                      Text(widget.emoji, style: const TextStyle(fontSize: 54))),
            ),
            const SizedBox(height: 8),
            Text(
              widget.exerciseName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── YouTube Button ───────────────────────────────────────────────────────────
class _YouTubeButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _YouTubeButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.red.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: isLoading
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_fill, color: Colors.white, size: 13),
                  SizedBox(width: 4),
                  Text('Tonton Tutorial',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}

// ─── Compact Thumbnail ────────────────────────────────────────────────────────
class ExerciseThumbnail extends StatefulWidget {
  final String exerciseName;
  final String? mediaUrl;
  final String emoji;
  final double size;

  const ExerciseThumbnail({
    super.key,
    required this.exerciseName,
    this.mediaUrl,
    this.emoji = '🏃',
    this.size = 70,
  });

  @override
  State<ExerciseThumbnail> createState() => _ExerciseThumbnailState();
}

class _ExerciseThumbnailState extends State<ExerciseThumbnail> {
  String? _url;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    // 1. Explicit mediaUrl
    if (widget.mediaUrl != null && widget.mediaUrl!.isNotEmpty) {
      if (mounted) setState(() => _url = widget.mediaUrl);
      return;
    }

    // 2. Local GIF asset
    final localGif = getLocalGifPath(widget.exerciseName);
    if (localGif != null) {
      if (mounted) setState(() => _url = 'localGif:$localGif');
      return;
    }

    // 3. Local Video asset -> use placeholder for now in thumbnail, or a thumbnail image?
    // For thumbnails, we can't easily show a full video. Let's show as emoji.
    final localVideo = getLocalVideoPath(widget.exerciseName);
    if (localVideo != null) {
      // we'll just show Emoji for now
      if (mounted) setState(() => _url = 'localVideo:$localVideo');
      return;
    }

    // 4. Exercise DB local
    final localDb = ExerciseMediaService.localGifUrl(widget.exerciseName);
    if (localDb != null && localDb.isNotEmpty && !localDb.contains('/search')) {
      if (mounted) setState(() => _url = localDb);
      return;
    }

    // 5. ExerciseDB API via cache
    final url = await ExerciseGifCache.getGifUrl(widget.exerciseName);
    if (mounted) setState(() => _url = url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;
    if (_url != null && _url!.startsWith('localGif:')) {
      content = Image.asset(
        _url!.substring('localGif:'.length),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildEmojiFallback(),
      );
    } else if (_url != null && _url!.startsWith('localVideo:')) {
      final videoPath = _url!.substring('localVideo:'.length);
      content = LocalVideoPlayer(
        key: ValueKey(videoPath),
        assetPath: videoPath,
        height: widget.size,
        autoPlay: false,
        fallbackBuilder: (_) => _buildEmojiFallback(),
      );
    } else if (_url != null && _url!.isNotEmpty) {
      content = CachedNetworkImage(
        imageUrl: _url!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildEmojiFallback(),
        errorWidget: (_, __, ___) => _buildEmojiFallback(),
      );
    } else {
      content = _buildEmojiFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: widget.size,
        height: widget.size,
        color: theme.colorScheme.surfaceContainerHighest,
        child: content,
      ),
    );
  }

  Widget _buildEmojiFallback() {
    return Image.asset(
      'assets/exercises/gifs/default.gif',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.fitness_center, color: Colors.grey, size: 30),
      ),
    );
  }
}
