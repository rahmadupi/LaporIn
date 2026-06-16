# Authentication & Session Management

## 1. Overview
This module governs how the user's active session is maintained securely across app restarts. It leverages Firebase Authentication's native token management and Riverpod to provide a reactive state that the router listens to.

## 2. State Management Strategy (Riverpod)
- **`authStateProvider`:** A `StreamProvider` listening to `FirebaseAuth.instance.authStateChanges()`.
- **`currentUserProvider`:** An `AsyncNotifier` that reacts to the `authStateProvider`. If a user is logged in, it fetches their full `UserEntity` (including their role) from the `/users` Firestore collection and holds it in memory.

## 3. Security Rules
- **Token Refresh:** Handled automatically by the Firebase Auth SDK. No custom token rotation logic is required in the Flutter client.
- **Account Deactivation:** If an Admin sets a user's `isActive` flag to `false` in Firestore, a Cloud Function must revoke their refresh tokens. The `authStateChanges()` stream will detect this and immediately push the user back to the `/login` route.

## 4. Acceptance Criteria
- **Scenario 1: App Restart persistence**
  - **Given** a user is logged into the app.
  - **When** the user force-closes the app and reopens it.
  - **Then** the app bypasses the login screen and routes them directly to their role workspace without requiring credentials again.
- **Scenario 2: Forced Logout (Banned User)**
  - **Given** an active Citizen user has their account disabled by an Admin.
  - **When** the backend token revocation triggers.
  - **Then** Riverpod detects the null session and `GoRouter` instantly redirects the user to the Login screen.