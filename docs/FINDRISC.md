markdown_content = """# Dokumentasi Sistem Aturan Skoring FINDRISC (Finnish Diabetes Risk Score)

Dokumen ini berisi spesifikasi aturan logika, variabel, skoring, dan kesimpulan untuk mengimplementasikan sistem skrining risiko Diabetes Melitus Tipe 2 menggunakan metode FINDRISC.

---

## 1. Variabel Input dan Bobot Skor

Sistem harus menerima 8 variabel input berikut dan menghitung skor berdasarkan ketentuan di bawah ini:

### Variabel 1: Usia (`usia`)

- **< 45 tahun**: 0 poin
- **45 – 54 tahun**: 2 poin
- **55 – 64 tahun**: 3 poin
- **> 64 tahun**: 4 poin

### Variabel 2: Indeks Massa Tubuh / IMT (`imt`)

_Formula IMT = Berat Badan (kg) / (Tinggi Badan (m) _ Tinggi Badan (m))\*

- **< 25 kg/m²**: 0 poin
- **25 – 30 kg/m²**: 1 poin
- **> 30 kg/m²**: 3 poin

### Variabel 3: Lingkar Pinggang (`lingkar_pinggang`)

_Nilai disesuaikan berdasarkan jenis kelamin pengguna._

- **Pria < 94 cm** ATAU **Wanita < 80 cm**: 0 poin
- **Pria 94 – 102 cm** ATAU **Wanita 80 – 88 cm**: 1 poin
- **Pria > 102 cm** ATAU **Wanita > 88 cm**: 4 poin

### Variabel 4: Aktivitas Fisik (`aktivitas_fisik`)

_Apakah pengguna melakukan aktivitas fisik minimal 30 menit setiap hari (termasuk saat bekerja/santai)?_

- **Ya**: 0 poin
- **Tidak**: 2 poin

### Variabel 5: Pola Makan (`konsumsi_buah_sayur`)

_Apakah pengguna mengonsumsi sayuran, buah-buahan, atau beri setiap hari?_

- **Setiap hari**: 0 poin
- **Tidak setiap hari**: 1 poin

### Variabel 6: Riwayat Obat Hipertensi (`obat_hipertensi`)

_Apakah pengguna pernah atau sedang rutin mengonsumsi obat tekanan darah tinggi?_

- **Tidak**: 0 poin
- **Ya**: 2 poin

### Variabel 7: Riwayat Gula Darah Tinggi (`riwayat_gula_darah`)

_Apakah pengguna pernah ditemukan memiliki kadar gula darah tinggi (misal: saat check-up, sakit, atau hamil)?_

- **Tidak**: 0 poin
- **Ya**: 5 poin

### Variabel 8: Riwayat Keluarga Diabetes (`riwayat_keluarga_dm`)

_Apakah ada anggota keluarga inti atau besar yang didiagnosis diabetes (Tipe 1 atau Tipe 2)?_

- **Tidak**: 0 poin
- **Ya: Keluarga jauh** (Kakek, nenek, paman, bibi, atau sepupu): 3 poin
- **Ya: Keluarga inti** (Orang tua, saudara kandung, atau anak kandung): 5 poin

---

## 2. Aturan Logika Pengambilan Keputusan (Decision Rules)

Total Skor didapatkan dari penjumlahan skor kedelapan variabel di atas:
`Total_Skor = Skor_1 + Skor_2 + Skor_3 + Skor_4 + Skor_5 + Skor_6 + Skor_7 + Skor_8`

Sistem harus memetakan `Total_Skor` ke dalam kategori risiko dan memberikan kesimpulan serta rekomendasi berikut:

### Aturan 1: Risiko Rendah

- **Kondisi**: `Total_Skor < 7`
- **Persentase Risiko (10 Tahun ke Depan)**: Estimasi 1% (1 dari 100 orang)
- **Kesimpulan**: Risiko Anda terkena Diabetes Melitus Tipe 2 dalam 10 tahun ke depan tergolong **Rendah**.
- **Rekomendasi**: Pertahankan gaya hidup sehat Anda saat ini. Tetap aktif bergerak dan konsumsi makanan bernutrisi seimbang.

### Aturan 2: Risiko Sedikit Meningkat

- **Kondisi**: `7 <= Total_Skor <= 11`
- **Persentase Risiko (10 Tahun ke Depan)**: Estimasi 4% (1 dari 25 orang)
- **Kesimpulan**: Risiko Anda terkena Diabetes Melitus Tipe 2 tergolong **Sedikit Meningkat**.
- **Rekomendasi**: Mulailah lebih memperhatikan pola makan dan tingkatkan durasi olahraga. Batasi konsumsi gula berlebih dan makanan olahan.

### Aturan 3: Risiko Sedang

- **Kondisi**: `12 <= Total_Skor <= 14`
- **Persentase Risiko (10 Tahun ke Depan)**: Estimasi 17% (1 dari 6 orang)
- **Kesimpulan**: Risiko Anda terkena Diabetes Melitus Tipe 2 tergolong **Sedang**.
- **Rekomendasi**: Disarankan untuk melakukan konsultasi dengan tenaga medis. Pertimbangkan untuk melakukan pemeriksaan gula darah berkala (GDS/GDP) dan mulailah program penurunan berat badan jika IMT berlebih.

### Aturan 4: Risiko Tinggi

- **Kondisi**: `15 <= Total_Skor <= 20`
- **Persentase Risiko (10 Tahun ke Depan)**: Estimasi 33% (1 dari 3 orang)
- **Kesimpulan**: Risiko Anda terkena Diabetes Melitus Tipe 2 tergolong **Tinggi**.
- **Rekomendasi**: Anda sangat disarankan untuk memeriksakan diri ke dokter atau fasilitas kesehatan terdekat untuk tes darah laboratorium (seperti HbA1c atau Tes Toleransi Glukosa Oral). Intervensi gaya hidup secara intensif sangat diperlukan.

### Aturan 5: Risiko Sangat Tinggi

- **Kondisi**: `Total_Skor > 20`
- **Persentase Risiko (10 Tahun ke Depan)**: Estimasi 50% (1 dari 2 orang)
- **Kesimpulan**: Risiko Anda terkena Diabetes Melitus Tipe 2 tergolong **Sangat Tinggi**.
- **Rekomendasi**: Segera jadwalkan pertemuan dengan dokter. Diperlukan evaluasi klinis menyeluruh untuk mendeteksi kemungkinan diabetes yang belum terdiagnosis atau kondisi prediabetes, serta penanganan medis dan perubahan gaya hidup secara radikal.

---

## 3. Contoh Implementasi Logika (Pseudo-code)

Anda bisa menggunakan struktur logika berikut saat menulis kode program (misal dalam JavaScript, Python, atau PHP):

Output kode
File aturan_sistem_findrisc.md berhasil dibuat.

```python
def hitung_kesimpulan_findrisc(total_skor):
    if total_skor < 7:
        kategori = "Rendah"
        probabilitas = "1%"
        rekomendasi = "Pertahankan gaya hidup sehat Anda saat ini. Tetap aktif bergerak."
    elif 7 <= total_skor <= 11:
        kategori = "Sedikit Meningkat"
        probabilitas = "4%"
        rekomendasi = "Perhatikan pola makan, batasi gula, dan tingkatkan aktivitas fisik harian."
    elif 12 <= total_skor <= 14:
        kategori = "Sedang"
        probabilitas = "17%"
        rekomendasi = "Disarankan cek gula darah berkala dan konsultasi perubahan gaya hidup ke fasilitas kesehatan."
    elif 15 <= total_skor <= 20:
        kategori = "Tinggi"
        probabilitas = "33%"
        rekomendasi = "Sangat disarankan pemeriksaan laboratorium (HbA1c/TTGO) ke dokter untuk penanganan dini."
    else: # Jika skor > 20
        kategori = "Sangat Tinggi"
        probabilitas = "50%"
        rekomendasi = "Segera hubungi dokter untuk evaluasi klinis menyeluruh dan intervensi medis."

    return {
        "skor": total_skor,
        "kategori": kategori,
        "probabilitas": probabilitas,
        "rekomendasi": rekomendasi
    }
"""

file_name = "aturan_sistem_findrisc.md"
with open(file_name, "w", encoding="utf-8") as file:
file.write(markdown_content)

print(f"File {file_name} berhasil dibuat.")
```
