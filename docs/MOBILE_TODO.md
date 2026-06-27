# 📱 MOBILE SPRINT — Glico Flutter

> Ref: `docs/ROADMAP.md` Fase 4 · `docs/USER_FLOWS.md` · `docs/FEATURES.md`

## 🎯 Fokus Sprint: Foundation & UI Shell

---

## Phase 0 — Design System ✅

- [x] **Global theme** — `AppColors`, `AppTypography`, `AppSpacing`, `AppTheme`
- [x] **Font setup** — Rametto One (judul) + Inter (body) via `google_fonts`
- [x] **Shared widgets** — `BentoCard`, `PrimaryButton`, `SkipButton`, `PageIndicator`
- [x] **Verifikasi visual** — Jalankan app, cek font & warna match Figma

---

## Phase 1 — Project Structure & Riverpod ✅

- [x] Setup `hooks_riverpod` + `ProviderScope` di `main.dart`
- [x] Struktur folder feature-based:
  ```text
  lib/
  ├── core/
  │   ├── env_config.dart
  │   ├── theme/          (app_colors, app_typography, app_spacing, app_theme)
  │   └── widgets/        (bento_card, primary_button, skip_button, page_indicator)
  └── features/
      ├── auth/           (domain, data, presentation)
      ├── onboarding/
      ├── splash/
      ├── legal/
      ├── home/           ← next
      ├── quests/         ← later
      ├── bot_hub/        ← later
      └── profile/        ← later
  ```
- [ ] Setup routing (`go_router` atau `auto_route`) — **belum**, masih pakai switch + enum di `main.dart`

---

## Phase 2 — Onboarding & Auth ✅ (sebagian)

- [x] **Splash Screen** — gradient animasi + floating logo (1200x1200), fade in/hold/fade out
- [x] **Onboarding (3 halaman)** — PageView illustrations + AnimatedSwitcher text fade + custom dots + skip button
- [x] **Legal Screen** — Terms of Service + Privacy Policy (checkbox consent)
- [x] **Google OAuth** — native `google_sign_in` (account picker) + Supabase `signInWithIdToken`
- [x] **Email/Password Auth** — Login + Register (dengan konfirmasi sandi) + Forgot Password
- [x] **Auth Flow** — Splash → Onboarding (first-time) → Legal → Auth → Home, auto-redirect
- [x] **Logout** — tombol di Home placeholder, auto-redirect ke Login screen
- [x] **Profil Risiko** — form FINDRISC (usia, TB/BB, lingkar perut, riwayat keluarga) ✅
- [x] Simpan profil ke Supabase setelah registrasi ✅

---

## Phase 3 — Sensor Permissions ✅

- [x] **Edukasi Bento Card** — jelaskan kenapa butuh langkah & screen time
- [x] Request permission OS (Activity Recognition / Health)
- [ ] Toggle permission di halaman Profile

---

## Phase 4 — Bottom Navigation Shell ✅

- [x] **Home** — integrasi dashboard di bottom navigation shell
- [x] **Quests** — integrasi misi harian
- [x] **Bot Hub** — integrasi menu deep link
- [x] **Profile** — integrasi menu profil & settings

---

## Phase 5 — Home Dashboard (UI) ✅

- [x] **FINDRISC Status Bar** — kategori risiko di bagian atas
- [x] **Bento Box — Live Sensors** — kartu aktivitas langkah, tidur, & screen time
- [x] **Bento Box — Analytics** — mini chart tren mingguan (MiniBarChart)
- [x] **Bento Box — AI Insight** — kartu tantangan harian (AI prompt/mock)
- [x] **Tutorial Karakter Iloo** — onboarding dialog & guard overlay (Iloo dialog flow)
- [x] **Pencatat Makanan AI** — Bento Card Pencatat Makanan & Bottom Sheet, terintegrasi dengan Elysia `/food/log`

---

## Phase 6 — Bot Hub & Deep Linking ✅
- [x] Status koneksi bot (Belum Terhubung / Terhubung)
- [x] Tombol "Hubungkan ke Telegram/WhatsApp"
- [x] Deep link: `GET /api/v1/bot/link` → buka `t.me/GlicoBot?start=<TOKEN>`
- [x] Poll/refresh status setelah user kembali dari chat app
- [x] Pengaturan persona AI (Tegas / Santai)

---

## Phase 7 — Background Sensor & Sync ✅

- [x] Integrasi `pedometer` package & perizinan (Permission.activityRecognition)
- [x] Integrasi screen time tracking (lokal timer + lifecycle observer)
- [x] Setup `workmanager` untuk background task execution
- [x] Sinkronisasi otomatis ke `POST /api/v1/sensors/sync` setiap 15 menit
- [x] SharedPreferences offline caching & dynamic UI updates

---

## Phase 8 — Quests (Gamifikasi) ✅

- [x] Daftar misi harian (Langkah, Tidur, Screen time)
- [x] Auto-check misi langkah dari sensor
- [x] Manual check untuk misi perilaku (belum/sudah selesai filter tabs)
- [x] UI progress & reward sederhana (misi-bg.svg & progress bar)

---

## Phase 9 — Profile & Settings ✅

- [x] Tampilkan data diri & FINDRISC score
- [x] Tombol debug reset (Reset FINDRISC, Reset Onboarding, Reset Tutorial Iloo)
- [x] Tombol "Hitung Ulang Risiko FINDRISC" (Simpan Perubahan & update score) ✅
- [ ] Toggle sensor permissions
- [x] Logout ✅

---

## Phase 11 — In-App Chatbot ✅

- [x] Desain Halaman Chatbot bawaan (Tab/Screen terpisah di mobile)
- [x] Integrasi pengiriman teks ke endpoint Elysia backend dan tampilkan respon AI
- [x] Caching riwayat obrolan secara lokal menggunakan Local Storage (Shared Preferences)

## Phase 12 — Local Push Notifications ✅

- [x] Integrasi library `flutter_local_notifications`
- [x] Setup schedule pengingat pagi (jam 08:00) dan pengingat malam (jam 21:00) berdasarkan data harian
- [x] Pengujian push notification lokal saat kondisi terpenuhi (Kirim Notifikasi Tes di Profil)

---

## Phase 10 — Polish & Testing ❌

- [ ] Widget test untuk shared components
- [ ] Manual test flow onboarding → home → bot link
- [ ] Test di Android (primary) + iOS jika memungkinkan
- [ ] Perbaiki edge cases (no permission, no network, token expired)

---

## 🚧 Blocked / Dependencies

| Task Mobile              | Butuh                                       |
| ------------------------ | ------------------------------------------- |
| Profil Risiko (FINDRISC) | DB table `User` (schema + migration)        |
| Bot deep link            | Backend `GET /bot/link`, `POST /bot/verify` |
| Sensor sync              | Backend `POST /sensors/sync`                |
| AI insight di Home       | Data dari n8n/bot (read-only dari Supabase) |

---

## ✅ Selesai (Summary)

### Design System (Phase 0)

- `AppColors` — brand 1–10 scale, neutrals, auth-specific grays
- `AppTypography` — Rammetto One (display) + Inter (body/title/label)
- `AppSpacing` — spacing tokens + pill button radius
- `AppTheme` — Material 3 theme (ColorScheme, Card, Button, InputDecoration)
- Shared widgets: `BentoCard`, `PrimaryButton`, `SkipButton`, `PageIndicator`

### Project Structure (Phase 1)

- `hooks_riverpod` + `flutter_hooks` + `freezed` + `build_runner`
- Feature-based folder structure
- `ProviderScope` + `StateNotifier` pattern
- `SupabaseAuthRepository` injection via `overrideWithValue`

### Onboarding & Auth (Phase 2)

- Splash Screen (gradient + floating logo animation)
- Onboarding (3 halaman, PageView + AnimatedSwitcher)
- Legal Screen (ToS + Privacy consent)
- Login (email/password + Google OAuth native + forgot password)
- Register (email + nama + password + konfirmasi password)
- Forgot Password (email reset + success view)
- Full auth flow (Splash → Onboarding → Legal → Auth → Home)
- Logout + auto-redirect

### Extra

- Native Google Sign-In (account picker, bukan browser)
- Supabase `signInWithIdToken` flow
- Auth state management (freezed sealed class: unauthenticated, authenticated, loading, error)
- Human-readable error mapping (Indonesian)
