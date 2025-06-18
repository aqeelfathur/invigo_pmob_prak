// screens/input_pengadaan_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/pengadaan_service.dart';

class InputPengadaanScreen extends StatefulWidget {
  @override
  _InputPengadaanScreenState createState() => _InputPengadaanScreenState();
}

class _InputPengadaanScreenState extends State<InputPengadaanScreen> {
  // Controllers untuk input fields
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  // Services
  final ProductService _productService = ProductService();
  final PengadaanService _pengadaanService = PengadaanService();

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
        _productList = products;
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
      lastDate: DateTime(2030),
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
    _supplierController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _savePengadaan() async {
    if (!_validateForm()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await _pengadaanService.addPengadaan(
        produkId: _selectedProduct!.id!,
        jumlahProduk: int.parse(_jumlahController.text),
        supplier: _supplierController.text,
        tanggalPengadaan: _selectedDate,
        deskripsi: _deskripsiController.text.isEmpty ? null : _deskripsiController.text,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data pengadaan berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      _resetForm();

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
      _supplierController.clear();
      _deskripsiController.clear();
      _selectedDate = DateTime.now();
    });
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Pengadaan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Produk: ${_selectedProduct?.namaProduk ?? "Belum dipilih"}'),
            Text('Jumlah: ${_jumlahController.text}'),
            Text('Supplier: ${_supplierController.text}'),
            Text('Tanggal: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
            if (_deskripsiController.text.isNotEmpty)
              Text('Deskripsi: ${_deskripsiController.text}'),
            SizedBox(height: 10),
            Text(
              'Stok produk akan bertambah dari ${_selectedProduct?.jumlahProduk ?? 0} menjadi ${(_selectedProduct?.jumlahProduk ?? 0) + int.parse(_jumlahController.text)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
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
              _savePengadaan();
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

    if (_supplierController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Supplier tidak boleh kosong')),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Input Pengadaan'),
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
                      hint: Text('Pilih produk yang akan diadakan'),
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
                        });
                      },
                    ),

                    SizedBox(height: 16),

                    // Current Stock Info
                    if (_selectedProduct != null)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedProduct!.isLowStock ? Colors.red[50] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedProduct!.isLowStock ? Colors.red[200]! : Colors.blue[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedProduct!.isLowStock ? Icons.warning : Icons.info,
                              color: _selectedProduct!.isLowStock ? Colors.red : Colors.blue,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stok saat ini: ${_selectedProduct!.jumlahProduk}',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Stok minimal: ${_selectedProduct!.stokMinimal}',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  if (_selectedProduct!.isLowStock)
                                    Text(
                                      'Stok rendah! Perlu pengadaan',
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
                        labelText: 'Jumlah Pengadaan',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                        helperText: 'Masukkan jumlah barang yang akan diadakan',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {}); // Refresh untuk update preview
                      },
                    ),

                    SizedBox(height: 16),

                    // Supplier Input
                    TextField(
                      controller: _supplierController,
                      decoration: InputDecoration(
                        labelText: 'Nama Supplier',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                        helperText: 'Masukkan nama supplier/pemasok',
                      ),
                    ),

                    SizedBox(height: 16),

                    // Date picker
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Tanggal Pengadaan',
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

                    // Description Input
                    TextField(
                      controller: _deskripsiController,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi (Opsional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        helperText: 'Catatan tambahan untuk pengadaan ini',
                      ),
                      maxLines: 3,
                    ),

                    SizedBox(height: 16),

                    // Stock Preview
                    if (_selectedProduct != null && _jumlahController.text.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.trending_up, color: Colors.green),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Stok setelah pengadaan: ${_selectedProduct!.jumlahProduk} + ${_jumlahController.text} = ${_selectedProduct!.jumlahProduk + (int.tryParse(_jumlahController.text) ?? 0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                  fontSize: 13,
                                ),
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
                        backgroundColor: Colors.blue,
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
                        _isLoading ? 'MENYIMPAN...' : 'SIMPAN PENGADAAN',
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

                    // Bottom padding untuk space
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    ));
  }
}