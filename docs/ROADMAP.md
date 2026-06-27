# 🗺️ GLICO DEVELOPMENT ROADMAP & TO-DO

Pendekatan pengembangan menggunakan metode **Horizontal (Per Aplikasi)**.

> ⚠️ **ATURAN MUTLAK UNTUK AI:**
> Saat kamu membaca tugas dari `docs/TODO.md` dan diarahkan ke Roadmap ini, kamu **WAJIB** membuka `.roo/rules/rules.md` terlebih dahulu.
> Gunakan dokumen indeks di sana (seperti `DATABASE_SCHEMA.md` atau `API_CONTRACTS.md`) sebagai panduan spesifikasi teknis agar kodemu tidak melanggar kontrak arsitektur yang sudah disepakati.

---

## Phase 1: 🏗️ Foundation & Shared Packages (The Glue)

Fase ini mengamankan fondasi monorepo agar Web dan Mobile memiliki sumber kebenaran tipe data yang sama.

- [x] **Task 1.1:** Inisialisasi Bun Workspaces (`apps/web`, `apps/backend`, `apps/mobile`, `packages/types`). ✅
- [x] **Task 1.2:** Setup Supabase Project & inisialisasi tabel berdasarkan `DATABASE_SCHEMA.md`. ✅
  - ✅ Supabase project sudah dibuat (`dsspywhpfjxmrlxwycyi`)
  - ✅ Auth providers (Email, Google OAuth) sudah dikonfigurasi
  - ✅ Tabel database sudah dibuat & disinkronkan via Prisma db push
- [x] **Task 1.3:** Konfigurasi Prisma ORM di `apps/backend` dan migrasi database awal. ✅
- [x] **Task 1.4:** Buat TypeScript Interfaces di `packages/types`. ✅
  - ✅ Interfaces manual sudah ada (`User`, `SensorData`, `FoodLog`, `Intervention`, `BotLink`)

---

## Phase 2: ⚙️ Backend API (Elysia.js)

Membangun logika server, validasi, dan integrasi AI.

- [x] **Task 2.1:** Setup struktur Elysia.js + Swagger UI untuk dokumentasi otomatis. ✅
  - ✅ Elysia.js + Swagger UI sudah jalan di `apps/backend/src/index.ts`
  - ✅ Health check endpoint (`GET /health`) sudah ada
  - ✅ Struktur routing modular dipecah per domain (`sensors`, `food`, `bot`)
- [x] **Task 2.2:** Buat Middleware untuk memvalidasi JWT dari Supabase Auth. ✅
- [x] **Task 2.3:** Buat rute `POST /sensors/sync` untuk menerima data agregasi dari Mobile. ✅
- [x] **Task 2.4:** Buat rute `POST /food/log` (simpan ke database dan picu analisis gizi AI secara asinkronus). ✅
- [x] **Task 2.5:** Buat rute Deep Linking `GET /bot/link` dan `POST /bot/verify` untuk sinkronisasi Telegram/WA. ✅
- [x] **Task 2.6:** Buat rute admin `GET /admin/stats` untuk mengambil metrik performa AI, kesehatan fungsi, dan statistik pengguna. ✅


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
- [ ] **Task 3.5:** Buat Halaman Unduhan APK Mandiri & API In-App Update gratis (version metadata + direct download via Supabase Storage). ❌
- [ ] **Task 3.6:** Buat Halaman Dashboard Admin Web untuk memantau performa AI (aktif/failover provider, latensi), status kesehatan fungsi, dan grafik statistik pengguna. ❌


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
- [x] **Task 4.3:** Implementasi Background Task (Workmanager) untuk membaca data _Pedometer_ (Langkah) dan _Screen Time_. ✅
- [x] **Task 4.4:** Buat Cron lokal di Flutter untuk sinkronisasi data sensor ke endpoint Elysia `/sensors/sync` setiap beberapa jam. ✅
- [x] **Task 4.5:** Buat UI input teks untuk Log Makanan, tembak ke endpoint Elysia `/food/log`. ✅
- [x] **Task 4.6:** Implementasi UI Deep Linking bot Telegram/WA. ✅
- [x] **Task 4.7:** Implementasi In-App Chatbot UI & integrasi ke backend Elysia. ✅
- [x] **Task 4.8:** Caching riwayat chat di Local Storage perangkat (Shared Preferences). ✅
- [x] **Task 4.9:** Setup Push Notifications lokal (`flutter_local_notifications`) untuk pengingat aktif harian. ✅


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

## Phase 5: 🤖 AI Engine & Chatbot Integration (Elysia + Gemini)

Menghidupkan "otak" dari Glico langsung di dalam backend Elysia.js.

- [x] **Task 5.1:** Setup API Client untuk Gemini menggunakan SDK resmi Google (`@google/genai` atau `@google/generative-ai`) di Elysia. ✅
- [x] **Task 5.2:** Integrasikan Bot SDK (Telegram/WhatsApp API) dan endpoint webhook `/api/v1/bot/webhook` untuk menerima update chat. ✅
- [x] **Task 5.3:** Buat handler asinkron untuk analisis log makanan (`/food/log`) menggunakan Gemini prompt dan kirim balik via Telegram. ✅
- [x] **Task 5.4:** Implementasikan Scheduler Lokal (Cron) menggunakan library `croner` di Elysia untuk pengingat aktif (jalan kaki pagi dan istirahat malam). ✅
- [x] **Task 5.5:** Implementasikan Mekanisme Fallback (Failover) LLM dengan pattern Circuit Breaker (jika provider utama gagal/rate-limit, otomatis dialihkan ke Groq/OpenAI/Anthropic). ✅




---

## 📊 Progress Summary

| Phase             | Status               | Progress                                                          |
| ----------------- | -------------------- | ----------------------------------------------------------------- |
| 1. Foundation     | 🟢 Completed         | 100% — workspaces ✅, Supabase project ✅, DB tables ✅, Prisma ✅  |
| 2. Backend API    | 🟢 Completed         | 100% — Elysia scaffold, sync, food log, bot link, admin stats ✅   |
| 3. Web Dashboard  | 🟡 In Progress       | ~25% — Next.js + Tailwind + landing page preview ✅               |
| **4. Mobile App** | **🟢 Completed**     | **100% — Full Auth, Dashboard, Sync, Chatbot, Quests, Push Notif**|
| 5. AI Engine      | 🟢 Completed         | 100% — Gemini integration, chatbot, bot webhook, cron, failover ✅ |

### 🔥 Prioritas Selanjutnya (Suggested)

1. **Web Phase 3.2** — Integrasi Supabase Auth (Google OAuth) untuk login Web.
2. **Web Phase 3.4** — Buat halaman Dashboard Utama (Menampilkan agregasi langkah, screen time, dan log intervensi chat).
3. **Web Phase 3.5** — Buat Halaman Unduhan APK Mandiri & API In-App Update gratis (direct download via Supabase Storage).
4. **Web Phase 3.6** — Buat Halaman Dashboard Admin Web untuk memantau performa AI, status kesehatan fungsi, dan grafik statistik pengguna.
