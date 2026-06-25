import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/officer/data/proof_upload_service.dart';
import '../../../shared_domain_data/auth/providers/auth_providers.dart';
import '../../../shared_domain_data/reports/data/repositories/report_repository.dart';
import '../../../shared_domain_data/reports/domain/entities/report_entity.dart';

/// Citizen Buat Laporan (Report Flow) — versi **3-step wizard** yang
/// disederhanakan dari spec 6-step (lihat
/// [SRS/citizen/feature/report_flow.md]). Pemetaan:
///   Step 1 (Foto + Lokasi) ↔ spec Step 2 + Step 3
///   Step 2 (Detail + Anonim) ↔ spec Step 4 + Step 5
///   Step 3 (Submit + Sukses)  ↔ spec Step 6
///
/// Field yang ditulis sesuai [SRS/data-model.md §3.2]. Foto di-host ke
/// ImgBB (key masih hard-coded, sama dengan officer proof). Jika
/// `image_picker` belum ditambahkan plugin-nya, kamera/galeri akan
/// menampilkan error SnackBar.
class ReportFlowScreen extends ConsumerStatefulWidget {
  const ReportFlowScreen({super.key});

  @override
  ConsumerState<ReportFlowScreen> createState() => _ReportFlowScreenState();
}

class _ReportFlowScreenState extends ConsumerState<ReportFlowScreen> {
  final PageController _pageController = PageController();
  int _step = 0;

  // Step 1 state
  File? _photo;
  Position? _position;
  bool _isLoadingGps = false;
  String? _gpsError;

  // Step 2 state
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategoryId;
  ReportUrgency _urgency = ReportUrgency.medium;
  bool _isAnonymous = false;

  // Step 3 state
  bool _isSubmitting = false;
  String? _createdTicketId;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoadingGps = true;
      _gpsError = null;
    });
    try {
      final service = await Geolocator.isLocationServiceEnabled();
      if (!service) {
        setState(() {
          _isLoadingGps = false;
          _gpsError = 'GPS tidak aktif.';
        });
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingGps = false;
          _gpsError = 'Izin lokasi ditolak.';
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _position = pos;
        _isLoadingGps = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingGps = false;
        _gpsError = '$e';
      });
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (xfile == null) return;
      setState(() => _photo = File(xfile.path));
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

  Future<void> _pickPhotoFromGallery() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (xfile == null) return;
      setState(() => _photo = File(xfile.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka galeri: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else {
      context.pop();
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      _snackError('Judul wajib diisi.');
      return;
    }
    if (_selectedCategoryId == null) {
      _snackError('Pilih kategori terlebih dahulu.');
      return;
    }
    if (_position == null) {
      _snackError('Lokasi GPS belum tersedia.');
      return;
    }
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      _snackError('Sesi login tidak ditemukan.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Upload foto ke ImgBB (reuse service dari officer).
      String imageUrl = '';
      if (_photo != null) {
        final proofService = ProofUploadService();
        final url = await proofService.uploadImageToImgBB(_photo!);
        if (url == null) {
          throw Exception('Gagal mengunggah foto. Coba lagi.');
        }
        imageUrl = url;
      }

      final ticketId = await ref
          .read(reportRepositoryProvider)
          .createCitizenReport(
            reporterId: user.uid,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            categoryId: _selectedCategoryId!,
            urgencyLevel: _urgency,
            isAnonymous: _isAnonymous,
            imageUrl: imageUrl,
            addressDetail: 'Lokasi GPS',
            latitude: _position!.latitude,
            longitude: _position!.longitude,
          );
      if (!mounted) return;
      setState(() {
        _createdTicketId = ticketId;
        _step = 2; // success screen
      });
    } catch (e) {
      if (!mounted) return;
      _snackError('Gagal mengirim: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snackError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(_step < 2 ? 'Buat Laporan (${_step + 1}/2)' : 'Selesai'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _step == 2 ? 1.0 : (_step + 1) / 2,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _step1FotoLokasi(),
                _step2DetailAnonim(),
                if (_step == 2) _step3Success(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _step == 2
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _step == 1
                    ? FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Kirim Laporan'),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              onPressed: _back,
                              child: const Text('Kembali'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size.fromHeight(48),
                              ),
                              onPressed: _next,
                              child: const Text('Lanjut'),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
    );
  }

  // STEP 1 — Foto + Lokasi
  Widget _step1FotoLokasi() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Foto & Lokasi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ambil foto kerusakan dan pastikan GPS aktif agar lokasi '
          'terekam otomatis.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        const Text(
          'Foto',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: _photo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_photo!, fit: BoxFit.cover),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt,
                            size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada foto',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Kamera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickPhotoFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galeri'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Lokasi GPS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _GpsCard(
          isLoading: _isLoadingGps,
          position: _position,
          error: _gpsError,
          onRetry: _getLocation,
        ),
      ],
    );
  }

  // STEP 2 — Detail + Anonim
  Widget _step2DetailAnonim() {
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Detail Laporan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Judul',
            border: OutlineInputBorder(),
            hintText: 'Cth: Lubang di Jl. X',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Deskripsi',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Kategori',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        categoriesAsync.when(
          data: (cats) {
            if (cats.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Belum ada kategori. Hubungi admin.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: cats.map((c) {
                final id = c['categoryId'] as String? ?? '';
                final name = c['name'] as String? ?? id;
                final isActive = _selectedCategoryId == id;
                return ChoiceChip(
                  label: Text(name),
                  selected: isActive,
                  onSelected: (_) =>
                      setState(() => _selectedCategoryId = id),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : AppColors.textPrimary,
                  ),
                  backgroundColor: AppColors.scaffoldBackground,
                  side: BorderSide(
                    color: isActive ? AppColors.primary : AppColors.border,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Gagal: $e'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tingkat Urgensi',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ReportUrgency.values.map((u) {
            final isActive = _urgency == u;
            return ChoiceChip(
              label: Text(u.label),
              selected: isActive,
              onSelected: (_) => setState(() => _urgency = u),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppColors.textPrimary,
              ),
              backgroundColor: AppColors.scaffoldBackground,
              side: BorderSide(
                color: isActive ? AppColors.primary : AppColors.border,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          value: _isAnonymous,
          onChanged: (v) => setState(() => _isAnonymous = v),
          title: const Text(
            'Sembunyikan nama saya (Anonim)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: const Text(
            'Nama Anda tidak akan ditampilkan di laporan publik. '
            'Identitas tetap disimpan untuk notifikasi.',
            style: TextStyle(fontSize: 11),
          ),
          secondary: Icon(
            _isAnonymous ? Icons.visibility_off : Icons.visibility,
            color: _isAnonymous ? AppColors.textSecondary : AppColors.primary,
          ),
        ),
      ],
    );
  }

  // STEP 3 — Success
  Widget _step3Success() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle,
              size: 80, color: AppColors.success),
          const SizedBox(height: 16),
          const Text(
            'Laporan Terkirim!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tiket: ${_createdTicketId ?? '-'}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Status awalnya "Pending". Admin akan memverifikasi dalam '
            'waktu dekat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
            ),
            onPressed: () => context.go('/citizen'),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Kembali ke Beranda'),
          ),
        ],
      ),
    );
  }
}

class _GpsCard extends StatelessWidget {
  const _GpsCard({
    required this.isLoading,
    required this.position,
    required this.error,
    required this.onRetry,
  });

  final bool isLoading;
  final Position? position;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Mendeteksi koordinat...',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }
    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }
    if (position == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lat ${position!.latitude.toStringAsFixed(4)}, '
              'Lng ${position!.longitude.toStringAsFixed(4)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
