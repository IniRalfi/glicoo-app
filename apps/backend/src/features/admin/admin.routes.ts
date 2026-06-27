import { Elysia, t } from "elysia";
import { prisma } from "../../core/db";
import { aiService } from "../ai/ai.service";

/**
 * Purpose:
 * Router untuk fitur Administrasi & Monitoring Glico Dashboard.
 * Menyediakan metrik performa AI (failover, latensi), status kesehatan database,
 * serta statistik agregasi data user (DAU, log makanan, total langkah) secara real-time.
 *
 * Used By:
 * src/index.ts
 *
 * Depends On:
 * db.ts, ai.service.ts
 *
 * Impact:
 * Menyediakan data krusial untuk divisualisasikan pada halaman Web Admin Dashboard Next.js.
 */
export const adminRoutes = new Elysia({ prefix: "/admin" })
  .get(
    "/stats",
    async ({ headers, set }) => {
      try {
        // [SECURITY] Admin key MUST be set in env. No hardcoded fallback.
        const adminApiKey = process.env.BACKEND_ADMIN_API_KEY;
        const requestApiKey = headers["x-api-key"];

        if (!adminApiKey) {
          console.error("[ADMIN] BACKEND_ADMIN_API_KEY is not set in environment variables!");
          set.status = 503;
          return { message: "Admin endpoint unavailable: server misconfiguration" };
        }

        if (!requestApiKey || requestApiKey !== adminApiKey) {
          set.status = 401;
          return { message: "Unauthorized: Invalid admin API Key" };
        }

        // 2. Cek status koneksi Database Supabase
        let databaseConnected = false;
        try {
          await prisma.$queryRaw`SELECT 1`;
          databaseConnected = true;
        } catch (e) {
          console.error("[ADMIN] Database connection failed check:", e);
        }

        // 3. Ambil data stats AI dari in-memory Service
        const aiStatsRaw = aiService.getStats();
        const averageLatency = aiStatsRaw.callsCount > 0 
          ? Math.round(aiStatsRaw.totalLatencyMs / aiStatsRaw.callsCount) 
          : 0;

        const aiStats = {
          active_provider: aiStatsRaw.activeProvider,
          fallback_chain: aiStatsRaw.fallbackChain,
          success_count_today: aiStatsRaw.successToday,
          failure_count_today: aiStatsRaw.failuresToday,
          average_latency_ms: averageLatency,
        };

        // 4. Kalkulasi metrik hari ini (Daily Active Users & Langkah Kaki)
        const todayStart = new Date();
        todayStart.setHours(0, 0, 0, 0);

        // DAU: User yang melakukan sinkronisasi pedometer hari ini
        const dauCount = await prisma.dailySensorLog.count({
          where: {
            date: {
              gte: todayStart,
            },
          },
        });

        // Total akumulasi langkah kaki semua pengguna hari ini
        const stepsAggregate = await prisma.dailySensorLog.aggregate({
          where: {
            date: {
              gte: todayStart,
            },
          },
          _sum: {
            step_count: true,
          },
        });

        const totalStepsToday = stepsAggregate._sum.step_count || 0;

        // 5. Agregasi data pengguna
        const totalUsers = await prisma.user.count();
        const totalLinkedUsers = await prisma.user.count({
          where: {
            phone_number: {
              not: null,
            },
          },
        });

        // 6. Agregasi aktivitas sistem
        const totalFoodLogs = await prisma.foodLog.count();
        const totalChats = await prisma.interventionChat.count();

        // 7. Satukan semua metrik
        return {
          health: {
            status: databaseConnected ? "healthy" : "degraded",
            uptime_seconds: Math.round(process.uptime()),
            database_connected: databaseConnected,
          },
          ai: aiStats,
          users: {
            total_users: totalUsers,
            total_linked_users: totalLinkedUsers,
            daily_active_users: dauCount,
          },
          activity: {
            total_food_logs_recorded: totalFoodLogs,
            total_chats_recorded: totalChats,
            total_step_count_accumulated: totalStepsToday,
          },
        };
      } catch (err) {
        console.error("[ADMIN] Gagal mengambil statistik dasbor:", err);
        set.status = 500;
        return { message: "Internal server error during stats compilation" };
      }
    },
    {
      headers: t.Object({
        "x-api-key": t.String({
          error: "Header 'x-api-key' is required for admin authorization",
        }),
      }),
      detail: {
        tags: ["admin"],
        summary: "Retrieve system health status, AI metrics, and aggregate user analytics",
      },
    }
  );
export default adminRoutes;
