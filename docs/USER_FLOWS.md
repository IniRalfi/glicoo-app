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

## 🤖 2. Alur Intervensi AI & Chatbot Multi-Channel (Telegram/WA & In-App)

Pendampingan terjadi melalui dua opsi saluran utama: melalui Bot Chat luar (Telegram/WhatsApp) atau Chatbot bawaan langsung di dalam aplikasi Mobile (In-App).

### A. Alur Proactive Intervensi (Proactive Intervention)
1. **Pemicu Sistem (Cron):** Sistem mendeteksi jam makan siang (12:30) atau jam malam (21:00/22:00) untuk memeriksa data sensor harian.
2. **Pengiriman Pengingat:**
   - **Saluran Bot Chat (Terhubung):** Pesan dikirim duluan ke Telegram/WA (misal: *"Halo Kak! Udah jam makan siang nih, makan apa hari ini? 🍛"* atau *"Kak, udah malam nih, yuk kurangi screen time dan istirahat! 💤"*).
   - **Saluran In-App (Bawaan):** Aplikasi mobile mengirim **Push Notification** lokal ke HP pengguna, mengarahkan mereka ke tab "In-App Chatbot" untuk berinteraksi.

### B. Alur Pencatatan Makanan & Feedback (Action-Driven)
1. **User Input:** Pengguna mengirim log makanan via teks (misal: *"Nasi padang pake es teh"*) baik di Telegram/WA atau melalui antarmuka **In-App Chatbot**.
2. **Pemrosesan AI:** Backend Elysia secara asinkron memanggil Gemini API untuk menganalisis perkiraan kalori/gula serta membuat feedback Socratic yang bersahabat.
3. **Response & Penyimpanan Riwayat:**
   - **Pada Bot Chat:** Respon dikirimkan ke Telegram/WA pengguna dan riwayat chat disimpan di database server.
   - **Pada In-App Chatbot:** Respon dikirim kembali ke aplikasi Mobile, dan **riwayat percakapan disimpan secara lokal di Local Storage perangkat** (Shared Preferences/SQLite) untuk kenyamanan privasi dan kecepatan.


---

## 🌐 3. Alur Web Dashboard (Next.js)

Web bertindak sebagai wajah publik produk dan alat pemantauan tingkat lanjut, mereplikasi model aplikasi terpusat.

### A. Landing Page (Pengunjung Publik)

1. **Hero Section:** Menampilkan _mockup_ aplikasi, _value proposition_ tentang pencegahan DM Tipe 2, dan integrasi AI.
2. **Call to Action (CTA):** Tombol **"Unduh Aplikasi Sekarang"**. Pengguna baru tidak bisa menggunakan fitur utama tanpa mengunduh aplikasi terlebih dahulu.

### B. Analytics Dashboard (Pengguna Terdaftar)

1. **Login:** Pengguna yang sudah mengunduh dan mendaftar di _mobile_ dapat masuk menggunakan Google OAuth.
2. **Dashboard View:** Menampilkan grafik analitik kesehatan yang lebih kaya dan interaktif (kadar rata-rata langkah, kalori dari log makanan, dan metrik aktivitas fisik) dalam tata letak minimalis dan warna pastel.
