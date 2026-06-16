import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Slider pemilih radius Watch Zone + label nilai + penanda skala (tick).
///
/// Dipisah sebagai komponen reusable karena merupakan kontrol mandiri yang
/// menggabungkan SliderTheme custom (track tipis, thumb berbingkai putih) dengan
/// baris label & tick — agar [WatchZoneScreen] tetap ringkas. Bersifat
/// presentational: nilai & perubahan dikelola parent lewat [value]/[onChanged].
class RadiusSlider extends StatelessWidget {
  const RadiusSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
  });

  /// Nilai radius saat ini dalam meter.
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  /// Dipanggil saat geser selesai (mis. untuk memicu perhitungan ulang).
  final ValueChanged<double>? onChangeEnd;

  /// Ubah meter menjadi label ringkas: "500m" atau "2.5km" (tanpa nol berlebih).
  static String formatRadius(double meters) {
    if (meters < 1000) return '${meters.round()}m';
    final km = meters / 1000;
    // Buang ",0" agar 5000 -> "5km", tetapi 2500 tetap "2.5km".
    final text = km.toStringAsFixed(1);
    return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text}km';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris atas: judul kiri, nilai terpilih kanan (disorot biru primer).
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'Radius Area',
                style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
            ),
            Text(
              formatRadius(value),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Slider dengan track tipis 4px + thumb 24px berbingkai putih (mockup).
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.12),
            thumbShape: const _BorderedThumb(),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        // Penanda skala selaras ujung-ujung track.
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Tick('100m'),
              _Tick('1km'),
              _Tick('2.5km'),
              _Tick('5km'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Label kecil satu tick skala radius.
class _Tick extends StatelessWidget {
  const _Tick(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
    );
  }
}

/// Thumb bundar berbingkai putih + bayangan halus, meniru desain Figma.
class _BorderedThumb extends SliderComponentShape {
  const _BorderedThumb();

  static const double _radius = 12; // diameter 24px

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    // Bayangan lembut di bawah thumb.
    canvas.drawCircle(
      center.translate(0, 2),
      _radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // Bingkai putih.
    canvas.drawCircle(center, _radius, Paint()..color = Colors.white);
    // Isi biru primer.
    canvas.drawCircle(
      center,
      _radius - 2,
      Paint()..color = sliderTheme.thumbColor ?? AppColors.primary,
    );
  }
}
