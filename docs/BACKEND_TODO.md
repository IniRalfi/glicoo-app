# ⚙️ BACKEND SPRINT — Glico Elysia.js & Database

> Ref: `docs/ROADMAP.md` Fase 2 · `docs/DATABASE_SCHEMA.md` · `docs/API_CONTRACTS.md`

## 🎯 Fokus Sprint: Database Migration, Auth Middleware, & API Endpoints

---

## Phase 1 — Database & Prisma ORM Setup ❌

- [ ] **Setup Prisma ORM** di `apps/backend`:
  - Install dependencies: `prisma`, `@prisma/client`.
  - Inisialisasi Prisma: `bunx prisma init`.
- [ ] **Desain Skema Database** (`prisma/schema.prisma`):
  - Model `User` (id, name, phone_number, age, weight, height, has_family_history, risk_score).
  - Model `DailySensorLog` (id, user_id, date, step_count, screen_time_minutes, updated_at).
  - Model `FoodLog` (id, user_id, description, logged_at, estimated_calories, estimated_sugar_grams, ai_feedback).
  - Model `InterventionChat` (id, user_id, message, sender_type, intervention_moment, created_at).
- [ ] **Koneksi Database & Migrasi**:
  - Ambil Connection String Supabase PostgreSQL (Transaction & Direct URL).
  - Konfigurasi file `.env` di `apps/backend` (gunakan template `.env.example`).
  - Jalankan migrasi awal: `bunx prisma migrate dev --name init`.
- [ ] **Penulisan Seed Script** (Opsional untuk testing/mock data).

---

## Phase 2 — Project Architecture & Core Config ❌

- [ ] **Struktur Folder Modular**:
  - Pecah routing Elysia menjadi:
    ```text
    src/
    ├── index.ts
    ├── core/
    │   ├── db.ts           (Prisma client instance)
    │   └── middlewares/    (Supabase JWT verifier)
    └── features/
        ├── sensors/        (sync routes)
        ├── food/           (logging routes)
        └── bot/            (linking & verification routes)
    ```
- [ ] **Inisialisasi Database Client**:
  - Ekspor instansi `PrismaClient` tunggal di `src/core/db.ts` untuk mencegah kebocoran koneksi.

---

## Phase 3 — Middleware & Keamanan (Supabase JWT) ❌

- [ ] **Supabase JWT Verifier Middleware**:
  - Ambil header `Authorization: Bearer <JWT_TOKEN>`.
  - Gunakan `JWT_SECRET` milik Supabase Project untuk memverifikasi keabsahan token.
  - Masukkan data `userId` hasil dekripsi JWT ke dalam context Elysia (akses via `derive` atau plugin).
  - Return `401 Unauthorized` jika token tidak valid/kedaluwarsa.

---

## Phase 4 — Implementasi API Endpoints ❌

### A. Sensor Sync (`/sensors/sync`)
- [ ] Buat route `POST /api/v1/sensors/sync`.
- [ ] Terapkan middleware JWT (hanya user terotentikasi yang bisa sinkronisasi).
- [ ] Schema validation menggunakan Elysia `t.Object` (`date`, `step_count`, `screen_time_minutes`).
- [ ] Implementasi logika database (Upsert `DailySensorLog` berdasarkan `user_id` + `date`).

### B. Food Logging (`/food/log`)
- [ ] Buat route `POST /api/v1/food/log`.
- [ ] Terapkan middleware JWT.
- [ ] Schema validation (`description` teks makanan).
- [ ] Implementasi penyimpanan ke database `FoodLog`.
- [ ] Kirim trigger webhook ke n8n secara asinkronus (non-blocking) untuk memulai analisis gizi AI.

### C. Bot Linking & Deep Link (`/bot/*`)
- [ ] Buat tabel/mekanisme penyimpanan token OTP sementara (`BotLinkToken`) dengan masa aktif 10 menit.
- [ ] Buat route `GET /api/v1/bot/link` (terlindungi JWT):
  - Generate token OTP acak unik.
  - Simpan relasi `userId` ↔ `token` di database.
  - Return URL Telegram deep link: `https://t.me/GlicoBot?start=<TOKEN>`.
- [ ] Buat route `POST /api/v1/bot/verify` (Admin/n8n only — menggunakan API Key / Admin token verification):
  - Terima `token` dan `chatId` dari Telegram.
  - Validasi token OTP: jika cocok, simpan `chatId` Telegram ke kolom `phone_number` atau kolom khusus `telegram_chat_id` di profil `User`.
  - Hapus token OTP dari database setelah verifikasi sukses.

---

## Phase 5 — Dokumentasi Swagger & Integration Test ❌

- [ ] Update Swagger UI tags di `/docs` agar rapi dan terorganisir per kelompok.
- [ ] Uji coba seluruh API menggunakan berkas test HTTP atau curl.
- [ ] Verifikasi format response agar konsisten dengan `docs/API_CONTRACTS.md`.
