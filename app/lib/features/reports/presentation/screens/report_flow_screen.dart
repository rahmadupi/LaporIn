import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/repositories/reports_repository.dart';
import '../providers/report_form_notifier.dart';
import 'report_success_screen.dart';
import 'step1_category_screen.dart';
import 'step2_photo_screen.dart';
import 'step3_location_screen.dart';
import 'step4_detail_screen.dart';
import 'step5_preview_screen.dart';

/// Cangkang alur "Buat Laporan" (Step 1 → 5).
///
/// Tanggung jawabnya:
///   1. MEMBUAT & MENYEDIAKAN satu [ReportFormNotifier] untuk seluruh step
///      (lewat ChangeNotifierProvider) — inilah yang membuat data "ikut" dari
///      satu layar ke layar berikutnya tanpa mengoper argumen.
///   2. MENGATUR navigasi antar-step lewat [PageView] yang dikendalikan tombol
///      (bukan swipe), serta menangkap tombol back sistem.
///
/// Step disusun di PageView (bukan route terpisah) agar semuanya berada di
/// bawah Provider yang sama dan transisinya mulus.
class ReportFlowScreen extends StatefulWidget {
  const ReportFlowScreen({super.key});

  @override
  State<ReportFlowScreen> createState() => _ReportFlowScreenState();
}

class _ReportFlowScreenState extends State<ReportFlowScreen> {
  final PageController _pageController = PageController();
  int _step = 0; // 0..4 untuk Step 1..5.

  // Notifier dibuat sekali untuk umur flow; repository disuntik dari Provider
  // app-level. Lazy-init agar context.read aman dipanggil saat pertama dibutuhkan.
  late final ReportFormNotifier _notifier =
      ReportFormNotifier(context.read<ReportsRepository>());

  @override
  void dispose() {
    _pageController.dispose();
    _notifier.dispose();
    super.dispose();
  }

  /// Maju satu step (dipanggil tombol "Lanjut" tiap step).
  void _next() => _goTo(_step + 1);

  /// Mundur: bila di step pertama, keluar dari flow; selain itu mundur 1 step.
  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      _goTo(_step - 1);
    }
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  /// Dipanggil Step 5 setelah submit sukses: ganti seluruh flow dengan Success
  /// Screen (pushReplacement) sambil mengoper nomor tiket.
  void _onSubmitted() {
    final ticketId = _notifier.ticketId!;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReportSuccessScreen(ticketId: ticketId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _notifier,
      // PopScope: tombol back sistem mengikuti logika step (mundur, bukan
      // langsung menutup) kecuali sudah di step pertama.
      child: PopScope(
        canPop: _step == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: PageView(
          controller: _pageController,
          // Swipe dimatikan: perpindahan hanya lewat tombol agar gating validasi
          // tiap step tidak bisa dilewati.
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Step1CategoryScreen(onNext: _next, onBack: _back),
            Step2PhotoScreen(onNext: _next, onBack: _back),
            Step3LocationScreen(onNext: _next, onBack: _back),
            Step4DetailScreen(onNext: _next, onBack: _back),
            Step5PreviewScreen(onBack: _back, onSubmitted: _onSubmitted),
          ],
        ),
      ),
    );
  }
}
