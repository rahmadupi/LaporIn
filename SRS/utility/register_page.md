# Registration (All Roles: Citizen, Officer, Admin)

## 1. Overview

The Registration module allows new users to create an account. This module supports **three roles**: `citizen`, `officer`, and `admin` — all selectable from the registration form.

> **Demo Note:** Since this is a **demo app**, all three roles (citizen, officer, admin) are available for public registration without restrictions. In a production environment, admin account creation should be restricted to a protected internal process (ADM-001) and officer accounts would go through an approval workflow.

## 2. Traceability

- **FRs Covered:** FR-001 (User Registration), FR-001.3 (Role Assignment)
- **Related:** ADM-001, ADM-014, ADM-026

## 3. UI/UX Requirements

### 3.1 Role Selection

The registration form presents **three role options**:

| Role      | Label            | Behavior                                                                                              |
| --------- | ---------------- | ----------------------------------------------------------------------------------------------------- |
| `citizen` | Warga            | Account immediately active upon registration. No approval needed.                                     |
| `officer` | Petugas Lapangan | Account created with **`status: "pending"`**. Cannot log in until admin approves (status → `active`). |
| `admin`   | Admin            | Account immediately active upon registration. For demo purposes; production would restrict this.      |

### 3.2 Input Fields

- **Full Name** (required)
- **Email Address** (required, unique)
- **Phone Number** (required, stored as `+62` format)
- **Password** (required, min 8 characters)
- **Confirm Password** (required, must match)
- **Role Selector** (required, default: `citizen`)

### 3.3 Role Card UI

Role is selected via a card-based selector (similar to `RoleSelectorCard` component):

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   Warga     │  │   Petugas   │  │   Admin     │
│   👤       │  │   👷       │  │   🏛️       │
│  [Citizen]  │  │  [Officer]  │  │   [Admin]   │
└─────────────┘  └─────────────┘  └─────────────┘
  Active       Needs Approval       Active (Demo)
```

### 3.4 Validation

| Field            | Rule                                          |
| ---------------- | --------------------------------------------- |
| Email            | Must match standard regex                     |
| Password         | Min 8 characters                              |
| Confirm Password | Must match Password                           |
| Phone            | Numeric, 8–15 digits                          |
| Role             | Must be one of: `citizen`, `officer`, `admin` |

### 3.5 Officer Pending State

When a user registers as `officer`:

- Success message: _"Pendaftaran berhasil! Akun Petugas Anda sedang menunggu persetujuan dari Admin."_
- User is **not** redirected to a home screen — they remain on a waiting state or are redirected to login with a message.
- `status: "pending"` is stored in Firestore.
- Admin sees this officer in the **Admin Petugas → Pending Approval** sub-page.

## 4. Database Interactions (Data Layer)

- **Action 1 (Auth):** Call `FirebaseAuth.instance.createUserWithEmailAndPassword()`.
- **Action 2 (Firestore):** Write user profile to `/users/{uid}`.

### Input Payload

```json
{
  "uid": "Auth.uid",
  "fullName": "Input String",
  "email": "Input String",
  "phoneNumber": "+62InputString",
  "role": "citizen | officer | admin",
  "status": "active", // "active" for citizen/admin; "pending" for officer awaiting approval
  "createdAt": "Timestamp",
  "approvedBy": null, // adminUid when an officer is approved (status: pending → active)
  "approvedAt": null // Timestamp when an officer is approved
}
```

### Role-Based Post-Registration Flow

```
Citizen registers
  → Firebase Auth account created
  → Firestore: status: "active"
  → Immediately redirected to Citizen home

Officer registers
  → Firebase Auth account created
  → Firestore: status: "pending"
  → User cannot authenticate until approved
  → Admin approves via Admin Petugas → Persetujuan
  → status: "active", approvedBy: adminUid, approvedAt: Timestamp
  → Officer can now log in

Admin registers (demo)
  → Firebase Auth account created
  → Firestore: status: "active"
  → Immediately redirected to Admin workspace
```

## 5. Acceptance Criteria

### Scenario 1: Citizen Registration

- **Given** a user fills the registration form and selects "Warga".
- **When** they submit.
- **Then** `status: "active"` is set.
- **And** the user is immediately redirected to the Citizen home.

### Scenario 1b: Admin Registration (Demo)

- **Given** a user fills the registration form and selects "Admin".
- **When** they submit.
- **Then** `role: "admin"` and `status: "active"` are set.
- **And** the user is immediately redirected to the Admin workspace.

### Scenario 2: Officer Registration (Pending Approval)

- **Given** a user fills the registration form and selects "Petugas Lapangan".
- **When** they submit.
- **Then** `status: "pending"` is stored in Firestore.
- **And** a success message "Akun Petugas sedang menunggu persetujuan Admin" is shown.
- **And** the user is redirected to Login.

### Scenario 3: Officer Login Before Approval

- **Given** an officer has registered but not yet been approved.
- **When** they attempt to log in.
- **Then** Firebase Auth succeeds but the app detects `status: "pending"`.
- **And** the user is shown: _"Akun Anda belum disetujui Admin. Mohon tunggu persetujuan."_
- **And** the user is not granted access to the officer workspace.

### Scenario 4: Admin Approves Officer

- **Given** an Admin opens Admin Petugas → Pending Approval.
- **When** the Admin clicks "Setujui" on an officer.
- **Then** `status: "active"`, `approvedBy: adminUid`, `approvedAt: Timestamp` are saved.
- **And** the officer can now log in and access the officer workspace.

---

## 6. Register Provider (Riverpod)

```dart
// filepath: app/lib/landing/auth/register/register_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/domain_data/auth/data/auth_repository.dart';
import '../../shared/domain_data/auth/data/user_model.dart';
import '../../shared/domain_data/auth/domain/auth_provider.dart';

enum RegisterStatus { initial, loading, success, error }

class RegisterState {
  final RegisterStatus status;
  final String? errorMessage;
  final bool officerPendingApproval;

  const RegisterState({
    this.status = RegisterStatus.initial,
    this.errorMessage,
    this.officerPendingApproval = false,
  });

  RegisterState copyWith({
    RegisterStatus? status,
    String? errorMessage,
    bool? officerPendingApproval,
  }) {
    return RegisterState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      officerPendingApproval: officerPendingApproval ?? this.officerPendingApproval,
    );
  }
}

class RegisterNotifier extends StateNotifier<RegisterState> {
  final Ref _ref;

  RegisterNotifier(this._ref) : super(const RegisterState());

  Future<bool> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(status: RegisterStatus.loading, errorMessage: null);

    try {
      final auth = _ref.read(firebaseAuthProvider);
      final repository = _ref.read(authRepositoryProvider);

      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      final status = role == 'officer' ? 'pending' : 'active';

      final userEntity = UserEntity(
        uid: uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        role: role,
        status: status,
        createdAt: DateTime.now(),
      );

      await repository.createUser(userEntity);
      await auth.signOut();

      if (role == 'officer') {
        state = state.copyWith(
          status: RegisterStatus.success,
          officerPendingApproval: true,
        );
      } else {
        state = state.copyWith(status: RegisterStatus.success);
      }

      return true;
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'email-already-in-use') {
        message = 'Email sudah terdaftar';
      } else if (e.code == 'weak-password') {
        message = 'Password minimal 8 karakter';
      } else {
        message = 'Terjadi kesalahan. Silakan coba lagi.';
      }
      state = state.copyWith(status: RegisterStatus.error, errorMessage: message);
      return false;
    } catch (e) {
      state = state.copyWith(
        status: RegisterStatus.error,
        errorMessage: 'Terjadi kesalahan. Silakan coba lagi.',
      );
      return false;
    }
  }

  void reset() {
    state = const RegisterState();
  }
}

final registerProvider = StateNotifierProvider<RegisterNotifier, RegisterState>((ref) {
  return RegisterNotifier(ref);
});
```

---

## 7. Register Screen Implementation

```dart
// filepath: app/lib/landing/auth/register/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/ui/widgets/lap_button.dart';
import '../../../shared/ui/widgets/lap_text_field.dart';
import '../../../shared/ui/widgets/lap_card.dart';
import '../../../core/constants/app_colors.dart';
import 'register_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'citizen';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password harus diisi';
    if (value.length < 8) return 'Password minimal 8 karakter';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Konfirmasi password harus diisi';
    if (value != _passwordController.text) return 'Password tidak cocok';
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(registerProvider.notifier).register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: '+62${_phoneController.text.replaceAll(RegExp(r'^0'), '')}',
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (success && mounted) {
      final state = ref.read(registerProvider);
      if (state.officerPendingApproval) {
        _showOfficerPendingDialog();
      } else {
        context.go('/login');
      }
    }
  }

  void _showOfficerPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pendaftaran Berhasil'),
        content: const Text(
          'Akun Petugas Anda sedang menunggu persetujuan dari Admin.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerProvider);

    ref.listen<RegisterState>(registerProvider, (previous, next) {
      if (next.status == RegisterStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.neutral900),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Daftar Akun',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pilih peran Anda di bawah ini',
                  style: TextStyle(fontSize: 14, color: AppColors.neutral600),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        role: 'citizen',
                        label: 'Warga',
                        icon: Icons.person,
                        description: 'Aktif langsung',
                        isSelected: _selectedRole == 'citizen',
                        onTap: () => setState(() => _selectedRole = 'citizen'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        role: 'officer',
                        label: 'Petugas',
                        icon: Icons.engineering,
                        description: 'Butuh persetujuan',
                        isSelected: _selectedRole == 'officer',
                        onTap: () => setState(() => _selectedRole = 'officer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        role: 'admin',
                        label: 'Admin',
                        icon: Icons.admin_panel_settings,
                        description: 'Demo only',
                        isSelected: _selectedRole == 'admin',
                        onTap: () => setState(() => _selectedRole = 'admin'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                LapTextField(
                  controller: _fullNameController,
                  label: 'Nama Lengkap',
                  prefixIcon: Icons.person_outlined,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Nama harus diisi' : null,
                ),
                const SizedBox(height: 16),
                LapTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email harus diisi';
                    if (!value.contains('@')) return 'Email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                LapTextField(
                  controller: _phoneController,
                  label: 'No. Telepon',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  prefixText: '+62 ',
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'No. telepon harus diisi';
                    if (value.length < 8) return 'No. telepon minimal 8 digit';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                LapTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                LapTextField(
                  controller: _confirmPasswordController,
                  label: 'Konfirmasi Password',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 32),
                LapButton(
                  onPressed: registerState.status == RegisterStatus.loading
                      ? null
                      : _handleRegister,
                  isLoading: registerState.status == RegisterStatus.loading,
                  child: const Text('Daftar'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun? '),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Masuk'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String role;
  final String label;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.label,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LapCard(
      onTap: onTap,
      borderColor: isSelected ? AppColors.primary : AppColors.outline,
      borderWidth: isSelected ? 2 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: isSelected ? AppColors.primary : AppColors.neutral600),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 10, color: AppColors.neutral600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
```
