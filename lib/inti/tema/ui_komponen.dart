import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// ─────────────────────────────────────────────────────────────────────────────
///  SKELETON LOADER — placeholder yang bentuk & radius persis mirip komponen asli
///  Shimmer animasi abu-abu (#E5E7EB → #F3F4F6) dengan durasi 1500ms
/// ─────────────────────────────────────────────────────────────────────────────

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool pulse;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = ComponentSpec.skeletonRadius,
    this.pulse = true,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: ComponentSpec.skeletonShimmerMs),
    );
    _shimmer = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    if (widget.pulse) {
      _controller.repeat();
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.skeletonBase.withValues(alpha: 0.5 + (0.5 * _shimmer.value)),
            borderRadius:
                BorderRadius.circular(widget.borderRadius),
          ),
          child: CustomPaint(
            painter: _ShimmerPainter(
              progress: _shimmer.value,
              colorBase: AppColors.skeletonBase,
              colorHighlight: AppColors.skeletonHighlight,
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  final Color colorBase;
  final Color colorHighlight;

  _ShimmerPainter({
    required this.progress,
    required this.colorBase,
    required this.colorHighlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shimmerWidth = size.width * 0.6;
    final shimmerX = (size.width - shimmerWidth) * progress;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          colorBase.withValues(alpha: 0.3),
          colorHighlight,
          colorBase.withValues(alpha: 0.3),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(shimmerX, 0, shimmerWidth, size.height));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(8),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
///  SKELETON TEXT — placeholder teks dengan tinggi sesuai typography scale
/// ─────────────────────────────────────────────────────────────────────────────

class SkeletonText extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonText({
    super.key,
    required this.width,
    this.height = 12,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
///  SKELETON CARD — placeholder kartu lengkap dengan icon + value + label
/// ─────────────────────────────────────────────────────────────────────────────

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(ComponentSpec.cardRadius),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ComponentSpec.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon placeholder
            SkeletonLoader(
              width: 34,
              height: 34,
              borderRadius: ComponentSpec.cardRadius - 4,
            ),
            const SizedBox(height: AppTokens.small),
            // Value placeholder (lebih panjang)
            SkeletonText(
              width: double.infinity,
              height: 20,
              borderRadius: 4,
            ),
            const SizedBox(height: 4),
            // Label placeholder (lebih pendek)
            SkeletonText(
              width: 80,
              height: 12,
              borderRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
///  EMPTY STATE — ilustrasi + judul + deskripsi + tombol aksi
///  Spesifikasi: ilustrasi maks 120x120dp, Heading 2, Body 2, Primary Button
/// ─────────────────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ilustrasi (maks 120x120dp)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: AppTokens.large),
            // Judul Heading 2 (20sp Semi-Bold)
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: AppTypography.h2Weight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.small),
            // Deskripsi Body 2 (13sp Regular)
            Text(
              description,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTokens.large),
            // Tombol Primary
            if (onButtonPressed != null)
              FilledButton(
                onPressed: onButtonPressed,
                child: Text(buttonLabel),
              ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
///  ERROR STATE — pesan error + tombol "Coba Lagi"
/// ─────────────────────────────────────────────────────────────────────────────

class ErrorState extends StatelessWidget {
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    required this.message,
    this.retryLabel = 'Coba Lagi',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppTokens.medium),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
                fontWeight: AppTypography.body2Weight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.large),
            if (onRetry != null)
              FilledButton(
                onPressed: onRetry,
                child: Text(retryLabel!),
              ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
///  DIVIDER STANDARD — garis pemisah 1dp, warna #E5E7EB, inset kiri 16dp
/// ─────────────────────────────────────────────────────────────────────────────

class StandardDivider extends StatelessWidget {
  final double? indent;

  const StandardDivider({super.key, this.indent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Divider(
      color: theme.dividerColor,
      thickness: ComponentSpec.dividerThick,
      indent: indent ?? ComponentSpec.dividerInset,
      endIndent: 0,
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
///  BADGE DOT — titik notifikasi 8x8dp
/// ─────────────────────────────────────────────────────────────────────────────

class BadgeDot extends StatelessWidget {
  final bool active;
  final double offset;

  const BadgeDot({
    super.key,
    required this.active,
    this.offset = ComponentSpec.badgeOffset,
  });

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();

    return Positioned(
      top: -offset,
      right: -offset,
      child: Container(
        width: ComponentSpec.badgeDotSize,
        height: ComponentSpec.badgeDotSize,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
///  BADGE NUMBER — badge angka 16-20dp height, Caption Bold
/// ─────────────────────────────────────────────────────────────────────────────

class BadgeNumber extends StatelessWidget {
  final int count;
  final double offset;

  const BadgeNumber({
    super.key,
    required this.count,
    this.offset = ComponentSpec.badgeOffset,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final displayCount = count > 99 ? '99+' : count.toString();

    return Positioned(
      top: -offset,
      right: -offset,
      child: Container(
        height: ComponentSpec.badgeNumberH,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppTokens.radiusXs),
        ),
        constraints: const BoxConstraints(
          minWidth: 18,
          maxWidth: 32,
        ),
        child: Center(
          child: Text(
            displayCount,
            style: const TextStyle(
              fontSize: AppTypography.captionSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
///  5-STATE WRAPPER — bungkus widget dengan 5 kondisi standar
///  [Default] → [Loading] → [Empty] atau [Error]
/// ─────────────────────────────────────────────────────────────────────────────

class UiStateWrapper<T> extends StatelessWidget {
  final T? data;
  final bool isLoading;
  final bool isEmpty;
  final String? errorMessage;
  final Widget Function(BuildContext, T) builder;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final Widget? loadingWidget;

  const UiStateWrapper({
    super.key,
    required this.data,
    required this.isLoading,
    required this.isEmpty,
    this.errorMessage,
    required this.builder,
    this.emptyWidget,
    this.errorWidget,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ??
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          );
    }

    if (errorMessage != null) {
      return errorWidget ??
          ErrorState(
            message: errorMessage!,
            onRetry: () {},
          );
    }

    if (data == null || isEmpty || (data is List && (data as List).isEmpty)) {
      return emptyWidget ?? const SizedBox.shrink();
    }

    return builder(context, data as T);
  }
}
