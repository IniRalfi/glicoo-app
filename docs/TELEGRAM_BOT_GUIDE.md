# 🤖 PANDUAN PEMBUATAN & INTEGRASI BOT TELEGRAM (GLICOO)

Dokumen ini menjelaskan langkah demi langkah untuk membuat Bot Telegram via BotFather, mendapatkan token akses, serta menghubungkannya dengan webhook Elysia backend agar bot dapat membalas pesan secara asinkron menggunakan kecerdasan buatan Gemini.

---

## 🛠️ Langkah 1: Membuat Bot Baru di Telegram

1. Buka aplikasi Telegram dan cari **@BotFather** (akun resmi dengan centang biru).
2. Mulai obrolan dengan mengirimkan perintah `/newbot`.
3. **Pilih Nama Bot**: Masukkan nama tampilan bot Anda (contoh: `Glicoo Buddy`).
4. **Pilih Username Bot**: Masukkan username unik yang berakhiran kata `bot` (contoh: `GlicoBot` atau `glicoo_assistant_bot`).
5. **Dapatkan Token HTTP API**: BotFather akan mengirimkan pesan berisi token akses rahasia (Token HTTP API). Simpan token ini dengan baik.
   * *Format Token:* `1234567890:ABCdefGhIJKlmNoPQRsTUVwxyZ`

---

## ⚙️ Langkah 2: Mengonfigurasi Environment Variables Backend

Buka file `.env` di `apps/backend/.env` dan tambahkan variabel berikut:

```env
# Token dari BotFather
TELEGRAM_BOT_TOKEN="1234567890:ABCdefGhIJKlmNoPQRsTUVwxyZ"

# URL Backend Publik (Wajib HTTPS untuk Webhook Telegram)
# Jika menggunakan local development, gunakan ngrok / localtunnel:
# ngrok http 3000
WEBHOOK_URL="https://subdomain-anda.ngrok-free.app"
```

---

## 🌐 Langkah 3: Mendaftarkan Webhook ke Telegram

Telegram membutuhkan endpoint publik HTTPS yang valid untuk mengirimkan pesan dari pengguna ke backend Glicoo.

### Cara Manual via Browser / cURL:
Untuk memberi tahu Telegram agar mengirimkan seluruh data pesan baru ke backend Anda, jalankan perintah berikut di terminal Anda (ganti `<TOKEN>` dan `<WEBHOOK_URL>`):

```bash
curl -F "url=<WEBHOOK_URL>/api/v1/bot/webhook" https://api.telegram.org/bot<TOKEN>/setWebhook
```

Jika sukses, Anda akan menerima respon JSON:
```json
{
  "ok": true,
  "result": true,
  "description": "Webhook was set"
}
```

---

## 🔗 Langkah 4: Bagaimana Pengguna Menautkan Akun Mereka?

Sistem Glicoo menggunakan mekanisme **Deep Linking** bawaan Telegram agar pengguna tidak perlu repot mengetik token di chat bot.

1. **Meminta OTP di App**: Pengguna menekan tombol "Hubungkan ke Telegram" di profil aplikasi mobile Glicoo.
2. **Redirect Otomatis**: Aplikasi Flutter akan mengarahkan pengguna ke link Telegram khusus:
   `https://t.me/<USERNAME_BOT>?start=<OTP_TOKEN>`
3. **Mulai Bot**: Ketika pengguna menekan **Start** di Telegram, Telegram akan mengirim pesan perintah `/start <OTP_TOKEN>` ke backend Elysia via Webhook.
4. **Verifikasi Webhook**: Backend akan memverifikasi token OTP tersebut di database Supabase dan secara otomatis menautkan `telegramChatId` ke akun pengguna yang sesuai.
5. **Koneksi Sukses**: Bot akan membalas dengan pesan selamat datang, dan tab status bot di aplikasi seluler Glicoo akan berubah menjadi **Terhubung**.

---

## 🎯 Tips Pengujian di Lingkungan Lokal (Local Development)

Karena webhook Telegram mewajibkan protokol HTTPS, Anda memerlukan alat penembus firewall lokal seperti **ngrok**:

1. Jalankan ngrok pada port backend Anda (default: `3000`):
   ```bash
   ngrok http 3000
   ```
2. Salin URL HTTPS yang dihasilkan oleh ngrok (misalnya `https://abcd-12-34.ngrok-free.app`).
3. Tempel URL tersebut pada file `.env` sebagai `WEBHOOK_URL`.
4. Jalankan perintah `setWebhook` seperti di **Langkah 3** menggunakan URL ngrok tersebut.
