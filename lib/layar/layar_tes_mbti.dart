import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../penyedia/penyedia_aktivitas.dart';

class _MBTIQuestion {
  final String text;
  final String dimension; // 'EI', 'SN', 'TF', 'JP'
  final bool positiveForA; // true = Agree is E/S/T/J, false = Agree is I/N/F/P

  const _MBTIQuestion({
    required this.text,
    required this.dimension,
    required this.positiveForA,
  });
}

enum _MBTIStage { intro, test, result }

class MBTITestScreen extends StatefulWidget {
  const MBTITestScreen({super.key});

  @override
  State<MBTITestScreen> createState() => _MBTITestScreenState();
}

class _MBTITestScreenState extends State<MBTITestScreen> {
  _MBTIStage _stage = _MBTIStage.intro;
  int _currentIdx = 0;

  // 32 Questions (8 for each of E-I, S-N, T-F, J-P)
  final List<_MBTIQuestion> _questions = const [
    // ── Extraversion (E) vs Introversion (I) ──
    _MBTIQuestion(
      text:
          "Anda merasa lelah setelah menghabiskan waktu bersama banyak orang dan membutuhkan waktu sendiri untuk memulihkan energi.",
      dimension: "EI",
      positiveForA: false,
    ),
    _MBTIQuestion(
      text:
          "Anda biasanya menikmati menjadi pusat perhatian dalam suatu kelompok atau acara sosial.",
      dimension: "EI",
      positiveForA: true,
    ),
    _MBTIQuestion(
      text:
          "Anda lebih suka memulai percakapan dengan orang baru yang baru Anda temui.",
      dimension: "EI",
      positiveForA: true,
    ),
    _MBTIQuestion(
      text:
          "Anda lebih suka menghabiskan waktu luang sendirian dengan hobi Anda daripada berkumpul dengan teman-teman.",
      dimension: "EI",
      positiveForA: false,
    ),
    _MBTIQuestion(
      text:
          "Dalam diskusi kelompok, Anda biasanya langsung mengutarakan pikiran Anda tanpa berpikir lama.",
      dimension: "EI",
      positiveForA: true,
    ),
    _MBTIQuestion(
      text:
          "Anda merasa lebih nyaman berkomunikasi secara tertulis (chat/email) daripada berbicara langsung.",
      dimension: "EI",
      positiveForA: false,
    ),
    _MBTIQuestion(
      text:
          "Anda lebih suka bekerja di lingkungan yang tenang dan mandiri daripada tempat kerja yang dinamis dan berorientasi tim.",
      dimension: "EI",
      positiveForA: false,
    ),
    _MBTIQuestion(
      text:
          "Anda sering mencari interaksi sosial baru atau bepergian ke tempat ramai ketika sedang bosan.",
      dimension: "EI",
      positiveForA: true,
    ),

    // ── Sensing (S) vs Intuition (N) ──
    _MBTIQuestion(
      text:
          "Anda lebih tertarik pada fakta nyata dan detail praktis daripada teori atau konsep abstrak.",
      dimension: "SN",
      positiveForA: true,
    ),
    _MBTIQuestion(
      text:
          "Anda sering membayangkan kemungkinan di masa depan dan memikirkan ide-ide visioner.",
      dimension: "SN",
      positiveForA: false,
    ),
    _MBTIQuestion(
      text:
          "Saat mempelajari sesuatu, Anda lebih suka contoh konkret daripada penjelasan teoretis yang rumit.",
      dimension: "SN",
      positiveForA: true,
    ),
    _MBTIQuestion(
      text:
          "Anda sering mencari makna mendalam di balik peristiwa atau perkataan orang lain.",
      dimension: "SN",
      positiveForA: false,
    ),
    _MBTIQuestion(
      text:
          "Anda lebih nyaman mengikuti metode kerja yang sudah terbukti berhasil daripada mencoba cara baru yang belum pasti.",
      dimension: "SN",
      positiveForA: true,
    ),
    _MBTIQuestion(
      text:
          "Anda sering terinspirasi oleh ide-ide kreatif dan skenario imajiner dalam pikiran Anda.",
      dimension: "SN",
      positiveForA: false,
    ),
    _MBTIQuestion(
      text:
          "Anda lebih fokus pada situasi 'saat ini' dan apa yang sedang terjadi dibandingkan apa yang 'mungkin terjadi' nanti.",
      dimension: "SN",
      positiveForA: true,
    ),
    _MBTIQuestion(
      text:
          "Anda sering berspekulasi tentang bagaimana tren global atau teknologi akan memengaruhi kehidupan di masa depan.",
      dimension: "SN",
      positiveForA: false,
    ),

    // ── Thinking (T) vs Feeling (F) ──
    _MBTIQuestion(
      text:
          "Dalam mengambil keputusan penting, logika dan objektivitas harus diutamakan di atas perasaan pribadi.",
      dimension: "TF",
      positiveForA: true,
    ),
    _MBTIQuestion(
      text:
          "Anda sangat peka terhadap suasana hati orang lain dan mudah berempati dengan perasaan mereka.",
      dimension: "TF",
      positiveForA: false,
    ),
    _MBTIQuestion(
      text:
          "Anda lebih menghargai argumen yang masuk akal daripada argumen yang emosional namun menyentuh hati.",
      dimension: "TF",
      positiveForA: true,
    ),
    _MBTIQuestion(
      text:
          "Menjaga keharmonisan hubungan dalam kelompok lebih penting bagi Anda daripada memenangkan perdebatan.",
      dimension: "TF",
      positiveForA: false,
    ),
    _MBTIQuestion(
      text:
          "Anda cenderung bersikap analitis dan kritis ketika seseorang menceritakan masalah mereka kepada Anda.",
      dimension: "TF",
      positiveForA: true,
    ),
    _MBTIQuestion(
      text:
          "Anda sering mengutamakan kebaikan hati dan perasaan orang lain, bahkan jika itu berarti sedikit mengabaikan aturan.",
      dimension: "TF",
      positiveForA: false,
    ),
    _MBTIQuestion(
      text:
          "Bagi Anda, kejujuran langsung (blak-blakan) lebih baik daripada berputar-putar untuk melindungi perasaan seseorang.",
      dimension: "TF",
      positiveForA: true,
    ),
    _MBTIQuestion(
      text:
          "Anda sering membuat keputusan besar berdasarkan intuisi moral atau apa yang terasa benar di hati Anda.",
      dimension: "TF",
      positiveForA: false,
    ),

    // ── Judging (J) vs Perceiving (P) ──
    _MBTIQuestion(
      text:
          "Anda lebih suka merencanakan kegiatan liburan secara mendetail daripada pergi begitu saja secara spontan.",
      dimension: "JP",
      positiveForA: true,
    ),
    _MBTIQuestion(
      text:
          "Anda merasa lebih nyaman jika tugas diselesaikan jauh-jauh hari sebelum tenggat waktu (deadline).",
      dimension: "JP",
      positiveForA: true,
    ),
    _MBTIQuestion(
      text:
          "Anda cenderung fleksibel dan suka membiarkan pilihan Anda tetap terbuka hingga menit terakhir.",
      dimension: "JP",
      positiveForA: false,
    ),
    _MBTIQuestion(
      text:
          "Daftar tugas harian (to-do list) yang teratur sangat membantu Anda dalam beraktivitas.",
      dimension: "JP",
      positiveForA: true,
    ),
    _MBTIQuestion(
      text:
          "Anda merasa tertekan oleh jadwal yang terlalu ketat dan lebih suka bekerja dengan ritme yang spontan.",
      dimension: "JP",
      positiveForA: false,
    ),
    _MBTIQuestion(
      text:
          "Anda menikmati tantangan yang muncul secara tiba-tiba dan sering bekerja dengan baik di bawah tekanan menit-menit terakhir.",
      dimension: "JP",
      positiveForA: false,
    ),
    _MBTIQuestion(
      text:
          "Anda merasa terganggu ketika rencana yang sudah dijadwalkan matang tiba-tiba berubah.",
      dimension: "JP",
      positiveForA: true,
    ),
    _MBTIQuestion(
      text:
          "Anda lebih senang berimprovisasi saat menghadapi situasi baru daripada mempersiapkannya secara berlebihan.",
      dimension: "JP",
      positiveForA: false,
    ),
  ];

  // User answers map: question_index -> score (-2 to 2)
  // 2 = Sangat Setuju, 1 = Setuju, 0 = Netral, -1 = Tidak Setuju, -2 = Sangat Tidak Setuju
  final Map<int, int> _answers = {};

  // Results computed at the end
  String _mbtiResult = '';
  double _pctE = 50;
  double _pctS = 50;
  double _pctT = 50;
  double _pctJ = 50;

  void _calculateResult() {
    int scoreEI = 0;
    int scoreSN = 0;
    int scoreTF = 0;
    int scoreJP = 0;

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final r = _answers[i] ?? 0;
      final val = q.positiveForA ? r : -r;
      if (q.dimension == 'EI') scoreEI += val;
      if (q.dimension == 'SN') scoreSN += val;
      if (q.dimension == 'TF') scoreTF += val;
      if (q.dimension == 'JP') scoreJP += val;
    }

    // Max score per dimension is 8 * 2 = 16, min is -16. Map to 0-100%
    _pctE = ((scoreEI + 16) / 32) * 100;
    _pctS = ((scoreSN + 16) / 32) * 100;
    _pctT = ((scoreTF + 16) / 32) * 100;
    _pctJ = ((scoreJP + 16) / 32) * 100;

    final type = StringBuffer();
    type.write(_pctE >= 50 ? 'E' : 'I');
    type.write(_pctS >= 50 ? 'S' : 'N');
    type.write(_pctT >= 50 ? 'T' : 'F');
    type.write(_pctJ >= 50 ? 'J' : 'P');

    _mbtiResult = type.toString();
  }

  void _answerQuestion(int rating) {
    setState(() {
      _answers[_currentIdx] = rating;
    });

    // Short delay for a clean visual transition
    Future.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      if (_currentIdx < _questions.length - 1) {
        setState(() {
          _currentIdx++;
        });
      } else {
        setState(() {
          _calculateResult();
          _stage = _MBTIStage.result;
        });
      }
    });
  }

  String _mbtiTitle(String type) {
    switch (type) {
      case 'ISTJ':
        return 'Sang Logistik';
      case 'ISFJ':
        return 'Sang Pelindung';
      case 'INFJ':
        return 'Sang Advokat';
      case 'INTJ':
        return 'Sang Arsitek';
      case 'ISTP':
        return 'Sang Pengrajin';
      case 'ISFP':
        return 'Sang Seniman';
      case 'INFP':
        return 'Sang Mediator';
      case 'INTP':
        return 'Sang Logikawan';
      case 'ESTP':
        return 'Sang Pengusahawan';
      case 'ESFP':
        return 'Sang Penghibur';
      case 'ENFP':
        return 'Sang Juru Kampanye';
      case 'ENTP':
        return 'Sang Pendebat';
      case 'ESTJ':
        return 'Sang Eksekutif';
      case 'ESFJ':
        return 'Sang Konsul';
      case 'ENFJ':
        return 'Sang Protokoler';
      case 'ENTJ':
        return 'Sang Komandan';
      default:
        return 'Tipe Tidak Dikenal';
    }
  }

  String _mbtiDescription(String type) {
    switch (type) {
      case 'ISTJ':
        return 'Anda adalah pribadi yang praktis, faktual, andal, dan sangat teratur. Anda menjunjung tinggi kewajiban dan tanggung jawab.';
      case 'ISFJ':
        return 'Anda adalah pelindung yang hangat, setia, penuh perhatian, dan selalu siap membela serta melindungi orang-orang yang Anda sayangi.';
      case 'INFJ':
        return 'Anda adalah idealis visioner yang misterius namun penuh empati. Anda senang memikirkan masa depan dan membantu sesama secara mendalam.';
      case 'INTJ':
        return 'Anda adalah pemikir strategis, mandiri, dan analitis. Anda memiliki rencana cadangan untuk segala hal dan menyukai tantangan intelektual.';
      case 'ISTP':
        return 'Anda adalah pemecah masalah yang praktis, fleksibel, toleran, dan senang mempelajari cara kerja berbagai benda nyata secara langsung.';
      case 'ISFP':
        return 'Anda adalah seniman yang ramah, berjiwa bebas, sensitif, dan sangat menikmati keindahan hidup di masa kini secara damai.';
      case 'INFP':
        return 'Anda adalah mediator yang idealis, puitis, altruistik, serta selalu mencari cara terbaik untuk membawa harmoni ke dunia.';
      case 'INTP':
        return 'Anda adalah penemu kreatif yang haus akan pengetahuan. Anda menyukai pemikiran logis, teori abstrak, dan analisis mendalam.';
      case 'ESTP':
        return 'Anda adalah pengusaha yang energik, tanggap, berani mengambil risiko, serta menikmati kehidupan sosial yang dinamis.';
      case 'ESFP':
        return 'Anda adalah penghibur yang spontan, ramah, antusias, dan membawa kegembiraan bagi lingkungan sekitar Anda.';
      case 'ENFP':
        return 'Anda adalah komunikator kreatif yang bersemangat bebas, ramah, berwawasan luas, dan selalu melihat potensi positif pada orang lain.';
      case 'ENTP':
        return 'Anda adalah pendebat cerdas yang kritis, menyukai pemikiran out-of-the-box, serta senang menantang ide-ide yang sudah ada.';
      case 'ESTJ':
        return 'Anda adalah eksekutif yang cakap, tertib, andal, dan tegas dalam menegakkan prinsip serta mengorganisasi kelompok.';
      case 'ESFJ':
        return 'Anda adalah konsul sosial yang populer, sangat ramah, penuh empati, dan berdedikasi tinggi untuk melayani komunitas Anda.';
      case 'ENFJ':
        return 'Anda adalah pemimpin karismatik, inspiratif, dan persuasif. Anda memiliki kemampuan alami untuk membantu orang lain bertumbuh.';
      case 'ENTJ':
        return 'Anda adalah komandan berani, berkemauan keras, strategis, dan pemimpin alami yang andal dalam memecahkan masalah berskala besar.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Tes Kepribadian MBTI',
          style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Poppins'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: _buildBody(context, primary, isDark),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Color primary, bool isDark) {
    switch (_stage) {
      case _MBTIStage.intro:
        return _buildIntroView(primary, isDark);
      case _MBTIStage.test:
        return _buildTestView(primary, isDark);
      case _MBTIStage.result:
        return _buildResultView(primary, isDark);
    }
  }

  Widget _buildIntroView(Color primary, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  const Spacer(),
                  // Mascot representation
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: 0.1),
                      border: Border.all(color: primary.withValues(alpha: 0.2), width: 3),
                    ),
                    child: ClipOval(
                      child: Icon(
                        Icons.psychology_rounded,
                        size: 84,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Kenali Kepribadian Anda 🧠',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      'Tes ini terdiri dari 32 pertanyaan tertarget untuk menganalisis kecenderungan psikologis Anda dalam 4 dimensi kepribadian Myers-Briggs (MBTI).\n\nJawablah secara jujur dan pilih pilihan yang paling menggambarkan diri Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.8),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => setState(() => _stage = _MBTIStage.test),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Mulai Tes',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTestView(Color primary, bool isDark) {
    final progress = (_currentIdx + 1) / _questions.length;
    final q = _questions[_currentIdx];
    final currentAnswer = _answers[_currentIdx];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pertanyaan ${_currentIdx + 1} dari ${_questions.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primary,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              '${((_currentIdx + 1) / _questions.length * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primary,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(primary),
          ),
        ),
        const SizedBox(height: 36),

        // Question Card
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFF8FAFC), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  q.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Likert Scale Circles
        Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Setuju',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                        fontFamily: 'Poppins')),
                Spacer(),
                Text('Netral',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                        fontFamily: 'Poppins')),
                Spacer(),
                Text('Tidak Setuju',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent,
                        fontFamily: 'Poppins')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Sangat Setuju
                _buildLikertCircle(
                    rating: 2,
                    size: 52,
                    color: const Color(0xFF10B981),
                    active: currentAnswer == 2),
                // Setuju
                _buildLikertCircle(
                    rating: 1,
                    size: 40,
                    color: const Color(0xFF10B981).withValues(alpha: 0.7),
                    active: currentAnswer == 1),
                // Netral
                _buildLikertCircle(
                    rating: 0,
                    size: 32,
                    color: Colors.grey,
                    active: currentAnswer == 0),
                // Tidak Setuju
                _buildLikertCircle(
                    rating: -1,
                    size: 40,
                    color: Colors.redAccent.withValues(alpha: 0.7),
                    active: currentAnswer == -1),
                // Sangat Tidak Setuju
                _buildLikertCircle(
                    rating: -2,
                    size: 52,
                    color: Colors.redAccent,
                    active: currentAnswer == -2),
              ],
            ),
          ],
        ),
        const SizedBox(height: 40),

        // Navigation Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentIdx > 0)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _currentIdx--;
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Sebelumnya',
                    style: TextStyle(
                        fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              )
            else
              const SizedBox(),
            if (currentAnswer != null)
              TextButton.icon(
                onPressed: () {
                  if (_currentIdx < _questions.length - 1) {
                    setState(() {
                      _currentIdx++;
                    });
                  } else {
                    setState(() {
                      _calculateResult();
                      _stage = _MBTIStage.result;
                    });
                  }
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Berikutnya',
                    style: TextStyle(
                        fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildLikertCircle({
    required int rating,
    required double size,
    required Color color,
    required bool active,
  }) {
    return GestureDetector(
      onTap: () => _answerQuestion(rating),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color : Colors.transparent,
          border: Border.all(
            color: active ? color : color.withValues(alpha: 0.4),
            width: active ? 4 : 2.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: active
            ? const Center(
                child: Icon(Icons.check_rounded, color: Colors.white, size: 18),
              )
            : null,
      ),
    );
  }

  Widget _buildResultView(Color primary, bool isDark) {
    final title = _mbtiTitle(_mbtiResult);
    final desc = _mbtiDescription(_mbtiResult);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Mascot circle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.1),
            ),
            child: ClipOval(
              child: Icon(
                Icons.emoji_events_rounded,
                size: 52,
                color: Colors.amber[600],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kepribadian Anda adalah:',
            style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          // MBTI Result Title
          Text(
            _mbtiResult,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: primary,
              fontFamily: 'Poppins',
              letterSpacing: -1.0,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          // Short Description Box
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary.withValues(alpha: 0.12)),
            ),
            child: Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.9),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Percentage Bars
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rincian Karakteristik:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              // EI Bar
              _buildDimensionChart(
                leftLabel: 'Introvert (I)',
                rightLabel: 'Ekstrovert (E)',
                percentageLeft: 100 - _pctE,
                percentageRight: _pctE,
                colorLeft: Colors.indigo,
                colorRight: Colors.orange,
              ),
              const SizedBox(height: 16),
              // SN Bar
              _buildDimensionChart(
                leftLabel: 'Intuisi (N)',
                rightLabel: 'Sensorik (S)',
                percentageLeft: 100 - _pctS,
                percentageRight: _pctS,
                colorLeft: Colors.deepPurple,
                colorRight: Colors.amber,
              ),
              const SizedBox(height: 16),
              // TF Bar
              _buildDimensionChart(
                leftLabel: 'Perasa (F)',
                rightLabel: 'Pemikir (T)',
                percentageLeft: 100 - _pctT,
                percentageRight: _pctT,
                colorLeft: Colors.pinkAccent,
                colorRight: Colors.teal,
              ),
              const SizedBox(height: 16),
              // JP Bar
              _buildDimensionChart(
                leftLabel: 'Spontan (P)',
                rightLabel: 'Terencana (J)',
                percentageLeft: 100 - _pctJ,
                percentageRight: _pctJ,
                colorLeft: Colors.cyan,
                colorRight: Colors.brown,
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () async {
                // Save results to provider and Supabase
                final provider =
                    Provider.of<ActivityProvider>(context, listen: false);
                await provider.updateMBTI(_mbtiResult);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Kepribadian $_mbtiResult berhasil disimpan ke profil!'),
                  ),
                );
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Simpan ke Profil',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins'),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDimensionChart({
    required String leftLabel,
    required String rightLabel,
    required double percentageLeft,
    required double percentageRight,
    required Color colorLeft,
    required Color colorRight,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$leftLabel (${percentageLeft.round()}%)',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins'),
            ),
            Text(
              '(${percentageRight.round()}%) $rightLabel',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            // Left progress bar
            Expanded(
              flex: percentageLeft.round() == 0 ? 1 : percentageLeft.round(),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: colorLeft,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(4)),
                ),
              ),
            ),
            // Middle separator/divider (optional)
            Container(
                width: 1.5,
                height: 8,
                color: Colors.white.withValues(alpha: 0.6)),
            // Right progress bar
            Expanded(
              flex: percentageRight.round() == 0 ? 1 : percentageRight.round(),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: colorRight,
                  borderRadius:
                      const BorderRadius.horizontal(right: Radius.circular(4)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
