# 🏛️ ARCHITECTURE DECISION RECORDS (ADR)

Dokumen ini mencatat keputusan teknologi utama untuk proyek Glico/Gluco. Jika AI atau Developer ingin mengubah stack, wajib merujuk dan mengevaluasi dokumen ini terlebih dahulu.

---

## Decision 001: Backend Framework menggunakan Elysia.js + Bun

- **Status:** Diterima
- **Alasan:** Fokus utama adalah **kecepatan eksekusi**. Ekosistem Bun dipadukan dengan Elysia.js memberikan performa _runtime_ tertinggi dibandingkan Express.js atau NestJS, sangat ideal untuk merespons sinkronisasi data sensor secara instan.
- **Tradeoff:** Komunitas dan _library_ pihak ketiga belum sebanyak Express, namun cukup untuk kebutuhan MVP.

## Decision 002: State Management Flutter menggunakan Riverpod

- **Status:** Diterima
- **Alasan:** Terpilih karena memberikan keseimbangan terbaik antara keamanan (_compile-safe_) dan produktivitas. Berbeda dengan BLoC yang membutuhkan banyak _boilerplate_ awal, Riverpod memungkinkan pengembangan fitur UI dengan arsitektur bersih yang lebih cepat, sangat cocok untuk ritme pengerjaan lomba.
- **Tradeoff:** Kurva belajar awal (_learning curve_) bagi tim yang belum terbiasa dengan konsep `ProviderScope` dan `ConsumerWidget`.

## Decision 003: Database Infrastructure menggunakan Supabase (PostgreSQL)

- **Status:** Diterima (Solusi Sementara / MVP)
- **Alasan:** Mempercepat fase _development_ karena fitur Auth (Google OAuth) dan database langsung tersedia secara instan. Ini adalah keputusan pragmatis untuk mengejar _deadline_ lomba.
- **Rencana Migrasi:** Ke depannya (fase produksi/post-lomba), _database_ akan dipindahkan ke VPS mandiri untuk menekan biaya. Oleh karena itu, penggunaan ORM (Prisma) diwajibkan agar proses migrasi nanti hanya perlu mengganti URL koneksi tanpa merombak logika kode.

## Decision 004: Mengintegrasikan AI Agent & Bot (Telegram/WhatsApp) ke Backend Utama

- **Status:** Diterima
- **Alasan:**
  1. **Kesederhanaan & Realistis:** AI Agent (Gemini SDK) dan Bot Interface (Telegram/WhatsApp via OpenWA) diintegrasikan langsung di dalam backend Elysia secara asinkronus, meminimalkan kompleksitas infrastruktur.
  2. **Efisiensi Runtime Bun:** Menggunakan runtime Bun yang mendukung pemrosesan asinkronus (_non-blocking_), sehingga pemanggilan API Gemini dan Telegram/WhatsApp Bot dapat berjalan di latar belakang tanpa menghambat respon utama server Elysia.
- **Tradeoff:** Logika chatbot dan penjadwalan (_cron_) didefinisikan langsung dalam kode TypeScript backend, yang membutuhkan _re-deploy_ jika terdapat perubahan prompt/logika percakapan.

## Decision 005: Multi-Provider LLM & Fallback Mechanism (Failover)

- **Status:** Diterima
- **Alasan:** Menjamin keandalan (_availability_) AI Agent agar sistem tetap responsif jika salah satu penyedia LLM (seperti Gemini) mengalami kegagalan, _rate limit_, atau _service outage_.
- **Desain:** Membuat layer abstrak `AIService` di backend Elysia. Sistem akan mencoba mengeksekusi LLM utama (misal: Gemini). Jika gagal, sistem secara otomatis menangkap _error_ (_fallback_) dan mengalihkan _request_ ke penyedia cadangan (seperti Groq, OpenAI, atau Anthropic) yang dikonfigurasi melalui API Key di `.env`.

## Decision 006: Web Admin Monitoring Dashboard

- **Status:** Diterima
- **Alasan:** Menyediakan antarmuka bagi panitia/admin untuk memantau status kesehatan sistem, performa AI, serta statistik penggunaan user secara langsung tanpa harus mengakses database secara mentah.
- **Metrik Utama:**
  1. _Health Monitor_: Server uptime, status koneksi Supabase, latensi endpoint.
  2. _AI Performance_: Status provider aktif, total token, rasio kegagalan/sukses API AI, rata-rata waktu respon AI.
  3. _User Stats_: Total user terdaftar, DAU (Daily Active User), persentase user terhubung ke Bot Telegram/WA.
  4. _Aggregated Sensor & Logs_: Total langkah mingguan, rata-rata _screen time_, dan total _food logs_ tercatat.
