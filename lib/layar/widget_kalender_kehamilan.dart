import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../penyedia/penyedia_aktivitas.dart';

class PregnancyCalendarTab extends StatefulWidget {
  const PregnancyCalendarTab({super.key});

  @override
  State<PregnancyCalendarTab> createState() => _PregnancyCalendarTabState();
}

class _PregnancyCalendarTabState extends State<PregnancyCalendarTab> {
  DateTime _selectedMonth = DateTime.now();

  // Form input states
  int _inputMode = 0; // 0: HPHT (LMP), 1: Umur Kehamilan (Gestational Weeks)
  DateTime _selectedHphtDate =
      DateTime.now().subtract(const Duration(days: 30));
  int _selectedWeeks = 12;

  // Women Health states: 0 = Kehamilan, 1 = Menstruasi
  int _womenHealthMode = 0;
  DateTime _menstruasiDate = DateTime.now().subtract(const Duration(days: 14));
  final int _cycleLength = 28;
  final int _periodDays = 5;

  // Calculates days in a month
  int _daysInMonth(DateTime date) => DateTime(date.year, date.month + 1, 0).day;

  // Calculates first day offset for calendar
  int _firstDayOffset(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday % 7;
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  // Fetal size details map
  Map<String, String> _getFetalDetails(int week) {
    if (week < 4) {
      return {
        'size': 'Sangat kecil',
        'comparison': 'Biji Selasih',
        'emoji': '🌱',
        'description':
            'Sel telur yang dibuahi sedang membelah dan menempel pada dinding rahim Anda.'
      };
    } else if (week <= 5) {
      return {
        'size': '2 mm',
        'comparison': 'Biji Poppy',
        'emoji': '🍓',
        'description':
            'Embrio mulai membentuk struktur dasar jantung, sistem saraf, dan organ dasar lainnya.'
      };
    } else if (week <= 8) {
      return {
        'size': '1.6 cm',
        'comparison': 'Buah Raspberry',
        'emoji': '🍇',
        'description':
            'Jantung bayi berdetak cepat! Tangan, kaki kecil, serta hidung dan kelopak mata mulai terbentuk.'
      };
    } else if (week <= 12) {
      return {
        'size': '5.4 cm',
        'comparison': 'Jeruk Nipis',
        'emoji': '🍋',
        'description':
            'Bayi sudah bisa membuka dan mengepalkan tangannya serta mulai menggerakkan kaki-kaki kecilnya.'
      };
    } else if (week <= 16) {
      return {
        'size': '11.6 cm',
        'comparison': 'Buah Alpukat',
        'emoji': '🥑',
        'description':
            'Kulit bayi yang transparan mulai ditumbuhi rambut halus (lanugo) dan matanya sudah bisa merespon cahaya.'
      };
    } else if (week <= 20) {
      return {
        'size': '25.6 cm',
        'comparison': 'Buah Pisang',
        'emoji': '🍌',
        'description':
            'Bayi sekarang aktif bergerak! Anda mungkin sudah bisa merasakan tendangan-tendangan lembutnya.'
      };
    } else if (week <= 24) {
      return {
        'size': '30 cm',
        'comparison': 'Jagung manis',
        'emoji': '🌽',
        'description':
            'Alat pendengaran bayi telah berfungsi penuh, ia sudah bisa mendengar suara detak jantung dan suara Anda.'
      };
    } else if (week <= 28) {
      return {
        'size': '37.6 cm',
        'comparison': 'Terong',
        'emoji': '🍆',
        'description':
            'Paru-paru bayi mulai memproduksi surfaktan, memungkinkannya belajar bernapas di dalam ketuban.'
      };
    } else if (week <= 32) {
      return {
        'size': '42.4 cm',
        'comparison': 'Labu Madu (Squash)',
        'emoji': '🎃',
        'description':
            'Tulang bayi sudah terbentuk sempurna meskipun masih lunak. Ia banyak tidur dan bermimpi.'
      };
    } else if (week <= 36) {
      return {
        'size': '47.4 cm',
        'comparison': 'Buah Pepaya',
        'emoji': '🍈',
        'description':
            'Posisi kepala bayi sebagian besar sudah mulai turun ke arah jalan lahir untuk bersiap.'
      };
    } else {
      return {
        'size': '51 cm',
        'comparison': 'Semangka Kecil',
        'emoji': '🍉',
        'description':
            'Bayi Anda siap lahir! Organ-organnya sudah matang sempurna dan siap menghadapi dunia luar.'
      };
    }
  }

  // Get food and activity advice based on trimester
  Map<String, dynamic> _getTrimesterAdvice(int trimester) {
    if (trimester == 1) {
      return {
        'foods': [
          {
            'icon': '🥬',
            'title': 'Asam Folat & Sayuran Hijau',
            'desc':
                'Penting untuk perkembangan tabung saraf bayi (bayam, brokoli).'
          },
          {
            'icon': '🥚',
            'title': 'Telur & Protein Matang',
            'desc': 'Kolin pada kuning telur sangat baik untuk sel otak bayi.'
          },
          {
            'icon': '🍵',
            'title': 'Jahe & Makanan Kering',
            'desc':
                'Membantu meredakan mual muntah (morning sickness) di awal kehamilan.'
          },
        ],
        'lifestyle':
            'Fokus pada istirahat cukup, hindari makanan mentah/setengah matang, dan lakukan jalan kaki santai 15-20 menit sehari.',
        'color': const Color(0xFFF43F5E), // Soft red/pink
      };
    } else if (trimester == 2) {
      return {
        'foods': [
          {
            'icon': '🥛',
            'title': 'Kalsium & Vitamin D',
            'desc':
                'Susu, yogurt, keju untuk pembentukan tulang dan gigi bayi yang kokoh.'
          },
          {
            'icon': '🥩',
            'title': 'Zat Besi & Protein Hewani',
            'desc':
                'Mencegah anemia pada ibu karena volume darah meningkat (daging merah, ikan matang).'
          },
          {
            'icon': '🥑',
            'title': 'Lemak Sehat (DHA)',
            'desc':
                'Alpukat dan kacang-kacangan mendukung tumbuh kembang saraf otak bayi.'
          },
        ],
        'lifestyle':
            'Waktu terbaik untuk tetap aktif. Lakukan prenatal yoga, senam hamil, atau berenang secara teratur.',
        'color': const Color(0xFF10B981), // Teal/Green
      };
    } else {
      return {
        'foods': [
          {
            'icon': '🌾',
            'title': 'Makanan Serat Tinggi',
            'desc':
                'Membantu mencegah sembelit yang umum terjadi di trimester akhir (oatmeal, buah segar).'
          },
          {
            'icon': '🍌',
            'title': 'Kalium & Energi Tambahan',
            'desc':
                'Pisang dan air kelapa mengurangi kram kaki dan menjaga cairan tubuh.'
          },
          {
            'icon': '🍗',
            'title': 'Protein Tinggi & Porsi Kecil',
            'desc':
                'Makan porsi kecil tapi sering agar lambung tidak terasa penuh sesak.'
          },
        ],
        'lifestyle':
            'Lakukan latihan pernapasan untuk melahirkan, jalan santai ringan, senam kegel, dan kelola kecemasan menjelang persalinan.',
        'color': const Color(0xFFF59E0B), // Amber
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Gender Gate: Khusus Wanita ──
    if (provider.gender != 'Wanita') {
      return _buildMaleRestrictedNotice(context, isDark);
    }

    return Column(
      children: [
        // Mode Selector: Kehamilan vs Menstruasi
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _womenHealthMode = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _womenHealthMode == 0
                          ? const Color(0xFFEC4899)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '👶 Kehamilan',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _womenHealthMode == 0
                              ? Colors.white
                              : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _womenHealthMode = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _womenHealthMode == 1
                          ? const Color(0xFFEC4899)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '🌸 Siklus Menstruasi',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _womenHealthMode == 1
                              ? Colors.white
                              : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Active View
        Expanded(
          child: _womenHealthMode == 0
              ? _buildPregnancyBody(isDark, provider)
              : _buildMenstruasiBody(isDark, provider),
        ),
      ],
    );
  }

  Widget _buildPregnancyBody(bool isDark, ActivityProvider provider) {
    if (!provider.isPregnancyConfigured || provider.pregnancyLmpDate == null) {
      return _buildSetupForm(isDark, provider);
    }

    final lmp = provider.pregnancyLmpDate!;
    final today = DateTime.now();
    final diffDays = today.difference(lmp).inDays;

    final currentWeeks = (diffDays / 7).floor().clamp(0, 42);
    final currentDays = diffDays % 7;
    final dueDate = lmp.add(const Duration(days: 280));
    final daysToDelivery = dueDate.difference(today).inDays;

    int trimester = 1;
    if (currentWeeks >= 28) {
      trimester = 3;
    } else if (currentWeeks >= 14) {
      trimester = 2;
    }

    final fetal = _getFetalDetails(currentWeeks);
    final advice = _getTrimesterAdvice(trimester);
    final themeColor = advice['color'] as Color;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PREGNANCY HEADER STATUS CARD
          _buildPregnancyStatusCard(currentWeeks, currentDays, daysToDelivery,
              dueDate, trimester, themeColor, isDark),
          const SizedBox(height: 20),

          // FETAL DEVELOPMENT CARD
          _buildFetalDevelopmentCard(fetal, currentWeeks, themeColor, isDark),
          const SizedBox(height: 20),

          // PREGNANCY CALENDAR CARD
          _buildPregnancyCalendarCard(lmp, themeColor, isDark),
          const SizedBox(height: 20),

          // NUTRITION AND FOOD ADVICE
          _buildNutritionAdviceCard(advice, themeColor, isDark),
          const SizedBox(height: 20),

          // LIFESTYLE & EXERCISE CARD
          _buildLifestyleCard(advice, themeColor, isDark),
          const SizedBox(height: 24),

          // RESET SETTING BUTTON
          OutlinedButton.icon(
            onPressed: () => _confirmResetDialog(context, provider),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reset / Ubah Data Kehamilan',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaleRestrictedNotice(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE7F3),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFBCFE8)),
                ),
                child: const Center(
                  child: Text('🌸', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Khusus Profil Wanita',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fitur Kalender Kehamilan dan Siklus Menstruasi dirancang khusus untuk pemantauan siklus reproduksi wanita. Jika profil Anda keliru, Anda dapat mengubahnya di pengaturan profil.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<ActivityProvider>().updateGender('Wanita');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil jenis kelamin diubah menjadi Wanita.'),
                      backgroundColor: Color(0xFFEC4899),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.female_rounded, size: 18),
                label: const Text('Ganti Profil ke Wanita', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenstruasiBody(bool isDark, ActivityProvider provider) {
    final today = DateTime.now();
    final diffDays = today.difference(_menstruasiDate).inDays;
    final currentCycleDay = (diffDays % _cycleLength) + 1;
    final daysUntilNext = _cycleLength - currentCycleDay + 1;
    final isFertile = currentCycleDay >= 12 && currentCycleDay <= 16;
    final isPeriod = currentCycleDay <= _periodDays;

    String phaseName;
    Color phaseColor;
    String phaseDesc;
    if (isPeriod) {
      phaseName = 'Fase Menstruasi';
      phaseColor = const Color(0xFFE11D48);
      phaseDesc = 'Pendarahan haid. Waktu tepat untuk istirahat, hindari kafein berlebih, dan minum cukup air.';
    } else if (currentCycleDay < 12) {
      phaseName = 'Fase Folikular';
      phaseColor = const Color(0xFF0284C7);
      phaseDesc = 'Estrogen meningkat! Energi dan stamina bertambah, waktu optimal untuk latihan kardio & kebugaran.';
    } else if (isFertile) {
      phaseName = 'Fase Ovulasi (Masa Subur)';
      phaseColor = const Color(0xFF8B5CF6);
      phaseDesc = 'Sel telur dilepaskan. Peluang konsepsi/kehamilan paling tinggi dalam siklus bulanan Anda.';
    } else {
      phaseName = 'Fase Luteal';
      phaseColor = const Color(0xFFF59E0B);
      phaseDesc = 'Progesteron naik. Jaga mood dengan konsumsi magnesium, jalan santai, dan tidur cukup menjelang haid.';
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF831843).withValues(alpha: 0.3), const Color(0xFF500724).withValues(alpha: 0.15)]
                    : [const Color(0xFFFDF2F8), const Color(0xFFFCE7F3)],
              ),
              border: Border.all(color: const Color(0xFFF472B6).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: phaseColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: phaseColor.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        phaseName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: phaseColor,
                        ),
                      ),
                    ),
                    Text(
                      'Siklus $_cycleLength Hari',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text('Hari ke- ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text(
                      '$currentCycleDay',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Poppins',
                        color: Color(0xFFEC4899),
                      ),
                    ),
                    Text(
                      ' / $_cycleLength',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  daysUntilNext <= 0
                      ? 'Hari ini estimasi hari pertama haid berikutnya'
                      : '~$daysUntilNext hari menuju periode haid berikutnya',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (currentCycleDay / _cycleLength).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  phaseDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _menstruasiDate,
                firstDate: today.subtract(const Duration(days: 60)),
                lastDate: today,
                helpText: 'Pilih Tanggal Hari Pertama Haid Terakhir',
              );
              if (picked != null) {
                setState(() => _menstruasiDate = picked);
              }
            },
            icon: const Icon(Icons.edit_calendar_rounded, size: 18),
            label: Text(
              'Hari Pertama Haid Terakhir: ${DateFormat('dd MMM yyyy').format(_menstruasiDate)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🌸 Panduan 4 Fase Siklus Menstruasi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 12),
                _buildPhaseRow('1. Fase Menstruasi (Hari 1-5)', 'Pendarahan haid. Relaksasi, yoga ringan, dan cukup istirahat.', const Color(0xFFE11D48), currentCycleDay <= 5),
                const Divider(height: 16),
                _buildPhaseRow('2. Fase Folikular (Hari 6-11)', 'Energi meningkat. Bagus untuk latihan kekuatan & kardio.', const Color(0xFF0284C7), currentCycleDay >= 6 && currentCycleDay <= 11),
                const Divider(height: 16),
                _buildPhaseRow('3. Fase Ovulasi (Hari 12-16)', 'Masa subur puncak. Metabolisme tubuh optimal.', const Color(0xFF8B5CF6), isFertile),
                const Divider(height: 16),
                _buildPhaseRow('4. Fase Luteal (Hari 17-28)', 'Masa PMS. Utamakan makanan kaya zat besi & kurangi stres.', const Color(0xFFF59E0B), currentCycleDay >= 17),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFBCFE8)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Image.asset(
                    'assets/images/maskot_nubi_study.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.favorite_rounded, color: Color(0xFFEC4899), size: 36),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pesan Hangat Nubi ✨',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFBE185D),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Dengarkan sinyal tubuhmu di setiap fase ya! Kompres hangat jika kram dan penuhi hidrasi 8 gelas air setiap hari.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF831843),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseRow(String title, String subtitle, Color color, bool isCurrent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent ? color.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isCurrent ? color : null,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Aktif', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Setup onboarding form
  Widget _buildSetupForm(bool isDark, ActivityProvider provider) {
    final primary = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Graphic Intro
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.pink.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/images/fitur/fitur_pregnancy_ai.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.pregnant_woman_rounded, size: 44, color: Colors.pink),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Kalender Kehamilan SEHATI-AI',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pantau pertumbuhan buah hati Anda hari demi hari, peroleh rekomendasi nutrisi khusus, dan dapatkan saran hidup sehat selama kehamilan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Selection tab mode
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _inputMode = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _inputMode == 0 ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Tanggal HPHT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _inputMode == 0
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _inputMode = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _inputMode == 1 ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Umur Kehamilan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _inputMode == 1
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Dynamic field based on mode
          if (_inputMode == 0) ...[
            Text(
              'Hari Pertama Haid Terakhir (HPHT) *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedHphtDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 290)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedHphtDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMMM yyyy', 'id_ID')
                          .format(_selectedHphtDate),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    Icon(Icons.calendar_month, color: primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Catatan: Kami akan menghitung hari taksiran persalinan (HPL) berdasarkan HPHT Anda.',
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.black45),
            ),
          ] else ...[
            Text(
              'Umur Kehamilan Saat Ini (Minggu) *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (ctx, setSt) => Column(
                children: [
                  Text(
                    '$_selectedWeeks Minggu',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: primary),
                  ),
                  Slider(
                    value: _selectedWeeks.toDouble(),
                    min: 1,
                    max: 42,
                    divisions: 41,
                    activeColor: primary,
                    onChanged: (v) {
                      setSt(() => _selectedWeeks = v.round());
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kami akan mengestimasikan tanggal HPHT Anda berjarak ${_selectedWeeks * 7} hari ke belakang dari hari ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.black45),
            ),
          ],
          const SizedBox(height: 36),

          // Submit button
          ElevatedButton(
            onPressed: () {
              DateTime finalLmp;
              if (_inputMode == 0) {
                finalLmp = _selectedHphtDate;
              } else {
                finalLmp =
                    DateTime.now().subtract(Duration(days: _selectedWeeks * 7));
              }
              provider.configurePregnancy(finalLmp);

              // Set the current calendar month to the current date
              setState(() {
                _selectedMonth = DateTime.now();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Simpan & Buka Kalender',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // Visual status card for pregnancy dashboard
  Widget _buildPregnancyStatusCard(int week, int day, int countdown,
      DateTime hpl, int trimester, Color themeColor, bool isDark) {
    final formattedHpl = DateFormat('dd MMMM yyyy', 'id_ID').format(hpl);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColor.withOpacity(isDark ? 0.16 : 0.08),
            themeColor.withOpacity(isDark ? 0.06 : 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withOpacity(0.25), width: 1.5),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.pregnant_woman_rounded, size: 22, color: themeColor),
                  const SizedBox(width: 8),
                  Text(
                    'Trimester $trimester',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: themeColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'HPL: $formattedHpl',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: themeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$week Minggu, $day Hari',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            countdown > 0
                ? 'Tersisa $countdown Hari menuju taksiran kelahiran bayi Anda.'
                : 'Hari persalinan telah dekat! Siapkan segala keperluan persalinan Anda.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 14),
          // Progress bar up to 40 weeks
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (week / 40.0).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: themeColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(themeColor),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Minggu 1',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text('${(week / 40.0 * 100).round()}% Kehamilan',
                      style: TextStyle(
                          fontSize: 10,
                          color: themeColor,
                          fontWeight: FontWeight.bold)),
                  const Text('Minggu 40',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Fetal development & baby size info card
  Widget _buildFetalDevelopmentCard(
      Map<String, String> fetal, int week, Color themeColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.child_care, color: themeColor, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Perkembangan Buah Hati',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeColor.withOpacity(0.2)),
                ),
                child: Center(
                  child: Text(
                    fetal['emoji']!,
                    style: const TextStyle(fontSize: 34),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Taksiran Ukuran: ${fetal['size']}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Seukuran ${fetal['comparison']}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            fetal['description']!,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  // Clean Pregnancy calendar view
  Widget _buildPregnancyCalendarCard(
      DateTime lmp, Color themeColor, bool isDark) {
    final monthName = DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                ),
              ),
              Text(
                monthName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                .map((day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          _buildCalendarDaysGrid(lmp, themeColor, isDark),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: themeColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('Hari Ini',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 18),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.2),
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('Hari Kehamilan',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDaysGrid(DateTime lmp, Color themeColor, bool isDark) {
    final days = _daysInMonth(_selectedMonth);
    final offset = _firstDayOffset(_selectedMonth);
    final gridCount = days + offset;
    final rowCount = (gridCount / 7).ceil();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: rowCount * 7,
      itemBuilder: (context, index) {
        if (index < offset || index >= offset + days) {
          return const SizedBox.shrink();
        }

        final dayNum = index - offset + 1;
        final cellDate =
            DateTime(_selectedMonth.year, _selectedMonth.month, dayNum);

        final isToday = DateUtils.isSameDay(cellDate, DateTime.now());

        // A day is inside pregnancy if it is after or on LMP
        final isPregnancyDay =
            (cellDate.isAfter(lmp) || DateUtils.isSameDay(cellDate, lmp)) &&
                cellDate.isBefore(DateTime.now().add(const Duration(days: 1)));

        Color? textColor;
        Color? cellBg;
        BoxBorder? border;

        if (isToday) {
          cellBg = themeColor;
          textColor = Colors.white;
        } else if (isPregnancyDay) {
          cellBg = themeColor.withOpacity(0.15);
          textColor = themeColor;
        } else {
          textColor = isDark ? Colors.white70 : const Color(0xFF1E293B);
        }

        return Container(
          decoration: BoxDecoration(
            color: cellBg,
            shape: BoxShape.circle,
            border: border,
          ),
          child: Center(
            child: Text(
              '$dayNum',
              style: TextStyle(
                fontSize: 13,
                fontWeight: (isToday || isPregnancyDay)
                    ? FontWeight.w900
                    : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        );
      },
    );
  }

  // Nutrition Card displaying trimester food advice
  Widget _buildNutritionAdviceCard(
      Map<String, dynamic> advice, Color themeColor, bool isDark) {
    final foods = advice['foods'] as List<Map<String, String>>;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, color: themeColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Saran Nutrisi & Makanan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: foods.length,
            separatorBuilder: (_, __) => Divider(
                color: isDark ? Colors.white10 : Colors.black12, height: 16),
            itemBuilder: (context, i) {
              final food = foods[i];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(food['icon']!,
                        style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food['title']!,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          food['desc']!,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Lifestyle advice card
  Widget _buildLifestyleCard(
      Map<String, dynamic> advice, Color themeColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_run_rounded, color: themeColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Aktivitas Fisik & Gaya Hidup',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            advice['lifestyle'] as String,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmResetDialog(BuildContext context, ActivityProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Data Kehamilan?'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus/mengubah data kehamilan saat ini? Data kalender kehamilan akan diatur ulang.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              provider.resetPregnancy();
              Navigator.pop(ctx);
            },
            child:
                const Text('Reset', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
