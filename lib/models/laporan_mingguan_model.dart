// models/laporan_mingguan_model.dart
import 'package:intl/intl.dart';

class LaporanMingguan {
  final String? id;
  final String produkId;
  final String? idPendapatan;
  final DateTime tanggalAwal;
  final DateTime tanggalAkhir;
  final int totalPendapatan;
  
  // Tambahan field untuk join data (opsional)
  final String? namaProduk;

  LaporanMingguan({
    this.id,
    required this.produkId,
    this.idPendapatan,
    required this.tanggalAwal,
    required this.tanggalAkhir,
    required this.totalPendapatan,
    this.namaProduk,
  });

  factory LaporanMingguan.fromJson(Map<String, dynamic> json) {
    return LaporanMingguan(
      id: json['id_laporan_mingguan'],
      produkId: json['produk_id'],
      idPendapatan: json['id_pendapatan'],
      tanggalAwal: json['tanggal_awal'] is String 
          ? DateTime.parse(json['tanggal_awal']) 
          : DateTime.fromMillisecondsSinceEpoch(json['tanggal_awal']),
      tanggalAkhir: json['tanggal_akhir'] is String 
          ? DateTime.parse(json['tanggal_akhir']) 
          : DateTime.fromMillisecondsSinceEpoch(json['tanggal_akhir']),
      totalPendapatan: json['total_pendapatan'],
      namaProduk: json['nama_produk'],
    );
  }

  Map<String, dynamic> toJson() {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final map = {
      'produk_id': produkId,
      'id_pendapatan': idPendapatan,
      'tanggal_awal': formatter.format(tanggalAwal),
      'tanggal_akhir': formatter.format(tanggalAkhir),
      'total_pendapatan': totalPendapatan,
    };
    
    if (id != null) {
      map['id_laporan_mingguan'] = id;
    }
    
    return map;
  }

  LaporanMingguan copyWith({
    String? id,
    String? produkId,
    String? idPendapatan,
    DateTime? tanggalAwal,
    DateTime? tanggalAkhir,
    int? totalPendapatan,
    String? namaProduk,
  }) {
    return LaporanMingguan(
      id: id ?? this.id,
      produkId: produkId ?? this.produkId,
      idPendapatan: idPendapatan ?? this.idPendapatan,
      tanggalAwal: tanggalAwal ?? this.tanggalAwal,
      tanggalAkhir: tanggalAkhir ?? this.tanggalAkhir,
      totalPendapatan: totalPendapatan ?? this.totalPendapatan,
      namaProduk: namaProduk ?? this.namaProduk,
    );
  }
  
  // Helper untuk mendapatkan rentang waktu formatted
  String getPeriodeFormatted() {
    final DateFormat formatter = DateFormat('dd MMM yyyy', 'id_ID');
    return '${formatter.format(tanggalAwal)} - ${formatter.format(tanggalAkhir)}';
  }
  
  // Helper untuk format rupiah
  String getTotalPendapatanFormatted() {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return currencyFormatter.format(totalPendapatan);
  }
}