# 🗺️ MONOREPO ARCHITECTURE & BOUNDARIES

Dokumen ini mendefinisikan batasan ekosistem di dalam repositori Glico. Repositori ini adalah **Polyglot Monorepo** yang dikelola menggunakan `bun workspaces`.

## 📂 Struktur Direktori

```text
glico/
├── apps/
│   ├── backend/    (TypeScript - Node.js/Elysia)
│   ├── mobile/     (Dart - Flutter)
│   └── web/        (TypeScript - Next.js)
├── packages/       (TypeScript Shared Libraries)
│   ├── config/     (Shared ESLint/TS configs)
│   └── types/      (Shared TypeScript Interfaces/Contracts)
└── package.json    (Bun Workspace Root)
🚧 Aturan Ekosistem (CRITICAL FOR AI)
1. Batasan Mobile (Flutter)
apps/mobile adalah ekosistem DART yang TERISOLASI PENUH.

JANGAN PERNAH mencoba meng-import file TypeScript dari packages/ ke dalam apps/mobile.

apps/mobile memiliki manajer paketnya sendiri (pubspec.yaml) dan tidak terhubung dengan Bun Workspace.

2. Batasan Web & Backend
apps/web dan apps/backend menggunakan TypeScript.

Kedua aplikasi ini WAJIB menggunakan kode bersama dari packages/ jika melibatkan type sharing untuk API payload atau database schema.

Gunakan absolute imports yang disediakan oleh workspace (misal: import { UserType } from "@glico/types").

3. Environment Variables
Setiap aplikasi mengelola file .env masing-masing di dalam direktori aplikasinya (apps/web/.env, apps/backend/.env).

Tidak ada .env global di root direktori yang menyuntikkan nilai ke aplikasi.

Variabel publik untuk Next.js harus menggunakan prefix NEXT_PUBLIC_.

4. Package Manager & Scripting
Gunakan bun untuk seluruh ekosistem TypeScript/JavaScript.

Eksekusi instalasi atau penambahan package TS dilakukan menggunakan perintah bun (contoh: bun add <package> --filter web).
```
