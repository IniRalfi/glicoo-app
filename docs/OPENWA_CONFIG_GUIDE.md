# 🔧 Panduan Konfigurasi OpenWA Panel

> **Untuk:** Glicoo WhatsApp Bot Integration  
> **Panel URL:** https://wa.glicoo.my.id  
> **Bot Phone:** +62 896-7258-5765

---

## 📋 Checklist Konfigurasi

- [x] OpenWA deployed di EC2
- [x] WhatsApp Session Connected
- [x] API Key tersedia
- [ ] **Webhook dikonfigurasi** ← **WAJIB untuk menerima pesan masuk**
- [ ] Backend `.env` updated dengan API Key
- [ ] Test webhook endpoint

---

## 1️⃣ Login ke Panel OpenWA

1. Buka browser → `https://wa.glicoo.my.id`
2. Login dengan kredensial admin panel (yang kamu buat waktu setup OpenWA di EC2)
3. Dashboard akan menampilkan:
   - ✅ **1 Active Session** (Status: Connected)
   - ✅ **Phone: 628967258765**
   - ❌ **0 Webhooks Configured** ← ini yang harus diisi

---

## 2️⃣ Cara Mendapatkan/Melihat API Key

### Lokasi API Key di Panel

1. **Klik sidebar menu "API Keys"** (biasanya ada icon key 🔑)
2. Akan tampil halaman dengan:
   - List of existing API Keys
   - Button "Create New API Key" atau "Generate API Key"

### API Key Format

```
owa_k1_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Prefix:** `owa_k1_` → OpenWA API Key version 1

### ⚠️ Jika API Key Hilang/Tidak Muncul

1. **Klik "Create New API Key"**
2. Beri nama: `glicoo-backend-api`
3. Copy key yang di-generate
4. **Simpan langsung** ke backend `.env` → key TIDAK bisa dilihat lagi setelah popup ditutup

---

## 3️⃣ Konfigurasi Webhook (WAJIB)

### Kenapa Webhook Diperlukan?

Tanpa webhook, backend **TIDAK BISA menerima pesan masuk** dari WhatsApp. OpenWA akan mengirim HTTP POST ke backend kamu setiap ada pesan baru.

### Langkah Konfigurasi

1. **Klik sidebar menu "Webhooks"**
2. **Klik "Create Webhook"** atau tombol "+ Add"
3. **Isi form "Create Webhook":**

#### Form Field 1: Session

**Pilih session:** `glicoo-bot`

> Session yang sudah connected dengan WhatsApp kamu (Phone: 628967258765)

---

#### Form Field 2: URL

```
https://api.glicoo.my.id/api/v1/bot/webhook/whatsapp
```

> **Catatan:**
>
> - Pastikan domain `api.glicoo.my.id` sudah pointing ke backend Elysia production
> - Endpoint ini sudah dibuat di [`bot.routes.ts`](../apps/backend/src/features/bot/bot.routes.ts) line 301-399

---

#### Form Field 3: Events

**Centang HANYA event berikut:**

- ✅ **message.received** ← **WAJIB** (untuk terima pesan masuk OTP dari user)
- ❌ message.sent (tidak perlu)
- ❌ message.ack (tidak perlu)
- ❌ message.failed (tidak perlu)
- ❌ message.revoked (tidak perlu)
- ❌ message.reaction (tidak perlu)
- ❌ session.status (tidak perlu)
- ❌ session.qr (tidak perlu)
- ❌ session.authenticated (tidak perlu)
- ❌ session.disconnected (tidak perlu)
- ❌ group.join (tidak perlu)
- ❌ group.leave (tidak perlu)
- ❌ group.update (tidak perlu)
- ❌ **\*** (wildcard — JANGAN dicentang, terlalu banyak traffic)

**Hanya centang `message.received` saja** — ini cukup untuk menerima pesan OTP dari user.

---

#### Form Field 4: Filters (optional)

**KOSONGKAN** — jangan isi apapun.

> **Kenapa kosong?**  
> Kita tidak tahu phone number user sebelumnya (user bisa chat dari nomor manapun). Jika filter diisi, hanya nomor tertentu yang bisa verifikasi OTP.

**Jangan isi:**

- ❌ Sender field
- ❌ Add condition

---

4. **Klik "Create"** untuk save webhook
5. Panel akan menampilkan **"1 Webhook Configured"** di dashboard (refresh homepage)

---

## 4️⃣ Update Backend Environment Variables

### File: `apps/backend/.env`

Tambahkan/update 3 baris ini:

```bash
# WhatsApp Bot (OpenWA)
OPENWA_BASE_URL="https://wa.glicoo.my.id"
OPENWA_API_KEY="owa_k1_xxxxx_YOUR_API_KEY_HERE"
OPENWA_WEBHOOK_SECRET=""
```

### ⚠️ Catatan Penting tentang Webhook Secret

Panel OpenWA versi kamu **TIDAK menyediakan field Webhook Secret**. Ini artinya:

- OpenWA **tidak mengirim signature verification** di webhook payload
- Backend kita **tidak bisa verify** bahwa webhook benar-benar dari OpenWA

**Solusi:**

Set `OPENWA_WEBHOOK_SECRET=""` (string kosong) di `.env` agar backend skip signature verification.

**Mitigasi Keamanan:**

1. ✅ Webhook URL (`https://api.glicoo.my.id`) sudah HTTPS
2. ✅ Endpoint tidak public-facing (hanya OpenWA yang tahu URL-nya)
3. ✅ Rate limiting (50 msg/hour per user) mencegah spam
4. ✅ OTP verification logic tetap aman (token harus valid di database)

---

### Vercel Production Environment

Jika backend deploy di Vercel:

1. Buka dashboard Vercel → pilih project `glicoo-backend`
2. Settings → Environment Variables
3. Tambahkan 3 variabel:
   - `OPENWA_BASE_URL` → `https://wa.glicoo.my.id`
   - `OPENWA_API_KEY` → `owa_k1_xxxxx_YOUR_API_KEY_HERE` (paste API key dari panel OpenWA)
   - `OPENWA_WEBHOOK_SECRET` → `""` (string kosong)
4. **Redeploy backend** agar env vars ter-apply

---

## 5️⃣ Test Webhook Endpoint

### A. Test dari Panel OpenWA

Setelah webhook dibuat, biasanya ada:

- **"Test" button** di list webhooks → klik untuk kirim test payload
- Atau **"Send Test Event"** di detail webhook

Cek response:

- ✅ **200 OK** → webhook berhasil
- ❌ **5xx / timeout** → backend belum deploy atau URL salah

---

### B. Test Manual dengan cURL

```bash
# Simulasi webhook payload dari OpenWA
curl -X POST https://api.glicoo.my.id/api/v1/bot/webhook/whatsapp \
  -H "Content-Type: application/json" \
  -d '{
    "event": "message.received",
    "session": "glicoo-bot",
    "data": {
      "from": "628123456789@c.us",
      "body": "test",
      "timestamp": 1719666000
    }
  }'
```

**Expected Response:**

```json
{
  "message": "Webhook received"
}
```

> **Catatan:** Struktur payload OpenWA bisa beda-beda tergantung versi. Cek logs backend untuk lihat payload asli yang dikirim.

---

### C. Test End-to-End (Real WhatsApp Message)

1. **Buka WhatsApp di HP kamu**
2. **Chat nomor bot:** +62 896-7258-765
3. **Kirim pesan:** `test`
4. **Cek logs backend:**

   ```bash
   # Jika pakai Vercel
   vercel logs glicoo-backend --follow

   # Jika pakai PM2 di EC2
   pm2 logs glicoo-backend
   ```

5. Harusnya ada log:
   ```
   [WhatsApp] Webhook received from: 628123456789@c.us
   [WhatsApp] Message: test
   ```

---

## 6️⃣ Verifikasi Session Status

Kembali ke dashboard OpenWA → pastikan:

- ✅ **Status: Connected** (hijau)
- ✅ **Last Active:** kurang dari 1 jam yang lalu
- ✅ **Webhooks Configured: 1** (setelah step 3)

### ⚠️ Jika Session Disconnected

1. **Scan QR Code ulang:**
   - Klik session → "Reconnect" atau "Scan QR"
   - Buka WhatsApp di HP → Settings → Linked Devices → Link a Device
   - Scan QR code yang muncul di panel
2. **Restart OpenWA service** (jika perlu):
   ```bash
   # SSH ke EC2
   sudo systemctl restart openwa
   # atau jika pakai PM2
   pm2 restart openwa
   ```

---

## 7️⃣ Testing OTP Flow (User Journey)

### Skenario: User Connect WhatsApp dari Mobile App

1. **Buka Glicoo mobile app** → Profile → Bot Hub
2. **Pilih "WhatsApp"** dari platform picker (ChoiceChip)
3. **Klik "Generate OTP"**
4. **App akan tampilkan:**

   ```
   Kode OTP: 123456

   Instruksi:
   1. Chat nomor: +62 896-7258-765
   2. Kirim pesan: OTP 123456
   ```

5. **Buka WhatsApp** → chat +62 896-7258-765
6. **Kirim pesan:** `OTP 123456`
7. **Backend akan:**
   - Verify token via webhook
   - Update user `bot_platform = 'WHATSAPP'`
   - Update user `bot_chat_id = '628123456789@c.us'`
   - Reply: "✅ Berhasil terhubung ke WhatsApp!"
8. **Refresh Profile di app** → status berubah jadi "Connected via WhatsApp"

---

## 📊 Monitoring & Troubleshooting

### Dashboard Metrics yang Perlu Dipantau

1. **Active Sessions** → harus tetap "1" (Connected)
2. **Messages Today** → akan naik setiap ada OTP verification atau reminder
3. **Webhooks Configured** → harus "1"
4. **Last Active** → harus update setiap kali ada traffic

---

### Common Issues

#### Issue 1: Webhook 404 Not Found

**Cause:** Backend belum deploy atau routing salah

**Fix:**

1. Cek backend deployment status di Vercel
2. Cek logs: `vercel logs glicoo-backend`
3. Pastikan endpoint `/api/v1/bot/webhook/whatsapp` ada di [`bot.routes.ts`](../apps/backend/src/features/bot/bot.routes.ts)

---

#### Issue 2: User kirim OTP tapi tidak ter-verify

**Cause:** Webhook tidak diterima backend atau token expired

**Fix:**

1. Cek logs backend untuk incoming webhook
2. Cek `bot_link_tokens` table di database → pastikan token belum expired (valid 5 menit)
3. Generate OTP baru dan coba lagi

---

#### Issue 3: Rate Limit Hit (50 messages/hour)

**Cause:** User spam messages

**Fix:**

1. Cek logs: `[WhatsApp] Rate limit exceeded for 628xxx@c.us`
2. Wait 1 hour atau reset manual di code [`whatsapp.service.ts`](../apps/backend/src/features/bot/whatsapp.service.ts) line 32-47

---

#### Issue 4: Session Disconnected

**Cause:** WhatsApp Web session expired atau device not connected

**Fix:**

1. Scan QR code ulang di panel OpenWA
2. Pastikan HP dengan WhatsApp primary terhubung internet
3. Restart OpenWA service jika perlu

---

## 🔒 Security Checklist

- [x] API Key disimpan di `.env` (tidak di-commit ke git)
- [x] HTTPS enabled untuk webhook URL (`https://api.glicoo.my.id`)
- [x] Webhook endpoint hanya accept POST method
- [x] Rate limiting enabled (50 msg/hour per user)
- [ ] ⚠️ Signature verification **disabled** (karena OpenWA tidak kirim signature)
  - **Mitigasi:** Webhook URL tidak public, hanya diketahui OpenWA
  - **Mitigasi:** Rate limiting mencegah spam
  - **Mitigasi:** OTP logic tetap verify di database
- [ ] Monitoring alerts untuk session disconnect
- [ ] Backup session data OpenWA (jika ada)

---

## 📚 References

- **OpenWA Docs:** https://docs.open-wa.org
- **Webhook Signature Verification Code:** [`whatsapp.service.ts`](../apps/backend/src/features/bot/whatsapp.service.ts) line 139-158 (disabled jika OPENWA_WEBHOOK_SECRET kosong)
- **Webhook Endpoint Handler:** [`bot.routes.ts`](../apps/backend/src/features/bot/bot.routes.ts) line 301-399
- **Integration Plan:** [`WHATSAPP_INTEGRATION_PLAN.md`](./WHATSAPP_INTEGRATION_PLAN.md)

---

## ✅ Next Steps After Configuration

1. ✅ Webhook configured di OpenWA panel (hanya centang `message.received`)
2. ✅ Backend `.env` updated dengan API Key (OPENWA_WEBHOOK_SECRET = "")
3. ✅ Backend deployed dengan env vars baru
4. 🔄 **Test OTP flow** (step 7)
5. 🔄 **Test exclusive connection** (user coba connect Telegram setelah WhatsApp)
6. 🔄 **Test scheduled reminders** (morning/afternoon/evening)
7. 📝 Update [`CHANGELOG.md`](../CHANGELOG.md) dengan release notes WhatsApp Integration
8. 🚀 Release v1.1.0 (WhatsApp Integration)

---

## 🎯 Summary untuk Kamu

### Yang Perlu Kamu Lakukan Sekarang:

1. **Buka panel OpenWA** → `https://wa.glicoo.my.id`
2. **Klik Webhooks** → "Create Webhook"
3. **Isi form:**
   - Session: `glicoo-bot`
   - URL: `https://api.glicoo.my.id/api/v1/bot/webhook/whatsapp`
   - Events: **HANYA centang `message.received`**
   - Filters: **KOSONGKAN**
4. **Klik "Create"**
5. **Update backend `.env`:**
   ```bash
   OPENWA_BASE_URL="https://wa.glicoo.my.id"
   OPENWA_API_KEY="owa_k1_xxxxx_YOUR_API_KEY_HERE"
   OPENWA_WEBHOOK_SECRET=""
   ```
6. **Deploy backend** dengan env vars baru (Vercel redeploy)
7. **Test:** Chat +62 896-7258-765 dari WhatsApp → kirim "test" → cek logs backend

---

**Last Updated:** 2026-06-29  
**Status:** ✅ Ready for Configuration
