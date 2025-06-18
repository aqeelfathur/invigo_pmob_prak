// services/pengadaan_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pengadaan_model.dart';
// import '../models/product_model.dart';
import 'auth_service.dart';
import 'product_service.dart';

class PengadaanService {
  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();

  // Singleton pattern
  static final PengadaanService _instance = PengadaanService._internal();
  factory PengadaanService() => _instance;
  PengadaanService._internal();

  // Get current user's ID from custom users table
  Future<String?> _getCurrentUserId() async {
    final authUser = _authService.getCurrentUser();
    if (authUser == null) return null;

    try {
      final response = await _client
          .from('users')
          .select('id_user')
          .eq('email', authUser.email!)
          .single();
      
      return response['id_user'];
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // Add new pengadaan and update product stock
  Future<Pengadaan> addPengadaan({
    required String produkId,
    required int jumlahProduk,
    required String supplier,
    required DateTime tanggalPengadaan,
    String? deskripsi,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User tidak terautentikasi');

      // Buat object pengadaan baru
      final pengadaan = Pengadaan(
        produkId: produkId,
        jumlahProdukPengadaan: jumlahProduk,
        tanggalPengadaan: tanggalPengadaan,
        deskripsiPengadaan: '$supplier - $deskripsi', // Gabungkan supplier dan deskripsi
        userId: userId,
      );

      // Start transaction-like operation
      // 1. Insert pengadaan data
      final response = await _client
          .from('pengadaan')
          .insert(pengadaan.toJson())
          .select()
          .single();

      final newPengadaan = Pengadaan.fromJson(response);

      // 2. Update product stock (tambah stok)
      final currentProduct = await _productService.getProductById(produkId);
      if (currentProduct != null) {
        final newStock = currentProduct.jumlahProduk + jumlahProduk;
        await _productService.updateProductStock(produkId, newStock);
      }

      return newPengadaan;
    } catch (e) {
      print('Error adding pengadaan: $e');
      throw Exception('Gagal menambahkan data pengadaan: $e');
    }
  }

  // Get all pengadaan for current user with product details
  Future<List<Pengadaan>> getAllPengadaan() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User tidak terautentikasi');

      final response = await _client
          .from('pengadaan')
          .select('''
            *,
            products!inner(nama_produk, harga_supplier)
          ''')
          .eq('id_user', userId)
          .order('tanggal_pengadaan', ascending: false);

      return (response as List).map((json) {
        // Flatten the nested product data
        final productData = json['products'];
        json['nama_produk'] = productData['nama_produk'];
        json['harga_supplier'] = productData['harga_supplier'];
        
        return Pengadaan.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error getting pengadaan: $e');
      throw Exception('Gagal mengambil data pengadaan: $e');
    }
  }

  // Get pengadaan by date range
  Future<List<Pengadaan>> getPengadaanByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User tidak terautentikasi');

      final response = await _client
          .from('pengadaan')
          .select('''
            *,
            products!inner(nama_produk, harga_supplier)
          ''')
          .eq('id_user', userId)
          .gte('tanggal_pengadaan', startDate.toIso8601String())
          .lte('tanggal_pengadaan', endDate.toIso8601String())
          .order('tanggal_pengadaan', ascending: false);

      return (response as List).map((json) {
        final productData = json['products'];
        json['nama_produk'] = productData['nama_produk'];
        json['harga_supplier'] = productData['harga_supplier'];
        
        return Pengadaan.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error getting pengadaan by date range: $e');
      throw Exception('Gagal mengambil data pengadaan: $e');
    }
  }

  // Get pengadaan statistics
  Future<Map<String, dynamic>> getPengadaanStats() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User tidak terautentikasi');

      // Get total pengadaan count
      final countResponse = await _client
          .from('pengadaan')
          .select('id_pengadaan', const FetchOptions(count: CountOption.exact))
          .eq('id_user', userId);

      // Get this month's pengadaan
      final now = DateTime.now();
      final firstDayThisMonth = DateTime(now.year, now.month, 1);
      final lastDayThisMonth = DateTime(now.year, now.month + 1, 0);

      final thisMonthResponse = await _client
          .from('pengadaan')
          .select('jumlah_produk_pengadaan')
          .eq('id_user', userId)
          .gte('tanggal_pengadaan', firstDayThisMonth.toIso8601String())
          .lte('tanggal_pengadaan', lastDayThisMonth.toIso8601String());

      int thisMonthTotal = 0;
      for (var item in thisMonthResponse) {
        thisMonthTotal += (item['jumlah_produk_pengadaan'] as int);
      }

      return {
        'total_pengadaan': countResponse.count ?? 0,
        'this_month_total': thisMonthTotal,
        'this_month_count': thisMonthResponse.length,
      };
    } catch (e) {
      print('Error getting pengadaan stats: $e');
      return {
        'total_pengadaan': 0,
        'this_month_total': 0,
        'this_month_count': 0,
      };
    }
  }

  // Delete pengadaan (optional - untuk keperluan management)
  Future<void> deletePengadaan(String pengadaanId) async {
    try {
      await _client
          .from('pengadaan')
          .delete()
          .eq('id_pengadaan', pengadaanId);
    } catch (e) {
      print('Error deleting pengadaan: $e');
      throw Exception('Gagal menghapus data pengadaan: $e');
    }
  }

  // Get pengadaan by product
  Future<List<Pengadaan>> getPengadaanByProduct(String produkId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User tidak terautentikasi');

      final response = await _client
          .from('pengadaan')
          .select('''
            *,
            products!inner(nama_produk, harga_supplier)
          ''')
          .eq('id_user', userId)
          .eq('produk_id', produkId)
          .order('tanggal_pengadaan', ascending: false);

      return (response as List).map((json) {
        final productData = json['products'];
        json['nama_produk'] = productData['nama_produk'];
        json['harga_supplier'] = productData['harga_supplier'];
        
        return Pengadaan.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error getting pengadaan by product: $e');
      throw Exception('Gagal mengambil data pengadaan produk: $e');
    }
  }
}