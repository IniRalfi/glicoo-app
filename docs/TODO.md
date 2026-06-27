# 📝 CURRENT SPRINT & TO-DO

> ⚠️ **Aturan AI:** Task di bawah ini merujuk langsung ke `docs/ROADMAP.md`. Sebelum mengeksekusi, buka `docs/ROADMAP.md` untuk melihat fase besarnya, lalu ikuti instruksi arsitektur yang diarahkan di sana.

## 🎯 Fokus Hari Ini — Backend Core & AI Setup

> Detail task mobile: **`docs/MOBILE_TODO.md`**  
> Detail task backend: **`docs/BACKEND_TODO.md`**

- [x] **Task B.1:** Install dependensi baru di `apps/backend` (`@google/generative-ai` dan `croner`). ✅
- [x] **Task B.2:** Desain abstraction `AIService` dan buat `GeminiProvider` serta provider cadangan (failover). ✅
- [x] **Task B.3:** Perbarui endpoint `POST /food/log` untuk memproses makanan via AI secara asinkronus. ✅
- [x] **Task B.4:** Buat endpoint baru `POST /chat` untuk memproses percakapan dari In-App Chatbot. ✅
- [x] **Task B.5:** Buat rute webhook Telegram `/bot/webhook` untuk menangani update dari bot secara langsung. ✅
- [x] **Task B.6:** Buat endpoint admin `GET /admin/stats` untuk dasbor visualisasi web. ✅
- [x] **Task M.1:** Implementasi Sinkronisasi Offline & Cache Lokal (`SyncManager`). ✅
- [x] **Task M.2:** Integrasi Misi Real-Time Sensor di Tab Misi. ✅
- [x] **Task M.3:** Implementasi Lembar Catat Tidur Luring Dinamis. ✅
- [x] **Task M.4:** Perhitungan Skor Kesehatan Dinamis (0-100) Terintegrasi. ✅
- [x] **Task M.5:** Integrasi Fitur Salin Kode OTP & Direct Link Hubungkan ke Bot Telegram. ✅
- [ ] **Task B.7:** Setup & implementasi Telegram Bot handler pada webhook `/bot/webhook` terintegrasi dengan Gemini.





## 📦 Foundation (Selesai)

- [x] **Task 1.1:** Inisialisasi Bun Workspaces _(Ref: docs/ROADMAP.md -> Phase 1 -> Task 1.1)_
  - [x] Buat folder `apps/web`, `apps/backend`, `apps/mobile`.
  - [x] Buat folder `packages/types` dan `packages/config`.
  - [x] Setup `package.json` utama untuk mendefinisikan workspace Bun.

- [x] **Mobile Phase 0:** Design System
  - [x] Global theme — `AppColors`, `AppTypography`, `AppSpacing`, `AppTheme`
  - [x] Font — Rammetto One (display) + Inter (body) via `google_fonts`
  - [x] Shared widgets — `BentoCard`, `PrimaryButton`, `SkipButton`, `PageIndicator`

- [x] **Mobile Phase 1:** Project Structure & Riverpod
  - [x] `hooks_riverpod` + `flutter_hooks` + `freezed` + `build_runner`
  - [x] Feature-based folder structure (`core/`, `features/auth`, `features/splash`, dll)
  - [x] `ProviderScope` + `StateNotifier` pattern

- [x] **Mobile Phase 2:** Onboarding & Auth
  - [x] Splash Screen — gradient animasi + floating logo
  - [x] Onboarding (3 halaman) — PageView + AnimatedSwitcher + custom dots
  - [x] Legal Screen — ToS + Privacy consent
  - [x] Google OAuth — native `google_sign_in` (account picker, bukan browser)
  - [x] Email/Password Auth — Login + Register (konfirmasi sandi) + Forgot Password
  - [x] Auth Flow — Splash → Onboarding → Legal → Auth → Home + auto-redirect
  - [x] Logout + auto-redirect ke Login

- [x] **Mobile Phase 4:** Bottom Navigation Shell
  - [x] `BottomNavShell` — 4 tab (Home, Quests, Bot Hub, Profile) via `NavigationBar`
  - [x] `HomeScreen`, `QuestsScreen`, `BotHubScreen`, `ProfileScreen` — placeholder screens
  - [x] Auth flow integrated: Splash → Onboarding → Legal → Auth → BottomNavShell
  - [x] Smart onboarding: first-time user vs returning user (SharedPreferences)

- [x] **Mobile — App Identity**
  - [x] App icon dari `glico_logo.svg` — cropped blob, background kuning `#FFB700`
  - [x] Rename app: glico → **glicoo** (Android, iOS, MaterialApp.title)
  - [x] `flutter_launcher_icons` — Android mipmap + iOS xcassets generated

- [x] **Mobile — Glico Loading System**
  - [x] `GlicoLoading` — 2-frame SVG animation (glico_1.svg ↔ glico_2.svg, 200ms toggle)
  - [x] `GlicoLoadingOverlay` — full page white background, centered
  - [x] `LoadingProvider` — Riverpod StateNotifier, global show/hide
  - [x] Auto-show from `authProvider` loading state
  - [x] Title font: Rammetto One (default: "Bentar yaa")

- [x] **Web Phase 3.1 (partial):** Next.js App Router + TailwindCSS v4
  - [x] Font (Inter + Rammetto One) via `next/font`
  - [x] `@theme` block di `globals.css` — brand scale, semantic aliases, typography
  - [ ] **Task 3.5:** Setup halaman download APK & update API metadata gratis (Supabase Storage)

- [x] **Backend Phase 2.1:** Elysia.js scaffold + Swagger UI + Prisma Database Setup

## 🚧 Blocked / Issue

Tidak ada (Semua blocker database, endpoint sensor, dan bot link telah diselesaikan).

## ✅ Selesai (Summary)

- Dokumen spesifikasi awal (PRD, User Flows, Decisions, ROADMAP, API_CONTRACTS, DB_SCHEMA)
- Task 1.1: Bun Workspaces + packages/types + packages/config
- Mobile Phase 0-9: Full design system, Riverpod, Onboarding/Auth, Bottom Nav, Home Dashboard, Bot Hub, Sync Manager offline, Quests dinamis, Local Push Notifications, dan In-App Chatbot.
- Web: Next.js + Tailwind + fonts + theme
- Backend: Elysia.js + Swagger + Prisma + AI Agent + Webhook integration
- ROADMAP.md + MOBILE_TODO.md di-update dengan progress actual
