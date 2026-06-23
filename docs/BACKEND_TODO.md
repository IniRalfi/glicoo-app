# ⚙️ BACKEND SPRINT — Glico Elysia.js & Database

> Ref: `docs/ROADMAP.md` Fase 2 · `docs/DATABASE_SCHEMA.md` · `docs/API_CONTRACTS.md`

## 🎯 Fokus Sprint: Database Migration, Auth Middleware, & API Endpoints

---

## Phase 1 — Database & Prisma ORM Setup ✅

- [x] **Setup Prisma ORM** di `apps/backend`:
  - Install dependencies: `prisma`, `@prisma/client`.
  - Inisialisasi Prisma: `bunx prisma init` (menggunakan Prisma v7.8.0).
- [x] **Desain Skema Database** (`prisma/schema.prisma`):
  - Model `User` (id, name, phone_number, age, weight, height, has_family_history, risk_score).
  - Model `DailySensorLog` (id, user_id, date, step_count, screen_time_minutes, updated_at).
  - Model `FoodLog` (id, user_id, description, logged_at, estimated_calories, estimated_sugar_grams, ai_feedback).
  - Model `InterventionChat` (id, user_id, message, sender_type, intervention_moment, created_at).
  - Model `BotLinkToken` (id, user_id, token, created_at, expires_at).
- [x] **Koneksi Database & Migrasi**:
  - Ambil Connection String Supabase PostgreSQL (Transaction & Direct URL).
  - Konfigurasi file `.env` di `apps/backend`.
  - Jalankan migrasi awal: `bun run db:migrate --name init` (sukses diaplikasikan).
- [x] **Inisialisasi Database Client** (`db.ts`):
  - Membuat singleton `PrismaClient` dengan driver adapter `@prisma/adapter-pg` & `pg` (Wajib untuk Prisma 7).

---

## Phase 2 — Project Architecture & Core Config ✅

- [x] **Struktur Folder Modular**:
  - Pecah routing Elysia menjadi modular (features & core).
- [x] **Inisialisasi Database Client**:
  - Ekspor instansi `PrismaClient` tunggal di `src/core/db.ts` dengan Pool & Driver Adapter.

---

## Phase 3 — Middleware & Keamanan (Supabase JWT) ✅

- [x] **Supabase JWT Verifier Middleware**:
  - Mengekstrak header `Authorization: Bearer <JWT_TOKEN>`.
  - Menggunakan plugin `@elysiajs/jwt` dengan `JWT_SECRET`.
  - Menerapkan macro `isAuth: true` untuk mengamankan route secara elegan dan deklaratif.

---

## Phase 4 — Implementasi API Endpoints ✅

### A. Sensor Sync (`/sensors/sync`)
- [x] Buat route `POST /api/v1/sensors/sync`.
- [x] Terapkan middleware JWT.
- [x] Schema validation menggunakan Elysia `t.Object` (`date`, `step_count`, `screen_time_minutes`).
- [x] Implementasi logika database (Upsert `DailySensorLog` berdasarkan `user_id` + `date`).

### B. Food Logging (`/food/log`)
- [x] Buat route `POST /api/v1/food/log`.
- [x] Terapkan middleware JWT.
- [x] Schema validation (`description` teks makanan).
- [x] Implementasi penyimpanan ke database `FoodLog`.
- [x] Kirim trigger webhook ke n8n secara asinkronus (non-blocking) untuk memulai analisis gizi AI.

### C. Bot Linking & Deep Link (`/bot/*`)
- [x] Buat tabel/mekanisme penyimpanan token OTP sementara (`BotLinkToken`) dengan masa aktif 10 menit.
- [x] Buat route `GET /api/v1/bot/link` (terlindungi JWT):
  - Generate token OTP acak unik (6-digit).
  - Simpan relasi `userId` ↔ `token` di database.
  - Return URL Telegram deep link: `https://t.me/GlicoBot?start=<TOKEN>`.
- [x] Buat route `POST /api/v1/bot/verify` (Admin/n8n only — menggunakan API Key / Admin token verification):
  - Terima `token` dan `identifier` dari Telegram.
  - Validasi token OTP: jika cocok, simpan identifier ke kolom `phone_number` di profil `User`.
  - Hapus token OTP dari database setelah verifikasi sukses.

---

## Phase 5 — Dokumentasi Swagger & Integration Test ✅

- [x] Update Swagger UI tags di `/docs` agar rapi dan terorganisir per kelompok.
- [x] Uji coba seluruh API menggunakan berkas test HTTP atau curl.
- [x] Verifikasi format response agar konsisten dengan `docs/API_CONTRACTS.md`.
