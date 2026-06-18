# 🚶‍♂️ USER FLOWS & JOURNEY

**Project:** Gluco/Glico — Software Cerdas Berbasis Agentic AI untuk Deteksi Risiko dan Intervensi Perilaku dalam Pencegahan Diabetes Melitus Tipe 2  
**Tujuan Dokumen:** Menjadi panduan bagi AI dan Developer dalam membangun urutan layar (UI/UX) dan interaksi sistem yang sejalan dengan SDGs 3 & 4.

---

## 📱 1. Alur Aplikasi Mobile (Flutter Gateway)

### A. Onboarding & Profiling Awal

Aplikasi bertindak sebagai asisten kesehatan pencegahan, bukan aplikasi _telemedicine_, sehingga pengumpulan data awal sangat krusial.

1. **Splash Screen:** Tampil singkat dengan animasi memuat data esensial (tanpa _loading_ panjang).
2. **Legalitas:** Layar persetujuan _Terms of Service_ dan _Privacy Policy_.
3. **Autentikasi:** Login menggunakan Google OAuth.
4. **Formulir Profil Risiko:** Pengguna mengisi data dasar pendampingan:
   - Usia dan Jenis Kelamin
   - Tinggi Badan (TB) & Berat Badan (BB)
   - Lingkar Perut
   - Riwayat Penyakit Keluarga / Gula Darah Tinggi

### B. Perizinan Sensor (Permissions)

1. **Edukasi Interaktif:** Muncul _popup_ kartu (Bento Grid) yang menjelaskan secara ramah mengapa aplikasi butuh melacak langkah kaki, durasi duduk, dan _screen time_ untuk pemantauan gaya hidup.
2. **System Prompt:** Muncul dialog bawaan OS (Android/iOS) untuk meminta izin sensor fisik dan akses latar belakang.

### C. Sinkronisasi Bot Agentic AI

Halaman khusus ini adalah jembatan utama antara aplikasi dan AI.

1. **Status Koneksi:** Masuk ke tab "Bot Assistant", terlihat status **"Belum Terhubung"**.
2. **Aksi Tautkan:** Pengguna menekan tombol "Hubungkan ke Telegram/WhatsApp".
3. **Deep Linking:** Aplikasi membuka platform _chat_ secara otomatis dengan parameter token unik.
4. **Keberhasilan:** Saat pengguna kembali ke aplikasi, antarmuka berubah. Status menjadi **"Terhubung"**, dan tombol berubah fungsi menjadi **"Chat Sekarang"**.

---

## 🤖 2. Alur Intervensi AI (WhatsApp/Telegram via n8n)

Fitur utama pendampingan terjadi di platform _chat_, berjalan secara _asynchronous_ dan diinisiasi oleh sistem (_Bot-first_), bukan _User-first_.

### A. Proactive Food Logging (Jam Makan)

1. **Sistem Trigger:** Jadwal (Cron) di n8n mendeteksi jam makan siang (misal: 12:30).
2. **Bot Menyapa:** Bot mengirim pesan duluan: _"Halo Kak! Udah jam makan siang nih, hari ini makan apa aja? 🍛"_
3. **User Input:** Pengguna membalas dengan teks alami (misal: _"Nasi padang pake es teh"_).
4. **AI XAI Feedback:** AI memproses estimasi karbohidrat/gula dan membalas dengan saran aktivitas fisik (misal: _"Wah enak! Jangan lupa nanti sore jalan 3000 langkah ya biar gula darah tetap stabil."_).

### B. Proactive Health Reminder (Metrik Sensor)

1. **Sistem Trigger:** n8n membaca data agregasi dari _database_ (jumlah langkah, durasi penggunaan ponsel, durasi duduk).
2. **Intervensi Malam:** Jika _screen time_ tinggi pada pukul 22:00, bot mengirim pesan: _"Kak, udah malam nih, screen time-nya tinggi banget. Yuk istirahat biar kualitas tidur dan mood besok tetap bagus! 💤"_

---

## 🌐 3. Alur Web Dashboard (Next.js)

Web bertindak sebagai wajah publik produk dan alat pemantauan tingkat lanjut, mereplikasi model aplikasi terpusat.

### A. Landing Page (Pengunjung Publik)

1. **Hero Section:** Menampilkan _mockup_ aplikasi, _value proposition_ tentang pencegahan DM Tipe 2, dan integrasi AI.
2. **Call to Action (CTA):** Tombol **"Unduh Aplikasi Sekarang"**. Pengguna baru tidak bisa menggunakan fitur utama tanpa mengunduh aplikasi terlebih dahulu.

### B. Analytics Dashboard (Pengguna Terdaftar)

1. **Login:** Pengguna yang sudah mengunduh dan mendaftar di _mobile_ dapat masuk menggunakan Google OAuth.
2. **Dashboard View:** Menampilkan grafik analitik kesehatan yang lebih kaya dan interaktif (kadar rata-rata langkah, kalori dari log makanan, dan metrik aktivitas fisik) dalam tata letak minimalis dan warna pastel.
