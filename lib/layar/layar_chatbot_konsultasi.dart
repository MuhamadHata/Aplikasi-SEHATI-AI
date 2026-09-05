import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../inti/tema/design_tokens.dart';

import '../inti/layanan/layanan_gemini.dart';
import '../penyedia/penyedia_aktivitas.dart';

class ConsultationChatScreen extends StatefulWidget {
  const ConsultationChatScreen({super.key});

  @override
  State<ConsultationChatScreen> createState() =>
      _ConsultationChatScreenState();
}

class _ConsultationChatScreenState extends State<ConsultationChatScreen> {
  static const String _systemPrompt = '''
Anda adalah SEHATI-AI Care, asisten konsultasi kesehatan personal yang empatik, tenang, bijaksana, dan sangat profesional dalam bahasa Indonesia.

PANDUAN GAYA BAHASA & FORMAT PENULISAN (MUTLAK WAJIB DIPATUHI):
1. Tuliskan jawaban Anda secara naratif dan mengalir dalam bentuk paragraf yang rapi, padu, dan mudah dibaca secara manusiawi layaknya dokter atau tenaga medis profesional.
2. DILARANG KERAS menggunakan simbol markdown bintang ganda (**) untuk menebalkan kata atau judul. Jangan gunakan format tebal.
3. DILARANG KERAS menggunakan tanda hubung (-), bintang (*), atau bullet point untuk membuat daftar berpoin. Jangan menulis jawaban seperti template bot atau slop AI yang kaku.
4. Jika ada beberapa langkah atau anjuran, sampaikanlah secara naratif dan mengalir menggunakan kata penghubung alami dalam paragraf (misalnya: "Sebagai langkah pertama, Anda dapat...", "Di samping itu, perhatikan juga...", "Langkah berikutnya yang disarankan...", "Terakhir...").

PANDUAN MEDIS & KESELAMATAN:
1. Fokus hanya pada pertanyaan kesehatan fisik, kesehatan mental ringan, gejala, penyakit, obat umum, dan keresahan pengguna terkait kondisi tubuh.
2. Jangan mengaku sebagai dokter spesialis dan jangan membuat diagnosis definitif.
3. Berikan edukasi awal, kemungkinan umum yang wajar, langkah perawatan mandiri yang aman, dan kapan harus periksa langsung.
4. Jika ada tanda bahaya seperti sesak napas berat, nyeri dada menjalar, penurunan kesadaran, kejang, perdarahan hebat, atau gejala darurat lain, arahkan segera dan tegas ke IGD atau layanan darurat medis terdekat.
5. Jangan menyarankan dosis obat resep dan jangan menyuruh menghentikan obat dokter.
6. Tutup jawaban dengan satu kalimat ramah bahwa anjuran ini merupakan edukasi awal dan bukan pengganti konsultasi langsung dengan dokter.
''';

  static const List<String> _quickPrompts = [
    'Saya sering sakit kepala, apa yang perlu diperhatikan?',
    'Batuk saya belum sembuh beberapa hari, aman atau perlu periksa?',
    'Saya cemas karena badan sering lemas dan mudah capek.',
    'Gejala apa saja yang termasuk tanda darurat dan harus ke IGD?',
  ];

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      role: _ChatRole.assistant,
      text:
          'Halo, saya SEHATI-AI Care. Ceritakan gejala, kondisi tubuh, atau keresahan kesehatan yang sedang Anda alami. Jika Anda mengalami kondisi darurat seperti sesak napas berat, nyeri dada hebat, atau penurunan kesadaran, pastikan segera mendapatkan pertolongan medis langsung di fasilitas kesehatan terdekat.',
    ),
  ];

  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? preset]) async {
    if (_isSending) return;

    final rawText = preset ?? _messageController.text;
    final message = rawText.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _messages.add(_ChatMessage(role: _ChatRole.user, text: message));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final activity = context.read<ActivityProvider>();
      final systemPrompt = _buildSystemPrompt(activity);
      final history = _messages
          .map((item) => {
                'role': item.role == _ChatRole.user ? 'user' : 'assistant',
                'content': item.text,
              })
          .toList();

      final response = await GeminiService.instance.generateChat(
        history,
        systemPrompt: systemPrompt,
        temperature: 0.35,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatMessage(
            role: _ChatRole.assistant,
            text: (response == null || response.trim().isEmpty)
                ? 'Saya belum bisa memberi jawaban yang jelas. Coba jelaskan gejala, durasi, usia, dan apakah ada demam, nyeri, atau sesak.'
                : _humanizeResponse(response),
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _ChatMessage(
            role: _ChatRole.assistant,
            text:
                'Koneksi ke layanan AI sedang bermasalah. Jika keluhan terasa berat, memburuk cepat, atau disertai tanda darurat, segera periksa langsung ke fasilitas kesehatan.',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  String _buildSystemPrompt(ActivityProvider activity) {
    final muscleGroups = activity.workoutMuscleGroups.isEmpty
        ? 'tidak ada fokus khusus'
        : activity.workoutMuscleGroups.join(', ');
    final recentFoods = activity.foodLogs.take(3).map((food) {
      return '${food.foodName} (${food.calories} kkal, ${food.time})';
    }).join('; ');
    final latestSleep = activity.sleepLogs.isNotEmpty ? activity.sleepLogs.first : null;

      final userContext = '''
KONTEKS DATA PENGGUNA SEHATI-AI:
- Nama: ${activity.userName}
- Usia: ${activity.age}
- Gender: ${activity.gender}
- Berat: ${activity.weight.toStringAsFixed(1)} kg
- Tinggi: ${activity.heightCm.toStringAsFixed(0)} cm
- BMI: ${activity.bmi.toStringAsFixed(1)}
- Status rokok: ${activity.smokingStatusLabel}
- Langkah hari ini: ${activity.steps}
- Kalori masuk hari ini: ${activity.calories}
- Kalori terbakar hari ini: ${activity.caloriesBurned}
- Air minum hari ini: ${activity.waterGlasses}/${activity.waterTarget} gelas
- Diet aktif: ${activity.activeDietProgram ?? 'tidak ada'}
- Mode puasa: ${activity.fastingMode}
- Fase puasa saat ini: ${activity.fastingPhaseLabel}
- Goal latihan: ${activity.workoutGoal ?? 'belum diatur'}
- Level latihan: ${activity.workoutLevel ?? 'belum diatur'}
- Fokus otot: $muscleGroups
- Peralatan latihan: ${activity.workoutEquipment ?? 'tidak diatur'}
- Tidur terakhir: ${latestSleep != null ? '${latestSleep.durationLabel}, tidur ${latestSleep.bedtimeLabel}, bangun ${latestSleep.wakeLabel}' : 'tidak ada data'}
- Makanan/minuman terbaru: ${recentFoods.isEmpty ? 'tidak ada data' : recentFoods}

Gunakan konteks ini hanya sebagai data pendukung personalisasi. Jika konteks tidak relevan dengan pertanyaan pengguna, abaikan.
''';

    return '$_systemPrompt\n$userContext';
  }

  String _humanizeResponse(String response) {
    var text = response
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll('`', '');

    // Hapus tanda hubung/bullet di awal baris (- , * , • ) agar menjadi kalimat naratif alami
    final lines = text.split('\n');
    final processed = <String>[];
    for (final line in lines) {
      var trimmed = line.trim();
      // Hapus garis pembatas markdown horizontal seperti "---" atau "- - -"
      if (RegExp(r'^[\-\_]{2,}$').hasMatch(trimmed)) {
        continue;
      }
      // Hapus bullet marker di awal baris (- , * , • )
      if (RegExp(r'^[\-\*\u2022]\s+').hasMatch(trimmed)) {
        trimmed = trimmed.replaceFirst(RegExp(r'^[\-\*\u2022]\s+'), '');
      }
      processed.add(trimmed);
    }

    text = processed
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return text;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: ext?.gradientPrimary ?? AppColors.gradientPrimary,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'SEHATI-AI Care',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'MiniCPM-V / AI',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Konsultasi awal gejala, penyakit, dan keresahan kesehatan',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.medical_services_outlined, size: 24, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Gunakan chatbot ini untuk konsultasi awal. Untuk keluhan berat, gejala memburuk, atau kondisi darurat, tetap prioritaskan pemeriksaan langsung.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickPrompts
                        .map(
                          (prompt) => ActionChip(
                            onPressed:
                                _isSending ? null : () => _sendMessage(prompt),
                            side: BorderSide(
                              color: primary.withValues(alpha: 0.18),
                            ),
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            label: Text(
                              prompt,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  ..._messages
                      .map((message) => _MessageBubble(message: message)),
                  if (_isSending)
                    _TypingBubble(
                      color: primary,
                      background: theme.colorScheme.surfaceContainerHighest,
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText:
                              'Tulis gejala, durasi, usia, atau keresahan kesehatan Anda...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              ext?.gradientPrimary ?? AppColors.gradientPrimary,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _isSending ? null : _sendMessage,
                        icon: Icon(
                          _isSending
                              ? Icons.hourglass_top_rounded
                              : Icons.send_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppThemeExtension>();
    final isUser = message.role == _ChatRole.user;
    final bubbleColor =
        isUser ? theme.colorScheme.primary : theme.colorScheme.surface;
    final textColor = isUser ? Colors.white : theme.colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  colors: ext?.gradientPrimary ?? AppColors.gradientPrimary,
                )
              : null,
          color: isUser ? null : bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 18),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.12),
                ),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? 'Anda' : 'SEHATI-AI Care',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isUser
                    ? Colors.white70
                    : theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  final Color color;
  final Color background;

  const _TypingBubble({
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TypingDot(color: color),
            const SizedBox(width: 4),
            _TypingDot(color: color.withValues(alpha: 0.72)),
            const SizedBox(width: 4),
            _TypingDot(color: color.withValues(alpha: 0.44)),
          ],
        ),
      ),
    );
  }
}

class _TypingDot extends StatelessWidget {
  final Color color;

  const _TypingDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

enum _ChatRole {
  assistant,
  user,
}

class _ChatMessage {
  final _ChatRole role;
  final String text;

  const _ChatMessage({
    required this.role,
    required this.text,
  });
}
