# 🗺️ GLICO DEVELOPMENT ROADMAP & TO-DO

Pendekatan pengembangan menggunakan metode **Horizontal (Per Aplikasi)**.
Aturan untuk AI: Saat mengerjakan suatu fase, pastikan kontrak API dan struktur data merujuk pada `DATABASE_SCHEMA.md` dan `API_CONTRACTS.md`.

---

## ase 1: 🏗️ Foundation & Shared Packages (The Glue)

Fase ini mengamankan fondasi monorepo agar Web dan Mobile memiliki sumber kebenaran tipe data yang sama.

- [ ] **Task 1.1:** Inisialisasi Bun Workspaces (`apps/web`, `apps/backend`, `apps/mobile`, `packages/types`).
- [ ] **Task 1.2:** Setup Supabase Project & inisialisasi tabel berdasarkan `DATABASE_SCHEMA.md`.
- [ ] **Task 1.3:** Konfigurasi Prisma ORM di `apps/backend` dan migrasi database awal.
- [ ] **Task 1.4:** Buat TypeScript Interfaces di `packages/types` (hasil generate dari schema Prisma) agar bisa dipakai oleh backend dan web.

---

## ase 2: ⚙️ Backend API (Elysia.js)

Membangun logika server, validasi, dan jembatan ke n8n.

- [ ] **Task 2.1:** Setup struktur Elysia.js + Swagger UI untuk dokumentasi otomatis.
- [ ] **Task 2.2:** Buat Middleware untuk memvalidasi JWT dari Supabase Auth.
- [ ] **Task 2.3:** Buat rute `POST /sensors/sync` untuk menerima data agregasi dari Mobile.
- [ ] **Task 2.4:** Buat rute `POST /food/log` (simpan ke database dan teruskan trigger webhook ke n8n).
- [ ] **Task 2.5:** Buat rute Deep Linking `GET /bot/link` dan `POST /bot/verify` untuk sinkronisasi Telegram/WA.

---

## ase 3: 🌐 Web Dashboard (Next.js)

Membangun antarmuka pemantauan dengan gaya Minimalist Bento Grid.

- [ ] **Task 3.1:** Setup Next.js App Router, TailwindCSS, dan Zustand.
- [ ] **Task 3.2:** Integrasi Supabase Auth (Google OAuth) untuk login Web.
- [ ] **Task 3.3:** Buat komponen UI Bento Grid (Card base, rounded, pastel, non-neobrutalism).
- [ ] **Task 3.4:** Buat halaman Dashboard Utama (Menampilkan agregasi langkah, screen time, dan log intervensi chat).

---

## ase 4: 📱 Mobile App (Flutter)

Aplikasi untuk pengguna akhir, berfokus pada koleksi data sensor pasif.

- [ ] **Task 4.1:** Setup struktur Flutter dengan `hooks_riverpod`.
- [ ] **Task 4.2:** Integrasi Supabase Auth (Google OAuth) di Mobile.
- [ ] **Task 4.3:** Implementasi Background Task (Workmanager) untuk membaca data _Pedometer_ (Langkah) dan _Screen Time_.
- [ ] **Task 4.4:** Buat Cron lokal di Flutter untuk sinkronisasi data sensor ke endpoint Elysia `/sensors/sync` setiap beberapa jam.
- [ ] **Task 4.5:** Buat UI input teks untuk Log Makanan, tembak ke endpoint Elysia `/food/log`.
- [ ] **Task 4.6:** Implementasi UI Deep Linking bot Telegram/WA.

---

## ase 5: 🤖 AI Engine & Chatbot (n8n + Gemini)

Menghidupkan "otak" dari Glico.

- [ ] **Task 5.1:** Setup webhook di n8n untuk menerima trigger dari Telegram/WA dan Elysia.
- [ ] **Task 5.2:** Masukkan `AI_AGENT_PROMPTS.md` ke dalam node Gemini di n8n.
- [ ] **Task 5.3:** Buat alur Socratic Questioning & XAI untuk membalas log makanan.
- [ ] **Task 5.4:** Buat Scheduler di n8n (Cron) untuk membaca database Supabase dan mengirim intervensi pagi (jalan kaki) dan malam (teguran tidur).
