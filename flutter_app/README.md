# BikinMerch Flutter

Konversi antarmuka BikinMerch ke Flutter untuk Android, iOS, dan Web. Seluruh layar menggunakan widget Flutter dan studio menggunakan Canvas Flutter. Backend tetap Next.js + Prisma + PostgreSQL pada folder induk, sehingga akun, desain, listing, dan pesanan menggunakan data yang sama.

## Menjalankan

Prasyarat: Flutter 3.38+ / Dart 3.10+, serta backend BikinMerch yang dapat terhubung ke database. Proyek dibuat dan diperiksa menggunakan Flutter 3.44.1 / Dart 3.12.1.

Jalankan backend dari folder induk, memakai `.env` yang sudah dikonfigurasi:

```sh
npm install
npm run dev -- --hostname 0.0.0.0
```

Di terminal lain:

```sh
cd flutter_app
flutter pub get
flutter run -d chrome --web-port=5000 \
  --dart-define=API_BASE_URL=http://localhost:3000
```

Jika memakai Microsoft Edge:

```sh
CHROME_EXECUTABLE="/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
  flutter run -d chrome --web-port=5000 \
  --dart-define=API_BASE_URL=http://localhost:3000
```

Alamat API berdasarkan target:

| Target | API_BASE_URL |
| --- | --- |
| Android Emulator | `http://10.0.2.2:3000` (default Android) |
| iOS Simulator | `http://localhost:3000` (default iOS) |
| Perangkat fisik | `http://<IP-LAN-komputer>:3000` untuk debug |
| Web lokal | `http://localhost:3000`, Flutter berjalan di port `5000` |
| Rilis | URL HTTPS backend, misalnya `https://bikinmerch.id` |

Contoh Android:

```sh
flutter run -d <device-id> --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Backend perlu tetap berjalan. File database dan kredensial PostgreSQL tidak disalin ke aplikasi Flutter. Jika backend/database belum tersedia, aplikasi menampilkan pesan koneksi dan tombol coba lagi.

## Fitur yang dipindahkan

| Fitur asal | Implementasi Flutter |
| --- | --- |
| Landing page, katalog 5 jenis produk, harga dasar | Katalog responsif dengan data `/api/products` |
| Login, registrasi Creator/Customer, logout | API autentikasi yang sama; empat role tetap didukung |
| Studio 6 template dan filter kategori | Weekend Society, After Hours, Less But Better, Sunday Run Club, In My Own Time, Good Things Ahead |
| Desain depan dan belakang | Pengaturan terpisah untuk kedua sisi, termasuk mengosongkan sisi |
| Produk dan varian | Pilihan produk, warna, regular/oversized untuk T-shirt, area cetak |
| Pengaturan artwork | Tiga teks, tiga gaya huruf, lima palet warna, posisi dada/tengah/besar, skala 60–120% |
| Upload gambar/logo | PNG, JPG, WebP maksimal 4 MB, ganti/hapus logo |
| Undo/redo | Riwayat hingga 50 perubahan |
| Simpan/buka/edit desain | Penyimpanan akun melalui API, plus salinan lokal per akun dan produk |
| Desain tersimpan | Edit, hapus draft, publikasi dan perbarui harga jual di atas modal |
| Storefront kreator | URL `/store/<slug>` / `/#/store/<slug>`, pencarian slug/nama kreator, salin tautan |
| Checkout Customer | Listing storefront, alamat pengiriman, mock payment, satu produk per checkout seperti aplikasi asal |
| Pesan dari Studio | Simpan desain, pilih varian, jumlah 1–10, alamat, masuk antrean produksi |
| Lacak pesanan | PAID → QUEUED → PRINTING → QC → PACKED → SHIPPED → DELIVERED |
| Dashboard Creator | Jumlah pesanan, revenue, profit, grafik interaktif, produk terlaris, pesanan terbaru |
| Print Partner / Admin | Antrean produksi dan perubahan status |
| Production Design Inspector | Artwork/preview produk, dua sisi, grid, ruler, safe area, perspektif, zoom, export |
| Admin | Daftar pengguna, katalog, pesanan, partner; aktif/nonaktif produk dan partner |

Format JSON studio mengikuti `src/components/Studio.tsx` pada aplikasi asal: `fit`, `shirt`, `activeSide`, dan `sides.front/back`. Desain yang disimpan dari versi web dapat dibuka di Flutter, dan sebaliknya. Mockup menggunakan aset kaos yang sama. Font dapat berbeda mengikuti font yang tersedia di platform; hasil visual tidak dijamin identik per piksel.

Ekspor menggunakan renderer yang sama dengan preview:

- Artwork transparan PNG: **2400 × 3000 px**.
- Mockup satu sisi PNG: **1000 × 1100 px**.
- Mockup depan + belakang PNG: **2000 × 1100 px**.

Android/iOS membuka lembar berbagi sistem untuk menyimpan/membagikan PNG. Web mengunduh PNG langsung seperti aplikasi asal. Gambar dari toko/katalog yang tidak dapat dimuat menampilkan placeholder.

Pembayaran, pengiriman, dan payout tetap mengikuti batas MVP asal: pembayaran masih simulasi, belum terhubung payment gateway atau kurir sungguhan.

## Integrasi backend

Tiga penyesuaian kecil dilakukan di backend induk:

1. `/api/auth/login` dan `/api/auth/register` menyertakan JWT jika header `X-Bikinmerch-Client: flutter-native` dikirim.
2. `src/lib/auth.ts` menerima `Authorization: Bearer <token>` untuk perangkat native. Browser tetap menggunakan cookie `httpOnly`.
3. `src/middleware.ts` mengatur CORS menggunakan daftar origin yang diizinkan.

Sesi native disimpan dengan `flutter_secure_storage` (Keychain/Keystore). Web tidak menyimpan JWT di localStorage. Salinan desain lokal memakai `shared_preferences` dan dipisahkan per akun/produk.

Untuk Flutter Web di origin lain, tambahkan pada `.env` backend lalu restart server:

```dotenv
FLUTTER_WEB_ORIGINS=http://localhost:5000,https://app.example.com
```

Origin localhost port 5000 diizinkan secara default saat `NODE_ENV=development`. Untuk deployment, tempatkan Flutter Web dan backend pada origin yang sama, atau dalam domain induk yang sama dengan HTTPS. Cookie `SameSite=Lax` dari backend asal tetap berlaku; deployment lintas situs yang tidak berhubungan memerlukan pengaturan cookie/proxy tersendiri.

## Akun demo

Jalankan seed dari backend bila database baru. Jangan menjalankan seed ulang bila tidak diperlukan.

| Peran | Email | Password |
| --- | --- | --- |
| Creator | creator@bikinmerch.id | bikinmerch123 |
| Customer | customer@bikinmerch.id | bikinmerch123 |
| Admin | admin@bikinmerch.id | bikinmerch123 |
| Print Partner | partner@bikinmerch.id | bikinmerch123 |

## Pemeriksaan dan build

```sh
flutter analyze
flutter test
flutter build web --release --dart-define=API_BASE_URL=https://backend.example.com
flutter build apk --release --dart-define=API_BASE_URL=https://backend.example.com
flutter build ios --release --dart-define=API_BASE_URL=https://backend.example.com
```

Pengujian mencakup kompatibilitas JSON, ukuran/transparansi PNG, undo/redo, sesi, validasi harga dan alamat, checkout kedua role, status produksi, akses peran, dan layout ponsel. Pengujian alur memakai respons API uji agar tidak mengubah database asli.

Android memerlukan SDK dan lisensi Android yang sudah disiapkan. HTTP lokal diizinkan pada build debug; gunakan HTTPS untuk rilis. Konfigurasi signing Android rilis masih memakai bawaan proyek Flutter dan perlu diganti dengan keystore distribusi milik aplikasi sebelum publikasi.

iOS memerlukan Xcode lengkap, toolchain plugin yang didukung Flutter, dan konfigurasi signing tim Apple. Entitlement Keychain dan akses jaringan lokal sudah disertakan. Build iOS belum dapat diverifikasi pada komputer yang hanya memasang Command Line Tools.

## Struktur

```text
lib/
  core/       API, sesi, model data, state aplikasi
  pages/      katalog, storefront, checkout, desain, dashboard, orders, admin, partner
  studio/     model proyek, renderer Canvas, editor, inspector, ekspor PNG
  ui/         tema, komponen responsif, dialog autentikasi
assets/studio/  aset mockup dari aplikasi asal
test/           pengujian API, studio, dan alur antarmuka
```

## Hasil verifikasi konversi

- `flutter analyze`: tidak ada issue.
- `flutter test`: 15 pengujian lulus.
- `flutter build web --release`: berhasil, termasuk pemeriksaan kompilasi Wasm.
- Pemeriksaan Microsoft Edge: tujuh tampilan desktop/ponsel tanpa error JavaScript, dialog perubahan belum tersimpan berfungsi, unduhan artwork PNG 2400 × 3000 berhasil.
- TypeScript backend serta verifikasi cookie/bearer/CORS lulus.
- Koneksi database Neon dari konfigurasi proyek belum dapat dijangkau saat pemeriksaan. Alur transaksi diuji dengan respons API uji; tidak ada order asli yang dibuat.
- Build APK belum terverifikasi karena unduhan dependensi Gradle belum selesai saat pemeriksaan. Build iOS belum dijalankan karena Xcode lengkap belum tersedia.
