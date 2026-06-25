# Officer App Implementation Plan

> **Source of truth:** [officer-overview.md](./officer-overview.md) + 7 feature specs in [feature/](./feature/).
> **Architecture:** App-Within-An-App (DDD) — see [../system-architecture.md](../system-architecture.md).
> **Data model:** [../data-model.md](../data-model.md).
> **Status legend:** ✅ done · ⚠️ partial · 🟡 placeholder · ❌ missing.

---

## 1. Current State Inventory

Audit of what's actually in `app/lib/` vs what the SRS claims.

| #   | Feature (SRS)                 | File                                                                                                                                       | SRS Status     | Code Reality                                                                                       | Gap                                                   |
| --- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | -------------- | -------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| 1   | Officer Home (Tugas)          | `workspaces/officer_app/screens/officer_shell_screen.dart` (Tugas tab)                                                                     | ✅ Implemented | 🟡 `UnderConstructionPage` placeholder                                                             | **Full rebuild**                                      |
| 2   | Officer Laporan (Public feed) | _(none)_                                                                                                                                   | 🟡 Planned     | 🟡 `UnderConstructionPage` placeholder                                                             | **Full build**                                        |
| 3   | Officer History (Riwayat)     | _(none)_                                                                                                                                   | ✅ Implemented | 🟡 `UnderConstructionPage` placeholder                                                             | **Full rebuild**                                      |
| 4   | Officer Profile (Profil)      | `features/officer/screens/officer_profile_screen.dart` (legacy) + `workspaces/officer_app/screens/officer_profile_screen.dart` (shell-tab) | ✅ Implemented | ⚠️ Legacy file hard-codes `User1`; workspace copy works but lacks fields per spec                  | **Refactor + extend**                                 |
| 5   | Officer Task Detail           | _(none)_                                                                                                                                   | ✅ Implemented | ❌ Missing                                                                                         | **Full build**                                        |
| 6   | Officer Proof Upload          | _(none)_                                                                                                                                   | ✅ Implemented | ❌ Missing                                                                                         | **Full build**                                        |
| 7   | Officer Notification          | `workspaces/officer_app/screens/officer_notification_screen.dart`                                                                          | 🟡 Planned     | ⚠️ Wraps shared `NotificationScreen`; deep-link TODO; per-user unread count missing                | **Wire deep-links + unread count**                    |
| 8   | Officer Shell                 | `workspaces/officer_app/screens/officer_shell_screen.dart`                                                                                 | ✅             | ✅                                                                                                 | Bell icon wired, but `onNotificationTap` is TODO-only |
| 9   | Peta (Map tab)                | _(inline placeholder)_                                                                                                                     | 🟡 Placeholder | 🟡 `UnderConstructionPage` placeholder                                                             | **Defer** (low priority)                              |
| 10  | Routing                       | `core/routing/app_router.dart`, `app_routes.dart`                                                                                          | ✅             | ✅ Auth-guard done; officer sub-routes still need `task/:id`, `proof/:id`, `report/:id`, `laporan` | **Add routes**                                        |

### Legacy file to retire

`app/lib/features/officer/screens/officer_profile_screen.dart` — duplicated by the workspace copy and hard-codes `User1`. **Delete after workspace copy is verified.**

---

## 2. Shared Components We Can Reuse

Already in `app/lib/shared/ui/`:

| Component                      | Used by               | Reuse opportunity                                                |
| ------------------------------ | --------------------- | ---------------------------------------------------------------- |
| `RoleScaffold`                 | Officer shell         | Shell only                                                       |
| `NotificationScreen` (generic) | Officer/Citizen/Admin | Already powers officer notification — just needs per-user wiring |
| `UnderConstructionPage`        | All 3 shells          | Temporary while we build out                                     |
| `BackPressHandler`             | All 3 shells          | Already wired in shell                                           |

Already in `app/lib/shared_domain_data/`:

| Provider                 | Purpose                      | Notes                            |
| ------------------------ | ---------------------------- | -------------------------------- |
| `authRepositoryProvider` | Login/logout, FCM token mgmt | Reused by shell logout           |
| `currentUserProvider`    | Stream of current user       | Drives profile + role gating     |
| `officerByIdProvider`    | Per-officer fetch            | Used in admin's officer drill-in |

### Things we need to add to `shared_domain_data/`

| New                                                                                                            | Justification                                                                        |
| -------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `report_repository` (queries: by assignedOfficerId, by status range, create emergency, append officer sub-doc) | Power Officer Home + History + Laporan + Task Detail                                 |
| `dispatch_repository` (read dispatches by officerId)                                                           | Optional — currently SRS reads via `/reports/{id}.assignedOfficerId` so we can defer |
| `notification_repository` (stream of `/users/{uid}/notifications`, mark-as-read)                               | Power officer unread badge + deep-link                                               |
| `user_profile_repository` (update name, phone, photo, isAvailable)                                             | OFC-010                                                                              |

### Plugins required (verify in `pubspec.yaml`)

| Plugin                   | Used by                                            | Status                              |
| ------------------------ | -------------------------------------------------- | ----------------------------------- |
| `cloud_firestore`        | All Firestore reads                                | ✅ already in project               |
| `firebase_messaging`     | OFC-004 FCM                                        | Verify — needed for topic-based FCM |
| `geolocator`             | OFC-012 GPS, OFC-006 proof coords                  | Verify                              |
| `image_picker`           | OFC-006 photo capture                              | Verify                              |
| `connectivity_plus`      | OFC-014 offline queue                              | Verify                              |
| `hive` / `hive_flutter`  | OFC-014 offline box `offline_proofs`               | Verify                              |
| `speech_to_text`         | OFC-006 description dictation                      | Verify (optional)                   |
| `flutter_image_compress` | OFC-006 reduce photo size before upload            | Verify (optional but recommended)   |
| `go_router`              | Sub-routes (`task/:id`, `proof/:id`, `report/:id`) | ✅                                  |
| `flutter_riverpod`       | State management                                   | ✅                                  |

> **Action item for M0:** run `flutter pub deps` and confirm every "Verify" plugin is declared. Add any missing.

---

## 3. FR → Screen → Data Operation Map

| FR      | Screen                                        | Firestore path                          | Operation                                                                                         |
| ------- | --------------------------------------------- | --------------------------------------- | ------------------------------------------------------------------------------------------------- |
| OFC-001 | `OfficerLoginScreen` (lives in landing/auth)  | `/users/{uid}`                          | Block login if `status != "active"`                                                               |
| OFC-002 | `OfficerHomeScreen`                           | `/reports/{id}`                         | Stream `where("assignedOfficerId","==",uid).where("status",whereIn:["dispatched","in_progress"])` |
| OFC-003 | `OfficerLaporanScreen` + `ReportDetailScreen` | `/reports/{id}/officer/{officerId}`     | `set({status:"requested", requestedAt})`                                                          |
| OFC-004 | `NotificationService` (background)            | n/a                                     | Topic subscribe `officer_{uid}` + topic `relawan` (broadcast)                                     |
| OFC-005 | `OfficerTaskDetailScreen`                     | `/reports/{id}`                         | `update({status:"in_progress", startedAt})`                                                       |
| OFC-006 | `OfficerProofScreen`                          | `/reports/{id}` + ImgBB                 | Upload → save `proofUrl`, `proofDescription`                                                      |
| OFC-007 | `OfficerProofScreen` (Submit)                 | `/reports/{id}`                         | `update({status:"resolved", completedAt})`                                                        |
| OFC-008 | `OfficerTaskDetailScreen` (Tolak)             | `/reports/{id}`                         | `update({status:"in_review", rejectComment})`                                                     |
| OFC-009 | `OfficerHistoryScreen`                        | `/reports/{id}`                         | Stream `where status in [resolved, rejected]`                                                     |
| OFC-010 | `OfficerProfileScreen` (edit mode)            | `/users/{uid}`                          | `update({displayName, phoneNumber, isAvailable})`                                                 |
| OFC-011 | `OfficerProfileScreen` / Notification AppBar  | `/users/{uid}` + auth                   | `update({fcmToken:null})` → `signOut()`                                                           |
| OFC-012 | FAB on `OfficerHomeScreen` → AlertDialog      | `/reports/{id}`                         | `add({reporterId:officerUid, status:"pending", location from geolocator})`                        |
| OFC-013 | Bell icon on all officer AppBars              | n/a                                     | `context.push(AppRoutes.officerNotifications)`                                                    |
| OFC-014 | `OfficerProofScreen` + `ConnectivityService`  | `/reports/{id}` + Hive `offline_proofs` | Queue when offline; flush on reconnect                                                            |
| OFC-015 | `OfficerLaporanScreen`                        | `/reports/{id}`                         | Stream `where status in [pending, in_review].limit(50)`                                           |

---

## 4. Milestones

Grouped so each milestone produces a demoable end-to-end slice.

### M0 — Foundation (no UI changes)

1. **Verify `pubspec.yaml`** — add `geolocator`, `image_picker`, `connectivity_plus`, `hive`, `hive_flutter`, `firebase_messaging`, `flutter_image_compress` (if missing).
2. **Permissions** — declare Android `ACCESS_FINE_LOCATION`, `INTERNET`, `READ_MEDIA_IMAGES` in `android/app/src/main/AndroidManifest.xml`; iOS `NSLocationWhenInUseUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` in `Info.plist`.
3. **Add new shared providers** under `shared_domain_data/`:
   - `report_repository_provider`
   - `notification_repository_provider`
   - `my_assigned_tasks_provider` (FutureProvider.family)
   - `my_officer_self_requests_provider` (FutureProvider.family)
   - `my_notifications_provider` (StreamProvider.family)
4. **Add sub-routes** to `app_routes.dart` + `app_router.dart`:
   - `/officer/task/:taskId`
   - `/officer/proof/:taskId`
   - `/officer/report/:reportId`
   - `/officer/laporan` (full-screen alternative to bottom-nav tab)
5. **Connectivity service** — `core/services/connectivity_service.dart` exposes a `Stream<bool>` backed by `connectivity_plus`.
6. **Hive init** — register `offline_proofs` adapter in `main.dart`; open box on app start.

### M1 — Home (Tugas) + FAB Laporan Darurat

Wires OFC-002, OFC-005 (entry), OFC-012.

1. Build `OfficerHomeScreen` — list of assigned tasks with filter chips (Semua / Belum Dimulai / Sedang Dikerjakan / Mendesak).
2. Task card component reused across Home & History → place in `workspaces/officer_app/widgets/officer_task_card.dart`.
3. FAB → `EmergencyReportDialog` → uses `geolocator` for GPS → creates report with `reporterId = officerUid`.
4. Replace placeholder in `officer_shell_screen.dart` Tugas tab.
5. Tap card → `context.push('/officer/task/:taskId')`.

### M2 — Task Detail + Start/Reject/Complete

Wires OFC-005, OFC-007 (partial), OFC-008.

1. Build `OfficerTaskDetailScreen` with hero image, info block, status-aware action buttons.
2. "Mulai Pengerjaan" → `update({status:"in_progress", startedAt})`.
3. "Tolak Tugas" → reason dialog → `update({status:"in_review", rejectComment})`.
4. "Selesaikan" (tanpa bukti, optional) → `update({status:"resolved", completedAt})`.
5. "Unggah Bukti" → push to M3's `OfficerProofScreen`.

### M3 — Proof Upload (Online)

Wires OFC-006, OFC-007 (final).

1. Build `OfficerProofScreen`:
   - Photo picker (camera + gallery) via `image_picker`.
   - Description field (multi-line).
   - GPS capture from `geolocator`.
   - Compress with `flutter_image_compress`.
   - Base64 → POST to **ImgBB** with build-time API key.
   - Save `proofUrl`, `proofDescription`, `proofLocation` on `/reports/{id}`.
   - Set `status:"resolved"`, `completedAt: serverTimestamp()`.
2. Empty-state guards (no photo → submit disabled).
3. SnackBar success + `pop()` back to Task Detail.

### M4 — Offline Queue + History

Wires OFC-009, OFC-014.

1. Extend `OfficerProofScreen`:
   - On `connectivity_plus` = offline, write payload to Hive `offline_proofs` instead.
   - Banner: "Tersimpan offline — akan dikirim saat online."
2. `ConnectivityService` listener → on reconnect, iterate box → upload to ImgBB → write to Firestore → delete box entry.
3. Build `OfficerHistoryScreen` — list of `resolved` + `rejected` reports, filter chips, search by title.
4. Tap → `OfficerTaskDetailScreen` in **read-only** mode (no action buttons).
5. Replace placeholder in shell Riwayat tab.

### M5 — Laporan Publik + Self-Request

Wires OFC-003, OFC-015.

1. Build `OfficerLaporanScreen` — feed of `pending` + `in_review` reports.
2. Filter chips: `Tersedia` / `Sudah Diajukan` / by category / by urgency.
3. Search bar by title.
4. List item with thumbnail, title, address, status badge, urgency indicator.
5. Tap → push to existing `ReportDetailScreen` (shared or citizen's) — if shared already exists, reuse.
6. CTA "Saya Ingin Menangani Laporan Ini" on detail → `set` on `/reports/{id}/officer/{officerId}` with `status:"requested"`.
7. Disable button when officer already requested this report.
8. Replace placeholder in shell Laporan tab.

### M6 — Notification Deep-Links + Profile Hardening

Wires OFC-010, OFC-011 (cleanup), OFC-013 (deep-links).

1. Extend `OfficerNotificationScreen`:
   - Add per-user stream subscription to `/users/{uid}/notifications`.
   - Wire `onNotificationTap` deep-links per [officer_notification.md §5](./feature/officer_notification.md#5-deep-link-behavior).
   - Unread badge count in shell AppBar.
2. Refactor `OfficerProfileScreen` (workspace copy):
   - Read `currentUserProvider` instead of hard-coded `User1`.
   - Add "Edit Profil" sheet (displayName, phoneNumber, isAvailable toggle).
   - Stat cards: "Tugas Selesai" (count of `resolved`) + "Rating Bintang" (from user doc).
   - Ganti Password tile → reuses `ForgotPasswordScreen` logic.
   - Hapus Akun tile → confirm → soft-delete (set `status:"banned"`) + signOut.
3. Delete legacy `app/lib/features/officer/screens/officer_profile_screen.dart`.
4. Wire logout icon in notification AppBar.

### M7 — Map Tab (defer if scope creeps)

- `OfficerPetaScreen` with `flutter_map` or Google Maps showing assigned task markers.
- Tap marker → same as tapping task card.
- **Decision gate:** if M1–M6 take longer than expected, defer to v2.

---

## 5. Acceptance Test Checklist

Pulled from each spec's "Acceptance Criteria" — used as DoD per milestone.

- [ ] **M1:** Empty task list shows illustration. "Mendesak" filter narrows to `urgencyLevel ∈ {high, critical}`. FAB submits emergency report with GPS coords.
- [ ] **M2:** "Mulai Pengerjaan" sets `status:"in_progress"`. "Tolak" with reason returns to `in_review` + records `rejectComment`.
- [ ] **M3:** Photo + description + submit online → URL saved, `status:"resolved"`. Disabled when no photo.
- [ ] **M4:** Offline submit lands in Hive + banner shows. Reconnect flushes box. History shows resolved + rejected; filter chips work.
- [ ] **M5:** Browse feed; "Saya Ingin Menangani" creates sub-doc; admin approval flows back into M1's active list (handled by admin side, but verify Firestore update triggers UI).
- [ ] **M6:** Profile reads `currentUser`. Edit persists. Logout clears `fcmToken` + signs out. Notification tap deep-links to correct screen.

---

## 6. Risks & Open Questions

| #   | Risk                                                                                                                   | Mitigation                                                                                                                     |
| --- | ---------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| R1  | ImgBB API key not yet configured                                                                                       | Add to `android/app/build.gradle.kts` `buildConfigField` + iOS `Info.plist` plist values; document retrieval in SRS `utility/` |
| R2  | Hive adapter for `offline_proofs` requires code generation                                                             | Generate `*.g.dart` once, commit, and gate behind `build_runner`                                                               |
| R3  | Officer "Self-Request" sub-collection uses different field name in code vs data-model (`status` vs `appliedAt` schema) | Reconcile with admin's [dispatch_workflow.md](../admin/feature/dispatch_workflow.md) before M5                                 |
| R4  | Reusing shared `NotificationScreen` may not support per-user unread badge                                              | Either extend it (preferred — affects all 3 roles) or wrap it                                                                  |
| R5  | Some "✅ Implemented" features per SRS are actually missing from code (Home, History, Task Detail, Proof)              | Don't trust SRS status flags alone — treat each as a build-from-scratch per the milestones above                               |
| R6  | Peta tab scope undefined                                                                                               | Explicit deferral in M7                                                                                                        |
| R7  | Officer login status-gate (OFC-001) — is it currently enforced?                                                        | Verify in `LoginScreen`; if not, add post-login `currentUser.status` check before navigating to `/officer`                     |

---

## 7. Suggested Task DAG (execution order)

```
M0 (foundation, blocking)
 ├── M1 (Home + FAB)         ── uses M0 providers/routes
 │    └── M2 (Task Detail)   ── opens from M1
 │         └── M3 (Proof)    ── opens from M2
 │              └── M4 (Offline + History)
 ├── M5 (Laporan + Self-Request)  ── can start in parallel with M1 (independent data path)
 └── M6 (Notifications + Profile polish) ── last; depends on M1's card deep-links
      └── M7 (Map tab — deferred)
```

---

## 8. Out of Scope (this plan)

- Admin-side dispatch approval changes (see [admin/feature/dispatch_workflow.md](../admin/feature/dispatch_workflow.md)).
- Cloud Functions for FCM — assumed already deployed; if not, add as a sibling task.
- Cloud Function `onUpdate` for status notifications to admin (NOTIF-002).
- Citizen-side changes.
- iOS-specific push notification entitlements (assumed already configured).

---

## 9. Progress Tracker

| Milestone                  | Status         | Notes |
| -------------------------- | -------------- | ----- |
| M0 Foundation              | ⬜ not started |       |
| M1 Home + FAB              | ⬜ not started |       |
| M2 Task Detail             | ⬜ not started |       |
| M3 Proof Upload            | ⬜ not started |       |
| M4 Offline + History       | ⬜ not started |       |
| M5 Laporan + Self-Request  | ⬜ not started |       |
| M6 Notifications + Profile | ⬜ not started |       |
| M7 Map tab                 | ⬜ deferred    |       |
