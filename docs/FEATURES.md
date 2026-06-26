# 🌟 CORE FEATURES & APP STRUCTURE

**Project:** Glico — Asisten Cerdas Pencegah Diabetes Tipe 2
**Platform:** Mobile (Flutter), Web (Next.js), Bot (Elysia + Gemini)

Dokumen ini mendefinisikan fitur utama dan struktur navigasi halaman dari ekosistem Glico.

---

## 📱 1. Mobile App (Flutter)

Aplikasi bertindak sebagai pemantau sensor pasif (langkah & _screen time_) dan pusat kontrol pengguna. Menggunakan desain minimalis _Bento Grid_ dan warna pastel.

### Bottom Navigation Bar (3-4 Menu):

1. **🏠 Home (Dashboard & Analytics Terpusat)**
   - **FINDRISC Status Bar:** Menampilkan kategori risiko pengguna (Rendah, Meningkat, Prediabetes, Diabetes Tipe 2) di bagian paling atas.
   - **Bento Box - Live Sensors:** Menampilkan grafik sirkular jumlah langkah kaki harian dan total _screen time_.
   - **Bento Box - Analytics:** Grafik mini tren mingguan (misal: Rata-rata langkah vs Perkiraan konsumsi gula dari Bot).
   - **Bento Box - AI Insight:** Rangkuman saran pendek dari interaksi Bot terakhir.

2. **🎯 Quests (Misi Harian / Gamifikasi)**
   - Daftar tugas harian yang di- _generate_ secara dinamis oleh AI berdasarkan tingkat risiko FINDRISC pengguna.
   - **Auto-Tracker Task:** Misi yang otomatis tercentang (contoh: "Jalan 3000 langkah") karena terhubung ke sensor perangkat.
   - **Manual Task:** Misi perilaku (contoh: "Minum air 2 Liter", "Tidur sebelum jam 10") yang bisa dicentang pengguna.

3. **🤖 Bot Hub & Chatbot (Pusat Kontrol AI)**
   - **In-App Chatbot:** Chatbot bawaan langsung di dalam aplikasi untuk interaksi offline/privacy-first.
   - **Local Storage Chat:** Seluruh riwayat obrolan In-App Chatbot disimpan di penyimpanan lokal HP pengguna.
   - **Bot Chat Integration:** Tombol *Deep Link* untuk opsional menghubungkan WhatsApp atau Telegram.
   - **Pengaturan Persona AI & Notifikasi:** Memilih persona asisten (misal: "Tegas & Menantang" atau "Santai & Edukatif") serta mengaktifkan Push Notifications lokal.


4. **👤 Profile**
   - Data diri, pengaturan akun (Google Auth), dan _toggle_ perizinan sensor (_Permissions_).
   - Tombol **"Hitung Ulang Risiko FINDRISC"** untuk evaluasi berkala.

---

## 🤖 2. AI Agent (Elysia + Gemini via WA/Tele)

Beroperasi sebagai pendamping asinkron yang proaktif. Logika perilakunya menyesuaikan input FINDRISC.

- **Proactive Food Logging:** Bot mengirim pesan saat jam makan untuk menanyakan menu.
- **Natural Language Parsing:** Menghitung estimasi karbohidrat dan gula dari teks biasa (tanpa _scan barcode_).
- **Contextual Reminders:** Menegur pengguna jika data sensor mobile menunjukkan _screen time_ malam yang berlebihan atau kurang gerak.
- **Dynamic Persona:**
  - _Risiko Rendah:_ Edukatif dan santai.
  - _Prediabetes / Diabetes:_ Lebih cerewet soal karbohidrat dan mengingatkan rutinitas sehat dengan ketat.

---

## 🌐 3. Web Dashboard (Next.js)

Tampilan layar lebar untuk keperluan publikasi dan analisis mendalam.

- **Public Landing Page (Non-Login):**
  - Halaman pameran _mockup_ aplikasi, penjelasan SDGs 3 & 4, dan CTA (Call-to-Action) untuk unduh `.apk` Android.
- **Advanced Dashboard (Login Required):**
  - Tampilan analitik yang lebih kaya dan detail.
  - **Food Log History:** Tabel lengkap riwayat makanan yang pernah dicatat melalui Bot, lengkap dengan estimasi kalorinya.
