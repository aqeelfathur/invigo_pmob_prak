// models/pendapatan_model.dart
import 'package:intl/intl.dart';

class Pendapatan {
  final String? id;
  final int jumlahProdukPendapatan;
  final DateTime tanggalPendapatan;
  final String? catatanPendapatan;
  final String produkId;
  final String userId;
  
  // Tambahan field untuk join data (opsional)
  final String? namaProduk;
  final int? hargaJual;
  final String? namaUser;

  Pendapatan({
    this.id,
    required this.jumlahProdukPendapatan,
    required this.tanggalPendapatan,
    this.catatanPendapatan,
    required this.produkId,
    required this.userId,
    this.namaProduk,
    this.hargaJual,
    this.namaUser,
  });

  factory Pendapatan.fromJson(Map<String, dynamic> json) {
    return Pendapatan(
      id: json['id_pendapatan'],
      jumlahProdukPendapatan: json['jumlah_produk_pendapatan'],
      tanggalPendapatan: json['tanggal_pendapatan'] is String 
          ? DateTime.parse(json['tanggal_pendapatan']) 
          : DateTime.fromMillisecondsSinceEpoch(json['tanggal_pendapatan']),
      catatanPendapatan: json['catatan_pendapatan'],
      produkId: json['produk_id'],
      userId: json['id_user'],
      // Data join (opsional)
      namaProduk: json['nama_produk'],
      hargaJual: json['harga_jual'],
      namaUser: json['nama_lengkap'],
    );
  }

  Map<String, dynamic> toJson() {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final map = {
      'jumlah_produk_pendapatan': jumlahProdukPendapatan,
      'tanggal_pendapatan': formatter.format(tanggalPendapatan),
      'catatan_pendapatan': catatanPendapatan,
      'produk_id': produkId,
      'id_user': userId,
    };
    
    if (id != null) {
      map['id_pendapatan'] = id;
    }
    
    return map;
  }

  Pendapatan copyWith({
    String? id,
    int? jumlahProdukPendapatan,
    DateTime? tanggalPendapatan,
    String? catatanPendapatan,
    String? produkId,
    String? userId,
    String? namaProduk,
    int? hargaJual,
    String? namaUser,
  }) {
    return Pendapatan(
      id: id ?? this.id,
      jumlahProdukPendapatan: jumlahProdukPendapatan ?? this.jumlahProdukPendapatan,
      tanggalPendapatan: tanggalPendapatan ?? this.tanggalPendapatan,
      catatanPendapatan: catatanPendapatan ?? this.catatanPendapatan,
      produkId: produkId ?? this.produkId,
      userId: userId ?? this.userId,
      namaProduk: namaProduk ?? this.namaProduk,
      hargaJual: hargaJual ?? this.hargaJual,
      namaUser: namaUser ?? this.namaUser,
    );
  }
  
  // Helper untuk mendapatkan total nilai pendapatan (jika data harga tersedia)
  int? getTotalNilai() {
    if (hargaJual != null) {
      return jumlahProdukPendapatan * hargaJual!;
    }
    return null;
  }
  
  // Helper untuk format tanggal
  String getTanggalFormatted() {
    final DateFormat formatter = DateFormat('dd MMMM yyyy', 'id_ID');
    return formatter.format(tanggalPendapatan);
  }
}