# 📋 CHANGELOG — Glicoo

Semua perubahan penting pada proyek Glicoo akan didokumentasikan di sini.
Format mengikuti [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) dan [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

---

## [1.0.2] — 2026-07-03

### ♻️ Refactored

#### Mobile (v1.0.2+4)

- **`main.dart` dipecah** — Entry point dikurangi dari 575 → 67 baris
  - Navigation flow state machine dipindah ke `core/app_flow.dart` (`AppEntryPoint`, `AppFlowState` enum, `_AuthFlow` enum)
  - `main.dart` sekarang hanya berisi `main()` + `GlicoApp`

- **`activity_provider.dart` dipecah** — 4 provider dipindah ke file terpisah sesuai domain
  - `findriscDataProvider` → `features/home/providers/findrisc_provider.dart`
  - `userNameProvider`, `tutorialSeenProvider`, `tutorialDoneProvider`, `tutorialDialogShowingProvider` → `features/home/providers/tutorial_provider.dart`

- **`profile_screen.dart` dipecah** — Inline form edit profil (~260 baris) dipisah
  - `_showEditProfileDialog` → `features/profile/widgets/edit_profile_bottom_sheet.dart` (`EditProfileBottomSheet`)
  - `profile_screen.dart` dikurangi dari 569 → ~270 baris

### 📚 Documentation

- **`docs/TODO.md`** — Semua task sprint selesai, file dihapus (tidak relevan lagi)

---

## [1.0.1] — 2026-06-29

### 🐛 Fixed

#### Mobile (v1.0.1+3)

- **Age field propagation fix** — Umur user yang diinput saat FINDRISC tidak lagi default ke 30 tahun untuk semua user < 45 tahun
  - Root cause: Flow FINDRISC hanya mengirim `ageGroup` (string range), bukan umur integer asli
  - Fix: Tambahkan field `int age` di `FindriscData`, propagasi dari step1 → step2 → database
  - Files: `findrisc_data.dart`, `findrisc_step1_screen.dart`, `findrisc_step2_screen.dart`, `main.dart`
  - Scoring FINDRISC tetap menggunakan `ageGroup` untuk akurasi kalkulasi risiko

- **FINDRISC focus screen SVG** — Semua kategori risiko sekarang menggunakan `glicoo_end.svg`
  - Sebelumnya: per-kategori SVG (rendah.svg, sedang.svg, tinggi.svg, dll)
  - Sesudah: satu SVG universal `glicoo_end.svg` untuk semua kondisi
  - File: `findrisc_focus_screen.dart`

- **Login/Register freeze** — Loading overlay ditampilkan segera setelah auth success untuk mencegah UI freeze
  - Root cause: `_checkFindriscDone()` API call membuat delay visual tanpa feedback
  - Fix: Tampilkan loading overlay sebelum `_checkFindriscDone()`, hide setelah selesai
  - File: `main.dart` auth listener

- **Risk score mismatch** — Skor FINDRISC default di Home dan Profile sekarang konsisten
  - Root cause: Profile screen menggunakan hardcoded default (score: 13, category: 'Sedang') yang berbeda dengan SharedPreferences (score: 0, category: 'Belum Tes')
  - Fix: Ubah field initializers di Profile screen untuk match SharedPreferences defaults
  - File: `profile_screen.dart`

#### Backend (v0.1.1)

- No changes (mobile-only bug fixes)

### 📚 Documentation

- **README.md** — Update arsitektur sistem untuk reflect realita project
  - Web: Dashboard monitoring → Landing page + download APK
  - AI: n8n external → Gemini integration langsung di backend
  - Chat: WhatsApp/Telegram → Telegram only
  - Tech stack: Detail lengkap (Flutter 3.x, Elysia.js, Prisma, Bun, Vercel)
- **CHANGELOG.md** — Konsolidasi semua TODO & ISSUES ke satu file
  - Merge: `ISSUES.md`, `TODO.md`, `BACKEND_TODO.md`, `MOBILE_TODO.md`
  - Documentation: 12 resolved bugs + full development history

---

## [1.0.0] — 2026-06-27 (First Release 🎉)

### ✨ Added

#### Mobile (Flutter)

- **Splash Screen** — Animasi gradien + floating logo Glicoo.
- **Onboarding (3 halaman)** — Ilustrasi + animasi teks + custom dots + tombol skip.
- **Legal Screen** — Persetujuan Syarat Layanan & Kebijakan Privasi.
- **Autentikasi lengkap** — Login, Register, Lupa Password, Google OAuth Native.
- **FINDRISC Risk Assessment** — Kuesioner faktor risiko Diabetes Tipe 2 dengan kalkulasi skor otomatis dan simpan ke Supabase.
- **Home Dashboard (Bento Grid)** — Kartu aktivitas langkah kaki, tidur, screen time, grafik tren mingguan, dan pencatat makanan AI.
- **Iloo Tutorial Dialog** — Alur onboarding karakter Iloo saat pertama kali buka beranda.
- **Bot Hub** — Layar pengantar in-app chatbot Iloo dengan navigasi ke chat.
- **In-App Chatbot (Iloo)** — Percakapan langsung dengan AI Gemini, riwayat chat tersimpan di local storage.
- **Tab Misi (Quests)** — Daftar misi harian dengan progress bar real-time dari sensor (langkah, tidur, screen time) dan skor kesehatan dinamis (0-100).
- **Profil & Pengaturan** — Avatar kustom (pilih karakter/galeri/warna), data kesehatan yang bisa diedit, toggle background sync.
- **Koneksi Bot Telegram** — OTP 6-digit + tombol salin + tombol hubungkan langsung ke @glicoo_bot.
- **Putus Koneksi Bot** — Tombol disconnect dengan konfirmasi dialog di halaman profil.
- **Background Sensor** — Pembacaan pedometer (langkah kaki) dan screen time via WorkManager.
- **Sinkronisasi Otomatis** — Sinkronisasi data sensor ke backend setiap 15 menit.
- **SyncManager (Offline Queue)** — Antrian tugas luring untuk log makanan & data profile ketika jaringan tidak tersedia.
- **Local Push Notifications** — Pengingat harian terjadwal (pagi 08.00 & malam 21.00) menggunakan `flutter_local_notifications`.

#### Backend (Elysia.js)

- **Elysia.js server** — Scaffold lengkap dengan Swagger UI, CORS, dan health check.
- **Prisma ORM** — Migrasi database ke Supabase PostgreSQL.
- **JWT Auth Middleware** — Validasi token Supabase pada semua rute yang dilindungi.
- **Sensor Sync** `POST /api/v1/sensors/sync` — Menerima data pedometer & screen time dari mobile.
- **Food Log AI** `POST /api/v1/food/log` — Analisis gizi makanan via Gemini secara asinkronus.
- **Bot Linking** `GET /api/v1/bot/link` — Generate OTP 6-digit untuk deep link Telegram.
- **Bot Disconnect** `DELETE /api/v1/bot/disconnect` — Memutuskan koneksi Telegram dari akun pengguna.
- **Telegram Webhook** `POST /api/v1/bot/webhook` — Menerima update pesan dari Telegram, routing ke handler Gemini.
- **In-App Chat** `POST /api/v1/chat` — Endpoint chatbot in-app dengan konteks sensor & FINDRISC.
- **Admin Stats** `GET /api/v1/admin/stats` — Agregasi metrik AI, DAU, langkah kaki, dan kesehatan sistem.
- **AI Service (Gemini 2.5 Flash)** — Layanan AI dengan struktur respons JSON tervalidasi.
- **Fallback LLM (Circuit Breaker)** — Otomatis beralih ke OpenAI/DeepSeek jika Gemini gagal.
- **Cron Scheduler** — Pengingat proaktif via Telegram: pagi (08.00), sore (15.00, cek langkah < 3000), malam (21.00).

### 🔒 Security

- JWT dev-mode fallback dibatasi hanya untuk `NODE_ENV=development` (sebelumnya aktif selama bukan `production`).
- `BACKEND_ADMIN_API_KEY` melindungi semua endpoint admin dan internal.
- Token OTP bot berlaku hanya 10 menit dan dihapus setelah digunakan.
- Seluruh rute pengguna dilindungi middleware `isAuth: true`.

### 🐛 Fixed

- Fallback durasi tidur awal dari 380 menit (hardcoded) menjadi 0 menit agar logis untuk pengguna baru.
- Skor misi harian diperbaiki dari `+10 Point` menjadi `+40/+30/+30 Point` sesuai bobot kalkulasi.
- Null-aware elements syntax Dart 3.8+ diperbaiki (`?value` bukan `value?`) di `api_service.dart` dan `chatbot_provider.dart`.

### 🐛 Bug Fixes (Post-Release)

#### Issue #1: Loading Setelah Login ✅

**Severity:** Low  
**Root Cause:** Async API call `_checkFindriscDone()` tanpa loading indicator  
**Fixed:** Cache FINDRISC status di SharedPreferences + loading overlay

#### Issue #2: Tutorial Muncul 2x ✅

**Severity:** High  
**Root Cause:** Double listener (`tutorialSeenProvider` + `bottomNavIndexProvider`)  
**Fixed:** Hapus listener redundan di `home_screen.dart`

#### Issue #3: Image Hasil FINDRISC Tidak Muncul ✅

**Severity:** High  
**Root Cause:** File `glicoo_result.svg` tidak ada di assets  
**Fixed:** Ganti path ke `glicoo_end.svg` yang tersedia

#### Issue #4: Aktivitas Tidak Jalan ✅

**Severity:** Critical  
**Root Cause:** Timer polling 2 detik terlalu cepat, data sensor tidak ter-update real-time  
**Fixed:** Refactor polling → push pattern, sensor service notify activity provider langsung

#### Issue #5: Redirect Delay Setelah Registrasi Google ✅

**Severity:** Medium  
**Root Cause:** Auth stream listener butuh waktu propagate state  
**Fixed:** Tampilkan loading overlay segera setelah OAuth success

#### Issue #6: Pop Up Asisten Muncul 2x Setelah FINDRISC ✅

**Severity:** High  
**Root Cause:** Tombol "Nanti Saja" tidak langsung pop, masih pindah step  
**Fixed:** Langsung set flag + pop dialog tanpa pindah step

#### Issue #7: Pencapaian Misi 20/100 Saat Login Pertama ✅

**Severity:** Medium  
**Root Cause:** Hardcoded dummy data di constructor `ActivityDataNotifier`  
**Fixed:** Ganti default history jadi array kosong

#### Issue #8: Umur di Profil Langsung Diset 30 Tahun ✅

**Severity:** Critical  
**Root Cause:** FINDRISC hanya menyimpan age group, tidak ada input umur spesifik  
**Fixed:** Ubah input dari radio button age group → text field numeric + auto-calculate age group untuk scoring

#### Issue #9: Format Pesan Telegram Untuk Link Bot Salah ✅

**Severity:** Medium  
**Root Cause:** Pesan welcome tidak menjelaskan format `/start <TOKEN>`  
**Fixed:** Update pesan welcome di `bot.service.ts` dengan contoh format

#### Issue #10: Default FINDRISC Score Bikin Bingung ✅

**Severity:** Critical  
**Root Cause:** Default value 13 + kategori "Sedang" terlihat seperti data asli  
**Fixed:** Ubah default ke score: 0, category: "Belum Tes" di `activity_provider.dart` dan `profile_screen.dart`

#### Issue #11: Style "Risiko Saat Ini" Berbeda di Home vs Profile ✅

**Severity:** Medium  
**Root Cause:** Home pakai `_StatRow` text biasa, Profile pakai badge warna dinamis  
**Fixed:** Update `_RiskCard` di home screen pakai badge style yang sama dengan profile

#### Issue #12: Challenge Card Styling & Pop-up untuk Food Logging ✅

**Severity:** Medium  
**Root Cause:** Warna pink + icon `food.svg`, desain baru minta purple + `iloo_food.svg`  
**Fixed:** Update warna ke `0xFFCB30E0` (purple) + icon ke `iloo_food.svg` + deskripsi dialog

---

## [0.9.0-beta] — 2026-06-23

### ✨ Added

- Backend Elysia scaffold awal + Swagger + health check.
- Auth mobile (Google OAuth + Email/Password).
- Struktur monorepo Bun Workspaces.
- Profil FINDRISC + simpan ke Supabase.
- Bottom Navigation Shell (4 tab).

---

## 📚 Development History & Task Completion

### Backend Sprint (BACKEND_TODO.md) — All Phases Complete ✅

#### Phase 1 — Database & Prisma ORM Setup ✅

- Setup Prisma ORM (v7.8.0) dengan `@prisma/adapter-pg` + `pg` driver
- Desain skema database: User, DailySensorLog, FoodLog, InterventionChat, BotLinkToken
- Koneksi Supabase PostgreSQL (Transaction + Direct URL)
- Migrasi awal `db:migrate --name init` berhasil
- Singleton PrismaClient dengan Pool & Driver Adapter

#### Phase 2 — Project Architecture & Core Config ✅

- Struktur folder modular (features & core)
- Database client singleton di `src/core/db.ts`

#### Phase 3 — Middleware & Keamanan (Supabase JWT) ✅

- JWT Verifier Middleware dengan `@elysiajs/jwt`
- Macro `isAuth: true` untuk proteksi route deklaratif

#### Phase 4 — Implementasi API Endpoints ✅

- `POST /api/v1/sensors/sync` — Sensor data upsert
- `POST /api/v1/food/log` — Food logging + webhook trigger ke AI
- `GET /api/v1/bot/link` — Generate OTP deep link Telegram
- `POST /api/v1/bot/verify` — Verifikasi OTP + simpan chat ID
- `DELETE /api/v1/bot/disconnect` — Putus koneksi bot dari akun

#### Phase 5 — Dokumentasi Swagger & Integration Test ✅

- Update Swagger UI tags per kelompok
- Test semua API via HTTP client / curl
- Verifikasi response format sesuai `API_CONTRACTS.md`

#### Phase 6 — LLM Failover & Admin Metrics ✅

- Abstract `AIService` interface
- Provider: GeminiProvider, GroqProvider, OpenAIProvider
- Failover logic (Gemini → Groq/OpenAI jika error)
- `POST /api/v1/bot/webhook` — Webhook Telegram langsung (ganti n8n)
- `GET /api/v1/admin/stats` — Admin dashboard metrics

---

### Mobile Sprint (MOBILE_TODO.md) — All Phases Complete ✅

#### Phase 0 — Design System ✅

- Global theme: `AppColors`, `AppTypography`, `AppSpacing`, `AppTheme`
- Font: Rammetto One (display) + Inter (body) via `google_fonts`
- Shared widgets: `BentoCard`, `PrimaryButton`, `SkipButton`, `PageIndicator`

#### Phase 1 — Project Structure & Riverpod ✅

- `hooks_riverpod` + `flutter_hooks` + `freezed` + `build_runner`
- Feature-based folder structure
- `ProviderScope` + `StateNotifier` pattern
- `SupabaseAuthRepository` injection

#### Phase 2 — Onboarding & Auth ✅

- Splash Screen (gradient + floating logo animation)
- Onboarding (3 halaman PageView + AnimatedSwitcher)
- Legal Screen (ToS + Privacy consent)
- Login (email/password + Google OAuth native + forgot password)
- Register (email + nama + password + konfirmasi)
- Forgot Password (email reset + success view)
- Full auth flow: Splash → Onboarding → Legal → Auth → Home
- Logout + auto-redirect

#### Phase 3 — Sensor Permissions ✅

- Edukasi Bento Card untuk permission rationale
- Request Activity Recognition / Health permission

#### Phase 4 — Bottom Navigation Shell ✅

- `BottomNavShell` dengan 4 tab (Home, Quests, Bot Hub, Profile)
- Auth flow integrated dengan navigation
- Smart onboarding (first-time vs returning user)

#### Phase 5 — Home Dashboard (UI) ✅

- FINDRISC Status Bar (kategori risiko)
- Bento Box Live Sensors (langkah, tidur, screen time)
- Bento Box Analytics (mini chart tren mingguan)
- Bento Box AI Insight (tantangan harian)
- Tutorial Karakter Iloo (onboarding dialog)
- Pencatat Makanan AI (Bento Card + Bottom Sheet + Elysia `/food/log`)

#### Phase 6 — Bot Hub & Deep Linking ✅

- Status koneksi bot (Belum Terhubung / Terhubung)
- Tombol "Hubungkan ke Telegram/WhatsApp"
- Deep link: `GET /api/v1/bot/link` → `t.me/GlicoBot?start=<TOKEN>`
- Poll/refresh status setelah user kembali
- Pengaturan persona AI (Tegas / Santai)

#### Phase 7 — Background Sensor & Sync ✅

- Integrasi `pedometer` package + perizinan
- Screen time tracking (lokal timer + lifecycle observer)
- `workmanager` untuk background task
- Sinkronisasi otomatis ke `POST /api/v1/sensors/sync` setiap 15 menit
- SharedPreferences offline caching + dynamic UI updates

#### Phase 8 — Quests (Gamifikasi) ✅

- Daftar misi harian (Langkah, Tidur, Screen time)
- Auto-check misi langkah dari sensor
- Manual check untuk misi perilaku
- UI progress & reward (misi-bg.svg + progress bar)

#### Phase 9 — Profile & Settings ✅

- Tampilkan data diri & FINDRISC score
- Tombol debug reset (FINDRISC, Onboarding, Tutorial Iloo)
- Tombol "Hitung Ulang Risiko FINDRISC" (update score)
- Logout

#### Phase 11 — In-App Chatbot ✅

- Desain halaman chatbot bawaan
- Integrasi endpoint Elysia + tampilkan respons AI
- Caching riwayat obrolan lokal (SharedPreferences)

#### Phase 12 — Local Push Notifications ✅

- Integrasi `flutter_local_notifications`
- Schedule pengingat pagi (08:00) dan malam (21:00)
- Pengujian push notification (Kirim Notifikasi Tes di Profil)

---

## 🔍 Technical Patterns & Lessons Learned

### Common Issues Identified

1. **Double listener problem** — Perlu audit semua `ref.listen` di codebase
2. **Hardcoded default values** — Gunakan empty state atau cache
3. **Missing assets** — Perlu checklist asset sebelum build
4. **Polling vs Push** — Sensor service harus pakai push notification pattern

### Tech Debt

1. Activity provider perlu refactor (hapus timer polling)
2. FINDRISC flow sudah diperbaiki untuk umur spesifik
3. Tutorial dialog perlu state management yang lebih robust
4. Asset management perlu CI check

---

> 📌 **Catatan Deployment:**
>
> - Mobile: `flutter build apk --release` → distribusikan via Supabase Storage / Firebase App Distribution.
> - Backend: Deploy ke **Vercel** dengan Bun runtime.
> - Database: Supabase PostgreSQL (managed).

---

## 📚 Archived Reference Docs

> File-file berikut diarsipkan dari `docs/` karena bersifat one-time setup atau panduan developer, bukan spesifikasi arsitektur aktif.

---

### Commit Guide (`docs/commit-guide.md`)

Format commit message untuk seluruh kontributor Glico.

#### Format

```
[type]([scope]): [subject]

[body (opsional)]

[footer (opsional)]
```

#### Type (Wajib)

| Type       | Deskripsi                             | Contoh                                      |
| ---------- | ------------------------------------- | ------------------------------------------- |
| `feat`     | Penambahan fitur baru                 | `feat: tambahkan endpoint health-data`      |
| `fix`      | Perbaikan bug                         | `fix: perbaiki crash saat akses kamera`     |
| `docs`     | Perubahan dokumentasi                 | `docs: update API_SPEC.md`                  |
| `style`    | Perubahan format kode (spasi, dll)    | `style: rapikan indentasi SensorService`    |
| `refactor` | Perubahan kode tanpa ubah perilaku    | `refactor: optimasi query database`         |
| `perf`     | Perbaikan performa                    | `perf: cache response dashboard`            |
| `test`     | Penambahan atau perbaikan test        | `test: tambahkan unit test untuk aiService` |
| `chore`    | Perubahan konfigurasi atau dependency | `chore: update express ke 4.19.0`           |
| `ci`       | Perubahan CI/CD pipeline              | `ci: tambahkan workflow deploy ke Vercel`   |
| `revert`   | Membatalkan commit sebelumnya         | `revert: revert commit abc123`              |

#### Scope (Opsional)

| Scope     | Komponen                           |
| --------- | ---------------------------------- |
| `mobile`  | Flutter App                        |
| `backend` | Node.js API (Elysia)               |
| `web`     | Next.js Dashboard                  |
| `db`      | Database migration / schema        |
| `api`     | Endpoint API                       |
| `ai`      | AI Engine (n8n / LLM)              |
| `sensor`  | Sensor Service (step, screen time) |
| `auth`    | Authentication / JWT               |
| `docs`    | Dokumentasi                        |
| `config`  | Konfigurasi proyek                 |

#### Aturan Subject

- Maksimal **50 karakter**
- Gunakan **imperative mood**
- Jangan diakhiri titik

#### Contoh Lengkap

```bash
feat(backend): tambahkan endpoint /api/health-data

Endpoint ini menerima data langkah, screen time, dan tidur dari mobile app.
Data akan disimpan ke database dan digunakan untuk menghitung risk score.

Closes #12
```

#### Contoh Per Komponen

```bash
# Mobile
feat(mobile): tambahkan akses sensor step counter
fix(mobile): perbaiki permission screen time di iOS 16

# Backend
feat(backend): tambahkan endpoint POST /api/health-data
fix(backend): perbaiki CORS error di production

# Web
feat(web): tambahkan landing page
style(web): implementasi TailwindCSS di seluruh komponen

# Docs
docs: tambahkan API_SPEC.md lengkap
```

#### Tools

```bash
# Commitizen (interactive commit prompt)
npm install -g commitizen
commitizen init cz-conventional-changelog --save-dev --save-exact
git cz

# Commitlint (validasi format commit)
npm install --save-dev @commitlint/cli @commitlint/config-conventional
echo "module.exports = { extends: ['@commitlint/config-conventional'] };" > commitlint.config.js
```

#### Git Cheat Sheet

```bash
git status
git add .
git commit -m "feat(mobile): tambahkan akses sensor step counter"
git log --oneline
git log --graph --oneline --all
git push origin main
git pull origin main
git checkout -b feature/health-data-endpoint
git merge feature/health-data-endpoint
```

---

### Global Commit Setup (`docs/global-setup.md`)

Setup format commit message agar bisa dipakai global di luar repository ini.

#### 1. Git Commit Template

```bash
# Buat file template
nano ~/.gitmessage
```

Isi template:

```text
[type]([scope]): [subject]

# type: feat, fix, docs, style, refactor, perf, test, chore, ci, revert
# scope: mobile, backend, web, db, api, ai, sensor, auth, docs, config
# subject: maks 50 karakter, imperative mood, tanpa titik di akhir.
#
# --- Batas baris kosong ---
#
# Body (opsional): jelaskan MENGAPA, maks 72 karakter per baris.
# Footer (opsional): Closes #issue atau BREAKING CHANGE.
```

```bash
# Daftarkan ke git global
git config --global commit.template ~/.gitmessage
```

#### 2. Global Commitizen

```bash
npm install -g commitizen cz-conventional-changelog
echo '{ "path": "cz-conventional-changelog" }' > ~/.czrc
git cz
```

#### 3. Alias Git Log

```bash
git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
# Gunakan: git lg
```

---

### FINDRISC Scoring Rules (`docs/FINDRISC.md`)

Spesifikasi aturan logika, variabel, skoring, dan kesimpulan sistem skrining risiko Diabetes Melitus Tipe 2 menggunakan metode FINDRISC.

#### Variabel Input & Bobot Skor

| #   | Variabel                            | Nilai                         | Poin |
| --- | ----------------------------------- | ----------------------------- | ---- |
| 1   | **Usia**                            | < 45 tahun                    | 0    |
|     |                                     | 45–54 tahun                   | 2    |
|     |                                     | 55–64 tahun                   | 3    |
|     |                                     | > 64 tahun                    | 4    |
| 2   | **IMT** (kg/m²)                     | < 25                          | 0    |
|     |                                     | 25–30                         | 1    |
|     |                                     | > 30                          | 3    |
| 3   | **Lingkar Pinggang**                | Pria < 94 / Wanita < 80 cm    | 0    |
|     |                                     | Pria 94–102 / Wanita 80–88 cm | 1    |
|     |                                     | Pria > 102 / Wanita > 88 cm   | 4    |
| 4   | **Aktivitas Fisik** ≥ 30 mnt/hari   | Ya                            | 0    |
|     |                                     | Tidak                         | 2    |
| 5   | **Konsumsi Buah/Sayur** setiap hari | Ya                            | 0    |
|     |                                     | Tidak                         | 1    |
| 6   | **Obat Hipertensi**                 | Tidak                         | 0    |
|     |                                     | Ya                            | 2    |
| 7   | **Riwayat Gula Darah Tinggi**       | Tidak                         | 0    |
|     |                                     | Ya                            | 5    |
| 8   | **Riwayat Keluarga DM**             | Tidak                         | 0    |
|     |                                     | Keluarga jauh                 | 3    |
|     |                                     | Keluarga inti                 | 5    |

`Total_Skor = Skor_1 + Skor_2 + ... + Skor_8`

#### Decision Rules

| Skor  | Kategori              | Risiko 10 Tahun | Rekomendasi                              |
| ----- | --------------------- | --------------- | ---------------------------------------- |
| < 7   | **Rendah**            | ~1%             | Pertahankan gaya hidup sehat             |
| 7–11  | **Sedikit Meningkat** | ~4%             | Perhatikan pola makan, batasi gula       |
| 12–14 | **Sedang**            | ~17%            | Cek gula darah berkala, konsultasi nakes |
| 15–20 | **Tinggi**            | ~33%            | Tes laboratorium (HbA1c/TTGO) ke dokter  |
| > 20  | **Sangat Tinggi**     | ~50%            | Segera evaluasi klinis menyeluruh        |

#### Pseudocode

```python
def hitung_kesimpulan_findrisc(total_skor):
    if total_skor < 7:
        return {"kategori": "Rendah", "probabilitas": "1%"}
    elif total_skor <= 11:
        return {"kategori": "Sedikit Meningkat", "probabilitas": "4%"}
    elif total_skor <= 14:
        return {"kategori": "Sedang", "probabilitas": "17%"}
    elif total_skor <= 20:
        return {"kategori": "Tinggi", "probabilitas": "33%"}
    else:
        return {"kategori": "Sangat Tinggi", "probabilitas": "50%"}
```
