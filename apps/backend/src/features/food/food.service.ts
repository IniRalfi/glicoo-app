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
  static async processFoodLogSync(userId: string, foodLogId: string, description: string) {
    // 1. Cari data user untuk memastikan identitas dan status bot Telegram
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });
    if (!user) {
      throw new Error("User not found");
    }

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
        carbohydrate_level: {
          type: 'string',
          enum: ['Rendah', 'Sedang', 'Tinggi'],
          description: 'Kategori kandungan karbohidrat makanan (Rendah/Sedang/Tinggi)'
        },
        sugar_level: {
          type: 'string',
          enum: ['Rendah', 'Sedang', 'Tinggi'],
          description: 'Kategori kandungan gula makanan (Rendah/Sedang/Tinggi)'
        },
        protein_level: {
          type: 'string',
          enum: ['Kurang', 'Cukup', 'Baik'],
          description: 'Kategori kandungan protein makanan (Kurang/Cukup/Baik)'
        },
        ai_feedback: {
          type: 'string',
          description: 'Feedback singkat gaya bahasa Iloo, Socratic, bersahabat, maksimal 2-3 kalimat'
        }
      },
      required: [
        'estimated_calories',
        'estimated_sugar_grams',
        'carbohydrate_level',
        'sugar_level',
        'protein_level',
        'ai_feedback'
      ]
    };

    const systemInstruction = `
      Kamu adalah Iloo, sahabat virtual pendeteksi risiko Diabetes Tipe 2 di aplikasi Glicoo.
      Gaya bahasamu santai, menggunakan bahasa Indonesia sehari-hari ("Kamu", "Kak"), dan lengkapi dengan sedikit emoji. Jangan menggurui atau menggunakan bahasa medis kaku.
      Tugasmu adalah menganalisis deskripsi makanan pengguna, mengestimasi kalori (kcal), mengestimasi kandungan gula (gram), karbohidrat (Tinggi/Sedang/Rendah), gula (Tinggi/Sedang/Rendah), protein (Baik/Cukup/Kurang) dan memberikan saran nutrisi bersahabat maksimal 2-3 kalimat.
      
      Aturan Penanganan Input:
      1. Jika input pengguna sama sekali bukan makanan (misalnya kata acak tanpa arti seperti "asdfghjk", angka acak, atau objek non-makanan seperti "batu", "sepatu"), tetapkan estimated_calories: 0, estimated_sugar_grams: 0, carbohydrate_level: "Rendah", sugar_level: "Rendah", protein_level: "Kurang", dan berikan ai_feedback bernada kebingungan lucu atau candaan khas sahabat dekat (contoh: "Waduh Kak, Iloo bingung nih... Sepertinya itu bukan menu makanan deh! 😅 Coba tuliskan menu makanan atau minuman yang kamu konsumsi ya! 🍲").
      2. Jika jumlah makanan/porsi yang dimasukkan sangat tidak wajar atau berlebihan (seperti makan nasi 10kg, es teh 50 gelas, dll.), tanggapilah dengan humor lucu khas sahabat dekat (misalnya: "Ini porsi makan satu kecamatan atau gimana Kak? 😂") lalu berikan estimasi angka kalori/gula yang sesuai secara logis.
    `;

    const aiResponse = await aiService.generateJSON<{
      estimated_calories: number;
      estimated_sugar_grams: number;
      carbohydrate_level: string;
      sugar_level: string;
      protein_level: string;
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

    // 5. Kirim notifikasi Telegram jika user sudah menyambungkan akun (asinkronus)
    if (user.phone_number) {
      BotService.sendTelegramMessage(user.phone_number, aiResponse.ai_feedback).catch((err) => {
        console.error('[FOOD] Gagal mengirim pesan Telegram:', err);
      });
    }

    return {
      estimated_calories: aiResponse.estimated_calories,
      estimated_sugar_grams: aiResponse.estimated_sugar_grams,
      carbohydrate_level: aiResponse.carbohydrate_level,
      sugar_level: aiResponse.sugar_level,
      protein_level: aiResponse.protein_level,
      ai_feedback: aiResponse.ai_feedback
    };
  }
}
