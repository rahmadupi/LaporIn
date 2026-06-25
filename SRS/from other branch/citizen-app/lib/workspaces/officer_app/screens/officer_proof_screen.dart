import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/officer/data/proof_upload_service.dart';

/// Halaman unggah bukti pengerjaan (Bukti Penyelesaian) untuk Petugas
/// Lapangan. Diakses dari `OfficerTaskDetailScreen` saat status
/// `dispatched` atau `in_progress`.
///
/// Implementasi mengikuti kode referensi di
/// `SRS/from other branch/officer-app/lib/features/officer/screens/officer_proof_screen.dart`:
/// - **Dua foto**: SEBELUM & SESUDAH (ImagePicker, imageQuality: 50).
/// - **GPS auto-capture** via Geolocator setiap kali foto dipilih.
/// - **Catatan teks** + speech-to-text (id_ID).
/// - **Draft offline** di Hive box `offline_proofs`.
/// - **Listener konektivitas** + banner Online/Offline.
class OfficerProofScreen extends ConsumerStatefulWidget {
  const OfficerProofScreen({
    super.key,
    required this.taskId,
    required this.taskData,
  });

  final String taskId;
  final Map<String, dynamic> taskData;

  @override
  ConsumerState<OfficerProofScreen> createState() => _OfficerProofScreenState();
}

class _OfficerProofScreenState extends ConsumerState<OfficerProofScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _notesController = TextEditingController();
  late final ProofUploadService _service;
  StreamSubscription<bool>? _connSub;

  File? _beforePhoto;
  File? _afterPhoto;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isOffline = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _service = ProofUploadService();
    _initConnectivity();
    _loadDraft();
  }

  Future<void> _initConnectivity() async {
    final online = await _service.isOnline();
    if (!mounted) return;
    setState(() => _isOffline = !online);
    _connSub = _service.onlineStream().listen((online) {
      if (!mounted) return;
      final wasOffline = _isOffline;
      setState(() => _isOffline = !online);
      if (wasOffline && online) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Koneksi pulih. Anda kembali Online.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (!wasOffline && !online) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Koneksi terputus. Masuk ke mode Offline.'),
            backgroundColor: AppColors.accent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _loadDraft() {
    final draft = _service.loadDraft(widget.taskId);
    setState(() {
      if (draft['before'] != null) _beforePhoto = File(draft['before']!);
      if (draft['after'] != null) _afterPhoto = File(draft['after']!);
      if (draft['notes'] != null) _notesController.text = draft['notes']!;
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _notesController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    final pos = await _service.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _currentPosition = pos;
      _isLoadingLocation = false;
    });
  }

  Future<void> _takePhoto(bool isBefore) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );
      if (photo != null) {
        setState(() {
          if (isBefore) {
            _beforePhoto = File(photo.path);
          } else {
            _afterPhoto = File(photo.path);
          }
        });
        await _getCurrentLocation();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka kamera: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _onMic() async {
    await _service.toggleListening(
      currentText: _notesController.text,
      onUpdate: (text) {
        if (!mounted) return;
        setState(() => _notesController.text = text);
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _saveDraft() async {
    await _service.saveDraft(
      taskId: widget.taskId,
      beforePath: _beforePhoto?.path,
      afterPath: _afterPhoto?.path,
      notes: _notesController.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft berhasil disimpan di memori lokal.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _submit() async {
    if (_beforePhoto == null || _afterPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi kedua foto terlebih dahulu!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // 1. Upload kedua foto ke ImgBB secara paralel
      final urls = await _service.uploadPair(_beforePhoto!, _afterPhoto!);
      if (urls.beforeUrl == null || urls.afterUrl == null) {
        throw Exception(
          'Gagal mengunggah foto ke server. Periksa koneksi Anda.',
        );
      }

      // 2. Tulis ke Firestore
      await _service.commitProofToFirestore(
        taskId: widget.taskId,
        beforeUrl: urls.beforeUrl,
        afterUrl: urls.afterUrl,
        description: _notesController.text,
        position: _currentPosition,
      );

      // 3. Bersihkan draft
      await _service.clearDraft(widget.taskId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tugas selesai dan foto sukses diunggah!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.taskData['title'] as String?) ?? 'Tanpa Judul';
    final address =
        (widget.taskData['addressDetail'] as String?) ??
        'Lokasi tidak diketahui';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Bukti Penyelesaian'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                _isOffline ? '🟠 Offline — akan disinkronkan' : '🟢 Online',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _taskInfoCard(title, address),
            const SizedBox(height: 24),
            _photoSection(),
            const SizedBox(height: 16),
            _gpsIndicator(),
            const SizedBox(height: 24),
            _notesSection(),
          ],
        ),
      ),
      bottomNavigationBar: _bottomStickyButtons(),
    );
  }

  Widget _taskInfoCard(String title, String address) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title • $address',
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            widget.taskId,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Bukti (Wajib 2 foto)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _photoBox('📷 Foto SEBELUM', true, _beforePhoto)),
            const SizedBox(width: 16),
            Expanded(child: _photoBox('📷 Foto SESUDAH', false, _afterPhoto)),
          ],
        ),
      ],
    );
  }

  Widget _photoBox(String label, bool isBefore, File? photoFile) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _takePhoto(isBefore),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.scaffoldBackground,
            ),
            child: photoFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(photoFile, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ketuk untuk\nambil foto',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _gpsIndicator() {
    if (_isLoadingLocation) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Mendeteksi koordinat lokasi...',
            style: TextStyle(fontSize: 12, color: AppColors.primary),
          ),
        ],
      );
    }
    if (_currentPosition == null) return const SizedBox.shrink();

    return Row(
      children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Lokasi terekam: Lat ${_currentPosition!.latitude.toStringAsFixed(4)}, '
            'Lng ${_currentPosition!.longitude.toStringAsFixed(4)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _notesSection() {
    final listening = _service.isListening;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catatan Pekerjaan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Misal: Tambal aspal 2m²...',
            hintStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: Icon(
                listening ? Icons.mic : Icons.mic_none,
                color: listening ? AppColors.error : AppColors.primary,
              ),
              onPressed: _onMic,
            ),
          ),
        ),
        if (listening)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.error,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Sedang mendengarkan...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _bottomStickyButtons() {
    final bothUploaded = _beforePhoto != null && _afterPhoto != null;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : _saveDraft,
              child: const Text('Simpan Draft'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(bothUploaded ? 'Kirim Bukti' : 'Lengkapi Foto'),
            ),
          ),
        ],
      ),
    );
  }
}
