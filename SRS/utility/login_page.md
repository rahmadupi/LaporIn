# User Login & Role Resolution

## 1. Overview
The Login module authenticates existing users. It acts as the gateway that identifies the user and triggers the Riverpod providers to fetch their role, dictating which isolated app workspace they are allowed to enter.

## 2. UI/UX Requirements
- **Input Fields:** Email Address, Password.
- **Actions:** "Login" button, "Forgot Password?" text button, "Don't have an account? Register" text button.
- **Loading State:** The login button must display a progress indicator during the network request to prevent double-tapping.

## 3. Database Interactions (Data Layer)
- **Action 1 (Auth):** Call `FirebaseAuth.instance.signInWithEmailAndPassword()`.
- **Action 2 (Firestore):** Await the read operation from `/users/{uid}` to resolve the user's role before clearing the loading state.

## 4. Acceptance Criteria
- **Scenario 1: Admin Login Routing**
  - **Given** a user inputs credentials for an account where the Firestore document has `role: "admin"`.
  - **When** the login is successful.
  - **Then** `GoRouter` redirects the user to `/admin_dashboard`.
- **Scenario 2: Invalid Credentials**
  - **Given** a user inputs an incorrect password.
  - **When** the login is submitted.
  - **Then** the UI stops loading and displays a "Invalid email or password" error banner.