// services/product_service.dart - OPTION 1 (Custom Users Table)
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import 'auth_service.dart';

class ProductService {
  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _authService = AuthService();

  // Singleton pattern
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

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

  // Get all products for current user
  Future<List<Product>> getAllProducts() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User tidak terautentikasi');

      final response = await _client
          .from('products')
          .select()
          .eq('id_user', userId)
          .order('nama_produk', ascending: true);
      
      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting products: $e');
      throw Exception('Gagal mengambil data produk: $e');
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllProducts();
      }

      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User tidak terautentikasi');

      final response = await _client
          .from('products')
          .select()
          .eq('id_user', userId)
          .or('nama_produk.ilike.%$query%,deskripsi.ilike.%$query%')
          .order('nama_produk', ascending: true);
      
      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching products: $e');
      throw Exception('Gagal mencari produk: $e');
    }
  }

  // Get products with low stock - FIXED: Gunakan stok_minimal per produk
  Future<List<Product>> getLowStockProducts() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User tidak terautentikasi');

      // Query dengan raw SQL untuk compare jumlah_produk dengan stok_minimal
      final response = await _client.rpc('get_low_stock_products', params: {
        'user_id_param': userId,
      });
      
      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting low stock products: $e');
      // Fallback: gunakan client-side filtering jika RPC tidak tersedia
      return await _getLowStockProductsFallback();
    }
  }

  // Fallback method: client-side filtering
  Future<List<Product>> _getLowStockProductsFallback() async {
    try {
      final allProducts = await getAllProducts();
      return allProducts.where((product) => product.isLowStock).toList()
        ..sort((a, b) => a.jumlahProduk.compareTo(b.jumlahProduk));
    } catch (e) {
      print('Error in fallback low stock: $e');
      return [];
    }
  }

  // Get total products count
  Future<int> getTotalProductsCount() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return 0;

      // Method 1: count() returns int directly in Supabase 2.8
      final count = await _client
          .from('products')
          .count()
          .eq('id_user', userId);
      
      return count; // count is already an int
    } catch (e) {
      print('Error getting products count: $e');
      return 0;
    }
  }

  // Add new product
  Future<Product> addProduct(Product product) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User tidak terautentikasi');

      final productData = product.toJson();
      productData['id_user'] = userId; // Use custom user ID

      final response = await _client
          .from('products')
          .insert(productData)
          .select()
          .single();

      return Product.fromJson(response);
    } catch (e) {
      print('Error adding product: $e');
      throw Exception('Gagal menambahkan produk: $e');
    }
  }

  // Update product
  Future<Product> updateProduct(Product product) async {
    try {
      if (product.id == null) {
        throw Exception('ID produk tidak ditemukan');
      }

      final response = await _client
          .from('products')
          .update(product.toJson())
          .eq('produk_id', product.id!)
          .select()
          .single();

      return Product.fromJson(response);
    } catch (e) {
      print('Error updating product: $e');
      throw Exception('Gagal mengupdate produk: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _client
          .from('products')
          .delete()
          .eq('produk_id', productId);
    } catch (e) {
      print('Error deleting product: $e');
      throw Exception('Gagal menghapus produk: $e');
    }
  }

  // Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('produk_id', productId)
          .single();

      return Product.fromJson(response);
    } catch (e) {
      print('Error getting product by ID: $e');
      return null;
    }
  }

  // Update product stock
  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await _client
          .from('products')
          .update({'jumlah_produk': newStock})
          .eq('produk_id', productId);
    } catch (e) {
      print('Error updating product stock: $e');
      throw Exception('Gagal mengupdate stok produk: $e');
    }
  }
}