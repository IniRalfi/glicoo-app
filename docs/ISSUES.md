# 🐛 ISSUES & BUG TRACKING

> **Status:** ✅ All Issues Resolved
> **Last Updated:** 2026-06-29

---

## 📋 DAFTAR ISSUE

| #   | Issue                                                 | Severity | Status   | Implementation                   |
| --- | ----------------------------------------------------- | -------- | -------- | -------------------------------- |
| 1   | Loading sedikit pas setelah login                     | Low      | ✅ FIXED | Cache via SharedPreferences      |
| 2   | Tutorial muncul 2x padahal udah dilewati              | High     | ✅ FIXED | Removed duplicate listener       |
| 3   | Image hasil findrisc ga muncul                        | High     | ✅ FIXED | Fixed asset path                 |
| 4   | Aktivitas ga jalan                                    | Critical | ✅ FIXED | Refactor polling → push pattern  |
| 5   | Redirect delay setelah registrasi Google              | Medium   | ✅ FIXED | Added loading overlay            |
| 6   | Pop up asisten muncul 2x setelah findrisc             | High     | ✅ FIXED | Simplified dialog flow           |
| 7   | Pencapaian misi menunjukkan 20/100 saat login pertama | Medium   | ✅ FIXED | Removed dummy data               |
| 8   | Umur di profil langsung diset 30 tahun                | Critical | ✅ FIXED | Numeric age input + auto-calc    |
| 9   | Format pesan Telegram untuk link bot salah            | Medium   | ✅ FIXED | Updated welcome message          |
| 10  | Default FINDRISC score membingungkan (13 vs 0)        | Critical | ✅ FIXED | Changed default to 0/"Belum Tes" |
| 11  | Style "Risiko Saat Ini" berbeda di Home vs Profile    | Medium   | ✅ FIXED | Unified badge style with colors  |
| 12  | Challenge card styling & pop-up untuk food logging    | Medium   | ✅ FIXED | Updated color & icon to purple   |

---

## 🔍 ANALISIS DETAIL & ROOT CAUSE

### **Issue #1: Loading Setelah Login**

**Lokasi:** [`apps/mobile/lib/main.dart`](apps/mobile/lib/main.dart:169-196)

**Root Cause:**

- Setelah splash selesai, kode melakukan **async check** untuk FINDRISC status dengan memanggil backend API (`_checkFindriscDone()`)
- Request API ke backend membutuhkan waktu (network latency)

**Kode Bermasalah:**

```dart
// Line 184-189 di main.dart
final findriscDone = await _checkFindriscDone(); // Async API call
_authHandled = true;
if (!mounted) return;
setState(() {
  _state = findriscDone ? _FlowState.home : _FlowState.findriscIntro;
});
```

**Solusi:**

1. Tambahkan loading indicator saat cek findrisc
2. Cache hasil findrisc_done di SharedPreferences untuk cek pertama (hindari API call jika sudah ada)
3. Background sync untuk update status terbaru

**Priority:** Low (UX improvement)

---

### **Issue #2: Tutorial Muncul 2x**

**Lokasi:** [`apps/mobile/lib/features/home/home_screen.dart`](apps/mobile/lib/features/home/home_screen.dart:35-58)

**Root Cause:**
Ada **DOUBLE LISTENER** yang sama-sama men-trigger tutorial dialog:

1. **Listener #1** (line 35-46): Listen ke `tutorialSeenProvider` → trigger dialog
2. **Listener #2** (line 49-58): Listen ke `bottomNavIndexProvider` → trigger dialog lagi

Keduanya berjalan saat user pertama kali masuk home screen, menyebabkan dialog muncul 2x.

**Kode Bermasalah:**

```dart
// Listener pertama
ref.listen<AsyncValue<bool>>(tutorialSeenProvider, (prev, next) {
  // ... trigger dialog
});

// Listener kedua (REDUNDANT)
ref.listen<int>(bottomNavIndexProvider, (prev, next) {
  if (next == 0) {
    // ... trigger dialog LAGI
  }
});
```

**Solusi:**

1. **Hapus listener kedua** (bottomNavIndexProvider) karena redundan
2. Atau gunakan flag `IlooTutorialDialog.isShowing` yang lebih ketat untuk prevent double show

**Priority:** High

---

### **Issue #3: Image Hasil FINDRISC Tidak Muncul**

**Lokasi:** [`apps/mobile/lib/features/findrisc/findrisc_result_screen.dart`](apps/mobile/lib/features/findrisc/findrisc_result_screen.dart:71-77)

**Root Cause:**
File SVG yang dipanggil **TIDAK ADA** di direktori assets!

**Kode Bermasalah:**

```dart
SvgPicture.asset(
  'assets/images/findrisc/glicoo_result.svg', // ❌ FILE TIDAK ADA
  width: 160,
  height: 168,
  fit: BoxFit.contain,
)
```

**File Assets yang Ada:**

```
assets/images/findrisc/
├── glicoo_end.svg          ✅
├── glicoo_findrisc.svg     ✅
├── rendah.svg              ✅
├── sangat-tinggi.svg       ✅
├── sedang.svg              ✅
├── sedikit-meningkat.svg   ✅
├── tinggi.svg              ✅
```

**File yang HILANG:**

- ❌ `glicoo_result.svg`

**Solusi:**

1. **Rename/Replace:** Ganti path ke `glicoo_end.svg` (yang ada)
2. **Atau:** Tambahkan file `glicoo_result.svg` ke assets (jika memang berbeda)

**Priority:** High

---

### **Issue #4: Aktivitas Tidak Jalan**

**Lokasi:** [`apps/mobile/lib/features/home/providers/activity_provider.dart`](apps/mobile/lib/features/home/providers/activity_provider.dart:156-158)

**Root Cause:**
Timer polling terlalu **CEPAT** dan **TIDAK EFISIEN**:

```dart
void _startTimer() {
  _timer = Timer.periodic(const Duration(seconds: 2), (_) => loadDailyValues());
}
```

**Masalah:**

1. Polling setiap 2 detik → battery drain
2. `loadDailyValues()` membaca SharedPreferences setiap kali → expensive operation
3. Tidak ada mekanisme untuk **real-time update** dari sensor service

**Dampak:**

- Data aktivitas (langkah kaki, screen time) tidak ter-update secara real-time
- Sensor service menulis ke SharedPreferences tapi UI tidak refresh dengan benar

**Solusi:**

1. **Gunakan StateNotifier method** untuk update state langsung dari sensor service (push model, bukan polling)
2. **Increase polling interval** menjadi 10-15 detik (jika tetap pakai polling)
3. **Implement listener pattern:** Sensor service notify activity provider saat ada perubahan data

**Priority:** Critical

---

### **Issue #5: Redirect Delay Setelah Registrasi Google**

**Lokasi:** [`apps/mobile/lib/main.dart`](apps/mobile/lib/main.dart:495-524)

**Root Cause:**
Flow autentikasi menggunakan **auth stream listener** yang membutuhkan waktu untuk propagate state change dari Supabase:

```dart
ref.listen<AuthState>(authProvider, (prev, next) {
  final isAuthenticated = next.maybeWhen(
    authenticated: (_) => true,
    orElse: () => false,
  );

  if (isAuthenticated && !_authHandled && _state == _FlowState.auth) {
    // Delay di sini karena menunggu stream emit state baru
  }
});
```

**Timeline:**

1. User klik Google Sign In
2. Supabase OAuth flow (redirect ke Google → kembali ke app)
3. Auth state berubah di background
4. Stream listener menangkap perubahan → setState
5. **Delay terlihat:** User melihat form login beberapa detik sebelum redirect ke FINDRISC

**Solusi:**

1. Tampilkan **loading overlay** segera setelah OAuth success (sebelum waiting stream)
2. Gunakan `authProvider.notifier.checkAuthStatus()` secara explicit setelah OAuth redirect
3. Skip form login screen jika token OAuth sudah ada (direct check)

**Priority:** Medium (UX improvement)

---

### **Issue #6: Pop Up Asisten Muncul 2x Setelah FINDRISC**

**Lokasi:** [`apps/mobile/lib/features/home/widgets/iloo_tutorial_dialog.dart`](apps/mobile/lib/features/home/widgets/iloo_tutorial_dialog.dart:115-167)

**Root Cause:**
User menekan tombol **"Nanti Saja"** (step 2) → dialog seharusnya **langsung tutup**, tapi malah menuju **step 3** dulu baru tutup.

**Flow Saat Ini:**

```dart
// Step 2 - Button "Nanti Saja"
OutlinedButton(
  onPressed: () => _completeTutorial(false), // ❌ Langsung complete
  child: Text('Nanti Saja'),
)

// Tapi di _completeTutorial:
Future<void> _completeTutorial(bool enableAi) async {
  await prefs.setBool('tutorial_iloo_done', true);
  // ... tidak langsung pop, masih di dalam dialog
}
```

**Masalah:**

- State `_step` tidak langsung ke step 3, tapi logic `_completeTutorial` tidak `pop()` dengan cepat
- Ada race condition antara `ref.invalidate` dan `Navigator.pop`
- Dialog muncul 2x karena flag `tutorial_iloo_done` belum ter-set dengan benar sebelum listener check

**Solusi:**

1. **Langsung pop dialog** saat "Nanti Saja" tanpa pindah step
2. **Set flag sebelum pop:**

```dart
OutlinedButton(
  onPressed: () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_iloo_done', true);
    ref.invalidate(tutorialSeenProvider);
    if (mounted) Navigator.of(context).pop();
  },
  child: Text('Nanti Saja'),
)
```

**Priority:** High

---

### **Issue #7: Pencapaian Misi 20/100 Saat Login Pertama**

**Lokasi:** [`apps/mobile/lib/features/home/providers/activity_provider.dart`](apps/mobile/lib/features/home/providers/activity_provider.dart:45-58)

**Root Cause:**
**Hardcoded dummy data** di constructor sebagai default value:

```dart
ActivityDataNotifier() : super(const ActivityData(
  steps: 0,
  stepsGoal: 5000,
  sleepMinutes: 0,
  screenTimeMinutes: 0,
  dailyCalories: 0,
  stepsHistory: [1500, 2400, 3100, 4200, 0, 2800], // ❌ DUMMY DATA
  sleepHistory: [450, 360, 480, 330, 380, 420],     // ❌ DUMMY DATA
  screenTimeHistory: [270, 372, 300, 426, 0, 360], // ❌ DUMMY DATA
))
```

**Dampak:**

- Saat pertama load, UI menghitung progress berdasarkan dummy history
- Progress bar misi menunjukkan **20/100** (dari data history dummy)
- Setelah `loadDailyValues()` selesai, baru data real di-load → progress jadi 0/100

**Solusi:**

1. **Ganti default value jadi kosong:**

```dart
stepsHistory: [],
sleepHistory: [],
screenTimeHistory: [],
```

2. **Load dari cache** terlebih dahulu di constructor sebelum set state

**Priority:** Medium

---

### **Issue #8: Umur di Profil Langsung Diset 30 Tahun** ✅

**Lokasi:** [`apps/mobile/lib/features/findrisc/findrisc_step1_screen.dart`](apps/mobile/lib/features/findrisc/findrisc_step1_screen.dart:45-96)

**Root Cause:**
FINDRISC **tidak menanyakan umur spesifik**, hanya **age group** (range) yang kemudian di-hardcode ke nilai default 30.

**Status:** ✅ **FIXED**

**Implementasi:**

1. **Changed age input** dari radio button selection ke numeric text field dengan `_SuffixField` widget
2. **Added auto-calculation** - Method `_calculateAgeGroup()` otomatis menghitung age group dari input numerik:
   ```dart
   void _calculateAgeGroup() {
     final age = int.tryParse(_ageCtrl.text);
     if (age == null) {
       setState(() => _ageGroup = '');
       return;
     }
     setState(() {
       if (age < 45) _ageGroup = '< 45 tahun';
       else if (age <= 54) _ageGroup = '45 - 54 tahun';
       else if (age <= 64) _ageGroup = '55 - 64 tahun';
       else _ageGroup = '> 64 tahun';
     });
   }
   ```
3. **Updated UI** - Menggunakan style yang sama dengan height/weight input (pill-style dengan suffix "tahun")
4. **Cleanup** - Removed unused `_OptionTile` widget dan fixed all Dart analyzer warnings

**Hasil:**

- User sekarang input umur spesifik (misal: 25 tahun)
- Age group dihitung otomatis untuk scoring FINDRISC
- Profil user menyimpan umur yang akurat

**Priority:** Critical

---

### **Issue #9: Format Pesan Telegram Untuk Link Bot Salah**

**Lokasi:** [`apps/backend/src/features/bot/bot.service.ts`](apps/backend/src/features/bot/bot.service.ts:129-134)

**Root Cause:**
Saat user belum memasukkan token (hanya `/start` tanpa parameter), bot mengirim pesan welcome tapi **tidak menjelaskan format yang benar**.

**Kode Saat Ini:**

```typescript
if (!token) {
  await this.sendTelegramMessage(
    chatId,
    "Selamat datang di Glicoo Bot! 🤖\n\nUntuk menghubungkan akun Anda, silakan buka menu *Bot Hub* di aplikasi Glicoo Anda dan ikuti panduannya."
  );
  return;
}
```

**Format yang Diharapkan User:**

```
/start <NoToken>
```

Tapi bot **tidak memberitahu** format ini di pesan welcome!

**Solusi:**
Update pesan welcome untuk memberikan contoh format:

```typescript
if (!token) {
  await this.sendTelegramMessage(
    chatId,
    "Selamat datang di Glicoo Bot! 🤖\n\n" +
      "Untuk menghubungkan akun Anda, gunakan format:\n" +
      "`/start <NoToken>`\n\n" +
      "Token bisa kamu dapatkan di menu *Bot Hub* pada aplikasi Glicoo."
  );
  return;
}
```

**Priority:** Medium

---

### **Issue #10: Default FINDRISC Score Bikin Bingung**

**Status:** ✅ FIXED

**Lokasi:**

- `apps/mobile/lib/features/home/providers/activity_provider.dart:217`
- `apps/mobile/lib/features/profile/profile_screen.dart:76`

**Deskripsi:**
Saat user belum melakukan tes FINDRISC, aplikasi menampilkan score `13` dengan kategori `'Sedang'` sebagai default value. Ini membingungkan karena terlihat seperti data asli, padahal user belum pernah tes.

**Root Cause:**

```dart
// activity_provider.dart:217
final score = prefs.getInt('findrisc_score') ?? 13;  // ❌ Looks like real data
final category = prefs.getString('findrisc_category') ?? 'Sedang';

// profile_screen.dart:76
_findriscScore = prefs.getInt('findrisc_score') ?? 13;
_findriscCategory = prefs.getString('findrisc_category') ?? 'Sedang';
_waistCircumference = prefs.getDouble('lingkar_pinggang_cm') ?? 98.0;  // ❌ Also confusing
```

Default value `13` dan `'Sedang'` membuat user bingung apakah ini data asli atau placeholder. Seharusnya jelas menunjukkan "belum ada data".

**Dampak:**

- **Data Integrity Issue**: User tidak tahu apakah skor yang ditampilkan adalah hasil tes asli
- **UX Problem**: Tidak ada indikator jelas bahwa user belum melakukan tes
- **Misleading Information**: Default value 13 (kategori Sedang) bisa mempengaruhi persepsi risiko user

**Solution Implemented:**
Changed default values to clearly indicate "no data":

```dart
// activity_provider.dart:217-219
final score = prefs.getInt('findrisc_score') ?? 0;  // ✅ Clear "no data" indicator
final category = prefs.getString('findrisc_category') ?? 'Belum Tes';

// profile_screen.dart:76-78
_findriscScore = prefs.getInt('findrisc_score') ?? 0;
_findriscCategory = prefs.getString('findrisc_category') ?? 'Belum Tes';
_waistCircumference = prefs.getDouble('lingkar_pinggang_cm') ?? 0.0;  // ✅ No dummy data
```

**Files Changed:**

- `apps/mobile/lib/features/home/providers/activity_provider.dart` (line 217-219)
- `apps/mobile/lib/features/profile/profile_screen.dart` (line 76-78)

**Priority:** Critical

---

## 🎯 PRIORITAS IMPLEMENTASI FIX

### **Critical (Harus Fix Segera):**

1. ✅ Issue #4: Aktivitas tidak jalan
2. ✅ Issue #8: Umur default 30 tahun
3. ✅ Issue #10: Default FINDRISC score bikin bingung

### **High (Fix Secepatnya):**

1. ✅ Issue #2: Tutorial muncul 2x
2. ✅ Issue #3: Image FINDRISC tidak muncul
3. ✅ Issue #6: Pop up asisten 2x

### **Medium (Bisa Ditunda):**

1. ✅ Issue #5: Redirect delay Google login
2. ✅ Issue #7: Dummy data misi
3. ✅ Issue #9: Format pesan Telegram

### **Low (Enhancement):**

1. ✅ Issue #1: Loading setelah login

---

## 📝 CATATAN TEKNIS

### **Pattern yang Sering Muncul:**

1. **Double listener problem** → Perlu audit semua `ref.listen` di codebase
2. **Hardcoded default values** → Gunakan empty state atau cache
3. **Missing assets** → Perlu checklist asset sebelum build
4. **Polling vs Push** → Sensor service harus pakai push notification pattern

### **Tech Debt yang Teridentifikasi:**

1. Activity provider perlu refactor (hapus timer polling)
2. FINDRISC flow perlu redesign untuk umur spesifik
3. Tutorial dialog perlu state management yang lebih robust
4. Asset management perlu CI check

---

### **Issue #11: Style "Risiko Saat Ini" Berbeda di Home vs Profile**

**Lokasi:**

- Home: [`apps/mobile/lib/features/home/home_screen.dart`](apps/mobile/lib/features/home/home_screen.dart:162-179)
- Profile: [`apps/mobile/lib/features/profile/profile_screen.dart`](apps/mobile/lib/features/profile/profile_screen.dart:1164-1184)

**Root Cause:**
Home screen menggunakan [`_StatRow`](apps/mobile/lib/features/home/home_screen.dart:258) yang hanya menampilkan text + icon biasa, sedangkan profile screen menggunakan badge dengan warna dinamis berdasarkan kategori risiko.

**Solusi Implemented:**
Update [`_RiskCard`](apps/mobile/lib/features/home/home_screen.dart:162) di home screen untuk menggunakan style badge yang sama dengan profile screen:

- ✅ Badge dengan background `riskColor.withValues(alpha: 0.1)`
- ✅ SVG icon dengan color filter sesuai kategori risiko
- ✅ Text bold dengan warna dinamis
- ✅ Mapping kategori ke warna: Rendah (Green), Sedikit Meningkat (Blue), Sedang (Yellow), Tinggi (Orange), Sangat Tinggi (Red), Belum Tes (Gray)

**Priority:** Medium

---

### **Issue #12: Challenge Card Styling & Pop-up untuk Food Logging**

**Lokasi:**

- Quest List: [`apps/mobile/lib/features/quests/quests_screen.dart`](apps/mobile/lib/features/quests/quests_screen.dart:127-138)
- Dialog: [`apps/mobile/lib/features/quests/quests_screen.dart`](apps/mobile/lib/features/quests/quests_screen.dart:546-553)

**Root Cause:**
Quest "Makan Lebih Bijak" menggunakan warna pink (`0xFFC73E8A`) dan icon static `food.svg`, sedangkan desain baru meminta warna purple (`0xFFCB30E0`) dan icon karakter `iloo_food.svg`.

**Solusi Implemented:**

1. ✅ Update warna theme dari `0xFFC73E8A` → `0xFFCB30E0` (purple)
2. ✅ Update icon dari `food.svg` → `iloo_food.svg`
3. ✅ Update deskripsi pop-up dialog:
   - **Sebelum:** "Mencatat makanan secara rutin membantumu mengontrol asupan kalori dan gula harian..."
   - **Sesudah:** "Mencatat makanan membantu Iloo memahami pola makanmu sehingga dapat memberikan rekomendasi yang lebih sesuai untuk mengurangi risiko Diabetes Melitus Tipe 2."
4. ✅ Sesuaikan padding dan alignment di dialog (`containerPadding`, `imageAlignment`, `svgHeight`)

**Files Changed:**

- [`quests_screen.dart`](apps/mobile/lib/features/quests/quests_screen.dart:127-138) - QuestItem definition
- [`quests_screen.dart`](apps/mobile/lib/features/quests/quests_screen.dart:546-553) - QuestDetailDialog styling

**Priority:** Medium

---

## 🔄 NEXT STEPS

1. [x] Identifikasi semua bug
2. [x] Analisis root cause
3. [x] Implementasi fix per priority (12/12 issues fixed)
4. [ ] Testing setiap fix
5. [ ] Update CHANGELOG.md
6. [ ] Deploy ke staging
