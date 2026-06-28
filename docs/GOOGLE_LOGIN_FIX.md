# 🔑 Panduan Memperbaiki Login Google (DEVELOPER_ERROR)

> **Gejala:** Tombol Google → account picker muncul → setelah pilih akun → **gagal / error generik**.
>
> **Root cause:** `DEVELOPER_ERROR (code 10)` — SHA-1 fingerprint aplikasi Android belum didaftarkan ke OAuth Client ID di Google Cloud Console & Supabase.

File ini adalah panduan konfigurasi **di luar kode** (tidak bisa dikerjakan AI dari editor). Ikuti urutannya.

---

## 📋 SHA-1 Fingerprint Anda (sudah diekstrak dari `~/.android/debug.keystore`)

| Build variant | SHA-1 |
|---|---|
| **Debug** (flutter run) | `7A:48:EB:06:D3:43:8B:9C:C8:98:83:37:D7:85:E9:23:02:DB:43:87` |
| **Release** | _(belum ada — generate setelah setup signing keystore release)_ |

> ⚠️ Fingerprint debug ini **unik per mesin**. Jika Anda build di komputer lain, fingerprintnya beda dan harus didaftarkan juga.

---

## 🚀 Langkah-langkah

### Langkah 1 — Daftarkan SHA-1 ke Google Cloud Console

1. Buka **[Google Cloud Console](https://console.cloud.google.com/)** → pilih project yang sama dengan `GOOGLE_WEB_CLIENT_ID` Anda (prefix `10052872…`, 73 karakter).
2. Menu **APIs & Services → OAuth consent screen** → pastikan sudah dikonfigurasi (App name, support email, scope `email/profile/openid`).
3. Menu **APIs & Services → Credentials**.
4. Buka (atau buat) **OAuth client ID** tipe **Web application** — ini yang client ID-nya dipakai sebagai `GOOGLE_WEB_CLIENT_ID` di `.env` mobile.
   - Pastikan **Authorized JavaScript origins** & **Authorized redirect URIs** berisi domain Supabase Anda: `https://<project-ref>.supabase.co/auth/v1/callback`.
5. **Penting:** Buka/buat juga **OAuth client ID** tipe **Android** (kalau belum ada):
   - **Package name:** `com.glicoo.glicoo_mobile` (dari `applicationId` di `build.gradle.kts:20`).
   - **SHA-1 certificate fingerprint:** `7A:48:EB:06:D3:43:8B:9C:C8:98:83:37:D7:85:E9:23:02:DB:43:87`.
6. Simpan. Perubahan SHA-1 butuh **~5 menit** untuk propagate.

### Langkah 2 — Daftarkan SHA-1 ke Supabase Auth

1. Buka **[Supabase Dashboard](https://supabase.com/dashboard)** → project Anda.
2. **Authentication → Providers → Google** → edit.
3. Gulir ke **Authorized client IDs** / **SHA-1 fingerprints** section.
4. Tambahkan:
   - **Web client ID** (sama dengan `GOOGLE_WEB_CLIENT_ID`).
   - **App secret / Web client secret** (dari Google Cloud, OAuth client Web).
   - **SHA-1 fingerprint:** `7A:48:EB:06:D3:43:8B:9C:C8:98:83:37:D7:85:E9:23:02:DB:43:87`.
5. Save.

### Langkah 3 — Verifikasi

1. Rebuild & reinstall app: `flutter clean && flutter run` (penting: cache lama harus bersih).
2. Coba login Google. Account picker muncul → pilih akun → **harus masuk home**.
3. Jika masih gagal, jalankan **logcat** untuk lihat error asli (dengan logging baru yang saya tambahkan di Paket B1):

```bash
adb logcat | grep -iE "GOOGLE_SIGN_IN|AUTH|flutter"
```

---

## 🔍 Diagnosis Error Umum

Setelah logging baru (Paket B1), `adb logcat` akan menampilkan tag `[GOOGLE_SIGN_IN]` dan `[AUTH]`. Cocokkan:

| Pesan log | Arti | Solusi |
|---|---|---|
| `idToken null` / `Token otentikasi kosong` | SHA-1 belum terdaftar (paling umum) | Ulangi Langkah 1 & 2 |
| `DEVELOPER_ERROR` / `code: 10` | SHA-1 salah / package name tidak cocok | Cek `applicationId` vs yang didaftarkan |
| `ApiException: 12500` | Konfigurasi OAuth consent screen belum lengkap | Lengkapi consent screen di Google Cloud |
| `ApiException: 7` (network) | Tidak ada koneksi internet | Cek koneksi device |
| `SIGN_IN_CANCELLED` | User tekan back di picker | Normal, bukan bug |

---

## 🛠️ Catatan untuk Build Release

Saat build release (`flutter build apk --release`), `build.gradle.kts:33` saat ini **masih sign pakai debug key**:

```kotlin
signingConfig = signingConfigs.getByName("debug")
```

Artinya fingerprint release = fingerprint debug untuk sekarang, **SHA-1 di atas sudah cukup**. Tapi sebelum publikasi ke Play Store, Anda harus:

1. Generate keystore release: `keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release`.
2. Tambah `signingConfigs.release` di `build.gradle.kts` + `.properties` untuk password.
3. Daftarkan **SHA-1 release** + **SHA-1 Play App Signing** (dari Play Console → App Integrity) ke Google Cloud & Supabase juga.
