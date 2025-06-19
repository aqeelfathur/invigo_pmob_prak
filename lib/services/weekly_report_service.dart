import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invigo/models/laporan_mingguan_model.dart';

class WeeklyReportService {
  final supabase = Supabase.instance.client;

  /// Ambil semua laporan mingguan, bisa difilter dengan tanggal_awal dan tanggal_akhir (opsional)
  Future<List<LaporanMingguan>> getLaporanMingguan({
    DateTime? tanggalAwal,
    DateTime? tanggalAkhir,
  }) async {
    final response = await supabase
        .from('laporan_mingguan')
        .select('*, produk_id(nama_produk)')
        .order('tanggal_awal', ascending: false);

    final semuaLaporan = (response as List).map((json) {
      return LaporanMingguan.fromJson({
        ...json,
        'nama_produk': json['produk_id']?['nama_produk'],
      });
    }).toList();

    // Filter manual jika range tanggal diberikan
    if (tanggalAwal != null && tanggalAkhir != null) {
      return semuaLaporan.where((laporan) {
        return laporan.tanggalAwal.isAfter(tanggalAwal.subtract(const Duration(days: 1))) &&
               laporan.tanggalAkhir.isBefore(tanggalAkhir.add(const Duration(days: 1)));
      }).toList();
    }

    return semuaLaporan;
  }

  /// Tambah laporan mingguan
  Future<void> addLaporanMingguan(LaporanMingguan laporan) async {
    await supabase.from('laporan_mingguan').insert(laporan.toJson());
  }

  /// Hapus laporan mingguan berdasarkan ID
  Future<void> deleteLaporanMingguan(String id) async {
    await supabase
        .from('laporan_mingguan')
        .delete()
        .eq('id_laporan_mingguan', id);
  }
}
