// ==========================================
// BAGIAN: LAYANAN (SERVICES)
// Berisi logika bisnis, pemanggilan API, dan fungsi inti aplikasi.
// ==========================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Web Client ID untuk Google Sign-In di Android
  static const String _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '643975197132-41d0jrjgvuafh4kjl2vegs1agti8aoc8.apps.googleusercontent.com',
  );

  GoogleSignIn get _googleSignIn => GoogleSignIn(
        serverClientId: _webClientId.isNotEmpty ? _webClientId : null,
        scopes: ['email', 'profile', 'openid'],
      );

  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
    DateTime? birthDate,
    int? age,
  }) async {
    try {
      final Map<String, dynamic> metadata = {'full_name': name};
      if (birthDate != null) {
        metadata['birth_date'] =
            '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}';
      }
      if (age != null) {
        metadata['age'] = age;
      }

      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      return res;
    } catch (e) {
      throw Exception('Gagal mendaftar: $e');
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Gagal masuk: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _supabase.auth.signOut();
  }

  /// Login dengan Google 100% Native In-App:
  /// Menampilkan lembar pemilih akun bawaan Android di dalam aplikasi tanpa membuka web browser.
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Pengguna membatalkan dialog pemilih akun Google
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken != null) {
        final AuthResponse res = await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
        return res;
      }

      // Jika idToken null pada Android
      throw Exception(
          'Google ID Token tidak ditemukan pada perangkat Anda.');
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      throw Exception('Gagal masuk dengan Google: $msg');
    }
  }

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
