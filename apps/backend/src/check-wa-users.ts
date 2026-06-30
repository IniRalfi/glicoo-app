import { prisma } from "./core/db";

async function main() {
  console.log("\n🔍 === Checking WhatsApp Reminder Configuration ===\n");

  // Check environment
  console.log("📋 Environment Variables:");
  console.log(`   OPENWA_BASE_URL: ${process.env.OPENWA_BASE_URL || "❌ NOT SET"}`);
  console.log(`   OPENWA_API_KEY: ${process.env.OPENWA_API_KEY ? "✅ SET" : "❌ NOT SET"}`);
  console.log(`   OPENWA_SESSION_ID: ${process.env.OPENWA_SESSION_ID || "❌ NOT SET"}`);
  console.log("");

  // Check users
  const users = await prisma.user.findMany({
    select: {
      name: true,
      bot_platform: true,
      bot_chat_id: true,
    },
  });

  console.log(`👥 Total Users: ${users.length}\n`);

  const whatsappUsers = users.filter((u) => u.bot_platform === "WHATSAPP");
  const telegramUsers = users.filter((u) => u.bot_platform === "TELEGRAM");

  console.log(`📱 Platform Distribution:`);
  console.log(`   📞 WhatsApp: ${whatsappUsers.length} users`);
  console.log(`   ✈️  Telegram: ${telegramUsers.length} users\n`);

  if (whatsappUsers.length > 0) {
    console.log("📞 WhatsApp Users:");
    whatsappUsers.forEach((u) => {
      console.log(`   - ${u.name}`);
      console.log(`     Chat ID: ${u.bot_chat_id}\n`);
    });
  } else {
    console.log("❌ ROOT CAUSE FOUND:");
    console.log("   No users with bot_platform='WHATSAPP' in database!");
    console.log("   Scheduler cannot send reminders to WhatsApp.\n");
    console.log("💡 SOLUTION:");
    console.log("   Connect WhatsApp via OTP flow in mobile app\n");
  }

  if (telegramUsers.length > 0) {
    console.log("✈️  Telegram Users (for comparison):");
    telegramUsers.forEach((u) => {
      console.log(`   - ${u.name}`);
      console.log(`     Chat ID: ${u.bot_chat_id}\n`);
    });
  }

  await prisma.$disconnect();
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
