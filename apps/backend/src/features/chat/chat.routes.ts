import { Elysia, t } from "elysia";
import { authPlugin } from "../../core/middlewares/auth";
import { prisma } from "../../core/db";
import { aiService } from "../ai/ai.service";

/**
 * Purpose:
 * Router untuk percakapan Chatbot Bawaan (In-App Chatbot) di dalam aplikasi Mobile.
 * Menerima input teks, mendeteksi secara cerdas apakah itu catatan makanan,
 * menyimpan riwayat chat dan log makanan ke DB, serta mengembalikan respon AI secara sinkron.
 *
 * Used By:
 * src/index.ts (main server routing)
 *
 * Depends On:
 * authPlugin, db.ts, ai.service.ts
 *
 * Impact:
 * Mengatur interaksi in-app chatbot dan pencatatan makanan internal di mobile.
 */

export const chatRoutes = new Elysia({ prefix: "/chat" })
  .use(authPlugin)
  .post(
    "/",
    async ({ userId, userMetadata, body, set }) => {
      try {
        const text = body.message.trim();

        // 1. Pastikan data user ada di tabel users publik
        let user = await prisma.user.findUnique({
          where: { id: userId! },
        });

        if (!user) {
          const name = userMetadata?.name || "Pengguna Glico";
          user = await prisma.user.create({
            data: {
              id: userId!,
              name: name,
            },
          });
        }

        // 2. Simpan pesan User ke InterventionChat
        await prisma.interventionChat.create({
          data: {
            user_id: userId!,
            message: text,
            sender_type: "USER",
            intervention_moment: "MEAL_TIME",
          },
        });

        // 3. Konfigurasi Schema parsing AI (is_food, calories, sugar, feedback)
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
          Tugasmu adalah membalas percakapan pengguna di dalam in-app chat. Jika pesan tersebut berupa deskripsi makanan/minuman, estimasikan kalori (kcal), estimasikan kandungan gula (gram), dan buatlah feedback bersahabat maksimal 2-3 kalimat yang memotivasi mereka untuk bergerak aktif jika makanan tinggi kalori/gula.
          Jika bukan makanan, balaslah seperti sahabat yang peduli kesehatan mereka dan tetapkan is_food = false, serta estimated_calories = null dan estimated_sugar_grams = null.
        `;

        // 4. Panggil AI Service
        const aiResponse = await aiService.generateJSON<{
          is_food: boolean;
          estimated_calories: number | null;
          estimated_sugar_grams: number | null;
          ai_feedback: string;
        }>(text, schema, systemInstruction);

        // 5. Jika AI mendeteksi makanan, simpan ke database FoodLog secara asinkron
        if (aiResponse.is_food) {
          await prisma.foodLog.create({
            data: {
              user_id: userId!,
              description: text,
              estimated_calories: aiResponse.estimated_calories,
              estimated_sugar_grams: aiResponse.estimated_sugar_grams,
              ai_feedback: aiResponse.ai_feedback,
            },
          });
        }

        // 6. Simpan balasan AI ke database InterventionChat
        await prisma.interventionChat.create({
          data: {
            user_id: userId!,
            message: aiResponse.ai_feedback,
            sender_type: "AI_AGENT",
            intervention_moment: aiResponse.is_food ? "MEAL_TIME" : "NONE",
          },
        });

        // 7. Kembalikan hasil respon ke klien
        return {
          reply: aiResponse.ai_feedback,
          isFood: aiResponse.is_food,
          estimatedCalories: aiResponse.estimated_calories,
          estimatedSugarGrams: aiResponse.estimated_sugar_grams,
        };
      } catch (err) {
        console.error("Error in chatbot endpoint:", err);
        set.status = 500;
        return { message: "Internal server error during chat processing" };
      }
    },
    {
      isAuth: true,
      body: t.Object({
        message: t.String({
          minLength: 1,
          error: "Message content cannot be empty",
        }),
      }),
      detail: {
        tags: ["chat"],
        summary: "Interact with the in-app Glico AI assistant (processes food logs if mentioned)",
      },
    }
  );
export default chatRoutes;
