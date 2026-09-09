-- Anlık senkron + push bildirimleri için ek kurulum.
-- schema.sql'i zaten çalıştırdıysan, bunu da SQL Editor'de bir kez çalıştır.

-- 1) Realtime: sales/bills tablolarındaki değişiklikler anında diğer
--    açık sekmelere/cihazlara yayınlansın.
alter publication supabase_realtime add table sales, bills;

-- 2) Push bildirim abonelikleri (telefonun/tarayıcının push endpoint'i).
create table if not exists push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  created_at timestamptz not null default now()
);
alter table push_subscriptions enable row level security;
create policy "Authenticated full access" on push_subscriptions
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- 3) Günlük hatırlatma işi. pg_cron + pg_net gerektirir (çoğu Supabase
--    projesinde hazır gelir; yoksa Database → Extensions'tan ikisini de aç).
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Çalıştırmadan önce aşağıdaki iki yer tırnak içinde değiştirilmeli:
--   <PROJECT_REF>  → Supabase proje referansın (dashboard adres çubuğunda görünür)
--   <CRON_SECRET>  → kendi belirlediğin rastgele bir parola. Aynı değeri Edge
--                     Function'ın CRON_SECRET secret'ı olarak da eklemen gerekir.
select cron.schedule(
  'defter-daily-reminder',
  '0 7 * * *',  -- her gün UTC 07:00 (TR/FI yerel saatte yaklaşık 09:00-10:00)
  $$
  select net.http_post(
    url := 'https://<PROJECT_REF>.supabase.co/functions/v1/send-reminders',
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-cron-secret', '<CRON_SECRET>'),
    body := '{}'::jsonb
  );
  $$
);
