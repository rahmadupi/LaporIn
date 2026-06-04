import 'package:flutter/material.dart';
import 'officer_proof_screen.dart';

class OfficerTaskDetailScreen extends StatefulWidget {
  const OfficerTaskDetailScreen({Key? key}) : super(key: key);

  @override
  State<OfficerTaskDetailScreen> createState() => _OfficerTaskDetailScreenState();
}

class _OfficerTaskDetailScreenState extends State<OfficerTaskDetailScreen> {
  // State untuk mensimulasikan status tugas sesuai Flow 3
  // "assigned" -> Belum Dimulai, "in_progress" -> Sedang Dikerjakan
  String _taskStatus = "assigned"; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Detail Tugas", 
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(),
            const SizedBox(height: 16),
            _buildCitizenReportImage(),
            const SizedBox(height: 20),
            _buildTaskDetails(),
            const SizedBox(height: 24),
            _buildNavigationButton(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  // Banner Status Terkini
  Widget _buildStatusBanner() {
    bool isInProgress = _taskStatus == "in_progress";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isInProgress ? Colors.amber[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isInProgress ? Icons.engineering : Icons.assignment_late,
            color: isInProgress ? Colors.amber[800] : Colors.red[800],
          ),
          const SizedBox(width: 12),
          Text(
            isInProgress ? "🔨 Status: Sedang Dikerjakan" : "📌 Status: Belum Dimulai",
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.bold, 
              color: isInProgress ? Colors.amber[900] : Colors.red[900]
            ),
          ),
        ],
      ),
    );
  }

  // Foto Kerusakan dari Warga (Citizen)
  Widget _buildCitizenReportImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Foto Laporan Warga", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey), // Simulasi foto jalan rusak
        ),
      ],
    );
  }

  // Informasi Detail Tugas
  Widget _buildTaskDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Jalan Berlubang", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(12)),
              child: const Text("CRITICAL", style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text("LPR-2026-0001234", style: TextStyle(fontFamily: 'monospace', color: Colors.grey)),
        const Divider(height: 32),
        
        _buildInfoRow(Icons.location_on, "Lokasi", "Jl. Diponegoro No. 45, Sidoarjo"),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.access_time_filled, "Tenggat Waktu", "Besok, 17:00 WIB (⏰ 4 jam lagi)"),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.description, "Deskripsi Laporan", "Lubang cukup dalam di lajur kiri, membahayakan pengendara motor yang lewat saat malam hari karena minim lampu jalan."),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(content, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  // Tombol Navigasi Peta Eksternal
  Widget _buildNavigationButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.explore),
        label: const Text("🧭 Buka Navigasi (Google Maps)"),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue[700],
          side: BorderSide(color: Colors.blue[700]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          // Simulasi Handoff ke Google Maps via geo URI sesuai dokumen
          debugPrint("Launching Geo URI: geo:-7.2936,112.7786?q=Jl.+Diponegoro+No.+45");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Membuka Google Maps... (Handoff via Geo URI)")),
          );
        },
      ),
    );
  }

  // Tombol Aksi Dinamis di Bagian Bawah
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: _taskStatus == "assigned"
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                setState(() {
                  _taskStatus = "in_progress"; // Ubah status tugas di UI
                });
              },
              child: const Text("▶ Mulai Pengerjaan", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                // Berpindah ke Form Bukti Penyelesaian
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OfficerProofScreen()),
                );
              },
              child: const Text("📷 Buat Bukti Penyelesaian", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
    );
  }
}