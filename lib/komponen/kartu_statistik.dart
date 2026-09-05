import 'package:flutter/material.dart';
import '../inti/tema/design_tokens.dart';

/// Statistik card — mengikuti spesifikasi komponen:
/// - Corner radius 14dp, border 1dp, internal padding 16dp
/// - Icon container 34x34 (di dalam padding)
/// - Value: H1 (24sp Bold) + unit (Caption 12sp)
/// - Label: Caption 12sp Medium
/// - Margin horizontal 4dp antar kartu dalam grid
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = gradientColors.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(ComponentSpec.cardRadius),
            border: Border.all(
              color: Theme.of(context)
                  .dividerColor
                  .withValues(alpha: isDark ? 0.15 : 0.08),
              width: 1,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ComponentSpec.cardRadius),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Body ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ComponentSpec.cardPadding,
                    ComponentSpec.cardPadding - 3,
                    ComponentSpec.cardPadding,
                    ComponentSpec.cardPadding - 5,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon container
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              gradientColors.first.withValues(alpha: 0.18),
                              gradientColors.last.withValues(alpha: 0.10),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(ComponentSpec.cardRadius - 4),
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            size: 17,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTokens.small),

                      // Value + unit (Heading 1 + Caption)
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: value,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontWeight: AppTypography.h1Weight,
                                    height: 1.0,
                                  ),
                            ),
                            TextSpan(
                              text: ' $unit',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Label (Caption 12sp Medium)
                      Text(
                        label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: AppTypography.captionWeight,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // ── Accent bar ─────────────────────────────
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
