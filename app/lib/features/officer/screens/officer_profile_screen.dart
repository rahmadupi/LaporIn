import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // 🐛 DEBUG: untuk Firebase.apps check
import 'officer_login_screen.dart'; // Import halaman login

class OfficerProfileScreen extends StatelessWidget {
  const OfficerProfileScreen({Key? key}) : super(key: key);

  // Fungsi untuk mengambil data dari Firestore
  Future<DocumentSnapshot> getProfileData() async {
    return await FirebaseFirestore.instance
        .collection('users')
        .doc('User1')
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Profil Relawan',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      // 🐛 DEBUG: kalau Firebase belum diinisialisasi, render mock body.
      body: _isFirebaseAvailable() ? _buildWithFirestore() : _buildMockBody(),
    );
  }

  /// 🐛 DEBUG: deteksi apakah Firebase app sudah aktif.
  bool _isFirebaseAvailable() {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Body dengan mock data (dipakai saat Firebase dimatikan / gagal).
  Widget _buildMockBody() {
    return Builder(
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Debug Officer',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Petugas Lapangan (mock)',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            _buildStatCard('12', '4.7'),
            const SizedBox(height: 32),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout, color: Colors.red),
              ),
              title: const Text(
                "Keluar Aplikasi (disabled in debug)",
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Logout dimatikan saat debug bypass.'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Body dengan FutureBuilder asli (Firebase hidup).
  Widget _buildWithFirestore() {
    return FutureBuilder<DocumentSnapshot>(
      future: getProfileData(),
      builder: (context, snapshot) {
        // 1. Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // 2. Error
        if (snapshot.hasError) {
          return const Center(
            child: Text("Terjadi kesalahan saat memuat data"),
          );
        }
        // 3. Data kosong
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Data profil tidak ditemukan"));
        }

        // 4. Ekstrak data
        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String name = userData['name'] ?? 'Nama Tidak Diketahui';
        String role = userData['role'] ?? '-';
        String completedTasks = userData['completed_tasks']?.toString() ?? '0';
        String rating = userData['rating']?.toString() ?? '0.0';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                role,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              _buildStatCard(completedTasks, rating),
              const SizedBox(height: 32),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.logout, color: Colors.red),
                ),
                title: const Text(
                  "Keluar Aplikasi",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext ctx) {
                      return AlertDialog(
                        title: const Text("Konfirmasi"),
                        content: const Text(
                          "Apakah Anda yakin ingin keluar dari aplikasi?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              "Batal",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OfficerLoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            child: const Text(
                              "Keluar",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Modifikasi fungsi ini untuk menerima parameter dinamis
  Widget _buildStatCard(String tasks, String rating) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(tasks, "Tugas Selesai"),
          Container(height: 40, width: 1, color: Colors.blue[200]),
          _statItem(rating, "Rating Bintang"),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.blue[600])),
      ],
    );
  }
}
