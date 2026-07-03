# 🛠️ AI ENGINEERING RULES

> Prinsip: AI adalah software engineer yang dapat menjelaskan keputusan teknis, bukan generator kode tanpa alasan.

---

# 📐 CORE PRINCIPLES

## 1. Priority Order

Saat terjadi konflik antar aturan:

```
Correctness
→ User Intent
→ Readability
→ Maintainability
→ Performance
→ Fancy
```

Penjelasan:

- Jangan mengorbankan kebenaran demi arsitektur cantik.
- Optimasi dilakukan jika memang diperlukan.
- Hindari overengineering.

---

## 2. Architecture Standards

Gunakan prinsip berikut secara bertahap:

```
KISS
→ YAGNI
→ DRY
→ SOLID
→ Clean Architecture
```

Aturan:

- Jangan membuat abstraction tanpa alasan.
- Clean Architecture hanya digunakan jika kompleksitas mulai meningkat.
- Duplikasi kecil lebih baik daripada abstraksi yang prematur.

---

## 3. Naming Convention

### File Naming

```txt
PascalCase.tsx
→ React Components

feature.role.ts
→ Backend Module

kebab-case.ts
→ Utility / Config / Non Component

SCREAMING_SNAKE_CASE
→ Env & Global Constant
```

---

## 4. Folder Structure

Gunakan:

```txt
feature-based
```

Contoh:

```txt
modules/
├── auth/
├── user/
├── post/
```

Hindari:

```txt
services/
routes/
controllers/
utils/
```

untuk project besar.

---

# 🧩 IMPLEMENTATION RULES

## 5. No Silent Edit

AI tidak boleh:

- mengubah workspace
- menghapus file
- refactor massal

tanpa persetujuan eksplisit.

Workflow:

```
Show
→ Explain
→ Confirm
→ Apply
```

---

## 6. Phase Breakdown

Task besar dibagi:

```txt
Design
→ Skeleton
→ Core Logic
→ Edge Cases
→ Testing
```

Gunakan `PROGRESS.md` hanya jika:

- > 3 phase
- > 5 file
- > 1 hari pengerjaan

---

## 7. No Magic Values

Dilarang:

```ts
retry(3);
```

Gunakan:

```ts
const MAX_RETRY = 3;
```

Jika literal dipakai:

- harus jelas
- tidak menimbulkan ambiguitas

---

## 8. Type Safety

Hindari:

```ts
any;
```

Prioritas:

```txt
specific type
→ interface
→ generic
→ unknown
→ any
```

Jika memakai `any`:

- alasan wajib dijelaskan
- scope sekecil mungkin

---

## 9. Import Order

Urutan import:

```txt
1 External

2 Internal Absolute

3 Relative
```

Contoh:

```ts
import react from "react";

import { api } from "@/lib/api";

import "./style.css";
```

---

# 📝 DOCUMENTATION RULES

## 10. Comment Policy

Komentar hanya boleh untuk:

✅ WHY
✅ TRADEOFF
✅ CONTRACT
✅ WARNING

Jangan komentar untuk menjelaskan:

❌ APA
❌ syntax
❌ nama variabel

---

## 11. Public Documentation

Setiap fungsi publik wajib memiliki JSDoc bilingual.

Format:

```ts
/**
 * [ID]
 * Tujuan fungsi
 *
 * [EN]
 * Function purpose
 */
```

Gunakan dokumentasi singkat.

---

## 12. File Metadata

Untuk file baru, tampilkan ringkasan:

```txt
Purpose:
→ Kenapa file ini ada

Used By:
→ Dipakai modul mana

Depends On:
→ Dependency penting

Impact:
→ Area yang terdampak jika berubah
```

Contoh:

```txt
Purpose:
Handle authentication

Used By:
auth.routes.ts

Depends On:
jwt
prisma

Impact:
login
register
middleware
```

---

# 🔍 DEBUGGING RULES

## 13. Error Workflow

Jika error:

```
Read Trace
→ Root Cause
→ Troubleshoot Options
→ Final Fix
```

Jangan langsung memberi solusi.

---

## 14. Verification Required

Setiap implementasi wajib punya minimal satu:

- manual test
- unit test
- integration test
- curl command
- reproduction step

---

## 15. Complexity Budget

Sebelum membuat abstraction:

Tanya:

```txt
Apa yang rusak kalau ini tidak dipisah?
```

Jika jawabannya:

```txt
Tidak ada
```

jangan buat layer baru.

---

## 16. Explain Architectural Decisions

Untuk keputusan besar jelaskan:

```txt
Why this?

Alternatives?

Tradeoff?
```

Jangan hanya bilang:

```txt
best practice
```

# 🚀 GLICO MONOREPO & TECH STACK RULES

## 17. Tech Stack Specifics

- **Web Dashboard:** Gunakan Next.js 14+ (App Router). Dilarang menggunakan Pages Router.
- **Backend API:** Gunakan Elysia.js (TypeScript). Dilarang memberikan solusi menggunakan Express.js atau NestJS.
- **Mobile App:** Gunakan Flutter 3.x.
- **Database:** PostgreSQL via Supabase. Gunakan standar Prisma atau Drizzle ORM (tergantung setup awal backend).

## 18. State Management

- **Web (Next.js):** Gunakan `Zustand` untuk global state. Dilarang menggunakan Redux.
- **Mobile (Flutter):** Gunakan `Riverpod` (`hooks_riverpod`). Pisahkan logika state dari UI secara tegas.

## 19. UI/UX & Styling Guidelines

- **Tema Utama:** Minimalist & Clean.
- **Layouting:** Gunakan pendekatan **Bento Grid** (card-based layout dengan rounded corners).
- **Color Palette:** Gunakan warna-warna pastel yang lembut.
- **Strict Rule:** Dilarang menggunakan desain Neobrutalism (tanpa bayangan blok tajam/hard shadows, tanpa border tebal).
- **Web Tooling:** Selalu gunakan TailwindCSS untuk web.

## 20. Architecture Boundaries (Crucial)

- **AI Agent & Bot Integration:** AI Agent (Gemini) dan Bot Interface (Telegram/WhatsApp via OpenWA) diintegrasikan langsung di dalam backend Elysia.js secara asinkronus (non-blocking) untuk meminimalkan kompleksitas infrastruktur.
- Elysia bertugas mengelola perizinan, sinkronisasi data sensor, menerima webhook bot, mengeksekusi prompt LLM/Gemini SDK secara asinkronus, serta mengirim pesan balasan dan pesan proaktif kembali ke platform chat.

# 📚 DOCUMENTATION INDEX

Sebelum mengeksekusi tugas, baca file dokumentasi berikut sesuai konteks yang sedang dikerjakan:

- `docs/ROADMAP.md` -> Untuk melihat target fase pengembangan (baca ini saat bingung tugas selanjutnya).
- `docs/MONOREPO_MAP.md` -> Untuk memahami arsitektur folder dan batas import antar aplikasi.
- `docs/DATABASE_SCHEMA.md` -> WAJIB dibaca saat membuat atau mengubah fitur backend/database.
- `docs/API_CONTRACTS.md` -> WAJIB dibaca saat menghubungkan Flutter ke Elysia.
- `docs/USER_FLOWS.md` & `docs/PRD.md` -> WAJIB dibaca saat mendesain UI/UX atau logika alur navigasi.
- `docs/DECISIONS.md` -> Untuk mengetahui alasan pemilihan tech stack (jangan sarankan stack lain).
- `docs/AI_AGENT_PROMPTS.md` -> Untuk referensi prompt Gemini dan alur chatbot.
