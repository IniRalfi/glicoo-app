import { Elysia, t } from "elysia";
import { authPlugin, isAuthenticated } from "../../core/middlewares/auth";
import { prisma } from "../../core/db";
import { FoodService } from "./food.service";

/**
 * [ID] Router untuk pencatatan log makanan tekstual (Food Log)
 * yang memproses analisis gizi secara asinkronus menggunakan AI.
 *
 * [EN] Router for food logging using natural text,
 * which processes nutrition analysis asynchronously using AI.
 */
export const foodRoutes = new Elysia({ prefix: "/food" })
  .use(authPlugin)
  .post(
    "/log",
    async ({ userId, userMetadata, body, set }) => {
      try {
        // [ID] Pastikan data user ada di tabel users publik
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

        // [ID] Simpan data log makanan ke database
        const foodLog = await prisma.foodLog.create({
          data: {
            user_id: userId!,
            description: body.description,
          },
        });

        // [ID] Proses analisis AI secara sinkronus untuk mendapatkan data hasil analisis langsung
        const analysis = await FoodService.processFoodLogSync(userId!, foodLog.id, body.description);

        set.status = 200;
        return {
          message: "Food log analyzed and saved successfully",
          foodLogId: foodLog.id,
          estimated_calories: analysis.estimated_calories,
          estimated_sugar_grams: analysis.estimated_sugar_grams,
          carbohydrate_level: analysis.carbohydrate_level,
          sugar_level: analysis.sugar_level,
          protein_level: analysis.protein_level,
          ai_feedback: analysis.ai_feedback,
        };
      } catch (err) {
        console.error("Error creating food log:", err);
        set.status = 500;
        return { message: "Internal server error during food logging" };
      }
    },
    {
      beforeHandle: isAuthenticated,
      body: t.Object({
        description: t.String({
          minLength: 3,
          error: "Description must be at least 3 characters long",
        }),
      }),
      detail: {
        tags: ["food"],
        summary: "Log daily food consumption and trigger asynchronous AI analysis",
      },
    }
  );
