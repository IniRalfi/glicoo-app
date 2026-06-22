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
- [ ] **Profil Risiko** — form FINDRISC (usia, TB/BB, lingkar perut, riwayat keluarga) ❌
- [ ] Simpan profil ke Supabase setelah registrasi ❌

---

## Phase 3 — Sensor Permissions ❌

- [ ] **Edukasi Bento Card** — jelaskan kenapa butuh langkah & screen time
- [ ] Request permission OS (Activity Recognition / Health)
- [ ] Toggle permission di halaman Profile

---

## Phase 4 — Bottom Navigation Shell ❌ ← **NEXT**

- [ ] **Home** — placeholder dashboard (sudah ada placeholder, belum ada shell)
- [ ] **Quests** — placeholder misi harian
- [ ] **Bot Hub** — placeholder deep link
- [ ] **Profile** — placeholder profil & settings

---

## Phase 5 — Home Dashboard (UI) ❌

- [ ] **FINDRISC Status Bar** — kategori risiko di bagian atas
- [ ] **Bento Box — Live Sensors** — grafik sirkular langkah & screen time
- [ ] **Bento Box — Analytics** — mini chart tren mingguan
- [ ] **Bento Box — AI Insight** — rangkuman saran bot terakhir

---

## Phase 6 — Bot Hub & Deep Linking ❌

- [ ] Status koneksi bot (Belum Terhubung / Terhubung)
- [ ] Tombol "Hubungkan ke Telegram/WhatsApp"
- [ ] Deep link: `GET /api/v1/bot/link` → buka `t.me/GlicoBot?start=<TOKEN>`
- [ ] Poll/refresh status setelah user kembali dari chat app
- [ ] Pengaturan persona AI (Tegas / Santai)

---

## Phase 7 — Background Sensor & Sync ❌

- [ ] Integrasi `pedometer` / `health` package
- [ ] Integrasi screen time (platform-specific)
- [ ] Setup `workmanager` untuk background task
- [ ] Cron lokal sync ke `POST /api/v1/sensors/sync` setiap beberapa jam
- [ ] Offline queue jika tidak ada koneksi

---

## Phase 8 — Quests (Gamifikasi) ❌

- [ ] Daftar misi harian (auto-tracked + manual)
- [ ] Auto-check misi langkah dari sensor
- [ ] Manual check untuk misi perilaku (minum air, tidur)
- [ ] UI progress & reward sederhana

---

## Phase 9 — Profile & Settings ❌ (sebagian)

- [ ] Tampilkan data diri & FINDRISC score
- [ ] Tombol "Hitung Ulang Risiko FINDRISC"
- [ ] Toggle sensor permissions
- [x] Logout ✅

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
