# 🌍 Global Commit Guide Setup

Panduan setup format commit message agar bisa dipakai global di luar repository ini.

---

## 1. Git Commit Template (Sangat Direkomendasikan)

Kamu bisa setup template pesan commit yang otomatis muncul setiap kali menjalankan `git commit` (tanpa `-m`).

### Langkah-langkah:

1. Buat file `.gitmessage` di home directory:

   ```bash
   nano ~/.gitmessage
   ```

2. Isi dengan template berikut:

   ```text
   [type]([scope]): [subject]

   # type: feat, fix, docs, style, refactor, perf, test, chore, ci, revert
   # scope: mobile, backend, web, db, api, ai, sensor, auth, docs, config
   # subject: maks 50 karakter, imperative mood, tanpa titik di akhir.
   #
   # --- Batas baris kosong ---
   #
   # Body (opsional): jelaskan MENGAPA, maks 72 karakter per baris.
   # Footer (opsional): Closes #issue atau BREAKING CHANGE.
   ```

3. Daftarkan template tersebut ke konfigurasi global git:
   ```bash
   git config --global commit.template ~/.gitmessage
   ```

Sekarang setiap kali ketik `git commit`, text editor default git akan otomatis menampilkan template di atas untuk diisi.

---

## 2. Global Commitizen (Supaya bisa pakai `git cz` di mana saja)

Jika ingin menggunakan prompt interaktif `git cz` secara global di semua repository:

1. Install Commitizen global:

   ```bash
   npm install -g commitizen cz-conventional-changelog
   ```

2. Buat file konfigurasi `.czrc` di home directory agar Commitizen selalu tahu adapter mana yang dipakai:

   ```bash
   echo '{ "path": "cz-conventional-changelog" }' > ~/.czrc
   ```

3. Jalankan commit dengan command berikut di repo mana saja:
   ```bash
   git cz
   ```

---

## 3. Alias Git

Buat shortcut singkat untuk melihat commit log rapi:

```bash
git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
```

Sekarang jalankan `git lg` untuk melihat grafik log commit yang bersih.
