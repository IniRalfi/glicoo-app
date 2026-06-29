# 🧠 Glicoo — Asisten Cerdas Pencegah Diabetes Tipe 2

> _"Cegah Diabetes Sejak Dini dengan AI yang Ada di Saku Anda"_

**Glicoo** adalah aplikasi mobile berbasis Agentic AI yang memanfaatkan sensor pasif smartphone (langkah, screen time, kamera) untuk mendeteksi dini risiko Diabetes Melitus Tipe 2. Aplikasi ini hadir dengan asisten AI proaktif yang berkomunikasi melalui WhatsApp/Telegram di 3 momen kritis (jam makan, jam kerja, jam tidur) untuk memberikan intervensi perilaku yang dipersonalisasi.

**🏆 Dibuat untuk Lomba PEKAN IT 2026 — Kategori Software Development**

---

## ✨ Fitur Utama

- 📱 **Mobile App** (Flutter) — Monitoring aktivitas harian via sensor HP (langkah, screen time), FINDRISC risk assessment, dan in-app chatbot AI
- 🤖 **Chatbot AI (Iloo)** — Asisten AI untuk konsultasi kesehatan dan intervensi perilaku, tersedia in-app dan via Telegram
- 📊 **Tracking Real-time** — Pantau langkah kaki, durasi tidur, screen time, dan pencatat makanan AI
- 🎯 **Gamifikasi Misi** — Misi harian dengan progress tracking dan skor kesehatan dinamis (0-100)
- 🌐 **Landing Page** (Next.js) — Website untuk informasi produk dan download APK

---

## 🏗️ Arsitektur Sistem

```
┌─────────────────────────────────────────────────────────┐
│                     Mobile App (Flutter)                 │
│  • Sensor (Langkah, Screen Time)                        │
│  • In-App Chatbot                                        │
│  • FINDRISC Assessment                                   │
│  • Gamifikasi Misi                                       │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│              Backend API (Elysia.js + Prisma)           │
│  • Auth & User Management (Supabase JWT)                │
│  • Sensor Data Sync                                      │
│  • Food Logging AI (Gemini)                             │
│  • In-App Chat Endpoint                                  │
│  • Telegram Bot Integration                             │
│  • Proactive Reminders (Cron)                           │
└──────────────────┬──────────────────────────────────────┘
                   │
      ┌────────────┼────────────┐
      ▼            ▼            ▼
┌──────────┐  ┌─────────┐  ┌──────────────┐
│PostgreSQL│  │ Gemini  │  │Telegram Bot  │
│(Supabase)│  │2.5 Flash│  │  @glicoo_bot │
└──────────┘  └─────────┘  └──────────────┘

┌─────────────────────────────────────────────────────────┐
│           Landing Page (Next.js + Vercel)               │
│  • Informasi Produk                                     │
│  • Download APK                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Komponen            | Teknologi                                 |
| ------------------- | ----------------------------------------- |
| **Mobile App**      | Flutter 3.x + Riverpod + Freezed          |
| **Backend API**     | Elysia.js + Prisma ORM + Bun Runtime      |
| **Landing Page**    | Next.js 14 App Router + TailwindCSS v4    |
| **Database**        | PostgreSQL (Supabase)                     |
| **AI**              | Gemini 2.5 Flash (Failover: OpenAI/Groq)  |
| **Chat Platform**   | Telegram Bot API (in-app + external)      |
| **Authentication**  | Supabase Auth (Google OAuth + Email/Pass) |
| **Deployment**      | Vercel (Backend + Web), APK (Mobile)      |
| **Background Jobs** | WorkManager (Android), Cron (Backend)     |

---

## 📂 Struktur Proyek

```
glicoo/
├── apps/
│   ├── backend/          # Backend API (Elysia + Prisma)
│   ├── mobile/           # Mobile App (Flutter)
│   └── web/              # Landing Page (Next.js)
├── packages/             # Shared packages (utils, configs, types)
├── docs/                 # Dokumentasi (API Spec, Arsitektur)
├── .gitignore
├── LICENSE
└── README.md
```

---

## 🚀 Cara Menjalankan

### Prerequisites

- **Bun** v1.0+ (untuk backend & workspaces)
- **Flutter SDK** v3.x+ (untuk mobile)
- **Android Studio** (untuk build APK)
- **Supabase Account** (database + auth)
- **Gemini API Key** (untuk AI chatbot)

### 1. Clone Repository

```bash
git clone https://github.com/iniralfi/glicoo.git
cd glicoo
```

### 2. Install Dependencies

```bash
bun install
```

### 3. Setup Backend

```bash
cd apps/backend
cp .env.example .env
# Edit .env: isi DATABASE_URL, SUPABASE_URL, GEMINI_API_KEY, dll
bun run db:migrate
bun run dev
```

### 4. Setup Mobile App

```bash
cd apps/mobile
cp .env.example .env
# Edit .env: isi BACKEND_URL, SUPABASE_URL, SUPABASE_ANON_KEY
flutter pub get
flutter run
```

### 5. Setup Landing Page (Opsional)

```bash
cd apps/web
bun run dev
```

---

## 🔐 Keamanan & Privasi

- **JWT Authentication** — Semua endpoint backend dilindungi Supabase JWT
- **No Medical Data** — Aplikasi hanya menyimpan pola perilaku (langkah, screen time), bukan data medis sensitif
- **Encrypted Database** — Data disimpan di Supabase PostgreSQL dengan enkripsi at-rest
- **Rate Limiting** — Bot webhook dan AI endpoints dilindungi rate limiting

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah **MIT License** — lihat file [`LICENSE`](LICENSE) untuk detail.

> **Attribution Required:** Setiap distribusi, fork, atau turunan dari proyek ini **wajib** menyertakan kredit yang jelas bahwa aplikasi ini adalah fork atau turunan dari **Glicoo** oleh [iniralfi](https://github.com/iniralfi). Kredit dapat dicantumkan di README, About page, atau bagian lain yang terlihat oleh pengguna.

---

## 🤝 Kontribusi

Kami menyambut kontribusi dari siapa pun! Silakan buka _issue_ atau _pull request_.

- 📋 Baca panduan kontribusi di [`CONTRIBUTING.md`](CONTRIBUTING.md)
- 📝 Ikuti format commit — lihat [`docs/commit-guide.md`](docs/commit-guide.md)
