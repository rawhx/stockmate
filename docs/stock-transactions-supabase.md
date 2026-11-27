# Stock Transactions with Supabase

Fitur Manajemen Transaksi Stok kini telah terintegrasi penuh dengan backend **Supabase**.
Aplikasi menggunakan `StockTransactionRemoteDataSource` secara default saat berjalan dengan konfigurasi Supabase live.
Untuk keperluan testing terisolasi, `StockTransactionMockDataSource` tetap dapat diinjeksi via parameter `AppProviders(stockTransactionRepository: ...)`.

## Database Schema & Relasi

Integrasi ini menggunakan skema PostgreSQL pada Supabase:

- **Tabel `public.stock_transactions`**:
  - `id`: UUID (Primary Key, default `gen_random_uuid()`)
  - `owner_id`: UUID (default `auth.uid()`, references `auth.users(id)`)
  - `product_id`: UUID (foreign key ke `public.products(id)`)
  - `type`: Text (`'IN'` atau `'OUT'`)
  - `quantity`: Integer (`> 0`)
  - `transaction_date`: Timestamp with time zone (default `now()`)
  - `note`: Text nullable
  - `created_at`: Timestamp with time zone (default UTC `now()`)
  - `updated_at`: Timestamp with time zone (default UTC `now()`)
- **Foreign Key Constraint Komposit**:
  `(product_id, owner_id) references public.products(id, owner_id) on delete restrict`
  Constraint ini mencegah penghapusan produk secara sembarangan jika produk tersebut memiliki riwayat transaksi stok.
- **Row Level Security (RLS)**:
  RLS aktif pada tabel `stock_transactions`. User terotentikasi hanya dapat membaca, menambah, mengubah, dan menghapus baris di mana `owner_id = auth.uid()`.

## Sinkronisasi Stok Otomatis

- Pada modul produk, view `product_stock_summary` secara otomatis menghitung `current_stock` dari kalkulasi:
  $$\text{current\_stock} = \sum(\text{IN}) - \sum(\text{OUT})$$
- Ketika transaksi stok dicatat, diubah, atau dihapus melalui `StockTransactionProvider`, callback `onRefreshProducts` secara otomatis memanggil `ProductProvider.fetchProducts()` sehingga tampilan inventaris produk langsung menampilkan stok terkini tanpa perlu reload manual.

## Penanganan Sesi & Pergantian Akun

- `StockTransactionProvider.setOwner(ownerId)` mendeteksi perubahan akun dari `AuthProvider`.
- Saat user logout atau login dengan akun baru, riwayat transaksi akun sebelumnya langsung dibersihkan dan riwayat transaksi milik akun baru dimuat secara otomatis.

## Verifikasi & Testing

Jalankan perintah berikut untuk menguji:

```sh
flutter analyze
flutter test
flutter run -d chrome --dart-define-from-file=.env.dev.json
```
