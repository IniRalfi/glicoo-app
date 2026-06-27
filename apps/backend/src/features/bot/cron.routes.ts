import { Elysia, t } from "elysia";
import { 
  sendMorningReminders, 
  sendAfternoonReminders, 
  sendEveningReminders 
} from "./scheduler.service";

/**
 * Purpose:
 * Router to trigger reminders via HTTP requests (specifically for serverless environments like Vercel).
 * Secures requests using a CRON_SECRET token.
 *
 * Used By:
 * src/index.ts
 *
 * Depends On:
 * scheduler.service.ts
 */
export const cronRoutes = new Elysia({ prefix: "/cron" })
  .derive(({ headers: { authorization } }) => {
    return {
      isCronAuth: () => {
        const cronSecret = process.env.CRON_SECRET || "dev-cron-secret";
        return authorization === `Bearer ${cronSecret}`;
      }
    };
  })
  .get(
    "/morning",
    async ({ isCronAuth, set }) => {
      if (!isCronAuth()) {
        set.status = 401;
        return { error: "Unauthorized: Invalid Cron Secret" };
      }
      await sendMorningReminders();
      return { success: true, message: "Morning reminders triggered successfully" };
    },
    {
      detail: {
        tags: ["cron"],
        summary: "Trigger morning reminders for linked Telegram users"
      }
    }
  )
  .get(
    "/afternoon",
    async ({ isCronAuth, set }) => {
      if (!isCronAuth()) {
        set.status = 401;
        return { error: "Unauthorized: Invalid Cron Secret" };
      }
      await sendAfternoonReminders();
      return { success: true, message: "Afternoon reminders triggered successfully" };
    },
    {
      detail: {
        tags: ["cron"],
        summary: "Trigger afternoon physical activity/step reminders"
      }
    }
  )
  .get(
    "/evening",
    async ({ isCronAuth, set }) => {
      if (!isCronAuth()) {
        set.status = 401;
        return { error: "Unauthorized: Invalid Cron Secret" };
      }
      await sendEveningReminders();
      return { success: true, message: "Evening/bedtime reminders triggered successfully" };
    },
    {
      detail: {
        tags: ["cron"],
        summary: "Trigger evening screen-time and bedtime reminders"
      }
    }
  );
