# 📝 CURRENT SPRINT TO-DO

## Web Dashboard & Admin Monitoring

- [x] Tambahkan model `WebMetric` di `apps/backend/prisma/schema.prisma` dan jalankan `bun run db:push` <!-- id: task-db-metric -->
- [x] Buat route `POST /admin/hit` di `apps/backend/src/features/admin/admin.routes.ts` untuk track kunjungan/unduhan APK <!-- id: task-api-hit -->
- [x] Integrasikan `WebMetric` ke respon `GET /admin/stats` di Elysia <!-- id: task-api-stats -->
- [x] Setup Next.js API Route `/api/admin-stats` sebagai proxy ber-auth API Key ke Elysia <!-- id: task-next-proxy -->
- [x] Investigasi dan perbaiki masalah White Screen of Death (layar putih blank) di tampilan mobile web <!-- id: task-mobile-bug -->
- [x] Buat reusable BentoCard component dengan tema pastel, rounded corners, minimalist & clean <!-- id: task-bento-card -->
- [x] Implementasi Halaman Dashboard Admin (`/admin`) dengan Bento Grid layout <!-- id: task-admin-dashboard -->
- [x] Tambahkan script logger (tracking hit) otomatis saat user membuka landing page dan menekan tombol unduh APK <!-- id: task-hit-logger -->
- [x] Verifikasi dan manual testing (health, metrics, UI/UX) <!-- id: task-verify -->
