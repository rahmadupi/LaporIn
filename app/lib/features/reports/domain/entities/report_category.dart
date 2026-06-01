import 'package:flutter/material.dart';

/// Kategori kerusakan yang bisa dipilih warga di Step 1.
///
/// Tiap kategori membawa tiga hal: [slug] (nilai yang disimpan ke Firestore —
/// stabil & tidak ikut berubah meski label UI diganti), [label] (teks yang
/// dilihat user), dan [icon] (representasi visual di grid). Memakai enum agar
/// pilihan terbatas & type-safe, bukan string bebas.
enum ReportCategory {
  roadDamage('road_damage', 'Jalan Rusak', Icons.dangerous_outlined),
  streetLight('street_light', 'Lampu Jalan', Icons.lightbulb_outline),
  drainage('drainage', 'Drainase', Icons.water_drop_outlined),
  trash('trash', 'Sampah', Icons.delete_outline),
  sidewalk('sidewalk', 'Trotoar', Icons.directions_walk),
  publicFacility('public_facility', 'Fasilitas Umum', Icons.chair_outlined),
  trafficSign('traffic_sign', 'Rambu', Icons.traffic_outlined),
  flooding('flooding', 'Banjir', Icons.flood_outlined),
  other('other', 'Lainnya', Icons.more_horiz);

  const ReportCategory(this.slug, this.label, this.icon);

  /// Slug stabil yang ditulis ke field `category` di Firestore (skema 8.2).
  final String slug;
  final String label;
  final IconData icon;
}
