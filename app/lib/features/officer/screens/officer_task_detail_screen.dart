import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'officer_proof_screen.dart';

class OfficerTaskDetailScreen extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> taskData;

  const OfficerTaskDetailScreen({
    Key? key, 
    required this.taskId, 
    required this.taskData,
  }) : super(key: key);

  @override
  State<OfficerTaskDetailScreen> createState() => _OfficerTaskDetailScreenState();
}

class _OfficerTaskDetailScreenState extends State<OfficerTaskDetailScreen> {
  late String _taskStatus;

  @override
  void initState() {
    super.initState();
    // Ambil status dari database saat halaman pertama dibuka
    _taskStatus = widget.taskData['status'] ?? "Belum Dimulai";
  }

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

  Widget _buildStatusBanner() {
    // Cek apakah statusnya sedang dikerjakan
    bool isInProgress = _taskStatus.toLowerCase() == "sedang dikerjakan";
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
            isInProgress ? "🔨 Status: Sedang Dikerjakan" : "📌 Status: $_taskStatus",
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
          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey), 
        ),
      ],
    );
  }

  Widget _buildTaskDetails() {
    // Mengekstrak data asli dari Firebase
    final title = widget.taskData['title'] ?? 'Tanpa Judul';
    final urgency = widget.taskData['urgency'] ?? 'Biasa';
    final location = widget.taskData['location'] ?? 'Lokasi tidak diketahui';
    final desc = widget.taskData['description'] ?? 'Tidak ada deskripsi laporan.';

    Color urgencyColor = Colors.blue;
    if (urgency.toString().toLowerCase() == 'mendesak') {
      urgencyColor = Colors.red;
    } else if (urgency.toString().toLowerCase() == 'sedang') {
      urgencyColor = Colors.orange;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: urgencyColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(urgency.toString().toUpperCase(), style: TextStyle(fontSize: 10, color: urgencyColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text("ID: ${widget.taskId}", style: const TextStyle(fontFamily: 'monospace', color: Colors.grey, fontSize: 12)),
        const Divider(height: 32),
        
        _buildInfoRow(Icons.location_on, "Lokasi", location),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.description, "Deskripsi Laporan", desc),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Membuka Google Maps... (Handoff via Geo URI)")),
          );
        },
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: _taskStatus.toLowerCase() == "belum dimulai"
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                // 1. Ubah tampilan di layar langsung (Optimistic UI)
                setState(() {
                  _taskStatus = "Sedang Dikerjakan"; 
                });
                
                // 2. Tembak perubahan status ke database Firebase!
                try {
                  await FirebaseFirestore.instance
                      .collection('assignments')
                      .doc(widget.taskId)
                      .update({'status': 'Sedang Dikerjakan'});
                } catch (e) {
                  debugPrint("Gagal update status: $e");
                }
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
                // Berpindah ke Form Bukti Penyelesaian dengan mengoper ID dan Data
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OfficerProofScreen(
                      taskId: widget.taskId,
                      taskData: widget.taskData,
                    ),
                  ),
                );
              },
              child: const Text("📷 Buat Bukti Penyelesaian", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
    );
  }
}