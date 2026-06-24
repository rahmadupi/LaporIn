/// Komparator "terbaru di atas" untuk tanggal opsional.
///
/// Dipakai sebagai pengganti `orderBy('createdAt')` server-side di Firestore
/// sehingga kueri TIDAK butuh composite index (penyebab umum "Gagal memuat").
/// Pengurutan dilakukan di klien.
///
/// Aturan: tanggal `null` (mis. server-timestamp yang masih pending pada write
/// optimistik) dianggap PALING BARU sehingga item yang baru dibuat langsung
/// muncul di puncak tanpa menunggu konfirmasi server.
int compareByDateDesc(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return -1;
  if (b == null) return 1;
  return b.compareTo(a);
}
