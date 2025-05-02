import 'package:flutter/material.dart';
import 'package:testing/pages/custom_drawer.dart';
import 'package:testing/pages/main_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, size: 28),
            onPressed: () {},
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 15),
            Text(
              'Hello, Aqeel!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.normal,
              ),
            ),
            SizedBox(height: 15),
            Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildGridCard(
                          context, '3', 'Total Item', Icons.warehouse_outlined),
                      _buildGridCard(context, '0', 'Total Stok',
                          Icons.inventory_2_outlined),
                    ],
                  ),
                  Row(
                    children: [
                      _buildGridCard(context, '0', 'Produk Stok Tipis',
                          Icons.warning_amber),
                      _buildGridCard(context, '0', 'Produk Stok Habis',
                          Icons.hourglass_disabled),
                    ],
                  ),
                ]),
            SizedBox(height: 28),
            Text(
              'Laporan Hari Ini',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 15),
            SizedBox(
              height: 220,
              child: ListView.separated(
                itemBuilder: (BuildContext context, int index) {
                  return _LaporanCard();
                },
                separatorBuilder: (BuildContext context, int index) {
                  return SizedBox(width: 16);
                },
                itemCount: 5,
                scrollDirection: Axis.horizontal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(
      BuildContext context, String value, String label, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8)),
                    child: Center(
                      child: Icon(icon, size: 30),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LaporanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(14),
        width: 260,
        height: 200,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Produk 1',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Divider(thickness: 1.5),
            SizedBox(height: 16),
            Text(
              'Produk Terjual',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '12',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Pendapatan',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Text('Rp 7.000.000')
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Pengeluaran',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Text('Rp 1.400.000')
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
