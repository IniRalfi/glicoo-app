import { sendWhatsAppMessage } from "./features/bot/whatsapp.service";

async function main() {
  console.log("\n🧪 Testing WhatsApp Message Send\n");

  const testChatId = "43448023433464@lid"; // From database
  const testMessage = "🧪 Test pesan dari scheduler debug script";

  console.log(`📤 Sending to: ${testChatId}`);
  console.log(`📝 Message: ${testMessage}\n`);

  try {
    const result = await sendWhatsAppMessage(testChatId, testMessage);

    if (result) {
      console.log("✅ Message sent successfully!");
    } else {
      console.log("❌ Message failed to send (returned false)");
    }
  } catch (error: any) {
    console.error("❌ Error sending message:");
    console.error(`   Type: ${error.name}`);
    console.error(`   Message: ${error.message}`);
    if (error.response) {
      console.error(`   Status: ${error.response.status}`);
      console.error(`   Data:`, error.response.data);
    }
  }
}

main();
