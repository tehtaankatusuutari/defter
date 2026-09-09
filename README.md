# Defter

Tek sayfalık gelir/gider/ALV takip uygulaması.

Kurulum yapılmadan direkt açılır ve bu cihazda (localStorage) çalışır. İstediğin zaman sağ üstteki **☁️ Buluta bağlan** ile Supabase'e geçebilirsin — o zaman veriler bulutta saklanır, cihazlar arası anlık senkronize olur ve gecikmiş/yaklaşan ödemeler için telefonuna push bildirimi gelir.

## Buluta bağlanma (opsiyonel)

1. [supabase.com](https://supabase.com) üzerinde yeni bir proje oluştur.
2. `supabase/schema.sql` dosyasının tamamını Supabase Dashboard → SQL Editor'de çalıştır.
3. Cihazlar arası anlık senkron ve push bildirimleri istiyorsan `supabase/realtime_and_push_migration.sql`'i de çalıştır (içindeki `<PROJECT_REF>` ve `<CRON_SECRET>` yer tutucularını doldurarak — bkz. dosyanın içindeki talimatlar). Push bildirimleri için ayrıca `supabase/functions/send-reminders` fonksiyonunu deploy edip VAPID/CRON_SECRET secret'larını eklemen gerekir.
4. Authentication → Providers → Email altında "Allow new users to sign up" kapat.
5. Authentication → Users → Add user ile kendi giriş hesabını oluştur.
6. Project Settings → API'den "Project URL" ve "anon public"/"Publishable" key'i al.
7. Uygulamada **☁️ Buluta bağlan**'a tıkla, URL + key'i yapıştır, sonra e-posta/şifre ile giriş yap.

Not: Bulut moduna geçtiğinde, o ana kadar bu cihazda yerel olarak girdiğin kayıtlar otomatik taşınmaz — henüz elle girmen gerekir.

## Veri modeli

- `sales` — her gelir kaydı (tarih, ödeme yöntemi, tutar, ALV oranı).
- `bills` — her gider kaydı (açıklama, tutar, vade, durum, ALV oranı, aylık tekrar bayrağı). Tekrarlayan bir gider "Ödendi" işaretlendiğinde bir sonraki ayın kaydı otomatik oluşturulur.
