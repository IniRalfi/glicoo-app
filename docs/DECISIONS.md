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

## Decision 004: Memisahkan AI Engine (n8n) dari Backend Utama

- **Status:** Diterima
- **Alasan:**
  1. **Performa:** Menjaga _backend_ Elysia agar tidak terbebani (_bottleneck_) oleh waktu tunggu pemrosesan _prompt_ LLM.
  2. **Fleksibilitas:** Logika _chatbot_ (Socratic Questioning, penjadwalan) bisa diubah secara bebas di _visual editor_ n8n kapan saja tanpa perlu melakukan _re-build_ atau _re-deploy_ pada _backend_ utama.
- **Tradeoff:** Arsitektur menjadi sedikit lebih kompleks karena harus memantau dua _service_ yang berbeda (_backend_ dan n8n) saat _debugging_.
