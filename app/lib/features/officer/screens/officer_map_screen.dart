import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfficerMapScreen extends StatelessWidget {
  const OfficerMapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Titik tengah default saat peta pertama kali dibuka (Kampus ITS)
    final LatLng defaultLocation = const LatLng(-7.282356, 112.794925);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      // Membungkus body dengan StreamBuilder untuk membaca Firestore secara Real-Time
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('assignments')
    .where('status', isNotEqualTo: 'Selesai')
    .snapshots(),
        builder: (context, snapshot) {
          // Tampilkan loading saat data sedang ditarik
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Tampilkan error jika ada masalah koneksi
          if (snapshot.hasError) {
            return const Center(child: Text("Terjadi kesalahan saat memuat data peta"));
          }

          // Siapkan wadah kosong untuk menampung pin/marker
          List<Marker> dynamicMarkers = [];

          // Jika data sukses ditarik dan tidak kosong
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            // Looping/cek satu per satu semua tugas di Firestore
            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              
              // Filter: Hanya tampilkan tugas yang memiliki titik koordinat GPS
              if (data['latitude'] != null && data['longitude'] != null) {
                // Konversi data dari Firebase ke tipe double
                double lat = data['latitude'] is double ? data['latitude'] : double.tryParse(data['latitude'].toString()) ?? 0.0;
                double lng = data['longitude'] is double ? data['longitude'] : double.tryParse(data['longitude'].toString()) ?? 0.0;

                // Rakit marker dan masukkan ke dalam wadah dynamicMarkers
                dynamicMarkers.add(
                  Marker(
                    point: LatLng(lat, lng),
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () {
                        // Munculkan pop-up kecil saat pin merah ditekan
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(data['title'] ?? 'Laporan Darurat'),
                            backgroundColor: Colors.blue[800],
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ),
                );
              }
            }
          }

          // Render petanya!
          return FlutterMap(
            options: MapOptions(
              initialCenter: defaultLocation, 
              initialZoom: 14.0, // Skala zoom kota
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.laporin', 
              ),
              MarkerLayer(
                markers: dynamicMarkers, // Memasukkan seluruh pin merah yang sudah dirakit
              ),
            ],
          );
        },
      ),
    );
  }
}