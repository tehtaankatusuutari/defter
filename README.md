# Defter

Tek sayfalık gelir/gider/ALV takip uygulaması. Veriler Supabase'te saklanır, giriş Supabase Auth (e-posta + şifre) ile korunur.

## Kurulum

1. [supabase.com](https://supabase.com) üzerinde yeni bir proje oluştur.
2. `supabase/schema.sql` dosyasının tamamını Supabase Dashboard → SQL Editor'de çalıştır.
3. Authentication → Providers → Email altında "Allow new users to sign up" kapat.
4. Authentication → Users → Add user ile kendi giriş hesabını oluştur.
5. Project Settings → API'den "Project URL" ve "anon public" key'i al.
6. `index.html`'i tarayıcıda aç, ilk açılan kurulum ekranına URL + anon key'i yapıştır, sonra e-posta/şifre ile giriş yap.

## Veri modeli

- `sales` — her gelir kaydı (tarih, ödeme yöntemi, tutar, ALV oranı).
- `bills` — her gider kaydı (açıklama, tutar, vade, durum, ALV oranı, aylık tekrar bayrağı). Tekrarlayan bir gider "Ödendi" işaretlendiğinde bir sonraki ayın kaydı otomatik oluşturulur.
