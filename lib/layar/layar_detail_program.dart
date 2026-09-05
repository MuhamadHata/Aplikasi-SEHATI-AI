import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../penyedia/penyedia_aktivitas.dart';
import '../../inti/tema/design_tokens.dart';
import 'layar_referensi.dart';

class ProgramDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final String type; // 'diet' or 'event'

  const ProgramDetailScreen(
      {super.key, required this.data, required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header Cover
          SliverAppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            expandedHeight: 250,
            pinned: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios,
                  color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: type == 'diet'
                        ? [
                            (ext?.success ?? Colors.green)
                                .withValues(alpha: 0.2),
                            theme.scaffoldBackgroundColor
                          ]
                        : [
                            (ext?.info ?? Colors.blue).withValues(alpha: 0.2),
                            theme.scaffoldBackgroundColor
                          ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Text(
                    data['emoji'] ?? '✨',
                    style: const TextStyle(fontSize: 103),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges (if any)
                  if (data['badge'] != null &&
                      data['badge'].toString().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            (data['badgeColor'] as Color? ?? AppColors.primary)
                                .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        data['badge'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: (data['badgeColor'] as Color? ??
                              theme.colorScheme.primary),
                        ),
                      ),
                    ),

                  // Title
                  Text(
                    data['name'] ?? data['title'] ?? 'Program',
                    style: TextStyle(
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Key Stats Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        if (type == 'diet') ...[
                          _buildStatItem(
                              Icons.local_fire_department,
                              'Target',
                              '${data['cal']} kkal/hari',
                              ext?.warning ?? Colors.orange,
                              theme),
                          const SizedBox(width: 24),
                          _buildStatItem(Icons.restaurant, 'Tipe', 'Pola Makan',
                              theme.colorScheme.primary, theme),
                        ] else ...[
                          _buildStatItem(
                              Icons.calendar_today,
                              'Tanggal',
                              data['date'] ?? '-',
                              ext?.info ?? Colors.blue,
                              theme),
                          const SizedBox(width: 24),
                          _buildStatItem(
                              Icons.location_on,
                              'Lokasi',
                              data['loc'] ?? '-',
                              theme.colorScheme.secondary,
                              theme),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Tentang Program',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data['longDesc'] ??
                        data['desc'] ??
                        'Deskripsi tidak tersedia.',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.8),
                      height: 1.6,
                    ),
                  ),
                  Builder(builder: (context) {
                    final tags = ((data['referencesTags'] as List?) ?? const [])
                        .map((e) => e.toString())
                        .toList();
                    if (tags.isEmpty) return const SizedBox.shrink();
                    return Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReferencesScreen(
                              tags: tags,
                              title:
                                  'Sumber: ${data['name'] ?? data['title'] ?? 'Program'}',
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: const Text('Sumber & Kutipan'),
                      ),
                    );
                  }),

                  // Additional specific info
                  if (type == 'diet') ...[
                    const SizedBox(height: 24),
                    const Text('Sangat Disarankan ✅',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 19)),
                    const SizedBox(height: 8),
                    Text(data['allowed'] ?? 'Ikuti panduan utama.',
                        textAlign: TextAlign.start,
                        style:
                            TextStyle(color: theme.textTheme.bodySmall?.color)),
                    const SizedBox(height: 16),
                    const Text('Dihindari ❌',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 19)),
                    const SizedBox(height: 8),
                    Text(data['avoid'] ?? 'Makanan olahan dan tinggi gula.',
                        textAlign: TextAlign.start,
                        style:
                            TextStyle(color: theme.textTheme.bodySmall?.color)),
                  ] else ...[
                    const SizedBox(height: 24),
                    const Text('Rundown Acara 📋',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 19)),
                    const SizedBox(height: 8),
                    Text(
                        data['rundown'] ??
                            '06:00 - Regristrasi\n07:00 - Start\n10:00 - Selesai',
                        style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            height: 1.6)),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
              top:
                  BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
        ),
        child: FilledButton(
          onPressed: () {
            if (type == 'diet') {
              // Parse calorie data. Fallback to 1500 if string format fails.
              final calorieString = data['cal']?.toString() ?? '1500';
              int targetCal = int.tryParse(calorieString) ?? 1500;

              context.read<ActivityProvider>().setActiveDietProgram(
                  data['name'] ?? data['title'] ?? 'Program Diet', targetCal);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Target Kalori Harian anda telah diperbarui!')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Berhasil Mendaftar Event!')),
              );
            }
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: type == 'diet'
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(
            type == 'diet' ? 'Mulai Diet Ini' : 'Daftar Sekarang',
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 19),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String label, String value, Color color, ThemeData theme) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 14, color: theme.hintColor)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
