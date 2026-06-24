# 📝 CURRENT SPRINT & TO-DO

> ⚠️ **Aturan AI:** Task di bawah ini merujuk langsung ke `docs/ROADMAP.md`. Sebelum mengeksekusi, buka `docs/ROADMAP.md` untuk melihat fase besarnya, lalu ikuti instruksi arsitektur yang diarahkan di sana.

## 🎯 Fokus Hari Ini — Setup Database & Backend API

> Detail task mobile: **`docs/MOBILE_TODO.md`**  
> Detail task backend: **`docs/BACKEND_TODO.md`**

- [x] **Mobile Phase 5:** Home Dashboard UI — FINDRISC status bar, Bento cards (mock data) ✅
- [x] **Mobile Phase 8:** Quests (Gamifikasi) — Banner pencapaian & filter pill ✅
- [x] **Tutorial Karakter Iloo:** Onboarding dialog & guard overlay ✅
- [x] **Mobile Phase 9:** Profile & Settings — Layout dasar, data real, sinkronisasi FINDRISC & logout ✅
- [x] **Database & Backend Phase 1-2:** Prisma & Elysia routes (sensors/sync, food/log, bot/link) ✅
- [x] **Mobile Phase 6:** Bot Hub & Deep Linking — Status, OTP token, & custom AI persona selection ✅
- [x] **Pencatat Makanan AI:** Bento Card input makanan & Bottom Sheet terintegrasi ke Elysia /food/log ✅
- [x] **Mobile Phase 7:** Background Sensor & Sync — Pedometer, Screen Time, Workmanager & Elysia sync ✅

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

- [x] **Backend Phase 2.1 (partial):** Elysia.js scaffold + Swagger UI

## 🚧 Blocked / Issue

| Task                             | Blocker                                     |
| -------------------------------- | ------------------------------------------- |
| Mobile: Profil Risiko (FINDRISC) | DB table `User` belum di-migrasi            |
| Mobile: Sensor Sync              | Backend endpoint `POST /sensors/sync` belum |
| Mobile: Bot Deep Link            | Backend endpoint `GET /bot/link` belum      |
| Backend: Prisma + DB Migration   | Belum dikerjain                             |

## ✅ Selesai (Summary)

- Dokumen spesifikasi awal (PRD, User Flows, Decisions, ROADMAP, API_CONTRACTS, DB_SCHEMA)
- Task 1.1: Bun Workspaces + packages/types + packages/config
- Mobile Phase 0: Full design system (theme, typography, spacing, widgets)
- Mobile Phase 1: Riverpod + feature-based structure
- Mobile Phase 2: Splash + Onboarding + Legal + Auth (Login, Register, Forgot Password, Google OAuth native, Logout)
- Mobile Phase 4: Bottom Navigation Shell (4 tabs, smart onboarding flow)
- Mobile App Identity: Icon (cropped SVG blob), rename glico→glicoo
- Mobile Glico Loading: 2-frame SVG animation, Rammetto One title, auto-show from auth state
- Web: Next.js + Tailwind + fonts + theme
- Backend: Elysia.js scaffold + Swagger + health check
- ROADMAP.md + MOBILE_TODO.md di-update dengan progress actual
