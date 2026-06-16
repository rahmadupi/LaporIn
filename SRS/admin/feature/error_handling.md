# Error Handling & Offline Mode (Pengelolaan Kesalahan)

## 1. Overview

Dokumen ini menetapkan penanganan error dan state manajemen untuk Admin app. Mencakup error messages, retry logic, dan offline capabilities.

## 1.1 Error Reporting (Firebase Crashlytics)

**Penting:** Semua error harus dilaporkan ke Firebase Crashlytics untuk debugging dan monitoring stabilitas app.

### Konfigurasi
- **Package:** `firebase_crashlytics`
- **Enable in:** Debug mode (via Firebase CLI) + Production
- **Symbol upload:** Automatic via Flutter build

### Reporting Strategy
| Event | Report to Crashlytics |
|-------|---------------------|
| Uncaught exception | Automatic |
| Caught exception (unexpected) | Manual `crashlytics.recordException()` |
| Firestore permission denied | Manual (non-sensitive) |
| Image upload failure | Manual |
| API/Cloud Function timeout | Manual |

### Yang TIDAK Dilaporkan
- Network offline (expected, not an error)
- User input validation errors
- Permission denied on own data
- Session expired (handled gracefully)

### Crashlytics Dashboard Alerts
- Setup alert untuk: New fatal issue, regression, spike in non-fatal

## 2. Error Categories & Messages

### 2.1 Network Errors

| Error           | Message                             | Action                     |
| --------------- | ----------------------------------- | -------------------------- |
| No internet     | "Periksa koneksi internet Anda"     | Show banner, retry button  |
| Timeout         | "Server tidak merespons. Coba lagi" | Auto-retry 3x, then manual |
| Slow connection | (No message, show skeleton loader)  | -                          |

### 2.2 Authentication Errors

| Error                  | Message                              | Action              |
| ---------------------- | ------------------------------------ | ------------------- |
| Session expired        | "Sesi berakhir. Silakan login ulang" | Redirect to Login   |
| Token revoked (banned) | "Akun Anda telah diblokir"           | Redirect to Landing |
| Permission denied      | "Anda tidak memiliki akses"          | Show error, log out |

### 2.3 Firestore Errors

| Error              | Message                                      | Action            |
| ------------------ | -------------------------------------------- | ----------------- |
| Permission denied  | "Tidak memiliki izin untuk aksi ini"         | Show error toast  |
| Document not found | "Data tidak ditemukan"                       | Refresh list      |
| Write failed       | "Gagal menyimpan. Coba lagi"                 | Show retry button |
| Quota exceeded     | "Terlalu banyak permintaan. Tunggu sebentar" | Show cooldown     |

### 2.4 Feature-Specific Errors

| Feature        | Error               | Message                                      |
| -------------- | ------------------- | -------------------------------------------- |
| Dispatch       | Officer unavailable | "Petugas tidak tersedia. Pilih petugas lain" |
| Image Upload   | File too large      | "Ukuran maksimal 5MB"                        |
| Image Upload   | Unsupported format  | "Format harus JPG/PNG"                       |
| Ban User       | Already banned      | "User sudah diblokir"                        |
| Delete Account | Wrong confirmation  | "Ketikan \"HAPUS\" dengan benar"             |
| Appeal         | Already appealed    | "Appeal sudah dikirim"                       |
| Category       | Duplicate name      | "Nama kategori sudah ada"                    |

## 3. State Management

### 3.1 UI States per Screen

- **Loading:** Skeleton loaders / Shimmer
- **Success:** Data displayed
- **Empty:** Illustration + "Tidak ada data"
- **Error:** Error message + Retry button
- **Offline:** Cached data + offline banner

### 3.2 Error Boundary

- Wrap each screen with error boundary
- Show generic "Terjadi kesalahan" for unexpected errors
- Log errors to analytics (non-sensitive)

## 4. Offline Mode

### 4.1 Caching Strategy

- **Reports List:** Cache last 50 items, refresh on app open
- **Dashboard Stats:** Cache, refresh in background
- **User Profile:** Cache, sync on update

### 4.2 Offline Actions

- Queue actions when offline:
  - Comment creation (sync when online)
  - Status filters (apply locally)
- Block actions when offline:
  - Dispatch (requires server)
  - Ban/Unban (requires server)
  - Delete account (requires server)

### 4.3 Offline Indicator

- Show persistent banner: "Mode offline - beberapa fitur terbatas"
- Disable buttons that require server

## 5. Retry Logic

### 5.1 Automatic Retry

| Action            | Retry Count | Interval   |
| ----------------- | ----------- | ---------- |
| Firestore read    | 3x          | 1s, 2s, 3s |
| Image upload      | 2x          | 2s, 4s     |
| FCM token refresh | 2x          | 1s, 2s     |

### 5.2 Manual Retry

- Show "Coba Lagi" button for failed actions
- Preserve form data on retry

## 6. Acceptance Criteria

### Scenario 1: Network Loss During Dispatch

- **Given** Admin initiates dispatch
- **When** internet disconnects
- **Then** "Periksa koneksi internet" banner appears
- **And** dispatch button disabled
- **When** internet returns
- **Then** banner dismissed, retry available

### Scenario 2: Session Expired

- **Given** Admin is on any page
- **When** session expires (401 response)
- **Then** "Sesi berakhir" dialog appears
- **And** Admin redirected to Login

### Scenario 3: Offline Viewing

- **Given** Admin opens app without internet
- **When** reports list loads
- **Then** cached data shown
- **And** "Mode offline" banner displayed
- **And** dispatch button shows "Perlu koneksi"
