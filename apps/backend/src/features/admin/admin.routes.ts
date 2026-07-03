import { Elysia, t } from "elysia";
import { prisma } from "../../core/db";
import { aiService } from "../ai/ai.service";

/**
 * Purpose:
 * Router untuk fitur Administrasi & Monitoring Glico Dashboard.
 * Menyediakan metrik performa AI, status kesehatan database,
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

// Fallback in-memory metrics in case of any database read failures
let inMemoryPageViews = 0;
let inMemoryApkDownloads = 0;

export const adminRoutes = new Elysia({ prefix: "/admin" })
  .get(
    "/stats",
    async ({ headers, set }) => {
      try {
        const adminApiKey = process.env.BACKEND_ADMIN_API_KEY;
        const requestApiKey = headers["x-api-key"];

        if (!adminApiKey) {
          console.error("[ADMIN] BACKEND_ADMIN_API_KEY is not set!");
          set.status = 503;
          return { message: "Admin endpoint unavailable: server misconfiguration" };
        }

        if (!requestApiKey || requestApiKey !== adminApiKey) {
          set.status = 401;
          return { message: "Unauthorized: Invalid admin API Key" };
        }

        // Cek status database
        let databaseConnected = false;
        try {
          await prisma.$queryRaw`SELECT 1`;
          databaseConnected = true;
        } catch (e) {
          console.error("[ADMIN] Database connection failed check:", e);
        }

        // Ambil data stats AI
        const aiStatsRaw = aiService.getStats();
        const averageLatency =
          aiStatsRaw.callsCount > 0
            ? Math.round(aiStatsRaw.totalLatencyMs / aiStatsRaw.callsCount)
            : 0;

        const aiStats = {
          active_provider: aiStatsRaw.activeProvider,
          fallback_chain: aiStatsRaw.fallbackChain,
          success_count_today: aiStatsRaw.successToday,
          failure_count_today: aiStatsRaw.failuresToday,
          average_latency_ms: averageLatency,
        };

        const todayStart = new Date();
        todayStart.setHours(0, 0, 0, 0);

        let dauCount = 0;
        let totalStepsToday = 0;
        let totalUsers = 0;
        let totalLinkedUsers = 0;
        let totalFoodLogs = 0;
        let totalChats = 0;

        if (databaseConnected) {
          try {
            dauCount = await prisma.dailySensorLog.count({
              where: { date: { gte: todayStart } },
            });

            const stepsAggregate = await prisma.dailySensorLog.aggregate({
              where: { date: { gte: todayStart } },
              _sum: { step_count: true },
            });
            totalStepsToday = stepsAggregate._sum.step_count || 0;

            totalUsers = await prisma.user.count();
            totalLinkedUsers = await prisma.user.count({
              where: { phone_number: { not: null } },
            });

            totalFoodLogs = await prisma.foodLog.count();
            totalChats = await prisma.interventionChat.count();
          } catch (dbErr) {
            console.error("[ADMIN] Failed querying some core tables:", dbErr);
          }
        }

        // Read Web Metrics dari table web_metrics
        let pageViews = inMemoryPageViews;
        let apkDownloads = inMemoryApkDownloads;

        if (databaseConnected) {
          try {
            const metrics = await prisma.webMetric.findMany();
            const viewsOpt = metrics.find((m) => m.key === "page_views");
            const downloadsOpt = metrics.find((m) => m.key === "apk_downloads");

            if (viewsOpt) pageViews = viewsOpt.count;
            if (downloadsOpt) apkDownloads = downloadsOpt.count;
          } catch (e) {
            console.warn("[ADMIN] web_metrics table query failed, using in-memory fallbacks.");
          }
        }

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
          web_metrics: {
            page_views: pageViews,
            apk_downloads: apkDownloads,
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
  )
  .post(
    "/hit",
    async ({ body }) => {
      const { key } = body;

      // Update in-memory fallback
      if (key === "page_views") {
        inMemoryPageViews++;
      } else if (key === "apk_downloads") {
        inMemoryApkDownloads++;
      }

      // Try update database
      try {
        await prisma.webMetric.upsert({
          where: { key },
          update: { count: { increment: 1 } },
          create: { key, count: 1 },
        });
      } catch (dbErr) {
        console.warn(
          `[ADMIN] Failed database webMetric upsert for '${key}', recorded in-memory only.`,
          dbErr
        );
      }

      return {
        success: true,
        key,
        current_in_memory_count: key === "page_views" ? inMemoryPageViews : inMemoryApkDownloads,
      };
    },
    {
      body: t.Object({
        key: t.Union([t.Literal("page_views"), t.Literal("apk_downloads")]),
      }),
      detail: {
        tags: ["admin"],
        summary: "Record landing page views or APK download clicks",
      },
    }
  );

export default adminRoutes;
