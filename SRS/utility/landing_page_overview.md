SplashScreen# Landing Page & Router Gatekeeper Overview

## 1. Overview
The Landing Page serves as the unified entry point for the LaporIn application. It is not just a UI screen, but the core **Router Gatekeeper**. Its primary responsibility is to intercept the user, verify their authentication status via Firebase, read their specific `role` from Firestore, and strictly route them to their isolated workspace (Citizen App, Admin App, or Officer App).

## 2. Architectural Role (App-Within-An-App)
- **Centralized Auth:** Users from all three roles use the same login interface. 
- **Decentralized Workspaces:** Once authenticated, the router permanently locks the user into their role-specific `lib/workspaces/` directory. An Admin cannot navigate to Citizen screens, and vice versa.

## 3. UI/UX Requirements
- **Splash Screen:** A minimal loading screen displaying the LaporIn logo while the `GoRouter` and Riverpod `StreamProvider` evaluate the current Firebase Auth session.
- **Onboarding (Optional):** A brief carousel explaining the app's purpose for first-time Citizen users.
- **Unified Gateway:** A clean interface with prominent "Login" and "Register" buttons.

## 4. Routing Logic (GoRouter + Riverpod)
- **Unauthenticated State:** If `FirebaseAuth.instance.currentUser` is null, lock navigation to `/login` or `/register`.
- **Authenticated State:** 
  1. Fetch `/users/{uid}` from Firestore.
  2. Read the `role` field.
  3. Execute `context.go('/citizen_dashboard')`, `context.go('/admin_dashboard')`, or `context.go('/officer_dashboard')` based strictly on the role.