# Dashboard & Analytics (Ringkasan & SLA)

## 1. Overview

The Admin Dashboard provides a high-level operational overview of city infrastructure health. It is composed of **two layers**:

1. **Stat Cards** — top-line counts (4 cards, 2×2 grid).
2. **Priority Alerts ("Perlu Perhatian Anda")** — three-tier attention queue with explicit, predefined thresholds.

Background cron jobs enforce Service Level Agreements (SLA) and feed the priority alerts.

## 2. Traceability

- **FRs Covered:** ADM-016
- **Notification FR:** NOTIF-001 (new report instant alert), NOTIF-003 (SLA > 48 hours).

## 3. UI/UX Requirements

### 3.1 Layout

```
+----------------------------------------------------------+
|  Selamat datang, Admin 👋                               |
|  Berikut ringkasan operasional hari ini                 |
+----------------------------------------------------------+
|  +----------------------+  +----------------------+      |
|  | 📊 Laporan Masuk     |  | 📄 Laporan Diverifi- |      |
|  |       N             |  |       kasi           |      |
|  |       0             |  |       0             |      |
|  +----------------------+  +----------------------+      |
|  +----------------------+  +----------------------+      |
|  | ✏️ Pengguna Aktif    |  | 🛡️ Petugas Aktif    |      |
|  |       N             |  |       N             |      |
|  |       0             |  |       0             |      |
|  +----------------------+  +----------------------+      |
+----------------------------------------------------------+
| ! Perlu Perhatian Anda                                  |
+----------------------------------------------------------+
| 🔴 0 Laporan Kritis            [KRITIS]            >    |
|    Permasalahan sangat besar pada keselamatan publik    |
+----------------------------------------------------------+
| 🟠 0 Laporan Prioritas Tinggi  [TINGGI]            >    |
|    Permasalahan besar pada lingkungan dan keselamatan   |
+----------------------------------------------------------+
| 🟡 0 Laporan Prioritas Sedang  [SEDANG]            >    |
|    Permasalahan sedang pada infrastruktur              |
+----------------------------------------------------------+
| 🟢 0 Laporan Prioritas Rendah  [RENDAH]            >    |
|    Permasalahan ringan                                  |
+----------------------------------------------------------+
```

### 3.2 Stat Cards (Top Section)

| Card                     | Source / Count                                                                  |
| ------------------------ | ------------------------------------------------------------------------------- |
| **Laporan Masuk**        | `count(reports where createdAt within current month)`                           |
| **Laporan Diverifikasi** | `count(reports where status in [in_review, dispatched, in_progress, resolved])` |
| **Pengguna Aktif**       | `count(users where role == "citizen" AND status == "active")`                   |
| **Petugas Aktif**        | `count(users where role == "officer" AND status == "active")`                   |

All counts are computed via Firestore `getCountFromServer()` aggregation — no document downloads.

### 3.3 Priority Alerts ("Perlu Perhatian Anda")

Four **fixed, predefined** severity tiers — one per urgency level in the data model (`critical`, `high`, `medium`, `low`). Each tier has an explicit, deterministic query so admin always sees the same set of reports for the same data.

The row description is a **generic overview of the report category** at that urgency level — **not** a triage reason or instruction.

| Tier   | Badge Color | Indonesian Label         | Description (overview)                             |
| ------ | ----------- | ------------------------ | -------------------------------------------------- |
| KRITIS | 🔴 Red      | Laporan Kritis           | Permasalahan sangat besar pada keselamatan publik  |
| TINGGI | 🟠 Orange   | Laporan Prioritas Tinggi | Permasalahan besar pada lingkungan dan keselamatan |
| SEDANG | 🟡 Yellow   | Laporan Prioritas Sedang | Permasalahan sedang pada infrastruktur             |
| RENDAH | 🟢 Green    | Laporan Prioritas Rendah | Permasalahan ringan                                |

#### 3.3.1 Predefined Scale (Thresholds)

| Tier   | Status        | `urgencyLevel` | Time condition                                                                     |
| ------ | ------------- | -------------- | ---------------------------------------------------------------------------------- |
| KRITIS | `pending`     | `critical`     | `createdAt < now - 1h` (i.e. unverified critical report older than 1 hour)         |
| TINGGI | `in_progress` | `high`         | `dispatchedAt < now - 75% of SLA` (e.g. if SLA = 48h → age > 36h in `in_progress`) |
| SEDANG | `in_review`   | `medium`       | `updatedAt < now - 24h` (i.e. awaiting dispatch for more than 24 hours)            |
| RENDAH | `pending`     | `low`          | `createdAt < now - 24h` (low-urgency report still unverified after 24h)            |

> **SLA baseline:** 48 hours from `createdAt` for `pending` reports (NOTIF-003). 48 hours from `dispatchedAt` for `in_progress` reports. 24 hours in `in_review` before the SEDANG alert fires. 24 hours for `low` urgency before RENDAH alert fires.
>
> These thresholds are **constants** — admins cannot configure them in v1.

#### 3.3.2 Display Rules

- Each row shows the **count** and the **generic overview description** (Section 3.3 table).
- The badge label (`KRITIS`, `TINGGI`, `SEDANG`, `RENDAH`) is fixed text with the tier's color.
- Trailing chevron `>` indicates tap-to-drill.
- **Tap behavior:** navigates to **Moderasi → Laporan** with a pre-applied filter chip matching the tier (see Section 3.3.3).
- **Empty state:** when count is `0`, the row still renders but with `0 Laporan ...` text and no special styling.
- **Render order:** KRITIS → TINGGI → SEDANG → RENDAH (most severe first).

#### 3.3.3 Filter Pre-applied on Drill-In

| Tier   | Lands on Moderasi → Laporan with filter                             |
| ------ | ------------------------------------------------------------------- |
| KRITIS | chip = `Menunggu`, urgency = `critical`, sort = oldest first        |
| TINGGI | chip = `Diproses`, urgency = `high`, sort = oldest SLA breach first |
| SEDANG | chip = `Diproses`, urgency = `medium`, sort = oldest wait first     |
| RENDAH | chip = `Menunggu`, urgency = `low`, sort = oldest first             |

Implementation: `Navigator.push` to Moderasi shell with `initialFilter` argument consumed by `report_moderation.md` Section 3.2.

### 3.4 Other Dashboard Elements (Out of Scope for v1)

- **Minimap Heatmap:** removed in v1 — not part of dashboard layout above. Re-evaluate for v2.
- **SLA Alert Banner:** replaced by the SEDANG tier in the priority alerts list (single source of truth).

## 4. Database Interactions (Data Layer)

### 4.1 Target Collections

- `/reports` (for stat cards + priority alerts)
- `/users` (for Pengguna/Petugas Aktif counts)

### 4.2 Firestore Queries

#### 4.2.1 Stat Cards

```ts
// Laporan Masuk (current month)
firestore
  .collection("reports")
  .where("createdAt", ">=", startOfMonth)
  .count()
  .get();

// Laporan Diverifikasi
firestore
  .collection("reports")
  .where("status", "in", ["in_review", "dispatched", "in_progress", "resolved"])
  .count()
  .get();

// Pengguna Aktif
firestore
  .collection("users")
  .where("role", "==", "citizen")
  .where("status", "==", "active")
  .count()
  .get();

// Petugas Aktif
firestore
  .collection("users")
  .where("role", "==", "officer")
  .where("status", "==", "active")
  .count()
  .get();
```

#### 4.2.2 Priority Alerts

```ts
// KRITIS: pending + critical urgency + older than 1h
firestore
  .collection("reports")
  .where("status", "==", "pending")
  .where("urgencyLevel", "==", "critical")
  .where("createdAt", "<", oneHourAgo)
  .count()
  .get();

// TINGGI: in_progress + high urgency + past 75% of SLA window (default 36h)
firestore
  .collection("reports")
  .where("status", "==", "in_progress")
  .where("urgencyLevel", "==", "high")
  .where("dispatchedAt", "<", slaBreachThreshold) // now - 36h
  .count()
  .get();

// SEDANG: in_review + medium urgency + older than 24h
firestore
  .collection("reports")
  .where("status", "==", "in_review")
  .where("urgencyLevel", "==", "medium")
  .where("updatedAt", "<", twentyFourHoursAgo)
  .count()
  .get();

// RENDAH: pending + low urgency + older than 24h (unverified)
firestore
  .collection("reports")
  .where("status", "==", "pending")
  .where("urgencyLevel", "==", "low")
  .where("createdAt", "<", twentyFourHoursAgo)
  .count()
  .get();
```

### 4.3 SLA Cron Job (NOTIF-003)

Firebase Cloud Scheduler triggers a Cloud Function daily. Function queries `where("status", "==", "pending")` and `where("createdAt", "<", now - 48h)` and pushes FCM to all admin users.

### 4.4 Expected Output

- All counts return efficiently via `getCountFromServer()` — no document downloads.
- Cron job NOTIF-003 fires when a `pending` report exceeds the 48-hour SLA.

## 5. Acceptance Criteria

### Scenario 1: KRITIS count reflects critical pending reports > 1h

- **Given** 3 reports with `status = "pending"`, `urgencyLevel = "critical"`, created 2 hours ago.
- **When** Admin opens the dashboard.
- **Then** the KRITIS row shows `3 Laporan Kritis`.

### Scenario 2: TINGGI count reflects high-urgency in_progress > 75% SLA

- **Given** 5 reports with `status = "in_progress"`, `urgencyLevel = "high"`, dispatched 40 hours ago (SLA = 48h).
- **When** Admin opens the dashboard.
- **Then** the TINGGI row shows `5 Laporan Prioritas Tinggi`.

### Scenario 3: SEDANG count reflects medium-urgency in_review > 24h

- **Given** 2 reports with `status = "in_review"`, `urgencyLevel = "medium"`, last updated 30 hours ago.
- **When** Admin opens the dashboard.
- **Then** the SEDANG row shows `2 Laporan Prioritas Sedang`.

### Scenario 4: RENDAH count reflects low-urgency pending > 24h

- **Given** 4 reports with `status = "pending"`, `urgencyLevel = "low"`, created 30 hours ago.
- **When** Admin opens the dashboard.
- **Then** the RENDAH row shows `4 Laporan Prioritas Rendah` with the description "Permasalahan ringan".

### Scenario 5: Drill-in applies the right filter

- **Given** Admin taps the KRITIS row.
- **When** Moderasi → Laporan opens.
- **Then** the filter chip = `Menunggu`, urgency filter = `critical`, sort = oldest first.

### Scenario 6: 48-Hour SLA Breach notification

- **Given** a report was created exactly 49 hours ago and `status = "pending"`.
- **When** the Cloud Scheduler runs the SLA validation function.
- **Then** an FCM notification is routed to all users with `role == admin`.
- **And** the report contributes to the KRITIS count if `urgencyLevel == "critical"`, otherwise appears in SEDANG (if medium urgency) or simply remains in the `pending` backlog.

### Scenario 7: Stat cards update in real-time

- **Given** Admin is viewing the dashboard.
- **When** a new citizen report is submitted.
- **Then** "Laporan Masuk" count increments within 5 seconds (real-time listener).

### Scenario 8: Row descriptions are generic overviews (not reasons)

- **Given** Admin is viewing the dashboard.
- **When** Admin reads each priority row.
- **Then** every row shows a **generic overview** of what the urgency level represents (e.g. "Permasalahan ringan"), **not** a triage instruction like "Butuh verifikasi".

## 6. Out of Scope (v2+)

- Customizable SLA thresholds per category.
- Historical trend charts (last 7/30 days).
- Officer workload distribution.
- Geographic heatmap.
- Export to CSV / PDF.
