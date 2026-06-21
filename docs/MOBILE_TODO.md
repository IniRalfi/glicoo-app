# 📱 MOBILE SPRINT — Glico Flutter

> Ref: `docs/ROADMAP.md` Fase 4 · `docs/USER_FLOWS.md` · `docs/FEATURES.md`

## 🎯 Fokus Sprint: Foundation & UI Shell

---

## Phase 0 — Design System ✅ (In Progress)

- [x] **Global theme** — `AppColors`, `AppTypography`, `AppSpacing`, `AppTheme`
- [ ] **Font setup** — Rametto One (judul) + Inter (body) via `google_fonts`
- [ ] **Shared widgets** — `BentoCard`, `PrimaryButton`, `SectionHeader`
- [ ] **Verifikasi visual** — Jalankan app, cek font & warna match Figma

---

## Phase 1 — Project Structure & Riverpod

- [ ] Setup `hooks_riverpod` + `ProviderScope` di `main.dart`
- [ ] Struktur folder feature-based:
  ```text
  lib/
  ├── core/          (theme, router, constants)
  ├── shared/        (widgets reusable)
  └── features/
      ├── auth/
      ├── onboarding/
      ├── home/
      ├── quests/
      ├── bot_hub/
      └── profile/
  ```
- [ ] Setup routing (`go_router` atau `auto_route`)

---

## Phase 2 — Onboarding & Auth

- [ ] **Splash Screen** — animasi singkat, preload essentials
- [ ] **Legal Screen** — Terms of Service & Privacy Policy
- [ ] **Google OAuth** — integrasi Supabase Auth
- [ ] **Profil Risiko** — form FINDRISC (usia, TB/BB, lingkar perut, riwayat keluarga)
- [ ] Simpan profil ke Supabase setelah registrasi

---

## Phase 3 — Sensor Permissions

- [ ] **Edukasi Bento Card** — jelaskan kenapa butuh langkah & screen time
- [ ] Request permission OS (Activity Recognition / Health)
- [ ] Toggle permission di halaman Profile

---

## Phase 4 — Bottom Navigation Shell

- [ ] **Home** — placeholder dashboard
- [ ] **Quests** — placeholder misi harian
- [ ] **Bot Hub** — placeholder deep link
- [ ] **Profile** — placeholder profil & settings

---

## Phase 5 — Home Dashboard (UI)

- [ ] **FINDRISC Status Bar** — kategori risiko di bagian atas
- [ ] **Bento Box — Live Sensors** — grafik sirkular langkah & screen time
- [ ] **Bento Box — Analytics** — mini chart tren mingguan
- [ ] **Bento Box — AI Insight** — rangkuman saran bot terakhir

---

## Phase 6 — Bot Hub & Deep Linking

- [ ] Status koneksi bot (Belum Terhubung / Terhubung)
- [ ] Tombol "Hubungkan ke Telegram/WhatsApp"
- [ ] Deep link: `GET /api/v1/bot/link` → buka `t.me/GlicoBot?start=<TOKEN>`
- [ ] Poll/refresh status setelah user kembali dari chat app
- [ ] Pengaturan persona AI (Tegas / Santai)

---

## Phase 7 — Background Sensor & Sync

- [ ] Integrasi `pedometer` / `health` package
- [ ] Integrasi screen time (platform-specific)
- [ ] Setup `workmanager` untuk background task
- [ ] Cron lokal sync ke `POST /api/v1/sensors/sync` setiap beberapa jam
- [ ] Offline queue jika tidak ada koneksi

---

## Phase 8 — Quests (Gamifikasi)

- [ ] Daftar misi harian (auto-tracked + manual)
- [ ] Auto-check misi langkah dari sensor
- [ ] Manual check untuk misi perilaku (minum air, tidur)
- [ ] UI progress & reward sederhana

---

## Phase 9 — Profile & Settings

- [ ] Tampilkan data diri & FINDRISC score
- [ ] Tombol "Hitung Ulang Risiko FINDRISC"
- [ ] Toggle sensor permissions
- [ ] Logout

---

## Phase 10 — Polish & Testing

- [ ] Widget test untuk shared components
- [ ] Manual test flow onboarding → home → bot link
- [ ] Test di Android (primary) + iOS jika memungkinkan
- [ ] Perbaiki edge cases (no permission, no network, token expired)

---

## 🚧 Blocked / Dependencies

| Task Mobile | Butuh |
|---|---|
| Auth & profil | Supabase project + schema user |
| Bot deep link | Backend `GET /bot/link`, `POST /bot/verify` |
| Sensor sync | Backend `POST /sensors/sync` |
| AI insight di Home | Data dari n8n/bot (read-only dari Supabase) |

---

## ✅ Selesai

- Global theme foundation (`lib/core/theme/`)
