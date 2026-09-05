import 'package:flutter/material.dart';
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
  final _ageCtrl = TextEditingController();
  String _selectedGender = 'Pria';
  bool _isLoading = false;

  Future<void> _saveProfile() async {
    final wText = _weightCtrl.text.trim();
    final hText = _heightCtrl.text.trim();
    final aText = _ageCtrl.text.trim();

    if (wText.isEmpty || hText.isEmpty || aText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi semua data tubuh Anda')),
      );
      return;
    }

    final weight = double.tryParse(wText);
    final height = double.tryParse(hText);
    final age = int.tryParse(aText);

    if (weight == null || height == null || age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan angka yang valid')),
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
        await Supabase.instance.client.from('users').update({
          'weight': weight,
          'height': height,
          'age': age,
          'gender': _selectedGender,
          'profile_completed': true,
        }).eq('id', user.id);

        if (mounted) {
          // Tarik ulang profil terbaru dari database untuk memastikan nama Tersinkronisasi
          await context.read<ActivityProvider>().loadProfile();
          
          final double hM = height / 100.0;
          final double bmi = weight / (hM * hM);
          if (mounted) {
            context.read<ActivityProvider>().updateBMI(bmi);
            context.read<ActivityProvider>().updateAge(age);
            context.read<ActivityProvider>().updateGender(_selectedGender);

            Navigator.pushReplacementNamed(context, '/home');
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
                const SizedBox(height: 16),
                _buildInputField('Usia (Tahun)', 'Contoh: 25', _ageCtrl,
                    Icons.cake_outlined),
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
}
