// screens/daily_income_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/pendapatan_service.dart';

class DailyIncomeScreen extends StatefulWidget {
  @override
  _DailyIncomeScreenState createState() => _DailyIncomeScreenState();
}

class _DailyIncomeScreenState extends State<DailyIncomeScreen> {
  // Controllers untuk input fields
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  // Services
  final ProductService _productService = ProductService();
  final PendapatanService _pendapatanService = PendapatanService();

  // State variables
  Product? _selectedProduct;
  DateTime _selectedDate = DateTime.now();
  List<Product> _productList = [];
  bool _isLoading = false;
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Load products from database
  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoadingProducts = true;
      });

      final products = await _productService.getAllProducts();
      setState(() {
        _productList = products.where((p) => p.jumlahProduk > 0).toList(); // Only show products with stock
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // Can't select future dates for income
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _savePendapatan() async {
    if (!_validateForm()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await _pendapatanService.addPendapatan(
        produkId: _selectedProduct!.id!,
        jumlahProduk: int.parse(_jumlahController.text),
        tanggalPendapatan: _selectedDate,
        catatan: _catatanController.text.isEmpty ? null : _catatanController.text,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data pendapatan berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form and reload products to update stock
      _resetForm();
      _loadProducts();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _selectedProduct = null;
      _jumlahController.clear();
      _catatanController.clear();
      _selectedDate = DateTime.now();
    });
  }

  void _showConfirmationDialog() {
    final int quantity = int.parse(_jumlahController.text);
    final int totalRevenue = (_selectedProduct?.hargaJual ?? 0) * quantity;
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Pendapatan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Produk: ${_selectedProduct?.namaProduk ?? "Belum dipilih"}'),
            Text('Jumlah terjual: $quantity'),
            Text('Harga satuan: ${currencyFormatter.format(_selectedProduct?.hargaJual ?? 0)}'),
            Text('Total pendapatan: ${currencyFormatter.format(totalRevenue)}'),
            Text('Tanggal: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
            if (_catatanController.text.isNotEmpty)
              Text('Catatan: ${_catatanController.text}'),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Text(
                'Stok akan berkurang dari ${_selectedProduct?.jumlahProduk ?? 0} menjadi ${(_selectedProduct?.jumlahProduk ?? 0) - quantity}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _savePendapatan();
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  bool _validateForm() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silakan pilih produk')),
      );
      return false;
    }

    if (_jumlahController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jumlah tidak boleh kosong')),
      );
      return false;
    }

    final jumlah = int.tryParse(_jumlahController.text);
    if (jumlah == null || jumlah <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jumlah harus berupa angka positif')),
      );
      return false;
    }

    if (jumlah > _selectedProduct!.jumlahProduk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jumlah melebihi stok tersedia (${_selectedProduct!.jumlahProduk})')),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Input Pendapatan'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: _isLoadingProducts
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                physics: BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // Product Dropdown
                    DropdownButtonFormField<Product>(
                      decoration: InputDecoration(
                        labelText: 'Pilih Produk',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory),
                      ),
                      value: _selectedProduct,
                      hint: Text('Pilih produk yang terjual'),
                      isExpanded: true,
                      items: _productList.map((Product product) {
                        return DropdownMenuItem<Product>(
                          value: product,
                          child: Container(
                            width: double.infinity,
                            child: RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style,
                                children: [
                                  TextSpan(
                                    text: product.namaProduk,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' (Stok: ${product.jumlahProduk})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: product.isLowStock ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' • ${currencyFormatter.format(product.hargaJual)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (Product? newValue) {
                        setState(() {
                          _selectedProduct = newValue;
                          _jumlahController.clear(); // Reset quantity when product changes
                        });
                      },
                    ),

                    SizedBox(height: 16),

                    // Product Info
                    if (_selectedProduct != null)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stok tersedia: ${_selectedProduct!.jumlahProduk}',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Harga jual: ${currencyFormatter.format(_selectedProduct!.hargaJual)}',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  if (_selectedProduct!.isLowStock)
                                    Text(
                                      'Peringatan: Stok rendah!',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 16),

                    // Quantity Input
                    TextField(
                      controller: _jumlahController,
                      decoration: InputDecoration(
                        labelText: 'Jumlah Terjual',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_cart),
                        helperText: _selectedProduct != null 
                            ? 'Maksimal: ${_selectedProduct!.jumlahProduk}'
                            : 'Masukkan jumlah produk yang terjual',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {}); // Refresh untuk update preview
                      },
                    ),

                    SizedBox(height: 16),

                    // Date picker
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Tanggal Penjualan',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                            Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Notes Input
                    TextField(
                      controller: _catatanController,
                      decoration: InputDecoration(
                        labelText: 'Catatan (Opsional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                        helperText: 'Catatan tambahan untuk penjualan ini',
                      ),
                      maxLines: 3,
                    ),

                    SizedBox(height: 16),

                    // Revenue Preview
                    if (_selectedProduct != null && _jumlahController.text.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.monetization_on, color: Colors.green),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Total Pendapatan:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${_jumlahController.text} × ${currencyFormatter.format(_selectedProduct!.hargaJual)} = ${currencyFormatter.format(_selectedProduct!.hargaJual * (int.tryParse(_jumlahController.text) ?? 0))}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Sisa stok: ${_selectedProduct!.jumlahProduk - (int.tryParse(_jumlahController.text) ?? 0)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 24),

                    // Save Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      icon: _isLoading 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.save),
                      label: Text(
                        _isLoading ? 'MENYIMPAN...' : 'SIMPAN PENDAPATAN',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: _isLoading ? null : () {
                        if (_validateForm()) {
                          _showConfirmationDialog();
                        }
                      },
                    ),

                    SizedBox(height: 20),

                    // Reset Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      icon: Icon(Icons.refresh),
                      label: Text('RESET FORM'),
                      onPressed: _isLoading ? null : _resetForm,
                    ),

                    SizedBox(height: 20),

                    // Info Card
                    if (_productList.isEmpty)
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tidak ada produk dengan stok tersedia. Lakukan pengadaan terlebih dahulu.',
                                style: TextStyle(color: Colors.orange[700]),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Bottom padding untuk space
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    ));
  }
}