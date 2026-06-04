import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OfficerProofScreen extends StatefulWidget {
  const OfficerProofScreen({Key? key}) : super(key: key);

  @override
  State<OfficerProofScreen> createState() => _OfficerProofScreenState();
}

class _OfficerProofScreenState extends State<OfficerProofScreen> {
  // Dummy state untuk UI
  final bool _isOffline = false;
  final bool _isGpsMatch = true;

  // === VARIABEL UNTUK KAMERA ===
  File? _beforePhoto;
  File? _afterPhoto;
  final ImagePicker _picker = ImagePicker();

  // === FUNGSI MEMBUKA KAMERA ===
  Future<void> _takePhoto(bool isBefore) async {
    try {
      // Membuka kamera HP
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50, // Kompres ukuran gambar agar tidak terlalu berat
      );

      if (photo != null) {
        setState(() {
          if (isBefore) {
            _beforePhoto = File(photo.path);
          } else {
            _afterPhoto = File(photo.path);
          }
        });
      }
    } catch (e) {
      debugPrint("Gagal membuka kamera: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskInfoCard(),
            const SizedBox(height: 24),
            _buildPhotoSection(),
            const SizedBox(height: 16),
            _buildGpsIndicator(),
            const SizedBox(height: 24),
            _buildNotesSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomStickyButtons(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          Navigator.pop(context); // Fungsi kembali ke layar sebelumnya
        },
      ),
      title: const Text("Bukti Penyelesaian", 
        style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Center(
            child: Text(
              _isOffline ? "🟠 Offline — akan disinkronkan" : "🟢 Online",
              style: TextStyle(
                fontSize: 12, 
                color: _isOffline ? Colors.orange[800] : Colors.green[700],
                fontWeight: FontWeight.bold
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTaskInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Jalan Berlubang • Jl. Diponegoro No. 45", style: TextStyle(fontSize: 12)),
          SizedBox(height: 4),
          Text("LPR-2026-0001234", style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Foto Bukti (Wajib 2 foto)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPhotoBox("📷 Foto SEBELUM", true, _beforePhoto)),
            const SizedBox(width: 16),
            Expanded(child: _buildPhotoBox("📷 Foto SESUDAH", false, _afterPhoto)),
          ],
        ),
        const SizedBox(height: 8),
        Text("💡 Pastikan foto jelas dan mencakup area kerusakan", 
          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // Parameter diubah untuk menerima status 'isBefore' dan 'file gambar'
  Widget _buildPhotoBox(String label, bool isBefore, File? photoFile) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _takePhoto(isBefore), // Memanggil fungsi kamera saat diklik
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            // Logika: Jika foto ada, tampilkan fotonya. Jika tidak, tampilkan icon kamera.
            child: photoFile != null 
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(photoFile, fit: BoxFit.cover),
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("Ketuk untuk\nambil foto", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildGpsIndicator() {
    return Row(
      children: [
        Icon(_isGpsMatch ? Icons.check_circle : Icons.warning, 
          color: _isGpsMatch ? Colors.green : Colors.orange, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _isGpsMatch 
                ? "Lokasi foto sesuai dengan lokasi tugas" 
                : "Lokasi foto berjarak 80m dari lokasi tugas. Lanjutkan?",
            style: TextStyle(fontSize: 12, color: _isGpsMatch ? Colors.green[800] : Colors.orange[800]),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Catatan Pekerjaan", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Misal: Tambal aspal 2m², material HRS-Base, durasi pengerjaan 90 menit",
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: const Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [Icon(Icons.mic, color: Colors.blue)],
            )
          ),
        ),
      ],
    );
  }

  Widget _buildBottomStickyButtons() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: OutlinedButton(
              onPressed: () {},
              child: const Text("Simpan Draft"),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
              onPressed: () {},
              // Tombol akan mendeteksi apakah kedua foto sudah terisi atau belum
              child: Text(_beforePhoto != null && _afterPhoto != null ? "Kirim Bukti" : "Lengkapi Foto"),
            ),
          ),
        ],
      ),
    );
  }
}