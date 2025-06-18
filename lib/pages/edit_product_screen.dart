import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  
  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _supplierPriceController;
  late TextEditingController _sellPriceController;
  late TextEditingController _minStockController;
  late TextEditingController _imageUrlController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.product.namaProduk);
    _descriptionController = TextEditingController(text: widget.product.deskripsi ?? '');
    _quantityController = TextEditingController(text: widget.product.jumlahProduk.toString());
    _supplierPriceController = TextEditingController(text: widget.product.hargaSupplier.toString());
    _sellPriceController = TextEditingController(text: widget.product.hargaJual.toString());
    _minStockController = TextEditingController(text: widget.product.stokMinimal.toString());
    _imageUrlController = TextEditingController(text: widget.product.gambarProduk ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _supplierPriceController.dispose();
    _sellPriceController.dispose();
    _minStockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProduct = widget.product.copyWith(
        namaProduk: _nameController.text.trim(),
        deskripsi: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        jumlahProduk: int.parse(_quantityController.text),
        hargaSupplier: int.parse(_supplierPriceController.text),
        hargaJual: int.parse(_sellPriceController.text),
        stokMinimal: _minStockController.text.isEmpty 
            ? 0 
            : int.parse(_minStockController.text),
        gambarProduk: _imageUrlController.text.trim().isEmpty 
            ? null 
            : _imageUrlController.text.trim(),
      );

      await _productService.updateProduct(updatedProduct);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "${widget.product.namaProduk}"? This action cannot be undone.'),
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
      setState(() {
        _isLoading = true;
      });

      try {
        await _productService.deleteProduct(widget.product.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Product'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: _isLoading ? null : _deleteProduct,
            tooltip: 'Delete Product',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Image Preview
              if (_imageUrlController.text.isNotEmpty)
                Container(
                  height: 200,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _imageUrlController.text,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 48, color: Colors.grey),
                              Text('Invalid image URL', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // Image URL Input
              _buildTextFormField(
                controller: _imageUrlController,
                label: 'Image URL (Optional)',
                hint: 'Enter image URL',
                prefixIcon: Icons.image,
              ),
              SizedBox(height: 16),

              // Product Name (Required)
              _buildTextFormField(
                controller: _nameController,
                label: 'Product Name *',
                hint: 'Enter product name',
                prefixIcon: Icons.inventory,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Product name is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Description (Optional)
              _buildTextFormField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Enter product description',
                prefixIcon: Icons.description,
                maxLines: 3,
              ),
              SizedBox(height: 16),

              // Quantity and Min Stock
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _quantityController,
                      label: 'Quantity *',
                      hint: '0',
                      prefixIcon: Icons.numbers,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Quantity is required';
                        }
                        final quantity = int.tryParse(value);
                        if (quantity == null || quantity < 0) {
                          return 'Enter valid quantity';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildTextFormField(
                      controller: _minStockController,
                      label: 'Min Stock',
                      hint: '0',
                      prefixIcon: Icons.warning,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Supplier Price and Sell Price
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _supplierPriceController,
                      label: 'Supplier Price *',
                      hint: '0',
                      prefixIcon: Icons.monetization_on,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Supplier price is required';
                        }
                        final price = int.tryParse(value);
                        if (price == null || price < 0) {
                          return 'Enter valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildTextFormField(
                      controller: _sellPriceController,
                      label: 'Sell Price *',
                      hint: '0',
                      prefixIcon: Icons.sell,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Sell price is required';
                        }
                        final price = int.tryParse(value);
                        if (price == null || price < 0) {
                          return 'Enter valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Update Product',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}