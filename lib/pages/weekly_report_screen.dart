import 'package:flutter/material.dart';

class WeeklyReportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weekly Reports'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Reports Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            Container(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildWeekTab('Week 1', true),
                  SizedBox(width: 12),
                  _buildWeekTab('Week 2', false),
                  SizedBox(width: 12),
                  _buildWeekTab('Week 3', false),
                  SizedBox(width: 12),
                  _buildWeekTab('Week 4', false),
                ],
              ),
            ),

            SizedBox(height: 20),

            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Movement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildBarChart('Mon', 0.3, Colors.blue),
                          _buildBarChart('Tue', 0.5, Colors.blue),
                          _buildBarChart('Wed', 0.7, Colors.blue),
                          _buildBarChart('Thu', 0.4, Colors.blue),
                          _buildBarChart('Fri', 0.6, Colors.blue),
                          _buildBarChart('Sat', 0.2, Colors.blue),
                          _buildBarChart('Sun', 0.1, Colors.blue),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Detail laporan mingguan
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Week 1: April 1-7, 2025',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildReportItem(
                        'Total Transactions', '23', Icons.swap_horiz),
                    Divider(),
                    _buildReportItem(
                        'Items In', '15', Icons.arrow_downward, Colors.green),
                    Divider(),
                    _buildReportItem(
                        'Items Out', '8', Icons.arrow_upward, Colors.red),
                    Divider(),
                    _buildReportItem('Stock Changes', '+7',
                        Icons.compare_arrows, Colors.blue),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Tombol untuk mengunduh laporan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloading weekly report...')),
                  );
                },
                icon: Icon(Icons.download),
                label: Text('Download Report'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekTab(String title, bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(String day, double height, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 120 * height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        SizedBox(height: 8),
        Text(day, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildReportItem(String title, String value, IconData icon,
      [Color? color]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color != null ? color.withOpacity(0.1) : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color ?? Colors.grey[700]),
          ),
          SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
