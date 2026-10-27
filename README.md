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

## Team development guide

Ikuti langkah berikut agar pekerjaan setiap anggota tetap terpisah dan mudah
digabungkan. Ganti contoh nama branch dan folder sesuai feature masing-masing.

### 1. Clone dan siapkan project

Langkah ini hanya perlu dilakukan saat pertama kali menyiapkan project:

```sh
git clone https://github.com/rawhx/stockmate.git
cd stockmate
flutter pub get
git fetch origin
```

Pastikan instalasi Flutter sesuai dengan versi pada bagian [Requirements](#requirements).

### 2. Gunakan branch sesuai pembagian tugas

| Owner | Feature | Branch | Folder kerja utama |
| --- | --- | --- | --- |
| Vincent | Products | `feature/products` | `lib/features/products/` |
| Najwan | Categories | `feature/categories` | `lib/features/categories/` |
| Hasbi | Suppliers | `feature/suppliers` | `lib/features/suppliers/` |
| Zain | Stock transactions | `feature/stock-transactions` | `lib/features/stock_transactions/` |

Contoh untuk anggota yang mengerjakan products:

```sh
git switch feature/products
```

Jika branch belum tersedia di komputer lokal:

```sh
git switch --track origin/feature/products
```

Selalu periksa branch aktif sebelum mulai bekerja:

```sh
git branch --show-current
git status
```

### 3. Ambil perubahan terbaru dari `develop`

Lakukan ini sebelum mulai mengerjakan task baru. Pastikan working tree bersih
atau commit pekerjaan yang masih berjalan terlebih dahulu.

```sh
git fetch origin
git switch feature/products
git merge --ff-only origin/develop
git push origin feature/products
```

Jangan gunakan `git reset --hard`, force-push, atau rebase pada branch bersama.
Jika fast-forward gagal, jangan dipaksa; diskusikan perubahan branch dengan
anggota kelompok atau integration owner.

### 4. Kerjakan hanya feature milik sendiri

Tempatkan kode berdasarkan lapisan Clean Architecture:

- `data/`: data source, model, dan implementasi repository.
- `domain/`: entity, repository interface, dan use case.
- `presentation/`: page, widget, Provider/`ChangeNotifier`, dan route.

Tambahkan route baru melalui file route milik feature, bukan langsung mengubah
`app_router.dart`:

- Products: `product_routes.dart`
- Categories: `category_routes.dart`
- Suppliers: `supplier_routes.dart`
- Stock transactions: `stock_transaction_routes.dart`

Perubahan pada `main.dart`, `app/**`, `core/**`, dependency, atau konfigurasi
project harus dikoordinasikan terlebih dahulu karena file tersebut dipakai
bersama dan lebih mudah menimbulkan merge conflict.

### 5. Format dan periksa perubahan

Jalankan pemeriksaan berikut sebelum commit:

```sh
dart format lib test
flutter analyze
flutter test
git status
git diff
```

Perbaiki error yang berkaitan dengan perubahan sendiri sebelum melakukan push.

### 6. Buat commit yang fokus

Stage hanya file yang memang dikerjakan. Contoh untuk feature products:

```sh
git add lib/features/products
git commit -m "feat(products): add product list UI"
```

Contoh prefix commit yang dapat digunakan:

- `feat`: menambahkan kemampuan baru.
- `fix`: memperbaiki bug.
- `refactor`: merapikan kode tanpa mengubah perilaku.
- `test`: menambah atau memperbaiki test.
- `docs`: mengubah dokumentasi.
- `chore`: perubahan konfigurasi atau maintenance.

Hindari mencampurkan beberapa pekerjaan yang tidak berhubungan dalam satu
commit.

### 7. Push ke feature branch

```sh
git push origin feature/products
```

Jangan push pekerjaan feature langsung ke `develop` atau `main`.

### 8. Buat pull request ke `develop`

Di GitHub, buat pull request dengan konfigurasi:

```text
base: develop
compare: feature/products
```

Isi deskripsi pull request dengan ringkasan perubahan, cara menguji, screenshot
UI jika relevan, dan catatan TODO. Minta minimal satu anggota lain melakukan
review sebelum merge.

Setelah pull request digabungkan, ambil kembali versi terbaru `develop` dengan
langkah pada bagian 3 sebelum memulai task berikutnya.

### 9. Promosikan `develop` ke `main`

Langkah ini dilakukan oleh integration owner ketika versi di `develop` sudah
stabil dan siap dipresentasikan. Buat pull request:

```text
base: main
compare: develop
```

Jalankan kembali `flutter analyze` dan `flutter test` sebelum merge. Alur normal
tetap `feature/* -> develop -> main`; jangan melewati `develop`.

### Menangani merge conflict

Jika terjadi conflict:

1. Jangan menghapus pekerjaan anggota lain atau melakukan force-push.
2. Identifikasi file yang conflict dengan `git status`.
3. Hubungi pemilik feature jika conflict menyentuh folder miliknya.
4. Koordinasikan file bersama dengan integration owner.
5. Setelah diselesaikan, jalankan formatter, analyzer, dan test lagi.

## Requirements

The repository currently requires the constraints recorded by its package
configuration:

- Flutter `>=3.47.0`
- Dart `>=3.13.0 <4.0.0`

Use a Flutter SDK release that satisfies both constraints.

## Setup

Create a local environment file from the committed placeholder:

```sh
cp .env.example .env
```

Replace the placeholder values in `.env` with the project's Supabase URL and
publishable key. The local `.env` file is ignored by Git. Never place a Supabase
secret key or `service_role` key in this Flutter application.

Install dependencies and verify the project:

```sh
flutter pub get
flutter analyze
flutter test
```

Run Android with an available device:

```sh
flutter run --dart-define-from-file=.env
```

Run Web using Chrome:

```sh
flutter run -d chrome --dart-define-from-file=.env
```

The application reads these values at compile time through
`String.fromEnvironment`; `.env` is not loaded directly at runtime.
