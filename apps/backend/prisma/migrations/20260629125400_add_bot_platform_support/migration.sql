-- CreateEnum
CREATE TYPE "BotPlatform" AS ENUM ('TELEGRAM', 'WHATSAPP');

-- AlterTable: Add bot_platform and bot_chat_id columns to users table
ALTER TABLE "users" ADD COLUMN "bot_platform" "BotPlatform",
ADD COLUMN "bot_chat_id" TEXT;

-- AlterTable: Add platform column to bot_link_tokens table
ALTER TABLE "bot_link_tokens" ADD COLUMN "platform" "BotPlatform" NOT NULL DEFAULT 'TELEGRAM';

-- Data Migration: Migrate existing Telegram users
-- If phone_number exists, set bot_platform to TELEGRAM and copy to bot_chat_id
UPDATE "users"
SET 
  "bot_platform" = 'TELEGRAM'::"BotPlatform",
  "bot_chat_id" = "phone_number"
WHERE "phone_number" IS NOT NULL;

-- Remove default from platform column after data migration
ALTER TABLE "bot_link_tokens" ALTER COLUMN "platform" DROP DEFAULT;
