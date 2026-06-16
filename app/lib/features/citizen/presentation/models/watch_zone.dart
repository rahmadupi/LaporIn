/// Model data DUMMY untuk satu Watch Zone milik warga.
///
/// Dibuat sebagai model tersendiri agar daftar zona di [WatchZoneListScreen]
/// punya kontrak data yang jelas dan mudah diganti dengan entitas Firestore
/// nanti tanpa mengubah widget. Pada tahap ini datanya lokal/statis.
class WatchZone {
  const WatchZone({
    required this.name,
    required this.activityText,
    required this.hasActivity,
  });

  final String name;

  /// Teks aktivitas zona (mis. "2 laporan baru hari ini" atau
  /// "Tidak ada aktivitas baru").
  final String activityText;

  /// Apakah ada aktivitas baru — menentukan warna teks pada kartu.
  final bool hasActivity;

  /// Data contoh untuk mengisi daftar zona (selaras desain Figma).
  static const List<WatchZone> dummyList = [
    WatchZone(
      name: 'Perumahan Bumi Sidoarjo',
      activityText: '2 laporan baru hari ini',
      hasActivity: true,
    ),
    WatchZone(
      name: 'Jl. Diponegoro',
      activityText: '1 laporan minggu ini',
      hasActivity: true,
    ),
    WatchZone(
      name: 'Kantor — Sidoarjo Kota',
      activityText: 'Tidak ada aktivitas baru',
      hasActivity: false,
    ),
  ];
}
