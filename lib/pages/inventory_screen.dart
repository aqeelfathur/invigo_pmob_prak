import 'package:flutter/material.dart';
import 'package:invigo/pages/custom_drawer.dart';
import 'package:invigo/pages/main_screen.dart';
import 'package:invigo/pages/inventory_detail_screen.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';

class InventoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Warehouse'),
        actions: [
          IconButton(
              icon: Icon(Icons.notifications, size: 28), onPressed: () {}),
          Builder(
            builder: (context) {
              return IconButton(
                icon: Icon(Icons.person, size: 28),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
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
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ItemsWidget(),
            SizedBox(height: 16),
            LowStockAlert(),
          ],
        ),
      ),
    );
  }
}

class ItemsWidget extends StatefulWidget {
  @override
  _ItemsWidgetState createState() => _ItemsWidgetState();
}

class _ItemsWidgetState extends State<ItemsWidget> {
  final ProductService _productService = ProductService();
  int _totalItems = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTotalItems();
  }

  Future<void> _loadTotalItems() async {
    try {
      final count = await _productService.getTotalProductsCount();
      setState(() {
        _totalItems = count;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading items count: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildListTile(
      Icons.inventory,
      'Items',
      _isLoading ? 'Loading...' : '$_totalItems items',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => InventoryDetailScreen()),
        );
      },
    );
  }
}

class LowStockAlert extends StatefulWidget {
  @override
  _LowStockAlertState createState() => _LowStockAlertState();
}

class _LowStockAlertState extends State<LowStockAlert> {
  final ProductService _productService = ProductService();
  List<Product> _lowStockProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLowStockProducts();
  }

  Future<void> _loadLowStockProducts() async {
    try {
      final products = await _productService.getLowStockProducts();
      setState(() {
        _lowStockProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading low stock products: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Low Stock Alert",
            style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                color: Colors.black)),
        SizedBox(height: 8),
        if (_isLoading)
          CircularProgressIndicator()
        else if (_lowStockProducts.isEmpty)
          Text("All items are in sufficient stock.",
              style: TextStyle(color: Colors.grey))
        else
          Column(
            children: _lowStockProducts.map((product) {
              return _buildListTile(
                Icons.warning,
                product.namaProduk,
                "Stock: ${product.jumlahProduk} (Low!)",
                isLowStock: true,
                onTap: () {
                  // Navigate ke inventory detail dan scroll ke produk ini
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InventoryDetailScreen(
                        highlightProductId: product.id,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
      ],
    );
  }

}

Widget _buildListTile(IconData icon, String title, String subtitle,
    {VoidCallback? onTap, bool isLowStock = false}) {
  return Card(
    elevation: 4,
    child: ListTile(
      leading: Icon(
        icon, 
        color: isLowStock ? Colors.red : Colors.blue
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isLowStock ? Colors.red : null,
        ),
      ),
      trailing: Icon(Icons.arrow_forward),
      onTap: onTap,
    ),
  );
}