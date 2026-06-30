#!/usr/bin/env bun
/**
 * [ID] Script debugging untuk WhatsApp reminders
 * [EN] Debugging script for WhatsApp reminders
 *
 * Purpose: Diagnose why WhatsApp users don't receive cron reminders
 */

import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  console.log("\n🔍 === DEBUG: WhatsApp Reminders Configuration ===\n");

  // 1. Check environment variables
  console.log("📋 Environment Variables:");
  console.log(`   OPENWA_BASE_URL: ${process.env.OPENWA_BASE_URL || "❌ NOT SET"}`);
  console.log(
    `   OPENWA_API_KEY: ${process.env.OPENWA_API_KEY ? "✅ SET (length: " + process.env.OPENWA_API_KEY.length + ")" : "❌ NOT SET"}`
  );
  console.log(`   OPENWA_SESSION_ID: ${process.env.OPENWA_SESSION_ID || "❌ NOT SET"}`);
  console.log(`   CRON_SECRET: ${process.env.CRON_SECRET ? "✅ SET" : "❌ NOT SET"}`);
  console.log("");

  // 2. Check users with bot connections
  const allUsers = await prisma.user.findMany({
    select: {
      id: true,
      name: true,
      bot_platform: true,
      bot_chat_id: true,
    },
  });

  console.log(`👥 Total Users in Database: ${allUsers.length}`);
  console.log("");

  const telegramUsers = allUsers.filter((u) => u.bot_platform === "TELEGRAM");
  const whatsappUsers = allUsers.filter((u) => u.bot_platform === "WHATSAPP");
  const noConnection = allUsers.filter((u) => !u.bot_platform || !u.bot_chat_id);

  console.log(`📱 Platform Distribution:`);
  console.log(`   Telegram: ${telegramUsers.length} users`);
  console.log(`   WhatsApp: ${whatsappUsers.length} users`);
  console.log(`   No Connection: ${noConnection.length} users`);
  console.log("");

  // 3. Show WhatsApp users details
  if (whatsappUsers.length > 0) {
    console.log("📞 WhatsApp Connected Users:");
    whatsappUsers.forEach((user, idx) => {
      console.log(`   ${idx + 1}. ${user.name}`);
      console.log(`      - ID: ${user.id}`);
      console.log(`      - Chat ID: ${user.bot_chat_id}`);
      console.log(`      - Platform: ${user.bot_platform}`);
      console.log("");
    });
  } else {
    console.log("⚠️  WARNING: No WhatsApp users found in database!");
    console.log("   This is why reminders aren't being sent to WhatsApp.");
    console.log("");
  }

  // 4. Show Telegram users for comparison
  if (telegramUsers.length > 0) {
    console.log("✈️  Telegram Connected Users (for comparison):");
    telegramUsers.forEach((user, idx) => {
      console.log(`   ${idx + 1}. ${user.name}`);
      console.log(`      - Chat ID: ${user.bot_chat_id}`);
      console.log("");
    });
  }

  // 5. Check today's sensor data for step count reminders
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const todaySensorLogs = await prisma.dailySensorLog.findMany({
    where: { date: today },
    include: {
      user: {
        select: {
          name: true,
          bot_platform: true,
          bot_chat_id: true,
        },
      },
    },
  });

  console.log(`📊 Today's Sensor Logs (${today.toISOString().split("T")[0]}):`);
  console.log(`   Total logs: ${todaySensorLogs.length}`);

  if (todaySensorLogs.length > 0) {
    todaySensorLogs.forEach((log) => {
      const platform = log.user.bot_platform || "No Connection";
      const icon = platform === "TELEGRAM" ? "✈️" : platform === "WHATSAPP" ? "📞" : "⚠️";
      console.log(`   ${icon} ${log.user.name}: ${log.step_count} steps (${platform})`);
    });
  }
  console.log("");

  // 6. Recommendations
  console.log("💡 Diagnosis & Recommendations:");

  if (whatsappUsers.length === 0) {
    console.log("   ❌ ROOT CAUSE: No users have bot_platform='WHATSAPP' in database");
    console.log("   ✅ SOLUTION:");
    console.log("      1. Connect WhatsApp via OTP flow in mobile app");
    console.log("      2. Or manually update database:");
    console.log("         UPDATE users SET bot_platform='WHATSAPP', bot_chat_id='628xxxxx@c.us'");
    console.log("         WHERE id='your-user-id';");
  } else {
    console.log("   ✅ WhatsApp users exist in database");

    if (!process.env.OPENWA_API_KEY || !process.env.OPENWA_BASE_URL) {
      console.log("   ❌ OpenWA environment variables not configured properly");
      console.log("   ✅ Check .env file for OPENWA_* variables");
    } else {
      console.log("   ✅ OpenWA environment variables are set");
      console.log("   ⚠️  Next steps:");
      console.log("      1. Check OpenWA server logs at wa.glicoo.my.id");
      console.log(
        "      2. Test manual send via: curl -X POST https://api.glicoo.my.id/bot/cron/test-whatsapp"
      );
      console.log("      3. Verify OpenWA session is active");
    }
  }

  console.log("\n✅ Debug check completed.\n");
}

main()
  .catch((e) => {
    console.error("❌ Error:", e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
