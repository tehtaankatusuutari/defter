-- Defter (muhasebe) — Supabase şeması
--
-- Kurulum:
-- 1. supabase.com üzerinde yeni bir proje oluştur.
-- 2. Project → SQL Editor → New query içine bu dosyanın tamamını yapıştırıp çalıştır.
-- 3. Authentication → Providers → Email altında "Allow new users to sign up"
--    seçeneğini kapat (sadece senin girişin olsun, başkası kayıt olamasın).
-- 4. Authentication → Users → Add user ile kendi e-posta + şifreni oluştur.
-- 5. Project Settings → API sayfasından "Project URL" ve "anon public" key'i
--    kopyala, uygulamanın ilk açılışındaki kurulum ekranına yapıştır.

create extension if not exists pgcrypto;

create table if not exists sales (
  id uuid primary key default gen_random_uuid(),
  date date not null,
  method text not null,
  amount numeric not null,
  vat numeric not null default 25.5,
  created_at timestamptz not null default now()
);

create table if not exists bills (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  amount numeric not null,
  due date not null,
  status text not null default 'beklemede' check (status in ('beklemede','odendi')),
  paid_date date,
  recurring boolean not null default false,
  recur_day int,
  vat numeric not null default 0,
  created_at timestamptz not null default now()
);

alter table sales enable row level security;
alter table bills enable row level security;

-- Sadece gerçek bir Supabase Auth oturumu olan (role = authenticated) istekler
-- okuyup yazabilir. Anon (public) erişim tamamen kapalı.
create policy "Authenticated full access" on sales
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "Authenticated full access" on bills
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- Opsiyonel: sabit aylık giderlerini başlangıç verisi olarak eklemek istersen
-- aşağıdaki INSERT'i kendi tutar/tarihlerine göre düzenleyip ayrıca çalıştır.

-- insert into bills (name, amount, due, recurring, recur_day, vat) values
--   ('Kira', 1085, '2026-10-06', true, 6, 0),
--   ('YEL Vakuutus', 155, '2026-10-19', true, 19, 0),
--   ('Vergi Taksit', 110, '2026-10-21', true, 21, 0),
--   ('Dna Telefon', 85, '2026-10-25', true, 25, 25.5),
--   ('Telia Taksit', 30, '2026-10-19', true, 19, 25.5);
