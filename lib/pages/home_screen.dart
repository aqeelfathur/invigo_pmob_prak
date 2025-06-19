import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:invigo/pages/custom_drawer.dart';
import 'package:invigo/pages/main_screen.dart';
import 'package:invigo/pages/profile_screen.dart';
import 'package:invigo/pages/login_page.dart';
import 'package:invigo/pages/inventory_detail_screen.dart';
import 'package:invigo/services/auth_service.dart';
import 'package:invigo/services/product_service.dart';
import 'package:invigo/models/user_model.dart';
import 'package:invigo/models/product_model.dart';
import 'package:invigo/pages/add_product_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();
  final supabase = Supabase.instance.client;
  
  bool isLoggedIn = false;
  User? userProfile;
  bool _isLoading = true;
  
  // Data statistik
  int totalItems = 0;
  int totalStock = 0;
  int lowStockItems = 0;
  int outOfStockItems = 0;
  double totalInventoryValue = 0;
  List<Product> recentLowStockProducts = [];
  List<Product> topProducts = [];

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
        // Ambil user profile
        await _loadUserProfile();
        
        // Load semua data statistik
        await _loadStatistics();
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadUserProfile() async {
    final authUser = _authService.getCurrentUser();
    if (authUser != null) {
      try {
        final userData = await supabase
            .from('users')
            .select()
            .eq('email', authUser.email!)
            .single();
        
        userProfile = User.fromJson(userData);
      } catch (e) {
        print('Error fetching user profile: $e');
      }
    }
  }
  
  Future<void> _loadStatistics() async {
    try {
      // Pakai ProductService untuk konsistensi
      final allProducts = await _productService.getAllProducts();
      final lowStockProducts = await _productService.getLowStockProducts();
      
      setState(() {
        totalItems = allProducts.length;
        
        // Calculate total stock
        totalStock = allProducts.fold(0, (sum, product) => sum + product.jumlahProduk);
        
        // Low stock count
        lowStockItems = lowStockProducts.length;
        
        // Out of stock count
        outOfStockItems = allProducts.where((product) => product.isOutOfStock).length;
        
        // Total inventory value (harga supplier * jumlah)
        totalInventoryValue = allProducts.fold(0.0, (sum, product) => 
            sum + (product.hargaSupplier * product.jumlahProduk));
        
        // Recent low stock products (max 5)
        recentLowStockProducts = lowStockProducts.take(5).toList();
        
        // Top products by value (max 5)
        topProducts = allProducts
            .where((product) => product.jumlahProduk > 0)
            .toList()
          ..sort((a, b) => (b.hargaJual * b.jumlahProduk).compareTo(a.hargaJual * a.jumlahProduk))
          ..take(5).toList();
      });
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
            icon: Stack(
              children: [
                Icon(Icons.notifications, size: 28),
                if (lowStockItems > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$lowStockItems',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              if (lowStockItems > 0) {
                _showLowStockDialog();
              }
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.person, size: 28),
            offset: Offset(0, 56),
            onSelected: (value) async {
              if (value == 'login') {
                await _navigateToLogin(context);
                _checkAuthAndLoadData();
              } else if (value == 'profile') {
                _navigateToProfile(context);
              } else if (value == 'logout') {
                await _handleLogout(context);
              }
            },
            itemBuilder: (BuildContext context) {
              if (isLoggedIn) {
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
                      
                      // Welcome Message with Time
                      _buildWelcomeSection(),
                      
                      SizedBox(height: 20),
                      
                      isLoggedIn
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Statistics Cards
                                _buildStatisticsSection(),
                                
                                SizedBox(height: 30),
                                
                                // Low Stock Alert Section
                                if (recentLowStockProducts.isNotEmpty)
                                  _buildLowStockSection(),
                                
                                SizedBox(height: 30),
                                
                                // Top Products Section
                                _buildTopProductsSection(),
                                
                                SizedBox(height: 30),
                                
                                // Quick Actions
                                _buildQuickActionsSection(),
                              ],
                            )
                          : _buildLoginPrompt(context),
                      
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeSection() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    
    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nights_stay;
    }

    return Row(
      children: [
        Icon(greetingIcon, color: Colors.orange, size: 24),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              Text(
                isLoggedIn && userProfile != null
                    ? userProfile!.namaLengkap
                    : 'Guest',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 15),
        
        // First Row
        Row(
          children: [
            _buildStatCard(
              'Total Items',
              totalItems.toString(),
              Icons.inventory_2,
              Colors.blue,
            ),
            SizedBox(width: 10),
            _buildStatCard(
              'Total Stock',
              totalStock.toString(),
              Icons.warehouse,
              Colors.green,
            ),
          ],
        ),
        
        SizedBox(height: 10),
        
        // Second Row
        Row(
          children: [
            _buildStatCard(
              'Low Stock',
              lowStockItems.toString(),
              Icons.warning_amber,
              Colors.orange,
              onTap: lowStockItems > 0 ? _showLowStockDialog : null,
            ),
            SizedBox(width: 10),
            _buildStatCard(
              'Out of Stock',
              outOfStockItems.toString(),
              Icons.remove_circle,
              Colors.red,
            ),
          ],
        ),
        
        SizedBox(height: 10),
        
        // Inventory Value Card (Full Width)
        Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.monetization_on, color: Colors.purple, size: 30),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Inventory Value',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        'Rp ${_formatNumber(totalInventoryValue.toInt())}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(height: 10),
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Low Stock Alert',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
           
          ],
        ),
        SizedBox(height: 10),
        ...recentLowStockProducts.map((product) => _buildLowStockItem(product)),
      ],
    );
  }

  Widget _buildLowStockItem(Product product) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.withOpacity(0.1),
          child: Icon(Icons.warning, color: Colors.red, size: 20),
        ),
        title: Text(product.namaProduk, style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('Stock: ${product.jumlahProduk} / Min: ${product.stokMinimal}'),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InventoryDetailScreen(highlightProductId: product.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopProductsSection() {
    if (topProducts.isEmpty) return SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Products by Value',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            
          ],
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 160, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: topProducts.length,
            itemBuilder: (context, index) {
              final product = topProducts[index];
              return _buildTopProductCard(product, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopProductCard(Product product, int rank) {
    final totalValue = product.hargaJual * product.jumlahProduk;
    
    // Determine rank color
    Color rankColor;
    if (rank == 1) {
      rankColor = Colors.amber; // Gold
    } else if (rank == 2) {
      rankColor = Colors.grey.shade400; // Silver
    } else if (rank == 3) {
      rankColor = Colors.orange; // Bronze
    } else {
      rankColor = Colors.blue.shade100;
    }
    
    return Container(
      width: 180, // Increased width to prevent overflow
      margin: EdgeInsets.only(right: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            // Navigate to product detail or inventory with highlight
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InventoryDetailScreen(highlightProductId: product.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  rankColor.withOpacity(0.1),
                  rankColor.withOpacity(0.05),
                ],
              ),
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with rank and product image placeholder
                Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: rankColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: rankColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: rank <= 3 ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    Spacer(),
                    // Product image or icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: product.gambarProduk != null && product.gambarProduk!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product.gambarProduk!,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.inventory_2, 
                                             color: Colors.grey.shade400, size: 20);
                                },
                              ),
                            )
                          : Icon(Icons.inventory_2, 
                                 color: Colors.grey.shade400, size: 20),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // Product name
                Text(
                  product.namaProduk,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: 8),
                
                // Stock info
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.isLowStock 
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: 12,
                        color: product.isLowStock ? Colors.red : Colors.green,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${product.jumlahProduk} units',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: product.isLowStock ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Spacer(),
                
                // Total value
                Text(
                  'Rp ${_formatNumber(totalValue)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 15),
        Row(
          children: [
            _buildQuickActionButton(
              'Add Product',
              Icons.add_box,
              Colors.blue,
              () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddProductScreen()),
                  );
                
              },
            ),
            SizedBox(width: 10),
            _buildQuickActionButton(
              'View Inventory',
              Icons.inventory,
              Colors.green,
              () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InventoryDetailScreen()),
                  );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Icon(icon, size: 32, color: color),
                SizedBox(height: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLowStockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Low Stock Products'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: recentLowStockProducts.length,
            itemBuilder: (context, index) {
              final product = recentLowStockProducts[index];
              return ListTile(
                title: Text(product.namaProduk),
                subtitle: Text('Stock: ${product.jumlahProduk} / Min: ${product.stokMinimal}'),
                trailing: Icon(Icons.warning, color: Colors.red),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InventoryDetailScreen(highlightProductId: product.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  // Existing methods remain the same
  Widget _buildLoginPrompt(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Welcome to Invigo',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Please login to access your inventory dashboard and manage your products',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () async {
              await _navigateToLogin(context);
              _checkAuthAndLoadData();
            },
            icon: Icon(Icons.login),
            label: Text('Login Now'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToLogin(BuildContext context) async {
    await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => LoginPage())
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => ProfileScreen())
    ).then((_) {
      _checkAuthAndLoadData();
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await _authService.signOut();
      
      setState(() {
        isLoggedIn = false;
        userProfile = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully logged out')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error dur ing logout: $e')),  
      );
    }
  }
}