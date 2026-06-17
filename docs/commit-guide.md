# 📝 Commit Message Guide — Glico

> Panduan format commit message untuk seluruh kontributor Glico.

---

## 1. Format Commit Message

```
[type]([scope]): [subject]

[body (opsional)]

[footer (opsional)]
```

---

## 2. Type (Wajib)

| Type       | Deskripsi                             | Contoh                                      |
| ---------- | ------------------------------------- | ------------------------------------------- |
| `feat`     | Penambahan fitur baru                 | `feat: tambahkan endpoint health-data`      |
| `fix`      | Perbaikan bug                         | `fix: perbaiki crash saat akses kamera`     |
| `docs`     | Perubahan dokumentasi                 | `docs: update API_SPEC.md`                  |
| `style`    | Perubahan format kode (spasi, dll)    | `style: rapikan indentasi SensorService`    |
| `refactor` | Perubahan kode tanpa ubah perilaku    | `refactor: optimasi query database`         |
| `perf`     | Perbaikan performa                    | `perf: cache response dashboard`            |
| `test`     | Penambahan atau perbaikan test        | `test: tambahkan unit test untuk aiService` |
| `chore`    | Perubahan konfigurasi atau dependency | `chore: update express ke 4.19.0`           |
| `ci`       | Perubahan CI/CD pipeline              | `ci: tambahkan workflow deploy ke Vercel`   |
| `revert`   | Membatalkan commit sebelumnya         | `revert: revert commit abc123`              |

---

## 3. Scope (Opsional)

| Scope     | Komponen                           |
| --------- | ---------------------------------- |
| `mobile`  | Flutter App                        |
| `backend` | Node.js API (Elysia)               |
| `web`     | Next.js Dashboard                  |
| `db`      | Database migration / schema        |
| `api`     | Endpoint API                       |
| `ai`      | AI Engine (n8n / LLM)              |
| `sensor`  | Sensor Service (step, screen time) |
| `auth`    | Authentication / JWT               |
| `docs`    | Dokumentasi                        |
| `config`  | Konfigurasi proyek                 |

---

## 4. Cara Menulis Commit Message yang Baik

### Subject (Baris Pertama)

- Maksimal **50 karakter**
- Gunakan **imperative mood** (seperti memberi perintah)
- Jangan diakhiri titik

✅ **Benar:**

```
feat(backend): tambahkan endpoint /api/health-data
fix(mobile): perbaiki bug crash di Android 12
docs: update README dengan link demo
```

❌ **Salah:**

```
feat: menambahkan endpoint health data.   (terlalu panjang, pakai titik)
Fix bug di mobile                          (kapital, tidak pakai scope)
Update README                              (tidak ada type)
```

### Body (Opsional)

- Menjelaskan **"mengapa"** perubahan dilakukan
- Maksimal 72 karakter per baris
- Pisahkan dari subject dengan satu baris kosong

### Footer (Opsional)

- Referensi issue: `Closes #12` atau `Refs #34`
- Breaking change: `BREAKING CHANGE: ...`

---

## 5. Contoh Commit Message Lengkap

```bash
# Fitur baru dengan body
feat(backend): tambahkan endpoint /api/health-data

Endpoint ini menerima data langkah, screen time, dan tidur dari mobile app.
Data akan disimpan ke database dan digunakan untuk menghitung risk score.

Closes #12

# Perbaikan bug dengan body
fix(mobile): perbaiki bug crash saat akses kamera di Android 12

Permission CAMERA tidak diminta sebelum akses kamera.
Tambahkan permission check sebelum memulai camera intent.

Closes #15

# Dokumentasi
docs(api): update API_SPEC.md dengan endpoint dashboard

Tambahkan dokumentasi untuk:
- GET /api/dashboard/summary
- GET /api/dashboard/weekly

# Refactor
refactor(backend): optimasi query dashboard

Gunakan join query daripada multiple query terpisah.
Performance improvement ~40%.

# Dependency update
chore(deps): update express ke 4.19.0

Update express untuk patch security vulnerability.

# Breaking change
feat(api): ubah response format /api/health-data

Response format diubah dari array ke object.

BREAKING CHANGE: response data.healthData menjadi data.items
```

---

## 6. Contoh Commit Per Komponen

### Mobile (Flutter)

```bash
feat(mobile): tambahkan akses sensor step counter
feat(mobile): tambahkan halaman HomeScreen dashboard
fix(mobile): perbaiki permission screen time di iOS 16
refactor(mobile): pisahkan SensorService ke file terpisah
```

### Backend (Elysia)

```bash
feat(backend): tambahkan endpoint POST /api/health-data
feat(backend): tambahkan scheduler untuk trigger AI di jam makan
feat(backend): tambahkan service ke AI Engine (n8n)
fix(backend): perbaiki CORS error di production
```

### Web Dashboard (Next.js)

```bash
feat(web): tambahkan landing page
feat(web): tambahkan dashboard monitoring
feat(web): tambahkan halaman history
style(web): implementasi TailwindCSS di seluruh komponen
```

### Docs

```bash
docs: tambahkan API_SPEC.md lengkap
docs: update README dengan link demo dan tech stack
```

---

## 7. Tools Pendukung

### Commitizen (Wajib Install!)

```bash
# Install global
npm install -g commitizen

# Inisialisasi di proyek
commitizen init cz-conventional-changelog --save-dev --save-exact

# Lalu commit pake:
git cz
```

Dengan Commitizen, kalian tinggal ikuti prompt, tidak perlu hafal format.

### Commitlint (Validasi Commit)

```bash
# Install
npm install --save-dev @commitlint/cli @commitlint/config-conventional

# Buat file commitlint.config.js
echo "module.exports = { extends: ['@commitlint/config-conventional'] };" > commitlint.config.js

# Tambahkan husky untuk pre-commit hook
npm install --save-dev husky
npx husky install
npx husky add .husky/commit-msg 'npx --no-install commitlint --edit "$1"'
```

Dengan ini, commit yang tidak sesuai format akan ditolak otomatis.

---

## 8. Git Cheat Sheet

```bash
# Melihat status
git status

# Menambahkan file ke staging
git add mobile/src/services/SensorService.js
git add backend/src/controllers/healthDataController.js

# Atau semua perubahan:
git add .

# Commit dengan message
git commit -m "feat(mobile): tambahkan akses sensor step counter"

# Commit dengan message multi-line
git commit -m "feat(backend): tambahkan endpoint health-data

Endpoint ini menerima data dari mobile app.
Data disimpan ke database dan digunakan untuk risk score calculation."

# Melihat history commit
git log --oneline

# Melihat history dengan grafik
git log --graph --oneline --all

# Push ke GitHub
git push origin main

# Pull terbaru dari GitHub
git pull origin main

# Membuat branch baru
git checkout -b feature/health-data-endpoint

# Switch branch
git checkout main

# Merge branch
git merge feature/health-data-endpoint
```

---

## 9. Contoh Commit History yang Rapi

```
$ git log --oneline

a1b2c3d feat(web): tambahkan dashboard monitoring
e4f5g6h fix(mobile): perbaiki crash akses kamera
i7j8k9l docs: update API_SPEC.md dengan endpoint dashboard
m1n2o3p feat(backend): tambahkan endpoint /api/health-data
q4r5s6t style(web): implementasi TailwindCSS
u7v8w9x chore(deps): update react-native ke 0.74
y0z1a2b feat(mobile): tambahkan akses sensor step counter
```

---

## Ringkasan (Buat yang Males Baca)

> **Format:** `[type]([scope]): [subject]`
>
> **Type:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`
>
> **Scope:** `mobile`, `backend`, `web`, `db`, `api`, `ai`, `sensor`, `auth`, `docs`, `config`
>
> **Tips:**
>
> - Subject max 50 karakter
> - Jangan pakai titik di akhir
> - Pakai imperative mood (tambah, perbaiki, update)
> - Install commitizen: `npm install -g commitizen`
>
> Gas! 🚀
