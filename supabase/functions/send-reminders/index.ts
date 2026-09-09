// Günlük hatırlatma işi. pg_cron (bkz. supabase/realtime_and_push_migration.sql)
// bu fonksiyonu her gün çağırır; gecikmiş/yaklaşan ödemeler varsa kayıtlı
// tüm push aboneliklerine bildirim gönderir.
//
// Gerekli secret'lar (Dashboard → Edge Functions → send-reminders → Secrets):
//   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_SUBJECT (mailto:...), CRON_SECRET
// SUPABASE_URL ve SUPABASE_SERVICE_ROLE_KEY her fonksiyona otomatik enjekte edilir.

import { createClient } from "npm:@supabase/supabase-js@2";
import webpush from "npm:web-push@3";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const VAPID_PUBLIC_KEY = Deno.env.get("VAPID_PUBLIC_KEY")!;
const VAPID_PRIVATE_KEY = Deno.env.get("VAPID_PRIVATE_KEY")!;
const VAPID_SUBJECT = Deno.env.get("VAPID_SUBJECT") ?? "mailto:example@example.com";
const CRON_SECRET = Deno.env.get("CRON_SECRET")!;

webpush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY);

function todayISO() {
  return new Date().toISOString().slice(0, 10);
}

Deno.serve(async (req) => {
  if (req.headers.get("x-cron-secret") !== CRON_SECRET) {
    return new Response("Unauthorized", { status: 401 });
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  const today = todayISO();
  const soonLimit = new Date(Date.now() + 3 * 86400000).toISOString().slice(0, 10);

  const { data: bills, error } = await supabase
    .from("bills")
    .select("*")
    .eq("status", "beklemede")
    .lte("due", soonLimit);

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }

  const overdue = (bills ?? []).filter((b) => b.due < today);
  const soon = (bills ?? []).filter((b) => b.due >= today);

  if (overdue.length === 0 && soon.length === 0) {
    return new Response(JSON.stringify({ sent: 0, reason: "nothing due" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  let title = overdue.length ? "⚠️ Ödeme gecikti" : "Yaklaşan ödeme";
  const lines: string[] = [];
  if (overdue.length) {
    lines.push(`Gecikmiş: ` + overdue.map((b) => `${b.name} (${b.due})`).join(", "));
  }
  if (soon.length) {
    lines.push(`Yaklaşan: ` + soon.map((b) => `${b.name} (${b.due})`).join(", "));
  }
  const body = lines.join("\n");

  const { data: subs } = await supabase.from("push_subscriptions").select("*");

  let sent = 0;
  for (const sub of subs ?? []) {
    try {
      await webpush.sendNotification(
        { endpoint: sub.endpoint, keys: { p256dh: sub.p256dh, auth: sub.auth } },
        JSON.stringify({ title, body })
      );
      sent++;
    } catch (err) {
      const statusCode = (err as { statusCode?: number }).statusCode;
      if (statusCode === 404 || statusCode === 410) {
        await supabase.from("push_subscriptions").delete().eq("id", sub.id);
      }
    }
  }

  return new Response(
    JSON.stringify({ sent, overdue: overdue.length, soon: soon.length }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});
