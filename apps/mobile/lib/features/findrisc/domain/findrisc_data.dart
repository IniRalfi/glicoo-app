// findrisc_data.dart
//
// Data model FINDRISC — menyimpan jawaban kuesioner dan menghitung skor risiko.
//
// Purpose:
// Model utama untuk data FINDRISC beserta algoritma scoring berdasarkan
// Finnish Diabetes Risk Score (FINDRISC).
//
// Used By:
// findrisc_step1_screen.dart, findrisc_step2_screen.dart,
// findrisc_result_screen.dart, main.dart
//
// Depends On:
// —
//
// Impact:
// Semua perhitungan skor FINDRISC di mobile

/// Model data lengkap hasil kuesioner FINDRISC.
class FindriscData {
  // ── Step 1 — Data Fisik ──
  final int age;
  final String ageGroup;
  final double tinggiCm;
  final double beratKg;
  final double lingkarPinggangCm;

  // ── Step 2 — Gaya Hidup & Riwayat ──
  final String aktivitasFisik;
  final String konsumsiBuahSayur;
  final String obatHipertensi;
  final String riwayatGulaDarah;
  final String riwayatKeluargaDM;

  const FindriscData({
    required this.age,
    required this.ageGroup,
    required this.tinggiCm,
    required this.beratKg,
    required this.lingkarPinggangCm,
    required this.aktivitasFisik,
    required this.konsumsiBuahSayur,
    required this.obatHipertensi,
    required this.riwayatGulaDarah,
    required this.riwayatKeluargaDM,
  });

  // ── Derived ──

  /// IMT (Indeks Massa Tubuh).
  double get imt {
    final tinggiM = tinggiCm / 100;
    return beratKg / (tinggiM * tinggiM);
  }

  // ── Scoring ──

  /// Hitung total skor FINDRISC dari 8 variabel.
  int get totalSkor {
    return _skorUsia +
        _skorImt +
        _skorLingkarPinggang +
        _skorAktivitasFisik +
        _skorKonsumsiBuahSayur +
        _skorObatHipertensi +
        _skorRiwayatGulaDarah +
        _skorRiwayatKeluargaDM;
  }

  int get _skorUsia {
    switch (ageGroup) {
      case '< 45 tahun':
        return 0;
      case '45 - 54 tahun':
        return 2;
      case '55 - 64 tahun':
        return 3;
      case '> 64 tahun':
        return 4;
      default:
        return 0;
    }
  }

  int get _skorImt {
    final bmi = imt;
    if (bmi < 25) return 0;
    if (bmi <= 30) return 1;
    return 3;
  }

  int get _skorLingkarPinggang {
    if (lingkarPinggangCm < 80) return 0;
    if (lingkarPinggangCm <= 88) return 1;
    return 4;
  }

  int get _skorAktivitasFisik {
    return aktivitasFisik == 'Tidak' ? 2 : 0;
  }

  int get _skorKonsumsiBuahSayur {
    return konsumsiBuahSayur == 'Tidak setiap hari' ? 1 : 0;
  }

  int get _skorObatHipertensi {
    return obatHipertensi == 'Iya' ? 2 : 0;
  }

  int get _skorRiwayatGulaDarah {
    return riwayatGulaDarah == 'Iya' ? 5 : 0;
  }

  int get _skorRiwayatKeluargaDM {
    switch (riwayatKeluargaDM) {
      case 'Iya, kakek/nenek, paman, bibi, atau sepupu':
        return 3;
      case 'Iya, orang tua, saudara kandung, atau anak':
        return 5;
      default:
        return 0;
    }
  }

  // ── Kategori Risiko ──

  /// Kategori risiko berdasarkan total skor.
  String get kategori {
    if (totalSkor < 7) return 'Rendah';
    if (totalSkor <= 11) return 'Sedikit Meningkat';
    if (totalSkor <= 14) return 'Sedang';
    if (totalSkor <= 20) return 'Tinggi';
    return 'Sangat Tinggi';
  }

  /// Estimasi persentase risiko 10 tahun ke depan.
  String get probabilitas {
    if (totalSkor < 7) return '1% (1 dari 100 orang)';
    if (totalSkor <= 11) return '4% (1 dari 25 orang)';
    if (totalSkor <= 14) return '17% (1 dari 6 orang)';
    if (totalSkor <= 20) return '33% (1 dari 3 orang)';
    return '50% (1 dari 2 orang)';
  }

  /// Rekomendasi berdasarkan kategori risiko.
  String get rekomendasi {
    if (totalSkor < 7) {
      return 'Pertahankan gaya hidup sehat Anda saat ini. '
          'Tetap aktif bergerak dan konsumsi makanan bernutrisi seimbang.';
    }
    if (totalSkor <= 11) {
      return 'Mulailah lebih memperhatikan pola makan dan '
          'tingkatkan durasi olahraga. '
          'Batasi konsumsi gula berlebih dan makanan olahan.';
    }
    if (totalSkor <= 14) {
      return 'Disarankan untuk melakukan konsultasi dengan tenaga medis. '
          'Pertimbangkan untuk melakukan pemeriksaan gula darah berkala '
          '(GDS/GDP) dan mulailah program penurunan berat badan '
          'jika IMT berlebih.';
    }
    if (totalSkor <= 20) {
      return 'Anda sangat disarankan untuk memeriksakan diri ke dokter '
          'atau fasilitas kesehatan terdekat untuk tes darah laboratorium '
          '(seperti HbA1c atau Tes Toleransi Glukosa Oral). '
          'Intervensi gaya hidup secara intensif sangat diperlukan.';
    }
    return 'Segera jadwalkan pertemuan dengan dokter. '
        'Diperlukan evaluasi klinis menyeluruh untuk mendeteksi '
        'kemungkinan diabetes yang belum terdiagnosis atau kondisi '
        'prediabetes, serta penanganan medis dan perubahan gaya '
        'hidup secara radikal.';
  }

  /// Daftar faktor risiko positif (yang menyumbang skor > 0).
  List<FaktorRisiko> get faktorPositif {
    final factors = <FaktorRisiko>[];

    if (_skorUsia > 0) {
      factors.add(
        FaktorRisiko(
          label: 'Usia',
          detail: 'Usia Anda ($ageGroup) termasuk kategori berisiko.',
          poin: _skorUsia,
        ),
      );
    }
    if (_skorImt > 0) {
      factors.add(
        FaktorRisiko(
          label: 'Indeks Massa Tubuh (IMT)',
          detail:
              'IMT Anda sebesar ${imt.toStringAsFixed(1)} berada di atas batas normal.',
          poin: _skorImt,
        ),
      );
    }
    if (_skorLingkarPinggang > 0) {
      factors.add(
        FaktorRisiko(
          label: 'Lingkar Perut',
          detail:
              'Lingkar pinggang Anda (${lingkarPinggangCm.toInt()} cm) melebihi batas yang disarankan.',
          poin: _skorLingkarPinggang,
        ),
      );
    }
    if (_skorAktivitasFisik > 0) {
      factors.add(
        FaktorRisiko(
          label: 'Aktivitas Fisik',
          detail:
              'Kurangnya aktivitas fisik dapat meningkatkan risiko resistensi insulin.',
          poin: _skorAktivitasFisik,
        ),
      );
    }
    if (_skorKonsumsiBuahSayur > 0) {
      factors.add(
        FaktorRisiko(
          label: 'Pola Makan',
          detail:
              'Konsumsi sayur, buah, atau beri yang tidak setiap hari dapat memengaruhi risiko.',
          poin: _skorKonsumsiBuahSayur,
        ),
      );
    }
    if (_skorObatHipertensi > 0) {
      factors.add(
        FaktorRisiko(
          label: 'Tekanan Darah Tinggi',
          detail:
              'Riwayat hipertensi merupakan salah satu faktor risiko diabetes.',
          poin: _skorObatHipertensi,
        ),
      );
    }
    if (_skorRiwayatGulaDarah > 0) {
      factors.add(
        FaktorRisiko(
          label: 'Gula Darah Tinggi',
          detail:
              'Pernah memiliki kadar gula darah tinggi menjadi indikator penting yang perlu diwaspadai.',
          poin: _skorRiwayatGulaDarah,
        ),
      );
    }
    if (_skorRiwayatKeluargaDM > 0) {
      factors.add(
        FaktorRisiko(
          label: 'Riwayat Keluarga',
          detail:
              'Adanya riwayat diabetes dalam keluarga meningkatkan kerentanan genetik Anda.',
          poin: _skorRiwayatKeluargaDM,
        ),
      );
    }

    return factors;
  }
}

/// Model for a single risk factor with its point contribution.
class FaktorRisiko {
  final String label;
  final String detail;
  final int poin;

  const FaktorRisiko({
    required this.label,
    required this.detail,
    required this.poin,
  });
}
