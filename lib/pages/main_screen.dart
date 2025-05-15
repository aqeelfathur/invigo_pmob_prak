import 'package:flutter/material.dart';
import 'package:invigo/pages/custom_drawer.dart';
import 'package:invigo/pages/daily_income_screen.dart';
import 'package:invigo/pages/home_screen.dart';
import 'package:invigo/pages/input_pengadaan_screen.dart';
import 'package:invigo/pages/inventory_screen.dart';
import 'package:invigo/pages/profile_screen.dart';
import 'package:invigo/pages/reports_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    InventoryScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    print("Bottom Navigation tapped: $index");
    setState(() {
      _selectedIndex = index;
    });
    print("Selected index after setState: $_selectedIndex");
  }

  void _handleDrawerTap(int index) {
    print("Drawer tapped: $index");
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });
      print("Updated index to: $_selectedIndex");
    } else {
      print("Invalid index: $index");
    }
    Navigator.pop(context); // Close the drawer
  }

  void _showInputOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.shopping_cart),
                title: Text('Input Pengadaan'),
                onTap: () {
                  Navigator.pop(context); // Tutup bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => InputPengadaanScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.attach_money),
                title: Text('Daily Income'),
                onTap: () {
                  Navigator.pop(context); // Tutup bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DailyIncomeScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(
        onTap: _handleDrawerTap,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.warehouse), label: 'Warehouse'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          _showInputOptions(context);
        },
        child: Icon(Icons.add, size: 28, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
