# Category Management (Kategori Laporan)

## 1. Overview
City infrastructure needs change. Admins must be able to dynamically manage the categories of reports (e.g., adding "Fallen Trees" during storm season) without requiring a new Flutter App Store deployment.

## 2. Traceability
- **FRs Covered:** ADM-020, ADM-021 (Subsection Report Controller)

## 3. UI/UX Requirements
- **Settings List:** A standard list view displaying all current categories.
- **Add Category:** A simple dialog to input a new category name.
- **Toggle State:** A switch next to each category to mark it Active or Inactive.

## 4. Database Interactions (Data Layer)
- **Target Collection:** `/settings/global/categories/{categoryId}`
- **Input (Add):** `{ "name": "Pohon Tumbang", "isActive": true, "updatedAt": "Timestamp" }`
- **Input (Disable):** `{ "isActive": false, "updatedAt": "Timestamp" }`
- **Expected Output:** Sub-collection is updated. Citizen App dropdowns automatically react to the change on next load.

## 5. Acceptance Criteria
- **Scenario 1: Soft Deletion of Categories**
  - **Given** an Admin wants to remove the "Jalan Rusak" category.
  - **When** the Admin toggles the category to inactive.
  - **Then** the document is updated to `isActive: false` (not deleted).
  - **And** the Citizen App will no longer show "Jalan Rusak" as an option for new reports, but old reports with this category will not break.