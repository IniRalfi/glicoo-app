import { prisma } from "../../core/db";
import { aiService } from "../ai/ai.service";

/**
 * Purpose:
 * Layanan khusus untuk mengelola interaksi dengan Bot Telegram.
 * Menangani pengiriman pesan proaktif, webhook dari Telegram, verifikasi OTP,
 * serta parsing pesan chat dari Telegram (menyimpannya sebagai FoodLog atau percakapan biasa).
 *
 * Used By:
 * bot.routes.ts, food.routes.ts
 *
 * Depends On:
 * db.ts, ai.service.ts
 *
 * Impact:
 * Mengontrol seluruh alur komunikasi antara pengguna di Telegram dengan backend Glico.
 */

export class BotService {
  /**
   * [ID]
   * Mengirimkan pesan proaktif ke user di Telegram menggunakan Chat ID.
   *
   * [EN]
   * Sends a proactive message to a user on Telegram using Chat ID.
   */
  static async sendTelegramMessage(chatId: string, text: string): Promise<boolean> {
    const botToken = process.env.TELEGRAM_BOT_TOKEN;
    if (!botToken) {
      console.warn('[BOT] TELEGRAM_BOT_TOKEN is not configured. Cannot send message.');
      return false;
    }

    try {
      const response = await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          chat_id: chatId,
          text: text,
          parse_mode: 'Markdown',
        }),
      });

      if (!response.ok) {
        console.error(`[BOT] Telegram API error: ${response.statusText} - ${await response.text()}`);
        return false;
      }
      return true;
    } catch (err) {
      console.error('[BOT] Failed to send Telegram message:', err);
      return false;
    }
  }

  /**
   * [ID]
   * Memproses Telegram Webhook Update yang dikirim langsung dari server Telegram.
   *
   * [EN]
   * Processes Telegram Webhook Update sent directly from Telegram servers.
   */
  static async handleTelegramWebhook(update: any): Promise<void> {
    const message = update?.message;
    if (!message || !message.text || !message.chat?.id) {
      return;
    }

    const chatId = message.chat.id.toString();
    const text = message.text.trim();

    // 1. Tangani alur verifikasi token (/start <TOKEN>)
    if (text.startsWith('/start')) {
      const parts = text.split(' ');
      const token = parts[1]?.trim();

      if (!token) {
        await this.sendTelegramMessage(
          chatId,
          'Selamat datang di Glico Bot! 🤖\n\nUntuk menghubungkan akun Anda, silakan buka menu *Bot Hub* di aplikasi Glico Anda dan ikuti panduannya.'
        );
        return;
      }

      // Validasi token OTP di database
      const linkToken = await prisma.botLinkToken.findUnique({
        where: { token: token },
        include: { user: true },
      });

      if (!linkToken) {
        await this.sendTelegramMessage(
          chatId,
          'Maaf Kak, token OTP tidak valid. Silakan generate ulang token di aplikasi Glico. ❌'
        );
        return;
      }

      if (linkToken.expires_at < new Date()) {
        await prisma.botLinkToken.delete({ where: { id: linkToken.id } });
        await this.sendTelegramMessage(
          chatId,
          'Maaf Kak, token OTP sudah kedaluwarsa. Silakan ambil token baru di aplikasi Glico. ❌'
        );
        return;
      }

      // Hubungkan user dengan chat ID ini
      await prisma.user.update({
        where: { id: linkToken.user_id },
        data: { phone_number: chatId },
      });

      // Bersihkan token
      await prisma.botLinkToken.delete({ where: { id: linkToken.id } });

      await this.sendTelegramMessage(
        chatId,
        `Selamat Kak *${linkToken.user.name}*! 🎉\n\nAkun Glico kamu berhasil terhubung dengan Telegram. Mulai sekarang, Glico akan memantau gizi makanan dan kesehatan harianmu secara interaktif. Cobain ketik apa saja yang kamu makan sekarang! 🥗`
      );
      return;
    }

    // 2. Tangani chat percakapan umum & log makanan proaktif
    // Cari user berdasarkan chat ID (phone_number)
    const user = await prisma.user.findUnique({
      where: { phone_number: chatId },
    });

    if (!user) {
      await this.sendTelegramMessage(
        chatId,
        'Akun Telegram kamu belum terhubung dengan aplikasi Glico. Silakan hubungkan terlebih dahulu di menu *Bot Hub* di dalam aplikasi Glico ya! 🔗'
      );
      return;
    }

    // Simpan pesan dari User ke InterventionChat
    await prisma.interventionChat.create({
      data: {
        user_id: user.id,
        message: text,
        sender_type: 'USER',
        intervention_moment: 'MEAL_TIME',
      },
    });

    // Panggil bot untuk merespon secara asinkron (mengirim typing status terlebih dahulu)
    const botToken = process.env.TELEGRAM_BOT_TOKEN;
    if (botToken) {
      // Kirim typing action biar kerasa natural
      fetch(`https://api.telegram.org/bot${botToken}/sendChatAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ chat_id: chatId, action: 'typing' }),
      }).catch(() => {});
    }

    // Prompt AI untuk membedakan makanan vs obrolan biasa
    const schema = {
      type: 'object',
      properties: {
        is_food: {
          type: 'boolean',
          description: 'Apakah pesan ini menceritakan atau mencatat aktivitas makan/minum pengguna?'
        },
        estimated_calories: {
          type: 'integer',
          description: 'Estimasi kalori makanan (null jika bukan makanan)'
        },
        estimated_sugar_grams: {
          type: 'number',
          description: 'Estimasi kandungan gula makanan dalam gram (null jika bukan makanan)'
        },
        ai_feedback: {
          type: 'string',
          description: 'Pesan balasan ramah, Socratic, maksimal 2-3 kalimat, dan menyisipkan emoji.'
        }
      },
      required: ['is_food', 'estimated_calories', 'estimated_sugar_grams', 'ai_feedback']
    };

    const systemInstruction = `
      Kamu adalah Glico, sahabat virtual pendeteksi risiko Diabetes Tipe 2.
      Gaya bahasamu santai, menggunakan bahasa Indonesia sehari-hari ("Kamu", "Kak"), dan lengkapi dengan sedikit emoji. Jangan menggurui atau menggunakan bahasa medis kaku.
      Tugasmu adalah membalas pesan pengguna. Jika pesan tersebut berupa deskripsi makanan/minuman, estimasikan kalori (kcal), estimasikan kandungan gula (gram), dan buatlah feedback bersahabat maksimal 2-3 kalimat yang memotivasi mereka untuk bergerak aktif jika makanan tinggi kalori/gula.
      Jika bukan makanan, balaslah seperti sahabat yang peduli kesehatan mereka dan tetapkan is_food = false, serta estimated_calories = null dan estimated_sugar_grams = null.
    `;

    try {
      const aiResponse = await aiService.generateJSON<{
        is_food: boolean;
        estimated_calories: number | null;
        estimated_sugar_grams: number | null;
        ai_feedback: string;
      }>(text, schema, systemInstruction);

      // Jika menceritakan makanan, simpan ke database FoodLog agar sinkron dengan aplikasi Mobile!
      if (aiResponse.is_food) {
        await prisma.foodLog.create({
          data: {
            user_id: user.id,
            description: text,
            estimated_calories: aiResponse.estimated_calories,
            estimated_sugar_grams: aiResponse.estimated_sugar_grams,
            ai_feedback: aiResponse.ai_feedback,
          },
        });
      }

      // Simpan balasan AI ke database InterventionChat
      await prisma.interventionChat.create({
        data: {
          user_id: user.id,
          message: aiResponse.ai_feedback,
          sender_type: 'AI_AGENT',
          intervention_moment: aiResponse.is_food ? 'MEAL_TIME' : 'NONE',
        },
      });

      // Kirim balik ke Telegram
      await this.sendTelegramMessage(chatId, aiResponse.ai_feedback);
    } catch (err) {
      console.error('[BOT] Gagal memproses respon AI:', err);
      await this.sendTelegramMessage(
        chatId,
        'Maaf Kak, aku lagi pusing nih (gangguan koneksi AI). Nanti chat aku lagi ya! ⏳'
      );
    }
  }
}
