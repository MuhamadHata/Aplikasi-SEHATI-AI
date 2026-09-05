// supabase/functions/send-push-notification/index.ts
// Deploy: supabase functions deploy send-push-notification

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID")!;
const FIREBASE_SERVICE_ACCOUNT = Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!;

// ── Generate OAuth2 access token dari service account ──────────────────────────
async function getAccessToken(): Promise<string> {
  const sa = JSON.parse(FIREBASE_SERVICE_ACCOUNT);

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");

  const signingInput = `${encode(header)}.${encode(payload)}`;

  // Import private key
  const pemKey = sa.private_key.replace(/\\n/g, "\n");
  const keyData = pemKey
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");

  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signingInput)
  );

  const jwt = `${signingInput}.${btoa(
    String.fromCharCode(...new Uint8Array(signature))
  )
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "")}`;

  // Tukar JWT dengan access token
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const data = await res.json();
  return data.access_token;
}

// ── Kirim satu notifikasi ke satu FCM token ─────────────────────────────────────
async function sendToToken(
  accessToken: string,
  fcmToken: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<boolean> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title, body },
          android: {
            notification: {
              channel_id: "sehati_push",
              priority: "HIGH",
              sound: "default",
            },
            priority: "HIGH",
          },
          apns: {
            payload: { aps: { sound: "default", badge: 1 } },
          },
          data: data ?? {},
        },
      }),
    }
  );

  if (!res.ok) {
    const err = await res.text();
    console.error(`FCM error for token ${fcmToken.substring(0, 20)}: ${err}`);
    return false;
  }
  return true;
}

// ── Main handler ────────────────────────────────────────────────────────────────
serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // Validasi Authorization header (pakai Supabase service role key)
  const authHeader = req.headers.get("Authorization");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!authHeader || authHeader !== `Bearer ${serviceRoleKey}`) {
    return new Response("Unauthorized", { status: 401 });
  }

  const { user_id, title, body, data } = await req.json();

  if (!user_id || !title || !body) {
    return new Response(
      JSON.stringify({ error: "user_id, title, body wajib diisi" }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    );
  }

  // Ambil semua token milik user dari Supabase
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const tokensRes = await fetch(
    `${supabaseUrl}/rest/v1/push_tokens?user_id=eq.${user_id}&select=token`,
    {
      headers: {
        apikey: serviceRoleKey!,
        Authorization: `Bearer ${serviceRoleKey}`,
      },
    }
  );

  const tokens: { token: string }[] = await tokensRes.json();

  if (!tokens.length) {
    return new Response(
      JSON.stringify({ sent: 0, message: "Tidak ada token untuk user ini" }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  }

  const accessToken = await getAccessToken();
  let sent = 0;

  for (const { token } of tokens) {
    const ok = await sendToToken(accessToken, token, title, body, data);
    if (ok) sent++;
  }

  return new Response(
    JSON.stringify({ sent, total: tokens.length }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});
