import { prisma } from "../../core/db";
import { aiService } from "../ai/ai.service";

/**
 * Interval refresh typing indicator Telegram.
 * [WHY] Telegram men-expire chat action "typing" setelah ~5 detik. Agar bot tidak
 * terlihat diam (offline) selama AI Gemini bekerja (8-15 detik), indikator di-refresh
 * setiap 4 detik sampai balasan benar-benar terkirim.
 */
const TYPING_REFRESH_INTERVAL_MS = 4000;

/** Pesan ack instan saat bot menerima pesan non-perintah (kontrak API_CONTRACTS.md §3). */
const PROCESSING_ACK_MESSAGE = "Hmm menarik, wait ya aku hitung dulu ⏳";

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
   * Mengirim satu Telegram chat action (mis. 'typing') ke chat tertentu.
   * Helper terpisah agar tidak menumpuk fetch promise yang unhandled.
   *
   * [EN]
   * Sends a single Telegram chat action (e.g. 'typing') to a given chat.
   */
  static async sendChatAction(chatId: string, action: 'typing' | 'upload_photo' | 'upload_document' = 'typing'): Promise<void> {
    const botToken = process.env.TELEGRAM_BOT_TOKEN;
    if (!botToken) return;
    try {
      await fetch(`https://api.telegram.org/bot${botToken}/sendChatAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ chat_id: chatId, action }),
      });
    } catch {
      // Typing action bersifat best-effort; kegagalan tidak boleh menggagalkan flow utama
    }
  }

  /**
   * [ID]
   * Menjaga indikator "typing" Telegram tetap hidup selama `task` berjalan.
   *
   * Telegram men-expire typing indicator dalam 5 detik, sehingga AI yang lambat
   * terlihat seperti offline. Helper ini me-refresh action setiap 4 detik
   * (TYPING_REFRESH_INTERVAL_MS) sampai task selesai, lalu otomatis berhenti.
   *
   * [EN]
   * Keeps the Telegram "typing" indicator alive while `task` is running by
   * re-sending the chat action on a short interval until the task settles.
   */
  static keepTypingWhile<T>(chatId: string, task: Promise<T>): Promise<T> {
    // [TRADEOFF] refresh 4 detik < expiry 5 detik Telegram → indikator never gaps
    this.sendChatAction(chatId, 'typing');
    const interval = setInterval(() => this.sendChatAction(chatId, 'typing'), TYPING_REFRESH_INTERVAL_MS);
    return task.finally(() => clearInterval(interval));
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
          'Selamat datang di Glicoo Bot! 🤖\n\nUntuk menghubungkan akun Anda, silakan buka menu *Bot Hub* di aplikasi Glicoo Anda dan ikuti panduannya.'
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
          'Maaf Kak, token OTP tidak valid. Silakan generate ulang token di aplikasi Glicoo. ❌'
        );
        return;
      }

      if (linkToken.expires_at < new Date()) {
        await prisma.botLinkToken.delete({ where: { id: linkToken.id } });
        await this.sendTelegramMessage(
          chatId,
          'Maaf Kak, token OTP sudah kedaluwarsa. Silakan ambil token baru di aplikasi Glicoo. ❌'
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
        `Selamat Kak *${linkToken.user.name}*! 🎉\n\nAkun Glicoo kamu berhasil terhubung dengan Telegram. Mulai sekarang, Iloo akan memantau gizi makanan dan kesehatan harianmu secara interaktif. Cobain ketik apa saja yang kamu makan sekarang! 🥗`
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
        'Akun Telegram kamu belum terhubung dengan aplikasi Glicoo. Silakan hubungkan terlebih dahulu di menu *Bot Hub* di dalam aplikasi Glicoo ya! 🔗'
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

    // [ID] Kirim chat action 'typing' di awal agar user langsung tahu bot aktif merespon,
    // lalu jaga agar tetap aktif selama pemrosesan AI (via keepTypingWhile).
    await this.sendChatAction(chatId, 'typing');

    // Ambil riwayat percakapan sebelumnya untuk memberikan konteks ke AI
    const recentChats = await prisma.interventionChat.findMany({
      where: { user_id: user.id },
      orderBy: { created_at: 'desc' },
      take: 7, // Ambil 7 pesan terakhir termasuk yang baru saja disimpan
    });

    recentChats.reverse();

    const formattedHistory = recentChats.map(c => {
      const role = c.sender_type === 'USER' ? 'Pengguna' : 'Iloo';
      return `${role}: ${c.message}`;
    }).join('\n');

    // Prompt AI untuk membedakan makanan vs obrolan biasa
    const schema = {
      type: 'object',
      properties: {
        is_food: {
          type: 'boolean',
          description: 'Apakah pesan terakhir ini menceritakan atau menanyakan tentang aktivitas makan/minum/kalori/gizi pengguna?'
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
      Kamu adalah Iloo, sahabat virtual pendeteksi risiko Diabetes Tipe 2 di aplikasi Glicoo.
      Gaya bahasamu santai, menggunakan bahasa Indonesia sehari-hari ("Kamu", "Kak"), dan lengkapi dengan sedikit emoji. Jangan menggurui atau menggunakan bahasa medis kaku.
      Tugasmu adalah membalas pesan pengguna berdasarkan riwayat chat yang diberikan.
      Jika jumlah makanan/porsi yang dimasukkan tidak wajar atau sangat berlebihan (seperti makan nasi 3kg, makan ikan 10 ekor sekaligus, minum sirup seember, dll.), tanggapilah dengan humor, candaan santai, atau rasa terkejut yang lucu khas sahabat dekat (misalnya: "Ini makan porsi satu RT atau gimana Kak? 😂") sebelum memberikan estimasi angka kalori/gula yang fantastis tersebut secara logis.
      Jika pesan terakhir dari Pengguna menanyakan atau mengacu pada deskripsi makanan/minuman sebelumnya, jawablah pertanyaannya sesuai konteks dan tentukan nilai gizi/kalori/gula yang sesuai.
      Jika pesan terakhir berupa deskripsi makanan/minuman, estimasikan kalori (kcal), estimasikan kandungan gula (gram), dan buatlah feedback bersahabat maksimal 2-3 kalimat yang memotivasi mereka untuk bergerak aktif jika makanan tinggi kalori/gula.
      Jika pesan terakhir tidak terkait makanan/minuman, balaslah seperti sahabat yang peduli kesehatan mereka dan tetapkan is_food = false, serta estimated_calories = null dan estimated_sugar_grams = null.
    `;

    const prompt = `Berikut adalah riwayat percakapan terakhir:\n${formattedHistory}\n\nAnalisis pesan terakhir dari Pengguna dan tentukan nilai JSON yang sesuai berdasarkan riwayat tersebut.`;

    try {
      // [ID] Bungkus pemanggilan AI dengan typing indicator agar bot terus aktif
      // terlihat selama pemrosesan (mencegah kesan "offline").
      const aiResponse = await this.keepTypingWhile(
        chatId,
        aiService.generateJSON<{
          is_food: boolean;
          estimated_calories: number | null;
          estimated_sugar_grams: number | null;
          ai_feedback: string;
        }>(prompt, schema, systemInstruction),
      );

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
