# 🗄️ DATABASE SCHEMA (Supabase / Prisma)

Dokumen ini mendefinisikan struktur database utama untuk ekosistem Glico. Skema ini bersifat _volatile_ selama masa pengembangan, pastikan untuk menyesuaikan file ini jika ada migrasi database baru.

## 📌 ERD & Penjelasan Tabel Utama

### 1. `User` (Profil & Risiko Kesehatan)

Menyimpan data otentikasi dasar dan profil kesehatan untuk kalkulasi risiko awal.

- **id**: UUID (Primary Key)
- **name**: String
- **phone_number**: String (Unik, digunakan untuk bot WhatsApp/Telegram)
- **age**: Int
- **weight**: Float (kg)
- **height**: Float (cm)
- **has_family_history**: Boolean (Riwayat diabetes keturunan)
- **risk_score**: Float (0-100, dihitung oleh AI berdasarkan profil dan behavior)

### 2. `DailySensorLog` (Agregasi Langkah & Screen Time)

Menyimpan agregasi harian. Logika _checkpoint_ pagi/siang ditangani oleh _backend_ dengan mengecek `updated_at`.

- **id**: UUID
- **user_id**: UUID (Foreign Key ke User)
- **date**: DateTime (Hanya tanggal: YYYY-MM-DD)
- **step_count**: Int (Diperbarui secara inkremental oleh aplikasi Flutter)
- **screen_time_minutes**: Int
- **updated_at**: DateTime (Penting untuk cek status siang/sore)

### 3. `FoodLog` (Pencatatan Makanan via Teks)

- **id**: UUID
- **user_id**: UUID
- **description**: String (Contoh: "Makan siang pakai nasi padang rendang dan es teh manis")
- **logged_at**: DateTime
- **estimated_calories**: Int? (Diisi otomatis oleh AI n8n)
- **estimated_sugar_grams**: Float? (Diisi otomatis oleh AI n8n)
- **ai_feedback**: String? (Komentar XAI terhadap makanan tersebut)

### 4. `InterventionChat` (Log Percakapan AI & Metacognitive)

Menyimpan riwayat chat WhatsApp/Telegram agar AI memiliki memori dan bisa dipantau dari Dashboard Web.

- **id**: UUID
- **user_id**: UUID
- **message**: String (Isi pesan)
- **sender_type**: Enum (`USER`, `AI_AGENT`)
- **intervention_moment**: Enum (`MORNING_CHECK`, `AFTERNOON_WALK`, `NIGHT_SLEEP`, `MEAL_TIME`, `NONE`)
- **created_at**: DateTime

---

## 🔒 Row Level Security (RLS) Rules

Karena menggunakan Supabase, patuhi aturan akses ini:

- **Mobile App (via Backend)**: Backend memvalidasi JWT dari Supabase Auth, hanya dapat membaca/menulis data milik `user_id` yang cocok.
- **AI Engine (n8n)**: Menggunakan Service Role Key (Admin) untuk menarik history chat dan memberikan update skor makanan.
- **Web Dashboard**: Admin (Panitia/Dokter) memiliki akses baca ke seluruh tabel agregasi (tanpa melihat PII / nama spesifik jika anonim).
