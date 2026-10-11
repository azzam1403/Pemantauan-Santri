-- ============================================================
-- Absen Musyrif - skema database + aturan akses (RLS)
-- Jalankan SEKALI di Supabase: SQL Editor > New query > Run
-- ============================================================

-- 1) Tabel -------------------------------------------------------------
create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  nama       text not null default '',
  role       text not null default 'musyrif' check (role in ('musyrif','admin','pimpinan')),
  created_at timestamptz not null default now()
);

create table if not exists public.santri (
  id         uuid primary key default gen_random_uuid(),
  musyrif_id uuid not null references public.profiles(id) on delete cascade,
  nama       text not null,
  kamar      text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists santri_musyrif_idx on public.santri(musyrif_id);

create table if not exists public.absensi (
  santri_id  uuid not null references public.santri(id) on delete cascade,
  musyrif_id uuid not null references public.profiles(id) on delete cascade,
  tanggal    date not null,
  slot       text not null,                       -- subuh, dzuhur, mpagi, tahfidz, ...
  status     text not null check (status in ('H','T','I','S','A')),
  menit      int  not null default 0,             -- menit keterlambatan
  catatan    text not null default '',
  updated_at timestamptz not null default now(),
  primary key (santri_id, tanggal, slot)
);
create index if not exists absensi_musyrif_tgl_idx on public.absensi(musyrif_id, tanggal);

create table if not exists public.konseling (
  id            uuid primary key default gen_random_uuid(),
  santri_id     uuid not null references public.santri(id) on delete cascade,
  musyrif_id    uuid not null references public.profiles(id) on delete cascade,
  tanggal       date not null,
  topik         text not null,
  catatan       text not null default '',
  tindak_lanjut text,
  tanggal_tl    date,
  status        text not null default 'Terbuka' check (status in ('Terbuka','Berjalan','Selesai')),
  eskalasi      boolean not null default false,
  created_at    timestamptz not null default now()
);
create index if not exists konseling_musyrif_idx on public.konseling(musyrif_id, tanggal desc);

-- 2) Profil otomatis saat akun dibuat -------------------------------------
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, nama)
  values (new.id, coalesce(new.raw_user_meta_data->>'nama', split_part(new.email, '@', 1)));
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3) Fungsi bantu: peran pengguna yang sedang login ---------------------------
create or replace function public.my_role() returns text
language sql stable security definer set search_path = public as
$$ select role from public.profiles where id = auth.uid() $$;

-- 4) Row Level Security --------------------------------------------------
alter table public.profiles  enable row level security;
alter table public.santri    enable row level security;
alter table public.absensi   enable row level security;
alter table public.konseling enable row level security;

-- profiles: baca diri sendiri; admin & pimpinan baca semua; hanya admin boleh ubah
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select to authenticated
  using (id = auth.uid() or public.my_role() in ('admin','pimpinan'));
drop policy if exists profiles_admin_update on public.profiles;
create policy profiles_admin_update on public.profiles for update to authenticated
  using (public.my_role() = 'admin') with check (public.my_role() = 'admin');

-- santri: musyrif kelola santrinya sendiri; admin & pimpinan hanya baca
drop policy if exists santri_musyrif on public.santri;
create policy santri_musyrif on public.santri for all to authenticated
  using (musyrif_id = auth.uid() and public.my_role() = 'musyrif')
  with check (musyrif_id = auth.uid() and public.my_role() = 'musyrif');
drop policy if exists santri_pengawas on public.santri;
create policy santri_pengawas on public.santri for select to authenticated
  using (public.my_role() in ('admin','pimpinan'));

-- absensi: musyrif kelola absen santrinya sendiri; admin & pimpinan hanya baca
drop policy if exists absensi_musyrif on public.absensi;
create policy absensi_musyrif on public.absensi for all to authenticated
  using (musyrif_id = auth.uid() and public.my_role() = 'musyrif')
  with check (
    musyrif_id = auth.uid() and public.my_role() = 'musyrif'
    and exists (select 1 from public.santri s where s.id = santri_id and s.musyrif_id = auth.uid())
  );
drop policy if exists absensi_pengawas on public.absensi;
create policy absensi_pengawas on public.absensi for select to authenticated
  using (public.my_role() in ('admin','pimpinan'));

-- konseling: musyrif kelola catatannya sendiri; HANYA admin yang boleh membaca semuanya.
-- (Pimpinan sengaja tidak diberi akses. Untuk membuka, lihat catatan di README.)
drop policy if exists konseling_musyrif on public.konseling;
create policy konseling_musyrif on public.konseling for all to authenticated
  using (musyrif_id = auth.uid() and public.my_role() = 'musyrif')
  with check (
    musyrif_id = auth.uid() and public.my_role() = 'musyrif'
    and exists (select 1 from public.santri s where s.id = santri_id and s.musyrif_id = auth.uid())
  );
drop policy if exists konseling_admin on public.konseling;
create policy konseling_admin on public.konseling for select to authenticated
  using (public.my_role() = 'admin');
