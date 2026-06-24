import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';

/// Peta mini statis di Detail: menampilkan satu pin di lokasi kejadian.
///
/// TAHAN-BANTING (sama seperti Step 3 Create Report): GoogleMap tetap dirender
/// walau API key belum dipasang — tile-nya kosong, tetapi TIDAK crash. Semua
/// gesture dimatikan karena ini hanya pratinjau lokasi, bukan peta interaktif.
class ReportMiniMap extends StatelessWidget {
  const ReportMiniMap({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    // Koordinat 0,0 berarti lokasi tidak tersimpan -> tampilkan placeholder
    // alih-alih peta yang menunjuk ke tengah laut.
    final hasLocation = latitude != 0 || longitude != 0;
    if (!hasLocation) {
      return _MapPlaceholder();
    }

    final target = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 160,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: target, zoom: 16),
          markers: {
            Marker(
              markerId: const MarkerId('report_pin'),
              position: target,
            ),
          },
          // Non-interaktif: hanya pratinjau, jadi semua gesture dinonaktifkan.
          zoomGesturesEnabled: false,
          scrollGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          // Lite mode = render statis ringan, TAPI hanya didukung Android.
          // Di-gate agar tidak memicu masalah di iOS (tetap tahan-banting).
          liteModeEnabled: defaultTargetPlatform == TargetPlatform.android,
        ),
      ),
    );
  }
}

/// Fallback saat koordinat tidak tersedia.
class _MapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, color: AppColors.textSecondary, size: 36),
            SizedBox(height: 8),
            Text('Lokasi tidak tersedia',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
