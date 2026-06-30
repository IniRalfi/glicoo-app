# 🐛 WhatsApp Cron Reminders Not Working - Root Cause & Fix

**Date**: 2026-06-30  
**Reporter**: Rafli Pratama  
**Status**: ✅ DIAGNOSED

---

## 📋 Problem Summary

WhatsApp tidak menerima pesan reminder terjadwal (jam 8 pagi, 3 sore, 9 malam) padahal Telegram bekerja normal.

---

## 🔍 Root Cause Analysis

### Investigation Steps

1. **✅ Checked Scheduler Code** ([`scheduler.service.ts`](../apps/backend/src/features/bot/scheduler.service.ts))
   - Code benar: menggunakan `sendMessageToUser()` yang support TELEGRAM & WHATSAPP
   - Logging lengkap sudah ditambahkan

2. **✅ Checked WhatsApp Service** ([`whatsapp.service.ts`](../apps/backend/src/features/bot/whatsapp.service.ts))
   - Function `sendWhatsAppMessage()` ada dan implementasi benar
   - Menggunakan OpenWA v0.7.11 API dengan endpoint yang tepat

3. **✅ Checked Database**
   - User **SUDAH TERDAFTAR** dengan:
     ```
     name: "Rafli Pratama"
     bot_platform: "WHATSAPP"
     bot_chat_id: "43448023433464@lid"
     ```

4. **✅ Checked Environment Variables**

   ```bash
   OPENWA_BASE_URL="https://wa.glicoo.my.id" ✅
   OPENWA_SESSION_ID="9b431dd6-0da5-46b3-ad1f-2e5b31096dfa" ✅
   OPENWA_API_KEY="..." ❌ INVALID!
   ```

5. **❌ FOUND THE BUG: API Key Test Failed**

   ```bash
   # Test manual send:
   $ bun run src/test-wa-send.ts

   Response: HTTP 401
   {"message":"Invalid API key","error":"Unauthorized","statusCode":401}
   ```

---

## 🎯 Root Cause

**`OPENWA_API_KEY` di file `.env` tidak valid atau expired!**

OpenWA server menolak semua request dengan error 401 Unauthorized.

---

## ✅ Solution

### Step 1: Get Valid API Key from OpenWA Dashboard

1. Login ke OpenWA Dashboard: https://wa.glicoo.my.id
2. Buka **Settings** → **API Keys**
3. Generate new API key atau copy existing valid key
4. Format API key harus: `owa_k1_...` (panjang 64+ karakter)

### Step 2: Update `.env` File

Edit [`apps/backend/.env`](../apps/backend/.env):

```bash
# --- CONFIG WHATSAPP BOT (OpenWA) ---
OPENWA_BASE_URL="https://wa.glicoo.my.id"
OPENWA_API_KEY="owa_k1_YOUR_ACTUAL_VALID_API_KEY_HERE"
OPENWA_SESSION_ID="9b431dd6-0da5-46b3-ad1f-2e5b31096dfa"
OPENWA_WEBHOOK_SECRET=""
```

**IMPORTANT**:

- Ganti `YOUR_ACTUAL_VALID_API_KEY_HERE` dengan API key yang valid
- API key harus **lengkap** (biasanya 64-70 karakter)
- Jangan ada spasi atau karakter tambahan

### Step 3: Restart Backend Server

```bash
# If using Vercel/Railway deployment:
git add apps/backend/.env
git commit -m "fix: update OpenWA API key"
git push

# If running locally:
cd apps/backend
bun run dev
```

### Step 4: Verify Fix

Test manual send:

```bash
cd apps/backend
bun run src/test-wa-send.ts
```

Expected output:

```
✅ Message sent successfully!
```

Test via cron endpoint (local):

```bash
curl -X GET "http://localhost:3000/bot/cron/morning" \
  -H "Authorization: Bearer YOUR_CRON_SECRET"
```

---

## 🧪 Verification Checklist

- [ ] OpenWA API key updated in `.env`
- [ ] Test script returns success (bun run src/test-wa-send.ts)
- [ ] Backend redeployed/restarted
- [ ] Manual cron trigger works
- [ ] Wait for scheduled time (8 AM, 3 PM, or 9 PM) and verify message received

---

## 📊 Technical Details

### WhatsApp User in Database

```sql
SELECT name, bot_platform, bot_chat_id
FROM users
WHERE bot_platform = 'WHATSAPP';

-- Result:
-- name: Rafli Pratama
-- bot_platform: WHATSAPP
-- bot_chat_id: 43448023433464@lid
```

### OpenWA API Endpoint

```
POST https://wa.glicoo.my.id/api/sessions/{SESSION_ID}/messages/send-text

Headers:
  Content-Type: application/json
  X-API-Key: {YOUR_API_KEY}

Body:
{
  "chatId": "43448023433464@lid",
  "text": "Your message"
}
```

### Cron Schedule (via cron-job.org)

- **8:00 AM**: `GET https://api.glicoo.my.id/bot/cron/morning`
- **3:00 PM**: `GET https://api.glicoo.my.id/bot/cron/afternoon`
- **9:00 PM**: `GET https://api.glicoo.my.id/bot/cron/evening`

All cron endpoints require header: `Authorization: Bearer {CRON_SECRET}`

---

## 🔗 Related Files

- [`apps/backend/.env`](../apps/backend/.env) - Environment config
- [`apps/backend/src/features/bot/scheduler.service.ts`](../apps/backend/src/features/bot/scheduler.service.ts) - Cron logic
- [`apps/backend/src/features/bot/whatsapp.service.ts`](../apps/backend/src/features/bot/whatsapp.service.ts) - WhatsApp send function
- [`apps/backend/src/features/bot/cron.routes.ts`](../apps/backend/src/features/bot/cron.routes.ts) - Cron HTTP endpoints
- [`docs/OPENWA_CONFIG_GUIDE.md`](./OPENWA_CONFIG_GUIDE.md) - OpenWA setup guide

---

## 📝 Notes

- Telegram bekerja normal karena menggunakan `TELEGRAM_BOT_TOKEN` yang berbeda dan valid
- Chat ID format `@lid` adalah valid untuk WhatsApp Business API (bukan `@c.us` untuk personal)
- Rate limit: 50 messages per user per hour (sudah implemented di code)

---

**Status**: Waiting for user to update API key and verify fix
