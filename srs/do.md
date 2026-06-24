# [EPIC] Fix Maps, Watch Zone Deletion, Runtime Permissions, Report Submission, and Firebase Integration

## Project Context

The LaporIn Flutter application currently has several partially working features:

* Coordinates and addresses can be retrieved, but Google Maps tiles remain blank.
* Watch Zones can be created and edited, but cannot be deleted.
* Watch Zone location selection also displays a blank map.
* The application does not provide a proper first-run permission flow for location, camera, and image access.
* Report photos may appear in the preview but are later rejected as invalid.
* Report submission fails during Firebase Storage upload.
* User-facing error notifications do not accurately represent the real failure.
* Firebase services may not be fully or correctly integrated, and some application paths may still use placeholder, mock, or incomplete implementations.

Work directly in the repository.

Do not stop after producing an analysis. Investigate each issue, modify the code, add or update tests, run verification commands, and report the actual implementation results.

Do not hide failures with mock data, static map images, placeholder success notifications, or hard-coded values.

---

# ISSUE 1 — Google Maps Tiles and Current Location Are Not Displayed

## User Story

As a citizen using LaporIn, I want to see a real interactive map with my current location, streets, markers, and an optional satellite view, so that I can accurately select the location of a report or Watch Zone.

## Current Behavior

* Coordinates and addresses can sometimes be retrieved correctly.
* Google Maps controls or branding may appear.
* The actual map tiles remain blank.
* The application may show an empty beige map area.
* The report location screen may fail to retrieve the current location and display a retry state.
* The Watch Zone location picker can store coordinates, but its map remains blank.
* The main map screen also does not display actual roads or satellite imagery.

Treat these as two separate concerns:

1. **Map rendering and map-tile authorization**
2. **Device-location acquisition and permission handling**

A location failure must not prevent the map itself from rendering.

## Acceptance Criteria

* Real map tiles are displayed on:

  * The main Map screen
  * The report location-selection screen
  * The Watch Zone create/edit location screen
* The map displays streets and geographical features instead of a blank container.
* The user can pan, zoom, and select a location.
* A selected-location marker is displayed correctly.
* The current-location marker or blue dot is displayed after location permission is granted.
* A location button moves the camera to the user’s current location.
* The initial camera uses:

  * The current location when available, or
  * A valid application fallback coordinate when location is unavailable
* The map remains visible when location permission is denied.
* The application distinguishes between:

  * Map loading failure
  * Location service disabled
  * Permission denied
  * Permission permanently denied
  * Location timeout
* Users can retry location acquisition.
* Permanently denied permission provides an action to open application settings.
* Normal map mode works by default.
* Satellite map mode is available through a map-type control if supported by the existing product design.
* Latitude and longitude are stored as numeric values and are not reversed.
* Address information remains synchronized with the selected coordinates.
* No API key, access token, or credential is hard-coded into tracked source files.

## To Do — Engineer

### Map provider configuration

* Identify the map package currently used by the application.
* Inspect all map widgets and shared map utilities.
* Verify that all map screens use the same valid provider configuration.
* Inspect:

  * `AndroidManifest.xml`
  * Gradle configuration
  * `local.properties`
  * Environment-variable loading
  * Application ID
  * Build variants
  * Firebase project configuration
  * Google Maps metadata
* Verify that the Maps API key is actually injected into the final Android manifest.
* Verify the final application package name rather than assuming it.
* Run:

```bash
cd android
./gradlew signingReport
```

* Record the actual:

  * Application ID
  * Debug SHA-1
  * Release SHA-1 when available
* Check whether the key restrictions require those exact values.
* Check whether the following external services must be enabled:

  * Maps SDK for Android
  * Billing for the Google Cloud project
  * Geocoding API only if the code actually calls Google Geocoding
* Do not claim that Geocoding API is required unless the implementation uses it.

### Rendering implementation

* Verify that every map has a finite width and height.
* Check parent constraints, `Expanded`, `Flexible`, `Stack`, and absolute-positioned widgets.
* Remove any remaining `liteModeEnabled` behavior from interactive location pickers.
* Check whether custom map styling hides map features.
* Check whether map type is accidentally set to an unsupported mode.
* Ensure camera initialization occurs only with valid coordinates.
* Ensure the map is not blocked while waiting for GPS.
* Add proper map-created and map-loaded state handling where required.
* Dispose map controllers correctly.
* Avoid rebuilding or recreating the map controller unnecessarily.

### Location implementation

* Audit the location package and permission flow.
* Check:

  * Whether location services are enabled
  * Permission state
  * Accuracy settings
  * Timeout behavior
  * Last-known-location fallback
* Ensure current-location acquisition does not leave the page permanently loading.
* Add a retry path.
* Add an open-settings path for permanently denied permission.
* Preserve manual map selection even when GPS is unavailable.

### Diagnostics

* Inspect Android runtime logs for:

  * Google Maps authorization failure
  * API-key restriction mismatch
  * Package name mismatch
  * SHA-1 mismatch
  * Maps SDK disabled
  * Billing disabled
  * Network failure
* Add development-only logs for map initialization without exposing the API key.
* If an external Google Cloud change is required, still complete all repository-level fixes and report the exact external action required.

## Required Tests

* Test all three map contexts independently.
* Test permission granted.
* Test permission denied.
* Test permission permanently denied.
* Test location services disabled.
* Test location timeout.
* Test initial coordinates and fallback coordinates.
* Test panning and marker updates.
* Test normal and satellite map types.
* Test map rendering after navigating away and returning.

---

# ISSUE 2 — Watch Zone Cannot Be Deleted

## User Story

As a citizen, I want to delete a Watch Zone that I no longer need, so that outdated or incorrect monitoring areas are removed from my account.

## Current Behavior

* Watch Zones can be created.
* Existing Watch Zones can be edited.
* Watch Zone deletion does not work or is not implemented end-to-end.
* The map in the Watch Zone editor remains affected by Issue 1.
* A deleted Watch Zone may remain in the list or home-screen count.

## Acceptance Criteria

* A delete action is available from an appropriate Watch Zone detail, edit, or contextual menu.
* The user must confirm deletion before the operation is executed.
* Canceling the confirmation must leave the Watch Zone unchanged.
* Confirming deletion must execute a real repository/backend operation.
* Success feedback is displayed only after confirmed backend persistence.
* Failure feedback is displayed when deletion fails.
* A failed deletion must not remove the item permanently from the UI.
* A successfully deleted Watch Zone disappears from the list immediately.
* The home-screen Watch Zone count updates after deletion.
* Reopening the application does not restore the deleted Watch Zone.
* The deleted Watch Zone does not continue to contribute to report monitoring.
* Loading, success, and error states are handled separately.
* Repeated taps cannot execute duplicate deletion operations.
* Firestore authorization is restricted to the Watch Zone owner.

## To Do — Engineer

* Locate:

  * Watch Zone model
  * Repository interface
  * Firebase repository implementation
  * Notifier/provider/controller
  * List screen
  * Edit screen
  * Dashboard count provider
* Determine whether the existing architecture expects:

  * Hard deletion, or
  * Soft deletion using `isDeleted`
* Prefer the existing domain convention.

### If soft deletion is used

Update the document using a server timestamp:

```text
isDeleted: true
deletedAt: server timestamp
```

Add `deletedBy` only if the data model already supports audit fields.

Ensure all active Watch Zone queries exclude soft-deleted documents.

### If hard deletion is used

* Delete the exact authenticated user-owned document.
* Ensure dependent data is handled safely.
* Do not delete unrelated reports or users.

### State synchronization

* Ensure the active stream or query updates after deletion.
* If using cached queries, invalidate or refetch the correct query.
* Clear stale errors after successful deletion.
* Ensure subscriptions are not duplicated after retry or navigation.
* Ensure the dashboard count reads from the same reliable data source.
* Add a loading state to prevent duplicate taps.
* Add confirmation UI using existing design conventions.

### Security

Inspect and update Firestore Rules where necessary so:

* Authenticated users can only delete or soft-delete their own Watch Zones.
* Users cannot modify ownership fields.
* Users cannot delete another user’s Watch Zone.

## Required Tests

* Delete an existing Watch Zone successfully.
* Cancel deletion.
* Attempt deletion while offline.
* Attempt deletion without authorization.
* Tap delete repeatedly.
* Verify list count after deletion.
* Verify dashboard count after deletion.
* Restart the app and verify the item remains deleted.
* Verify another user’s Watch Zone cannot be deleted.

---

# ISSUE 3 — Missing Runtime Permission and First-Run Permission Flow

## User Story

As a new user, I want the application to clearly explain and request the permissions required for location, camera, and image selection, so that I understand why each permission is needed and features do not fail silently.

## Current Behavior

* The user can enter the application without a clear permission explanation.
* Location-dependent screens may fail later without a clear permission flow.
* Camera or gallery actions may be attempted without the required permission state being handled properly.
* Permission denial and permanent denial may not be distinguished.

## Acceptance Criteria

* On first relevant use, the application clearly explains why location, camera, or image access is needed.
* Location permission is requested before using current-location functionality.
* Camera permission is requested before opening the camera where required by the platform.
* Gallery/image-selection behavior follows current Android platform rules.
* Android Photo Picker is used where supported without requesting unnecessary broad storage permission.
* The application does not request obsolete or excessive storage permissions.
* On Android 13 or later:

  * Use the system Photo Picker where possible, or
  * Request `READ_MEDIA_IMAGES` only if direct media-library access genuinely requires it
* On older Android versions:

  * Request storage permission only if required by the selected implementation
* Permission denial does not crash the application.
* Permission permanently denied displays an explanation and an open-settings action.
* The user is not repeatedly prompted on every app launch after denying permission.
* Previously granted permissions are not requested again unnecessarily.
* The app remains usable with reduced functionality when optional permissions are denied.
* Manifest permissions match actual runtime requirements.
* Permission handling is testable and centralized rather than duplicated across screens.

## To Do — Engineer

* Audit the permission package and current permission utilities.
* Inspect Android SDK target and minimum SDK versions.
* Inspect:

  * `AndroidManifest.xml`
  * iOS `Info.plist` if the project supports iOS
  * Camera picker
  * Gallery picker
  * Location service
* Create or improve a centralized permission service.
* Implement clear permission states:

  * Not requested
  * Granted
  * Denied
  * Permanently denied
  * Restricted when applicable
* Add an in-app permission explanation before the native OS prompt.
* Request each permission contextually.

Do not request every OS permission immediately at startup without context.

A first-run onboarding screen may explain the permissions, but native permission prompts should be triggered when the user continues or when the corresponding feature is first used.

### Location permission

* Request foreground location access.
* Do not request background location unless a proven product requirement exists.
* Handle disabled GPS separately from denied permission.
* Provide `Open Settings` where necessary.

### Camera permission

* Request camera access before photo capture where the plugin/platform requires it.
* Handle denial and permanent denial.
* Do not block gallery selection when only camera permission is denied.

### Gallery access

* Prefer Android’s system Photo Picker.
* Do not add broad media/storage permissions merely to force a permission popup.
* Confirm that the selected image remains readable after selection.

## Required Tests

* Fresh install with no permission state.
* Location granted.
* Location denied.
* Location permanently denied.
* GPS disabled.
* Camera granted.
* Camera denied.
* Gallery selection through Android Photo Picker.
* Application restart after permission decisions.
* Returning from system settings after granting permission.

---

# ISSUE 4 — Report Photo Becomes Invalid and Submission Fails

## User Story

As a citizen, I want to capture or choose a valid report photo and submit the report successfully, so that the report and its evidence are stored and available to authorized users.

## Current Behavior

* A captured photo may appear as a black preview.
* A gallery photo may display correctly in the final preview but still be rejected as invalid.
* The application displays an inaccurate user-facing message such as:

  * `Foto tidak valid. Ambil atau pilih ulang foto.`
* Submission fails during Firebase Storage upload.
* Runtime logs contain evidence similar to:

```text
StorageException: Object does not exist at location
Code: -13010
HTTP result: 404
The server has terminated the upload session
Firebase code: object-not-found
No AppCheckProvider installed
```

Do not assume this is only a corrupted-photo problem.

A Storage upload returning HTTP 404 during resumable-upload creation may indicate an invalid or nonexistent Firebase Storage bucket, wrong Firebase project configuration, incorrect Firebase app initialization, or an invalid Storage reference.

## Acceptance Criteria

* A newly captured photo displays correctly.
* A gallery-selected photo displays correctly.
* The exact file shown in the final preview is the file submitted.
* A valid readable image is not falsely rejected as invalid.
* The application correctly handles Android file paths and content URIs.
* A valid report can upload its photo to Firebase Storage.
* The uploaded Storage object exists at the expected path.
* A report document is created in Firestore only after the required upload succeeds.
* The Firestore document contains the correct photo URL or storage path.
* If Firestore creation fails after upload, the orphaned uploaded file is removed.
* Duplicate taps do not create duplicate uploads or reports.
* The submit button displays a loading state and becomes temporarily disabled.
* Form data remains available after failure.
* User-facing messages correctly distinguish:

  * Unreadable or invalid image
  * Unsupported image format
  * File too large
  * Authentication failure
  * Firebase Storage misconfiguration
  * Storage authorization failure
  * App Check failure
  * Network failure
  * Timeout
  * Firestore write failure
* The application does not label every Storage error as an invalid photo.
* Debug logs include relevant Firebase error codes without exposing credentials or personal data.

## To Do — Engineer

### Photo pipeline

* Trace the complete photo lifecycle:

  * Camera/gallery selection
  * Returned `XFile` or equivalent
  * File path or URI
  * Form-state storage
  * Preview rendering
  * Validation
  * Upload
* Verify that the preview and uploader use the same canonical photo object.
* Check whether a stale or different path is stored in form state.
* Check whether the selected temporary file is deleted before submission.
* If necessary, copy the selected image into an application-controlled temporary directory.
* Validate:

  * File exists
  * File is readable
  * File length is greater than zero
  * File size is within the allowed limit
  * MIME type is supported
* Do not rely only on the file extension.
* Handle `content://` and `file://` inputs safely.
* Fix camera preview rendering.
* Add an explicit error placeholder rather than a black container.

### Firebase initialization

Audit:

* `google-services.json`
* Generated `firebase_options.dart`
* `Firebase.initializeApp`
* Firebase project ID
* Application ID/package name
* `storageBucket`
* Default Firebase app
* Multiple Firebase app instances
* Firebase Storage instance construction
* Storage reference path
* Firebase Auth user state

Verify that the configured Firebase Storage bucket:

* Exists
* Belongs to the same Firebase project
* Matches the bucket in Firebase options
* Is correctly formatted
* Is actually provisioned in Firebase Console

Do not construct a file reference using an invalid full `gs://` path as a child path.

If a non-default bucket is used, initialize it explicitly using the correct Firebase Storage instance.

### App Check

* Determine whether Firebase App Check enforcement is enabled.
* If App Check is required:

  * Configure the debug provider for debug builds
  * Configure the correct production provider for release builds
* Do not disable App Check globally merely to make development pass.
* Document any Firebase Console registration required.

### Storage and Firestore rules

Inspect and update:

* `storage.rules`
* `firestore.rules`
* Firebase deployment configuration

Ensure:

* Authenticated users can upload only to permitted report paths.
* File size and content type are validated.
* Users cannot overwrite another user’s report image.
* Firestore report creation validates required ownership and fields.

### Error mapping

Correct Firebase Storage error mapping.

Do not map upload-start `object-not-found` HTTP 404 directly to “invalid photo.”

Map it to a configuration or Storage availability failure when the local photo is confirmed valid.

Log in development:

* Firebase error code
* HTTP context where available
* Storage bucket name, but not private credentials
* Target object path
* Whether authentication is available
* Whether App Check is configured

## Required Tests

* Submit using a camera photo.
* Submit using a gallery image.
* Submit a JPG.
* Submit a PNG.
* Submit a zero-byte or unreadable file.
* Submit an oversized image.
* Submit while offline.
* Submit with Firebase Auth expired.
* Submit with Storage Rules denying access.
* Submit with App Check enforcement enabled.
* Verify only one report is created after rapid repeated taps.
* Verify Storage object and Firestore document through Firebase Console or emulator.
* Verify form state is preserved after failure.

---

# ISSUE 5 — Audit and Complete Firebase Integration

## User Story

As the application owner, I want every production feature to use a real, correctly configured Firebase service rather than mock, placeholder, or incomplete implementations, so that authentication, reports, images, Watch Zones, and dashboard data persist reliably.

## Current Behavior

Firebase integration may be incomplete or inconsistent.

Some features appear functional in the UI but may only update local state, display a success notification without confirmed persistence, or use partially configured Firebase services.

## Acceptance Criteria

* Firebase initializes using one consistent project configuration.
* Firebase Auth is connected to the user identity used by Firestore and Storage.
* Reports persist in Firestore.
* Report images persist in Firebase Storage.
* Watch Zones persist in Firestore.
* Watch Zone create, read, update, and delete operations work end-to-end.
* Dashboard counts reflect persisted Firestore data.
* Data remains available after application restart.
* Production execution paths do not use dummy, fake, mock, or placeholder repositories.
* Test-only mocks remain limited to test code.
* Firestore Rules and Storage Rules enforce ownership.
* Required Firestore indexes are documented and version-controlled.
* App Check configuration is either correctly implemented or explicitly documented as not enforced.
* Firebase errors are visible in development logs and accurately translated for users.
* Firebase configuration files do not expose secrets that should remain untracked.
* Required external Firebase Console actions are documented exactly.

## To Do — Engineer

### Integration inventory

Search the repository for:

```text
mock
fake
dummy
placeholder
sample
hardcoded
TODO
FIXME
local-only
in-memory
```

Create an internal integration matrix covering:

| Feature          | Current Data Source | Expected Firebase Service | Status | Required Fix |
| ---------------- | ------------------- | ------------------------- | ------ | ------------ |
| Authentication   |                     | Firebase Auth             |        |              |
| User profile     |                     | Firestore/Auth            |        |              |
| Reports          |                     | Firestore                 |        |              |
| Report photos    |                     | Firebase Storage          |        |              |
| Watch Zones      |                     | Firestore                 |        |              |
| Dashboard counts |                     | Firestore queries         |        |              |
| Notifications    |                     | Existing architecture     |        |              |
| App Check        |                     | Firebase App Check        |        |              |

Do not only produce this matrix. Use it to implement the missing integrations.

### Firebase project consistency

Verify that all of the following refer to the same Firebase project:

* `google-services.json`
* `firebase_options.dart`
* `.firebaserc`
* `firebase.json`
* Firestore Rules
* Storage Rules
* App Check configuration
* Firebase Auth
* Firestore
* Storage bucket
* Android application ID

Detect and fix mismatched project IDs or storage buckets.

### Repository and provider audit

* Check repository interfaces and production bindings.
* Confirm Firebase repositories are selected in production.
* Ensure no demo repository is injected in normal builds.
* Ensure successful UI feedback occurs only after awaited persistence.
* Ensure streams and subscriptions are properly disposed.
* Ensure retry creates one valid subscription rather than duplicates.
* Ensure cached errors are cleared after successful retries.
* Ensure server timestamps and pending writes are handled correctly.

### Data persistence validation

Verify end-to-end:

1. Authenticate a real test user.
2. Create a Watch Zone.
3. Edit the Watch Zone.
4. Delete the Watch Zone.
5. Create a report with a photo.
6. Confirm the Storage object exists.
7. Confirm the Firestore report exists.
8. Restart the application.
9. Confirm persisted data is still correct.
10. Confirm home-screen counts update correctly.

### Firebase configuration files

Review or create where required:

* `firebase.json`
* `.firebaserc`
* `firestore.rules`
* `storage.rules`
* `firestore.indexes.json`
* `.env.example` or documented local configuration

Do not commit private keys or unrestricted credentials.

If Firebase CLI access is available, run safe validation commands.

Do not deploy to a production Firebase project without explicit authorization.

Provide the exact deployment commands required for the owner to run.

---

# Engineering Execution Rules

1. Inspect the existing architecture before editing.
2. Preserve existing visual design and state-management conventions.
3. Implement the issues directly rather than only proposing solutions.
4. Avoid unrelated large-scale refactoring.
5. Do not use mock data as a fallback for failed Firebase requests.
6. Do not display success before backend confirmation.
7. Do not hide runtime exceptions.
8. Do not log API keys, authentication tokens, private image URLs, or personal data.
9. Add focused automated tests for changed business logic.
10. Use development-only diagnostics for external-service failures.
11. Review the final Git diff before finishing.
12. Remove temporary debugging code that is no longer useful.
13. Keep useful structured debug logs behind `kDebugMode`.
14. Do not declare an issue fixed solely because the APK builds.

---

# Required Verification Commands

Run the relevant project commands, including:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Also run:

```bash
cd android
./gradlew signingReport
```

When a connected Android device or emulator is available, run:

```bash
flutter run
flutter logs
```

Verify Firebase and Google Maps behavior through actual runtime logs.

---

# Required Final Report

After implementation, return the result using this format:

## Issue 1 — Maps

* Root cause:
* Files changed:
* Fix implemented:
* Runtime verification:
* Remaining external configuration:

## Issue 2 — Watch Zone Deletion

* Root cause:
* Files changed:
* Fix implemented:
* Runtime verification:

## Issue 3 — Permissions

* Root cause:
* Files changed:
* Fix implemented:
* Runtime verification:

## Issue 4 — Report Submission

* Root cause:
* Files changed:
* Fix implemented:
* Firebase Storage result:
* Firestore result:
* Runtime verification:

## Issue 5 — Firebase Integration Audit

* Real integrations found:
* Mock or placeholder paths found:
* Configuration mismatches found:
* Files changed:
* Remaining Firebase Console actions:

## Tests and Commands

List every command that was executed and its result.

## Remaining Blockers

Only list genuine external blockers such as:

* Google Maps API key restrictions
* Missing SHA-1 registration
* Disabled Maps SDK
* Google Cloud billing
* Firebase Storage not provisioned
* Incorrect Firebase Storage bucket
* Firebase App Check registration
* Undeployed Firestore or Storage Rules

For every blocker, provide the exact required action.

Do not end with recommendations only. Complete every repository-level fix that can be implemented first.
