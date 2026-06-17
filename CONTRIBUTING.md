# Contributing to Glico

Kami senang kamu tertarik berkontribusi ke Glico! 🎉 Berikut panduan untuk memulai.

---

## Cara Berkontribusi

### 1. Fork & Clone

```bash
git clone https://github.com/iniralfi/glico.git
cd glico
```

### 2. Buat Branch

Buat branch dari `main` dengan nama yang deskriptif:

```bash
git checkout -b feat/tambah-endpoint-health-data
# atau
git checkout -b fix/perbaiki-crash-kamera
# atau
git checkout -b docs/update-readme
```

### 3. Lakukan Perubahan

- Ikuti struktur folder yang sudah ada
- Pastikan kode mengikuti standar arsitektur proyek (Clean Architecture, SOLID)
- Jangan gunakan `any` di TypeScript

### 4. Commit

Gunakan format commit yang sudah ditentukan:

```bash
git add .
git commit -m "feat(backend): tambahkan endpoint /api/health-data"
```

Lihat panduan lengkap di [`docs/commit-guide.md`](docs/commit-guide.md).

> **Tips:** Install Commitizen untuk kemudahan:
>
> ```bash
> npm install -g commitizen
> git cz
> ```

### 5. Push & Pull Request

```bash
git push origin feat/tambah-endpoint-health-data
```

Buka Pull Request ke branch `main` repository ini.

---

## Panduan Kode

### TypeScript

- Hindari `any` — gunakan `unknown`, generic `<T>`, atau definisikan interface/type
- Gunakan JSDoc (`/** */`) untuk fungsi publik yang diekspor

### Import Order

```
1. External libraries   (react, elysia, prisma)
2. Internal absolute    (@/modules/..., @/utils/...)
3. Relative             (./utils, ../schema)
```

### Comment Style

Tulis komentar untuk menjelaskan **MENGAPA**, bukan **APA**.

```typescript
// ❌ Buruk: increment counter
counter++;

// ✅ Bagus: retry limit reached, force logout to prevent infinite loop
counter++;
```

---

## Report Bug

Buka issue dengan template bug report yang sudah disediakan di [`.github/ISSUE_TEMPLATE/bug_report.md`](.github/ISSUE_TEMPLATE/bug_report.md).

---

## Lisensi

Dengan berkontribusi, kamu setuju bahwa kontribusimu akan dilisensikan di bawah **MIT License** — lihat file [`LICENSE`](LICENSE).
