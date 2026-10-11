-- ============================================================
-- Mengatur nama & peran akun.
-- Langkah: buat akun dulu di Authentication > Users > Add user
-- (centang "Auto Confirm User"), lalu edit email di bawah dan Run.
-- ============================================================

-- Jadikan satu akun sebagai ADMIN (pemilik / pengelola):
update public.profiles
   set role = 'admin', nama = 'Admin Pondok'
 where id = (select id from auth.users where email = 'admin@contoh.com');

-- Jadikan satu akun sebagai PIMPINAN (hanya melihat laporan):
update public.profiles
   set role = 'pimpinan', nama = 'Pimpinan Pondok'
 where id = (select id from auth.users where email = 'pimpinan@contoh.com');

-- Akun musyrif tidak perlu diatur: peran bawaannya sudah 'musyrif'.
-- Cukup isi nama yang tampil, satu baris per musyrif:
update public.profiles set nama = 'Ust. Ahmad'
 where id = (select id from auth.users where email = 'ahmad@contoh.com');
update public.profiles set nama = 'Ust. Budi'
 where id = (select id from auth.users where email = 'budi@contoh.com');

-- Cek hasilnya:
select u.email, p.nama, p.role from public.profiles p join auth.users u on u.id = p.id order by p.role, p.nama;
