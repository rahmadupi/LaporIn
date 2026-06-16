# Notification Center (Pusat Notifikasi)

## 1. Overview

Notification Center menyediakan pusat informasi notifikasi untuk Admin, mencakup push notification (FCM) dan riwayat in-app. Admin dapat melihat semua notifikasi, menandai sudah dibaca, dan mengatur preferensi notifikasi per tipe.

## 2. Traceability

- **FRs Covered:** NOTIF-001, NOTIF-002, NOTIF-003
- **Related:** ADM-016 (SLA Alert Banner)

## 3. Notification Types

| Type                 | Trigger                      | Target                    |
| -------------------- | ---------------------------- | ------------------------- |
| `new_report`         | Citizen membuat laporan baru | Admin                     |
| `status_update`      | Status laporan berubah       | Citizen (pemilik laporan) |
| `dispatch_assigned`  | Admin menugaskan officer     | Officer                   |
| `dispatch_completed` | Officer menyelesaikan tugas  | Admin                     |
| `sla_breach`         | Laporan >48 jam Pending      | Admin                     |
| `appeal_submitted`   | Warga mengajukan banding     | Admin                     |
| `comment_reply`      | Ada komentar baru di laporan | Subscriber                |

## 4. Database Interactions (Data Layer)

### 4.1 Firestore Collection

**Path:** `/users/{uid}/notifications/{notificationId}`

```json
{
  "type": "new_report",
  "title": "Laporan Baru Masuk",
  "body": "Lubang Jalan di Jalan Sudirman",
  "dataPayload": {
    "reportId": "rep_xxx",
    "category": "cat_roads"
  },
  "isRead": false,
  "createdAt": "2026-06-16T10:00:00Z"
}
```

### 4.2 UI Requirements

- **Notification List:** Scrollable list, newest first
- **Badge Count:** Number di tab/ikon notification (unread count)
- **Pull to Refresh:** Untuk memuat notifikasi terbaru
- **Tap Action:** Tap notifikasi → navigasi ke halaman terkait (detail laporan, dll)
- **Swipe to Delete:** Hapus notifikasi dari riwayat

### 4.3 Preference Settings

- **Toggle per type:** Admin dapat mengaktifkan/mematikan notifikasi per tipe
- **Master toggle:** Aktifkan/nonaktifkan semua notifikasi

## 5. Acceptance Criteria

### Scenario 1: Badge Count Updates

- **Given** Admin memiliki 3 notifikasi belum dibaca
- **When** Admin membuka Notification Center
- **Then** Badge count menunjukkan "3"
- **And** Setelah semua dibaca, badge count menjadi "0"

### Scenario 2: SLA Breach Notification

- **Given** Laporan berstatus Pending > 48 jam
- **When** Cloud Scheduler menjalankan SLA check
- **Then** Notifikasi type `sla_breach` dibuat di `/users/{adminUid}/notifications`
- **And** FCM push dikirim ke Admin

### Scenario 3: Preference Toggle

- **Given** Admin mematikan notifikasi `new_report`
- **When** Warga membuat laporan baru
- **Then** Notifikasi TIDAK dibuat di Firestore untuk Admin tersebut
- **But** FCM tetap dikirim (handled di Cloud Function)
