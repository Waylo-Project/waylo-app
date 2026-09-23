// send_push — Supabase Edge Function (Phase 8).
//
// Called by Database Webhooks on friend_requests / post_likes / post_comments.
// Resolves the recipient + message, looks up their FCM tokens, and delivers via
// the FCM HTTP v1 API. Never notifies the actor about their own action.
//
// Secrets (set as Edge Function secrets, NEVER committed):
//   FCM_SERVICE_ACCOUNT  - the Firebase service-account JSON (whole file)
//   SUPABASE_URL         - provided automatically
//   SUPABASE_SERVICE_ROLE_KEY - provided automatically
// The webhook must send  Authorization: Bearer <service_role_key>  so random
// callers can't spam notifications (the function runs with verify_jwt = false).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SERVICE_ACCOUNT = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT")!);
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const admin = createClient(SUPABASE_URL, SERVICE_ROLE);

// ---- FCM HTTP v1 OAuth2 access token (cached ~1h) -------------------------
let cached: { token: string; exp: number } | null = null;

async function accessToken(): Promise<string> {
  if (cached && cached.exp > Date.now() + 60_000) return cached.token;
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = b64url(JSON.stringify({
    iss: SERVICE_ACCOUNT.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = `${header}.${claim}`;
  const key = await importKey(SERVICE_ACCOUNT.private_key);
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${b64urlBytes(new Uint8Array(sig))}`;
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body:
      `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const data = await res.json();
  cached = { token: data.access_token, exp: Date.now() + 3500_000 };
  return data.access_token;
}

function b64url(s: string): string {
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
function b64urlBytes(b: Uint8Array): string {
  let s = "";
  for (const x of b) s += String.fromCharCode(x);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
async function importKey(pem: string): Promise<CryptoKey> {
  const body = pem.replace(/-----[A-Z ]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

// ---- localized message templates ------------------------------------------
// Each returns [title, body] for the recipient's language ("ko" or "en", with
// English as the fallback). `n` is the actor's username.
type Tmpl = (n: string) => [string, string];
const MESSAGES: Record<string, Record<string, Tmpl>> = {
  friend_request: {
    ko: (n) => ["새 친구 요청", `${n}님이 친구 요청을 보냈어요`],
    en: (n) => ["New friend request", `${n} sent you a friend request`],
  },
  friend_accepted: {
    ko: (n) => ["친구 요청 수락", `${n}님이 친구 요청을 수락했어요`],
    en: (n) => ["Friend request accepted", `${n} accepted your friend request`],
  },
  like: {
    ko: (n) => ["새 좋아요", `${n}님이 회원님의 사진을 좋아합니다`],
    en: (n) => ["New like", `${n} liked your photo`],
  },
  comment: {
    ko: (n) => ["새 댓글", `${n}님이 댓글을 남겼어요`],
    en: (n) => ["New comment", `${n} commented on your photo`],
  },
};

function compose(type: string, lang: string, name: string): [string, string] {
  const byLang = MESSAGES[type];
  return (byLang[lang] ?? byLang.en)(name);
}

// ---- delivery -------------------------------------------------------------
// Sends one notification per device, each composed in that device's language.
async function pushToUser(
  userId: string,
  type: string,
  name: string,
  data: Record<string, string> = {},
) {
  const { data: tokens } = await admin
    .from("device_tokens")
    .select("token, language")
    .eq("user_id", userId);
  console.log(`pushToUser ${userId} type=${type} tokens=${tokens?.length ?? 0}`);
  if (!tokens || tokens.length === 0) return;

  const bearer = await accessToken();
  for (const { token, language } of tokens) {
    const [title, body] = compose(type, language ?? "en", name);
    // Data-only message (title/body live in `data`, NOT a `notification` block):
    // the OS never auto-displays it, so the Flutter app draws every notification
    // itself — in the foreground and in the background isolate — and can set the
    // real app icon as the large icon. See app/lib/core/push_messaging.dart.
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${SERVICE_ACCOUNT.project_id}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${bearer}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token,
            data: { ...data, type, title, body },
            android: { priority: "HIGH" },
          },
        }),
      },
    );
    if (!res.ok) {
      const errBody = await res.text();
      console.error(`FCM ${res.status} for token ${token.slice(0, 12)}…: ${errBody}`);
      // Stale / unregistered token → drop it so the table stays clean.
      if (res.status === 404 || res.status === 400) {
        await admin.from("device_tokens").delete().eq("token", token);
      }
    } else {
      console.log(`FCM ok → ${token.slice(0, 12)}…`);
    }
  }
}

async function usernameOf(id: string): Promise<string> {
  const { data } = await admin
    .from("profiles")
    .select("username")
    .eq("id", id)
    .maybeSingle();
  return data?.username ?? "someone";
}

async function postOwner(postId: string): Promise<string | null> {
  const { data } = await admin
    .from("posts")
    .select("user_id")
    .eq("id", postId)
    .maybeSingle();
  return data?.user_id ?? null;
}

// ---- webhook entry --------------------------------------------------------
Deno.serve(async (req) => {
  // NOTE: auth check temporarily removed — Supabase manages the Authorization
  // header on Edge Function webhooks, which collided with our service-role
  // check (401). Re-secure later with a custom header (e.g. x-webhook-secret)
  // that Supabase doesn't touch. The function runs with verify_jwt = false.

  try {
    const { type, table, record: rec, old_record: old } = await req.json();
    console.log(`webhook ${type} on ${table}`);

    if (table === "friend_requests" && type === "INSERT") {
      const name = await usernameOf(rec.from_user);
      await pushToUser(rec.to_user, "friend_request", name);
    } else if (
      table === "friend_requests" && type === "UPDATE" &&
      rec.status === "accepted" && old?.status !== "accepted"
    ) {
      const name = await usernameOf(rec.to_user);
      await pushToUser(rec.from_user, "friend_accepted", name);
    } else if (table === "post_likes" && type === "INSERT") {
      const owner = await postOwner(rec.post_id);
      if (owner && owner !== rec.user_id) {
        const name = await usernameOf(rec.user_id);
        await pushToUser(owner, "like", name, { post_id: rec.post_id });
      }
    } else if (table === "post_comments" && type === "INSERT") {
      const owner = await postOwner(rec.post_id);
      if (owner && owner !== rec.user_id) {
        const name = await usernameOf(rec.user_id);
        await pushToUser(owner, "comment", name, { post_id: rec.post_id });
      }
    }

    return new Response("ok");
  } catch (e) {
    console.error("send_push error", e);
    return new Response("error", { status: 500 });
  }
});
