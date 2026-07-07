# 📋 TODO — Glicoo Bug Fixes & UI Updates

> Last updated: 2026-07-07 (UI-01 ✅ UI-02 ✅ UI-03 ✅ UI-04 ✅ UI-05 ✅ BE-01 ✅)

---

## 🐛 Mobile UI Bugs

### Findrisc

- [x] **[UI-01]** Tambahkan **thought bubble Iloo** di `findrisc_intro_screen.dart` ✅

- [x] **[UI-02]** Warna teks dinamis Findrisc: Rendah=hijau, Sedikit=kuning, Sedang=oranye, Tinggi=merah, SangatTinggi=merah tua ✅
  - Fix di: `profile_stats_widget.dart` (`_getRiskColor`) + `findrisc_result_screen.dart` (`_buildScoreSection`)

- [x] **[UI-03]** Konversi *"Catat Menu Makan"* bottom sheet → full-page ✅
  - Buat `food_log_screen.dart` (Scaffold baru)
  - `food_log_card.dart`: ganti `showModalBottomSheet` → `Navigator.push`

- [x] **[UI-04]** Screen *"Estimasi Menu"* — semua teks putih ✅
  - Label header, nilai, dan level badge di blue card sekarang semua `Colors.white`

- [x] **[UI-05]** Screen *"Perbarui Data Kesehatan"* → full-page ✅
  - `edit_profile_bottom_sheet.dart`: Container → Scaffold + AppBar
  - `profile_screen.dart`: `showModalBottomSheet` → `Navigator.push`

---

## 🐛 Backend Bugs

- [x] **[BE-01]** Chatbot WhatsApp kirim pesan 2x — fixed ✅
  - Root cause: OpenWA retry webhook saat koneksi tidak stabil → event masuk 2x
  - Fix: Tambah `isDuplicateWaEvent()` di `bot.routes.ts` — dedup key = `chatId::text::time-bucket(5s)`, TTL 30s

---

## ❓ Open Questions

> Semua item selesai! 🎉
