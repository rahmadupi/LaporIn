# Password Recovery

## 1. Overview
Allows users who have lost access to their accounts to initiate a secure password reset flow via their registered email address.

## 2. UI/UX Requirements
- **Input Field:** Email Address.
- **Action:** "Send Reset Link" button.
- **Success State:** A visual confirmation (e.g., a green checkmark or dialog) instructing the user to check their inbox, along with a "Back to Login" button.

## 3. Database Interactions (Data Layer)
- **Action (Auth):** Call `FirebaseAuth.instance.sendPasswordResetEmail(email: inputEmail)`.
- **Note:** This action does not touch Firestore.

## 4. Acceptance Criteria
- **Scenario 1: Valid Email Reset**
  - **Given** a user inputs an email address that exists in the Firebase Auth system.
  - **When** they request a reset link.
  - **Then** Firebase triggers a password reset email.
  - **And** the UI shows a success message.
- **Scenario 2: Unregistered Email**
  - **Given** a user inputs an email not registered in the system.
  - **When** they request a reset link.
  - **Then** the UI shows an error stating "No account found with this email." (Or, depending on security preference to prevent email enumeration, displays the standard success message regardless).