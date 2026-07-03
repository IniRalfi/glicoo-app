/**
 * Purpose:
 * → Mengelola interaksi HTTP langsung dengan Telegram Bot API.
 *
 * Used By:
 * → bot.service.ts, bot-auth.service.ts, scheduler.service.ts
 *
 * Depends On:
 * → node-fetch (built-in fetch)
 *
 * Impact:
 * → Pengiriman pesan proaktif dan chat action Telegram.
 */

/**
 * Interval refresh typing indicator Telegram.
 * [WHY] Telegram men-expire chat action "typing" setelah ~5 detik. Agar bot tidak
 * terlihat diam (offline) selama AI Gemini bekerja (8-15 detik), indikator di-refresh
 * setiap 4 detik sampai balasan benar-benar terkirim.
 */
const TYPING_REFRESH_INTERVAL_MS = 4000;

export class TelegramService {
  /**
   * [ID]
   * Mengirimkan pesan proaktif ke user di Telegram menggunakan Chat ID.
   *
   * [EN]
   * Sends a proactive message to a user on Telegram using Chat ID.
   */
  static async sendMessage(chatId: string, text: string): Promise<boolean> {
    const botToken = process.env.TELEGRAM_BOT_TOKEN;
    if (!botToken) {
      console.warn("[TELEGRAM] TELEGRAM_BOT_TOKEN is not configured. Cannot send message.");
      return false;
    }

    try {
      const response = await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          chat_id: chatId,
          text: text,
          parse_mode: "Markdown",
        }),
      });

      if (!response.ok) {
        console.error(`[TELEGRAM] API error: ${response.statusText} - ${await response.text()}`);
        return false;
      }
      return true;
    } catch (err) {
      console.error("[TELEGRAM] Failed to send message:", err);
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
  static async sendChatAction(
    chatId: string,
    action: "typing" | "upload_photo" | "upload_document" = "typing"
  ): Promise<void> {
    const botToken = process.env.TELEGRAM_BOT_TOKEN;
    if (!botToken) return;
    try {
      await fetch(`https://api.telegram.org/bot${botToken}/sendChatAction`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
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
   * [EN]
   * Keeps the Telegram "typing" indicator alive while `task` is running by
   * re-sending the chat action on a short interval until the task settles.
   */
  static keepTypingWhile<T>(chatId: string, task: Promise<T>): Promise<T> {
    // [TRADEOFF] refresh 4 detik < expiry 5 detik Telegram → indikator never gaps
    this.sendChatAction(chatId, "typing");
    const interval = setInterval(
      () => this.sendChatAction(chatId, "typing"),
      TYPING_REFRESH_INTERVAL_MS
    );
    return task.finally(() => clearInterval(interval));
  }
}
