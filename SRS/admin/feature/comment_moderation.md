# Communication & Moderation (Komentar & Catatan)

## 1. Overview
LaporIn allows two-way communication on reports. Admins must moderate public discussions between citizens to maintain community guidelines. Furthermore, Admins require a private channel (Internal Notes) attached to reports to communicate with other city officials without exposing sensitive operational details to the public.

## 2. Traceability
- **FRs Covered:** ADM-006, ADM-007, ADM-008

## 3. UI/UX Requirements
- **Comment Thread:** Displayed below the Report Detail. Supports sorting (Newest/Oldest).
- **Moderation Tool:** A "Delete" or "Hide" icon next to citizen comments. Requires a confirmation dialog.
- **Input Area:** Text field to add a comment. Includes a toggle switch: `[ ] Send as Internal Note (Admin Only)`.
- **Internal Notes UI:** Notes marked as internal must have a distinct visual background (e.g., light yellow) and a "Lock/Admin-Only" icon to visually separate them from public replies.

## 4. Database Interactions (Data Layer)
- **Target Collection:** `/reports/{reportId}/comments/{commentId}`
- **Input (Add Internal Note):** `{ "authorId": "adminId", "text": "Needs heavy machinery", "isInternal": true, "createdAt": "Timestamp" }`
- **Input (Delete Citizen Comment):** Call `document.delete()` on the specific comment ID.
- **Expected Output:** Comment is written or deleted. Real-time stream automatically updates the UI.

## 5. Acceptance Criteria
- **Scenario 1: Writing an Internal Note**
  - **Given** the Admin writes a comment and toggles "Internal Note".
  - **When** the comment is submitted.
  - **Then** the document is saved with `isInternal: true`.
  - **And** the Citizen App UI must NOT receive this document (enforced via Citizen-side Firestore query `where("isInternal", "==", false)`).
- **Scenario 2: Moderating Comments**
  - **Given** a citizen posts an inappropriate comment.
  - **When** the Admin clicks delete and confirms.
  - **Then** the comment document is permanently removed from the `/comments` sub-collection.