# 📑 PRODUCT REQUIREMENTS DOCUMENT (PRD)

**Project:** Glico — Asisten Cerdas Pencegah Diabetes Tipe 2  
**Event:** PEKAN IT 2026 (Kategori: Software Development)  
**Theme:** Gaya Hidup Sehat dan Kesehatan

---

## 1. 🎯 Latar Belakang & Pernyataan Masalah (Problem Statement)

Diabetes Melitus Tipe 2 saat ini menjadi salah satu penyebab kematian tertinggi di Indonesia. Penyakit ini sering kali mengintai tanpa disadari, terutama akibat gaya hidup _sedentary_ (kurang gerak) dan pola konsumsi gula yang tidak terkontrol.
Sayangnya, edukasi kesehatan sering kali terasa menggurui atau satu arah. Glico hadir untuk memecahkan masalah ini dengan memberikan intervensi proaktif, personal, dan empatik melalui platform yang paling sering dibuka masyarakat: aplikasi _chat_ (WhatsApp/Telegram).

## 2. 👤 Target Pengguna (Target Audience)

- **Demografi Utama:** Gen Z dan masyarakat umum di Indonesia yang memiliki _smartphone_.
- **Karakteristik:** Pengguna yang ingin mulai hidup sehat tapi butuh pengingat yang ramah (tidak kaku seperti alarm biasa), serta pengguna yang memiliki riwayat genetik diabetes di keluarganya.
- **Syarat Akses (Gated Access):** Pengguna **wajib** mengunduh dan melakukan registrasi di aplikasi _mobile_ Glico untuk mendapatkan _Deep Link_ akses ke asisten bot Telegram/WA. Ini memastikan bot hanya melayani pengguna dengan profil risiko yang sudah terukur.

## 3. 🏆 Metrik Kesuksesan (Success Metrics)

Sebagai MVP untuk kompetisi, kesuksesan Glico diukur melalui metrik teknis dan perilaku:

1. **Peningkatan Aktivitas:** Persentase pengguna yang mengalami peningkatan rata-rata langkah kaki harian setelah intervensi bot.
2. **Engagement Log Makanan:** Pengguna secara konsisten melaporkan makanan mereka (minimal 1 kali sehari) karena proses input berbasis teks yang mudah.
3. **Performa Sistem:** AI Agent (Gemini via Backend Elysia) mampu merespons log makanan pengguna dalam waktu kurang dari 5 detik.
4. **Metrik Kesehatan:** Penurunan tren _screen time_ di jam rawan tidur (setelah pukul 21:00) yang terukur melalui sensor aplikasi.

## 4. 🚧 Batasan Produk (Out of Scope / Non-Goals)

Untuk menjaga fokus pada MVP (Minimum Viable Product), fitur berikut **TIDAK** akan dikembangkan pada fase ini:

- Tidak ada integrasi dengan perangkat eksternal (_Smartwatch_, _Fitness Tracker_).
- Tidak menyediakan fitur konsultasi _live_ dengan dokter atau tenaga medis asli.
- Tidak menggunakan fitur pemindaian _barcode_ atau deteksi gambar makanan (OCR/Vision); log makanan murni menggunakan pendekatan _Natural Language Text_.
- Bukan aplikasi medis untuk mendiagnosis penyakit secara pasti.

## 5. 💡 Model Keberlanjutan & Nilai Tambah (Social Impact Value)

Glico dirancang sebagai inisiatif **Non-Profit / Social Impact** yang berfokus pada pencegahan di masyarakat Indonesia.
Strategi keberlanjutan (jika diluncurkan ke publik) tidak berfokus pada langganan pengguna akhir, melainkan melalui:

- Potensi kerja sama CSR (_Corporate Social Responsibility_) dari perusahaan multinasional.
- Pemanfaatan hibah teknologi kesehatan (_Health-Tech Grants_) dari pemerintah atau instansi kesehatan terkait.
