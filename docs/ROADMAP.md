# 🗺️ GLICO DEVELOPMENT ROADMAP & TO-DO

Pendekatan pengembangan menggunakan metode **Horizontal (Per Aplikasi)**.

> ⚠️ **ATURAN MUTLAK UNTUK AI:**
> Saat kamu membaca tugas dari `docs/TODO.md` dan diarahkan ke Roadmap ini, kamu **WAJIB** membuka `.roo/rules/rules.md` terlebih dahulu.
> Gunakan dokumen indeks di sana (seperti `DATABASE_SCHEMA.md` atau `API_CONTRACTS.md`) sebagai panduan spesifikasi teknis agar kodemu tidak melanggar kontrak arsitektur yang sudah disepakati.

---

## Phase 1: 🏗️ Foundation & Shared Packages (The Glue)

Fase ini mengamankan fondasi monorepo agar Web dan Mobile memiliki sumber kebenaran tipe data yang sama.

- [x] **Task 1.1:** Inisialisasi Bun Workspaces (`apps/web`, `apps/backend`, `apps/mobile`, `packages/types`). ✅
- [~] **Task 1.2:** Setup Supabase Project & inisialisasi tabel berdasarkan `DATABASE_SCHEMA.md`.
  - ✅ Supabase project sudah dibuat (`dsspywhpfjxmrlxwycyi`)
  - ✅ Auth providers (Email, Google OAuth) sudah dikonfigurasi
  - ❌ Tabel database belum dibuat / belum di-migrasi
- [ ] **Task 1.3:** Konfigurasi Prisma ORM di `apps/backend` dan migrasi database awal. ❌
- [~] **Task 1.4:** Buat TypeScript Interfaces di `packages/types`.
  - ✅ Interfaces manual sudah ada (`User`, `SensorData`, `FoodLog`, `Intervention`, `BotLink`)
  - ❌ Belum auto-generate dari Prisma schema (Task 1.3 belum)

---

## Phase 2: ⚙️ Backend API (Elysia.js)

Membangun logika server, validasi, dan jembatan ke n8n.

- [~] **Task 2.1:** Setup struktur Elysia.js + Swagger UI untuk dokumentasi otomatis.
  - ✅ Elysia.js + Swagger UI sudah jalan di `apps/backend/src/index.ts`
  - ✅ Health check endpoint (`GET /health`) sudah ada
  - ❌ Struktur routing modular belum dipecah per domain
- [ ] **Task 2.2:** Buat Middleware untuk memvalidasi JWT dari Supabase Auth. ❌
  - `@elysiajs/jwt` sudah di-install tapi belum dipakai untuk validasi Supabase JWT
- [ ] **Task 2.3:** Buat rute `POST /sensors/sync` untuk menerima data agregasi dari Mobile. ❌
- [ ] **Task 2.4:** Buat rute `POST /food/log` (simpan ke database dan teruskan trigger webhook ke n8n). ❌
- [ ] **Task 2.5:** Buat rute Deep Linking `GET /bot/link` dan `POST /bot/verify` untuk sinkronisasi Telegram/WA. ❌

---

## Phase 3: 🌐 Web Dashboard (Next.js)

Membangun antarmuka pemantauan dengan gaya Minimalist Bento Grid.

- [~] **Task 3.1:** Setup Next.js App Router, TailwindCSS, dan Zustand.
  - ✅ Next.js 14 App Router + TailwindCSS v4 (Tailwind v4) sudah jalan
  - ✅ Font Google (Inter + Rammetto One) via `next/font`
  - ✅ `@theme` block di `globals.css` — brand scale, semantic aliases, typography tokens
  - ❌ Zustand belum di-install (state management)
- [ ] **Task 3.2:** Integrasi Supabase Auth (Google OAuth) untuk login Web. ❌
- [~] **Task 3.3:** Buat komponen UI Bento Grid (Card base, rounded, pastel, non-neobrutalism).
  - ✅ Landing page "COMING SOON" sudah ada (`home-content.tsx`)
  - ✅ Bento cards untuk fitur preview
  - ❌ Belum ada reusable Bento Grid component
- [ ] **Task 3.4:** Buat halaman Dashboard Utama (Menampilkan agregasi langkah, screen time, dan log intervensi chat). ❌

---

## Phase 4: 📱 Mobile App (Flutter)

Aplikasi untuk pengguna akhir, berfokus pada koleksi data sensor pasif.

- [x] **Task 4.1:** Setup struktur Flutter dengan `hooks_riverpod`. ✅
  - ✅ `hooks_riverpod` + `flutter_hooks` + `freezed` + `build_runner`
  - ✅ Feature-based structure: `lib/core/` (theme, widgets, env) + `lib/features/` (auth, splash, onboarding, legal)
  - ✅ `ProviderScope` + `StateNotifier` pattern
- [x] **Task 4.2:** Integrasi Supabase Auth (Google OAuth) di Mobile. ✅
  - ✅ Native `google_sign_in` plugin (account picker, bukan browser)
  - ✅ Supabase `signInWithIdToken` flow
  - ✅ Email/password login + register + forgot password
  - ✅ Auth state management (freezed sealed class)
  - ✅ Logout flow + auto-redirect ke login
- [ ] **Task 4.3:** Implementasi Background Task (Workmanager) untuk membaca data _Pedometer_ (Langkah) dan _Screen Time_. ❌
- [ ] **Task 4.4:** Buat Cron lokal di Flutter untuk sinkronisasi data sensor ke endpoint Elysia `/sensors/sync` setiap beberapa jam. ❌
- [ ] **Task 4.5:** Buat UI input teks untuk Log Makanan, tembak ke endpoint Elysia `/food/log`. ❌
- [ ] **Task 4.6:** Implementasi UI Deep Linking bot Telegram/WA. ❌

### 🎁 Mobile — Extra Work (di luar roadmap, tapi penting)

- [x] **Design System** — `AppColors` (brand 1–10 + semantic), `AppTypography` (Rammetto One + Inter), `AppSpacing`, `AppTheme` (Material 3)
- [x] **Shared Widgets** — `BentoCard`, `PrimaryButton`, `SkipButton`, `PageIndicator`
- [x] **Splash Screen** — Gradient animasi + floating logo
- [x] **Onboarding (3 halaman)** — PageView illustrations + AnimatedSwitcher text fade + skip button + custom dots
- [x] **Legal Screen** — Terms of Service + Privacy Policy (checkbox consent)
- [x] **Login Screen** — Email + password, forgot password link, Google OAuth, navigasi ke Register
- [x] **Register Screen** — Email + nama + kata sandi + konfirmasi kata sandi, Google OAuth
- [x] **Forgot Password Screen** — Reset password via email, success view
- [x] **Auth Flow** — Splash → Onboarding (first-time) → Legal → Auth → Home, with auto-redirect

---

## Phase 5: 🤖 AI Engine & Chatbot (n8n + Gemini)

Menghidupkan "otak" dari Glico.

- [ ] **Task 5.1:** Setup webhook di n8n untuk menerima trigger dari Telegram/WA dan Elysia. ❌
- [ ] **Task 5.2:** Masukkan `AI_AGENT_PROMPTS.md` ke dalam node Gemini di n8n. ❌
- [ ] **Task 5.3:** Buat alur Socratic Questioning & XAI untuk membalas log makanan. ❌
- [ ] **Task 5.4:** Buat Scheduler di n8n (Cron) untuk membaca database Supabase dan mengirim intervensi pagi (jalan kaki) dan malam (teguran tidur). ❌

---

## 📊 Progress Summary

| Phase             | Status               | Progress                                                          |
| ----------------- | -------------------- | ----------------------------------------------------------------- |
| 1. Foundation     | 🟡 In Progress       | ~40% — workspace ✅, Supabase project ✅, DB tables ❌, Prisma ❌ |
| 2. Backend API    | 🟡 In Progress       | ~15% — Elysia scaffold ✅, endpoints ❌                           |
| 3. Web Dashboard  | 🟡 In Progress       | ~20% — Next.js + Tailwind ✅, auth + dashboard ❌                 |
| **4. Mobile App** | **🟢 Good Progress** | **~45% — auth + UI shell ✅, sensors + food + bot ❌**            |
| 5. AI Engine      | 🔴 Not Started       | 0%                                                                |

### 🔥 Prioritas Selanjutnya (Suggested)

1. **Mobile Phase 4** — Bottom Navigation Shell (Home, Quests, Bot Hub, Profile tabs)
2. **Mobile Phase 5** — Home Dashboard UI (FINDRISC status, sensor cards, AI insight)
3. **Mobile Phase 6** — Bot Hub + Deep Linking (Telegram/WA connect)
4. **Backend Phase 2** — Middleware JWT + route `/sensors/sync`, `/food/log`, `/bot/link`
5. **Phase 1** — Prisma schema + DB migration (unblocks backend + web)
