# 🔌 API CONTRACTS & INTEGRATION FLOW

Dokumen ini mendefinisikan rute komunikasi antara Mobile App (Flutter), Backend (Elysia), dan AI Engine (n8n).

## 🔗 1. Alur Sinkronisasi Akun & Bot (Deep Linking)

Untuk menghubungkan User ID di sistem dengan Chat ID di WhatsApp/Telegram:

1. **Flutter** memanggil `GET /api/v1/bot/link` untuk mendapatkan token unik yang kedaluwarsa dalam 10 menit.
2. **Flutter** membuka URL: `t.me/GlicoBot?start=<TOKEN_UNIK>`.
3. **User** menekan "Start" di Telegram.
4. **n8n** menerima Webhook dari Telegram berisi Chat ID dan Token.
5. **n8n** memanggil `POST /api/v1/bot/verify` ke Elysia untuk menyimpan Chat ID tersebut ke database User.

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
Endpoint: POST /food/log

Trigger: Saat user men-submit teks makanan di Flutter.

Flow: Elysia menyimpan ke DB -> Elysia hit Webhook n8n -> Elysia kembalikan response 200 ke Flutter (tanpa menunggu AI).

Payload Request:

JSON
  {
    "description": "Nasi padang pakai rendang dan es teh manis"
  }
Response (202 Accepted):

JSON
  {
    "message": "Log saved. AI is processing the analysis via chat."
  }
🤖 3. n8n Trigger & Webhooks (AI Engine)
Karena n8n berjalan terpisah, backend Elysia dan n8n berinteraksi melalui metode berikut:

Food Log Webhook (Action-Driven)

Elysia memanggil Webhook n8n saat /food/log dipanggil.

n8n Action 1: Segera kirim pesan Telegram: "Hmm menarik wait ya aku hitung dulu ⏳"

n8n Action 2: Eksekusi Gemini API.

n8n Action 3: Kirim hasil analisis diet ke Telegram user.

Intervention Scheduler (Time-Driven / Cron)

Diatur langsung di dalam n8n (tanpa campur tangan Elysia).

Pagi (08:00): Cek tabel DailySensorLog hari sebelumnya. Jika langkah kaki < 3000, kirim dorongan aktivitas.

Malam (21:00): Cek screen_time_minutes. Jika tinggi, kirim peringatan istirahat untuk menekan risiko lonjakan gula darah.
```
