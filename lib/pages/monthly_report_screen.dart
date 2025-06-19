import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invigo/models/laporan_bulanan_model.dart';
import 'package:invigo/services/report_service.dart';

class MonthlyReportScreen extends StatefulWidget {
  @override
  _MonthlyReportScreenState createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final ReportService _reportService = ReportService();
  List<LaporanBulanan> _laporanList = [];
  bool _isLoading = true;
  final now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMonthlyReport();
  }

  Future<void> _loadMonthlyReport() async {
    try {
      final data = await _reportService.getLaporanBulanan(
        bulan: now.month,
        tahun: now.year,
      );
      setState(() {
        _laporanList = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading laporan bulanan: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  double get totalPengadaan =>
      _laporanList.fold(0.0, (sum, item) => sum + item.totalPengadaan);

  double get totalPendapatan =>
      _laporanList.fold(0.0, (sum, item) => sum + (item.totalPendapatan ?? 0));

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(now);

    return Scaffold(
      appBar: AppBar(
        title: Text('Monthly Reports'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Reports Overview',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                monthName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(Icons.more_vert),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text('Total Pengadaan',
                                        style: TextStyle(color: Colors.grey[600])),
                                    SizedBox(height: 4),
                                    Text(
                                      '$totalPengadaan',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text('Total Keluar',
                                        style: TextStyle(color: Colors.grey[600])),
                                    SizedBox(height: 4),
                                    Text(
                                      '$totalPendapatan',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: _laporanList.isEmpty
                        ? Center(child: Text('Tidak ada laporan untuk bulan ini.'))
                        : ListView.separated(
                            itemCount: _laporanList.length,
                            separatorBuilder: (_, __) => Divider(),
                            itemBuilder: (context, index) {
                              final laporan = _laporanList[index];
                              final selisih = laporan.totalPengadaan - (laporan.totalPendapatan ?? 0);
                              final warna = selisih >= 0 ? Colors.green : Colors.red;
                              final simbol = selisih >= 0 ? '+' : '-';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Icon(Icons.inventory, color: Colors.blue),
                                ),
                                title: Text('${laporan.namaProduk ?? 'Produk'}'),
                                trailing: Text(
                                  '$simbol${selisih.abs()}',
                                  style: TextStyle(
                                    color: warna,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
