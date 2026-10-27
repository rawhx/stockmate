# StockMate

StockMate is a university inventory-management project built for collaborative
development. The application starts with local or dummy data for the UI stage
and will use Supabase for database integration in a later stage.

## Tech stack

- Flutter
- Provider with `ChangeNotifier`
- `go_router`
- Supabase (planned; not integrated yet)

## Supported platforms

- Android
- Web

## Architecture

The project uses a feature-first structure with Clean Architecture boundaries.
Each primary feature is split into `data`, `domain`, and `presentation` layers.

The intended dependency flow is:

```text
Page / Widget
  -> Provider
  -> Use Case
  -> Repository Interface
  -> Repository Implementation
  -> Data Source
  -> Mock Data Source or Supabase
```

The domain layer must not import data or presentation code. UI code accesses
data through providers and use cases, not through Supabase directly.

## Primary feature ownership

| Feature | Owner |
| --- | --- |
| `products` | Vincent |
| `categories` | Najwan |
| `suppliers` | Hasbi |
| `stock_transactions` | Zain |

Developers should primarily change files inside their own feature directory.
Files under `app/`, `core/`, and `main.dart` are integration-owned and should be
changed carefully to minimize merge conflicts.

## Folder structure

```text
lib/
|-- main.dart
|-- app/
|   |-- app.dart
|   |-- providers/
|   |-- router/
|   `-- theme/
|-- core/
|   |-- config/
|   |-- errors/
|   |-- utils/
|   `-- widgets/
`-- features/
    |-- auth/
    |-- dashboard/
    |-- profile/
    |-- products/
    |-- categories/
    |-- suppliers/
    `-- stock_transactions/
```

Each primary feature follows this convention:

```text
features/<feature>/
|-- data/
|   |-- datasources/
|   |-- models/
|   `-- repositories/
|-- domain/
|   |-- entities/
|   |-- repositories/
|   `-- usecases/
`-- presentation/
    |-- pages/
    |-- providers/
    |-- widgets/
    `-- routes/
```

## Git workflow

- `main`: stable branch.
- `develop`: integration branch.
- `feature/*`: individual development branches.

The normal integration flow is:

```text
feature/* -> develop -> main
```

Feature branches should not normally merge directly into `main`. Pull the
latest integration changes from `develop` before opening a feature pull request.

## Requirements

The repository currently requires the constraints recorded by its package
configuration:

- Flutter `>=3.29.0`
- Dart `>=3.12.2 <4.0.0`

Use a Flutter SDK release that satisfies both constraints.

## Setup

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Choose an Android device or a web browser when running the application.
