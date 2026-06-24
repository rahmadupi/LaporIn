# Git Workflows — Build, Release, and Deployment

> Dokumen ini adalah **single source of truth** untuk seluruh proses version
> control, integrasi berkelanjutan (CI), rilis, dan deployment aplikasi
> LaporIn. Berlaku untuk semua platform (Android, iOS, Web) dan semua
> workspace (citizen, officer, admin).

## 1. Overview

LaporIn mengadopsi **GitFlow** sebagai branching model (karena kombinasi
multi-platform + multi-workspace + siklus rilis yang terstruktur) dan
**GitHub Actions** sebagai CI/CD engine. Tujuan:

1. Branch `main` selalu dalam kondisi **production-ready** (siap rilis kapan saja).
2. Branch `develop` adalah tempat integrasi harian (latest delivered changes).
3. Setiap perubahan feature harus melalui **Pull Request** dengan review & CI checks.
4. Rilis ke Play Store / App Store / Firebase Hosting dilakukan otomatis lewat
   **tag-based deployment** (push tag → trigger deployment).
5. Perbaikan darurat (**hotfix**) bisa langsung ke `main` tanpa menunggu `develop`.

## 2. Repository & Branching Strategy

### 2.1 Branch Utama

| Branch    | Tujuan                                                              | Protected? | Push langsung?     |
| --------- | ------------------------------------------------------------------- | ---------- | ------------------ |
| `main`    | Source of truth untuk production. Setiap commit di sini siap rilis. | ✅ Ya      | ❌ Tidak (PR only) |
| `develop` | Tempat integrasi fitur harian. Default branch untuk development.    | ✅ Ya      | ❌ Tidak (PR only) |

### 2.2 Branch Pendukung

| Branch pattern            | Branch dari | Merge ke                | Tujuan                                             |
| ------------------------- | ----------- | ----------------------- | -------------------------------------------------- |
| `feature/<id>-<desc>`     | `develop`   | `develop` (PR)          | Pengembangan fitur / task baru.                    |
| `fix/<id>-<desc>`         | `develop`   | `develop` (PR)          | Bug fix non-kritis.                                |
| `release/<version>`       | `develop`   | `main` + `develop` (PR) | Persiapan rilis (version bump, changelog, freeze). |
| `hotfix/<version>-<desc>` | `main`      | `main` + `develop` (PR) | Perbaikan kritis di production.                    |
| `chore/<desc>`            | `develop`   | `develop` (PR)          | Tugas teknis (deps, refactor, tooling).            |
| `docs/<desc>`             | `develop`   | `develop` (PR)          | Perubahan dokumentasi (termasuk SRS).              |

Contoh:

```
feature/ADM-019-user-moderation
fix/citizen-218-report-list-crash
release/1.2.0
hotfix/1.2.1-fcm-token-rotation
chore/bump-firebase-bom
docs/add-git-workflows-srs
```

### 2.3 Aturan Branch

- **Tidak boleh commit langsung ke `main` atau `develop`.** Semua perubahan via PR.
- **1 fitur = 1 branch.** Jangan mix multiple unrelated changes dalam satu branch.
- **Branch harus up-to-date dengan base** sebelum merge (`Rebase` atau `Merge main`).
- **Squash merge** untuk `feature/*`, `fix/*`, `chore/*`, `docs/*` ke `develop`.
- **Merge commit** untuk `release/*` dan `hotfix/*` ke `main` (preserve history).
- **Hapus branch** setelah di-merge (kecuali `release/*`/`hotfix/*` yang bisa diarsipkan).

## 3. Commit Message Convention (Conventional Commits)

Setiap commit message mengikuti [Conventional Commits](https://www.conventionalcommits.org/)
untuk auto-generate changelog dan semantic versioning.

```
<type>(<scope>): <short summary>

<body - optional>

<footer - optional>
```

| Type       | Untuk                                    | Contoh                                                |
| ---------- | ---------------------------------------- | ----------------------------------------------------- |
| `feat`     | Fitur baru                               | `feat(citizen): add appeal flow for rejected report`  |
| `fix`      | Bug fix                                  | `fix(auth): prevent banned account recovery override` |
| `refactor` | Refactor tanpa perubahan behavior        | `refactor(report): extract status mapping helper`     |
| `perf`     | Performa                                 | `perf(map): cache geohash decode result`              |
| `test`     | Tambah/ubah test                         | `test(auth): add banned-login integration test`       |
| `docs`     | Dokumentasi                              | `docs(srs): add git workflows spec`                   |
| `chore`    | Tooling, deps, config                    | `chore(deps): bump firebase_auth to 5.7.0`            |
| `style`    | Formatting, whitespace (no logic change) | `style: format with dart format`                      |
| `ci`       | Perubahan CI/CD                          | `ci: add ios release workflow`                        |
| `revert`   | Revert commit sebelumnya                 | `revert: feat(citizen): appeal flow`                  |

**Scope** merujuk ke workspace / layer / modul: `citizen`, `officer`, `admin`,
`auth`, `report`, `dispatch`, `comment`, `srs`, `ci`, `deps`, dll.

## 4. Versioning (Semantic Versioning)

Format: `MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]`

- `MAJOR` — breaking change atau rewrite besar (e.g. migrasi Flutter 3 → 4).
- `MINOR` — fitur baru yang backward-compatible.
- `PATCH` — bug fix / hotfix yang backward-compatible.
- `PRERELEASE` — optional, mis. `1.3.0-beta.1` untuk internal testing.
- `BUILD` — auto-incremented (mirroring `versionCode` Android & `CFBundleVersion` iOS).

Contoh:

- `1.0.0+1` — rilis pertama, build 1.
- `1.1.0+5` — minor release ke-1 (fitur baru), build 5.
- `1.1.1+6` — patch untuk 1.1.0, build 6.
- `2.0.0+10` — major release (breaking), build 10.

Sumber kebenaran version ada di [pubspec.yaml](../../app/pubspec.yaml)
(`version: x.y.z+build`).

## 5. Environment & Firebase Projects

LaporIn menggunakan **3 environment** dengan Firebase project terpisah
supaya data staging tidak bocor ke production dan sebaliknya.

| Environment    | Branch pemicu                                             | Firebase Project ID             | Distribution                                                             | Audience          |
| -------------- | --------------------------------------------------------- | ------------------------------- | ------------------------------------------------------------------------ | ----------------- |
| **dev**        | push ke `develop`                                         | `laporin-dev` (akan dibuat)     | Firebase App Distribution + Hosting preview channel                      | Internal dev team |
| **staging**    | push ke `main` (pre-release tag `*-rc*`) atau `release/*` | `laporin-staging` (akan dibuat) | Firebase App Distribution (tester group) + Play Store **internal** track | QA + beta testers |
| **production** | push tag `vX.Y.Z` (tanpa prerelease)                      | `laporin-d3376` (saat ini)      | Play Store **production**, App Store **release**, Firebase Hosting live  | End users         |

> **Catatan keamanan:** `firebase_options.dart` **tidak boleh** di-commit
> untuk project production ke public repo. Gunakan **Firebase CLI + Secret
> Manager** di CI untuk generate `firebase_options.dart` per environment.

## 6. CI Pipeline (Pull Request)

Tiap Pull Request ke `develop` atau `main` menjalankan workflow
`ci.yml` di GitHub Actions. PR hanya bisa di-merge jika **semua check
lulus** (branch protection rules).

### 6.1 Checks yang Dijalankan

| Step             | Perintah                                     | Kegagalan = block merge? |
| ---------------- | -------------------------------------------- | ------------------------ |
| Checkout         | `actions/checkout@v4`                        | n/a                      |
| Setup Flutter    | `subosito/flutter-action@v2`                 | n/a                      |
| Cache pub        | `actions/cache@v4`                           | n/a                      |
| Install deps     | `flutter pub get`                            | ✅ Ya                    |
| Format check     | `dart format --set-exit-if-changed lib test` | ✅ Ya                    |
| Analyze (lint)   | `flutter analyze`                            | ✅ Ya (errors only)      |
| Unit tests       | `flutter test --coverage`                    | ✅ Ya                    |
| Build (smoke)    | `flutter build apk --debug`                  | ⚠️ Best-effort           |
| Upload coverage  | `codecov/codecov-action@v4`                  | n/a                      |
| Comment coverage | (auto-comment di PR)                         | n/a                      |

### 6.2 Lintas-Platform Check

Untuk PR yang menyentuh shared code, semua platform di-build:

- `flutter build apk --debug` (Android)
- `flutter build ios --no-codesign --debug` (iOS, macOS runner only)
- `flutter build web` (Web)

Untuk PR yang hanya menyentuh satu workspace UI (mis. hanya `lib/workspaces/citizen_app/**`),
maka cukup build platform yang relevan saja (matrix strategy GitHub Actions).

## 7. CD / Release Pipeline (Tag-based Deployment)

### 7.1 Cara Trigger

```
git tag -a v1.2.0 -m "Release 1.2.0 — appeal flow & dormant accounts"
git push origin v1.2.0
```

Atau lewat GitHub UI: **Releases → Draft a new release → Choose a tag → Publish**.

Tag **harus** match dengan `version` di `pubspec.yaml` (CI akan validasi).

### 7.2 Workflow `release.yml`

Setelah tag dipush, GitHub Actions menjalankan:

1. **Validate tag** ↔ `pubspec.yaml` version (gagal jika mismatch).
2. **Generate release notes** dari conventional commits sejak tag sebelumnya
   (via `action-github-release-action` atau custom script).
3. **Build per platform** dengan signing config:
   - **Android:** `flutter build appbundle --release` → upload ke Play Store
     via `r0adkll/upload-google-play@v1` (track: `internal`/`production` sesuai tag).
   - **iOS:** `flutter build ipa --release` → upload ke App Store Connect via
     `apple-actions/upload-testflight-notes@v1` + `fastlane pilot upload`.
   - **Web:** `flutter build web --release` → deploy ke Firebase Hosting
     (channel `live`) via `FirebaseExtended/action-hosting-deploy@v0`.
4. **Inject Firebase config** untuk environment yang sesuai
   (gunakan env var `FIREBASE_PROJECT_ID` + `firebase_options.dart` template).
5. **Sign artifacts** dengan secrets dari GitHub Secrets / OIDC ke Google Play.
6. **Create GitHub Release** dengan changelog otomatis.
7. **Notify** ke Slack/Discord channel `#laporin-releases` via webhook.

### 7.3 Bagan Alur Deployment

```
[Developer] --PR--> [develop]
   |                     |
   |  (merge)            v
   |               [CI: lint, test, build]
   |                     |
   |                     v
   |               [auto-deploy to Firebase App Distribution (dev)]
   |
   v
[Release Manager] --branch release/1.2.0--> [develop]
                              |
                              v
                  [CI on release/*: full test + smoke deploy to staging]
                              |
                              v
                  [QA validation on staging env]
                              |
                  (bug found)  |  (QA pass)
                      |        |
          hotfix/X.Y.Z |        v
                      |   [tag v1.2.0]
                      |        |
                      v        v
                  [merge back to develop + main]
                              |
                              v
                  [CI: build signed artifacts per platform]
                              |
                              v
                  [Deploy: Play Store, App Store, Firebase Hosting]
                              |
                              v
                  [Create GitHub Release + notify Slack]
```

## 8. Hotfix Workflow (Patch Darurat)

Untuk bug kritis di production yang tidak bisa menunggu rilis berikutnya:

1. **Branch dari `main`**, bukan dari `develop`:
   ```
   git checkout main
   git checkout -b hotfix/1.2.1-fix-fcm-token-rotation
   ```
2. Commit fix + bump version di `pubspec.yaml` (`1.2.0+5` → `1.2.1+6`).
3. Push branch → buka PR ke `main` **dan** ke `develop` (dua PR, atau satu PR
   dengan base `main` lalu cherry-pick ke `develop`).
4. Setelah merge ke `main`, push tag `v1.2.1` → CD workflow rilis otomatis.
5. Merge perubahan hotfix kembali ke `develop` agar tidak hilang di rilis
   berikutnya.

## 9. Secrets & Credentials Management

| Secret                             | Disimpan di                  | Dipakai oleh                    |
| ---------------------------------- | ---------------------------- | ------------------------------- |
| `ANDROID_KEYSTORE`                 | GitHub Secrets (base64)      | `release.yml` (signing APK/AAB) |
| `ANDROID_KEYSTORE_PASSWORD`        | GitHub Secrets               | `release.yml`                   |
| `ANDROID_KEY_ALIAS`                | GitHub Secrets               | `release.yml`                   |
| `ANDROID_KEY_PASSWORD`             | GitHub Secrets               | `release.yml`                   |
| `IOS_DISTRIBUTION_CERT`            | GitHub Secrets (base64, p12) | `release.yml`                   |
| `IOS_PROVISIONING_PROFILE`         | GitHub Secrets (base64)      | `release.yml`                   |
| `IOS_APP_STORE_CONNECT_API_KEY`    | GitHub Secrets               | `release.yml`                   |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | GitHub Secrets               | `release.yml` (Play upload)     |
| `FIREBASE_TOKEN`                   | GitHub Secrets               | `release.yml` (Hosting deploy)  |
| `FIREBASE_APP_ID_*` (per env)      | GitHub Secrets               | `release.yml` (env selection)   |
| `SLACK_WEBHOOK_URL`                | GitHub Secrets               | `release.yml` (notify)          |
| `CODECOV_TOKEN`                    | GitHub Secrets               | `ci.yml` (coverage)             |

> ⚠️ **Tidak boleh** commit `google-services.json`, `GoogleService-Info.plist`,
> `firebase_options.dart`, `key.properties`, atau keystore ke repo.
> Semua disuplai via secret injection di CI.

## 10. Branch Protection Rules

Aktifkan di Settings → Branches → Branch protection rules.

### `main`

- ✅ Require pull request before merging
- ✅ Require approvals: **2** (untuk non-owner; owner boleh 1)
- ✅ Require status checks to pass before merging
- ✅ Require conversation resolution before merging
- ✅ Require linear history (no merge commits dari feature branches)
- ✅ Include administrators (rules berlaku untuk admin repo juga)
- ✅ Do not allow force pushes
- ✅ Do not allow branch deletion

### `develop`

- ✅ Require pull request before merging
- ✅ Require approvals: **1**
- ✅ Require status checks to pass before merging
- ✅ Allow force pushes: ❌
- ✅ Do not allow branch deletion

## 11. Code Review Checklist (PR Template)

Setiap PR harus memenuhi checklist berikut sebelum bisa merge:

- [ ] Title PR mengikuti conventional commit format (`feat(scope): ...`).
- [ ] Deskripsi PR menjelaskan **apa** yang berubah dan **mengapa**.
- [ ] Ada linked issue / ticket ID (e.g. `Closes ADM-019`).
- [ ] Ada screenshot / screen recording untuk perubahan UI.
- [ ] Ada unit test untuk logic baru / diubah.
- [ ] Ada update ke SRS jika ada perubahan behavior / data model.
- [ ] Tidak ada file sensitif yang di-commit
      (`*.jks`, `*.p12`, `key.properties`, `firebase_options.dart`,
      `google-services.json`, `GoogleService-Info.plist`).
- [ ] CI checks lulus (lint, format, test, build).
- [ ] Tidak ada penurunan coverage (>2% drop ⇒ butuh justifikasi).

## 12. Tag & Release Conventions

- Tag format: `vX.Y.Z` atau `vX.Y.Z-rc.N` (release candidate).
- Tag di-push **setelah** PR ke `main` di-merge (tidak langsung dari `develop`).
- GitHub Release dibuat otomatis oleh `release.yml` dengan changelog dari
  conventional commits.
- Tag **tidak boleh dihapus** setelah di-push (signed / annotated tag).
- Hotfix tag (e.g. `v1.2.1`) boleh di-push langsung dari merge commit hotfix.

## 13. File & Folder Ignore Policy

Selain `.gitignore` standard Flutter, tambahkan:

```gitignore
# Secrets & local config
**/key.properties
**/*.jks
**/*.p12
**/google-services.json
**/GoogleService-Info.plist
**/firebase_options.dart

# Build artifacts
**/build/
**/.dart_tool/
**/.flutter-plugins
**/.flutter-plugins-dependencies
**/coverage/
**/Pods/

# IDE
.idea/
.vscode/
*.iml
```

> **Pengecualian untuk repo ini:** `google-services.json` dan `firebase_options.dart`
> untuk environment **production** saat ini masih di-commit karena repo
> masih private. **Sebelum go public**, pindahkan semua ke secret injection.

## 14. Web Deployment Khusus (Firebase Hosting)

Untuk `flutter build web --release` yang di-deploy ke Firebase Hosting:

- **Channel `live`** ← tag `vX.Y.Z` (production).
- **Channel preview** ← setiap push ke `develop` (auto-generated URL,
  expired dalam 7 hari).
- **Channel staging** ← branch `release/*` (untuk QA).
- Konfigurasi di `firebase.json` section `hosting`:
  ```json
  {
    "hosting": {
      "public": "build/web",
      "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
      "rewrites": [{ "source": "**", "destination": "/index.html" }],
      "headers": [
        {
          "source": "/assets/**",
          "headers": [
            {
              "key": "Cache-Control",
              "value": "public, max-age=31536000, immutable"
            }
          ]
        }
      ]
    }
  }
  ```

## 15. Disaster Recovery

| Situasi                                       | Tindakan                                                                          |
| --------------------------------------------- | --------------------------------------------------------------------------------- |
| Tag di-push tapi CD gagal                     | Re-run workflow dari Actions tab. Jangan push tag duplikat.                       |
| Build sukses tapi Play Store reject           | Fix issue → re-tag dengan suffix `-rc.N+1` → push tag baru.                       |
| Hotfix merge ke `main` tapi lupa ke `develop` | Cherry-pick commit ke `develop`, atau merge `main` ke `develop`.                  |
| Secrets bocor                                 | Rotate **immediately**, audit last 90 days, invalidate active sessions.           |
| Production crash karena deploy buruk          | Rollback via Play Store (hanya untuk staged rollout < 100%) atau push hotfix tag. |

## 16. Acceptance Criteria Workflow

- **AC-WF-01:** Branch `main` selalu buildable dan deployable tanpa intervensi manual.
- **AC-WF-02:** Tiap PR ke `develop`/`main` menjalankan CI minimal: format, analyze, test, build debug.
- **AC-WF-03:** Push tag `vX.Y.Z` men-trigger deployment otomatis ke semua platform.
- **AC-WF-04:** Hotfix bisa rilis dalam < 1 jam dari insiden detected.
- **AC-WF-05:** Tidak ada secret / credential yang ter-commit di git history.
- **AC-WF-06:** Coverage test tidak turun > 2% antar-PR (kecuali di-justifikasi).
- **AC-WF-07:** Changelog tiap release di-generate otomatis dari conventional commits.
- **AC-WF-08:** Deploy ke production selalu lewat tag (tidak push langsung ke main).
