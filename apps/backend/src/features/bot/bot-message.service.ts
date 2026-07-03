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
    const promptParams = {
      message: text,
      user: {
        name: user.name || "Sobat Glico",
        age: user.age || "Belum diisi",
        weight: user.weight || "Belum diisi",
        height: user.height || "Belum diisi",
      },
      currentDate: new Date().toLocaleDateString("id-ID", {
        weekday: "long",
        year: "numeric",
        month: "long",
        day: "numeric",
      }),
    };

    const botSystemPrompt = `
Kamu adalah "Iloo", asisten kesehatan pintar dan ramah dari aplikasi "Glico" (berfokus pada diabetes & gaya hidup sehat).
Kepribadianmu: Ceria, suportif, informatif, dan suka memakai emoji.
Gunakan bahasa Indonesia yang santai tapi sopan (seperti ngobrol dengan teman).

Informasi Pengguna:
Nama: ${promptParams.user.name}
Umur: ${promptParams.user.age} tahun
Berat Badan: ${promptParams.user.weight} kg
Tinggi Badan: ${promptParams.user.height} cm
Tanggal Hari Ini: ${promptParams.currentDate}

Tugas Utama:
1. Jawab pertanyaan pengguna dengan ramah dan ringkas.
2. JIKA pengguna menyebutkan/bertanya tentang Makanan atau Minuman, kamu WAJIB menganalisis kandungan gizinya (Kalori, Karbohidrat, Lemak, Protein).
3. Berikan saran kesehatan yang relevan dengan kondisi pengguna jika diperlukan.

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
      const response = await aiService.generateJSON<{
        message: string;
        food?: {
          description?: string | null;
          calories?: number | null;
          sugar?: number | null;
        } | null;
      }>(JSON.stringify({ user_message: promptParams.message }), responseSchema, botSystemPrompt);

      // Jika ada data makanan yang terekstrak dari pesan pengguna, simpan
      if (response.food && response.food.description) {
        try {
          await prisma.foodLog.create({
            data: {
              user_id: user.id,
              description: response.food.description,
              estimated_calories: response.food.calories || 0,
              estimated_sugar_grams: response.food.sugar || 0,
              ai_feedback: "Dicatat otomatis via Bot Glico",
            },
          });
        } catch (foodErr) {
          console.warn("[BotMessageService] Error logging food to DB:", foodErr);
          // Continue execution, do not fail chat response
        }
      }

      return response.message;
    } catch (error) {
      console.error("[BotMessageService] Error processing AI message:", error);
      return "Waduh, Iloo lagi pusing nih, belum bisa mencerna pesan kamu... Coba lagi nanti ya!";
    }
  }
}
