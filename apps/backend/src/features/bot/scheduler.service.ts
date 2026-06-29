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
  console.log("[SCHEDULER] Menjalankan pengingat pagi hari...");
  try {
    const users = await prisma.user.findMany({
      where: {
        bot_chat_id: { not: null },
        bot_platform: { not: null },
      },
    });

    for (const user of users) {
      const message = `Selamat pagi, Kak *${user.name}*! 🌅 Jangan lupa sarapan bergizi seimbang hari ini dan mari mulai langkah pertamamu dengan semangat ya. Glicoo siap memantau kesehatanmu! 🥗🏃‍♂️`;
      await sendMessageToUser(user.bot_chat_id!, user.bot_platform, message);
    }
  } catch (e) {
    console.error("[SCHEDULER] Gagal mengirim pengingat pagi:", e);
  }
}

export async function sendAfternoonReminders(): Promise<void> {
  console.log("[SCHEDULER] Menjalankan pengecekan langkah sore hari...");
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

    for (const user of users) {
      const stepCount = user.sensorLogs[0]?.step_count || 0;
      if (stepCount < 3000) {
        const message = `Halo Kak *${user.name}*! 👋 Langkah kakimu hari ini baru tercatat *${stepCount}* langkah. Yuk sempatkan jalan santai sore sebentar biar badan segar dan sirkulasi gula darah tetap terjaga! 🚶‍♂️🏃‍♂️`;
        await sendMessageToUser(user.bot_chat_id!, user.bot_platform, message);
      }
    }
  } catch (e) {
    console.error("[SCHEDULER] Gagal mengirim pengingat sore:", e);
  }
}

export async function sendEveningReminders(): Promise<void> {
  console.log("[SCHEDULER] Menjalankan pengingat istirahat malam...");
  try {
    const users = await prisma.user.findMany({
      where: {
        bot_chat_id: { not: null },
        bot_platform: { not: null },
      },
    });

    for (const user of users) {
      const message = `Sudah jam 9 malam nih, Kak *${user.name}*! 🛌 Saatnya batasi screen time handphone kamu, rileks sejenak, dan persiapkan tidur nyenyak malam ini. Tidur yang cukup sangat baik untuk metabolisme tubuhmu besok pagi. Selamat istirahat! 😴💤`;
      await sendMessageToUser(user.bot_chat_id!, user.bot_platform, message);
    }
  } catch (e) {
    console.error("[SCHEDULER] Gagal mengirim pengingat malam:", e);
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
  new Cron("0 8 * * *", sendMorningReminders);

  // 2. Cek Aktivitas Langkah Sore (Setiap hari pukul 15:00 sore)
  new Cron("0 15 * * *", sendAfternoonReminders);

  // 3. Pengingat Istirahat Malam (Setiap hari pukul 21:00 malam)
  new Cron("0 21 * * *", sendEveningReminders);

  console.log("[SCHEDULER] Cron scheduler lokal berhasil dijalankan.");
}
