import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';

/// Jenis kegagalan upload, dipetakan repository ke pesan ramah-pengguna.
enum CloudinaryErrorKind { notConfigured, unauthorized, network, invalid, unknown }

/// Exception saat upload ke Cloudinary gagal.
class CloudinaryUploadException implements Exception {
  CloudinaryUploadException(this.kind, [this.detail]);

  final CloudinaryErrorKind kind;
  final String? detail;

  @override
  String toString() => 'CloudinaryUploadException($kind): $detail';
}

/// Hasil sukses upload.
class CloudinaryUploadResult {
  const CloudinaryUploadResult({required this.secureUrl, required this.publicId});

  /// URL HTTPS publik gambar — inilah yang disimpan ke Firestore.
  final String secureUrl;

  /// Public ID Cloudinary (untuk transformasi/hapus dari SERVER bila perlu).
  final String publicId;
}

/// Mengunggah gambar ke Cloudinary lewat **unsigned upload** (REST API).
///
/// Pengganti Firebase Storage agar proyek tetap gratis tanpa mengaktifkan Blaze
/// plan. Unsigned preset memungkinkan klien mengunggah TANPA menaruh API Secret
/// di aplikasi; cukup `cloudName` + `uploadPreset` publik (lihat
/// [CloudinaryConfig]).
///
/// Semua pemanggilan HTTP terkurung di kelas ini agar repository tidak tahu
/// detail transport (sejajar pola "SDK terkurung di repo" pada NFR-6).
class CloudinaryStorageService {
  CloudinaryStorageService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Batas waktu agar UI tidak menggantung bila jaringan sangat lambat.
  static const Duration _timeout = Duration(seconds: 60);

  /// Unggah [file] gambar laporan. Mengembalikan secure URL HTTPS.
  ///
  /// Melempar [CloudinaryUploadException] dengan [CloudinaryErrorKind] yang
  /// sesuai bila gagal (config kosong, jaringan, ditolak, dll).
  Future<CloudinaryUploadResult> uploadReportPhoto(File file) async {
    if (!CloudinaryConfig.isConfigured) {
      throw CloudinaryUploadException(
        CloudinaryErrorKind.notConfigured,
        'cloudName/uploadPreset belum diisi. Lihat CloudinaryConfig.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      // Folder opsional agar rapi di Media Library. Berlaku selama preset tidak
      // mengunci folder. Aman dihapus bila preset menolaknya.
      ..fields['folder'] = 'reports'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(request).timeout(_timeout);
    } on TimeoutException catch (e) {
      throw CloudinaryUploadException(CloudinaryErrorKind.network, '$e');
    } on SocketException catch (e) {
      throw CloudinaryUploadException(CloudinaryErrorKind.network, '$e');
    } on http.ClientException catch (e) {
      throw CloudinaryUploadException(CloudinaryErrorKind.network, '$e');
    } catch (e) {
      throw CloudinaryUploadException(CloudinaryErrorKind.unknown, '$e');
    }

    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      final secureUrl = _string(body, 'secure_url');
      if (secureUrl == null || secureUrl.isEmpty) {
        throw CloudinaryUploadException(
          CloudinaryErrorKind.unknown,
          'Respons 200 tanpa secure_url.',
        );
      }
      return CloudinaryUploadResult(
        secureUrl: secureUrl,
        publicId: _string(body, 'public_id') ?? '',
      );
    }

    if (kDebugMode) {
      debugPrint('[Cloudinary] Upload gagal HTTP ${streamed.statusCode}: $body');
    }

    // Cloudinary mengembalikan { "error": { "message": "..." } } saat gagal.
    final kind = switch (streamed.statusCode) {
      400 || 420 || 422 => CloudinaryErrorKind.invalid,
      401 || 403 => CloudinaryErrorKind.unauthorized,
      _ => CloudinaryErrorKind.unknown,
    };
    throw CloudinaryUploadException(kind, 'HTTP ${streamed.statusCode}');
  }

  /// Ambil field string dari respons JSON; null bila tidak ada / parse gagal.
  String? _string(String body, String key) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json[key] as String?;
    } catch (_) {
      return null;
    }
  }
}
