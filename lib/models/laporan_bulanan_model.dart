// models/laporan_bulanan_model.dart
import 'package:intl/intl.dart';

class LaporanBulanan {
  final String? id;
  final String produkId;
  final String? idPengadaan;
  final int bulan;
  final int tahun;
  final int totalPengadaan;
  final int? totalPendapatan; // ← Tambahkan ini
  
  final String? namaProduk;

  LaporanBulanan({
    this.id,
    required this.produkId,
    this.idPengadaan,
    required this.bulan,
    required this.tahun,
    required this.totalPengadaan,
    this.totalPendapatan, // ← Tambahkan ini
    this.namaProduk,
  });

  factory LaporanBulanan.fromJson(Map<String, dynamic> json) {
    return LaporanBulanan(
      id: json['id_laporan_bulanan'],
      produkId: json['produk_id'],
      idPengadaan: json['id_pengadaan'],
      bulan: json['bulan'],
      tahun: json['tahun'],
      totalPengadaan: json['total_pengadaan'],
      totalPendapatan: json['total_pendapatan'], // ← Tambahkan ini
      namaProduk: json['nama_produk'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'produk_id': produkId,
      'id_pengadaan': idPengadaan,
      'bulan': bulan,
      'tahun': tahun,
      'total_pengadaan': totalPengadaan,
      'total_pendapatan': totalPendapatan, // ← Tambahkan ini
    };
    
    if (id != null) {
      map['id_laporan_bulanan'] = id;
    }
    
    return map;
  }

  LaporanBulanan copyWith({
    String? id,
    String? produkId,
    String? idPengadaan,
    int? bulan,
    int? tahun,
    int? totalPengadaan,
    int? totalPendapatan, // ← Tambahkan ini
    String? namaProduk,
  }) {
    return LaporanBulanan(
      id: id ?? this.id,
      produkId: produkId ?? this.produkId,
      idPengadaan: idPengadaan ?? this.idPengadaan,
      bulan: bulan ?? this.bulan,
      tahun: tahun ?? this.tahun,
      totalPengadaan: totalPengadaan ?? this.totalPengadaan,
      totalPendapatan: totalPendapatan ?? this.totalPendapatan, // ← Tambahkan ini
      namaProduk: namaProduk ?? this.namaProduk,
    );
  }
  
  // Helper untuk mendapatkan nama bulan
  String getNamaBulan() {
    final List<String> namaBulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return namaBulan[bulan - 1]; // Bulan 1-12 disesuaikan dengan index 0-11
  }
  
  // Helper untuk mendapatkan periode formatted
  String getPeriodeFormatted() {
    return '${getNamaBulan()} $tahun';
  }
  
  // Helper untuk format rupiah
  String getTotalPengadaanFormatted() {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return currencyFormatter.format(totalPengadaan);
  }
}