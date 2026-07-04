/**
 * Purpose:
 * → Memproses pesan dari user (Telegram/WhatsApp) melalui AI Gemini
 *    dan mencatat makanan jika terdeteksi oleh AI.
 *
 * Used By:
 * → bot.service.ts
 *
 * Depends On:
 * → ai.service.ts, prisma
 *
 * Impact:
 * → Interaksi natural chatbot dan pencatatan kalori otomatis.
 */

import { User } from "@prisma/client";

import { aiService } from "../ai/ai.service";
import { prisma } from "../../core/db";

export class BotMessageService {
  /**
   * [ID]
   * Memproses pesan teks pengguna menggunakan AI Gemini. Jika AI mengekstrak data
   * nutrisi (food object), fungsi ini akan menyimpannya langsung ke DB.
   *
   * [EN]
   * Processes user text message using Gemini AI. If AI extracts nutritional data
   * (food object), this function saves it directly to the DB.
   */
  static async processAndReplyMessage(user: User, text: string): Promise<string> {
    // 1. Ambil data sensor hari ini untuk user (langkah & screen time)
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const todaySensor = await prisma.dailySensorLog.findFirst({
      where: {
        user_id: user.id,
        date: today,
      },
    });

    const recentChats = await prisma.interventionChat.findMany({
      where: { user_id: user.id },
      orderBy: { created_at: "desc" },
      take: 5,
    });
    recentChats.reverse();

    const formattedHistory = recentChats
      .map((c) => {
        const role = c.sender_type === "USER" ? "Pengguna" : "Iloo";
        return `${role}: ${c.message}`;
      })
      .join("\n");

    const promptParams = {
      message: text,
      user: {
        name: user.name || "Sobat Glico",
        age: user.age || "Belum diisi",
        weight: user.weight || "Belum diisi",
        height: user.height || "Belum diisi",
        waist: user.waist_circumference || "Belum diisi",
        findrisc_score: user.risk_score || "Belum diisi",
        steps: todaySensor?.step_count || 0,
        screenTime: todaySensor?.screen_time_minutes || 0,
      },
      currentDate: new Date().toLocaleDateString("id-ID", {
        weekday: "long",
        year: "numeric",
        month: "long",
        day: "numeric",
      }),
    };

    const botSystemPrompt = `
Kamu adalah "Iloo", asisten kesehatan pintar, ramah, dan sedikit kocak dari aplikasi "Glico" (fokus pada diabetes & gaya hidup sehat).
Kepribadianmu: Ceria, suportif, informatif, suka pakai emoji, dan kadang sedikit menyindir lucu (sarcastic comedy) jika pengguna makan ngawur.
Gunakan bahasa Indonesia yang santai, gaul tapi sopan (pakai "Kamu" atau "Kak").

[Informasi & Kondisi Real-time Pengguna]
Nama: ${promptParams.user.name}
Umur: ${promptParams.user.age} tahun
Berat Badan: ${promptParams.user.weight} kg
Tinggi Badan: ${promptParams.user.height} cm
Lingkar Pinggang: ${promptParams.user.waist} cm
Skor Risiko Diabetes (FINDRISC): ${promptParams.user.findrisc_score}
Langkah kaki hari ini: ${promptParams.user.steps} langkah
Waktu layar (Screen Time) hari ini: ${promptParams.user.screenTime} menit
Tanggal: ${promptParams.currentDate}

[Riwayat Chat Terakhir]
${formattedHistory}

Tugas Utama:
1. Jawab berdasarkan riwayat chat dan konteks kesehatan di atas secara natural. Puji jika langkahnya banyak, atau sindir halus jika screen time-nya tinggi (misal: "rebahan terus ya?").
2. JIKA pengguna cerita atau tanya soal Makanan/Minuman, kamu WAJIB ekstrak data gizinya.
3. JIKA porsi makanannya sangat tidak wajar (misal: "makan 10 piring nasi", "minum es teh sebaskom"), kamu HARUS memberikan reaksi kaget yang lucu khas sahabat, sebelum memberikan estimasinya. Jangan kaku!
4. Berikan saran kesehatan yang relevan, maksimal 2-3 kalimat agar tidak kepanjangan.

Kamu HARUS mengembalikan response dalam format JSON dengan struktur:
{
  "message": "Balasan chat kamu ke pengguna (gunakan Markdown jika perlu)",
  "food": {
    "description": "Nama makanan/minuman (jika ada, null jika tidak ada)",
    "calories": "Estimasi kalori dalam kcal (angka saja, null jika tidak ada)",
    "sugar": "Estimasi gula dalam gram (angka saja, null jika tidak ada)"
  }
}
`;

    const responseSchema = {
      type: "object",
      properties: {
        message: {
          type: "string",
          description: "Pesan balasan chatbot untuk pengguna",
        },
        food: {
          type: "object",
          description: "Data makanan yang terekstrak dari pesan pengguna (jika ada)",
          nullable: true,
          properties: {
            description: { type: "string", nullable: true },
            calories: { type: "number", nullable: true },
            sugar: { type: "number", nullable: true },
          },
        },
      },
      required: ["message"],
    };

    try {
      // Simpan chat user
      await prisma.interventionChat.create({
        data: {
          user_id: user.id,
          message: text,
          sender_type: "USER",
          intervention_moment: "NONE",
        },
      });

      const response = await aiService.generateJSON<{
        message: string;
        food?: {
          description?: string | null;
          calories?: number | null;
          sugar?: number | null;
        } | null;
      }>(JSON.stringify({ user_message: promptParams.message }), responseSchema, botSystemPrompt);

      let isFood = false;

      // Jika ada data makanan yang terekstrak dari pesan pengguna, simpan
      if (response.food && response.food.description) {
        isFood = true;
        try {
          await prisma.foodLog.create({
            data: {
              user_id: user.id,
              description: response.food.description,
              estimated_calories: response.food.calories || 0,
              estimated_sugar_grams: response.food.sugar || 0,
              ai_feedback: response.message,
            },
          });
        } catch (foodErr) {
          console.warn("[BotMessageService] Error logging food to DB:", foodErr);
        }
      }

      // Simpan balasan bot
      await prisma.interventionChat.create({
        data: {
          user_id: user.id,
          message: response.message,
          sender_type: "AI_AGENT",
          intervention_moment: isFood ? "MEAL_TIME" : "NONE",
        },
      });

      return response.message;
    } catch (error) {
      console.error("[BotMessageService] Error processing AI message:", error);
      return "Waduh, Iloo lagi pusing nih, belum bisa mencerna pesan kamu... Coba lagi nanti ya!";
    }
  }
}
