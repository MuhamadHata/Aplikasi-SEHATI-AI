import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../inti/tema/design_tokens.dart';
import '../../penyedia/penyedia_aktivitas.dart';

class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  DateTime? _birthDate;
  int? _age;
  String _selectedGender = 'Pria';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialBirthDate();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialBirthDate() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final metaBirthDate = user?.userMetadata?['birth_date'] as String?;
      final metaAge = user?.userMetadata?['age'] as int?;

      final prefs = await SharedPreferences.getInstance();
      final tempBirthDateStr =
          prefs.getString('temp_birth_date') ?? metaBirthDate;
      final tempAge = prefs.getInt('temp_age') ?? metaAge;

      if (tempBirthDateStr != null) {
        final parsed = DateTime.tryParse(tempBirthDateStr);
        if (parsed != null && mounted) {
          setState(() {
            _birthDate = parsed;
            _age = _calculateAge(parsed);
          });
          return;
        }
      }
      if (tempAge != null && mounted) {
        setState(() {
          _age = tempAge;
          _birthDate = DateTime(DateTime.now().year - tempAge, 1, 1);
        });
      }
    } catch (_) {}
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickBirthDate() async {
    final initial = _birthDate ??
        DateTime.now().subtract(const Duration(days: 365 * 22));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1910),
      lastDate: DateTime.now(),
      helpText: 'PILIH TANGGAL LAHIR (ULANG TAHUN)',
      confirmText: 'PILIH',
      cancelText: 'BATAL',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF0F52BA),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _age = _calculateAge(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    final wText = _weightCtrl.text.trim();
    final hText = _heightCtrl.text.trim();

    if (wText.isEmpty || hText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi tinggi dan berat badan Anda')),
      );
      return;
    }

    if (_birthDate == null || _age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih tanggal lahir / ulang tahun Anda'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final weight = double.tryParse(wText);
    final height = double.tryParse(hText);
    final age = _age!;

    if (weight == null || height == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Masukkan angka tinggi dan berat yang valid')),
      );
      return;
    }

    // ── Validasi Range ───────────────────────────────────────────────────────
    if (height < 100 || height > 250) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tinggi badan harus antara 100–250 cm'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (weight < 20 || weight > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berat badan harus antara 20–300 kg'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (age < 10 || age > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usia harus antara 10–120 tahun'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    // ────────────────────────────────────────────────────────────────────────

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final metaName = user.userMetadata?['full_name'] ??
            user.userMetadata?['name'] ??
            'User';

        // Menggunakan upsert agar akun baru via Google yang belum memiliki baris
        // di public.users dapat dibuat secara otomatis tanpa error update
        await Supabase.instance.client.from('users').upsert({
          'id': user.id,
          'email': user.email,
          'name': metaName,
          'weight': weight,
          'height': height,
          'age': age,
          'gender': _selectedGender,
          'profile_completed': true,
        });

        // Simpan juga tanggal lahir di auth user metadata
        try {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(data: {
              'birth_date': _birthDate!.toIso8601String().split('T')[0],
              'age': age,
            }),
          );
        } catch (_) {}

        if (mounted) {
          // Tarik ulang profil terbaru dari database untuk memastikan nama tersinkronisasi
          await context.read<ActivityProvider>().loadProfile();

          final double hM = height / 100.0;
          final double bmi = weight / (hM * hM);
          if (mounted) {
            context.read<ActivityProvider>().updateBMI(bmi);
            context.read<ActivityProvider>().updateAge(age);
            context.read<ActivityProvider>().updateGender(_selectedGender);

            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          }
        }
      } else {
        throw Exception('Tidak ada user login aktif');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan profil: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Mencegah back button
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '💪',
                  style: TextStyle(fontSize: 51),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Lengkapi Profil Anda',
                  style: TextStyle(
                    fontSize: 31,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Untuk mendapatkan akurasi BMI, target kalori harian, dan rekomendasi personal dari SEHATI-AI, kami perlu data tubuh Anda.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Form
                _buildInputField('Tinggi Badan (cm)', 'Contoh: 170',
                    _heightCtrl, Icons.height),
                const SizedBox(height: 16),
                _buildInputField('Berat Badan (kg)', 'Contoh: 65', _weightCtrl,
                    Icons.monitor_weight_outlined),
                _buildBirthDatePicker(context),
                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jenis Kelamin',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            letterSpacing: 0.4)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      dropdownColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontFamily: 'Poppins'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                      items: ['Pria', 'Wanita'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => _selectedGender = newValue);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Submit Button
                GestureDetector(
                  onTap: _isLoading ? null : _saveProfile,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: AppColors.gradientPrimary,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : const Text(
                              'Simpan & Mulai',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'Poppins'),
                            ),
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

  Widget _buildInputField(String label, String hint,
      TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                letterSpacing: 0.4)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: 'Poppins'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            prefixIcon: Icon(icon,
                color: Theme.of(context).textTheme.bodySmall?.color, size: 20),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildBirthDatePicker(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tanggal Lahir (Ulang Tahun)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyMedium?.color,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickBirthDate,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _birthDate != null
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.dividerColor.withValues(alpha: 0.1),
                width: _birthDate != null ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cake_outlined,
                  color: _birthDate != null
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodySmall?.color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _birthDate != null
                        ? _formatDate(_birthDate!)
                        : 'Pilih Tanggal Lahir (Contoh: 15 Mei 1998)',
                    style: TextStyle(
                      fontSize: 15,
                      color: _birthDate != null
                          ? theme.colorScheme.onSurface
                          : theme.textTheme.bodySmall?.color,
                      fontFamily: 'Poppins',
                      fontWeight: _birthDate != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (_age != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Usia: $_age Thn',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                Icon(
                  Icons.calendar_today_rounded,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
