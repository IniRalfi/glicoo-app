# 📱 WhatsApp Integration — Execution Plan

## 🎯 Tujuan

Menambahkan WhatsApp sebagai platform bot kedua (selain Telegram) dengan constraint **exclusive connection** — user hanya bisa connect ke SATU platform (Telegram ATAU WhatsApp) dalam satu waktu.

---

## 📊 Current State Analysis

### ✅ Infrastructure (Already Done by User)

- **OpenWA API** deployed di Amazon EC2
- **Nginx** configured untuk port forwarding
- **Domain**: `wa.glicoo.my.id` (dashboard accessible)
- **WhatsApp connection**: Already connected

### 🔍 Backend Current State

**Database Schema:**

```prisma
model User {
  phone_number String? @db.VarChar(255)
  // ^ Currently stores Telegram chat_id (e.g., "123456789")
  // No platform differentiation exists
}

model BotLinkToken {
  token String @unique @db.VarChar(6)
  // ^ Used for OTP verification
}
```

**Bot Service (`apps/backend/src/features/bot/bot.service.ts`):**

- ✅ `sendTelegramMessage()` — sends via Telegram API
- ✅ `sendChatAction()` — Telegram typing indicator
- ✅ `handleTelegramWebhook()` — processes Telegram updates
- ❌ No WhatsApp methods exist

**Bot Routes (`apps/backend/src/features/bot/bot.routes.ts`):**

- `GET /api/v1/bot/link` — generates 6-digit OTP
- `POST /api/v1/bot/verify` — verifies token, stores chat identifier
- `DELETE /api/v1/bot/disconnect` — sets phone_number to null
- `POST /api/v1/bot/webhook` — handles Telegram webhooks only

**Scheduler Service (`apps/backend/src/features/bot/scheduler.service.ts`):**

- Uses `sendTelegramMessage()` for ALL users with `phone_number !== null`
- No platform routing logic

### 🔍 Mobile Current State

**Profile Screen (`apps/mobile/lib/features/profile/profile_screen.dart`):**

- Line 1858: UI text already mentions "WhatsApp atau Telegram"
- `_generateOtp()` method generates OTP via `GET /api/v1/bot/link`
- `_disconnectBot()` method calls `DELETE /api/v1/bot/disconnect`
- `_isBotConnected` boolean state (doesn't track platform)
- No platform selection UI exists

---

## 🏗️ Architectural Changes Needed

### 1. Database Schema Updates

**Problem:**

- Single `phone_number` field stores chat identifier without platform context
- Cannot differentiate Telegram vs WhatsApp users
- Cannot enforce exclusive connection

**Solution:**

```prisma
model User {
  phone_number  String?   @db.VarChar(255)  // Keep for backward compat
  bot_platform  BotPlatform?                // NEW: track which platform
  bot_chat_id   String?   @db.VarChar(255)  // NEW: standardized identifier
}

enum BotPlatform {
  TELEGRAM
  WHATSAPP
}

model BotLinkToken {
  token       String      @unique @db.VarChar(6)
  user_id     String
  platform    BotPlatform                      // NEW: target platform
  created_at  DateTime    @default(now())
}
```

**Migration Strategy:**

1. Add `bot_platform` enum to schema
2. Add `bot_chat_id` field (nullable)
3. Migrate existing users: if `phone_number !== null` → set `bot_platform = TELEGRAM`, `bot_chat_id = phone_number`
4. Mark `phone_number` as deprecated (keep for 1-2 releases for backward compat)

### 2. Backend Service Layer

**New: WhatsApp Service (`apps/backend/src/features/bot/whatsapp.service.ts`)**

```typescript
/**
 * [ID] Service untuk mengirim pesan via OpenWA
 * [EN] Service for sending messages via OpenWA
 */
export class WhatsAppService {
  private baseUrl = process.env.OPENWA_BASE_URL; // wa.glicoo.my.id
  private apiKey = process.env.OPENWA_API_KEY;

  async sendMessage(chatId: string, message: string): Promise<boolean> {
    // POST to OpenWA API: /api/sendText
    // Body: { chatId: "628123456789@c.us", content: message }
  }

  async sendTypingIndicator(chatId: string): Promise<void> {
    // POST to OpenWA API: /api/startTyping
  }

  async handleWebhook(body: any): Promise<void> {
    // Handle incoming messages from OpenWA webhook
    // Parse: message.from, message.body
  }

  formatChatId(phoneNumber: string): string {
    // Convert "628123456789" → "628123456789@c.us"
  }

  extractPhoneNumber(chatId: string): string {
    // Convert "628123456789@c.us" → "628123456789"
  }
}
```

**Update: Bot Service (`apps/backend/src/features/bot/bot.service.ts`)**

Add platform routing logic:

```typescript
async sendMessage(userId: string, message: string): Promise<boolean> {
  const user = await db.user.findUnique({ where: { id: userId } });

  if (!user.bot_platform || !user.bot_chat_id) {
    throw new Error('User not connected to any bot platform');
  }

  if (user.bot_platform === 'TELEGRAM') {
    return this.sendTelegramMessage(user.bot_chat_id, message);
  } else {
    return this.whatsappService.sendMessage(user.bot_chat_id, message);
  }
}
```

### 3. API Endpoints Updates

**Update: `GET /api/v1/bot/link`**

Add `platform` query parameter:

```typescript
.get(
  '/link',
  async ({ userId, query, set }) => {
    const platform = query.platform as 'telegram' | 'whatsapp';

    if (!['telegram', 'whatsapp'].includes(platform)) {
      set.status = 400;
      return { error: 'Invalid platform. Must be telegram or whatsapp' };
    }

    // Check if user already connected to DIFFERENT platform
    const user = await db.user.findUnique({ where: { id: userId } });
    if (user.bot_platform && user.bot_platform.toLowerCase() !== platform) {
      set.status = 409;
      return {
        error: 'Already connected to another platform',
        connectedPlatform: user.bot_platform,
        message: 'Please disconnect first before connecting to a different platform'
      };
    }

    const token = generateSixDigitToken();

    await db.botLinkToken.create({
      data: {
        token,
        user_id: userId,
        platform: platform.toUpperCase(),
        created_at: new Date(),
      }
    });

    return {
      token,
      platform,
      instructions: platform === 'telegram'
        ? `Kirim /start ${token} ke bot Telegram @GlicooBot`
        : `Kirim pesan "OTP ${token}" ke WhatsApp +62 XXX-XXXX-XXXX`
    };
  }
)
```

**New: `POST /api/v1/bot/webhook/whatsapp`**

Handle OpenWA incoming messages:

```typescript
.post(
  '/webhook/whatsapp',
  async ({ body, headers, set }) => {
    // Verify OpenWA signature
    const signature = headers['x-openwa-signature'];
    if (!verifyOpenWASignature(signature, body)) {
      set.status = 401;
      return { error: 'Invalid signature' };
    }

    const { from, body: messageBody } = body.message;
    const phoneNumber = extractPhoneNumber(from); // "628123456789@c.us" → "628123456789"

    // Check if this is OTP verification
    const otpMatch = messageBody.match(/^OTP (\d{6})$/i);
    if (otpMatch) {
      const token = otpMatch[1];

      const linkToken = await db.botLinkToken.findUnique({
        where: { token },
        include: { user: true }
      });

      if (!linkToken) {
        await whatsappService.sendMessage(from, '❌ Token tidak valid atau sudah expired.');
        return { ok: true };
      }

      if (linkToken.platform !== 'WHATSAPP') {
        await whatsappService.sendMessage(from, '❌ Token ini untuk Telegram, bukan WhatsApp.');
        return { ok: true };
      }

      // Save chat_id to user
      await db.user.update({
        where: { id: linkToken.user_id },
        data: {
          bot_platform: 'WHATSAPP',
          bot_chat_id: from,
          phone_number: phoneNumber, // backward compat
        }
      });

      await db.botLinkToken.delete({ where: { token } });

      await whatsappService.sendMessage(
        from,
        '✅ Berhasil terhubung dengan Glicoo!\n\nKamu akan menerima reminder & tips kesehatan di sini.'
      );

      return { ok: true };
    }

    // Handle regular chat messages (future: integrate with AI Agent)
    return { ok: true };
  }
)
```

**Update: `POST /api/v1/bot/verify`**

Add platform validation:

```typescript
// Existing Telegram verification logic
// Add: check if token.platform matches expected platform
```

**Update: `DELETE /api/v1/bot/disconnect`**

Return which platform was disconnected:

```typescript
.delete(
  '/disconnect',
  async ({ userId, set }) => {
    const user = await db.user.findUnique({ where: { id: userId } });

    if (!user.bot_platform) {
      set.status = 400;
      return { error: 'No bot connected' };
    }

    const disconnectedPlatform = user.bot_platform;

    await db.user.update({
      where: { id: userId },
      data: {
        bot_platform: null,
        bot_chat_id: null,
        phone_number: null,
      }
    });

    return {
      success: true,
      message: `Disconnected from ${disconnectedPlatform}`,
      platform: disconnectedPlatform
    };
  }
)
```

### 4. Scheduler Service Updates

**Update: `apps/backend/src/features/bot/scheduler.service.ts`**

Route scheduled messages based on platform:

```typescript
async sendScheduledReminders() {
  const users = await db.user.findMany({
    where: {
      bot_platform: { not: null },
      bot_chat_id: { not: null }
    }
  });

  for (const user of users) {
    const message = generateReminderMessage(user);

    if (user.bot_platform === 'TELEGRAM') {
      await this.botService.sendTelegramMessage(user.bot_chat_id, message);
    } else if (user.bot_platform === 'WHATSAPP') {
      await this.whatsappService.sendMessage(user.bot_chat_id, message);
    }
  }
}
```

---

## 📱 Mobile App Changes

### 1. Profile Screen UI Updates

**File: `apps/mobile/lib/features/profile/profile_screen.dart`**

**Changes around line 1800-1896 (Bot Integration Section):**

```dart
// NEW: Add state variables
String? _connectedPlatform; // 'telegram' | 'whatsapp' | null
String _selectedPlatform = 'telegram'; // for platform picker

// UPDATE: _fetchProfile() method
Future<void> _fetchProfile() async {
  // ... existing code ...

  setState(() {
    _connectedPlatform = userData['bot_platform']?.toString().toLowerCase();
    _isBotConnected = _connectedPlatform != null;
  });
}

// UPDATE: _generateOtp() method
Future<void> _generateOtp() async {
  try {
    setState(() => _isOtpLoading = true);

    // ADD: platform query parameter
    final response = await ApiService.getWithAuth(
      '/api/v1/bot/link?platform=$_selectedPlatform'
    );

    if (response.statusCode == 409) {
      // User already connected to different platform
      final data = jsonDecode(response.body);
      _showErrorDialog(
        'Sudah Terhubung',
        'Kamu sudah terhubung ke ${data['connectedPlatform']}. '
        'Putuskan koneksi terlebih dahulu jika ingin beralih platform.'
      );
      return;
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _generatedOtp = data['token'];
        _otpPlatform = data['platform'];
      });
    }
  } catch (e) {
    _showErrorDialog('Error', e.toString());
  } finally {
    setState(() => _isOtpLoading = false);
  }
}

// UPDATE: Bot Integration UI
Widget _buildBotIntegration() {
  return BentoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🤖 Asisten Bot', style: AppTypography.h3),
        SizedBox(height: 12),

        if (!_isBotConnected) ...[
          // Platform Picker
          Text('Pilih Platform:', style: AppTypography.bodySmall),
          SizedBox(height: 8),
          Row(
            children: [
              _buildPlatformChip('telegram', 'Telegram', Icons.telegram),
              SizedBox(width: 8),
              _buildPlatformChip('whatsapp', 'WhatsApp', Icons.chat),
            ],
          ),
          SizedBox(height: 16),
        ],

        if (_isBotConnected) ...[
          // Show connected platform
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _connectedPlatform == 'telegram'
                    ? Icons.telegram
                    : Icons.chat,
                  color: AppColors.success,
                ),
                SizedBox(width: 8),
                Text(
                  'Terhubung ke ${_connectedPlatform == "telegram" ? "Telegram" : "WhatsApp"}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.success
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
        ],

        // ... existing OTP generation logic ...

        if (_generatedOtp != null) ...[
          Text(
            _otpPlatform == 'telegram'
              ? 'Kirim /start $_generatedOtp ke @GlicooBot'
              : 'Kirim "OTP $_generatedOtp" ke WhatsApp Bot',
            style: AppTypography.bodySmall
          ),
        ],
      ],
    ),
  );
}

Widget _buildPlatformChip(String platform, String label, IconData icon) {
  final isSelected = _selectedPlatform == platform;

  return Expanded(
    child: InkWell(
      onTap: () => setState(() => _selectedPlatform = platform),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected ? AppColors.primary : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

### 2. API Service Types

**File: `apps/mobile/lib/core/api_service.dart`**

No changes needed — existing `getWithAuth` and `deleteWithAuth` methods already support query parameters and proper headers.

---

## 🧪 Testing Strategy

### Backend Tests

**1. Unit Tests (`apps/backend/src/features/bot/bot.service.test.ts`)**

```typescript
describe("BotService", () => {
  it("should route message to Telegram for TELEGRAM platform", async () => {
    // Mock user with bot_platform: TELEGRAM
    // Assert sendTelegramMessage called
  });

  it("should route message to WhatsApp for WHATSAPP platform", async () => {
    // Mock user with bot_platform: WHATSAPP
    // Assert whatsappService.sendMessage called
  });

  it("should throw error if user not connected to any platform", async () => {
    // Mock user with bot_platform: null
    // Assert error thrown
  });
});
```

**2. Integration Tests (Manual via cURL)**

```bash
# Generate OTP for Telegram
curl -X GET "http://localhost:3000/api/v1/bot/link?platform=telegram" \
  -H "Authorization: Bearer $TOKEN"

# Try to generate OTP for WhatsApp while already connected to Telegram
curl -X GET "http://localhost:3000/api/v1/bot/link?platform=whatsapp" \
  -H "Authorization: Bearer $TOKEN"
# Expected: 409 Conflict with message about existing connection

# Disconnect bot
curl -X DELETE "http://localhost:3000/api/v1/bot/disconnect" \
  -H "Authorization: Bearer $TOKEN"

# Now generate OTP for WhatsApp
curl -X GET "http://localhost:3000/api/v1/bot/link?platform=whatsapp" \
  -H "Authorization: Bearer $TOKEN"
```

**3. Webhook Tests**

```bash
# Test WhatsApp webhook (simulate OpenWA payload)
curl -X POST "http://localhost:3000/api/v1/bot/webhook/whatsapp" \
  -H "Content-Type: application/json" \
  -H "X-OpenWA-Signature: $SIGNATURE" \
  -d '{
    "message": {
      "from": "628123456789@c.us",
      "body": "OTP 123456"
    }
  }'
```

### Mobile Tests

**1. Manual Test Checklist**

- [ ] User belum connect → tampil platform picker (Telegram & WhatsApp)
- [ ] User pilih Telegram → generate OTP → OTP muncul dengan instruksi Telegram
- [ ] User connect via Telegram → UI update jadi "Terhubung ke Telegram"
- [ ] User disconnect → confirm dialog → berhasil disconnect → UI reset ke platform picker
- [ ] User pilih WhatsApp → generate OTP → OTP muncul dengan instruksi WhatsApp
- [ ] User sudah connect Telegram, coba connect WhatsApp → error dialog "Sudah terhubung ke Telegram"
- [ ] User disconnect Telegram → lalu connect WhatsApp → berhasil
- [ ] Scheduled reminder dikirim ke platform yang benar (Telegram user dapat di Telegram, WhatsApp user dapat di WhatsApp)

**2. Edge Cases**

- [ ] OTP expired (>5 menit) → coba verifikasi → error
- [ ] User kirim OTP Telegram ke WhatsApp bot → error message platform mismatch
- [ ] User connect → logout → login lagi → status connected masih preserved
- [ ] OpenWA webhook down → scheduled message gagal → log error, jangan crash
- [ ] Telegram webhook down → scheduled message gagal → log error, jangan crash

---

## 🔐 Security Considerations

### 1. OpenWA Webhook Signature Verification

**Problem:** Webhook dari OpenWA harus diverifikasi untuk mencegah request palsu.

**Solution:**

```typescript
function verifyOpenWASignature(signature: string, body: any): boolean {
  const secret = process.env.OPENWA_WEBHOOK_SECRET;
  const hash = crypto.createHmac("sha256", secret).update(JSON.stringify(body)).digest("hex");

  return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(hash));
}
```

### 2. Rate Limiting

Add rate limit untuk OTP generation:

```typescript
// Max 3 OTP requests per 5 minutes per user
const rateLimiter = new RateLimiter({
  windowMs: 5 * 60 * 1000,
  max: 3,
  keyGenerator: (req) => req.userId,
});
```

### 3. Phone Number Privacy

- Jangan expose full phone number di API response
- Log phone numbers dengan masking: `6281234****89`

---

## 📦 Environment Variables

**New Variables Needed:**

```env
# apps/backend/.env
OPENWA_BASE_URL=https://wa.glicoo.my.id
OPENWA_API_KEY=xxx
OPENWA_WEBHOOK_SECRET=xxx
WHATSAPP_BOT_NUMBER=+62xxx  # For display in mobile UI
```

---

## 📅 Implementation Phases

### Phase 1: Database Migration ✅ (1 hari)

- [ ] Create Prisma migration for `bot_platform` enum + `bot_chat_id` field
- [ ] Run migration on dev database
- [ ] Migrate existing Telegram users (set `bot_platform = TELEGRAM`)
- [ ] Test backward compatibility with existing `phone_number` field

### Phase 2: Backend WhatsApp Service ✅ (2 hari)

- [ ] Create `whatsapp.service.ts` dengan methods sendMessage, handleWebhook
- [ ] Update `bot.service.ts` untuk routing platform
- [ ] Add OpenWA webhook signature verification
- [ ] Unit tests untuk WhatsAppService

### Phase 3: API Endpoints ✅ (2 hari)

- [ ] Update `GET /bot/link` dengan query parameter `platform`
- [ ] Add conflict check (409 jika sudah connect platform lain)
- [ ] Create `POST /bot/webhook/whatsapp` endpoint
- [ ] Update `DELETE /bot/disconnect` return connected platform
- [ ] Integration tests via cURL

### Phase 4: Scheduler Update ✅ (1 hari)

- [ ] Update `scheduler.service.ts` untuk routing berdasarkan `bot_platform`
- [ ] Test scheduled reminders dikirim ke platform yang benar
- [ ] Add error handling untuk webhook down

### Phase 5: Mobile UI ✅ (2 hari)

- [ ] Update profile_screen.dart dengan platform picker
- [ ] Update `_generateOtp()` dengan query parameter platform
- [ ] Update UI untuk show connected platform
- [ ] Add error handling untuk 409 conflict
- [ ] Manual testing semua user flows

### Phase 6: Testing & Bug Fix ✅ (2 hari)

- [ ] Manual test checklist lengkap
- [ ] Edge cases testing
- [ ] Bug fixing dari testing
- [ ] Update dokumentasi API_CONTRACTS.md

### Phase 7: Deployment ✅ (1 hari)

- [ ] Add environment variables ke Vercel
- [ ] Deploy backend (auto-trigger dari git push)
- [ ] Configure OpenWA webhook URL: `https://api.glicoo.my.id/api/v1/bot/webhook/whatsapp`
- [ ] Test production webhook
- [ ] Build & release mobile APK v1.1.0

**Total Estimasi: 11 hari kerja (~2 minggu)**

---

## ⚠️ Risks & Mitigations

| Risk                                           | Impact | Mitigation                                                   |
| ---------------------------------------------- | ------ | ------------------------------------------------------------ |
| OpenWA API unstable                            | HIGH   | Add retry logic + fallback notification via Telegram         |
| WhatsApp number banned                         | HIGH   | Follow WhatsApp Business API guidelines, rate limit messages |
| User connects to both platforms simultaneously | MEDIUM | Database constraint + UI validation                          |
| Migration breaks existing Telegram users       | HIGH   | Thorough testing + rollback plan                             |
| OpenWA webhook signature mismatch              | MEDIUM | Log mismatches for debugging, don't fail silently            |

---

## 🔄 Rollback Plan

Jika terjadi critical bug di production:

1. **Revert Git Commit:**

   ```bash
   git revert <commit-hash>
   git push origin main
   ```

2. **Rollback Database Migration:**

   ```bash
   cd apps/backend
   bun prisma migrate down
   ```

3. **Emergency Hotfix:**
   - Set `FEATURE_FLAG_WHATSAPP=false` di environment variables
   - Add feature flag check di semua WhatsApp-related endpoints
   - Deploy hotfix

4. **Communication:**
   - Notify users via in-app notification
   - Disable WhatsApp option di mobile UI (fallback to Telegram only)

---

## 📝 Documentation Updates

Files yang perlu diupdate setelah implementation:

- [ ] `docs/API_CONTRACTS.md` — tambahkan WhatsApp endpoints
- [ ] `docs/DATABASE_SCHEMA.md` — update User model dengan `bot_platform` & `bot_chat_id`
- [ ] `docs/TELEGRAM_BOT_GUIDE.md` — rename jadi `BOT_INTEGRATION_GUIDE.md`, tambahkan WhatsApp section
- [ ] `CHANGELOG.md` — entry untuk v1.1.0 dengan WhatsApp feature
- [ ] `README.md` — update feature list mention WhatsApp support

---

## ✅ Definition of Done

Feature dianggap selesai ketika:

- [x] Database migration success di dev & staging
- [x] Backend API endpoints semua pass integration tests
- [x] Scheduler dapat route message ke platform yang benar
- [x] Mobile UI dapat pilih platform & enforce exclusive connection
- [x] Manual testing checklist 100% pass
- [x] Documentation updated
- [x] Deployed to production tanpa breaking existing users
- [x] Monitoring: track message delivery rate per platform
- [x] User dapat send & receive messages di WhatsApp
- [x] Scheduled reminders delivered di platform yang dipilih user

---

## 🤔 Open Questions → ✅ ANSWERED

1. **WhatsApp Bot Number:** ✅ Sesuai jumlah user (akan ditampilkan di mobile UI dari backend config)
2. **OpenWA API Key:** ✅ Disimpan di `OPENWA_API_KEY` env var backend
3. **Message Format:** ✅ Cek dokumentasi OpenWA: https://docs.open-wa.org/plugins/overview/
4. **Rate Limits:** ✅ No hard limit from OpenWA, akan implement rate limiting di backend (max 50 messages/user/hour untuk safety)
5. **Analytics:** ✅ YES - track platform distribution untuk insights

---

**Next Steps:**

1. User confirm questions di atas
2. Mulai Phase 1 (Database Migration)
3. Setup OpenWA API credentials di backend .env
