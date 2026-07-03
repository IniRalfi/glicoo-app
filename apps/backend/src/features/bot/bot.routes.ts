/**
 * Purpose:
 * → Router HTTP untuk koneksi bot (Telegram/WA) dan penerimaan webhook.
 *
 * Used By:
 * → index.ts (app entry)
 *
 * Depends On:
 * → BotAuthService, BotService
 *
 * Impact:
 * → Semua endpoint /bot — koneksi, verifikasi, disconnect, webhook Telegram & WA.
 */
import { Elysia, t } from "elysia";
import { rateLimit } from "elysia-rate-limit";

import { authPlugin, isAuthenticated } from "../../core/middlewares/auth";
import { BotAuthService } from "./bot-auth.service";
import { BotService } from "./bot.service";

/**
 * [ID] Router untuk sinkronisasi akun dengan bot Telegram/WhatsApp (Deep Linking).
 *
 * [EN] Router for account synchronization with Telegram/WhatsApp bot (Deep Linking).
 */
export const botRoutes = new Elysia({ prefix: "/bot" })
  .use(authPlugin)
  .use(
    rateLimit({
      duration: 60_000,
      max: 20,
      generator: (request) =>
        request.headers.get("x-forwarded-for") || request.headers.get("x-real-ip") || "unknown",
    })
  )

  // [ID] Ambil status koneksi bot; generate token jika belum terhubung
  // [EN] Get bot connection status; generate token if not yet linked
  .get(
    "/connection",
    async ({ userId, query, set }) => {
      try {
        const platform = query.target === "telegram" ? "telegram" : "whatsapp";
        const data = await BotAuthService.getConnectionData(userId!, platform);
        return { status: "success", data };
      } catch {
        set.status = 500;
        return { status: "error", message: "Gagal mengambil kode OTP untuk bot." };
      }
    },
    {
      beforeHandle: isAuthenticated,
      detail: { summary: "Dapatkan Kode OTP Bot", tags: ["Bot"], security: [{ bearerAuth: [] }] },
      query: t.Optional(t.Object({ target: t.Optional(t.String()) })),
    }
  )

  // [ID] Verifikasi token OTP dari bot — hubungkan akun user ke platform bot
  // [EN] Verify OTP token from bot — link user account to bot platform
  .post(
    "/verify",
    async ({ body, set }) => {
      try {
        const { success, user } = await BotAuthService.verifyToken(
          body.token,
          body.platform,
          body.platformId,
          body.username
        );

        if (!success || !user) {
          set.status = 400;
          return { status: "error", message: "Token tidak valid atau sudah kedaluwarsa." };
        }

        return {
          status: "success",
          message: "Berhasil terhubung dengan bot.",
          data: { userId: user.id, name: user.name },
        };
      } catch {
        set.status = 500;
        return { status: "error", message: "Gagal memverifikasi token." };
      }
    },
    {
      body: t.Object({
        token: t.String(),
        platform: t.Union([t.Literal("telegram"), t.Literal("whatsapp")]),
        platformId: t.String(),
        username: t.Optional(t.String()),
      }),
      detail: { summary: "Verifikasi OTP Bot", tags: ["Bot Webhook"] },
    }
  )

  // [ID] Putus koneksi bot untuk user yang sedang login
  // [EN] Disconnect bot for the currently authenticated user
  .delete(
    "/disconnect",
    async ({ userId, set }) => {
      try {
        await BotAuthService.disconnectUser(userId!);
        return { status: "success", message: "Berhasil memutus koneksi dengan bot." };
      } catch {
        set.status = 500;
        return { status: "error", message: "Gagal memutus koneksi bot." };
      }
    },
    {
      beforeHandle: isAuthenticated,
      detail: { summary: "Putus Koneksi Bot", tags: ["Bot"], security: [{ bearerAuth: [] }] },
    }
  )

  // [ID] Webhook Telegram — terima update pesan dari Telegram API
  // [EN] Telegram webhook — receive message updates from Telegram API
  .post(
    "/webhook",
    async ({ body, set }) => {
      try {
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
        summary: "Telegram Webhook Endpoint",
        description: "Receives messages and updates directly from Telegram API.",
      },
    }
  )

  // [ID] Webhook WhatsApp — terima pesan dari OpenWA
  // [EN] WhatsApp webhook — receive messages from OpenWA
  .post(
    "/webhook/whatsapp",
    async ({ body, headers, set }) => {
      try {
        const waAuthToken = process.env.WHATSAPP_WEBHOOK_SECRET;
        if (waAuthToken && headers["authorization"] !== `Bearer ${waAuthToken}`) {
          set.status = 401;
          return { error: "Unauthorized webhook access" };
        }

        const data: any = body;

        // [WHY] Log raw payload so we can diagnose OpenWA format mismatches
        console.log("[WA Webhook] raw payload:", JSON.stringify(data));

        // OpenWA can send either flat { chatId, text } or nested { messages: [...] }
        // Try flat first, then array envelope
        const chatId: string | undefined =
          data.chatId ??
          data.chat_id ??
          data.from ??
          data.messages?.[0]?.chatId ??
          data.messages?.[0]?.from;

        const text: string | undefined =
          data.text ??
          data.body ??
          data.content ??
          data.messages?.[0]?.text ??
          data.messages?.[0]?.body ??
          data.messages?.[0]?.content;

        if (chatId && text) {
          await BotService.handleWhatsAppMessage(chatId, text);
        } else {
          console.warn(
            "[WA Webhook] Could not extract chatId/text from payload:",
            JSON.stringify(data)
          );
        }

        return { ok: true };
      } catch (err) {
        console.error("[WEBHOOK] Error di endpoint webhook WhatsApp:", err);
        set.status = 500;
        return { error: "Failed to process WhatsApp webhook" };
      }
    },
    {
      body: t.Any(),
      detail: {
        tags: ["bot"],
        summary: "WhatsApp Webhook Endpoint",
        description: "Receives messages from WhatsApp via OpenWA.",
      },
    }
  );
