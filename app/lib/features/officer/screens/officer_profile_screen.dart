import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'officer_login_screen.dart'; // Import halaman login

class OfficerProfileScreen extends StatelessWidget {
  const OfficerProfileScreen({Key? key}) : super(key: key);

  // Fungsi untuk mengambil data dari Firestore
  Future<DocumentSnapshot> getProfileData() async {
    // Memanggil collection 'users' dan document 'User1'
    return await FirebaseFirestore.instance.collection('users').doc('User1').get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profil Relawan', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      // Membungkus body dengan FutureBuilder
      body: FutureBuilder<DocumentSnapshot>(
        future: getProfileData(),
        builder: (context, snapshot) {
          // 1. Tampilkan loading spinner saat data sedang diambil
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Tampilkan pesan jika terjadi error
          if (snapshot.hasError) {
            return const Center(child: Text("Terjadi kesalahan saat memuat data"));
          }

          // 3. Tampilkan pesan jika data tidak ditemukan/kosong
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Data profil tidak ditemukan"));
          }

          // 4. Jika sukses, ekstrak data dan masukkan ke variabel
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String name = userData['name'] ?? 'Nama Tidak Diketahui';
          String role = userData['role'] ?? '-';
          
          // Gunakan .toString() agar angka (int/double) dari Firebase otomatis jadi String
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
                
                // Gunakan variabel nama dan role
                Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(role, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                
                const SizedBox(height: 32),
                
                // Passing variabel angka ke dalam StatCard
                _buildStatCard(completedTasks, rating),
                
                const SizedBox(height: 32),
                
                // HANYA MENYISAKAN FITUR KELUAR APLIKASI
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.logout, color: Colors.red),
                  ),
                  title: const Text("Keluar Aplikasi", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () {
                    // Menampilkan pop-up konfirmasi
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Konfirmasi"),
                          content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Menutup pop-up jika batal
                              },
                              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Tutup pop-up dulu
                                
                                // Arahkan ke halaman login dan hapus riwayat page sebelumnya
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const OfficerLoginScreen()),
                                  (route) => false,
                                );
                              },
                              child: const Text("Keluar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  // Modifikasi fungsi ini untuk menerima parameter dinamis
  Widget _buildStatCard(String tasks, String rating) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
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
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[800])),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.blue[600])),
      ],
    );
  }
}