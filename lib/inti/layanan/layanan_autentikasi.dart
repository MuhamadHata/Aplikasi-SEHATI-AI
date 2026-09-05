// ==========================================
// BAGIAN: LAYANAN (SERVICES)
// Berisi logika bisnis, pemanggilan API, dan fungsi inti aplikasi.
// ==========================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
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
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
  }

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Cancelled by user

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'Google ID Token tidak ditemukan. Pastikan akun Google dan koneksi internet Anda aktif.';
      }

      final AuthResponse res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return res;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      throw Exception('Gagal masuk dengan Google: $msg');
    }
  }

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
