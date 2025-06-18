// services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Register
  Future<void> signUp({
    required String email,
    required String password,
    required String namaLengkap,
    String? phoneNumber,
  }) async {
    // 1. Daftarkan user di Auth
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    
    // 2. Simpan data user di tabel users
    if (response.user != null) {
      await _client.from('users').insert({
        'id_user': response.user!.id,
        'nama_lengkap': namaLengkap,
        'email': email,
        'password': password,
        'phone_number': phoneNumber,
      });
    } else {
      throw Exception('Gagal mendaftarkan pengguna baru');
    }
  }

  // Login
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      return response.user;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Logout
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _client.auth.currentUser != null;
  }
}