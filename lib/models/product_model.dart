// models/product_model.dart

class Product {
  final String? id;
  final String namaProduk;
  final String? deskripsi;
  final int hargaSupplier;
  final int stokMinimal;
  final int hargaJual;
  final String? gambarProduk;
  final int jumlahProduk;

  Product({
    this.id,
    required this.namaProduk,
    this.deskripsi,
    required this.hargaSupplier,
    this.stokMinimal = 0,
    required this.hargaJual,
    this.gambarProduk,
    this.jumlahProduk = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['produk_id'],
      namaProduk: json['nama_produk'],
      deskripsi: json['deskripsi'],
      hargaSupplier: json['harga_supplier'],
      stokMinimal: json['stok_minimal'] ?? 0,
      hargaJual: json['harga_jual'],
      gambarProduk: json['gambar_produk'],
      jumlahProduk: json['jumlah_produk'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
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
    );
  }
}