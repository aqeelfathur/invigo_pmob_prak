import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:invigo/pages/custom_drawer.dart';
import 'package:invigo/pages/main_screen.dart';
import 'package:invigo/pages/profile_screen.dart';
import 'package:invigo/pages/login_page.dart';
import 'package:invigo/services/auth_service.dart';
import 'package:invigo/models/user_model.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final supabase = Supabase.instance.client;
  bool isLoggedIn = false;
  User? userProfile;
  bool _isLoading = true;
  
  // Data statistik
  int totalItems = 0;
  int totalStock = 0;
  int lowStockItems = 0;
  int outOfStockItems = 0;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  Future<void> _checkAuthAndLoadData() async {
    setState(() {
      _isLoading = true;
    });

    // Check authentication status
    isLoggedIn = _authService.isAuthenticated();

    if (isLoggedIn) {
      try {
        // Ambil ID user dari auth
        final authUserId = _authService.getCurrentUser()?.id;
        
        if (authUserId != null) {
          // Fetch user profile dari database
          final userData = await supabase
              .from('users')
              .select()
              .eq('id_user', authUserId)
              .single();
          
          userProfile = User.fromJson(userData);
          
          // Fetch data statistik dari database
          await _loadStatistics();
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _loadStatistics() async {
    try {
      // Get total items (product count)
      final productsResponse = await supabase
          .from('products')
          .select('produk_id');
      
      totalItems = productsResponse.length;
      
      // Get total stock
      final stockResponse = await supabase
          .from('products')
          .select('jumlah_produk');
      
      totalStock = 0;
      for (var item in stockResponse) {
        totalStock += (item['jumlah_produk'] as int? ?? 0);
      }
      
      // Get low stock items
      final lowStockResponse = await supabase
          .from('products')
          .select('produk_id')
          .lt('jumlah_produk', 10) // Menggunakan nilai tetap 10 sebagai stok minimal
          .gt('jumlah_produk', 0);
      
      lowStockItems = lowStockResponse.length;
      
      // Get out of stock items
      final outOfStockResponse = await supabase
          .from('products')
          .select('produk_id')
          .eq('jumlah_produk', 0);
      
      outOfStockItems = outOfStockResponse.length;
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, size: 28),
            onPressed: () {},
          ),
          // Mengganti builder dengan PopupMenuButton untuk dropdown
          PopupMenuButton<String>(
            icon: Icon(Icons.person, size: 28),
            offset: Offset(0, 56),
            onSelected: (value) async {
              // Handle pilihan menu
              if (value == 'login') {
                // Navigate ke halaman login
                await _navigateToLogin(context);
                // Refresh status setelah kembali dari halaman login
                _checkAuthAndLoadData();
              } else if (value == 'profile') {
                // Navigate ke halaman profil
                _navigateToProfile(context);
              } else if (value == 'logout') {
                // Proses logout
                await _handleLogout(context);
              }
            },
            itemBuilder: (BuildContext context) {
              // Menampilkan menu berdasarkan status login
              if (isLoggedIn) {
                // Menu untuk user yang sudah login
                return [
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.account_circle),
                        SizedBox(width: 8),
                        Text('Profil'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ];
              } else {
                // Menu untuk user yang belum login
                return [
                  PopupMenuItem<String>(
                    value: 'login',
                    child: Row(
                      children: [
                        Icon(Icons.login),
                        SizedBox(width: 8),
                        Text('Login'),
                      ],
                    ),
                  ),
                ];
              }
            },
          ),
        ],
      ),
      drawer: CustomDrawer(
        onTap: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        },
      ),
      // Membungkus body dengan SingleChildScrollView untuk membuat konten scrollable
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _checkAuthAndLoadData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 15),
                      Text(
                        isLoggedIn && userProfile != null
                            ? 'Hello, ${userProfile!.namaLengkap}!'
                            : 'Hello, Guest!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: 15),
                      // Menggunakan Column sebagai pengganti Wrap untuk layout yang lebih konsisten
                      isLoggedIn
                          ? Column(
                              children: [
                                Row(
                                  children: [
                                    _buildGridCard(
                                        context,
                                        totalItems.toString(),
                                        'Total Item',
                                        Icons.warehouse_outlined),
                                    _buildGridCard(
                                        context,
                                        totalStock.toString(),
                                        'Total Stok',
                                        Icons.inventory_2_outlined),
                                  ],
                                ),
                                SizedBox(height: 10), // Spacing antar baris
                                Row(
                                  children: [
                                    _buildGridCard(
                                        context,
                                        lowStockItems.toString(),
                                        'Produk Stok Tipis',
                                        Icons.warning_amber),
                                    _buildGridCard(
                                        context,
                                        outOfStockItems.toString(),
                                        'Produk Stok Habis',
                                        Icons.hourglass_disabled),
                                  ],
                                ),
                                SizedBox(height: 28),
                                Text(
                                  'Laporan Hari Ini',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 15),
                                SizedBox(
                                  height: 220,
                                  child: ListView.separated(
                                    itemBuilder: (BuildContext context, int index) {
                                      return _LaporanCard();
                                    },
                                    separatorBuilder: (BuildContext context, int index) {
                                      return SizedBox(width: 16);
                                    },
                                    itemCount: 5,
                                    scrollDirection: Axis.horizontal,
                                  ),
                                ),
                              ],
                            )
                          : _buildLoginPrompt(context),
                      // Tambahkan padding di bawah untuk memastikan konten terakhir tidak terpotong
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Widget prompt untuk user yang belum login
  Widget _buildLoginPrompt(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 20),
          Text(
            'Silakan login untuk melihat data inventory dan laporan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Data inventory dan laporan hanya tersedia untuk pengguna yang sudah login',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () async {
              await _navigateToLogin(context);
              _checkAuthAndLoadData();
            },
            icon: Icon(Icons.login),
            label: Text('Login Sekarang'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi navigasi ke halaman login
  Future<void> _navigateToLogin(BuildContext context) async {
    await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => LoginPage())
    );
  }

  // Fungsi navigasi ke halaman profil
  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => ProfileScreen())
    ).then((_) {
      // Refresh data setelah kembali dari halaman profil
      _checkAuthAndLoadData();
    });
  }

  // Fungsi untuk handle logout
  Future<void> _handleLogout(BuildContext context) async {
    try {
      await _authService.signOut();
      
      setState(() {
        isLoggedIn = false;
        userProfile = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berhasil logout')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saat logout: $e')),
      );
    }
  }

  Widget _buildGridCard(
      BuildContext context, String value, String label, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8)),
                    child: Center(
                      child: Icon(icon, size: 30),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LaporanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(14),
        width: 260,
        height: 200,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Produk 1',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Divider(thickness: 1.5),
            SizedBox(height: 16),
            Text(
              'Produk Terjual',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '12',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Pendapatan',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Text('Rp 7.000.000')
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Pengeluaran',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Text('Rp 1.400.000')
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}