import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:connectivity_plus/connectivity_plus.dart'; 
import 'package:hive/hive.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; 
import 'package:cloud_firestore/cloud_firestore.dart'; // TAMBAHAN: Mesin Firebase

class OfficerProofScreen extends StatefulWidget {
  // TAMBAHAN: Variabel penerima data dari halaman detail
  final String taskId;
  final Map<String, dynamic> taskData;

  const OfficerProofScreen({
    Key? key, 
    required this.taskId, 
    required this.taskData
  }) : super(key: key);

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
  bool _isSubmitting = false; // Status loading saat mengirim

  // === VARIABEL VOICE-TO-TEXT ===
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _previousText = ""; 

  @override
  void initState() {
    super.initState();
    _offlineBox = Hive.box('offline_proofs'); 
    _speech = stt.SpeechToText(); 
    
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

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
      );
      
      if (available) {
        setState(() {
          _isListening = true;
          _previousText = _notesController.text;
          if (_previousText.isNotEmpty && !_previousText.endsWith(" ")) {
            _previousText += " "; 
          }
        });
        
        _speech.listen(
          onResult: (val) => setState(() {
            _notesController.text = _previousText + val.recognizedWords;
          }),
          localeId: 'id_ID', 
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

  // === FUNGSI UTAMA: MENGIRIM BUKTI KE FIREBASE ===
  Future<void> _submitProof() async {
    if (_beforePhoto == null || _afterPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi kedua foto terlebih dahulu!")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Simulasi Upload Foto (Pura-pura loading 2 detik)
      await Future.delayed(const Duration(seconds: 2));

      // 2. Ubah Status di Firebase menjadi 'Selesai'
      await FirebaseFirestore.instance
          .collection('assignments')
          .doc(widget.taskId)
          .update({
            'status': 'Selesai',
            'completion_notes': _notesController.text, // Menyimpan catatan ke database juga!
          });

      // 3. Bersihkan Hive Draft agar form kembali kosong untuk tugas berikutnya
      await _offlineBox.delete('before_photo');
      await _offlineBox.delete('after_photo');
      await _offlineBox.delete('notes');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎉 Tugas berhasil diselesaikan!"), 
            backgroundColor: Colors.green
          ),
        );
        // Kembali ke halaman Beranda
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengirim: $e"), backgroundColor: Colors.red),
        );
      }
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
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }
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
    final title = widget.taskData['title'] ?? 'Tanpa Judul';
    final location = widget.taskData['location'] ?? 'Lokasi tidak diketahui';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title • $location", style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(widget.taskId, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.grey)),
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
    if (_currentPosition == null) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(_isGpsMatch ? Icons.check_circle : Icons.warning, color: _isGpsMatch ? Colors.green : Colors.orange, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "Lokasi terekam: Lat ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng ${_currentPosition!.longitude.toStringAsFixed(4)}",
            style: TextStyle(fontSize: 12, color: Colors.green[800], fontWeight: FontWeight.bold),
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
            hintText: "Misal: Tambal aspal 2m²...",
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : Colors.blue),
                  onPressed: _listen, 
                ),
              ],
            )
          ),
        ),
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
              onPressed: _isSubmitting ? null : _saveDraftToHive, 
              child: const Text("Simpan Draft"),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
              onPressed: _isSubmitting ? null : _submitProof,
              child: _isSubmitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_beforePhoto != null && _afterPhoto != null ? "Kirim Bukti" : "Lengkapi Foto"),
            ),
          ),
        ],
      ),
    );
  }
}