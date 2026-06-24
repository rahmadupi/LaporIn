import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/core/utils/recency_sort.dart';

/// Memverifikasi pengurutan klien yang menggantikan `orderBy('createdAt')`
/// server-side (fix Watch Zone "Gagal memuat" + zona baru langsung tampil).
void main() {
  final older = DateTime(2026, 1, 1);
  final newer = DateTime(2026, 6, 1);

  group('compareByDateDesc', () {
    test('mengurutkan terbaru di atas', () {
      final list = [older, newer]..sort(compareByDateDesc);
      expect(list, [newer, older]);
    });

    test('null (pending server-timestamp) dianggap paling baru', () {
      final list = <DateTime?>[older, null, newer]..sort(compareByDateDesc);
      expect(list.first, isNull);
      expect(list[1], newer);
      expect(list.last, older);
    });

    test('dua null dianggap setara', () {
      expect(compareByDateDesc(null, null), 0);
    });

    test('membuat item baru (createdAt null) muncul di puncak daftar', () {
      // Simulasikan: dua zona lama + satu zona yang baru dibuat (pending write).
      final zones = <(String, DateTime?)>[
        ('lama-1', older),
        ('lama-2', newer),
        ('baru', null),
      ]..sort((a, b) => compareByDateDesc(a.$2, b.$2));
      expect(zones.first.$1, 'baru');
    });
  });
}
