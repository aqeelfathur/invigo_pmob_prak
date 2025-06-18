// services/pendapatan_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pendapatan_model.dart';
// import '../models/product_model.dart';
import 'auth_service.dart';
import 'product_service.dart';

class PendapatanService {
  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();

  // Singleton pattern
  static final PendapatanService _instance = PendapatanService._internal();
  factory PendapatanService() => _instance;
  PendapatanService._internal();

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

  // Add new pendapatan and update product stock
  Future<Pendapatan> addPendapatan({
    required String produkId,
    required int jumlahProduk,
    required DateTime tanggalPendapatan,
    String? catatan,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User tidak terautentikasi');

      // Validasi stok terlebih dahulu
      final currentProduct = await _productService.getProductById(produkId);
      if (currentProduct == null) {
        throw Exception('Produk tidak ditemukan');
      }

      if (currentProduct.jumlahProduk < jumlahProduk) {
        throw Exception('Stok tidak mencukupi. Stok tersedia: ${currentProduct.jumlahProduk}');
      }

      // Buat object pendapatan baru
      final pendapatan = Pendapatan(
        produkId: produkId,
        jumlahProdukPendapatan: jumlahProduk,
        tanggalPendapatan: tanggalPendapatan,
        catatanPendapatan: catatan,
        userId: userId,
      );

      // Start transaction-like operation
      // 1. Insert pendapatan data
      final response = await _client
          .from('pendapatan')
          .insert(pendapatan.toJson())
          .select()
          .single();

      final newPendapatan = Pendapatan.fromJson(response);

      // 2. Update product stock (kurangi stok)
      final newStock = currentProduct.jumlahProduk - jumlahProduk;
      await _productService.updateProductStock(produkId, newStock);

      return newPendapatan;
    } catch (e) {
      print('Error adding pendapatan: $e');
      throw Exception('Gagal menambahkan data pendapatan: $e');
    }
  }

  // Get all pendapatan for current user with product details
  Future<List<Pendapatan>> getAllPendapatan() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User tidak terautentikasi');

      final response = await _client
          .from('pendapatan')
          .select('''
            *,
            products!inner(nama_produk, harga_jual)
          ''')
          .eq('id_user', userId)
          .order('tanggal_pendapatan', ascending: false);

      return (response as List).map((json) {
        // Flatten the nested product data
        final productData = json['products'];
        json['nama_produk'] = productData['nama_produk'];
        json['harga_jual'] = productData['harga_jual'];
        
        return Pendapatan.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error getting pendapatan: $e');
      throw Exception('Gagal mengambil data pendapatan: $e');
    }
  }

  // Get pendapatan by date range
  Future<List<Pendapatan>> getPendapatanByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User tidak terautentikasi');

      final response = await _client
          .from('pendapatan')
          .select('''
            *,
            products!inner(nama_produk, harga_jual)
          ''')
          .eq('id_user', userId)
          .gte('tanggal_pendapatan', startDate.toIso8601String())
          .lte('tanggal_pendapatan', endDate.toIso8601String())
          .order('tanggal_pendapatan', ascending: false);

      return (response as List).map((json) {
        final productData = json['products'];
        json['nama_produk'] = productData['nama_produk'];
        json['harga_jual'] = productData['harga_jual'];
        
        return Pendapatan.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error getting pendapatan by date range: $e');
      throw Exception('Gagal mengambil data pendapatan: $e');
    }
  }

  // Get today's pendapatan
  Future<List<Pendapatan>> getTodayPendapatan() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    
    return await getPendapatanByDateRange(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  // Get pendapatan statistics
  Future<Map<String, dynamic>> getPendapatanStats() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User tidak terautentikasi');

      // Get total pendapatan count
      final countResponse = await _client
          .from('pendapatan')
          .select('id_pendapatan', const FetchOptions(count: CountOption.exact))
          .eq('id_user', userId);

      // Get today's pendapatan
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final todayResponse = await _client
          .from('pendapatan')
          .select('''
            jumlah_produk_pendapatan,
            products!inner(harga_jual)
          ''')
          .eq('id_user', userId)
          .gte('tanggal_pendapatan', startOfDay.toIso8601String())
          .lte('tanggal_pendapatan', endOfDay.toIso8601String());

      int todayRevenue = 0;
      int todayQuantity = 0;
      for (var item in todayResponse) {
        final quantity = item['jumlah_produk_pendapatan'] as int;
        final hargaJual = item['products']['harga_jual'] as int;
        todayRevenue += (quantity * hargaJual);
        todayQuantity += quantity;
      }

      // Get this month's pendapatan
      final firstDayThisMonth = DateTime(today.year, today.month, 1);
      final lastDayThisMonth = DateTime(today.year, today.month + 1, 0);

      final thisMonthResponse = await _client
          .from('pendapatan')
          .select('''
            jumlah_produk_pendapatan,
            products!inner(harga_jual)
          ''')
          .eq('id_user', userId)
          .gte('tanggal_pendapatan', firstDayThisMonth.toIso8601String())
          .lte('tanggal_pendapatan', lastDayThisMonth.toIso8601String());

      int thisMonthRevenue = 0;
      int thisMonthQuantity = 0;
      for (var item in thisMonthResponse) {
        final quantity = item['jumlah_produk_pendapatan'] as int;
        final hargaJual = item['products']['harga_jual'] as int;
        thisMonthRevenue += (quantity * hargaJual);
        thisMonthQuantity += quantity;
      }

      return {
        'total_transactions': countResponse.count ?? 0,
        'today_revenue': todayRevenue,
        'today_quantity': todayQuantity,
        'today_transactions': todayResponse.length,
        'this_month_revenue': thisMonthRevenue,
        'this_month_quantity': thisMonthQuantity,
        'this_month_transactions': thisMonthResponse.length,
      };
    } catch (e) {
      print('Error getting pendapatan stats: $e');
      return {
        'total_transactions': 0,
        'today_revenue': 0,
        'today_quantity': 0,
        'today_transactions': 0,
        'this_month_revenue': 0,
        'this_month_quantity': 0,
        'this_month_transactions': 0,
      };
    }
  }

  // Delete pendapatan (optional - untuk keperluan management)
  Future<void> deletePendapatan(String pendapatanId) async {
    try {
      await _client
          .from('pendapatan')
          .delete()
          .eq('id_pendapatan', pendapatanId);
    } catch (e) {
      print('Error deleting pendapatan: $e');
      throw Exception('Gagal menghapus data pendapatan: $e');
    }
  }

  // Get pendapatan by product
  Future<List<Pendapatan>> getPendapatanByProduct(String produkId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User tidak terautentikasi');

      final response = await _client
          .from('pendapatan')
          .select('''
            *,
            products!inner(nama_produk, harga_jual)
          ''')
          .eq('id_user', userId)
          .eq('produk_id', produkId)
          .order('tanggal_pendapatan', ascending: false);

      return (response as List).map((json) {
        final productData = json['products'];
        json['nama_produk'] = productData['nama_produk'];
        json['harga_jual'] = productData['harga_jual'];
        
        return Pendapatan.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error getting pendapatan by product: $e');
      throw Exception('Gagal mengambil data pendapatan produk: $e');
    }
  }

  // Get top selling products
  Future<List<Map<String, dynamic>>> getTopSellingProducts({int limit = 5}) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User tidak terautentikasi');

      // Menggunakan RPC function untuk aggregation
      // Jika tidak ada RPC, gunakan client-side processing
      try {
        final response = await _client.rpc('get_top_selling_products', params: {
          'user_id_param': userId,
          'limit_param': limit,
        });
        
        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        // Fallback: client-side processing
        return await _getTopSellingProductsFallback(limit);
      }
    } catch (e) {
      print('Error getting top selling products: $e');
      return [];
    }
  }

  // Fallback method untuk top selling products
  Future<List<Map<String, dynamic>>> _getTopSellingProductsFallback(int limit) async {
    try {
      final allPendapatan = await getAllPendapatan();
      final Map<String, Map<String, dynamic>> productSales = {};

      for (var pendapatan in allPendapatan) {
        final produkId = pendapatan.produkId;
        final quantity = pendapatan.jumlahProdukPendapatan;
        final revenue = pendapatan.getTotalNilai() ?? 0;

        if (productSales.containsKey(produkId)) {
          productSales[produkId]!['total_quantity'] += quantity;
          productSales[produkId]!['total_revenue'] += revenue;
          productSales[produkId]!['transaction_count'] += 1;
        } else {
          productSales[produkId] = {
            'produk_id': produkId,
            'nama_produk': pendapatan.namaProduk ?? 'Unknown',
            'total_quantity': quantity,
            'total_revenue': revenue,
            'transaction_count': 1,
          };
        }
      }

      final sortedProducts = productSales.values.toList()
        ..sort((a, b) => (b['total_quantity'] as int).compareTo(a['total_quantity'] as int));

      return sortedProducts.take(limit).toList();
    } catch (e) {
      print('Error in fallback top selling products: $e');
      return [];
    }
  }
}