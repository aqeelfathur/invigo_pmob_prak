// models/pengadaan_model.dart
import 'package:intl/intl.dart';

class Pengadaan {
  final String? id;
  final int jumlahProdukPengadaan;
  final DateTime tanggalPengadaan;
  final String? deskripsiPengadaan;
  final String produkId;
  final String userId;
  
  // Tambahan field untuk join data (opsional)
  final String? namaProduk;
  final int? hargaSupplier;
  final String? namaUser;

  Pengadaan({
    this.id,
    required this.jumlahProdukPengadaan,
    required this.tanggalPengadaan,
    this.deskripsiPengadaan,
    required this.produkId,
    required this.userId,
    this.namaProduk,
    this.hargaSupplier,
    this.namaUser,
  });

  factory Pengadaan.fromJson(Map<String, dynamic> json) {
    return Pengadaan(
      id: json['id_pengadaan'],
      jumlahProdukPengadaan: json['jumlah_produk_pengadaan'],
      tanggalPengadaan: json['tanggal_pengadaan'] is String 
          ? DateTime.parse(json['tanggal_pengadaan']) 
          : DateTime.fromMillisecondsSinceEpoch(json['tanggal_pengadaan']),
      deskripsiPengadaan: json['deskripsi_pengadaan'],
      produkId: json['produk_id'],
      userId: json['id_user'],
      // Data join (opsional)
      namaProduk: json['nama_produk'],
      hargaSupplier: json['harga_supplier'],
      namaUser: json['nama_lengkap'],
    );
  }

  Map<String, dynamic> toJson() {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final map = {
      'jumlah_produk_pengadaan': jumlahProdukPengadaan,
      'tanggal_pengadaan': formatter.format(tanggalPengadaan),
      'deskripsi_pengadaan': deskripsiPengadaan,
      'produk_id': produkId,
      'id_user': userId,
    };
    
    if (id != null) {
      map['id_pengadaan'] = id;
    }
    
    return map;
  }

  Pengadaan copyWith({
    String? id,
    int? jumlahProdukPengadaan,
    DateTime? tanggalPengadaan,
    String? deskripsiPengadaan,
    String? produkId,
    String? userId,
    String? namaProduk,
    int? hargaSupplier,
    String? namaUser,
  }) {
    return Pengadaan(
      id: id ?? this.id,
      jumlahProdukPengadaan: jumlahProdukPengadaan ?? this.jumlahProdukPengadaan,
      tanggalPengadaan: tanggalPengadaan ?? this.tanggalPengadaan,
      deskripsiPengadaan: deskripsiPengadaan ?? this.deskripsiPengadaan,
      produkId: produkId ?? this.produkId,
      userId: userId ?? this.userId,
      namaProduk: namaProduk ?? this.namaProduk,
      hargaSupplier: hargaSupplier ?? this.hargaSupplier,
      namaUser: namaUser ?? this.namaUser,
    );
  }
  
  // Helper untuk mendapatkan total nilai pengadaan (jika data harga tersedia)
  int? getTotalNilai() {
    if (hargaSupplier != null) {
      return jumlahProdukPengadaan * hargaSupplier!;
    }
    return null;
  }
  
  // Helper untuk format tanggal
  String getTanggalFormatted() {
    final DateFormat formatter = DateFormat('dd MMMM yyyy', 'id_ID');
    return formatter.format(tanggalPengadaan);
  }
}