# 🔍 WhatsApp Bot Debug Checklist

## Problem: Bot tidak balas saat terima "OTP 123456"

---

## ✅ Checklist Debugging (Urutan prioritas)

### 1. Cek OpenWA Session Status ⚠️ (PALING PENTING)

**Location:** https://wa.glicoo.my.id/dashboard

**Cara cek:**

1. Login ke OpenWA panel (https://wa.glicoo.my.id)
2. Klik tab "Sessions"
3. Cari session dengan phone number +62 896-7258-5765
4. Cek status:
   - ✅ **Connected** → Session aktif, lanjut ke step 2
   - ❌ **Disconnected** → **INI MASALAHNYA!** Scan QR code lagi
   - ❌ **Not found** → Session belum dibuat, scan QR pertama kali

**Fix jika Disconnected:**

```bash
1. Buka OpenWA panel
2. Klik "Scan QR Code"
3. Buka WhatsApp di HP bot
4. Settings → Linked Devices → Link a Device
5. Scan QR code dari OpenWA panel
6. Tunggu sampai status jadi "Connected"
```

---

### 2. Cek Webhook Configuration di OpenWA Panel

**Location:** https://wa.glicoo.my.id/webhooks

**Expected Config:**

```
Session: [your-session-id]
URL: https://api.glicoo.my.id/api/v1/bot/webhook/whatsapp
Events: message
Status: Active ✅
```

**Cara cek:**

1. Login OpenWA panel
2. Tab "Webhooks"
3. Cari webhook untuk session bot
4. Verify URL: `https://api.glicoo.my.id/api/v1/bot/webhook/whatsapp`
5. Verify events: "message" ter-checklist
6. Verify status: Active (toggle ON)

**Fix jika salah:**

- Edit webhook
- Pastikan URL exact match
- Save changes
- Test webhook (ada button "Test" di panel)

---

### 3. Test Webhook Manually dari OpenWA Panel

**Location:** OpenWA dashboard → Webhooks → Test button

**Expected result:**

- Status: 200 OK
- Response: `{"ok": true}`

**Jika gagal (4xx/5xx error):**

- Cek backend Vercel logs: https://vercel.com/dashboard
- Search untuk error di endpoint `/api/v1/bot/webhook/whatsapp`
- Kemungkinan issue:
  - Backend crash
  - Database connection error
  - Prisma query error

---

### 4. Cek Vercel Backend Logs (Real-time)

**Location:** https://vercel.com/dashboard → Project glicoo-backend → Logs

**Cara debug:**

1. Buka Vercel logs
2. Filter: Function `/api/v1/bot/webhook/whatsapp`
3. Kirim "OTP 123456" ke WhatsApp bot
4. Refresh logs (real-time)

**Expected logs:**

```
[WhatsApp] OPENWA_WEBHOOK_SECRET not set, skipping signature verification
[WhatsApp] Incoming message: OTP 123456
[WhatsApp] chatId: 628xxx@c.us
[WhatsApp] Verifying token: 123456
[WhatsApp] Token valid, connecting user...
[WhatsApp] Sending success message...
```

**Jika tidak ada logs sama sekali:**
→ Webhook TIDAK ter-trigger dari OpenWA
→ Kembali ke step 1 & 2 (session/webhook config)

**Jika ada error di logs:**
→ Copy exact error message
→ Debug dari error tersebut

---

### 5. Test Backend Endpoint Manual (curl)

**Purpose:** Verify backend bisa handle webhook tanpa OpenWA

```bash
curl -X POST https://api.glicoo.my.id/api/v1/bot/webhook/whatsapp \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "from": "628123456789@c.us",
      "body": "OTP 123456",
      "timestamp": 1719678000
    }
  }'
```

**Expected response:**

```json
{ "ok": true }
```

**Jika gagal:**

- 401 Unauthorized → Signature issue (sudah kita handle, harusnya tidak terjadi)
- 500 Internal Server Error → Backend crash (cek logs)
- Timeout → Database connection issue

---

### 6. Generate Fresh OTP Token

**Kemungkinan:** Token sudah expired (10 menit)

**Cara test:**

1. Buka app mobile
2. Profile → Bot Connection
3. Generate OTP **BARU**
4. Copy token yang baru (misal: 385879)
5. Kirim "OTP 385879" ke WhatsApp bot
6. Tunggu 5 detik

**Expected:**

- Bot balas: "✅ Selamat! Akun Glicoo berhasil terhubung..."

---

### 7. Cek Database botLinkToken

**Purpose:** Verify token ter-generate dengan benar

**Query di Supabase SQL Editor:**

```sql
SELECT
  token,
  platform,
  user_id,
  expires_at,
  created_at,
  (expires_at > NOW()) as is_valid
FROM bot_link_tokens
ORDER BY created_at DESC
LIMIT 5;
```

**Expected result:**

- Token: 6 digit number (e.g., "385879")
- Platform: "WHATSAPP"
- expires_at: 10 minutes from created_at
- is_valid: true

**Jika is_valid = false:**
→ Token expired, generate ulang

---

### 8. Cek Rate Limit (OpenWA/WhatsApp)

**OpenWA Free Tier Limit:** 50 messages/hour per session

**Cara cek:**

1. OpenWA dashboard → Usage/Metrics
2. Lihat message count dalam 1 jam terakhir

**Jika hit rate limit:**

- Tunggu 1 jam
- Atau upgrade OpenWA plan

---

## 🚨 Most Common Issues (Prioritas)

### Issue #1: OpenWA Session Disconnected (80% cases)

**Symptom:** Bot tidak balas sama sekali, tidak ada error
**Solution:** Scan QR code ulang di OpenWA panel
**Prevention:** Jangan logout WhatsApp di HP bot, jangan uninstall WhatsApp

### Issue #2: Webhook URL Salah/Tidak Aktif (15% cases)

**Symptom:** Test manual curl berhasil, tapi bot real tidak balas
**Solution:** Edit webhook di OpenWA panel, pastikan URL exact match
**Prevention:** Copy-paste URL dari docs, jangan ketik manual

### Issue #3: Token Expired (5% cases)

**Symptom:** Bot balas "❌ Token tidak valid atau sudah kedaluwarsa"
**Solution:** Generate OTP baru, kirim dalam < 10 menit
**Prevention:** Kirim OTP segera setelah generate

---

## 📊 Decision Tree

```
Bot tidak balas?
├─ Cek OpenWA session status
│  ├─ Disconnected? → Scan QR code lagi ✅
│  └─ Connected? → Lanjut
├─ Cek webhook config di OpenWA
│  ├─ URL salah? → Fix URL ✅
│  ├─ Events tidak checklist? → Enable "message" event ✅
│  └─ Correct? → Lanjut
├─ Test webhook manual dari OpenWA panel
│  ├─ Error 4xx/5xx? → Cek Vercel logs ✅
│  └─ 200 OK? → Lanjut
├─ Kirim OTP ke bot, cek Vercel real-time logs
│  ├─ Tidak ada logs? → Webhook tidak ter-trigger, back to step 1-2
│  ├─ Ada error? → Debug error spesifik
│  └─ Success logs tapi bot tidak balas? → Issue di sendWhatsAppMessage()
└─ Generate fresh OTP, test lagi
```

---

## 🛠️ Quick Fix Commands

### Restart OpenWA Session (if stuck)

```bash
# Di OpenWA panel:
1. Stop session
2. Wait 10 seconds
3. Start session
4. Re-scan QR if needed
```

### Force Redeploy Backend (if code not updated)

```bash
git commit --allow-empty -m "force redeploy"
git push origin main
```

### Clear Old Tokens (if banyak expired tokens)

```sql
DELETE FROM bot_link_tokens
WHERE expires_at < NOW();
```

---

## ✅ Success Indicators

Jika semua setup benar, flow harus seperti ini:

1. User generate OTP → Backend create token di database ✅
2. User kirim "OTP 123456" ke WhatsApp bot ✅
3. OpenWA forward message ke webhook backend ✅
4. Backend verify token, update user.bot_platform = WHATSAPP ✅
5. Backend kirim success message via OpenWA API ✅
6. User terima "✅ Selamat! Akun Glicoo berhasil terhubung..." ✅

Jika step 3-6 tidak terjadi → **Session disconnected atau webhook config salah**

---

## 📝 Debug Log Template

Copy template ini untuk report issue:

```
## WhatsApp Bot Debug Report

**Date/Time:** [ISO timestamp]
**User:** [email/user_id]
**OTP Token:** [6 digit]

### OpenWA Status
- Session Status: [Connected/Disconnected]
- Webhook URL: [actual URL]
- Webhook Status: [Active/Inactive]
- Last Message Received: [timestamp]

### Backend Logs (Vercel)
```

[paste relevant logs here]

````

### Database Check
```sql
-- Token query result
[paste query result]
````

### Test Results

- [ ] OpenWA webhook test: [200 OK / Error]
- [ ] Manual curl test: [200 OK / Error]
- [ ] Real message test: [Bot balas / No response]

### Error Messages

[paste any error messages]

```

---

## 📞 Next Steps

Setelah cek checklist ini, report hasil dengan format:

```

✅ Step 1: Session Connected
✅ Step 2: Webhook configured correctly
❌ Step 3: Webhook test returns 500 error

```

Lalu saya bisa debug lebih spesifik dari situ.
```
