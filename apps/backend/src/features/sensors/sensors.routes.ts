import { Elysia, t } from "elysia";
import { authPlugin, isAuthenticated } from "../../core/middlewares/auth";
import { prisma } from "../../core/db";

/**
 * [ID] Router untuk sinkronisasi data sensor harian (langkah & screen time).
 *
 * [EN] Router for syncing daily sensor data (steps & screen time).
 */
export const sensorsRoutes = new Elysia({ prefix: "/sensors" })
  .use(authPlugin)
  .post(
    "/sync",
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

        const parsedDate = new Date(body.date);

        await prisma.dailySensorLog.upsert({
          where: {
            user_id_date: {
              user_id: userId!,
              date: parsedDate,
            },
          },
          update: {
            step_count: body.step_count,
            screen_time_minutes: body.screen_time_minutes,
          },
          create: {
            user_id: userId!,
            date: parsedDate,
            step_count: body.step_count,
            screen_time_minutes: body.screen_time_minutes,
          },
        });

        return { message: "Sensor data synced successfully" };
      } catch (err) {
        console.error("Error syncing sensors:", err);
        set.status = 500;
        return { message: "Internal server error during synchronization" };
      }
    },
    {
      beforeHandle: isAuthenticated,
      body: t.Object({
        date: t.String({
          pattern: "^\\d{4}-\\d{2}-\\d{2}$",
          error: "Date format must be YYYY-MM-DD",
        }),
        step_count: t.Integer({ minimum: 0 }),
        screen_time_minutes: t.Integer({ minimum: 0 }),
      }),
      detail: {
        tags: ["sensors"],
        summary: "Sync step counts and screen time data for a specific date",
      },
    }
  );
