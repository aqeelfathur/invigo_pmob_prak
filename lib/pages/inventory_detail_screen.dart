import 'package:flutter/material.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';

class InventoryDetailScreen extends StatefulWidget {
  final String? highlightProductId; // Parameter untuk highlight produk tertentu

  const InventoryDetailScreen({Key? key, this.highlightProductId}) : super(key: key);

  @override
  _InventoryDetailScreenState createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Scroll controller
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _highlightedProductId; // ID produk yang akan di-highlight

  @override
  void initState() {
    super.initState();
    _highlightedProductId = widget.highlightProductId;
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose(); // Dispose scroll controller
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productService.getAllProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });

      // Auto scroll ke produk yang di-highlight setelah data loaded
      if (_highlightedProductId != null) {
        _scrollToHighlightedProduct();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
    }
  }

  // Method untuk scroll ke produk yang di-highlight
  void _scrollToHighlightedProduct() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_highlightedProductId != null) {
        final index = _filteredProducts.indexWhere(
          (product) => product.id == _highlightedProductId,
        );
        
        if (index != -1 && _scrollController.hasClients) {
          // Scroll ke item yang di-highlight
          _scrollController.animateTo(
            index * 80.0, // Estimasi tinggi setiap card (bisa disesuaikan)
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          
          // Hapus highlight setelah 3 detik
          Future.delayed(Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _highlightedProductId = null;
              });
            }
          });
        }
      }
    });
  }

  void _searchProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products
            .where((product) =>
                product.namaProduk.toLowerCase().contains(query.toLowerCase()) ||
                (product.deskripsi?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
    });

    // Jika sedang search dan ada highlight, scroll lagi ke item yang di-highlight
    if (_highlightedProductId != null && query.isEmpty) {
      _scrollToHighlightedProduct();
    }
  }

  Future<void> _deleteProduct(Product product) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "${product.namaProduk}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _productService.deleteProduct(product.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product deleted successfully')),
        );
        _loadProducts(); // Reload products
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    }
  }

  void _editProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    ).then((_) {
      // Reload products when returning from edit screen
      _loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inventory')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _searchProducts,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchProducts('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Products List
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, 
                                   size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty 
                                    ? 'No products found for "$_searchQuery"'
                                    : 'No products available',
                                style: TextStyle(
                                  fontSize: 16, 
                                  color: Colors.grey
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadProducts,
                          child: ListView.builder(
                            controller: _scrollController, // Tambahkan scroll controller
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              final isHighlighted = product.id == _highlightedProductId;
                              return _buildInventoryItem(product, isHighlighted);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductScreen()),
          ).then((_) {
            // Reload products when returning from add screen
            _loadProducts();
          });
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildInventoryItem(Product product, [bool isHighlighted = false]) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 8),
      // Tambahkan highlight dengan warna berbeda
      color: isHighlighted ? Colors.blue.withOpacity(0.1) : null,
      elevation: isHighlighted ? 8 : 1,
      child: Container(
        decoration: isHighlighted
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 2),
              )
            : null,
        child: ListTile(
          leading: product.gambarProduk != null && product.gambarProduk!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.gambarProduk!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
                )
              : Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.inventory, color: Colors.grey),
                ),
          title: Text(
            product.namaProduk,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isHighlighted ? Colors.blue[800] : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${product.jumlahProduk} in Stock',
                style: TextStyle(
                  // FIXED: Gunakan dynamic logic berdasarkan stok minimal per produk
                  color: product.isLowStock ? Colors.red : Colors.grey[600],
                  fontWeight: isHighlighted ? FontWeight.w500 : null,
                ),
              ),
              if (product.deskripsi != null && product.deskripsi!.isNotEmpty)
                Text(
                  product.deskripsi!,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Rp ${product.hargaJual.toString()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isHighlighted ? Colors.blue[700] : Colors.green[700],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editProduct(product);
                  } else if (value == 'delete') {
                    _deleteProduct(product);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
                child: Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }
}