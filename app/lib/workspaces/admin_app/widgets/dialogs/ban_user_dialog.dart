import 'package:flutter/material.dart';

/// Dialog untuk memblokir (ban) user.
///
/// Wajib mengisi alasan pemblokiran (min 10 karakter).
class BanUserDialog extends StatefulWidget {
  const BanUserDialog({super.key, required this.userName});

  final String userName;

  /// Tampilkan dialog dan kembalikan alasan jika dikonfirmasi; null jika batal.
  static Future<String?> show(
    BuildContext context, {
    required String userName,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => BanUserDialog(userName: userName),
    );
  }

  @override
  State<BanUserDialog> createState() => _BanUserDialogState();
}

class _BanUserDialogState extends State<BanUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_reasonController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.block, color: Colors.red.shade700, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Blokir Pengguna',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.userName,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                minLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Alasan pemblokiran *',
                  hintText: 'Jelaskan mengapa pengguna ini diblokir...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Alasan wajib diisi';
                  if (v.length < 10) return 'Minimal 10 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Blokir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
