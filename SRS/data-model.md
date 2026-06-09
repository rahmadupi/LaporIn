# 3. NoSQL Data Model (Firestore Structure)

This document outlines the schema-less document structure for the LaporIn platform. It relies on top-level collections for core entities and sub-collections for isolated, relational data to optimize Firestore read costs.

## 3.1. Collection: `users`

**Path:** `/users/{uid}`
**Description:** Stores user profiles, role-based access levels, and notification tokens. The `uid` matches the Firebase Auth UID.

{
"uid": "user_xyz123",
"fullName": "Bisma Pahlevi",
"email": "bisma@example.com",
"phoneNumber": "+6281234567890",
"role": "admin", // "citizen" | "officer" | "admin"
"fcmToken": "token_abc_123", // Used for Firebase Cloud Messaging (Push Notifications)
"isActive": true, // Set to false if Admin bans the user (ADM-019) only for citzens and officers
"isAvailable": true, // Used only if role == "officer" (ADM-014)
"createdAt": "2026-06-09T03:30:00Z"
}

## 3.2. Collection: `reports`

**Path:** `/reports/{reportId}`
**Description:** The core dataset representing infrastructure issues. Includes Geohashes for rapid map rendering and location queries.

{
"reportId": "rep_987abc",
"reporterId": "user_xyz123",
"isAnonymous": false, // If true, UI hides reporter details, but DB retains ID for notifications
"title": "Lubang Jalan Besar di Sudirman",
"description": "Pothole deep enough to damage tires on the main road.",
"categoryId": "cat_roads", // References settings/categories
"urgencyLevel": "high", // "low" | "medium" | "high" | "critical"
"status": "pending", // "pending" | "in_review" | "dispatched" | "in_progress" | "resolved" | "rejected"
"imageUrl": "https://firebasestorage.googleapis.com/.../pothole.jpg",
"location": {
"latitude": -7.2575,
"longitude": 112.7521,
"geohash": "qw8nm1u" // Required for radius filtering (ADM-009)
},
"addressDetails": {
"province": "Jawa Timur",
"city": "Surabaya",
"district": "Sukolilo"
},
"createdAt": "2026-06-09T03:45:00Z",
"updatedAt": "2026-06-09T03:45:00Z"
}

### 3.2.1. Sub-Collection: `comments`

**Path:** `/reports/{reportId}/comments/{commentId}`
**Description:** Stores discussion threads. Nested inside the report so it can be queried easily when the report detail page is opened.

{
"commentId": "com_111",
"authorId": "user_xyz123",
"authorName": "Bisma Pahlevi", // Duplicated here to save a secondary 'users' read query
"authorRole": "admin",
"text": "Kami akan segera menugaskan tim ke lokasi.",
"createdAt": "2026-06-09T04:00:00Z"
}

### 3.2.2. Sub-Collection: `officer`

**Path:** `/reports/{reportId}/officer/{officerId}`
**Description:** Manages Field Officers applying to take on a specific report.

{
"officerId": "off_456def",
"officerName": "Ahmad Petugas",
"status": "applied", // "applied" | "accepted" | "rejected"
"appliedAt": "2026-06-09T04:10:00Z"
}

## 3.3. Collection: `dispatches`

**Path:** `/dispatches/{dispatchId}`
**Description:** The official record of a job assignment. Kept as a top-level collection so the app can easily query "All active jobs for Officer X".

{
"dispatchId": "disp_777",
"reportId": "rep_987abc",
"officerId": "off_456def",
"assignedBy": "user_xyz123", // The Admin who approved the dispatch
"status": "dispatched", // "dispatched" | "in_progress" | "completed"
"resolutionNotes": "Lubang telah ditambal menggunakan aspal dingin.", // Filled when completed
"resolutionImageUrl": "https://firebasestorage...", // Filled when completed
"assignedAt": "2026-06-09T04:15:00Z",
"completedAt": "2026-06-09T14:00:00Z"
}

## 3.4. Collection: `settings` (Global Configurations)

**Path:** `/settings/categories`
**Description:** A single configuration document to manage dynamic dropdown lists without requiring app updates.

// Document ID: 'categories'
{
"list": [
{
"id": "cat_roads",
"name": "Jalan Rusak",
"isActive": true
},
{
"id": "cat_drainage",
"name": "Saluran Air/Banjir",
"isActive": true
},
{
"id": "cat_lighting",
"name": "Penerangan Jalan",
"isActive": true
}
],
"updatedAt": "2026-06-01T00:00:00Z"
}
