/// Helper format tanggal/waktu sederhana tanpa dependency `intl`.
///
/// Dipusatkan agar tampilan waktu (mis. "2 jam lalu", "2 Jun 2026") konsisten
/// di kartu riwayat, timeline, dan detail laporan.
class DateFormatter {
  DateFormatter._();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  /// Waktu relatif ringkas: "Baru saja", "5 mnt lalu", "3 jam lalu", "2 hr lalu".
  /// Untuk selisih > 7 hari, jatuh ke tanggal absolut agar tetap jelas.
  static String relative(DateTime? time) {
    if (time == null) return '-';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hr lalu';
    return fullDate(time);
  }

  /// Tanggal absolut: "2 Jun 2026".
  static String fullDate(DateTime? time) {
    if (time == null) return '-';
    return '${time.day} ${_months[time.month - 1]} ${time.year}';
  }

  /// Tanggal + jam: "2 Jun 2026, 14:30".
  static String dateTime(DateTime? time) {
    if (time == null) return '-';
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '${fullDate(time)}, $hh:$mm';
  }
}
