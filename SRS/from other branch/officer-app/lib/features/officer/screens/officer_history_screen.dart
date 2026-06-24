import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfficerHistoryScreen extends StatelessWidget {
  const OfficerHistoryScreen({Key? key}) : super(key: key);

  void _showDetailHistoryDialog(
    BuildContext context, 
    String title, 
    String location, 
    String notes, 
    String? beforeUrl, 
    String? afterUrl
  ) {
    // KUNCI JAWABAN: Hapus memori cache gambar yang error secara paksa di level engine!
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue[700], size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(location, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                  ],
                ),
                const Divider(height: 24),

                const Text("Catatan Penyelesaian:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(notes, style: const TextStyle(fontSize: 14, height: 1.3, color: Colors.black87)),
                const Divider(height: 24),

                const Text("Foto Bukti Lapangan:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text("Sebelum", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          _buildImageGlance(beforeUrl),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          const Text("Sesudah", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          _buildImageGlance(afterUrl),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Helper Widget kembali menggunakan Image.network murni
  // Helper Widget untuk merender gambar dari URL secara aman
  Widget _buildImageGlance(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      );
    }

    String cleanUrl = url.trim().replaceFirst('http://', 'https://');

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        cleanUrl,
        headers: const {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        },
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 120,
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          String errorMsg = error.toString();
          String friendlyMessage = "Gagal memuat gambar.";
          
          // Deteksi otomatis jika diblokir oleh ISP / Jaringan
          if (errorMsg.contains("Connection reset by peer") || errorMsg.contains("empty file") || errorMsg.contains("CERTIFICATE_VERIFY_FAILED")) {
            friendlyMessage = "Gambar diblokir oleh\nJaringan Internet.\n(Gunakan VPN)";
          }

          return Container(
            height: 120,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.red, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    friendlyMessage,
                    style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Riwayat Tugas', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .where('status', isEqualTo: 'Selesai')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Belum ada riwayat tugas yang diselesaikan.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final tasks = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final data = tasks[index].data() as Map<String, dynamic>;
              final id = tasks[index].id;

              final title = data['title'] ?? 'Tanpa Judul';
              final location = data['location'] ?? 'Lokasi tidak diketahui';
              final status = data['status'] ?? 'Selesai';
              
              final completionNotes = data['completion_notes'] ?? 'Tidak ada catatan penyelesaian.';
              final photoBeforeUrl = data['photo_before_url'];
              final photoAfterUrl = data['photo_after_url'];
              
              final shortId = id.substring(0, 6).toUpperCase();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    _showDetailHistoryDialog(
                      context, 
                      title, 
                      location, 
                      completionNotes, 
                      photoBeforeUrl, 
                      photoAfterUrl
                    );
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: Icon(Icons.check_circle, color: Colors.green[700]),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(location, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.green[700], fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Text("ID: $shortId", style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
                            const Spacer(),
                            Text("Lihat Bukti ➔", style: TextStyle(fontSize: 11, color: Colors.blue[700], fontWeight: FontWeight.w600)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}