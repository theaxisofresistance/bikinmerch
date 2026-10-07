# BikinMerch MVP

Platform print-on-demand lokal untuk kreator Indonesia. Implementasi ini mencakup login multi-role, katalog produk, editor desain Fabric.js, penyimpanan desain, storefront, checkout dengan mock payment, order tracking, dashboard Creator, Admin, dan Print Partner.

## Prasyarat

- Node.js 20+
- Akun dan project PostgreSQL di [Neon](https://neon.com)
- pnpm atau npm

## Menjalankan secara lokal

```bash
cp .env.example .env
```

Di Neon Console, buka project lalu pilih **Connect**. Salin dua connection string ke `.env`:

- `DATABASE_URL`: aktifkan **Connection pooling**; hostname mengandung `-pooler`.
- `DIRECT_URL`: nonaktifkan **Connection pooling**; hostname tidak mengandung `-pooler`.

Pertahankan parameter SSL yang diberikan Neon dan atur `JWT_SECRET` ke string rahasia acak minimal 32 karakter. Jangan commit file `.env` karena berisi kredensial database. Kemudian jalankan:

```bash
pnpm install
pnpm db:push
pnpm db:seed
pnpm dev
```

Buka http://localhost:3000.

Seed membuat produk T-shirt, Hoodie, Tote Bag, Mug, dan Notebook beserta varian, satu storefront Creator, satu Print Partner, dan akun demo:

| Role | Email | Password |
| --- | --- | --- |
| Creator | creator@bikinmerch.id | bikinmerch123 |
| Customer | customer@bikinmerch.id | bikinmerch123 |
| Admin | admin@bikinmerch.id | bikinmerch123 |
| Print Partner | partner@bikinmerch.id | bikinmerch123 |

## Alur demo end-to-end

1. Masuk sebagai Creator. Pilih produk dari katalog, lalu tambah teks/gambar dan atur desain di `/studio`.
2. Simpan desain. Masukkan harga jual yang lebih tinggi dari modal, lalu publikasikan ke storefront.
3. Keluar, masuk sebagai Customer, buka storefront dan checkout produk dengan alamat pengiriman. Mock payment langsung membuat order berstatus `PAID` dan production order `QUEUED`.
4. Keluar dan masuk sebagai Print Partner. Buka `/partner` lalu lanjutkan status produksi dari `QUEUED` ke `PRINTING`, `QC`, `PACKED`, `SHIPPED`, dan `DELIVERED`.
5. Kembali masuk sebagai Creator dan lihat pesanan, revenue, profit, produk terlaris, dan grafik di `/dashboard`.
6. Admin dapat melihat pengguna, katalog, pesanan, dan partner, serta mengaktifkan/menonaktifkan produk dan partner di `/admin`.

## Implementasi dan batas MVP

- Neon PostgreSQL dan Prisma menyimpan seluruh akun, varian, desain Fabric canvas, storefront, listing, order, serta production order.
- Login menggunakan password bcrypt dan sesi cookie JWT httpOnly. Registrasi publik tersedia untuk Creator dan Customer; akun Admin/Print Partner dibuat melalui seed oleh administrator.
- Checkout hanya mock payment. Belum ada transaksi uang sungguhan, layanan kurir, email, payout, moderation IP, atau auto-routing multi-partner.
- Mockup saat ini menggunakan foto produk katalog dan preview artwork 2D tersimpan. Hasil cetak masih perlu proofing fisik oleh partner.
- Grafik menggunakan Recharts. Editor menggunakan Fabric.js dengan upload image lokal, teks, bentuk, drag, resize, rotate, layer, undo/redo, print area dan safe area.

## Perintah berguna

```bash
pnpm db:studio     # melihat/mengelola record database
pnpm db:push       # menerapkan perubahan schema ke PostgreSQL
pnpm db:seed       # menambah akun dan katalog demo
pnpm build         # generate Prisma Client dan build Next.js
```

Rencana setelah MVP: payment gateway Indonesia, integrasi kurir, dashboard payout, supplier routing berbasis lokasi dan SLA, moderasi desain/hak cipta, marketplace integration, B2B/bulk order, dan fulfillment API.
