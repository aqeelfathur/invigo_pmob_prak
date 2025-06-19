import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invigo/models/laporan_bulanan_model.dart';
import 'package:invigo/models/pendapatan_model.dart';
import 'package:invigo/models/pengadaan_model.dart';

class ReportService {
  final supabase = Supabase.instance.client;

  // ------------------ Laporan Bulanan ------------------

  Future<List<LaporanBulanan>> getLaporanBulanan({int? bulan, int? tahun}) async {
    final query = supabase
        .from('laporan_bulanan')
        .select('*, produk_id(nama_produk)')
        .order('tahun', ascending: false)
        .order('bulan', ascending: false);

    final response = await query;

    return (response as List)
        .map((json) => LaporanBulanan.fromJson({
              ...json,
              'nama_produk': json['produk_id']?['nama_produk'],
            }))
        .toList();
  }

  Future<void> addLaporanBulanan(LaporanBulanan laporan) async {
    await supabase.from('laporan_bulanan').insert(laporan.toJson());
  }

  Future<void> deleteLaporanBulanan(String id) async {
    await supabase.from('laporan_bulanan').delete().eq('id_laporan_bulanan', id);
  }

  Future<void> generateLaporanBulanan() async {
    final now = DateTime.now();
    final tahun = now.month == 1 ? now.year - 1 : now.year;
    final bulan = now.month == 1 ? 12 : now.month - 1;

    final startDate = DateTime(tahun, bulan, 1);
    final endDate = DateTime(tahun, bulan + 1, 0);

    final pendapatanList = await getAllPendapatan();
    final pengadaanList = await getAllPengadaan();

    // Filter sesuai rentang waktu
    final pendapatan = pendapatanList.where((p) {
      return p.tanggalPendapatan.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
             p.tanggalPendapatan.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final pengadaan = pengadaanList.where((g) {
      return g.tanggalPengadaan.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
             g.tanggalPengadaan.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final Map<String, Map<String, dynamic>> laporanMap = {};

    for (var p in pendapatan) {
      final id = p.produkId;
      final total = (p.jumlahProdukPendapatan) * (p.hargaJual ?? 0);

      laporanMap[id] ??= {
        'produk_id': id,
        'bulan': bulan,
        'tahun': tahun,
        'total_pendapatan': 0,
        'total_pengeluaran': 0,
      };

      laporanMap[id]!['total_pendapatan'] += total;
    }

    for (var g in pengadaan) {
      final id = g.produkId;
      final total = (g.jumlahProdukPengadaan) * (g.hargaSupplier ?? 0);

      laporanMap[id] ??= {
        'produk_id': id,
        'bulan': bulan,
        'tahun': tahun,
        'total_pendapatan': 0,
        'total_pengeluaran': 0,
      };

      laporanMap[id]!['total_pengeluaran'] += total;
    }

    final data = laporanMap.values.toList();
    for (var item in data) {
      await supabase.from('laporan_bulanan').insert(item);
    }
  }

  // ------------------ Pendapatan ------------------

  Future<List<Pendapatan>> getAllPendapatan() async {
    final response = await supabase
        .from('pendapatan')
        .select('*, produk_id(nama_produk, harga_jual), id_user(nama_lengkap)')
        .order('tanggal_pendapatan', ascending: false);

    return (response as List)
        .map((json) => Pendapatan.fromJson({
              ...json,
              'nama_produk': json['produk_id']?['nama_produk'],
              'harga_jual': json['produk_id']?['harga_jual'],
              'nama_lengkap': json['id_user']?['nama_lengkap'],
            }))
        .toList();
  }

  Future<void> addPendapatan(Pendapatan pendapatan) async {
    await supabase.from('pendapatan').insert(pendapatan.toJson());
  }

  Future<void> deletePendapatan(String id) async {
    await supabase.from('pendapatan').delete().eq('id_pendapatan', id);
  }

  // ------------------ Pengadaan ------------------

  Future<List<Pengadaan>> getAllPengadaan() async {
    final response = await supabase
        .from('pengadaan')
        .select('*, produk_id(nama_produk, harga_supplier), id_user(nama_lengkap)')
        .order('tanggal_pengadaan', ascending: false);

    return (response as List)
        .map((json) => Pengadaan.fromJson({
              ...json,
              'nama_produk': json['produk_id']?['nama_produk'],
              'harga_supplier': json['produk_id']?['harga_supplier'],
              'nama_lengkap': json['id_user']?['nama_lengkap'],
            }))
        .toList();
  }

  Future<void> addPengadaan(Pengadaan pengadaan) async {
    await supabase.from('pengadaan').insert(pengadaan.toJson());
  }

  Future<void> deletePengadaan(String id) async {
    await supabase.from('pengadaan').delete().eq('id_pengadaan', id);
  }
}
