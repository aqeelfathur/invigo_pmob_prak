import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InputPengadaanScreen extends StatefulWidget {
  @override
  _InputPengadaanScreenState createState() => _InputPengadaanScreenState();
}

class _InputPengadaanScreenState extends State<InputPengadaanScreen> {
  // Controllers untuk input fields
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  String? _selectedItem;
  DateTime _selectedDate = DateTime.now();

  final List<String> _itemList = [
    'Laptop Asus ROG',
    'Monitor Samsung 24"',
    'Keyboard Mechanical',
    'Mouse Wireless',
    'Headset Gaming',
    'SSD 1TB',
    'RAM DDR4 16GB',
    'UPS 1000VA',
    'Kabel HDMI 2m',
    'Flashdisk 64GB'
  ];

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

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Pengadaan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Produk: ${_selectedItem ?? "Belum dipilih"}'),
            Text('Jumlah: ${_jumlahController.text}'),
            Text('Supplier: ${_supplierController.text}'),
            Text('Tanggal: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
            Text('Deskripsi: ${_deskripsiController.text}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              // Di sini nanti untuk proses penyimpanan ke database
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Data pengadaan berhasil disimpan')),
              );
              Navigator.pop(context); // Tutup dialog

              // Reset form
              setState(() {
                _selectedItem = null;
                _jumlahController.clear();
                _supplierController.clear();
                _deskripsiController.clear();
                _selectedDate = DateTime.now();
              });
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  bool _validateForm() {
    if (_selectedItem == null || _selectedItem!.isEmpty) {
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Nama Barang',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                value: _selectedItem,
                hint: Text('Pilih barang'),
                isExpanded: true,
                items: _itemList.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedItem = newValue;
                  });
                },
              ),

              SizedBox(height: 16),

              TextField(
                controller: _jumlahController,
                decoration: InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),

              SizedBox(height: 16),

              TextField(
                controller: _supplierController,
                decoration: InputDecoration(
                  labelText: 'Supplier',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
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

              TextField(
                controller: _deskripsiController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),

              SizedBox(height: 24),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                icon: Icon(Icons.save),
                label: Text('SIMPAN', style: TextStyle(fontSize: 16)),
                onPressed: () {
                  if (_validateForm()) {
                    _showConfirmationDialog();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
