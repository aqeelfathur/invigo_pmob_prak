// models/product_model.dart - OPTION 1 (Custom Users Table)

class Product {
  final String? id;
  final String namaProduk;
  final String? deskripsi;
  final int hargaSupplier;
  final int stokMinimal;
  final int hargaJual;
  final String? gambarProduk;
  final int jumlahProduk;
  final String? idUser; // Relasi ke custom users table
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.namaProduk,
    this.deskripsi,
    required this.hargaSupplier,
    this.stokMinimal = 0,
    required this.hargaJual,
    this.gambarProduk,
    this.jumlahProduk = 0,
    this.idUser,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['produk_id'],
      namaProduk: json['nama_produk'],
      deskripsi: json['deskripsi'],
      hargaSupplier: json['harga_supplier'] ?? 0,
      stokMinimal: json['stok_minimal'] ?? 0,
      hargaJual: json['harga_jual'] ?? 0,
      gambarProduk: json['gambar_produk'],
      jumlahProduk: json['jumlah_produk'] ?? 0,
      idUser: json['id_user'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'nama_produk': namaProduk,
      'deskripsi': deskripsi,
      'harga_supplier': hargaSupplier,
      'stok_minimal': stokMinimal,
      'harga_jual': hargaJual,
      'gambar_produk': gambarProduk,
      'jumlah_produk': jumlahProduk,
    };
    
    if (id != null) {
      map['produk_id'] = id;
    }
    
    if (idUser != null) {
      map['id_user'] = idUser;
    }
    
    return map;
  }

  Product copyWith({
    String? id,
    String? namaProduk,
    String? deskripsi,
    int? hargaSupplier,
    int? stokMinimal,
    int? hargaJual,
    String? gambarProduk,
    int? jumlahProduk,
    String? idUser,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      namaProduk: namaProduk ?? this.namaProduk,
      deskripsi: deskripsi ?? this.deskripsi,
      hargaSupplier: hargaSupplier ?? this.hargaSupplier,
      stokMinimal: stokMinimal ?? this.stokMinimal,
      hargaJual: hargaJual ?? this.hargaJual,
      gambarProduk: gambarProduk ?? this.gambarProduk,
      jumlahProduk: jumlahProduk ?? this.jumlahProduk,
      idUser: idUser ?? this.idUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isLowStock => jumlahProduk <= stokMinimal;
  
  bool get isOutOfStock => jumlahProduk <= 0;
  
  double get profitMargin => hargaJual > 0 
      ? ((hargaJual - hargaSupplier) / hargaJual * 100) 
      : 0.0;

  @override
  String toString() {
    return 'Product(id: $id, nama: $namaProduk, stock: $jumlahProduk)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}