import { Cron } from "croner";
import { prisma } from "../../core/db";
import { BotService } from "./bot.service";
import { sendWhatsAppMessage } from "./whatsapp.service";

/**
 * [ID] Kirim reminder ke user via platform yang terhubung
 * [EN] Send reminder to user via connected platform
 */
async function sendMessageToUser(
  chatId: string,
  platform: "TELEGRAM" | "WHATSAPP" | null | undefined,
  message: string
): Promise<void> {
  if (!chatId || !platform) {
    console.warn(`[SCHEDULER] User has no connected platform, skipping`);
    return;
  }

  if (platform === "TELEGRAM") {
    await BotService.sendTelegramMessage(chatId, message);
  } else if (platform === "WHATSAPP") {
    await sendWhatsAppMessage(chatId, message);
  }
}

export async function sendMorningReminders(): Promise<void> {
  const timestamp = new Date().toISOString();
  console.log(`[SCHEDULER] ⏰ sendMorningReminders() dipanggil pada ${timestamp}`);
  try {
    const users = await prisma.user.findMany({
      where: {
        bot_chat_id: { not: null },
        bot_platform: { not: null },
      },
    });

    console.log(`[SCHEDULER] 📤 Mengirim morning reminder ke ${users.length} users`);

    for (const user of users) {
      const message = `Selamat pagi, Kak *${user.name}*! 🌅 Jangan lupa sarapan bergizi seimbang hari ini dan mari mulai langkah pertamamu dengan semangat ya. Glicoo siap memantau kesehatanmu! 🥗🏃‍♂️`;
      await sendMessageToUser(user.bot_chat_id!, user.bot_platform, message);
    }
    console.log(`[SCHEDULER] ✅ Morning reminders selesai dikirim`);
  } catch (e) {
    console.error("[SCHEDULER] ❌ Gagal mengirim pengingat pagi:", e);
  }
}

export async function sendAfternoonReminders(): Promise<void> {
  const timestamp = new Date().toISOString();
  console.log(`[SCHEDULER] ⏰ sendAfternoonReminders() dipanggil pada ${timestamp}`);
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const users = await prisma.user.findMany({
      where: {
        bot_chat_id: { not: null },
        bot_platform: { not: null },
      },
      include: {
        sensorLogs: {
          where: { date: today },
        },
      },
    });

    console.log(`[SCHEDULER] 📊 Mengecek langkah untuk ${users.length} users`);

    let sentCount = 0;
    for (const user of users) {
      const stepCount = user.sensorLogs[0]?.step_count || 0;
      console.log(`[SCHEDULER] User ${user.name}: ${stepCount} langkah`);
      if (stepCount < 3000) {
        const message = `Halo Kak *${user.name}*! 👋 Langkah kakimu hari ini baru tercatat *${stepCount}* langkah. Yuk sempatkan jalan santai sore sebentar biar badan segar dan sirkulasi gula darah tetap terjaga! 🚶‍♂️🏃‍♂️`;
        await sendMessageToUser(user.bot_chat_id!, user.bot_platform, message);
        sentCount++;
      }
    }
    console.log(
      `[SCHEDULER] ✅ Afternoon reminders selesai (${sentCount}/${users.length} dikirim)`
    );
  } catch (e) {
    console.error("[SCHEDULER] ❌ Gagal mengirim pengingat sore:", e);
  }
}

export async function sendEveningReminders(): Promise<void> {
  const timestamp = new Date().toISOString();
  console.log(`[SCHEDULER] ⏰ sendEveningReminders() dipanggil pada ${timestamp}`);
  try {
    const users = await prisma.user.findMany({
      where: {
        bot_chat_id: { not: null },
        bot_platform: { not: null },
      },
    });

    console.log(`[SCHEDULER] 📤 Mengirim evening reminder ke ${users.length} users`);

    for (const user of users) {
      const message = `Sudah jam 9 malam nih, Kak *${user.name}*! 🛌 Saatnya batasi screen time handphone kamu, rileks sejenak, dan persiapkan tidur nyenyak malam ini. Tidur yang cukup sangat baik untuk metabolisme tubuhmu besok pagi. Selamat istirahat! 😴💤`;
      await sendMessageToUser(user.bot_chat_id!, user.bot_platform, message);
    }
    console.log(`[SCHEDULER] ✅ Evening reminders selesai dikirim`);
  } catch (e) {
    console.error("[SCHEDULER] ❌ Gagal mengirim pengingat malam:", e);
  }
}

export function startScheduler(): void {
  // Hanya jalankan cron in-memory jika bukan di serverless environment
  if (process.env.NODE_ENV === "production" && process.env.IS_VERCEL) {
    console.log(
      "[SCHEDULER] Serverless environment dideteksi. Cron lokal dinonaktifkan (Gunakan Vercel Cron / trigger HTTP)."
    );
    return;
  }

  // 1. Pengingat Pagi (Setiap hari pukul 08:00 pagi)
  new Cron("0 8 * * *", { timezone: "Asia/Jakarta" }, sendMorningReminders);

  // 2. Cek Aktivitas Langkah Sore (Setiap hari pukul 15:00 sore)
  new Cron("0 15 * * *", { timezone: "Asia/Jakarta" }, sendAfternoonReminders);

  // 3. Pengingat Istirahat Malam (Setiap hari pukul 21:00 malam)
  new Cron("0 21 * * *", { timezone: "Asia/Jakarta" }, sendEveningReminders);

  console.log("[SCHEDULER] Cron scheduler lokal berhasil dijalankan.");
}
