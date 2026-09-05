import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../inti/tema/design_tokens.dart';
import '../penyedia/penyedia_aktivitas.dart';
import 'layar_detail_program.dart';
import 'layar_meditasi.dart';
import 'widget_kalender_kehamilan.dart';

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen>
    with TickerProviderStateMixin {
  TabController? _tabCtrl;
  int _lastTabLength = 0;

  void _syncTabController(int length) {
    if (_tabCtrl != null && _lastTabLength == length) return;
    _tabCtrl?.dispose();
    _lastTabLength = length;
    _tabCtrl = TabController(length: length, vsync: this);
    _tabCtrl!.addListener(() {
      if (!_tabCtrl!.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFemale = context.watch<ActivityProvider>().gender == 'Wanita';
    final tabCount = isFemale ? 4 : 3;
    _syncTabController(tabCount);
    final ctrl = _tabCtrl!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Program',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.titleLarge?.color)),
        actions: [
          Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Image.asset(
              'assets/images/logo_brin.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: TabBar(
            controller: ctrl,
            dividerColor: Colors.transparent,
            indicatorColor: Colors.transparent,
            indicator: const BoxDecoration(),
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: theme.hintColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            onTap: (index) {
              setState(() {}); // Trigger rebuild instan saat tap
            },
            tabs: [
              _buildTab(0, '🥗 Diet'),
              _buildTab(1, '🎉 Event'),
              _buildTab(2, '🧘 Meditasi'),
              if (isFemale) _buildTab(3, '🌸 Kesehatan Wanita'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: ctrl,
        children: [
          const _DietTab(),
          const _EventTab(),
          const _MeditationTab(),
          if (isFemale) const PregnancyCalendarTab(),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isActive = (_tabCtrl?.index ?? 0) == index;
    return Tab(
      height: 48,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive ? Colors.white : Theme.of(context).hintColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _DietTab extends StatelessWidget {
  const _DietTab();
  static const _diets = [
    {
      'emoji': '🌿',
      'name': 'Mediterranean',
      'cal': 1800,
      'badge': 'TERPOPULER',
      'badgeColor': AppColors.success,
      'desc': 'Kaya sayuran, ikan, minyak zaitun. Proteksi jantung optimal.',
      'longDesc':
          'Diet Mediterania didasarkan pada makanan tradisional masyarakat sekitar Laut Mediterania. Diet ini menekankan konsumsi sayuran, buah-buahan, biji-bijian utuh, kacang-kacangan, ikan, dan minyak zaitun ekstra perawan, dengan batasan asupan daging merah dan gula.\n\nSangat baik untuk menjaga kolesterol, tekanan darah, dan kesehatan jantung jangka panjang.',
      'allowed':
          'Sayuran segar, ikan laut kaya omega-3, minyak zaitun murni, kacang kenari, buah utuh.',
      'avoid':
          'Gula tambahan, daging olahan, karbohidrat rafinasi, dan minyak bunga matahari olahan.'
    },
    {
      'emoji': '🥑',
      'name': 'Keto Diet',
      'cal': 1600,
      'badge': 'TRENDING',
      'badgeColor': AppColors.warning,
      'desc': 'Sangat rendah karbohidrat. Penurunan berat badan cepat.',
      'longDesc':
          'Diet Ketogenik berfokus pada asupan lemak tinggi dan karbohidrat sangat rendah. Hal ini memaksa tubuh masuk ke status metabolik "Ketosis", di mana tubuh menjadi sangat efisien dalam membakar lemak menjadi energi.\n\nCocok untuk penurunan berat badan drastis dalam waktu singkat, namun butuh kedisiplinan makro-nutrien.',
      'allowed':
          'Daging segar, telur, mentega murni, keju murni, ikan berlemak, dan alpukat.',
      'avoid': 'Nasi, roti, pasta, gula, minuman manis, dan buah tinggi gula.'
    },
    {
      'emoji': '🥦',
      'name': 'Intermittent Fasting',
      'cal': 1700,
      'badge': '',
      'badgeColor': Colors.transparent,
      'desc': 'Pola makan 16:8. Fokus pada jendela makan.',
      'longDesc':
          'Intermittent Fasting (IF) adalah pola makan berbasis waktu: Anda membatasi waktu makan pada jendela tertentu. Metode populer adalah 16:8 (puasa 16 jam, makan dalam 8 jam).\n\nCatatan: manfaat IF sangat bergantung pada kualitas makanan, porsi, dan konsistensi. Jika punya kondisi medis (misalnya diabetes, hamil, atau gangguan makan), sebaiknya konsultasi tenaga kesehatan sebelum mencoba.',
      'referencesTags': ['fasting', 'diet', 'sugar', 'activity'],
      'allowed':
          'Saat jendela makan: Pola makan seimbang sehat (sayur, protein, karbo kompleks).',
      'avoid':
          'Saat jendela puasa: Dilarang mengonsumsi apapun yang berkalori. Hanya air putih, kopi/teh tanpa gula yang diizinkan.'
    },
    {
      'emoji': '🌾',
      'name': 'Whole Food Plant',
      'cal': 1900,
      'badge': 'BARU',
      'badgeColor': AppColors.info,
      'desc': 'Berbasis tanaman utuh. Ramah lingkungan & kesehatan.',
      'longDesc':
          'Diet Berbasis Tanaman Utuh (WFPB) menekankan konsumsi makanan dari tanaman yang tidak melalui atau hanya sedikit proses pengolahan kimia. Diet ini sangat etis dan juga terbukti membalikkan beberapa risiko penyakit kronis.\n\nSangat mengandalkan sayuran, oat, quinoa, dan berbagai macam kacang-kacangan.',
      'allowed':
          'Gandum utuh, polong-polongan, umbi-umbian, sayur mayur lokal, dan jamur.',
      'avoid':
          'Segala bentuk daging hewani, susu sapi/turunannya, dan makanan nabati hasil olahan pabrik (seperti sosis vegan instan).'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _diets.length,
      itemBuilder: (context, i) {
        final d = _diets[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: Theme.of(context)
                          .extension<AppThemeExtension>()
                          ?.gradientCard ??
                      AppColors.gradientCard),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color:
                      Theme.of(context).dividerColor.withValues(alpha: 0.1))),
          child: InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ProgramDetailScreen(data: d, type: 'diet')));
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(d['emoji'].toString(),
                      style: const TextStyle(fontSize: 38)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(d['name'].toString(),
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.color,
                                    fontFamily: 'Poppins'),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (d['badge'].toString().isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: (d['badgeColor'] as Color)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(d['badge'].toString(),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: d['badgeColor'] as Color)),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 4),
                        Text(d['desc'].toString(),
                            textAlign: TextAlign.start,
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                                height: 1.4)),
                        const SizedBox(height: 8),
                        Text('Target: ${d['cal']} kkal/hari',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context)
                                        .extension<AppThemeExtension>()
                                        ?.warning ??
                                    AppColors.warning)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 72,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ]),
                      child: const Center(
                        child: Text('Pilih',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EventTab extends StatelessWidget {
  const _EventTab();
  static const _events = [
    {
      'emoji': '🏃',
      'title': '5K Run Jakarta',
      'date': '1 Mar 2026',
      'loc': 'GBK, Jakarta',
      'type': 'Lari',
      'desc':
          'Ajang lari santai tahunan yang diselenggarakan di jantung ibukota. Cocok untuk semua umur dan tingkat kebugaran mulai dari pemula hingga profesional. Raih medali finisher eksklusif dan nikmati festival di garis finish.',
      'rundown':
          '05:30 - Gate Buka & Pengambilan Race Pack\n06:00 - Pemanasan Massal (Zumba)\n06:30 - Flag Off Kategori 5K\n07:30 - Cut Off Time (COT)\n08:00 - Hiburan & Hadiah Doorprice'
    },
    {
      'emoji': '🧘',
      'title': 'Yoga in the Park',
      'date': '5 Mar 2026',
      'loc': 'Taman Suropati',
      'type': 'Yoga',
      'desc':
          'Rasakan ketenangan batin melalui kelas yoga terbuka (outdoor) bersama instruktur profesional. Terhubung dengan alam, udara pagi, dan sesama praktisi. Bawa matras sendiri.',
      'rundown':
          '06:00 - Regristrasi & Penempatan Matras\n06:30 - Meditasi Awal & Grounding\n07:00 - Vinyasa Flow (Intensitas Menengah)\n08:00 - Savasana\n08:30 - Sesi Berbagi Edukasi Holistik'
    },
    {
      'emoji': '🚴',
      'title': 'Cycling Clean City',
      'date': '15 Mar 2026',
      'loc': 'Jl. Sudirman',
      'type': 'Bersepeda',
      'desc':
          'Kampanye hari bebas kendaraan bermotor dengan berkeliling ibukota sejauh 15 kilometer menunggangi sepeda favorit Anda. Mendukung gerakan Nol Karbon 2030.',
      'rundown':
          '05:30 - Kumpul di Bundaran HI\n06:00 - Briefing Keamanan Rute\n06:15 - Ride Dimulai (Pace Santai 15-20 km/j)\n08:00 - Tiba di Finish (Monas)\n08:30 - Kampanye Penanaman Pohon'
    },
    {
      'emoji': '🫀',
      'title': 'CERDIK Challenge 30 Hari',
      'date': 'Mulai kapan saja',
      'loc': 'Di rumah / kantor',
      'type': 'Kampanye',
      'desc':
          'Tantangan kebiasaan sehat berbasis CERDIK: cek kesehatan berkala, berhenti merokok, aktivitas fisik, diet seimbang, istirahat cukup, kelola stres.',
      'rundown':
          'Hari 1: ukur berat/tinggi/lingkar perut\nHari 2: jalan cepat 30 menit\nHari 3: ganti minuman manis jadi air\n... lanjutkan pola kecil konsisten tiap hari',
      'referencesTags': ['cerdik', 'campaign', 'activity', 'sugar', 'diabetes']
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _events.length,
      itemBuilder: (context, i) {
        final e = _events[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: Theme.of(context)
                          .extension<AppThemeExtension>()
                          ?.gradientCard ??
                      AppColors.gradientCard),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color:
                      Theme.of(context).dividerColor.withValues(alpha: 0.1))),
          child: InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ProgramDetailScreen(data: e, type: 'event')));
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(e['emoji'].toString(),
                      style: const TextStyle(fontSize: 38)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e['title'].toString(),
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.color,
                              fontFamily: 'Poppins')),
                      const SizedBox(height: 4),
                      Text('📅 ${e['date']}  📍 ${e['loc']}',
                          style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color)),
                    ],
                  )),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 72,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ]),
                      child: const Center(
                        child: Text('Daftar',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MeditationTab extends StatelessWidget {
  const _MeditationTab();
  static const _meds = [
    {
      'emoji': '🌅',
      'title': 'Meditasi Pagi',
      'duration': '10 menit',
      'level': 'Pemula',
      'desc':
          'Mulai hari dengan ketenangan dan fokus positif. Latihan pernapasan sederhana yang dirancang untuk membuka hari Anda dengan kejernihan pikiran.'
    },
    {
      'emoji': '💼',
      'title': 'Breath for Focus',
      'duration': '5 menit',
      'level': 'Semua',
      'desc':
          'Teknik pernapasan 4-7-8 untuk meningkatkan konsentrasi. Cocok dilakukan di sela-sela jam kerja atau saat merasa buntu.'
    },
    {
      'emoji': '🌙',
      'title': 'Sleep Meditation',
      'duration': '20 menit',
      'level': 'Semua',
      'desc':
          'Relaksasi tubuh sedalam-dalamnya dan pikiran sebelum tidur. Ikuti alunan nafas untuk mengantarkan gelombang otak masuk ke fase delta.'
    },
    {
      'emoji': '😰',
      'title': 'Anxiety Relief',
      'duration': '15 menit',
      'level': 'Menengah',
      'desc':
          'Turunkan kadar kortisol secara ilmiah dengan pernapasan perut. Membantu menenangkan sistem saraf yang sedang tegang dalam hitungan menit.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _meds.length,
      itemBuilder: (context, i) {
        final m = _meds[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: Theme.of(context)
                          .extension<AppThemeExtension>()
                          ?.gradientCard ??
                      AppColors.gradientCard),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color:
                      Theme.of(context).dividerColor.withValues(alpha: 0.1))),
          child: InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MeditationScreen(data: m)));
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(m['emoji'].toString(),
                      style: const TextStyle(fontSize: 38)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['title'].toString(),
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.color,
                              fontFamily: 'Poppins')),
                      const SizedBox(height: 4),
                      Text(m['desc'].toString(),
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              fontSize: 13,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                              height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text('⏱ ${m['duration']}  •  🏷 ${m['level']}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.color)),
                    ],
                  )),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 72,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ]),
                      child: const Center(
                        child: Text('Mulai',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
