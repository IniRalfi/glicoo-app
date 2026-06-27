import { Cron } from 'croner';
import { prisma } from '../../core/db';
import { BotService } from './bot.service';

/**
 * Purpose:
 * Mengatur jalannya Scheduler/Cron lokal untuk mengirimkan pesan pengingat aktif harian
 * (Pagi untuk motivasi, Sore untuk cek langkah kaki, Malam untuk istirahat).
 *
 * Used By:
 * src/index.ts (dipanggil saat inisialisasi aplikasi)
 *
 * Depends On:
 * croner, db.ts, bot.service.ts
 *
 * Impact:
 * Menjalankan tugas berkala yang mengirimkan pesan proaktif ke pengguna Telegram.
 */

export async function sendMorningReminders(): Promise<void> {
  console.log('[SCHEDULER] Menjalankan pengingat pagi hari...');
  try {
    const users = await prisma.user.findMany({
      where: {
        phone_number: { not: null },
        NOT: { phone_number: "" }
      }
    });

    for (const user of users) {
      await BotService.sendTelegramMessage(
        user.phone_number!,
        `Selamat pagi, Kak *${user.name}*! 🌅 Jangan lupa sarapan bergizi seimbang hari ini dan mari mulai langkah pertamamu dengan semangat ya. Glicoo siap memantau kesehatanmu! 🥗🏃‍♂️`
      );
    }
  } catch (e) {
    console.error('[SCHEDULER] Gagal mengirim pengingat pagi:', e);
  }
}

export async function sendAfternoonReminders(): Promise<void> {
  console.log('[SCHEDULER] Menjalankan pengecekan langkah sore hari...');
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const users = await prisma.user.findMany({
      where: {
        phone_number: { not: null },
        NOT: { phone_number: "" }
      },
      include: {
        sensorLogs: {
          where: { date: today }
        }
      }
    });

    for (const user of users) {
      const stepCount = user.sensorLogs[0]?.step_count || 0;
      if (stepCount < 3000) {
        await BotService.sendTelegramMessage(
          user.phone_number!,
          `Halo Kak *${user.name}*! 👋 Langkah kakimu hari ini baru tercatat *${stepCount}* langkah. Yuk sempatkan jalan santai sore sebentar biar badan segar dan sirkulasi gula darah tetap terjaga! 🚶‍♂️🏃‍♂️`
        );
      }
    }
  } catch (e) {
    console.error('[SCHEDULER] Gagal mengirim pengingat sore:', e);
  }
}

export async function sendEveningReminders(): Promise<void> {
  console.log('[SCHEDULER] Menjalankan pengingat istirahat malam...');
  try {
    const users = await prisma.user.findMany({
      where: {
        phone_number: { not: null },
        NOT: { phone_number: "" }
      }
    });

    for (const user of users) {
      await BotService.sendTelegramMessage(
        user.phone_number!,
        `Sudah jam 9 malam nih, Kak *${user.name}*! 🛌 Saatnya batasi screen time handphone kamu, rileks sejenak, dan persiapkan tidur nyenyak malam ini. Tidur yang cukup sangat baik untuk metabolisme tubuhmu besok pagi. Selamat istirahat! 😴💤`
      );
    }
  } catch (e) {
    console.error('[SCHEDULER] Gagal mengirim pengingat malam:', e);
  }
}

export function startScheduler(): void {
  // Hanya jalankan cron in-memory jika bukan di serverless environment
  if (process.env.NODE_ENV === 'production' && process.env.IS_VERCEL) {
    console.log('[SCHEDULER] Serverless environment dideteksi. Cron lokal dinonaktifkan (Gunakan Vercel Cron / trigger HTTP).');
    return;
  }

  // 1. Pengingat Pagi (Setiap hari pukul 08:00 pagi)
  new Cron('0 8 * * *', sendMorningReminders);

  // 2. Cek Aktivitas Langkah Sore (Setiap hari pukul 15:00 sore)
  new Cron('0 15 * * *', sendAfternoonReminders);

  // 3. Pengingat Istirahat Malam (Setiap hari pukul 21:00 malam)
  new Cron('0 21 * * *', sendEveningReminders);

  console.log('[SCHEDULER] Cron scheduler lokal berhasil dijalankan.');
}
