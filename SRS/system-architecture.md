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

## 4.2. Project Structure

Takok gae structure gae per role ui

<!--
```lib/
├── domain/
│   ├── entities/
│   │   ├── user_entity.dart
│   │   └── report_entity.dart
│   └── repositories/
│       ├── user_repository.dart
│       └── report_repository.dart
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   └── report_model.dart
│   └── repositories/
│       ├── user_repository_impl.dart
│       └── report_repository_impl.dart
└── presentation/
    ├── controllers/
    │   ├── user_controller.dart
    │   └── report_controller.dart
    └── screens/
        ├── user_screen.dart
        └── report_screen.dart
```
 -->
