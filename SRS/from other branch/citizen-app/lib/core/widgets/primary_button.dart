import 'package:flutter/material.dart';

/// Tombol utama (mis. "Masuk", "Daftar", "Kirim").
///
/// Menangani state [isLoading] secara terpusat: saat proses async berjalan
/// tombol menampilkan spinner dan non-aktif, mencegah double-submit.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      // Saat loading, onPressed dibuat null agar tombol otomatis disabled.
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}
