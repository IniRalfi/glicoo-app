// Shared configuration for Glico monorepo

export const APP_CONFIG = {
  name: "Glico",
  description: "Agentic AI for Early Diabetes Prevention",
  version: "0.1.0",
} as const;

export const API_CONFIG = {
  baseUrl: process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001",
  timeout: 10000,
} as const;

export const SUPABASE_CONFIG = {
  url: process.env.NEXT_PUBLIC_SUPABASE_URL || "",
  anonKey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || "",
} as const;

export const SENSOR_SYNC_INTERVAL_HOURS = 4;
export const MAX_FOOD_LOG_LENGTH = 500;
