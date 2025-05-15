import 'package:flutter/material.dart';
import 'package:invigo/pages/custom_drawer.dart';
import 'package:invigo/pages/main_screen.dart';
import 'package:invigo/pages/monthly_report_screen.dart';
import 'package:invigo/pages/weekly_report_screen.dart';
import 'package:invigo/widgets/build_list_tile.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int monthlyReports = 1;
  int weeklyReports = 4;

  void updateReports() {
    setState(() {
      monthlyReports += 1;
      weeklyReports += 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MonthlyReportScreen(),
                  ),
                );
              },
              child: buildListTile(
                Icons.bar_chart,
                'Report in Month',
                '$monthlyReports Reports',
              ),
            ),
            SizedBox(height: 16),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeeklyReportScreen(),
                  ),
                );
              },
              child: buildListTile(
                Icons.bar_chart,
                'Reports in Week',
                '$weeklyReports Reports',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: updateReports,
              child: Text('Update Reports'),
            ),
          ],
        ),
      ),
    );
  }
}
