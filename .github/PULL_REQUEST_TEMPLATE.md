## Deskripsi Perubahan

Jelaskan secara singkat apa yang diubah atau ditambahkan.

Contoh:

- feat: tambahkan endpoint /health-data untuk menerima data sensor
- fix: perbaiki bug crash saat akses kamera di Android 12
- docs: tambahkan API documentation untuk dashboard
- refactor: optimasi query database untuk grafik mingguan

---

## Type of Change

- [ ] feat - Penambahan fitur baru
- [ ] fix - Perbaikan bug
- [ ] docs - Perubahan dokumentasi
- [ ] refactor - Perubahan kode tanpa mengubah perilaku
- [ ] perf - Perbaikan performa
- [ ] test - Penambahan atau perbaikan test
- [ ] chore - Perubahan konfigurasi atau dependency
- [ ] style - Perubahan format kode (spasi, indentasi, dll)
- [ ] ci - Perubahan CI/CD pipeline

---

## Scope Perubahan

- [ ] Mobile (React Native)
- [ ] Backend (Node.js)
- [ ] Web (Next.js)
- [ ] Docs
- [ ] Database
- [ ] AI Engine (n8n)
- [ ] Config / DevOps

---

## Checklist

### Kode

- [ ] Kode sudah di-test secara lokal (berhasil running)
- [ ] Tidak ada error atau warning di console
- [ ] Tidak ada console.log() yang tertinggal (kecuali untuk debug)
- [ ] Tidak ada secret/API key yang terekspos di kode
- [ ] Mengikuti coding convention tim

### Dokumentasi

- [ ] README.md diperbarui (jika perlu)
- [ ] API_SPEC.md diperbarui (jika ada perubahan endpoint)
- [ ] Komentar kode ditambahkan untuk logika kompleks

### Testing

- [ ] Fitur berjalan sesuai ekspektasi
- [ ] Tidak merusak fitur lain (regression test)
- [ ] Testing dilakukan di device/emulator yang sesuai

---

## Screenshots atau Video (jika UI berubah)

**Sebelum:**
(tambahkan screenshot)

**Sesudah:**
(tambahkan screenshot)

---

## Link Terkait

- Issue: #[nomor]
- Dokumentasi: [link ke docs/API_SPEC.md]
- Referensi: [link ke jurnal / artikel terkait]

---

## Cara Test

1. Clone branch ini: git checkout [branch-name]
2. Jalankan: npm install / yarn install
3. Test skenario:
   - Skenario 1: ...
   - Skenario 2: ...
4. Expected result: ...

---

## Catatan Tambahan

- Dependensi baru: [nama library] versi [x.x.x]
- Perlu migrasi database: [ya/tidak]
- Perlu update environment variable: [ya/tidak]

---

Reviewer yang disarankan: @[username]
