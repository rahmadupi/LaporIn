import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'officer_task_detail_screen.dart'; 
import 'officer_history_screen.dart';
import 'officer_profile_screen.dart';
import 'officer_map_screen.dart';
import 'package:geolocator/geolocator.dart';

class OfficerHomeScreen extends StatefulWidget {
  const OfficerHomeScreen({Key? key}) : super(key: key);

  @override
  State<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  int _selectedBottomNavIndex = 0; 
  int _selectedFilterIndex = 0;
  
  final List<String> _filters = [
    "Semua",
    "Belum Dimulai",
    "Sedang Dikerjakan",
    "Mendesak"
  ];

 Widget _buildBodyContent() {
  switch (_selectedBottomNavIndex) {
    case 0:
      return _buildActiveTasksView(); 
    case 1:
      return const OfficerMapScreen(); // <-- INI YANG DIUBAH
    case 2:
      return const OfficerHistoryScreen(); 
    case 3:
      return const OfficerProfileScreen(); 
    default:
      return _buildActiveTasksView();
  }
}

  void _onItemTapped(int index) {
    setState(() {
      _selectedBottomNavIndex = index;
    });
  }

  // === FITUR CREATE: FUNGSI MEMBUAT LAPORAN DARURAT (UNTUK NILAI CRUD) ===
  // === FITUR CREATE: FUNGSI MEMBUAT LAPORAN DARURAT (DENGAN SENSOR GPS) ===
  void _showCreateEmergencyDialog() {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    bool isLoading = false; // State untuk animasi loading saat cari GPS

    showDialog(
      context: context,
      barrierDismissible: false, // Jangan tutup dialog kalau ditekan di luar
      builder: (context) {
        return StatefulBuilder( // Butuh StatefulBuilder agar dialog bisa update state loading
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Buat Laporan Darurat", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Judul Masalah (Misal: Tiang Roboh)"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: "Detail Lokasi"),
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text("Mencari titik koordinat GPS...", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                  onPressed: isLoading ? null : () async {
                    if (titleController.text.isNotEmpty && locationController.text.isNotEmpty) {
                      setState(() { isLoading = true; }); // Nyalakan loading

                      try {
                        // 1. Cek izin GPS
                        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                        if (!serviceEnabled) {
                          throw Exception("GPS HP Anda mati. Nyalakan terlebih dahulu.");
                        }

                        LocationPermission permission = await Geolocator.checkPermission();
                        if (permission == LocationPermission.denied) {
                          permission = await Geolocator.requestPermission();
                          if (permission == LocationPermission.denied) {
                            throw Exception("Izin lokasi ditolak.");
                          }
                        }
                        
                        if (permission == LocationPermission.deniedForever) {
                          throw Exception("Izin lokasi diblokir permanen oleh sistem.");
                        }

                        // 2. Tarik Koordinat saat ini!
                        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

                        // 3. Tembak data baru ke Firestore BESERTA Koordinat
                        await FirebaseFirestore.instance.collection('assignments').add({
                          'title': titleController.text,
                          'location': locationController.text,
                          'latitude': position.latitude,   // Data GPS asli
                          'longitude': position.longitude, // Data GPS asli
                          'urgency': 'Mendesak',
                          'status': 'Belum Dimulai',
                          'description': 'Laporan darurat dibuat langsung oleh relawan di lapangan.',
                          'created_at': FieldValue.serverTimestamp(),
                        });

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Berhasil membuat laporan dengan lokasi GPS akurat!"), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        setState(() { isLoading = false; }); // Matikan loading jika gagal
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Gagal: ${e.toString()}"), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text("Kirim & Lacak GPS", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _selectedBottomNavIndex == 0 ? _buildOfficerAppBar() : null, 
      body: _buildBodyContent(), 
      // === FITUR CREATE: TOMBOL FAB (UNTUK NILAI CRUD) ===
      floatingActionButton: _selectedBottomNavIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showCreateEmergencyDialog,
              backgroundColor: Colors.red[700],
              icon: const Icon(Icons.add_alert, color: Colors.white),
              label: const Text("Lapor Darurat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedBottomNavIndex,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, 
        onTap: _onItemTapped, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tugas'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Peta'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildActiveTasksView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTodaySummaryCard(),
          _buildFilterChips(),
          _buildSortDropdown(),
          _buildRealTaskList(), 
        ],
      ),
    );
  }

  // === FITUR DINAMIS: PROFIL DI HEADER APP BAR ===
  AppBar _buildOfficerAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      toolbarHeight: 72,
      elevation: 0,
      title: FutureBuilder<DocumentSnapshot>(
        // Mengambil data dari koleksi 'users', dokumen 'User1'
        future: FirebaseFirestore.instance.collection('users').doc('User1').get(),
        builder: (context, snapshot) {
          String name = "Memuat...";
          String role = "Mencari data...";

          if (snapshot.hasData && snapshot.data!.exists) {
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            name = userData['name'] ?? 'Nama Tidak Diketahui';
            role = userData['role'] ?? '-';
          } else if (snapshot.hasError) {
            name = "Error";
            role = "Gagal memuat data";
          }

          return Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                  Text(role, 
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.black),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Halaman Riwayat Notifikasi Belum Dibuat')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTodaySummaryCard() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tugas Hari Ini", style: TextStyle(fontSize: 12, color: Colors.white70)),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text("Real-Time", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(width: 8),
              Text("sinkronisasi", style: TextStyle(fontSize: 14, color: Colors.white)),
            ],
          ),
          SizedBox(height: 12),
          Text("Membaca data langsung dari Firestore Sandbox...", style: TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(_filters[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
              selectedColor: Colors.blue[700],
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text("Urutkan: Terbaru ⌄", 
            style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRealTaskList() {
    return StreamBuilder<QuerySnapshot>(
      // Hanya menampilkan tugas yang statusnya bukan Selesai
      stream: FirebaseFirestore.instance.collection('assignments')
          .where('status', isNotEqualTo: 'Selesai')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(child: Text("Terjadi kesalahan: ${snapshot.error}")),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.assignment_turned_in, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Belum ada tugas yang diberikan.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        final tasks = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final taskData = tasks[index].data() as Map<String, dynamic>;
            final taskId = tasks[index].id;
            
            return _buildTaskCardReal(context, taskData, taskId);
          },
        );
      },
    );
  }

  Widget _buildTaskCardReal(BuildContext context, Map<String, dynamic> data, String id) {
    final title = data['title'] ?? 'Tanpa Judul';
    final location = data['location'] ?? 'Lokasi tidak diketahui';
    final urgency = data['urgency'] ?? 'Biasa';
    final status = data['status'] ?? 'Belum Dimulai';
    
    Color urgencyColor = Colors.blue;
    String urgencyText = "🔵 BIASA";
    if (urgency.toString().toLowerCase() == 'mendesak') {
      urgencyColor = Colors.red;
      urgencyText = "🔴 MENDESAK";
    } else if (urgency.toString().toLowerCase() == 'sedang') {
      urgencyColor = Colors.orange;
      urgencyText = "🟡 SEDANG";
    }

    // === FITUR DELETE: BUNGKUS DENGAN DISMISSIBLE (UNTUK NILAI CRUD) ===
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red[700],
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        child: const Icon(Icons.delete_forever, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Hapus Tugas?"),
              content: const Text("Apakah Anda yakin ingin membatalkan/menghapus tugas ini?"),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Batal"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        // Tembak perintah hapus ke Firestore (DELETE)
        await FirebaseFirestore.instance.collection('assignments').doc(id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tugas berhasil dihapus'), backgroundColor: Colors.red),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: urgencyColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(urgencyText, style: TextStyle(fontSize: 10, color: urgencyColor, fontWeight: FontWeight.bold)),
                ),
                Text("ID: ${id.substring(0, 6)}...", style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, color: Colors.grey), 
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(location, style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(status.toString().toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                TextButton(
                  onPressed: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (context) => OfficerTaskDetailScreen(
                           taskId: id,
                           taskData: data,
                         ),
                       ),
                     );
                  },
                  child: const Text("Detail →", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}