import { Elysia, t } from "elysia";
import { authPlugin } from "../../core/middlewares/auth";
import { prisma } from "../../core/db";
import { BotService } from "./bot.service";


/**
 * [ID] Router untuk sinkronisasi akun dengan bot Telegram/WhatsApp (Deep Linking).
 *
 * [EN] Router for account synchronization with Telegram/WhatsApp bot (Deep Linking).
 */
export const botRoutes = new Elysia({ prefix: "/bot" })
  // [ID] Route untuk generate OTP token link (User Auth)
  .use(authPlugin)
  .get(
    "/link",
    async ({ userId, set }) => {
      try {
        // [ID] Pastikan data user ada di tabel users publik
        let user = await prisma.user.findUnique({
          where: { id: userId! },
        });

        if (!user) {
          user = await prisma.user.create({
            data: {
              id: userId!,
              name: "Pengguna Glico",
            },
          });
        }

        // [ID] Generate OTP Token unik (6 digit angka acak)
        const token = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 menit kedaluwarsa

        // [ID] Bersihkan token lama milik user ini agar tidak menumpuk
        await prisma.botLinkToken.deleteMany({
          where: { user_id: userId! },
        });

        // [ID] Simpan token baru ke database
        await prisma.botLinkToken.create({
          data: {
            user_id: userId!,
            token: token,
            expires_at: expiresAt,
          },
        });

        // [ID] Ambil nama bot Telegram dari env, default: GlicoBot
        const botUsername = process.env.TELEGRAM_BOT_USERNAME || "GlicoBot";
        const telegramLink = `https://t.me/${botUsername}?start=${token}`;

        return {
          token,
          expiresAt: expiresAt.toISOString(),
          telegramLink,
        };
      } catch (err) {
        console.error("Error generating bot link token:", err);
        set.status = 500;
        return { message: "Internal server error during link generation" };
      }
    },
    {
      isAuth: true,
      detail: {
        tags: ["bot"],
        summary: "Generate a secure temporary OTP token for Telegram bot linking",
      },
    }
  )
  // [ID] Route untuk verifikasi token (Internal/Admin n8n saja)
  .post(
    "/verify",
    async ({ body, headers, set }) => {
      try {
        // [ID] Validasi API Key Admin untuk keamanan
        const adminApiKey = process.env.BACKEND_ADMIN_API_KEY || "dev-admin-key";
        const requestApiKey = headers["x-api-key"];

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
          await prisma.botLinkToken.delete({ where: { id: linkToken.id } });
          set.status = 400;
          return { message: "Token has expired" };
        }

        // [ID] Hubungkan user ke chat bot dengan memperbarui phone_number (diisi chat ID / phone)
        await prisma.user.update({
          where: { id: linkToken.user_id },
          data: {
            phone_number: body.identifier,
          },
        });

        // [ID] Hapus token karena sudah digunakan
        await prisma.botLinkToken.delete({
          where: { id: linkToken.id },
        });

        return {
          message: "Account successfully linked to bot",
          userId: linkToken.user_id,
          name: linkToken.user.name,
        };
      } catch (err) {
        console.error("Error verifying bot link token:", err);
        set.status = 500;
        return { message: "Internal server error during token verification" };
      }
    },
    {
      body: t.Object({
        token: t.String(),
        identifier: t.String(), // Dapat berupa Chat ID Telegram atau Phone Number WhatsApp
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
  // [ID] Webhook Telegram Bot untuk menerima pesan update dari Telegram
  .post(
    "/webhook",
    async ({ body, set }) => {
      try {
        // Jalankan secara asinkronus (non-blocking) agar segera membalas 200 OK ke Telegram
        BotService.handleTelegramWebhook(body).catch((err) => {
          console.error("[WEBHOOK] Gagal memproses update webhook Telegram:", err);
        });
        return { ok: true };
      } catch (err) {
        console.error("[WEBHOOK] Error di endpoint webhook Telegram:", err);
        set.status = 500;
        return { error: "Failed to receive webhook" };
      }
    },
    {
      detail: {
        tags: ["bot"],
        summary: "Telegram Bot Webhook receiver (Internal/Telegram only)",
      },
    }
  );

