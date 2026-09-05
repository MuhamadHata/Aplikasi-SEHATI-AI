import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../inti/layanan/layanan_referensi.dart';
import '../inti/model/referensi.dart';
import '../inti/tema/design_tokens.dart';

class ReferencesScreen extends StatelessWidget {
  final String title;
  final List<String> tags;
  final List<String> codes;

  const ReferencesScreen({
    super.key,
    this.title = 'Sumber & Kutipan',
    this.tags = const [],
    this.codes = const [],
  });

  String? _yearOf(String? published) {
    if (published == null || published.trim().isEmpty) return null;
    final dt = DateTime.tryParse(published.trim());
    if (dt != null) return dt.year.toString();
    final m = RegExp(r'\b(19\d{2}|20\d{2})\b').firstMatch(published);
    return m?.group(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
      ),
      body: FutureBuilder<List<ReferenceItem>>(
        future: codes.isNotEmpty
            ? ReferenceService.instance.getByCodes(codes)
            : ReferenceService.instance.getByTags(tags),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return Center(
              child: Text(
                'Tidak ada sumber untuk kategori ini.',
                style: TextStyle(color: theme.hintColor),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final it = items[i];
              final y = _yearOf(it.published);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${it.publisher}${y != null ? ' ($y)' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Text(
                        '"${it.quote}"',
                        style: TextStyle(
                          height: 1.4,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              it.code,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final uri = Uri.tryParse(it.url);
                            if (uri == null) return;
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Buka sumber'),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
