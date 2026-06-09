# 4. Class Architecture (Domain-Driven Design)

LaporIn utilizes a strict Domain-Driven Design (DDD) architecture within the Flutter application. This separates the business logic from the user interface and the external database (Firebase).

The architecture is divided into three primary layers: **Domain**, **Data**, and **Presentation**.

## 4.1. Core Architectural Layers

### 1. Domain Layer (The Core)

This is the heart of the application. It contains pure Dart code and has **zero dependencies** on external packages like Firebase or Flutter UI libraries.

- **Entities:** Pure object representations of the system's actors and data (e.g., `UserEntity`, `ReportEntity`).
- **Repository Interfaces:** Abstract classes (contracts) defining what operations can be performed (e.g., `getReports()`), without specifying _how_ they fetch the data.

### 2. Data Layer (The Outside World)

This layer handles communication with Firebase and converts external JSON data into Dart objects.

- **Models:** Extensions of Entities that include data parsing logic (`fromJson`, `toJson`).
- **Repositories (Implementation):** Concrete classes that implement the Domain layer's interfaces. These classes contain the actual `FirebaseFirestore.instance` calls.

### 3. Presentation Layer (The UI)

This layer handles everything the user sees and interacts with.

- **Controllers / ViewModels:** State managers (e.g., Riverpod or Provider) that call the Repository Interfaces to fetch data and update the UI state (Loading, Success, Error).
- **Screens & Widgets:** The visual Flutter components.

---

## 4.2. Class Diagram Overview

```plaintext
+----------------------+     +------------------------------+     +-------------------------------+     +----------------------+
|  Presentation Layer  |     |         Domain Layer         |     |           Data Layer          |     | Infrastructure Layer |
|     (Controllers)    |     |   (Entities & Interfaces)    |     |   (Models & Implementations)  |     |    (External APIs)   |
+----------------------+     +------------------------------+     +-------------------------------+     +----------------------+
| - auth_controller    |---->| - user_entity                |<----| - user_model                  |---->| - FirebaseAuth       |
| - report_controller  |---->| - report_entity              |<----| - report_model                |---->| - FirebaseFirestore  |
| - dispatch_controller|---->| - comment_entity             |<----| - comment_model               |     +----------------------+
|                      |---->| - officer_volunteer entity   |<----| - officer_model               |
|                      |---->| - dispatch_entity            |<----| - dispatch_model              |
|                      |     |                              |     |                               |
|                      |---->| - iauth_repository           |<----| - auth_repository_implement   |
|                      |---->| - ireport_repository         |<----| - report_repository_implement |
|                      |---->| - idispatch_repository       |<----| - dispatch_repository_implement
+----------------------+     +------------------------------+     +-------------------------------+
```

![Class Diagram](./LaporIn_class_diagram.jpg "Class Diagram")

## 4.2. Project Structure(App-Within-An-App Architecture)


To maximize team coordination, prevent version control conflicts, and ensure scalable UI development, LaporIn utilizes an **"App-Within-An-App" (Role-First Presentation)** architecture.

This structure treats the core business logic (Domain) and database interactions (Data) as a shared internal library. Meanwhile, the Presentation layer (UI and State Controllers) is split entirely by user role into isolated workspaces. This allows developers to work on the Citizen UI, Admin UI, and Officer UI simultaneously without ever modifying the same files.

The Flutter `lib/` folder is divided into three main pillars: core utilities, shared backend logic, and the isolated UI applications.

```text
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── routing/
│   │   └── role_router_gate.dart
│   └── utils/
│       ├── geohash_helper.dart
│       └── date_formatter.dart
├── shared_domain_data/
│   ├── auth/
│   │   ├── domain/ 
│   │   │   ├── user_entity.dart
│   │   │   └── iauth_repository.dart
│   │   └── data/   
│   │       ├── user_model.dart
│   │       └── auth_repository_implement.dart
│   ├── report/
│   │   ├── domain/ 
│   │   │   ├── report_entity.dart
│   │   │   ├── comment_entity.dart
│   │   │   └── ireport_repository.dart
│   │   └── data/   
│   │       ├── report_model.dart
│   │       ├── comment_model.dart
│   │       └── report_repository_implement.dart
│   └── dispatch/
│       ├── domain/ 
│       │   ├── dispatch_entity.dart
│       │   ├── officer_volunteer_entity.dart
│       │   └── idispatch_repository.dart
│       └── data/   
│           ├── dispatch_model.dart
│           ├── officer_model.dart
│           └── dispatch_repository_implement.dart
└── workspaces/
    ├── admin_app/
    │   ├── controllers/
    │   │   ├── admin_auth_controller.dart
    │   │   ├── admin_report_controller.dart
    │   │   └── admin_dispatch_controller.dart
    │   ├── screens/
    │   │   ├── admin_dashboard_screen.dart
    │   │   └── admin_assign_officer_screen.dart
    │   └── widgets/
    │       └── admin_data_table_widget.dart
    ├── citizen_app/
    │   ├── controllers/
    │   │   ├── citizen_auth_controller.dart
    │   │   └── citizen_report_controller.dart
    │   ├── screens/
    │   │   ├── citizen_map_feed_screen.dart
    │   │   └── citizen_create_report_screen.dart
    │   └── widgets/
    │       └── citizen_report_card_widget.dart
    └── officer_app/
        ├── controllers/
        │   ├── officer_auth_controller.dart
        │   └── officer_task_controller.dart
        ├── screens/
        │   ├── officer_job_list_screen.dart
        │   └── officer_job_execution_screen.dart
        └── widgets/
            └── officer_swipe_to_complete_widget.dart
```
