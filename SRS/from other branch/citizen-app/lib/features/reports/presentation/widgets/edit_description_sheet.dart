import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

/// Menampilkan bottom sheet untuk mengedit deskripsi laporan (FR-2.4).
///
/// Mengembalikan teks baru bila user menekan "Simpan", atau null bila batal.
/// Sengaja dibuat sebagai fungsi pembungkus agar pemanggil (Detail) cukup
/// `await` hasilnya tanpa mengurus detail showModalBottomSheet.
Future<String?> showEditDescriptionSheet(
  BuildContext context, {
  required String initialValue,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true, // Agar sheet naik mengikuti keyboard.
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _EditDescriptionSheet(initialValue: initialValue),
  );
}

class _EditDescriptionSheet extends StatefulWidget {
  const _EditDescriptionSheet({required this.initialValue});

  final String initialValue;

  @override
  State<_EditDescriptionSheet> createState() => _EditDescriptionSheetState();
}

class _EditDescriptionSheetState extends State<_EditDescriptionSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // viewInsets.bottom mengangkat sheet di atas keyboard.
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Deskripsi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hanya bisa diubah selama laporan masih menunggu verifikasi.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: 280,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Perbarui keterangan kerusakan...',
            ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Simpan',
            // Kirim teks baru ke pemanggil lewat Navigator.pop.
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          ),
        ],
      ),
    );
  }
}
