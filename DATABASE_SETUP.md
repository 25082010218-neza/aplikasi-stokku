# Integrasi Flutter, Dart API, dan MySQL

Arsitektur yang digunakan:

`Flutter / React → REST API Dart → MySQL`

Aplikasi klien tidak terhubung langsung ke MySQL agar kata sandi database tidak
tertanam di aplikasi dan validasi stok dapat dijalankan dalam transaksi server.

## 1. Siapkan MySQL

```bash
mysql -u root -p < dart_api/schema.sql
```

Buat pengguna database dengan hak akses hanya untuk database `stokku`, lalu isi
environment variable berdasarkan `dart_api/.env.example`.

## 2. Jalankan API Dart

```bash
cd dart_api
dart pub get
DB_HOST=127.0.0.1 \
DB_PORT=3306 \
DB_NAME=stokku \
DB_USER=stokku \
DB_PASSWORD=password_anda \
dart run bin/server.dart
```

Tes koneksi melalui `GET http://localhost:8080/api/health`.

Endpoint utama:

- `GET /api/products`
- `POST /api/products`
- `GET /api/invoices`
- `POST /api/invoices`
- `GET /api/invoices/:id/comments`
- `POST /api/invoices/:id/comments`
- `GET /api/statistics/profit?period=week`
- `GET /api/statistics/profit?period=month`

Pembuatan faktur menggunakan transaksi MySQL dan `SELECT ... FOR UPDATE`, sehingga
faktur dan pemotongan stok disimpan sebagai satu operasi yang konsisten.
Endpoint pembuatan produk dan faktur memeriksa role Admin. Riwayat faktur dapat
dibaca Admin dan Manager, sedangkan komentar koreksi hanya dapat dibuat Manager.
Contoh Flutter mengirim header `x-stokku-role`; pada produksi, ganti header
sederhana ini dengan role dari token autentikasi yang telah diverifikasi server.

Statistik keuntungan menyimpan snapshot `unit_cost` pada setiap detail faktur,
kemudian mengagregasikan keuntungan berdasarkan minggu atau bulan. Endpoint ini
hanya menerima role Manager.

Jika database dibuat sebelum fitur Pareto tersedia, jalankan migrasi satu kali:

```bash
mysql -u root -p < dart_api/migrations/002_invoice_profit.sql
```

## 3. Jalankan Flutter

Folder `flutter_app` berisi klien Flutter dasar dan service API yang dapat dipakai
untuk layar inventaris maupun Faktur.

```bash
cd flutter_app
flutter pub get
flutter run --dart-define=STOKKU_API_URL=http://10.0.2.2:8080/api
```

`10.0.2.2` adalah alamat host dari Android Emulator. Untuk perangkat fisik,
gunakan alamat IP komputer pada jaringan lokal. Untuk produksi, gunakan URL HTTPS.

## Catatan keamanan

- Jangan masukkan `.env` atau password MySQL ke repository.
- Batasi CORS ke domain aplikasi saat deployment.
- Tambahkan autentikasi token dan validasi role Admin pada API sebelum produksi.
- Gunakan HTTPS dan backup database terjadwal.
