# Absen Musyrif (PWA) - Supabase + Vercel

Absensi santri untuk musyrif (shalat, makan, keterlambatan, kegiatan wajib), profil santri,
penanda "perlu perhatian", dan bimbingan konseling. Login memakai Supabase, di-host di Vercel.

## Peran akun

| Peran | Dibuat sebagai | Bisa melakukan |
|---|---|---|
| `musyrif` | akun baru (peran bawaan) | Mengelola santri, absen, dan konseling **miliknya sendiri**. Tidak bisa melihat data musyrif lain. |
| `admin` | `02_atur_peran.sql` | Tab Laporan: melihat semua musyrif, termasuk konseling (hanya lihat). |
| `pimpinan` | `02_atur_peran.sql` | Tab Laporan: melihat absen dan rekap semua musyrif (hanya lihat). **Tidak** bisa melihat konseling. |

Aturan ini dijaga di database (Row Level Security), bukan hanya di tampilan aplikasi.

## Isi proyek

```
index.html            Aplikasi (satu file)
config.js             URL dan kunci Supabase  <- ANDA ISI
sw.js                 Service worker (offline untuk file aplikasi)
manifest.webmanifest  Pengaturan PWA
vercel.json           Pengaturan header Vercel
vendor/supabase.js    Pustaka Supabase (sudah disertakan, v2.45.4)
icons/                Ikon aplikasi
supabase/01_skema.sql        Tabel + aturan akses
supabase/02_atur_peran.sql   Mengatur nama dan peran akun
```

## Langkah 1 - Siapkan Supabase

1. Buat proyek di https://supabase.com (Region: pilih yang terdekat, misalnya Singapore).
2. Buka **SQL Editor > New query**, tempel isi `supabase/01_skema.sql`, klik **Run**.
3. Buka **Authentication > Sign In / Providers** (atau Settings), **matikan** "Allow new users to sign up"
   agar hanya akun buatan admin yang bisa masuk.
4. Buka **Authentication > Users > Add user > Create new user**. Buat akun untuk admin, pimpinan, dan
   tiap musyrif (isi email + kata sandi, centang **Auto Confirm User**).
5. Edit email dan nama di `supabase/02_atur_peran.sql`, tempel di SQL Editor, **Run**.
   Hasil akhirnya berupa tabel email, nama, dan peran untuk dicek.
6. Buka **Project Settings > API**, salin **Project URL** dan **anon / publishable key**.

## Langkah 2 - Isi `config.js`

Ganti `url` dan `key` dengan data dari langkah 1.6. Kunci anon aman dipublikasikan karena data dilindungi RLS.
**Jangan pernah** memasukkan kunci `service_role`. Jika kunci "publishable" (`sb_publishable_...`) bermasalah,
pakai kunci anon versi lama (berawalan `eyJ`) di bagian Legacy API Keys.

## Langkah 3 - Deploy ke Vercel

1. Upload semua file proyek ke repositori GitHub (pertahankan struktur folder `icons`, `vendor`, `supabase`).
2. Di https://vercel.com: **Add New > Project**, pilih repositori tersebut.
3. **Framework Preset: Other**. Kosongkan Build Command dan Output Directory. Klik **Deploy**.
4. Selesai. Alamatnya berbentuk `https://nama-proyek.vercel.app`. Setiap kali Anda commit, Vercel deploy ulang otomatis.

## Langkah 4 - Pasang di HP

- **Android (Chrome):** buka alamat, menu titik tiga > **Install app**.
- **iPhone (Safari):** tombol Bagikan > **Tambah ke Layar Utama**.

## Memperbarui aplikasi

Ubah file, naikkan versi di `sw.js` (`absen-musyrif-v3` menjadi `v4`), commit. HP akan mengambil versi baru.

## Catatan penting

- **Perlu internet untuk menyimpan.** File aplikasi bisa dibuka offline, tetapi absen disimpan ke server.
  Jika sinyal hilang, muncul pesan "Gagal menyimpan" dan aplikasi mencoba lagi saat sinyal kembali,
  **selama halaman belum ditutup**. Data yang belum tersimpan hilang bila aplikasi ditutup saat offline.
- **Data yang dimuat:** 62 hari terakhir (cukup untuk profil 30 hari dan tren). Saat tanggal awal di tab Rekap
  digeser lebih lama, data lama dimuat otomatis.
- **Cara memberi pimpinan akses konseling** (jika diperlukan), jalankan di SQL Editor:
  ```sql
  drop policy if exists konseling_admin on public.konseling;
  create policy konseling_admin on public.konseling for select to authenticated
    using (public.my_role() in ('admin','pimpinan'));
  ```
- **Lupa kata sandi / tambah musyrif:** lewat Authentication > Users di dashboard Supabase.
- Sebelum dipakai sungguhan, uji dengan 1 akun musyrif dan 1 akun admin, lalu pastikan musyrif tidak bisa melihat musyrif lain.
