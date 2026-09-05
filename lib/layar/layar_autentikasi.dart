import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../inti/tema/design_tokens.dart';
import '../../inti/layanan/layanan_autentikasi.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();

  Future<void> _checkProfileAndNavigate() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('users').select('profile_completed')
            .eq('id', user.id)
            .maybeSingle();
        if (data != null && data['profile_completed'] == true) {
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        } else {
          if (mounted) Navigator.pushReplacementNamed(context, '/setup-profile');
        }
      } catch (e) {
        debugPrint('Profile check fallback: $e');
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _loading = true);
    try {
      final cred = await _authService.signInWithGoogle();
      if (cred != null) {
        await _checkProfileAndNavigate();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Google: ${e.toString().replaceAll('Exception: ', '')}'), 
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSubmit() async {
    final emailText = _emailCtrl.text.trim();
    if (emailText.isEmpty ||
        _passCtrl.text.isEmpty ||
        (!_isLogin && _nameCtrl.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi semua field.')),
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(emailText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format email tidak valid (contoh: nama@gmail.com)'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isLogin) {
        await _authService.signIn(
          email: emailText,
          password: _passCtrl.text.trim(),
        );
        await _checkProfileAndNavigate();
      } else {
        final res = await _authService.signUp(
          name: _nameCtrl.text.trim(),
          email: emailText,
          password: _passCtrl.text.trim(),
        );
        if (res.session == null) {
          if (mounted) {
            setState(() => _isLogin = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Pendaftaran berhasil! Silakan cek email Anda untuk verifikasi akun, lalu masuk.'),
                backgroundColor: AppColors.primary,
                duration: Duration(seconds: 6),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
        await _checkProfileAndNavigate();
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString();
        if (errMsg.contains('user-not-found') ||
            errMsg.contains('no user record')) {
          errMsg = 'Email belum terdaftar di database';
        } else if (errMsg.contains('invalid-credential') ||
            errMsg.contains('invalid_credentials') ||
            errMsg.contains('wrong-password') ||
            errMsg.toLowerCase().contains('incorrect')) {
          errMsg = 'Email belum terdaftar atau password Anda salah';
        } else if (errMsg.contains('email_not_confirmed')) {
          errMsg = 'Email belum diverifikasi. Silahkan cek kotak masuk/spam Email Anda.';
        } else if (errMsg.contains('over_email_send_rate_limit')) {
          errMsg = 'Terlalu banyak percobaan daftar. Tunggu hingga 1 menit.';
        } else {
          errMsg = errMsg
              .replaceAll('Exception: ', '')
              .replaceAll('AuthException: ', '')
              .replaceAll('[firebase_auth/invalid-credential] ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                  theme.scaffoldBackgroundColor,
                  theme.scaffoldBackgroundColor
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Decor
          Positioned(
            top: -100,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Logo — SEHATI-AI (sesuai desain)
                  Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F52BA),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF0F52BA).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.favorite_rounded, size: 40, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      RichText(
                        text: const TextSpan(children: [
                          TextSpan(
                              text: 'SEHATI',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: 1.2)),
                          TextSpan(
                              text: '-AI',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F52BA),
                                  letterSpacing: 1.2)),
                        ]),
                      ),
                      const SizedBox(height: 4),
                      const Text('Evaluasi Holistik Aktivitas & Nutrisi',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), letterSpacing: 0.3, fontFamily: 'Poppins')),
                    ],
                  ),
                  const SizedBox(height: 36),
                  // Toggle
                  Container(
                    decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _TabButton(
                            label: 'Masuk',
                            isActive: _isLogin,
                            onTap: () => setState(() => _isLogin = true)),
                        _TabButton(
                            label: 'Daftar',
                            isActive: !_isLogin,
                            onTap: () => setState(() => _isLogin = false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Form fields
                  if (!_isLogin) ...[
                    _InputField(
                        key: const ValueKey('name_field'),
                        label: 'Nama Lengkap',
                        hint: 'Nama Anda',
                        controller: _nameCtrl,
                        icon: Icons.person_outline),
                    const SizedBox(height: 14),
                  ],
                  _InputField(
                      key: const ValueKey('email_field'),
                      label: 'Email',
                      hint: 'email@contoh.com',
                      controller: _emailCtrl,
                      icon: Icons.email_outlined,
                      isEmail: true),
                  const SizedBox(height: 14),
                  _InputField(
                      key: const ValueKey('pass_field'),
                      label: 'Password',
                      hint: 'Minimal 8 karakter',
                      controller: _passCtrl,
                      icon: Icons.lock_outline,
                      isPassword: true),
                  if (_isLogin) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        child: Text('Lupa Password?',
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Submit
                  GestureDetector(
                    onTap: _loading ? null : _handleSubmit,
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
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 6))
                        ],
                      ),
                      child: Center(
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)
                            : Text(
                                _isLogin ? 'Masuk ke SEHATI-AI' : 'Buat Akun',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontFamily: 'Poppins'),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Divider
                  Row(
                    children: [
                      Expanded(
                          child: Divider(
                              color:
                                  theme.dividerColor.withValues(alpha: 0.1))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('atau',
                            style: TextStyle(
                                color: theme.textTheme.labelSmall?.color,
                                fontSize: 15)),
                      ),
                      Expanded(
                          child: Divider(
                              color:
                                  theme.dividerColor.withValues(alpha: 0.1))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Google
                  _SocialButton(
                      label: ' Login dengan Google',
                      iconWidget: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SvgPicture.asset(
                          'assets/images/google_logo.svg',
                          height: 24,
                          width: 24,
                        ),
                      ),
                      onTap: _handleGoogleSignIn),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TabButton(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : Theme.of(context).textTheme.labelSmall?.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool isPassword;
  final bool isEmail;

  const _InputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.isPassword = false,
    this.isEmail = false,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                letterSpacing: 0.4)),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType:
              widget.isEmail ? TextInputType.emailAddress : TextInputType.text,
          style: TextStyle(
              color: Theme.of(context).textTheme.titleMedium?.color,
              fontFamily: 'Poppins'),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle:
                TextStyle(color: Theme.of(context).textTheme.labelSmall?.color),
            prefixIcon: Icon(widget.icon,
                color: Theme.of(context).textTheme.labelSmall?.color, size: 20),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Theme.of(context).textTheme.labelSmall?.color,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
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

class _SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Widget? iconWidget;

  const _SocialButton({
    required this.label,
    required this.onTap,
    this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconWidget != null) iconWidget!,
              Text(label,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontFamily: 'Poppins')),
            ],
          ),
        ),
      ),
    );
  }
}
