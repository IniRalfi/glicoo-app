# 🧠 Glico — Asisten Cerdas Pencegah Diabetes Tipe 2

> _"Cegah Diabetes Sejak Dini dengan AI yang Ada di Saku Anda"_

**Glico** adalah aplikasi mobile berbasis Agentic AI yang memanfaatkan sensor pasif smartphone (langkah, screen time, kamera) untuk mendeteksi dini risiko Diabetes Melitus Tipe 2. Aplikasi ini hadir dengan asisten AI proaktif yang berkomunikasi melalui WhatsApp/Telegram di 3 momen kritis (jam makan, jam kerja, jam tidur) untuk memberikan intervensi perilaku yang dipersonalisasi.

**🏆 Dibuat untuk Lomba PEKAN IT 2026 — Kategori Software Development**

---

## ✨ Fitur Utama

- 📱 **Mobile App** (Flutter) — Akses sensor HP (langkah, screen time, kamera)
- 🌐 **Web Dashboard** (Next.js) — Monitoring data dan landing page
- 🤖 **Agentic AI** — Intervensi proaktif via WhatsApp/Telegram
- 🧠 **Explainable AI (XAI)** — Setiap saran disertai alasan jelas
- 📊 **Metacognitive Tracking** — Pantau bias offloading & overconfidence

---

## 🏗️ Arsitektur Sistem

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Mobile App    │────▶│   Backend API   │────▶│   AI Engine     │
│    (Flutter)    │     │  (Elysia/Express)│     │   (n8n + LLM)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │                        │
         ▼                       ▼                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Sensor HP     │     │   PostgreSQL    │     │ WhatsApp/Telegram│
│ - Step Counter  │     │   (Supabase)    │     │   (User Chat)    │
│ - Screen Time   │     └─────────────────┘     └─────────────────┘
│ - Kamera        │
└─────────────────┘
```

---

## 🛠️ Tech Stack

| Komponen           | Teknologi                                     |
| ------------------ | --------------------------------------------- |
| **Mobile App**     | Flutter                                       |
| **Backend API**    | Node.js + Elysia                              |
| **Web Dashboard**  | Next.js + TailwindCSS                         |
| **Database**       | PostgreSQL (Supabase / Neon)                  |
| **AI Engine**      | n8n + Gemini API (dipisah)                    |
| **Chat Interface** | Telegram Bot API / WhatsApp API               |
| **Deployment**     | Vercel (Web), Railway (Backend), APK (Mobile) |

---

## 📂 Struktur Proyek

```
glico/
├── apps/
│   ├── backend/          # Backend API (Elysia + Prisma)
│   ├── mobile/           # Mobile App (Flutter)
│   └── web/              # Web Dashboard (Next.js)
├── packages/             # Shared packages (utils, configs, types)
├── docs/                 # Dokumentasi (API Spec, Arsitektur)
├── .gitignore
├── LICENSE
└── README.md
```

---

## 🚀 Cara Menjalankan

### Prerequisites

- Node.js v18+
- Flutter SDK
- PostgreSQL
- Android Studio / Xcode (untuk mobile)
- API Key Gemini (untuk AI Engine)

### 1. Clone Repository

```bash
git clone https://github.com/iniralfi/glico.git
cd glico
```

### 2. Setup Backend

```bash
cd apps/backend
cp .env.example .env
# isi konfigurasi database & API key di .env
npm install
npm run dev
```

### 3. Setup Web Dashboard

```bash
cd apps/web
npm install
npm run dev
```

### 4. Setup Mobile App

```bash
cd apps/mobile
flutter pub get
flutter run
```

---

## 🔐 Keamanan & Privasi

- AI Engine **dipisah** di repository privat (hanya API endpoint yang diekspos)
- Semua data sensor disimpan di database dengan enkripsi
- Tidak ada data medis sensitif yang disimpan (hanya pola perilaku)

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah **MIT License** — lihat file [`LICENSE`](LICENSE) untuk detail.

> **Attribution Required:** Setiap distribusi, fork, atau turunan dari proyek ini **wajib** menyertakan kredit yang jelas bahwa aplikasi ini adalah fork atau turunan dari **Glico** oleh [iniralfi](https://github.com/iniralfi). Kredit dapat dicantumkan di README, About page, atau bagian lain yang terlihat oleh pengguna.

---

## 🤝 Kontribusi

Kami menyambut kontribusi dari siapa pun! Silakan buka _issue_ atau _pull request_.

- 📋 Baca panduan kontribusi di [`CONTRIBUTING.md`](CONTRIBUTING.md)
- 📝 Ikuti format commit — lihat [`docs/commit-guide.md`](docs/commit-guide.md)
