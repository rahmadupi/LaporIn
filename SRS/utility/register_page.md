# Public Registration (Citizen Only)

## 1. Overview
The Registration module allows new users to create an account. For strict security reasons, this public-facing form hardcodes the user's role to `citizen`. Admin and Officer accounts cannot be created here.

## 2. Traceability
- **Security Constraint:** Public registration strictly provisions `role: "citizen"`.

## 3. UI/UX Requirements
- **Input Fields:** Full Name, Email Address, Phone Number (Optional), Password, Confirm Password.
- **Validation:** 
  - Email must match standard regex.
  - Passwords must match and be at least 8 characters.
- **Error Handling:** Clear UI text for "Email already in use" or "Weak password".

## 4. Database Interactions (Data Layer)
- **Action 1 (Auth):** Call `FirebaseAuth.instance.createUserWithEmailAndPassword()`.
- **Action 2 (Firestore):** Upon successful Auth creation, immediately write the user profile to Firestore.
- **Target Collection:** `/users/{uid}`
- **Input Payload:**
```json
  {
    "uid": "Auth.uid",
    "fullName": "Input String",
    "email": "Input String",
    "phoneNumber": "Input String?",
    "role": "citizen", 
    "isActive": true,
    "createdAt": "Timestamp"
  }