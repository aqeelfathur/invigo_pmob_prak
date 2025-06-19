import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invigo/models/laporan_mingguan_model.dart';
import 'package:invigo/services/weekly_report_service.dart';

class WeeklyReportScreen extends StatefulWidget {
  @override
  _WeeklyReportScreenState createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final WeeklyReportService _weeklyReportService = WeeklyReportService();
  List<LaporanMingguan> _laporanList = [];
  bool _isLoading = true;
  final DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadWeeklyReport();
  }

  Future<void> _loadWeeklyReport() async {
    try {
      // Ambil laporan dari seminggu terakhir
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(Duration(days: 6));

      final data = await _weeklyReportService.getLaporanMingguan(
        tanggalAwal: startOfWeek,
        tanggalAkhir: endOfWeek,
      );

      setState(() {
        _laporanList = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading laporan mingguan: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  int get totalPendapatan =>
      _laporanList.fold(0, (sum, item) => sum + item.totalPendapatan);

  String formatRupiah(int value) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0)
        .format(value);
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat rangeFormat = DateFormat('dd MMM');
    final weekRange = _laporanList.isEmpty
        ? ''
        : '${rangeFormat.format(_laporanList.first.tanggalAwal)} - ${rangeFormat.format(_laporanList.first.tanggalAkhir)}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Weekly Reports'),
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
                    'Weekly Reports Overview',
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
                          Text(
                            'Periode: $weekRange',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text('Total Pendapatan',
                                        style:
                                            TextStyle(color: Colors.grey[600])),
                                    SizedBox(height: 4),
                                    Text(
                                      formatRupiah(totalPendapatan),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
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
                        ? Center(
                            child: Text('Tidak ada laporan untuk minggu ini.'))
                        : ListView.separated(
                            itemCount: _laporanList.length,
                            separatorBuilder: (_, __) => Divider(),
                            itemBuilder: (context, index) {
                              final laporan = _laporanList[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Icon(Icons.inventory, color: Colors.blue),
                                ),
                                title: Text(laporan.namaProduk ?? 'Produk'),
                                subtitle:
                                    Text(laporan.getPeriodeFormatted()),
                                trailing: Text(
                                  laporan.getTotalPendapatanFormatted(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700]),
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
