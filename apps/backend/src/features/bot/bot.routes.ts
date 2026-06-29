import { Elysia, t } from "elysia";
import { rateLimit } from "elysia-rate-limit";
import { authPlugin, isAuthenticated } from "../../core/middlewares/auth";
import { prisma } from "../../core/db";
import { BotService } from "./bot.service";
import {
  sendWhatsAppMessage,
  formatChatId,
  handleIncomingMessage,
  verifyWebhookSignature,
} from "./whatsapp.service";

// [ID] Type guard: validasi platform yang didukung
// [EN] Type guard: validate supported platforms
const SUPPORTED_PLATFORMS = ["telegram", "whatsapp"] as const;
type BotPlatform = (typeof SUPPORTED_PLATFORMS)[number];

function isValidPlatform(p: string): p is BotPlatform {
  return SUPPORTED_PLATFORMS.includes(p as BotPlatform);
}

function toEnum(p: BotPlatform): "TELEGRAM" | "WHATSAPP" {
  return p === "telegram" ? "TELEGRAM" : "WHATSAPP";
}

/**
 * [ID] Router untuk sinkronisasi akun dengan bot Telegram/WhatsApp (Deep Linking).
 *
 * [EN] Router for account synchronization with Telegram/WhatsApp bot (Deep Linking).
 */
export const botRoutes = new Elysia({ prefix: "/bot" })
  // [ID] Route untuk generate OTP token link (User Auth)
  .use(authPlugin)
  .use(
    rateLimit({
      duration: 60_000,
      max: 20,
      generator: (request) => {
        return (
          request.headers.get("x-forwarded-for") || request.headers.get("x-real-ip") || "unknown"
        );
      },
    })
  )
  .get(
    "/link",
    async ({ userId, query, set }) => {
      try {
        const platform = query.platform?.toLowerCase() ?? "telegram";

        // [ID] Validasi platform
        if (!isValidPlatform(platform)) {
          set.status = 400;
          return {
            error: "Invalid platform",
            message: 'Platform must be "telegram" or "whatsapp"',
          };
        }

        // [ID] Pastikan data user ada di tabel users publik
        let user = await prisma.user.findUnique({
          where: { id: userId! },
        });

        if (!user) {
          user = await prisma.user.create({
            data: {
              id: userId!,
              name: "Pengguna Glicoo",
            },
          });
        }

        // [EXCLUSIVE CONNECTION] Cek apakah user sudah connect ke platform LAIN
        if (user.bot_platform && user.bot_platform !== toEnum(platform)) {
          set.status = 409;
          return {
            error: "Already connected to another platform",
            connectedPlatform: user.bot_platform.toLowerCase(),
            message:
              user.bot_platform === "TELEGRAM"
                ? "Kamu sudah terhubung ke Telegram. Putuskan koneksi dulu jika ingin pindah ke WhatsApp."
                : "Kamu sudah terhubung ke WhatsApp. Putuskan koneksi dulu jika ingin pindah ke Telegram.",
          };
        }

        // [ID] Generate OTP Token unik (6 digit angka acak)
        const token = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 menit kedaluwarsa

        // [ID] Bersihkan token lama milik user ini agar tidak menumpuk
        await prisma.botLinkToken.deleteMany({
          where: { user_id: userId! },
        });

        // [ID] Simpan token baru ke database dengan platform target
        await prisma.botLinkToken.create({
          data: {
            user_id: userId!,
            token: token,
            platform: toEnum(platform),
            expires_at: expiresAt,
          },
        });

        // [ID] Siapkan instruksi sesuai platform
        const botUsername = process.env.TELEGRAM_BOT_USERNAME || "GlicoBot";
        const whatsappNumber = process.env.WHATSAPP_BOT_NUMBER || "";

        const instructions =
          platform === "telegram"
            ? `Kirim /start ${token} ke @${botUsername} di Telegram`
            : `Kirim pesan "OTP ${token}" ke WhatsApp ${whatsappNumber}`;

        return {
          token,
          platform,
          expiresAt: expiresAt.toISOString(),
          instructions,
          telegramLink:
            platform === "telegram" ? `https://t.me/${botUsername}?start=${token}` : undefined,
        };
      } catch (err) {
        console.error("Error generating bot link token:", err);
        set.status = 500;
        return { message: "Internal server error during link generation" };
      }
    },
    {
      beforeHandle: isAuthenticated,
      query: t.Object({
        platform: t.Optional(t.String()),
      }),
      detail: {
        tags: ["bot"],
        summary: "Generate a secure temporary OTP token for Telegram/WhatsApp bot linking",
      },
    }
  )
  // [ID] Route untuk verifikasi token (Internal/Admin n8n saja)
  .post(
    "/verify",
    async ({ body, headers, set }) => {
      try {
        // [SECURITY] Admin key MUST be set in env. No hardcoded fallback.
        const adminApiKey = process.env.BACKEND_ADMIN_API_KEY;
        const requestApiKey = headers["x-api-key"];

        if (!adminApiKey) {
          set.status = 503;
          return {
            message: "Admin endpoint unavailable: server misconfiguration",
          };
        }

        if (!requestApiKey || requestApiKey !== adminApiKey) {
          set.status = 401;
          return { message: "Unauthorized: Invalid admin API Key" };
        }

        // [ID] Cari token verifikasi di DB
        const linkToken = await prisma.botLinkToken.findUnique({
          where: { token: body.token },
          include: { user: true },
        });

        if (!linkToken) {
          set.status = 400;
          return { message: "Invalid verification token" };
        }

        if (linkToken.expires_at < new Date()) {
          // [ID] Hapus token jika sudah kedaluwarsa
          await prisma.botLinkToken.delete({
            where: { id: linkToken.id },
          });
          set.status = 400;
          return { message: "Token has expired" };
        }

        // [ID] Hubungkan user ke bot dengan menyimpan chat_id dan platform
        await prisma.user.update({
          where: { id: linkToken.user_id },
          data: {
            phone_number: body.identifier, // backward compat
            bot_chat_id: body.identifier,
            bot_platform: linkToken.platform,
          },
        });

        // [ID] Hapus token karena sudah digunakan
        await prisma.botLinkToken.delete({
          where: { id: linkToken.id },
        });

        return {
          message: "Account successfully linked to bot",
          userId: linkToken.user_id,
          platform: linkToken.platform.toLowerCase(),
          name: linkToken.user.name,
        };
      } catch (err) {
        console.error("Error verifying bot link token:", err);
        set.status = 500;
        return {
          message: "Internal server error during token verification",
        };
      }
    },
    {
      body: t.Object({
        token: t.String(),
        identifier: t.String(), // Chat ID Telegram atau Phone WhatsApp
      }),
      headers: t.Object({
        "x-api-key": t.String(),
      }),
      detail: {
        tags: ["bot"],
        summary: "Verify OTP token and link user to Telegram/WhatsApp identifier (Internal)",
      },
    }
  )
  // [ID] Route untuk memutuskan koneksi bot dari akun pengguna
  .delete(
    "/disconnect",
    async ({ userId, set }) => {
      try {
        const user = await prisma.user.findUnique({
          where: { id: userId! },
        });

        if (!user) {
          set.status = 404;
          return { message: "User not found" };
        }

        if (!user.bot_platform) {
          set.status = 400;
          return {
            message: "Bot is not currently linked to this account",
          };
        }

        const disconnectedPlatform = user.bot_platform.toLowerCase();

        // [ID] Hapus semua field bot untuk memutuskan koneksi
        await prisma.user.update({
          where: { id: userId! },
          data: {
            phone_number: null,
            bot_platform: null,
            bot_chat_id: null,
          },
        });

        return {
          message: `Bot successfully disconnected from account`,
          platform: disconnectedPlatform,
        };
      } catch (err) {
        console.error("Error disconnecting bot:", err);
        set.status = 500;
        return {
          message: "Internal server error during bot disconnect",
        };
      }
    },
    {
      isAuth: true,
      detail: {
        tags: ["bot"],
        summary: "Disconnect Telegram/WhatsApp bot from user account",
      },
    }
  )
  // [ID] Webhook Telegram Bot untuk menerima pesan update dari Telegram
  .post(
    "/webhook",
    async ({ body, set }) => {
      try {
        // [WHY] Tidak menggunakan fire-and-forget (.catch()) karena di Vercel Fluid Compute,
        // function bisa di-freeze setelah response dikirim sebelum async task selesai.
        // Telegram mentoleransi tunggu hingga 60 detik — AI kita ~5-20 detik, aman.
        await BotService.handleTelegramWebhook(body);
        return { ok: true };
      } catch (err) {
        console.error("[WEBHOOK] Error di endpoint webhook Telegram:", err);
        set.status = 500;
        return { error: "Failed to process webhook" };
      }
    },
    {
      detail: {
        tags: ["bot"],
        summary: "Telegram Bot Webhook receiver (Internal/Telegram only)",
      },
    }
  )
  // [ID] Webhook WhatsApp Bot untuk menerima pesan dari OpenWA
  .post(
    "/webhook/whatsapp",
    async ({ body, headers, set }) => {
      try {
        // [WHY] Webhook signature verification prevents fake requests
        const signature = headers["x-openwa-signature"];
        const rawBody = JSON.stringify(body);

        if (!verifyWebhookSignature(signature, rawBody)) {
          set.status = 401;
          return { error: "Invalid webhook signature" };
        }

        // [ID] Parse incoming message
        const result = await handleIncomingMessage(body);
        if (!result.ok || !result.chatId || !result.text) {
          return { ok: true }; // Ignore non-text messages
        }

        const { chatId, text } = result;

        // [ID] Cek apakah ini OTP verification
        const otpMatch = text.match(/^OTP\s*(\d{6})$/i);
        if (otpMatch) {
          const token = otpMatch[1];
          const linkToken = await prisma.botLinkToken.findUnique({
            where: { token },
            include: { user: true },
          });

          if (!linkToken) {
            await sendWhatsAppMessage(
              chatId,
              "❌ Token tidak valid atau sudah kedaluwarsa. Generate token baru di aplikasi Glicoo."
            );
            return { ok: true };
          }

          // [WHY] Tidak perlu cek platform - biarkan user pilih platform yang mana saat kirim OTP
          // Token yang sama bisa digunakan untuk Telegram atau WhatsApp (yang kirim duluan menang)

          if (linkToken.expires_at < new Date()) {
            await prisma.botLinkToken.delete({
              where: { id: linkToken.id },
            });
            await sendWhatsAppMessage(
              chatId,
              "❌ Token sudah kedaluwarsa. Generate token baru di aplikasi Glicoo."
            );
            return { ok: true };
          }

          // [ID] Connect user to WhatsApp
          await prisma.user.update({
            where: { id: linkToken.user_id },
            data: {
              phone_number: chatId.replace(/@c\.us$/, ""), // backward compat
              bot_chat_id: chatId,
              bot_platform: "WHATSAPP",
            },
          });

          await prisma.botLinkToken.delete({
            where: { id: linkToken.id },
          });

          await sendWhatsAppMessage(
            chatId,
            "✅ *Selamat! Akun Glicoo berhasil terhubung dengan WhatsApp.*\n\nKamu akan menerima:\n- 📊 Pengingat pengisian data harian\n- 🏃 Tips aktivitas fisik\n- 🍎 Saran pola makan\n- 💤 Pengingat tidur\n\nGunakan /help untuk bantuan."
          );

          return { ok: true };
        }

        // [ID] Handle regular chat messages (AI processing)
        // Delegate to BotService for AI response & food logging
        await BotService.handleWhatsAppMessage(chatId, text);

        return { ok: true };
      } catch (err) {
        console.error("[WEBHOOK] Error di endpoint webhook WhatsApp:", err);
        set.status = 500;
        return { error: "Failed to process webhook" };
      }
    },
    {
      detail: {
        tags: ["bot"],
        summary: "WhatsApp Bot Webhook receiver (Internal/OpenWA only)",
      },
    }
  );
