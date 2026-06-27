# 📋 CHANGELOG — Glicoo

Semua perubahan penting pada proyek Glicoo akan didokumentasikan di sini.
Format mengikuti [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) dan [Semantic Versioning](https://semver.org/).

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

---

## [0.9.0-beta] — 2026-06-23

### ✨ Added
- Backend Elysia scaffold awal + Swagger + health check.
- Auth mobile (Google OAuth + Email/Password).
- Struktur monorepo Bun Workspaces.
- Profil FINDRISC + simpan ke Supabase.
- Bottom Navigation Shell (4 tab).

---

> 📌 **Catatan Deployment:**
> - Mobile: `flutter build apk --release` → distribusikan via Supabase Storage / Firebase App Distribution.
> - Backend: Deploy ke **Railway.app** atau **Fly.io** dengan Docker / Bun runtime.
