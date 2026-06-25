# Communication & Moderation (Komentar & Catatan) — **REMOVED**

> ## ⚠️ This module has been removed from scope.
>
> The public comment thread, internal admin notes, and citizen-to-admin two-way communication features are **no longer part of the LaporIn product**. This document is kept only as historical reference.
>
> **Removal date:** 2026-06-25
> **Related specs:**
>
> - [`report_detail_page.md`](./report_detail_page.md) — replacement surface for any "context" the admin needs on a report (status roadmap + Penyelesaian photo).
> - [`notification_center.md`](./notification_center.md) — one-way FCM notifications remain the channel for citizen ↔ admin communication.

## 1. Historical Overview

> _(Kept for traceability — do NOT implement.)_
>
> LaporIn previously allowed two-way communication on reports via a comment thread under each report, plus a private "internal note" channel for admins. Admin moderation tools (delete / hide) were provided.

## 2. Historical Traceability

- **FRs Removed:** ADM-006, ADM-007, ADM-008
- **FRs Kept (renumbered):** the notification FRs in [`notification_center.md`](./notification_center.md) cover any user-visible communication.

## 3. Historical UI/UX

> _(Do not build.)_

## 4. Historical Database Interactions

- The `/reports/{reportId}/comments/{commentId}` sub-collection may still contain legacy data but is **read-only by the client** and not surfaced in the UI.

## 5. Replacement

Any feedback the citizen wants to give on a rejected report is now handled via direct contact (out of scope) — there is **no appeal / banding** flow either (see [report_moderation.md](./report_moderation.md) Section 1 note).

Admin may also re-open a `rejected` report via the status dropdown on the Detail page (see [`report_status_management.md`](./report_status_management.md) Section 3.3).
