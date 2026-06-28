/**
 * Shared TypeScript contracts for the Glicoo monorepo.
 *
 * Purpose:
 * Menyediakan satu sumber kebenaran (single source of truth) untuk bentuk data
 * yang dipertukarkan antara `apps/web` dan `apps/backend`. Interface di bawah
 * MENCERMINKAN `apps/backend/prisma/schema.prisma` secara 1:1 — jika ada migrasi
 * schema baru, file ini WAJIB disesuaikan.
 *
 * Used By:
 * apps/web, apps/backend (saat type sharing untuk API payload/DB row dibutuhkan)
 *
 * Depends On:
 * None (pure type declarations)
 *
 * Impact:
 * Perubahan di sini berdampak pada seluruh consumer TS. Mobile (Dart) tidak
 * terpengaruh — ekosistemnya terisolasi (lihat MONOREPO_MAP.md §1).
 */

// ─── Enums (string literal unions — sinkron dengan kolom DB) ───

/** Pengirim sebuah pesan dalam riwayat intervensi. */
export type SenderType = "USER" | "AI_AGENT";

/**
 * Momen intervensi sebuah pesan/chat.
 * [CONTRACT] Harus identik dengan nilai di `intervention_chats.intervention_moment`.
 */
export type InterventionMoment =
  | "MORNING_CHECK"
  | "AFTERNOON_WALK"
  | "NIGHT_SLEEP"
  | "MEAL_TIME"
  | "NONE";

// ─── Models (mirror Prisma schema.prisma) ───

/**
 * Profil pengguna + data kesehatan dasar untuk kalkulasi risiko FINDRISC.
 * Maps to table: `users`
 *
 * [PRISMA SYNC] Semua field di bawah 1:1 dengan schema.prisma model User
 */
export interface User {
  /** UUID primary key (@db.Uuid) */
  id: string;
  name: string;
  /** Menyimpan Chat ID Telegram (sebagai identifier bot) saat sudah ter-link. Unique constraint. */
  phone_number: string | null;
  age: number | null;
  /** Berat badan dalam kg (Float di Prisma) */
  weight: number | null;
  /** Tinggi badan dalam cm (Float di Prisma) */
  height: number | null;
  has_family_history: boolean | null;
  /** Skor risiko Diabetes 0-100 hasil kalkulasi FINDRISC. Default: 0.0 */
  risk_score: number | null;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Agregasi sensor harian (langkah & screen time).
 * Maps to table: `daily_sensor_logs` (unique constraint: [user_id, date])
 *
 * [PRISMA SYNC] Semua field di bawah 1:1 dengan schema.prisma model DailySensorLog
 */
export interface DailySensorLog {
  /** UUID primary key (@db.Uuid, default: uuid()) */
  id: string;
  /** Foreign key ke users.id (Cascade on delete) */
  user_id: string;
  /** Tanggal log (@db.Date) */
  date: Date;
  /** Jumlah langkah hari ini. Default: 0 */
  step_count: number;
  /** Total screen time dalam menit. Default: 0 */
  screen_time_minutes: number;
  updated_at: Date;
}

/**
 * Pencatatan makanan via teks bebas (Natural Language).
 * Maps to table: `food_logs`.
 * Kolom estimasi gizi diisi asynchronously oleh AI (lihat food.service.ts).
 *
 * [PRISMA SYNC] Semua field di bawah 1:1 dengan schema.prisma model FoodLog
 */
export interface FoodLog {
  /** UUID primary key (@db.Uuid, default: uuid()) */
  id: string;
  /** Foreign key ke users.id (Cascade on delete) */
  user_id: string;
  /** Deskripsi makanan dalam Natural Language */
  description: string;
  /** Timestamp log dibuat. Default: now() */
  logged_at: Date;
  /** Estimasi kalori (Int). Diisi AI secara async */
  estimated_calories: number | null;
  /** Estimasi gula dalam gram (Float). Diisi AI secara async */
  estimated_sugar_grams: number | null;
  /** Feedback/saran AI terkait makanan ini */
  ai_feedback: string | null;
}

/**
 * Riwayat percakapan AI (Telegram & in-app chatbot).
 * Maps to table: `intervention_chats`.
 *
 * [PRISMA SYNC] Semua field di bawah 1:1 dengan schema.prisma model InterventionChat
 */
export interface InterventionChat {
  /** UUID primary key (@db.Uuid, default: uuid()) */
  id: string;
  /** Foreign key ke users.id (Cascade on delete) */
  user_id: string;
  /** Isi pesan chat */
  message: string;
  /** "USER" | "AI_AGENT" (String di Prisma, disesuaikan dengan SenderType) */
  sender_type: SenderType;
  /** Momen intervensi sesuai InterventionMoment type */
  intervention_moment: InterventionMoment;
  /** Timestamp pesan dibuat. Default: now() */
  created_at: Date;
}

/**
 * Token OTP ephemeral (6 digit) untuk deep-link Telegram.
 * Maps to table: `bot_link_tokens`.
 * [WARNING] Selalu cek `expires_at` sebelum menerima; hapus setelah dipakai.
 *
 * [PRISMA SYNC] Semua field di bawah 1:1 dengan schema.prisma model BotLinkToken
 */
export interface BotLinkToken {
  /** UUID primary key (@db.Uuid, default: uuid()) */
  id: string;
  /** Foreign key ke users.id (Cascade on delete) */
  user_id: string;
  /** Token unik 6 digit (unique constraint) */
  token: string;
  /** Timestamp token dibuat. Default: now() */
  created_at: Date;
  /** Timestamp token kadaluarsa */
  expires_at: Date;
}

// ─── API Request Payloads (kontrak wire format) ───

/**
 * [CONTRACT] Body request `POST /api/v1/sensors/sync`.
 * Lihat API_CONTRACTS.md §2A.
 */
export interface SensorSyncRequest {
  date: string; // YYYY-MM-DD
  step_count: number;
  screen_time_minutes: number;
}

/**
 * [CONTRACT] Body request `POST /api/v1/food/log`.
 * Lihat API_CONTRACTS.md §2B.
 */
export interface FoodLogRequest {
  description: string;
}

/**
 * [CONTRACT] Body request `POST /api/v1/chat` (in-app chatbot).
 * `context` bersifat opsional dan menyediakan data sensor real-time dari mobile.
 */
export interface ChatRequest {
  message: string;
  context?: ChatContext;
}

/** Konteks kesehatan real-time yang dikirim mobile ke endpoint chat. */
export interface ChatContext {
  today_steps?: number;
  today_screen_time_minutes?: number;
  age?: number;
  weight?: number;
  height?: number;
  waist_circumference?: number;
  findrisc_score?: number;
}

/**
 * [CONTRACT] Response `GET /api/v1/bot/link` — OTP + deep link Telegram.
 */
export interface BotLinkResponse {
  token: string;
  expiresAt: string; // ISO 8601
  telegramLink: string;
}
