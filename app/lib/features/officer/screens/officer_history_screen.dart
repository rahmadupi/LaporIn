import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // TAMBAHAN: Mesin Firebase

class OfficerHistoryScreen extends StatelessWidget {
  const OfficerHistoryScreen({Key? key}) : super(key: key);

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
      // DIUBAH: Menggunakan StreamBuilder untuk mendengar data dari awan
      body: StreamBuilder<QuerySnapshot>(
        // MANTRA MAGIS: Ambil HANYA dokumen yang statusnya "Selesai"
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .where('status', isEqualTo: 'Selesai')
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Jika masih loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Jika ada error
          if (snapshot.hasError) {
            return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
          }

          // 3. Jika database kosong atau belum ada tugas yang diselesaikan
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

          // 4. Jika datanya ada, ubah menjadi bentuk List UI
          final tasks = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final data = tasks[index].data() as Map<String, dynamic>;
              final id = tasks[index].id;

              // Mengekstrak data dengan pengaman (fallback)
              final title = data['title'] ?? 'Tanpa Judul';
              final location = data['location'] ?? 'Lokasi tidak diketahui';
              final status = data['status'] ?? 'Selesai';
              
              // Potong ID agar rapi ditampilkan
              final shortId = id.substring(0, 6).toUpperCase();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        ],
                      )
                    ],
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