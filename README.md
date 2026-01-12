# Offline-First Contractor Job App

A native iOS application for managing contractor jobs with offline-first support, automatic background synchronization, and reliable local data persistence. This project was built as part of a machine test to demonstrate handling of real-world mobile challenges such as network instability, partial failures, and app lifecycle interruptions.

---

## Table of Contents

1. App Architecture
2. Local Storage Strategy
3. Sync Strategy
4. Offline & Network Handling
5. Failure & Retry Handling
6. Known Limitations
7. Production Improvements
8. Setup Instructions

---

## 1. App Architecture

### Architecture Pattern: MVC with Service-Based Separation

The app follows a lightweight **MVC (Model–View–Controller)** architecture enhanced with a **service-based separation**. While UIKit ViewControllers manage UI and navigation, core responsibilities such as networking, persistence, and synchronization are delegated to dedicated service classes.

This approach keeps the implementation simple while still supporting offline-first behavior and clear separation of concerns within the scope of the assignment.

### Core Components

**Models**

* `Job`, `Note`, `User`
* Codable structs representing domain entities
* Contain identifiers and sync-related metadata

**ViewControllers**

* Handle user interaction and UI rendering
* Display locally stored data immediately
* Trigger background sync via services

**Services**

* `APIService`: Centralized HTTP networking layer
* `LocalStorageManager`: Handles local persistence
* `SyncManager`: Orchestrates sync for jobs, notes, and videos
* `NetworkManager`: Monitors network connectivity

This structure ensures the UI remains responsive even when offline, while sync logic remains centralized and reusable.

---

## 2. Local Storage Strategy

### Storage Mechanism

Local persistence is implemented using **UserDefaults with JSON encoding**, chosen for simplicity and fast iteration given the limited dataset size and time constraints of the assignment.

* **Jobs**: Stored as a JSON array under a single key
* **Notes**: Stored independently from jobs
* **Videos**: Stored as files in the app’s Documents directory
* **Metadata**: File paths and sync state stored in UserDefaults

> Note: This approach is suitable for small datasets and prototyping. It is not recommended for large-scale production apps and is listed as a known limitation.

### Dual Identifier System

Each entity maintains two identifiers:

* **localId (UUID)**

  * Generated immediately when data is created
  * Always available, even when offline
  * Used for local lookup and persistence

* **serverId (id)**

  * Assigned by the backend after successful sync
  * Used to determine create vs update operations

This dual-ID system allows offline-created data to be safely reconciled with server responses.

### Persistence Across App Restarts

* All data is written to disk immediately
* Pending sync state is preserved
* On app relaunch, data is loaded before any network call
* Sync resumes automatically when the app enters foreground and network is available

---

## 3. Sync Strategy

Synchronization is fully automatic. There is **no manual sync button**, as required.

### Job Sync Flow

**Create Job**

1. Job created locally with `localId`
2. Marked as `pending`
3. Saved immediately to local storage
4. Synced automatically when online

**Edit Job**

* If `serverId` exists → update API is used
* If `serverId` is missing → create API is used
* Local data is always updated first

**Retry Behavior**

* Failed jobs are marked as `failed`
* Retried automatically on network availability or app foreground

### Notes Sync (Independent State)

* Each note maintains its own `syncStatus`
* Notes are synced only after the parent job has a valid `serverId`
* Failure of one note does not block others

This dependency exists because notes cannot be created on the server without an associated job.

### Video Upload Flow (Optional Feature)

* Video can be selected while offline
* File is copied to the Documents directory
* Upload is attempted when network is available
* Upload failures do not block job or note sync
* Pending videos survive app restarts

Video uploads are retried automatically without user intervention.

---

## 4. Offline & Network Handling

### Offline → Online

* Network changes detected using `NWPathMonitor`
* SyncManager automatically triggers sync when connectivity is restored
* Jobs → Notes → Videos are synced sequentially

### Online → Offline

* App continues to function fully
* All new or edited data is saved locally
* Items are marked as pending for later sync

### App Termination During Sync

* All changes are persisted immediately
* On relaunch, pending items remain intact
* Sync resumes automatically

Data loss is avoided in all supported scenarios.

---

## 5. Failure & Retry Handling

### API Failures

* Network and server errors are captured per request
* Failures are non-blocking
* Each item tracks its own sync state

### Retry Strategy

* Triggered when:

  * Network becomes available
  * App enters foreground
* No exponential backoff or retry limits
* Failed items remain retryable indefinitely

### Authentication Failures (401)

* Token is attached to all authenticated requests
* On `401 Unauthorized`:

  * Token is cleared
  * User is redirected to login
  * Pending local data is preserved

No token refresh mechanism is implemented.

---

## 6. Known Limitations

* MVC architecture without ViewModels
* UserDefaults used instead of Core Data
* Sequential sync (no parallel execution)
* No background sync when app is terminated
* No conflict resolution (last-write-wins)
* Uploaded videos are not deleted automatically
* No sync progress indicators
* Tokens stored in UserDefaults instead of Keychain
* No automated tests

These limitations were accepted to prioritize correctness and clarity within the assignment timeline.

---

## 7. Production Improvements

If this app were to be taken to production, the following improvements would be prioritized:

* Replace UserDefaults with Core Data
* Move auth token storage to Keychain
* Implement MVVM with ViewModels
* Add background sync using BGTaskScheduler
* Add exponential backoff and retry limits
* Implement conflict resolution
* Add unit, integration, and UI tests
* Improve error messaging and logging
* Clean up uploaded video files

---

## 8. Setup Instructions

### Requirements

* Xcode 13 or later
* iOS 13+
* Swift 5+
* CocoaPods

### Installation

1. Clone the repository
2. Run `pod install`
3. Open the `.xcworkspace` file
4. Build and run on simulator or device

### Offline Testing

1. Enable Airplane Mode
2. Create or edit jobs, notes, or videos
3. Disable Airplane Mode
4. Observe automatic synchronization

---

## API Usage

All APIs are consumed from the provided backend:

* Authentication
* Job creation and updates
* Notes management
* Video upload

All authenticated requests include:

`Authorization: Bearer <token>`

---

## Author

Anmol Kumar
iOS Developer

---

This project was built specifically to demonstrate offline-first design, sync reliability, and thoughtful handling of real-world mobile edge cases.
