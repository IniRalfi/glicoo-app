# 🔌 API CONTRACTS & INTEGRATION FLOW

Dokumen ini mendefinisikan rute komunikasi antara Mobile App (Flutter), Backend (Elysia), dan AI Agent/Bot (Telegram/WhatsApp).

## 🔗 1. Alur Sinkronisasi Akun & Bot (Deep Linking)

Untuk menghubungkan User ID di sistem dengan Chat ID di WhatsApp/Telegram:

1. **Flutter** memanggil `GET /api/v1/bot/link` untuk mendapatkan token unik yang kedaluwarsa dalam 10 menit.
2. **Flutter** membuka URL: `t.me/GlicoBot?start=<TOKEN_UNIK>`.
3. **User** menekan "Start" di Telegram.
4. **Telegram** mengirim webhook berisi Chat ID dan Token ke backend Elysia (`POST /api/v1/bot/webhook`).
5. **Elysia** memproses webhook tersebut, memvalidasi token, dan menyimpan Chat ID/identifier pengguna ke database User.


## 📡 2. Endpoints Backend (Elysia)

Base URL: `http://localhost:3000/api/v1`
Authorization: `Bearer <JWT_TOKEN>`

### A. Sinkronisasi Sensor (Background Task)

- **Endpoint:** `POST /sensors/sync`
- **Trigger:** Dipanggil oleh Flutter `workmanager` setiap beberapa jam.
- **Payload Request:**

```json
  {
    "date": "2026-05-14",
    "step_count": 4500,
    "screen_time_minutes": 120
  }
Response (200 OK):

JSON
  { "message": "Sensor data synced successfully" }
B. Pencatatan Makanan (Asynchronous)
- **Endpoint:** `POST /food/log`
- **Trigger:** Saat user men-submit teks makanan di Flutter.
- **Flow:** Elysia menyimpan ke DB -> Elysia kembalikan response 202 ke Flutter -> Elysia memicu analisis Gemini di latar belakang -> Elysia mengirim hasil ke Telegram user secara asinkron.
- **Payload Request:**
```json
  {
    "description": "Nasi padang pakai rendang dan es teh manis"
  }
```
- **Response (202 Accepted):**
```json
  {
    "message": "Log saved. AI is processing the analysis via chat."
  }
```

🤖 3. Integrasi AI Agent & Scheduler (Elysia Core)

Seluruh logika AI Agent dijalankan secara langsung dan asinkronus (non-blocking) di dalam backend Elysia:

### Analisis Makanan (Action-Driven)
1. Elysia memproses input makanan dan segera membalas ke Flutter dengan kode status 202.
2. Di latar belakang (asinkronus), Elysia memicu fungsi:
   - Kirim pesan Telegram awal ke user: "Hmm menarik, wait ya aku hitung dulu ⏳"
   - Eksekusi Gemini API untuk menghitung kalori, gula, dan memberikan feedback.
   - Perbarui data `FoodLog` (kolom `estimated_calories`, `estimated_sugar_grams`, dan `ai_feedback`) di database Supabase.
   - Kirim pesan hasil analisis gizi ke Telegram user.

### Intervention Scheduler (Time-Driven / Cron)
Diatur menggunakan library scheduler lokal (`croner`) di dalam backend Elysia:
- **Pagi (08:00):** Cek tabel DailySensorLog hari sebelumnya. Jika langkah kaki < 3000, kirim dorongan aktivitas secara proaktif ke Telegram user.
- **Malam (21:00):** Cek screen_time_minutes hari ini. Jika tinggi, kirim peringatan istirahat secara proaktif ke Telegram user untuk mencegah resiko lonjakan gula darah.

## 📊 4. Endpoints Admin Dashboard (`/admin/*`)

Rute khusus admin untuk memantau performa AI dan kesehatan sistem:

### A. Mendapatkan Metrik Utama Admin (Dashboard Overview)
- **Endpoint:** `GET /admin/stats`
- **Headers:** `x-admin-key: <ADMIN_API_KEY>`
- **Response (200 OK):**
```json
{
  "system": {
    "uptime_seconds": 345600,
    "database_connected": true,
    "api_latency_ms": 42
  },
  "ai": {
    "active_provider": "gemini",
    "fallback_chain": ["gemini", "groq", "openai"],
    "failures_today": 2,
    "success_today": 128,
    "average_latency_ms": 1240
  },
  "users": {
    "total_registered": 150,
    "daily_active_users": 84,
    "linked_to_bot": 65
  },
  "sensors": {
    "total_steps_today": 320000,
    "average_steps": 3809,
    "average_screen_time_minutes": 185
  }
}
```


