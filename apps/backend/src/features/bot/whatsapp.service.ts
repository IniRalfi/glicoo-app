/**
 * [ID] Service untuk mengirim pesan via OpenWA API
 * [EN] Service for sending messages via OpenWA API
 *
 * OpenWA Docs: https://docs.open-wa.org/
 * Deployed at: wa.glicoo.my.id
 *
 * WARNING:
 * - OpenWA tidak support Markdown natively (beda format dari Telegram)
 * - Gunakan format plain text atau simple emoji
 * - Rate limit: 50 messages/user/hour (backend-side enforcement)
 */

const OPENWA_BASE_URL = process.env.OPENWA_BASE_URL ?? "https://wa.glicoo.my.id";
const OPENWA_API_KEY = process.env.OPENWA_API_KEY ?? "";

// Rate limiter: max 50 messages/user/hour
const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000; // 1 hour
const RATE_LIMIT_MAX = 50;
const messageCounts = new Map<string, { count: number; resetAt: number }>();

interface OpenWAResponse {
  status: "success" | "error";
  message?: string;
  data?: any;
}

/**
 * [ID] Cek dan update rate limit per user
 * [EN] Check and update rate limit per user
 */
function checkRateLimit(chatId: string): boolean {
  const now = Date.now();
  const entry = messageCounts.get(chatId);

  if (!entry || now > entry.resetAt) {
    messageCounts.set(chatId, { count: 1, resetAt: now + RATE_LIMIT_WINDOW_MS });
    return true;
  }

  if (entry.count >= RATE_LIMIT_MAX) {
    return false;
  }

  entry.count++;
  return true;
}

/**
 * [ID] Kirim pesan teks ke pengguna WhatsApp
 * [EN] Send text message to WhatsApp user
 *
 * @param chatId - Format: "628123456789@c.us" (phone + @c.us suffix)
 * @param message - Plain text message (OpenWA tidak support Markdown)
 * @returns boolean - true jika berhasil
 */
export async function sendWhatsAppMessage(chatId: string, message: string): Promise<boolean> {
  if (!checkRateLimit(chatId)) {
    console.warn(`[WhatsApp] Rate limit exceeded for ${chatId}`);
    return false;
  }

  try {
    const response = await fetch(`${OPENWA_BASE_URL}/api/sendText`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${OPENWA_API_KEY}`,
      },
      body: JSON.stringify({
        chatId,
        content: message,
      }),
    });

    const data = (await response.json()) as OpenWAResponse;

    if (data.status !== "success") {
      console.error(`[WhatsApp] sendMessage failed:`, data.message);
      return false;
    }

    return true;
  } catch (error) {
    console.error(`[WhatsApp] sendMessage error:`, error);
    return false;
  }
}

/**
 * [ID] Kirim indikator "typing..." ke WhatsApp
 * [EN] Send typing indicator to WhatsApp
 */
export async function sendTypingIndicator(chatId: string): Promise<void> {
  try {
    await fetch(`${OPENWA_BASE_URL}/api/startTyping`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${OPENWA_API_KEY}`,
      },
      body: JSON.stringify({ chatId }),
    });
  } catch (error) {
    // Non-critical, silently fail
    console.warn(`[WhatsApp] sendTypingIndicator failed:`, error);
  }
}

/**
 * [ID] Format nomor HP ke format OpenWA (phone@c.us)
 * [EN] Format phone number to OpenWA format (phone@c.us)
 *
 * Input: 628123456789
 * Output: 628123456789@c.us
 */
export function formatChatId(phoneNumber: string): string {
  const cleaned = phoneNumber.replace(/[^0-9]/g, "");
  return `${cleaned}@c.us`;
}

/**
 * [ID] Extract nomor HP dari OpenWA chatId
 * [EN] Extract phone number from OpenWA chatId
 *
 * Input: 628123456789@c.us
 * Output: 628123456789
 */
export function extractPhoneNumber(chatId: string): string {
  return chatId.replace(/@c\.us$/, "");
}

/**
 * [ID] Verifikasi signature webhook dari OpenWA
 * [EN] Verify webhook signature from OpenWA
 *
 * WHY: Mencegah request palsu dari pihak luar
 */
export function verifyWebhookSignature(signature: string | undefined, body: string): boolean {
  const secret = process.env.OPENWA_WEBHOOK_SECRET;

  // Skip verification if secret not configured (OpenWA panel doesn't support signature)
  if (!secret || secret.trim() === "") {
    console.warn("[WhatsApp] OPENWA_WEBHOOK_SECRET not set, skipping signature verification");
    return true;
  }

  // If secret is configured, signature is required
  if (!signature) {
    console.warn("[WhatsApp] Signature missing but OPENWA_WEBHOOK_SECRET is set");
    return false;
  }

  try {
    const crypto = require("crypto");
    const hash = crypto.createHmac("sha256", secret).update(body).digest("hex");

    return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(hash));
  } catch (error) {
    console.error("[WhatsApp] Webhook verification error:", error);
    return false;
  }
}

/**
 * [ID] Handle incoming message dari OpenWA webhook
 * [EN] Handle incoming message from OpenWA webhook
 *
 * OpenWA webhook payload format bervariasi tergantung versi & config:
 * Format 1: { message: { from: "...", body: "..." } }
 * Format 2: { data: { key: { remoteJid: "..." }, message: { conversation: "..." } } }
 * Format 3: { data: { from: "...", body: "..." } }
 * Format 4: { messages: [{ from: "...", body: "..." }] }
 */
export async function handleIncomingMessage(body: any): Promise<{
  ok: boolean;
  chatId?: string;
  text?: string;
}> {
  // [ID] Log raw body untuk debugging
  // [WHY] Format payload OpenWA bisa berbeda-beda, perlu lihat aslinya
  console.log("[WhatsApp] Raw webhook payload:", JSON.stringify(body).slice(0, 500));

  let chatId: string | undefined;
  let text: string | undefined;

  // Format 1: { message: { from: "...", body: "..." } }
  if (body?.message?.from && body?.message?.body) {
    chatId = body.message.from;
    text = String(body.message.body).trim();
    console.log("[WhatsApp] Parsed Format 1:", { chatId, text });
  }
  // Format 2: { data: { key: { remoteJid }, message: { conversation } } }
  else if (body?.data?.key?.remoteJid && body?.data?.message?.conversation) {
    chatId = body.data.key.remoteJid;
    text = String(body.data.message.conversation).trim();
    console.log("[WhatsApp] Parsed Format 2:", { chatId, text });
  }
  // Format 3: { data: { from: "...", body: "..." } }
  else if (body?.data?.from && body?.data?.body) {
    chatId = body.data.from;
    text = String(body.data.body).trim();
    console.log("[WhatsApp] Parsed Format 3:", { chatId, text });
  }
  // Format 4: { messages: [{ from: "...", body: "..." }] }
  else if (body?.messages?.[0]?.from && body?.messages?.[0]?.body) {
    chatId = body.messages[0].from;
    text = String(body.messages[0].body).trim();
    console.log("[WhatsApp] Parsed Format 4:", { chatId, text });
  }
  // Unknown format — log struktur untuk debug
  else {
    console.warn("[WhatsApp] Unknown payload format. Top-level keys:", Object.keys(body || {}));
    return { ok: false };
  }

  return { ok: true, chatId, text };
}
