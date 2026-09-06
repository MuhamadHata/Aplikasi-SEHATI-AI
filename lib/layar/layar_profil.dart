import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../inti/tema/design_tokens.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../inti/tema/ikon_mapper.dart';
import '../inti/layanan/layanan_autentikasi.dart';
import '../penyedia/penyedia_aktivitas.dart';
import '../penyedia/penyedia_tema.dart';
import '../komponen/progres_lingkaran.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notif = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().loadProfile();
    });
  }

  Future<void> _pickImage() async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 90,
      maxWidth: 512,
      maxHeight: 512,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Atur Ukuran Foto',
          toolbarColor: primaryColor,
          toolbarWidgetColor: Colors.white,
          backgroundColor: Colors.black,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          showCropGrid: true,
        ),
        IOSUiSettings(
          title: 'Atur Ukuran Foto',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile == null) return;
    if (!mounted) return;

    final file = File(croppedFile.path);
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage.from('avatars').upload(
          path, file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true));
      final url = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(path);
      if (!mounted) return;
      await context.read<ActivityProvider>().updateProfile(photoUrl: url);
    }
  }

  void _showEditProfile() {
    final provider = context.read<ActivityProvider>();
    final nameCtrl = TextEditingController(text: provider.userName);
    final wCtrl = TextEditingController(text: provider.weight.toString());
    final hCtrl = TextEditingController(text: provider.heightCm.toString());
    final aCtrl = TextEditingController(text: provider.age.toString());
    String selectedGender = provider.gender;
    String smokingStatus = provider.smokingStatus;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                20,
            left: 20,
            right: 20,
            top: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Profil',
                style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color)),
            const SizedBox(height: 16),
            TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    labelStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color)),
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
                keyboardType: TextInputType.text),
            const SizedBox(height: 12),
            TextField(
                controller: hCtrl,
                decoration: InputDecoration(
                    labelText: 'Tinggi Badan (cm)',
                    labelStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color)),
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(
                controller: wCtrl,
                decoration: InputDecoration(
                    labelText: 'Berat Badan (kg)',
                    labelStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color)),
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(
                controller: aCtrl,
                decoration: InputDecoration(
                    labelText: 'Usia',
                    labelStyle: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color)),
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedGender,
              decoration: InputDecoration(
                  labelText: 'Jenis Kelamin',
                  labelStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color)),
              dropdownColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color),
              items: ['Pria', 'Wanita'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) selectedGender = newValue;
              },
            ),
            const SizedBox(height: 12),
            StatefulBuilder(builder: (ctx, setSt) {
              return DropdownButtonFormField<String>(
                initialValue: smokingStatus,
                decoration: const InputDecoration(
                  labelText: 'Status Merokok',
                ),
                items: const [
                  DropdownMenuItem(
                    value: ActivityProvider.smokingStatusNone,
                    child: Text('Tidak merokok'),
                  ),
                  DropdownMenuItem(
                    value: ActivityProvider.smokingStatusActive,
                    child: Text('Merokok'),
                  ),
                  DropdownMenuItem(
                    value: ActivityProvider.smokingStatusPassive,
                    child: Text('Sering terpapar asap rokok dari orang lain'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setSt(() => smokingStatus = value);
                },
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  final name = nameCtrl.text;
                  final h = double.tryParse(hCtrl.text) ?? provider.heightCm;
                  final w = double.tryParse(wCtrl.text) ?? provider.weight;
                  final a = int.tryParse(aCtrl.text) ?? provider.age;

                  await context.read<ActivityProvider>().updateProfile(
                        name: name,
                        height: h,
                        weight: w,
                        age: a,
                        gender: selectedGender,
                        smokingStatus: smokingStatus,
                      );

                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Simpan',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSleepLogger() {
    // Default: tidur 22:00, bangun 05:30
    int bedtimeMin = 22 * 60;
    int wakeMin = 5 * 60 + 30;

    String fmt(int totalMin) {
      final h = (totalMin ~/ 60).toString().padLeft(2, '0');
      final m = (totalMin % 60).toString().padLeft(2, '0');
      return '$h:$m';
    }

    double calcDur(int bed, int wake) {
      if (wake > bed) return (wake - bed) / 60.0;
      return ((1440 - bed) + wake) / 60.0;
    }

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setSt) {
        final dur = calcDur(bedtimeMin, wakeMin);
        final durH = (dur).floor();
        final durM = ((dur - durH) * 60).round();
        final isOk = dur >= 7;

        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx2).viewInsets.bottom +
                  MediaQuery.of(ctx2).padding.bottom +
                  16,
              left: 20,
              right: 20,
              top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Catat Jam Tidur',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Tekan jam untuk memilih waktu tidur & bangun',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx2).textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final h = bedtimeMin ~/ 60;
                        final m = bedtimeMin % 60;
                        final t = await showTimePicker(
                          context: ctx2,
                          initialTime: TimeOfDay(hour: h, minute: m),
                          helpText: 'Jam Tidur',
                        );
                        if (t != null) {
                          setSt(() => bedtimeMin = t.hour * 60 + t.minute);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(ctx2)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Theme.of(ctx2).colorScheme.primary,
                              width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bedtime_outlined, size: 14),
                                SizedBox(width: 4),
                                Text('Jam Tidur',
                                    style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(fmt(bedtimeMin),
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Poppins',
                                    color:
                                        Theme.of(ctx2).colorScheme.primary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.arrow_forward, size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final h = wakeMin ~/ 60;
                        final m = wakeMin % 60;
                        final t = await showTimePicker(
                          context: ctx2,
                          initialTime: TimeOfDay(hour: h, minute: m),
                          helpText: 'Jam Bangun',
                        );
                        if (t != null) {
                          setSt(() => wakeMin = t.hour * 60 + t.minute);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF10B981), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Text('Jam Bangun',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text(fmt(wakeMin),
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF10B981))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Duration badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: (isOk ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                        color: isOk
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444)),
                  ),
                  child: Text(
                    isOk
                        ? '⭐ ${durH}j ${durM}m — Tidur Cukup!'
                        : '⚠️ ${durH}j ${durM}m — Kurang dari 7 jam',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isOk
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(ctx2).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  onPressed: () async {
                    await context
                        .read<ActivityProvider>()
                        .addSleepRecord(bedtimeMin, wakeMin);
                    if (ctx2.mounted) Navigator.pop(ctx2);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '✅ Tidur ${durH}j ${durM}m berhasil dicatat!'),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  child: const Text('Simpan Jam Tidur',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final userName = provider.userName;
    final photoUrl = provider.photoUrl;
    final weight = provider.weight;
    final heightCm = provider.heightCm;
    final age = provider.age;
    final gender = provider.gender;
    final bmi = provider.bmi;

    // Weekly calories: computed from realtime provider data (Firestore streams + local prefs).
    String ymd(DateTime d) {
      final yyyy = d.year.toString().padLeft(4, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final dd = d.day.toString().padLeft(2, '0');
      return '$yyyy-$mm-$dd';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final byDate = <String, double>{
      for (final s in provider.dailySummaries)
        s.date: s.caloriesConsumed.toDouble(),
    };

    final weeklyData = List<double>.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      final key = ymd(d);
      if (d == today) return provider.calorieConsumed.toDouble();
      return byDate[key] ?? 0.0;
    });

    const weekDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final maxVal = math.max(weeklyData.reduce(math.max), 1.0);
    final todayIndex = today.weekday - 1; // Sen=0 ... Min=6

    final double idealWeight = gender == 'Pria'
        ? (heightCm - 100) - ((heightCm - 100) * 0.1)
        : (heightCm - 100) - ((heightCm - 100) * 0.15);
    final double weightProgress =
        weight <= 0 ? 0.0 : (idealWeight / weight).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => context.read<ActivityProvider>().refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.2),
                    Theme.of(context).scaffoldBackgroundColor
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                ),
                padding: const EdgeInsets.fromLTRB(20, 55, 20, 24),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar with camera/edit badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: Theme.of(context)
                                              .extension<AppThemeExtension>()
                                              ?.gradientPrimary ??
                                          AppColors.gradientPrimary),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.25),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.18),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                  image: photoUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(photoUrl),
                                          fit: BoxFit.cover)
                                      : null,
                                ),
                                child: photoUrl == null
                                    ? const Center(
                                        child: Icon(Icons.person_rounded,
                                            size: 38, color: Colors.white))
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(4.5),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        // Name and Badges (Email removed as requested)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      userName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.color,
                                        fontFamily: 'Poppins',
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  if (provider.mbti != null &&
                                      provider.mbti!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => Navigator.pushNamed(
                                          context, '/tes-mbti'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('🧠 ',
                                                style:
                                                    TextStyle(fontSize: 9)),
                                            Text(
                                              provider.mbti!.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                fontFamily: 'Poppins',
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _BadgeChip(
                                      label: '🥗 Diet Aktif',
                                      color: Theme.of(context)
                                              .extension<AppThemeExtension>()
                                              ?.success ??
                                          AppColors.success),
                                  _BadgeChip(
                                      label: '🎯 Konsisten 7 Hari',
                                      color: Theme.of(context)
                                              .extension<AppThemeExtension>()
                                              ?.warning ??
                                          AppColors.warning),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // BRIN Logo & Edit Button
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .dividerColor
                                      .withValues(alpha: 0.12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo_brin.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showEditProfile,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Theme.of(context)
                                              .dividerColor
                                              .withValues(alpha: 0.12))),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 13,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text('Edit',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                  delegate: SliverChildListDelegate([
                // Body stats (Compact, balanced 2x2 grid)
                Row(children: [
                  _BodyStatCard(
                    label: 'Tinggi',
                    value: '$heightCm',
                    unit: 'cm',
                    emoji: '📏',
                    icon: Icons.straighten_rounded,
                    color: const Color(0xFF6366F1), // Indigo
                    onTap: _showEditProfile,
                  ),
                  const SizedBox(width: 10),
                  _BodyStatCard(
                    label: 'Berat',
                    value: '$weight',
                    unit: 'kg',
                    emoji: '⚖️',
                    icon: Icons.monitor_weight_outlined,
                    color: const Color(0xFF0284C7), // Sky Blue
                    onTap: _showEditProfile,
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _BodyStatCard(
                    label: 'Usia',
                    value: '$age',
                    unit: 'thn',
                    emoji: '🎂',
                    icon: Icons.cake_outlined,
                    color: const Color(0xFFD97706), // Amber
                    onTap: _showEditProfile,
                  ),
                  const SizedBox(width: 10),
                  _BodyStatCard(
                    label: 'Gender',
                    value: gender,
                    unit: '',
                    emoji: gender == 'Pria' ? '👨' : '👩',
                    icon: gender == 'Pria'
                        ? Icons.male_rounded
                        : Icons.female_rounded,
                    color: gender == 'Pria'
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFEC4899),
                    onTap: _showEditProfile,
                  ),
                ]),
                const SizedBox(height: 20),
                // BMI
                const _SectionTitle('Indeks Massa Tubuh'),
                Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: Theme.of(context)
                                  .extension<AppThemeExtension>()
                                  ?.gradientCard ??
                              AppColors.gradientCard),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.1))),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      RingProgress(
                          size: 110,
                          progress: (bmi - 14) / (36 - 14),
                          color: bmi < 18.5
                              ? (Theme.of(context)
                                      .extension<AppThemeExtension>()
                                      ?.info ??
                                  AppColors.info)
                              : bmi < 25
                                  ? (Theme.of(context)
                                          .extension<AppThemeExtension>()
                                          ?.success ??
                                      AppColors.success)
                                  : bmi < 30
                                      ? (Theme.of(context)
                                              .extension<AppThemeExtension>()
                                              ?.warning ??
                                          AppColors.warning)
                                      : Theme.of(context).colorScheme.secondary,
                          strokeWidth: 12,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(bmi.toStringAsFixed(1),
                                  style: TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w700,
                                      color: bmi < 18.5
                                          ? (Theme.of(context)
                                                  .extension<
                                                      AppThemeExtension>()
                                                  ?.info ??
                                              AppColors.info)
                                          : bmi < 25
                                              ? (Theme.of(context)
                                                      .extension<
                                                          AppThemeExtension>()
                                                      ?.success ??
                                                  AppColors.success)
                                              : bmi < 30
                                                  ? (Theme.of(context)
                                                          .extension<
                                                              AppThemeExtension>()
                                                          ?.warning ??
                                                      AppColors.warning)
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                      fontFamily: 'Poppins')),
                              Text('BMI',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color)),
                            ],
                          )),
                      const SizedBox(width: 20),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: bmi < 18.5
                                      ? (Theme.of(context)
                                              .extension<AppThemeExtension>()
                                              ?.info ??
                                          AppColors.info)
                                      : bmi < 25
                                          ? (Theme.of(context)
                                                  .extension<
                                                      AppThemeExtension>()
                                                  ?.success ??
                                              AppColors.success)
                                          : bmi < 30
                                              ? (Theme.of(context)
                                                      .extension<
                                                          AppThemeExtension>()
                                                      ?.warning ??
                                                  AppColors.warning)
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(
                                bmi < 18.5
                                    ? 'Underweight'
                                    : bmi < 25
                                        ? 'Normal'
                                        : bmi < 30
                                            ? 'Overweight'
                                            : 'Obese',
                                style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w700,
                                    color: bmi < 18.5
                                        ? (Theme.of(context)
                                                .extension<AppThemeExtension>()
                                                ?.info ??
                                            AppColors.info)
                                        : bmi < 25
                                            ? (Theme.of(context)
                                                    .extension<
                                                        AppThemeExtension>()
                                                    ?.success ??
                                                AppColors.success)
                                            : bmi < 30
                                                ? (Theme.of(context)
                                                        .extension<
                                                            AppThemeExtension>()
                                                        ?.warning ??
                                                    AppColors.warning)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                    fontFamily: 'Poppins')),
                          ]),
                          const SizedBox(height: 10),
                          _BmiRange(
                              label: 'Kurang',
                              range: '< 18.5',
                              color: Theme.of(context)
                                      .extension<AppThemeExtension>()
                                      ?.info ??
                                  AppColors.info),
                          _BmiRange(
                              label: 'Normal',
                              range: '18.5 – 24.9',
                              color: Theme.of(context)
                                      .extension<AppThemeExtension>()
                                      ?.success ??
                                  AppColors.success),
                          _BmiRange(
                              label: 'Lebih',
                              range: '25 – 29.9',
                              color: Theme.of(context)
                                      .extension<AppThemeExtension>()
                                      ?.warning ??
                                  AppColors.warning),
                          _BmiRange(
                              label: 'Obese',
                              range: '≥ 30',
                              color: Theme.of(context).colorScheme.secondary),
                        ],
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Health Score Card
                const _SectionTitle('Health Score'),
                const _HealthScoreCard(),
                const SizedBox(height: 20),

                // Sleep Logger Card
                const _SectionTitle('Catat Jam Tidur'),
                _SleepLogCard(onLog: _showSleepLogger),
                const SizedBox(height: 20),

                // Weekly chart
                const _SectionTitle('Kalori Mingguan'),
                Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.08)),
                      boxShadow: Theme.of(context).brightness == Brightness.dark
                          ? []
                          : [
                              const BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 12,
                                offset: Offset(0, 3),
                              ),
                            ]),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chart header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Avg ${(weeklyData.reduce((a, b) => a + b) / 7).round()} kkal/hari',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.labelSmall?.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: AppColors.gradientPrimary,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text('Hari ini',
                                style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: math.max(maxVal, 1.0) * 1.35,
                            minY: 0,
                            barGroups: List.generate(7, (i) {
                              final val = weeklyData[i];
                              final isToday = i == todayIndex;
                              final isDark = Theme.of(context).brightness ==
                                  Brightness.dark;
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: val,
                                    gradient: LinearGradient(
                                      colors: isToday
                                          ? AppColors.gradientPrimary
                                          : isDark
                                              ? [
                                                  const Color(0xFF334155),
                                                  const Color(0xFF475569)
                                                ]
                                              : [
                                                  const Color(0xFFCBD5E1),
                                                  const Color(0xFFE2E8F0)
                                                ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    width: 22,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(7),
                                      bottom: Radius.circular(3),
                                    ),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: math.max(maxVal, 1.0) * 1.35,
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withValues(alpha: 0.06),
                                    ),
                                  ),
                                ],
                              );
                            }),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i < 0 || i >= weekDays.length) {
                                      return const SizedBox();
                                    }
                                    final isToday = i == todayIndex;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        weekDays[i],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isToday
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isToday
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.color,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 38,
                                  interval: math.max(
                                      (maxVal / 3).roundToDouble(), 1.0),
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) return const SizedBox();
                                    return Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 6),
                                        child: Text(
                                          value >= 1000
                                              ? '${(value / 1000).toStringAsFixed(1)}k'
                                              : value.round().toString(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.color,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval:
                                  math.max((maxVal / 3).roundToDouble(), 1.0),
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.12),
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) =>
                                    Theme.of(context).colorScheme.primary,
                                tooltipRoundedRadius: 8,
                                tooltipPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    '${rod.toY.round()}\nkkal',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      height: 1.4,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOutCubic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Goals
                const _SectionTitle('Target Kesehatan'),
                _GoalItem(
                    label: 'Berat Badan Ideal',
                    sublabel: 'Target ${idealWeight.round()} kg',
                    emoji: '⚖️',
                    value: '${idealWeight.round()} kg',
                    progress: weightProgress,
                    color: Theme.of(context).colorScheme.primary,
                    showValueAsSuffix: true),
                const SizedBox(height: 10),
                // ── Langkah Harian (Interaktif) ──
                Builder(builder: (ctx) {
                  final ap = ctx.watch<ActivityProvider>();
                  final stepsDone = ap.steps;
                  final stepGoal = ap.stepTarget;
                  final stepPct = (stepsDone / stepGoal).clamp(0.0, 1.0);
                  return GestureDetector(
                    onTap: () async {
                      final ctrl = TextEditingController(text: '$stepGoal');
                      final result = await showDialog<int>(
                        context: ctx,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          title: const Text('Target Langkah Harian',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Masukkan target langkah per hari:',
                                  style: TextStyle(
                                      fontFamily: 'Poppins', fontSize: 13)),
                              const SizedBox(height: 12),
                              TextField(
                                controller: ctrl,
                                keyboardType: TextInputType.number,
                                autofocus: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  hintText: 'Contoh: 10000',
                                  suffixText: 'langkah',
                                ),
                                style: const TextStyle(fontFamily: 'Poppins'),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [2000, 5000, 7000, 10000]
                                    .map(
                                      (v) => ActionChip(
                                        label: Text('${v ~/ 1000}K',
                                            style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12)),
                                        onPressed: () => ctrl.text = '$v',
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Batal'),
                            ),
                            FilledButton(
                              onPressed: () {
                                final v = int.tryParse(ctrl.text);
                                if (v != null) Navigator.pop(ctx, v);
                              },
                              child: const Text('Simpan'),
                            ),
                          ],
                        ),
                      );
                      if (result != null && ctx.mounted) {
                        await ctx
                            .read<ActivityProvider>()
                            .updateStepTarget(result);
                      }
                    },
                    child: _GoalItem(
                        label: 'Langkah Harian',
                        sublabel: 'Target $stepGoal langkah • Ketuk untuk ubah',
                        emoji: '👟',
                        value: '$stepsDone / $stepGoal',
                        progress: stepPct,
                        color: Theme.of(ctx)
                                .extension<AppThemeExtension>()
                                ?.success ??
                            AppColors.success),
                  );
                }),
                const SizedBox(height: 10),
                // ── Konsumsi Air (Interaktif) ──
                Builder(builder: (ctx) {
                  final ap = ctx.watch<ActivityProvider>();
                  final waterDone = ap.waterGlasses;
                  final waterGoal = ap.waterTarget;
                  final waterPct = (waterDone / waterGoal).clamp(0.0, 1.0);
                  return GestureDetector(
                    onTap: () async {
                      final ctrl = TextEditingController(text: '$waterGoal');
                      final result = await showDialog<int>(
                        context: ctx,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          title: const Text('Target Konsumsi Air',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Masukkan target gelas air per hari:',
                                  style: TextStyle(
                                      fontFamily: 'Poppins', fontSize: 13)),
                              const SizedBox(height: 12),
                              TextField(
                                controller: ctrl,
                                keyboardType: TextInputType.number,
                                autofocus: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  hintText: 'Contoh: 8',
                                  suffixText: 'gelas',
                                ),
                                style: const TextStyle(fontFamily: 'Poppins'),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [6, 8, 10, 12]
                                    .map(
                                      (v) => ActionChip(
                                        label: Text('$v gelas',
                                            style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12)),
                                        onPressed: () => ctrl.text = '$v',
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Batal'),
                            ),
                            FilledButton(
                              onPressed: () {
                                final v = int.tryParse(ctrl.text);
                                if (v != null) Navigator.pop(ctx, v);
                              },
                              child: const Text('Simpan'),
                            ),
                          ],
                        ),
                      );
                      if (result != null && ctx.mounted) {
                        await ctx
                            .read<ActivityProvider>()
                            .updateWaterTarget(result);
                      }
                    },
                    child: _GoalItem(
                        label: 'Konsumsi Air',
                        sublabel: 'Target $waterGoal gelas • Ketuk untuk ubah',
                        emoji: '💧',
                        value: '$waterDone / $waterGoal gelas',
                        progress: waterPct,
                        color: Theme.of(ctx)
                                .extension<AppThemeExtension>()
                                ?.info ??
                            AppColors.info),
                  );
                }),
                const SizedBox(height: 20),

                // Settings
                const _SectionTitle('Pengaturan'),
                _SettingSwitch(
                    icon: '🔔',
                    label: 'Notifikasi Harian',
                    value: _notif,
                    onChanged: (v) => setState(() => _notif = v)),
                const SizedBox(height: 8),
                _SettingSwitch(
                    icon: '🌙',
                    label: 'Mode Gelap',
                    value: context.watch<ThemeProvider>().isDarkMode,
                    onChanged: (v) =>
                        context.read<ThemeProvider>().toggleTheme(v)),
                const SizedBox(height: 8),
                _SettingAction(
                  icon: 'IF',
                  label: 'Mode Puasa',
                  valueText: _fastingModeLabel(
                      context.watch<ActivityProvider>().fastingMode),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      useSafeArea: true,
                      showDragHandle: true,
                      builder: (_) => _FastingModeSheet(
                        provider: context.read<ActivityProvider>(),
                        current: context.read<ActivityProvider>().fastingMode,
                        onPick: (m) =>
                            context.read<ActivityProvider>().setFastingMode(m),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _SettingAction(
                  icon: '🧠',
                  label: 'Tipe Kepribadian (MBTI)',
                  valueText: context.watch<ActivityProvider>().mbti ?? 'Belum Tes',
                  onTap: () => Navigator.pushNamed(context, '/tes-mbti'),
                ),
                if (context.watch<ActivityProvider>().gender == 'Wanita') ...[
                  const SizedBox(height: 8),
                  _SettingAction(
                    icon: '🌸',
                    label: 'Kalender Kehamilan & Menstruasi',
                    valueText: context.watch<ActivityProvider>().isPregnancyConfigured
                        ? 'Aktif'
                        : 'Atur',
                    onTap: () => Navigator.pushNamed(context, '/pregnancy-calendar'),
                  ),
                ],
                const SizedBox(height: 8),
                _SettingAction(
                  icon: '📈',
                  label: 'Tren & Trajektori Kesehatan',
                  valueText: 'Buka',
                  onTap: () => Navigator.pushNamed(context, '/health-trends'),
                ),
                const SizedBox(height: 8),
                _SettingAction(
                  icon: 'ℹ️',
                  label: 'About',
                  valueText: 'Paten & Tim',
                  onTap: () => Navigator.pushNamed(context, '/about'),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    await AuthService().signOut();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/auth');
                    }
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.35),
                      ),
                    ),
                    child: Center(
                        child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Text('Keluar',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.error,
                                fontFamily: 'Poppins')),
                      ],
                    )),
                  ),
                ),
                const SizedBox(height: 100),
              ])),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontFamily: 'Poppins',
                letterSpacing: -0.2)),
      );
}

class _BodyStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String emoji;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  const _BodyStatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.emoji,
    this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = color ?? Theme.of(context).colorScheme.primary;
    final effectiveIcon = icon ?? IkonMapper.dariEmoji(emoji);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context)
                    .dividerColor
                    .withValues(alpha: isDark ? 0.15 : 0.08),
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Themed Icon in tinted rounded container
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      effectiveIcon,
                      size: 19,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Value and Label neatly stacked
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: value,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.color,
                                  fontFamily: 'Poppins',
                                  height: 1.1,
                                ),
                              ),
                              if (unit.isNotEmpty)
                                TextSpan(
                                  text: ' $unit',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

class _BmiRange extends StatelessWidget {
  final String label;
  final String range;
  final Color color;
  const _BmiRange(
      {required this.label, required this.range, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color)),
          const Spacer(),
          Text(range,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.labelSmall?.color)),
        ]),
      );
}

class _GoalItem extends StatelessWidget {
  final String label;
  final String sublabel;
  final String emoji;
  final String value;
  final double progress;
  final Color color;
  final bool showValueAsSuffix;
  const _GoalItem(
      {required this.label,
      this.sublabel = '',
      required this.emoji,
      required this.value,
      required this.progress,
      required this.color,
      this.showValueAsSuffix = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context)
                  .dividerColor
                  .withValues(alpha: isDark ? 0.15 : 0.08)),
          boxShadow: isDark
              ? []
              : [
                  const BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]),
      child: Column(
        children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                  child: Icon(IkonMapper.dariEmoji(emoji), size: 19, color: Theme.of(context).colorScheme.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                              Theme.of(context).textTheme.titleMedium?.color)),
                  if (sublabel.isNotEmpty)
                    Text(sublabel,
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).textTheme.labelSmall?.color)),
                ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(showValueAsSuffix ? value : '$pct%',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            ),
          ]),
          const SizedBox(height: 12),
          // Progress bar
          Stack(children: [
            // Background track
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Filled portion
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.7),
                      color,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final String icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingSwitch(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: Theme.of(context)
                  .dividerColor
                  .withValues(alpha: isDark ? 0.15 : 0.08)),
          boxShadow: isDark
              ? []
              : [
                  const BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child:
              Center(child: Text(icon, style: const TextStyle(fontSize: 17))),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color))),
        Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Theme.of(context).colorScheme.primary),
      ]),
    );
  }
}

String _fastingModeLabel(String mode) {
  switch (mode) {
    case 'ramadan':
      return 'Ramadan (reminder malam)';
    case 'if':
      return 'Intermittent fasting';
    default:
      return 'Nonaktif';
  }
}

class _SettingAction extends StatelessWidget {
  final String icon;
  final String label;
  final String valueText;
  final VoidCallback onTap;

  const _SettingAction(
      {required this.icon,
      required this.label,
      required this.valueText,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Theme.of(context)
                    .dividerColor
                    .withValues(alpha: isDark ? 0.15 : 0.08)),
            boxShadow: isDark
                ? []
                : [
                    const BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ]),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(icon,
                  style: const TextStyle(
                      fontSize: 13, height: 1.0, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
                const SizedBox(height: 2),
                Text(valueText,
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).hintColor)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Theme.of(context).hintColor),
        ]),
      ),
    );
  }
}

class _FastingModeSheet extends StatelessWidget {
  final ActivityProvider provider;
  final String current;
  final void Function(String mode) onPick;

  const _FastingModeSheet(
      {required this.provider, required this.current, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget tile(String mode, String title, String subtitle) {
      final selected = current == mode;
      return ListTile(
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface)),
        subtitle: Text(subtitle),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : null,
        onTap: () {
          onPick(mode);
          Navigator.pop(context);
        },
      );
    }

    String fmtMin(int minute) {
      final h = (minute ~/ 60).clamp(0, 23).toString().padLeft(2, '0');
      final m = (minute % 60).clamp(0, 59).toString().padLeft(2, '0');
      return '$h:$m';
    }

    Future<void> pickTime({
      required int initialMinute,
      required void Function(int newMinute) onSelected,
    }) async {
      final init = TimeOfDay(
          hour: (initialMinute ~/ 60).clamp(0, 23),
          minute: (initialMinute % 60).clamp(0, 59));
      final picked = await showTimePicker(context: context, initialTime: init);
      if (picked == null) return;
      onSelected(picked.hour * 60 + picked.minute);
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          tile('none', 'Nonaktif', 'Jadwal notifikasi normal.'),
          tile('ramadan', 'Ramadan',
              'Reminder minum setelah berbuka dan sahur.'),
          if (current == 'ramadan') ...[
            ListTile(
              title: const Text('Mulai berbuka (iftar)'),
              subtitle:
                  Text('Saat ini: ${fmtMin(provider.ramadanIftarMinute)}'),
              trailing: const Icon(Icons.schedule_rounded),
              onTap: () => pickTime(
                initialMinute: provider.ramadanIftarMinute,
                onSelected: (m) => provider.setRamadanWindowMinutes(
                    iftarMinute: m,
                    suhoorEndMinute: provider.ramadanSuhoorEndMinute),
              ),
            ),
            ListTile(
              title: const Text('Selesai sahur (imsak)'),
              subtitle:
                  Text('Saat ini: ${fmtMin(provider.ramadanSuhoorEndMinute)}'),
              trailing: const Icon(Icons.schedule_rounded),
              onTap: () => pickTime(
                initialMinute: provider.ramadanSuhoorEndMinute,
                onSelected: (m) => provider.setRamadanWindowMinutes(
                    iftarMinute: provider.ramadanIftarMinute,
                    suhoorEndMinute: m),
              ),
            ),
          ],
          tile('if', 'Intermittent fasting',
              'Puasa berbasis waktu (air tetap boleh).'),
          if (current == 'if') ...[
            ListTile(
              title: const Text('Mulai jendela makan (IF)'),
              subtitle: Text('Saat ini: ${fmtMin(provider.ifEatStartMinute)}'),
              trailing: const Icon(Icons.schedule_rounded),
              onTap: () => pickTime(
                initialMinute: provider.ifEatStartMinute,
                onSelected: (m) => provider.setIfWindowMinutes(
                    startMinute: m, endMinute: provider.ifEatEndMinute),
              ),
            ),
            ListTile(
              title: const Text('Selesai jendela makan (IF)'),
              subtitle: Text('Saat ini: ${fmtMin(provider.ifEatEndMinute)}'),
              trailing: const Icon(Icons.schedule_rounded),
              onTap: () => pickTime(
                initialMinute: provider.ifEatEndMinute,
                onSelected: (m) => provider.setIfWindowMinutes(
                    startMinute: provider.ifEatStartMinute, endMinute: m),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              'Jam ini dipakai untuk menentukan jendela makan/puasa, izin minum (Ramadan), notifikasi, dan konteks saran AI.',
              style: TextStyle(fontSize: 12, color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;
  const _BadgeChip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4))),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      );
}

// ─── Health Score Card ─────────────────────────────────────────────────────────
class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard();

  Color _scoreColor(int score) {
    if (score >= 75) return const Color(0xFF10B981);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<ActivityProvider>();
    final score = ap.healthScore;
    final label = ap.healthScoreLabel;
    final color = _scoreColor(score);
    final theme = Theme.of(context);
    final smokingStatus = ap.smokingStatus;
    final smokingPoints = ap.smokingHealthPoints;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.extension<AppThemeExtension>()?.gradientCard ??
              AppColors.gradientCard,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RingProgress(
                size: 90,
                progress: score / 100,
                color: color,
                strokeWidth: 10,
                child: Text(
                  '$score',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color,
                      fontFamily: 'Poppins'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: color,
                            fontFamily: 'Poppins')),
                    const SizedBox(height: 6),
                    Text('Skor gaya hidup harian (0-100)',
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Breakdown
          _ScoreRow(
              icon: '',
              label:
                  'Paparan rokok: ${ap.smokingStatusLabel} (${smokingPoints >= 0 ? '+' : ''}$smokingPoints)',
              isGood: smokingStatus == ActivityProvider.smokingStatusNone),
          _ScoreRow(
              icon: ap.isSmoker ? '🚬' : '🚭',
              label: ap.isSmoker ? 'Merokok (−25)' : 'Tidak Merokok (+25)',
              isGood: !ap.isSmoker),
          _ScoreRow(
              icon: '👟',
              label:
                  'Langkah: ${ap.steps} / ${ap.stepTarget}',
              isGood: ap.steps >= ap.stepTarget),
          _ScoreRow(
              icon: '💧',
              label: 'Air: ${ap.waterGlasses} / ${ap.waterTarget} gelas',
              isGood: ap.waterGlasses >= ap.waterTarget),
          _ScoreRow(
              icon: '😴',
              label: ap.lastSleepRecord != null
                  ? 'Tidur: ${ap.lastSleepRecord!.durationLabel}'
                  : 'Tidur: Belum dicatat',
              isGood: ap.lastSleepRecord?.isAdequate ?? false),
          const SizedBox(height: 16),
          _HealthAdvice(
            smokingStatus: smokingStatus,
            stepsDone: ap.steps >= ap.stepTarget,
            waterDone: ap.waterGlasses >= ap.waterTarget,
            sleepDone: ap.lastSleepRecord?.isAdequate ?? false,
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String icon;
  final String label;
  final bool isGood;
  const _ScoreRow(
      {required this.icon, required this.label, required this.isGood});

  @override
  Widget build(BuildContext context) {
    if (label.startsWith('Merokok (') || label.startsWith('Tidak Merokok (')) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          if (icon.isNotEmpty) ...[
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8))),
          ),
          Icon(
            isGood ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: isGood ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }
}

class _HealthAdvice extends StatelessWidget {
  final String smokingStatus;
  final bool stepsDone;
  final bool waterDone;
  final bool sleepDone;

  const _HealthAdvice({
    required this.smokingStatus,
    required this.stepsDone,
    required this.waterDone,
    required this.sleepDone,
  });

  @override
  Widget build(BuildContext context) {
    if (smokingStatus == ActivityProvider.smokingStatusNone &&
        stepsDone &&
        waterDone &&
        sleepDone) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.celebration_rounded, size: 24, color: Color(0xFF10B981)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Luar biasa! Semua target kesehatan Anda terpenuhi hari ini. Pertahankan gaya hidup sehat Anda!',
                style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final advices = <String>[];
    final isSmoker = smokingStatus == ActivityProvider.smokingStatusActive;
    if (smokingStatus == ActivityProvider.smokingStatusPassive) {
      advices.add('Paparan asap rokok dari lingkungan sebaiknya dikurangi karena tetap memengaruhi kualitas napas dan pemulihan tubuh.');
    }
    if (isSmoker) advices.add('• Batasi atau berhenti merokok untuk memperbaiki kualitas pernapasan.');
    if (!stepsDone) advices.add('• Perbanyak jalan kaki atau aktivitas untuk mencapai target langkah harian.');
    if (!waterDone) advices.add('• Minum lebih banyak air putih untuk memenuhi hidrasi agar tidak dehidrasi.');
    if (!sleepDone) advices.add('• Usahakan tidur 7-8 jam agar tubuh memiliki waktu memulihkan diri.');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 18, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text('Saran untuk Anda:', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ...advices.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(a, style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B))),
          )),
        ],
      ),
    );
  }
}

// ─── Sleep Log Card ────────────────────────────────────────────────────────────
class _SleepLogCard extends StatelessWidget {
  final VoidCallback onLog;
  const _SleepLogCard({required this.onLog});

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<ActivityProvider>();
    final last = ap.lastSleepRecord;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (last != null) ...[
            Row(
              children: [
                Icon(Icons.bedtime_outlined,
                    size: 28,
                    color: last.isAdequate
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        last.durationLabel,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                            color: last.isAdequate
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B)),
                      ),
                      Text(
                        '${last.bedtimeLabel} → ${last.wakeLabel}  •  ${last.date}',
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (last.isAdequate
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B))
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: last.isAdequate
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B)),
                  ),
                  child: Text(
                    last.isAdequate ? 'Cukup ✓' : 'Kurang',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: last.isAdequate
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '😴 Belum ada catatan tidur hari ini.',
                style: TextStyle(
                    fontSize: 13,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLog,
              icon: const Icon(Icons.bedtime_rounded, size: 18),
              label: Text(
                  last != null ? 'Perbarui Jam Tidur' : 'Catat Jam Tidur'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(
                    color: theme.colorScheme.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
