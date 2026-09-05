import 'package:flutter/material.dart';
import '../inti/tema/design_tokens.dart';

/// Widget chip kutipan sumber tunggal
class CitationChip extends StatelessWidget {
  final String source;
  final Color? color;

  const CitationChip({super.key, required this.source, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded, size: 10, color: c),
          const SizedBox(width: 4),
          Text(
            source,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: c,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget baris kutipan multi-sumber (Wrap chips)
class CitationWidget extends StatelessWidget {
  final List<String> sources;
  final EdgeInsets? padding;

  const CitationWidget({
    super.key,
    required this.sources,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: sources.map((s) => CitationChip(source: s)).toList(),
      ),
    );
  }
}

/// Widget footer kutipan dengan label "Sumber:" yang bisa dijadikan ExpansionTile
class CitationFooter extends StatelessWidget {
  final List<String> sources;
  final String? note;

  const CitationFooter({
    super.key,
    required this.sources,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (sources.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.library_books_rounded,
                  size: 12, color: theme.hintColor),
              const SizedBox(width: 5),
              Text(
                'Sumber referensi:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: sources.map((s) => CitationChip(source: s)).toList(),
          ),
          if (note != null) ...[
            const SizedBox(height: 5),
            Text(
              note!,
              style: TextStyle(
                fontSize: 10,
                color: theme.hintColor.withValues(alpha: 0.75),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget kartu tips dengan kutipan & warna gradien
class HealthTipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String tip;
  final List<String> citations;
  final List<Color> gradientColors;

  const HealthTipCard({
    super.key,
    required this.icon,
    required this.title,
    required this.tip,
    required this.citations,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: gradientColors.first.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 26, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tip,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 10),
          CitationWidget(sources: citations),
        ],
      ),
    );
  }
}

/// Penanda sumber kecil inline dalam teks rekomendasi
class InlineCitation extends StatelessWidget {
  final String text;
  const InlineCitation(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary.withValues(alpha: 0.85),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
