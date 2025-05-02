import 'package:flutter/material.dart';
import 'package:testing/pages/custom_drawer.dart';
import 'package:testing/pages/main_screen.dart';
import 'package:testing/pages/inventory_detail_screen.dart';

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
  @override
  Widget build(BuildContext context) {
    return _buildListTile(
      Icons.inventory,
      'Items',
      '150 items',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => InventoryDetailScreen()),
        );
      },
    );
  }
}

class LowStockAlert extends StatelessWidget {
  final List<Map<String, dynamic>> inventory = [
    {"name": "Coca Cola", "stock": 36},
    {"name": "Doritos", "stock": 30},
    {"name": "Lays", "stock": 5},
    {"name": "Apples", "stock": 2},
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> lowStockItems =
        inventory.where((item) => item["stock"] < 10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Low Stock Alert",
            style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                color: Colors.black)),
        if (lowStockItems.isEmpty)
          Text("All items are in sufficient stock.",
              style: TextStyle(color: Colors.grey))
        else
          Column(
            children: lowStockItems.map((item) {
              return _buildListTile(
                Icons.warning,
                item["name"],
                "Stock: ${item["stock"]} (Low!)",
              );
            }).toList(),
          ),
      ],
    );
  }
}

Widget _buildListTile(IconData icon, String title, String subtitle,
    {VoidCallback? onTap}) {
  return Card(
    elevation: 4,
    child: ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.arrow_forward),
      onTap: () {
        if (onTap != null) {
          onTap();
        }
      },
    ),
  );
}
