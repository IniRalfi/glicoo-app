import { prisma } from "../../core/db";
import { aiService } from "../ai/ai.service";
import { BotService } from "../bot/bot.service";

/**
 * Purpose:
 * Layanan khusus untuk mengolah pencatatan log makanan.
 * Mengatur pemrosesan AI di latar belakang (asinkronus), kalkulasi kalori/gula,
 * pencatatan ke database riwayat chat, dan pengiriman notifikasi/pesan ke Telegram.
 *
 * Used By:
 * food.routes.ts
 *
 * Depends On:
 * db.ts, ai.service.ts, bot.service.ts
 *
 * Impact:
 * Menjalankan tugas latar belakang utama saat makanan dicatat dari aplikasi Mobile.
 */
export class FoodService {
  /**
   * [ID]
   * Memproses analisis gizi makanan via AI secara asinkronus (non-blocking),
   * mengupdate database, dan mengirimkan notifikasi balik ke Telegram jika terhubung.
   *
   * [EN]
   * Processes food nutrition analysis via AI asynchronously (non-blocking),
   * updates the database, and sends a notification message back to Telegram if linked.
   */
  static async processFoodLogAsync(userId: string, foodLogId: string, description: string): Promise<void> {
    try {
      // 1. Cari data user untuk memastikan identitas dan status bot Telegram
      const user = await prisma.user.findUnique({
        where: { id: userId },
      });
      if (!user) return;

      // 2. Hubungi AI Service untuk melakukan Natural Language Parsing dengan format terstruktur
      const schema = {
        type: 'object',
        properties: {
          estimated_calories: {
            type: 'integer',
            description: 'Estimasi kalori makanan (integer, dalam satuan kcal)'
          },
          estimated_sugar_grams: {
            type: 'number',
            description: 'Estimasi kandungan gula makanan dalam gram (float)'
          },
          ai_feedback: {
            type: 'string',
            description: 'Feedback singkat gaya bahasa Glico, Socratic, bersahabat, maksimal 2-3 kalimat'
          }
        },
        required: ['estimated_calories', 'estimated_sugar_grams', 'ai_feedback']
      };

      const systemInstruction = `
        Kamu adalah Glico, sahabat virtual pendeteksi risiko Diabetes Tipe 2.
        Gaya bahasamu santai, menggunakan bahasa Indonesia sehari-hari ("Kamu", "Kak"), dan lengkapi dengan sedikit emoji. Jangan menggurui atau menggunakan bahasa medis kaku.
        Tugasmu adalah menganalisis deskripsi makanan pengguna, mengestimasi kalori (kcal), mengestimasi kandungan gula (gram), dan memberikan saran nutrisi bersahabat maksimal 2-3 kalimat yang memotivasi mereka untuk bergerak aktif jika makanannya tinggi kalori/gula.
      `;

      const aiResponse = await aiService.generateJSON<{
        estimated_calories: number;
        estimated_sugar_grams: number;
        ai_feedback: string;
      }>(description, schema, systemInstruction);

      // 3. Update data gizi di tabel FoodLog
      await prisma.foodLog.update({
        where: { id: foodLogId },
        data: {
          estimated_calories: aiResponse.estimated_calories,
          estimated_sugar_grams: aiResponse.estimated_sugar_grams,
          ai_feedback: aiResponse.ai_feedback,
        },
      });

      // 4. Simpan riwayat interaksi ini ke InterventionChat agar terdata di Dashboard
      await prisma.interventionChat.create({
        data: {
          user_id: userId,
          message: `Mencatat makanan: "${description}"`,
          sender_type: 'USER',
          intervention_moment: 'MEAL_TIME',
        },
      });

      await prisma.interventionChat.create({
        data: {
          user_id: userId,
          message: aiResponse.ai_feedback,
          sender_type: 'AI_AGENT',
          intervention_moment: 'MEAL_TIME',
        },
      });

      // 5. Kirim notifikasi Telegram jika user sudah menyambungkan akun
      if (user.phone_number) {
        await BotService.sendTelegramMessage(user.phone_number, aiResponse.ai_feedback);
      } else {
        console.log(`[FOOD] User ${userId} belum menghubungkan Telegram. Hasil analisa disimpan di database.`);
      }
    } catch (err) {
      console.error(`[FOOD] Gagal memproses latar belakang analisis makanan untuk user ${userId}:`, err);
    }
  }
}
