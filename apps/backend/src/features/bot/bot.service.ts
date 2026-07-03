/**
 * Purpose:
 * → Orkestrasi webhook Telegram dan WhatsApp — routing pesan masuk ke
 *    BotAuthService (OTP) atau BotMessageService (AI chat).
 *
 * Used By:
 * → bot.routes.ts
 *
 * Depends On:
 * → TelegramService, BotAuthService, BotMessageService, whatsapp.service, prisma
 *
 * Impact:
 * → Semua alur percakapan bot Telegram & WhatsApp.
 */

import { prisma } from "../../core/db";

import { TelegramService } from "./telegram.service";
import { BotAuthService } from "./bot-auth.service";
import { BotMessageService } from "./bot-message.service";

/**
 * [WHY] In-memory lock untuk mencegah duplikasi balasan akibat retry webhook Telegram.
 * Telegram mengirim ulang webhook jika tidak mendapat respon 200 dalam 5 detik.
 * Lock di-clear di blok `finally` agar tidak ada deadlock.
 */
const processingChats = new Set<string>();

export class BotService {
  /**
   * [ID]
   * Meng-handle update webhook dari Telegram. Routing: OTP → verifikasi akun,
   * teks biasa → AI chat.
   *
   * [EN]
   * Handles Telegram webhook updates. Routes: OTP → account verification,
   * plain text → AI chat.
   */
  static async handleTelegramWebhook(update: any): Promise<void> {
    if (!update.message || !update.message.text) return;

    const chatId = update.message.chat.id.toString();
    const text = update.message.text.trim();
    const username = update.message.from?.username || update.message.from?.first_name || "User";

    if (processingChats.has(chatId)) {
      console.log(`[BOT] User ${chatId} masih diproses. Mengabaikan retry Telegram.`);
      return;
    }
    processingChats.add(chatId);

    try {
      if (text.startsWith("/start")) {
        await TelegramService.sendMessage(
          chatId,
          "Halo! Aku Iloo, asisten kesehatan pribadimu dari Glico. \n\n" +
            "Untuk menghubungkan aplikasi Glico dengan Telegram ini, silakan masukkan *6 digit kode OTP* " +
            "yang ada di menu profil aplikasi Glico kamu ya!"
        );
        return;
      }

      if (/^\d{6}$/.test(text)) {
        const { success, user } = await BotAuthService.verifyToken(
          text,
          "telegram",
          chatId,
          username
        );
        if (success && user) {
          await TelegramService.sendMessage(
            chatId,
            `Berhasil! ✅\n\nAkun Glico kamu (${user.name}) sudah terhubung. Aku siap menemani pola makan sehatmu!`
          );
        } else {
          await TelegramService.sendMessage(chatId, "Kode OTP tidak valid atau kedaluwarsa ❌.");
        }
        return;
      }

      const activeUser = await prisma.user.findFirst({
        where: { bot_platform: "TELEGRAM", bot_chat_id: chatId },
      });

      if (!activeUser) {
        await TelegramService.sendMessage(
          chatId,
          "Maaf, akun belum terhubung. Ketik 6 digit OTP Glico."
        );
        return;
      }

      const aiResponsePromise = BotMessageService.processAndReplyMessage(activeUser, text);
      const reply = await TelegramService.keepTypingWhile(chatId, aiResponsePromise);
      await TelegramService.sendMessage(chatId, reply);
    } catch (error) {
      console.error("[BOT] Telegram error:", error);
      await TelegramService.sendMessage(chatId, "Waduh, Iloo lagi pusing nih... Coba lagi ya!");
    } finally {
      processingChats.delete(chatId);
    }
  }

  /**
   * [ID]
   * Meng-handle pesan masuk dari WhatsApp. Routing: OTP → verifikasi akun,
   * teks biasa → AI chat.
   *
   * [EN]
   * Handles incoming WhatsApp messages. Routes: OTP → account verification,
   * plain text → AI chat.
   */
  static async handleWhatsAppMessage(chatId: string, text: string): Promise<void> {
    const cleanText = text.trim();

    if (processingChats.has(chatId)) {
      return;
    }
    processingChats.add(chatId);

    try {
      const { sendWhatsAppMessage, sendTypingIndicator } = await import("./whatsapp.service");

      if (/^\d{6}$/.test(cleanText)) {
        const { success, user } = await BotAuthService.verifyToken(cleanText, "whatsapp", chatId);
        if (success && user) {
          await sendWhatsAppMessage(
            chatId,
            `Berhasil! ✅\n\nAkun Glico kamu (${user.name}) sudah terhubung. Aku siap menemani pola makan sehatmu!`
          );
        } else {
          await sendWhatsAppMessage(chatId, "Kode OTP tidak valid atau kedaluwarsa ❌.");
        }
        return;
      }

      const activeUser = await prisma.user.findFirst({
        where: { bot_platform: "WHATSAPP", bot_chat_id: chatId },
      });

      if (!activeUser) {
        await sendWhatsAppMessage(
          chatId,
          "Maaf, WhatsApp kamu belum terhubung. Kirim 6 digit OTP Glico."
        );
        return;
      }

      const TYPING_REFRESH_MS = 4000;
      sendTypingIndicator(chatId).catch(console.error);
      const typingInterval = setInterval(
        () => sendTypingIndicator(chatId).catch(console.error),
        TYPING_REFRESH_MS
      );

      try {
        const reply = await BotMessageService.processAndReplyMessage(activeUser, cleanText);
        await sendWhatsAppMessage(chatId, reply);
      } finally {
        clearInterval(typingInterval);
      }
    } catch (error) {
      console.error("[BOT] WhatsApp error:", error);
      const { sendWhatsAppMessage } = await import("./whatsapp.service");
      await sendWhatsAppMessage(chatId, "Waduh, Iloo lagi pusing nih... Coba lagi nanti ya!");
    } finally {
      processingChats.delete(chatId);
    }
  }
}
