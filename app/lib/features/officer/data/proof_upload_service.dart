import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show ValueChanged;
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Layanan yang dipakai oleh `OfficerProofScreen` — merangkum:
///
/// 1. Upload foto ke **ImgBB** (HTTP). Kunci API masih hard-coded
///    mengikuti kode referensi di SRS; idealnya dipindah ke
///    `--dart-define` di langkah berikutnya (lihat PLAN §6 R1).
/// 2. Antrean offline di Hive box `offline_proofs`.
/// 3. Listener konektivitas (connectivity_plus) untuk sinkron otomatis.
/// 4. Pembungkus speech-to-text dengan locale `id_ID`.
/// 5. Pembungkus geolocator dengan permission handling.
/// 6. Update `/reports/{id}` di Firestore — field-field bukti
///    (`photoBeforeUrl`, `photoAfterUrl`, `proofDescription`,
///    `proofLocation`, `completedAt`) ditulis mentah via Map, mengikuti
///    konvensi kode referensi di SRS.
///
/// Pola dan urutan langkah mengikuti kode asli di
/// `SRS/from other branch/officer-app/lib/features/officer/screens/officer_proof_screen.dart`,
/// disesuaikan dengan schema Firestore LaporIn saat ini (lihat
/// `SRS/data-model.md` §3.2 + `SRS/officer/feature/officer_proof.md`).
class ProofUploadService {
  ProofUploadService({
    http.Client? httpClient,
    String imgbbApiKey = '072ae2e1c37bce3c098abf56b08d9c89',
    String offlineBoxName = 'offline_proofs',
  }) : _http = httpClient ?? http.Client(),
       _imgbbApiKey = imgbbApiKey,
       _offlineBox = Hive.box(offlineBoxName);

  final http.Client _http;
  final String _imgbbApiKey;
  final Box _offlineBox;

  // ===========================================================================
  // ImgBB upload
  // ===========================================================================

  /// Encode gambar ke Base64 lalu POST ke ImgBB. Return URL publik
  /// (`display_url`) atau `null` saat gagal.
  Future<String?> uploadImageToImgBB(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await _http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {'key': _imgbbApiKey, 'image': base64Image},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        return data['data']?['display_url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Upload dua foto secara paralel. Return `({beforeUrl, afterUrl})`.
  /// Jika salah satu null, perlakukan sebagai kegagalan total di caller.
  Future<({String? beforeUrl, String? afterUrl})> uploadPair(
    File before,
    File after,
  ) async {
    final results = await Future.wait([
      uploadImageToImgBB(before),
      uploadImageToImgBB(after),
    ]);
    return (beforeUrl: results[0], afterUrl: results[1]);
  }

  // ===========================================================================
  // Hive offline draft
  // ===========================================================================

  /// Simpan draft lokal (path foto + catatan). Dipakai oleh tombol
  /// "Simpan Draft" atau otomatis sebelum submit offline.
  Future<void> saveDraft({
    required String taskId,
    String? beforePath,
    String? afterPath,
    String? notes,
  }) async {
    await _offlineBox.put('${taskId}_before', beforePath);
    await _offlineBox.put('${taskId}_after', afterPath);
    await _offlineBox.put('${taskId}_notes', notes);
  }

  /// Muat draft lokal. Return map dengan key `before` / `after` / `notes`
  /// masing-masing berisi path file atau null.
  Map<String, String?> loadDraft(String taskId) {
    return {
      'before': _offlineBox.get('${taskId}_before') as String?,
      'after': _offlineBox.get('${taskId}_after') as String?,
      'notes': _offlineBox.get('${taskId}_notes') as String?,
    };
  }

  Future<void> clearDraft(String taskId) async {
    await _offlineBox.delete('${taskId}_before');
    await _offlineBox.delete('${taskId}_after');
    await _offlineBox.delete('${taskId}_notes');
  }

  // ===========================================================================
  // Connectivity
  // ===========================================================================

  Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  Stream<bool> onlineStream() {
    return Connectivity().onConnectivityChanged.map(
      (r) => !r.contains(ConnectivityResult.none),
    );
  }

  // ===========================================================================
  // Speech-to-text
  // ===========================================================================

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _previousText = '';

  bool get isListening => _isListening;

  Future<bool> ensureSpeechInitialized() => _speech.initialize();

  /// Mulai / hentikan listening. `currentText` adalah teks awal (untuk
  /// append), dan `onUpdate` dipanggil dengan teks baru setiap kali ada
  /// hasil speech.
  Future<void> toggleListening({
    required String currentText,
    required ValueChanged<String> onUpdate,
  }) async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      return;
    }
    final available = await ensureSpeechInitialized();
    if (!available) return;
    _isListening = true;
    _previousText = currentText;
    if (_previousText.isNotEmpty && !_previousText.endsWith(' ')) {
      _previousText += ' ';
    }
    await _speech.listen(
      onResult: (val) => onUpdate('$_previousText${val.recognizedWords}'),
      localeId: 'id_ID',
    );
  }

  Future<void> stopListening() => _speech.stop();

  // ===========================================================================
  // Geolocator
  // ===========================================================================

  Future<Position?> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) return null;

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ===========================================================================
  // Firestore updates — ditulis mentah via Map (field-field bukti
  // belum ada di ReportEntity, ditambahkan via raw write).
  // ===========================================================================

  /// Tandai tugas mulai dikerjakan (status `dispatched` → `in_progress`).
  /// Dipakai oleh tombol "Mulai Pengerjaan" di Task Detail.
  Future<void> markInProgress(String taskId) async {
    await FirebaseFirestore.instance.collection('reports').doc(taskId).update({
      'status': 'in_progress',
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Tolak tugas (status → `in_review`) dengan alasan. Dipakai oleh
  /// tombol "Tolak Tugas" di Task Detail.
  Future<void> rejectTask(String taskId, String reason) async {
    await FirebaseFirestore.instance.collection('reports').doc(taskId).update({
      'status': 'in_review',
      'rejectComment': reason,
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Tulis bukti ke `/reports/{id}` (status → `resolved`).
  ///
  /// Field yang ditulis mentah (belum ada di ReportEntity):
  /// - `photoBeforeUrl`, `photoAfterUrl` (legacy dari SRS asli)
  /// - `proofDescription` (catatan teks)
  /// - `proofLocation` (GeoPoint)
  /// - `completedAt` (serverTimestamp)
  /// - `proofUrl` (canonical URL untuk UI = foto "sesudah")
  Future<void> commitProofToFirestore({
    required String taskId,
    required String? beforeUrl,
    required String? afterUrl,
    required String? description,
    required Position? position,
  }) async {
    final canonicalProof = afterUrl ?? beforeUrl;
    final data = <String, dynamic>{
      'status': 'resolved',
      'completedAt': FieldValue.serverTimestamp(),
      if (beforeUrl != null) 'photoBeforeUrl': beforeUrl,
      if (afterUrl != null) 'photoAfterUrl': afterUrl,
      if (canonicalProof != null) 'proofUrl': canonicalProof,
      if (description != null) 'proofDescription': description,
      if (position != null)
        'proofLocation': GeoPoint(position.latitude, position.longitude),
    };
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(taskId)
        .update(data);
  }

  /// Tutup HTTP client. Aman dipanggil di `dispose()`.
  void dispose() {
    _http.close();
  }
}
