import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:connectivity_plus/connectivity_plus.dart'; 
import 'package:hive/hive.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; // Import Speech-to-Text

class OfficerProofScreen extends StatefulWidget {
  const OfficerProofScreen({Key? key}) : super(key: key);

  @override
  State<OfficerProofScreen> createState() => _OfficerProofScreenState();
}

class _OfficerProofScreenState extends State<OfficerProofScreen> {
  // === VARIABEL SINYAL ===
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // === VARIABEL KAMERA ===
  File? _beforePhoto;
  File? _afterPhoto;
  final ImagePicker _picker = ImagePicker();

  // === VARIABEL GPS ===
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isGpsMatch = true;

  // === VARIABEL FORM & HIVE ===
  final TextEditingController _notesController = TextEditingController();
  late Box _offlineBox;

  // === VARIABEL VOICE-TO-TEXT ===
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _previousText = ""; // Untuk menyimpan teks yang sudah diketik/diucapkan sebelumnya

  @override
  void initState() {
    super.initState();
    _offlineBox = Hive.box('offline_proofs'); 
    _speech = stt.SpeechToText(); // Inisialisasi engine suara
    
    _checkInitialConnection();
    _loadSavedDraft(); 
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      bool isCurrentlyOffline = results.contains(ConnectivityResult.none);
      setState(() => _isOffline = isCurrentlyOffline);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyOffline ? "Koneksi terputus. Masuk ke mode Offline." : "Koneksi pulih. Anda kembali Online."),
            backgroundColor: isCurrentlyOffline ? Colors.orange[800] : Colors.green[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  // === FUNGSI VOICE-TO-TEXT ===
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          debugPrint('onStatus: $val');
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => debugPrint('onError: $val'),
      );
      
      if (available) {
        setState(() {
          _isListening = true;
          // Simpan teks yang sudah ada agar tidak tertimpa saat mulai bicara baru
          _previousText = _notesController.text;
          if (_previousText.isNotEmpty && !_previousText.endsWith(" ")) {
            _previousText += " "; 
          }
        });
        
        _speech.listen(
          onResult: (val) => setState(() {
            // Gabungkan teks lama dengan hasil ucapan baru
            _notesController.text = _previousText + val.recognizedWords;
          }),
          localeId: 'id_ID', // Paksa menggunakan bahasa Indonesia
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _checkInitialConnection() async {
    final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
    setState(() => _isOffline = results.contains(ConnectivityResult.none));
  }

  void _loadSavedDraft() {
    String? beforeBoxPath = _offlineBox.get('before_photo');
    String? afterBoxPath = _offlineBox.get('after_photo');
    String? savedNotes = _offlineBox.get('notes');

    setState(() {
      if (beforeBoxPath != null) _beforePhoto = File(beforeBoxPath);
      if (afterBoxPath != null) _afterPhoto = File(afterBoxPath);
      if (savedNotes != null) _notesController.text = savedNotes;
    });
  }

  Future<void> _saveDraftToHive() async {
    try {
      await _offlineBox.put('before_photo', _beforePhoto?.path);
      await _offlineBox.put('after_photo', _afterPhoto?.path);
      await _offlineBox.put('notes', _notesController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✓ Draft berhasil disimpan di memori lokal"), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      debugPrint("Gagal menyimpan draft: $e");
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _notesController.dispose(); 
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = position;
      _isLoadingLocation = false;
      _isGpsMatch = true; 
    });
  }

  Future<void> _takePhoto(bool isBefore) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);

      if (photo != null) {
        setState(() {
          if (isBefore) _beforePhoto = File(photo.path);
          else _afterPhoto = File(photo.path);
        });
        await _getCurrentLocation();
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
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text("Bukti Penyelesaian", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Center(
            child: Text(
              _isOffline ? "🟠 Offline — akan disinkronkan" : "🟢 Online",
              style: TextStyle(fontSize: 12, color: _isOffline ? Colors.orange[800] : Colors.green[700], fontWeight: FontWeight.bold),
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
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
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
        Text("💡 Pastikan foto jelas dan mencakup area kerusakan", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildPhotoBox(String label, bool isBefore, File? photoFile) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _takePhoto(isBefore),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: photoFile != null 
              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(photoFile, fit: BoxFit.cover))
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
    if (_isLoadingLocation) {
      return const Row(
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 8),
          Text("Mendeteksi koordinat lokasi...", style: TextStyle(fontSize: 12, color: Colors.blue)),
        ],
      );
    }

    if (_currentPosition == null) {
      return const Row(
        children: [
          Icon(Icons.location_off, color: Colors.grey, size: 20),
          SizedBox(width: 8),
          Text("Lokasi belum didapatkan (Ambil foto terlebih dahulu)", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
    }

    return Row(
      children: [
        Icon(_isGpsMatch ? Icons.check_circle : Icons.warning, color: _isGpsMatch ? Colors.green : Colors.orange, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _isGpsMatch 
                ? "Sesuai: Lat ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng ${_currentPosition!.longitude.toStringAsFixed(4)}" 
                : "Lokasi foto berjarak 80m dari tugas. Lanjutkan?",
            style: TextStyle(fontSize: 12, color: _isGpsMatch ? Colors.green[800] : Colors.orange[800], fontWeight: FontWeight.bold),
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
          controller: _notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Misal: Tambal aspal 2m², material HRS-Base...",
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // === TOMBOL MIKROFON YANG SUDAH HIDUP ===
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none, 
                    color: _isListening ? Colors.red : Colors.blue
                  ),
                  onPressed: _listen, // Panggil fungsi rekam suara saat ditekan
                ),
              ],
            )
          ),
        ),
        // === INDIKATOR VISUAL SAAT MEREKAM ===
        if (_isListening) 
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)),
                const SizedBox(width: 8),
                Text("Sedang mendengarkan...", style: TextStyle(fontSize: 12, color: Colors.red[700], fontStyle: FontStyle.italic)),
              ],
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
              onPressed: _saveDraftToHive, 
              child: const Text("Simpan Draft"),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
              onPressed: () {},
              child: Text(_beforePhoto != null && _afterPhoto != null ? "Kirim Bukti" : "Lengkapi Foto"),
            ),
          ),
        ],
      ),
    );
  }
}