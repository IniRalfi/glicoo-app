// Shared TypeScript types for Glico monorepo
// Generated from Prisma schema - will be populated after Task 1.3

export interface User {
  id: string;
  email: string;
  name: string | null;
  avatarUrl: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface SensorData {
  id: string;
  userId: string;
  steps: number;
  screenTimeMinutes: number;
  recordedAt: Date;
  syncedAt: Date | null;
  createdAt: Date;
}

export interface FoodLog {
  id: string;
  userId: string;
  description: string;
  calories: number | null;
  protein: number | null;
  carbs: number | null;
  fat: number | null;
  loggedAt: Date;
  createdAt: Date;
}

export interface Intervention {
  id: string;
  userId: string;
  type: "MORNING_WALK" | "EVENING_SLEEP" | "FOOD_FEEDBACK" | "CUSTOM";
  title: string;
  message: string;
  sentAt: Date;
  readAt: Date | null;
  createdAt: Date;
}

export interface BotLink {
  id: string;
  userId: string;
  platform: "TELEGRAM" | "WHATSAPP";
  externalId: string;
  verifiedAt: Date | null;
  createdAt: Date;
}
