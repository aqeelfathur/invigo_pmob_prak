import 'package:flutter/material.dart';
import 'add_product_screen.dart';

class InventoryDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inventory')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildInventoryItem(
                    'Coca Cola',
                    'Soft Drink',
                    36,
                    15.00,
                    '36985214753951',
                    'https://upload.wikimedia.org/wikipedia/commons/3/3f/Coca-Cola_logo.svg',
                  ),
                  _buildInventoryItem(
                    'Doritos',
                    'Snacks',
                    30,
                    5.00,
                    '36985214753951',
                    'https://upload.wikimedia.org/wikipedia/en/2/22/Doritos-Logo.png',
                  ),
                  _buildInventoryItem(
                    'Lays',
                    'Snacks',
                    40,
                    12.00,
                    '36985214753951',
                    'https://upload.wikimedia.org/wikipedia/en/6/69/Lay%27s_logo.png',
                  ),
                  _buildInventoryItem(
                    'Apples',
                    'Box',
                    20,
                    40.00,
                    '36985214753951',
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Red_Apple.jpg/600px-Red_Apple.jpg',
                  ),
                ],
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
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildInventoryItem(
    String name,
    String category,
    int stock,
    double price,
    String barcode,
    String imageUrl,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Image.network(
          imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.broken_image, size: 50, color: Colors.red);
          },
        ),
        title: Text('$name ($category)'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$stock in Stock'),
            Text(barcode, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing:
            Text('\$$price', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
