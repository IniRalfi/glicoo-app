import { Elysia, t } from "elysia";
import { authPlugin } from "../../core/middlewares/auth";
import { prisma } from "../../core/db";

/**
 * [ID] Router untuk pencatatan log makanan tekstual (Food Log)
 * yang meneruskan pemicu (webhook) ke n8n secara asinkronus.
 *
 * [EN] Router for food logging using natural text,
 * which forwards a webhook trigger to n8n asynchronously.
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
          const name = userMetadata?.name || "Pengguna Glico";
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

        // [ID] Kirim pemicu (webhook) ke n8n secara asinkronus (non-blocking)
        const n8nWebhook = process.env.N8N_FOOD_LOG_WEBHOOK_URL;
        if (n8nWebhook) {
          fetch(n8nWebhook, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              userId: userId!,
              foodLogId: foodLog.id,
              description: body.description,
              userName: user.name,
              phone: user.phone_number,
            }),
          }).catch((err) => {
            console.error("Failed to trigger n8n food log webhook asynchronously:", err);
          });
        } else {
          console.warn("N8N_FOOD_LOG_WEBHOOK_URL is not set in environment variables.");
        }

        // [ID] Kembalikan 202 Accepted karena AI masih memproses laporan di latar belakang
        set.status = 202;
        return {
          message: "Log saved. AI is processing the analysis via chat.",
          foodLogId: foodLog.id,
        };
      } catch (err) {
        console.error("Error creating food log:", err);
        set.status = 500;
        return { message: "Internal server error during food logging" };
      }
    },
    {
      isAuth: true,
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
