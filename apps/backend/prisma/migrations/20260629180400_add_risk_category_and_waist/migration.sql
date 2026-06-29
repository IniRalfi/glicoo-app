-- Add risk_category and waist_circumference columns to users table
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "risk_category" TEXT DEFAULT 'Belum Tes';
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "waist_circumference" DOUBLE PRECISION;
