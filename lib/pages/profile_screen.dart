import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:testing/pages/custom_drawer.dart';
import 'package:testing/pages/main_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _image;
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, size: 28),
            onPressed: () {},
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : AssetImage('assets/profile.jpg') as ImageProvider,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Kevin Azaris',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'kevin.azaris-2023@fst.unair.ac.id',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.business),
              title: Text('My Company'),
              subtitle: Text('Innovative IT Solutions, Delivered Fast'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.visibility),
              title: Text('View'),
              subtitle: Text('Dreams inspire actions, shaping destinies.'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.price_change),
              title: Text('Prices'),
              subtitle: Text('Prices fluctuate; shop smartly, wisely.'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.qr_code_scanner),
              title: Text('Barcode Scanner'),
              subtitle: Text('Scan barcodes quickly and easily.'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.storage),
              title: Text('Databases'),
              subtitle: Text('Database store and organize data efficiently.'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
