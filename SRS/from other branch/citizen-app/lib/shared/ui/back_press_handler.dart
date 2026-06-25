import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget yang handle back button untuk workspace shells:
/// - Jika tidak di tab pertama, switch ke tab pertama
/// - Jika di tab pertama, butuh double-tap untuk keluar (close app)
class BackPressHandler extends StatefulWidget {
  const BackPressHandler({
    super.key,
    required this.child,
    required this.isOnFirstTab,
    required this.onSwitchToFirstTab,
    this.exitMessage = 'Tekan sekali lagi untuk keluar',
  });

  /// Widget child (biasanya RoleScaffold)
  final Widget child;

  /// Fungsi untuk cek apakah sedang di tab pertama (dipanggil setiap back press)
  final bool Function() isOnFirstTab;

  /// Callback untuk switch ke tab pertama
  final VoidCallback onSwitchToFirstTab;

  /// Pesan toast saat pertama kali tekan back di tab pertama
  final String exitMessage;

  @override
  State<BackPressHandler> createState() => _BackPressHandlerState();
}

class _BackPressHandlerState extends State<BackPressHandler> {
  DateTime? _lastBackPress;

  /// Handle tombol back Android.
  Future<void> _handleBack() async {
    // Jika tidak di tab pertama, switch ke tab pertama
    if (!widget.isOnFirstTab()) {
      widget.onSwitchToFirstTab();
      return;
    }

    // Tab pertama - cek double-tap
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      // Tekan pertama: tampilkan pesan
      _lastBackPress = now;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.exitMessage),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Tekan kedua dalam 2 detik: keluar dari app
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: widget.child,
    );
  }
}
