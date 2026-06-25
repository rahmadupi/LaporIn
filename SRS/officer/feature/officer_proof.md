# Officer Proof Upload (Unggah Bukti Pengerjaan)

## 1. Overview

Halaman bagi Petugas Lapangan untuk mengunggah bukti visual (foto) pengerjaan tugas — fitur utama untuk menutup satu siklus dispatch. Mendukung mode **offline-first**: bukti disimpan lokal dulu (Hive), disinkronkan ke cloud saat online.

## 2. Traceability

- **FRs Covered:** OFC-006 (upload bukti), OFC-007 (complete task), OFC-014 (offline queue).
- **Layer:** Presentation + Data (`features/officer/screens/officer_proof_screen.dart` + ImgBB HTTP client + Hive local store).

## 3. UI/UX Requirements

- **AppBar:** Title "Unggah Bukti" + indicator offline/online (banner di atas).
- **Task summary card:** judul tugas + status.
- **Photo picker area:** tombol kamera / galeri + preview foto yang dipilih.
- **Description field:** textarea multi-line untuk deskripsi pengerjaan (opsional, mendukung speech-to-text via `speech_to_text` plugin).
- **GPS capture otomatis:** koordinat lokasi saat bukti diambil (dari `geolocator`).
- **Submit button:** "Kirim Bukti" — disabled jika belum ada foto.

## 4. Database Interactions (Data Layer)

- **Target Collections:** `/reports/{reportId}`, Hive box `offline_proofs`.
- **Upload Foto (Online, OFC-006):**
  1. Base64 encode foto → POST ke **ImgBB API** (eksternal, key di build config).
  2. Simpan URL hasil di `/reports/{reportId}.proofUrl`.
- **Update Laporan:** `firestore.collection('reports').doc(taskId).update({ proofUrl, proofDescription, completedAt: serverTimestamp(), status: 'resolved' })`.
- **Offline Queue (OFC-014):** jika `connectivity_plus` returns no network, simpan payload (base64 foto + metadata) ke Hive box `offline_proofs`. Saat koneksi pulih, sinkronkan otomatis via stream listener.
- **Speech-to-text:** `speech_to_text` plugin untuk input deskripsi via suara.

## 5. Acceptance Criteria

### Scenario 1: Online Submit (OFC-006 + OFC-007)

- **Given** officer on the Proof Upload screen with online connection.
- **When** they select a photo + add description + tap "Kirim Bukti".
- **Then** photo uploads to ImgBB → URL saved to Firestore.
- **And** status changes to `resolved` (pending admin validation).
- **And** officer sees success SnackBar + back-navigates to Task Detail.
- **And** Admin menerima FCM (NOTIF-002).

### Scenario 2: Offline Submit (OFC-014)

- **Given** officer has no internet connection.
- **When** they submit a proof.
- **Then** the payload (photo as base64 + metadata) is saved to Hive box `offline_proofs`.
- **And** UI shows "Tersimpan offline — akan dikirim saat online".
- **When** connectivity is restored.
- **Then** the queued proof is auto-uploaded to ImgBB + Firestore.

## Implementation Reference

- File: `lib/features/officer/screens/officer_proof_screen.dart`
- External service: **ImgBB API** (key configured at build time).
- Local storage: Hive box `offline_proofs`.
