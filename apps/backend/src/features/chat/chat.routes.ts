import { Elysia, t } from "elysia";
import { rateLimit } from "elysia-rate-limit";
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
  // [SECURITY] Rate limit: 30 pesan/menit per IP untuk mencegah penyalahgunaan Gemini API
  .use(rateLimit({ duration: 60_000, max: 30 }))
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
          const name = userMetadata?.name || "Pengguna Glicoo";
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

        // Ambil riwayat percakapan sebelumnya untuk memberikan konteks ke AI
        const recentChats = await prisma.interventionChat.findMany({
          where: { user_id: userId! },
          orderBy: { created_at: 'desc' },
          take: 7, // Ambil 7 pesan terakhir termasuk yang baru saja disimpan
        });

        recentChats.reverse();

        const formattedHistory = recentChats.map(c => {
          const role = c.sender_type === 'USER' ? 'Pengguna' : 'Iloo';
          return `${role}: ${c.message}`;
        }).join('\n');

        // Tambahkan context kesehatan real-time dari payload mobile jika tersedia
        let contextInfo = "";
        if (body.context) {
          const { today_steps, today_screen_time_minutes, age, weight, height, waist_circumference, findrisc_score } = body.context;
          contextInfo = `\n\n[Konteks Kesehatan Real-time Pengguna Saat Ini]:` +
            (today_steps !== undefined ? `\n- Langkah kaki hari ini: ${today_steps} langkah` : '') +
            (today_screen_time_minutes !== undefined ? `\n- Waktu layar hari ini: ${today_screen_time_minutes} menit` : '') +
            (age !== undefined ? `\n- Umur: ${age} tahun` : '') +
            (weight !== undefined ? `\n- Berat badan: ${weight} kg` : '') +
            (height !== undefined ? `\n- Tinggi badan: ${height} cm` : '') +
            (waist_circumference !== undefined ? `\n- Lingkar pinggang: ${waist_circumference} cm` : '') +
            (findrisc_score !== undefined ? `\n- Skor risiko Diabetes (FINDRISC): ${findrisc_score}` : '');
        }

        // 3. Konfigurasi Schema parsing AI (is_food, calories, sugar, feedback)
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
          Tugasmu adalah membalas percakapan pengguna di dalam in-app chat berdasarkan riwayat chat yang diberikan.
          Jika informasi Konteks Kesehatan Real-time Pengguna Saat Ini disediakan, gunakan informasi tersebut secara alami untuk mempersonalisasi balasanmu (misalnya memuji langkah kaki mereka jika banyak, memperingatkan screen time jika tinggi, atau menyinggung lingkar pinggang/skor risiko jika mereka bertanya).
          Jika jumlah makanan/porsi yang dimasukkan tidak wajar atau sangat berlebihan (seperti makan nasi 3kg, makan ikan 10 ekor sekaligus, minum sirup seember, dll.), tanggapilah dengan humor, candaan santai, atau rasa terkejut yang lucu khas sahabat dekat (misalnya: "Ini makan porsi satu RT atau gimana Kak? 😂") sebelum memberikan estimasi angka kalori/gula yang fantastis tersebut secara logis.
          Jika pesan terakhir dari Pengguna menanyakan atau mengacu pada deskripsi makanan/minuman sebelumnya, jawablah pertanyaannya sesuai konteks dan tentukan nilai gizi/kalori/gula yang sesuai.
          Jika pesan terakhir berupa deskripsi makanan/minuman, estimasikan kalori (kcal), estimasikan kandungan gula (gram), dan buatlah feedback bersahabat maksimal 2-3 kalimat yang memotivasi mereka untuk bergerak aktif jika makanan tinggi kalori/gula.
          Jika pesan terakhir tidak terkait makanan/minuman, balaslah seperti sahabat yang peduli kesehatan mereka dan tetapkan is_food = false, serta estimated_calories = null dan estimated_sugar_grams = null.
        `;

        const prompt = `Berikut adalah riwayat percakapan terakhir:\n${formattedHistory}${contextInfo}\n\nAnalisis pesan terakhir dari Pengguna dan tentukan nilai JSON yang sesuai berdasarkan riwayat tersebut.`;

        // 4. Panggil AI Service
        const aiResponse = await aiService.generateJSON<{
          is_food: boolean;
          estimated_calories: number | null;
          estimated_sugar_grams: number | null;
          ai_feedback: string;
        }>(prompt, schema, systemInstruction);

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
        context: t.Optional(
          t.Object({
            today_steps: t.Optional(t.Integer()),
            today_screen_time_minutes: t.Optional(t.Integer()),
            age: t.Optional(t.Integer()),
            weight: t.Optional(t.Numeric()),
            height: t.Optional(t.Numeric()),
            waist_circumference: t.Optional(t.Numeric()),
            findrisc_score: t.Optional(t.Integer()),
          })
        ),
      }),
      detail: {
        tags: ["chat"],
        summary: "Interact with the in-app Glicoo AI assistant (processes food logs if mentioned)",
      },
    }
  );
export default chatRoutes;
