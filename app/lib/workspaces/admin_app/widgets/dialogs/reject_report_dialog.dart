import 'package:flutter/material.dart';

/// Result yang dikembalikan oleh [RejectReportDialog].
class RejectReportResult {
  final String rejectComment;
  final String? duplicateOfId;

  const RejectReportResult({required this.rejectComment, this.duplicateOfId});
}

/// Dialog untuk menolak laporan.
///
/// Field:
/// - rejectComment (required, min 10 chars)
/// - duplicateOfId (optional, free-text ID)
class RejectReportDialog extends StatefulWidget {
  const RejectReportDialog({super.key});

  /// Tampilkan dialog dan kembalikan [RejectReportResult] jika user
  /// mengkonfirmasi; null jika dibatalkan.
  static Future<RejectReportResult?> show(BuildContext context) {
    return showDialog<RejectReportResult>(
      context: context,
      builder: (_) => const RejectReportDialog(),
    );
  }

  @override
  State<RejectReportDialog> createState() => _RejectReportDialogState();
}

class _RejectReportDialogState extends State<RejectReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _duplicateController = TextEditingController();
  bool _includeDuplicate = false;

  @override
  void dispose() {
    _commentController.dispose();
    _duplicateController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(
        RejectReportResult(
          rejectComment: _commentController.text.trim(),
          duplicateOfId:
              _includeDuplicate && _duplicateController.text.trim().isNotEmpty
              ? _duplicateController.text.trim()
              : null,
        ),
      );
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
                    'Tolak Laporan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                minLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Alasan penolakan *',
                  hintText: 'Jelaskan mengapa laporan ini ditolak...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Alasan penolakan wajib diisi';
                  if (v.length < 10) return 'Minimal 10 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 4),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Tandai sebagai duplikat',
                  style: TextStyle(fontSize: 13),
                ),
                value: _includeDuplicate,
                onChanged: (v) =>
                    setState(() => _includeDuplicate = v ?? false),
              ),
              if (_includeDuplicate)
                TextFormField(
                  controller: _duplicateController,
                  decoration: const InputDecoration(
                    labelText: 'ID laporan asli',
                    hintText: 'LPR-YYYY-NNNNNNN',
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Tolak Laporan'),
                    ),
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
