import '../models/sensor_data.dart';

/// Implementasi Fuzzy Logic Mamdani untuk menentukan kualitas air
/// Variabel input: pH, Turbidity (kekeruhan), Temperature (suhu)
/// Variabel output: water quality score (0-100)
class FuzzyMamdaniService {
  // ============================================================
  // FUNGSI KEANGGOTAAN pH (6.5 - 8.5 standar PDAM)
  // ============================================================

  /// pH sangat asam: [0, 5] -> 1, [5, 6.5] -> turun ke 0
  double _phVeryAcidic(double ph) {
    if (ph <= 4.0) return 1.0;
    if (ph <= 6.0) return (6.0 - ph) / 2.0;
    return 0.0;
  }

  /// pH asam: [5.5, 6.5] -> naik ke 1, [6.5, 7.0] -> turun ke 0
  double _phAcidic(double ph) {
    if (ph <= 5.5) return 0.0;
    if (ph <= 6.0) return (ph - 5.5) / 0.5;
    if (ph <= 6.5) return 1.0;
    if (ph <= 7.0) return (7.0 - ph) / 0.5;
    return 0.0;
  }

  /// pH netral/normal: [6.5, 7.0] -> naik ke 1, [7.0, 8.0] = 1, [8.0, 8.5] -> turun ke 0
  double _phNormal(double ph) {
    if (ph <= 6.5) return 0.0;
    if (ph <= 7.0) return (ph - 6.5) / 0.5;
    if (ph <= 7.5) return 1.0;
    if (ph <= 8.5) return (8.5 - ph) / 1.0;
    return 0.0;
  }

  /// pH basa: [7.5, 8.5] -> naik ke 1, [8.5, 9.0] -> turun ke 0
  double _phAlkaline(double ph) {
    if (ph <= 7.5) return 0.0;
    if (ph <= 8.0) return (ph - 7.5) / 0.5;
    if (ph <= 8.5) return 1.0;
    if (ph <= 9.5) return (9.5 - ph) / 1.0;
    return 0.0;
  }

  /// pH sangat basa: [8.5, 9.5] -> naik ke 1, [9.5+] = 1
  double _phVeryAlkaline(double ph) {
    if (ph <= 8.5) return 0.0;
    if (ph <= 9.5) return (ph - 8.5) / 1.0;
    return 1.0;
  }

  // ============================================================
  // FUNGSI KEANGGOTAAN TURBIDITY (kekeruhan) dalam NTU
  // Standar WHO: < 1 NTU ideal, < 5 NTU batas
  // ============================================================

  /// Sangat jernih: [0, 1] = 1, [1, 3] -> turun ke 0
  double _turbJernih(double ntu) {
    if (ntu <= 1.0) return 1.0;
    if (ntu <= 3.0) return (3.0 - ntu) / 2.0;
    return 0.0;
  }

  /// Agak keruh: [1, 3] -> naik ke 1, [3, 7] -> turun ke 0
  double _turbAgakKeruh(double ntu) {
    if (ntu <= 1.0) return 0.0;
    if (ntu <= 3.0) return (ntu - 1.0) / 2.0;
    if (ntu <= 5.0) return 1.0;
    if (ntu <= 7.0) return (7.0 - ntu) / 2.0;
    return 0.0;
  }

  /// Keruh: [5, 7] -> naik ke 1, [7, 15] -> turun ke 0
  double _turbKeruh(double ntu) {
    if (ntu <= 5.0) return 0.0;
    if (ntu <= 7.0) return (ntu - 5.0) / 2.0;
    if (ntu <= 10.0) return 1.0;
    if (ntu <= 15.0) return (15.0 - ntu) / 5.0;
    return 0.0;
  }

  /// Sangat keruh: [10, 15] -> naik ke 1, [15+] = 1
  double _turbSangatKeruh(double ntu) {
    if (ntu <= 10.0) return 0.0;
    if (ntu <= 15.0) return (ntu - 10.0) / 5.0;
    return 1.0;
  }

  // ============================================================
  // FUNGSI KEANGGOTAAN TEMPERATURE (suhu) dalam °C
  // Standar air minum: 10-26°C
  // ============================================================

  /// Sangat dingin: <= 10°C
  double _tempSangatDingin(double temp) {
    if (temp <= 10.0) return 1.0;
    if (temp <= 15.0) return (15.0 - temp) / 5.0;
    return 0.0;
  }

  /// Dingin: [10, 18] -> naik ke 1, [18, 22] -> turun ke 0
  double _tempDingin(double temp) {
    if (temp <= 10.0) return 0.0;
    if (temp <= 15.0) return (temp - 10.0) / 5.0;
    if (temp <= 18.0) return 1.0;
    if (temp <= 22.0) return (22.0 - temp) / 4.0;
    return 0.0;
  }

  /// Normal: [18, 22] -> naik ke 1, [22, 26] = 1, [26, 28] -> turun ke 0
  double _tempNormal(double temp) {
    if (temp <= 18.0) return 0.0;
    if (temp <= 22.0) return (temp - 18.0) / 4.0;
    if (temp <= 25.0) return 1.0;
    if (temp <= 28.0) return (28.0 - temp) / 3.0;
    return 0.0;
  }

  /// Hangat: [25, 28] -> naik ke 1, [28, 33] -> turun ke 0
  double _tempHangat(double temp) {
    if (temp <= 25.0) return 0.0;
    if (temp <= 28.0) return (temp - 25.0) / 3.0;
    if (temp <= 30.0) return 1.0;
    if (temp <= 33.0) return (33.0 - temp) / 3.0;
    return 0.0;
  }

  /// Panas: >= 30°C
  double _tempPanas(double temp) {
    if (temp <= 28.0) return 0.0;
    if (temp <= 33.0) return (temp - 28.0) / 5.0;
    return 1.0;
  }

  // ============================================================
  // OUTPUT MEMBERSHIP FUNCTIONS (Quality Score 0-100)
  // ============================================================

  Map<String, double> _getOutputCentroids() {
    return {
      'sangatBuruk': 10.0,
      'buruk': 30.0,
      'cukup': 50.0,
      'baik': 70.0,
      'sangatBaik': 90.0,
    };
  }

  // ============================================================
  // RULE BASE (Fuzzy Rules Mamdani)
  // ============================================================

  Map<String, double> _applyRules(
    double ph,
    double turbidity,
    double temperature,
  ) {
    // Hitung derajat keanggotaan input
    final phVAcidic = _phVeryAcidic(ph);
    final phAcidic = _phAcidic(ph);
    final phNormal = _phNormal(ph);
    final phAlkaline = _phAlkaline(ph);
    final phVAlkaline = _phVeryAlkaline(ph);

    final tJernih = _turbJernih(turbidity);
    final tAgakKeruh = _turbAgakKeruh(turbidity);
    final tKeruh = _turbKeruh(turbidity);
    final tSangatKeruh = _turbSangatKeruh(turbidity);

    final tempSDingin = _tempSangatDingin(temperature);
    final tempDingin = _tempDingin(temperature);
    final tempNormal = _tempNormal(temperature);
    final tempHangat = _tempHangat(temperature);
    final tempPanas = _tempPanas(temperature);

    // Akumulasi output fuzzy
    Map<String, double> output = {
      'sangatBuruk': 0.0,
      'buruk': 0.0,
      'cukup': 0.0,
      'baik': 0.0,
      'sangatBaik': 0.0,
    };

    void applyRule(double strength, String outputTerm) {
      if (output[outputTerm]! < strength) {
        output[outputTerm] = strength;
      }
    }

    // ---- RULES: pH Normal + Jernih = Kondisi terbaik ----
    applyRule(_min([phNormal, tJernih, tempNormal]), 'sangatBaik');
    applyRule(_min([phNormal, tJernih, tempDingin]), 'sangatBaik');
    applyRule(_min([phNormal, tJernih, tempHangat]), 'baik');
    applyRule(_min([phNormal, tJernih, tempSDingin]), 'cukup');
    applyRule(_min([phNormal, tJernih, tempPanas]), 'cukup');

    // ---- RULES: pH Normal + Agak Keruh ----
    applyRule(_min([phNormal, tAgakKeruh, tempNormal]), 'baik');
    applyRule(_min([phNormal, tAgakKeruh, tempDingin]), 'baik');
    applyRule(_min([phNormal, tAgakKeruh, tempHangat]), 'cukup');
    applyRule(_min([phNormal, tAgakKeruh, tempSDingin]), 'cukup');
    applyRule(_min([phNormal, tAgakKeruh, tempPanas]), 'buruk');

    // ---- RULES: pH Normal + Keruh ----
    applyRule(_min([phNormal, tKeruh, tempNormal]), 'cukup');
    applyRule(_min([phNormal, tKeruh, tempDingin]), 'cukup');
    applyRule(_min([phNormal, tKeruh, tempHangat]), 'buruk');
    applyRule(_min([phNormal, tKeruh, tempPanas]), 'buruk');

    // ---- RULES: pH Normal + Sangat Keruh ----
    applyRule(_min([phNormal, tSangatKeruh, tempNormal]), 'buruk');
    applyRule(_min([phNormal, tSangatKeruh, tempDingin]), 'buruk');
    applyRule(_min([phNormal, tSangatKeruh, tempHangat]), 'sangatBuruk');
    applyRule(_min([phNormal, tSangatKeruh, tempPanas]), 'sangatBuruk');

    // ---- RULES: pH Asam ----
    applyRule(_min([phAcidic, tJernih, tempNormal]), 'baik');
    applyRule(_min([phAcidic, tJernih, tempDingin]), 'cukup');
    applyRule(_min([phAcidic, tAgakKeruh, tempNormal]), 'cukup');
    applyRule(_min([phAcidic, tAgakKeruh, tempHangat]), 'buruk');
    applyRule(_min([phAcidic, tKeruh]), 'buruk');
    applyRule(_min([phAcidic, tSangatKeruh]), 'sangatBuruk');

    // ---- RULES: pH Basa ----
    applyRule(_min([phAlkaline, tJernih, tempNormal]), 'baik');
    applyRule(_min([phAlkaline, tJernih, tempDingin]), 'cukup');
    applyRule(_min([phAlkaline, tAgakKeruh, tempNormal]), 'cukup');
    applyRule(_min([phAlkaline, tAgakKeruh, tempHangat]), 'buruk');
    applyRule(_min([phAlkaline, tKeruh]), 'buruk');
    applyRule(_min([phAlkaline, tSangatKeruh]), 'sangatBuruk');

    // ---- RULES: pH Sangat Asam/Sangat Basa (berbahaya) ----
    applyRule(phVAcidic, 'sangatBuruk');
    applyRule(phVAlkaline, 'sangatBuruk');
    applyRule(_min([phVAcidic, tJernih]), 'buruk');
    applyRule(_min([phVAlkaline, tJernih]), 'buruk');

    // ---- RULES: Suhu ekstrem ----
    applyRule(_min([tempSDingin, tSangatKeruh]), 'sangatBuruk');
    applyRule(_min([tempPanas, tSangatKeruh]), 'sangatBuruk');
    applyRule(_min([tempSDingin, tKeruh]), 'buruk');
    applyRule(_min([tempPanas, tKeruh]), 'buruk');

    return output;
  }

  double _min(List<double> values) {
    double min = values[0];
    for (final v in values) {
      if (v < min) min = v;
    }
    return min;
  }

  // ============================================================
  // DEFUZZIFIKASI (Metode Centroid / Center of Gravity)
  // ============================================================

  FuzzyResult evaluate(double ph, double turbidity, double temperature) {
    final ruleOutput = _applyRules(ph, turbidity, temperature);
    final centroids = _getOutputCentroids();

    double numerator = 0.0;
    double denominator = 0.0;

    ruleOutput.forEach((term, strength) {
      final centroid = centroids[term]!;
      numerator += strength * centroid;
      denominator += strength;
    });

    final double qualityScore =
        denominator == 0.0 ? 0.0 : numerator / denominator;

    // Tentukan status berdasarkan skor
    WaterQualityStatus status;
    String statusLabel;

    if (qualityScore >= 75) {
      status = WaterQualityStatus.drinkable;
      statusLabel = 'Layak Minum';
    } else if (qualityScore >= 35) {
      status = WaterQualityStatus.usable;
      statusLabel = 'Layak Tidak Minum';
    } else {
      status = WaterQualityStatus.notDrinkable;
      statusLabel = 'Tidak Layak Minum';
    }

    // Detail diagnosis
    final diagnosis = _buildDiagnosis(ph, turbidity, temperature);
    final recommendation = _buildRecommendation(
      status,
      ph,
      turbidity,
      temperature,
    );

    return FuzzyResult(
      qualityScore: qualityScore,
      status: status,
      statusLabel: statusLabel,
      diagnosis: diagnosis,
      recommendation: recommendation,
      membershipDegrees: {
        'sangatBuruk': ruleOutput['sangatBuruk']!,
        'buruk': ruleOutput['buruk']!,
        'cukup': ruleOutput['cukup']!,
        'baik': ruleOutput['baik']!,
        'sangatBaik': ruleOutput['sangatBaik']!,
      },
    );
  }

  String _buildDiagnosis(double ph, double turbidity, double temperature) {
    final List<String> issues = [];

    if (ph < 6.5) {
      issues.add('pH terlalu asam (${ph.toStringAsFixed(2)})');
    } else if (ph > 8.5) {
      issues.add('pH terlalu basa (${ph.toStringAsFixed(2)})');
    }

    if (turbidity > 5) {
      issues.add(
        'kekeruhan melebihi batas (${turbidity.toStringAsFixed(1)} NTU)',
      );
    }

    if (temperature < 10) {
      issues.add('suhu terlalu dingin (${temperature.toStringAsFixed(1)}°C)');
    } else if (temperature > 30) {
      issues.add('suhu terlalu panas (${temperature.toStringAsFixed(1)}°C)');
    }

    if (issues.isEmpty) {
      return 'Semua parameter dalam batas normal';
    }
    return 'Terdeteksi: ${issues.join(', ')}';
  }

  String _buildRecommendation(
    WaterQualityStatus status,
    double ph,
    double turbidity,
    double temperature,
  ) {
    switch (status) {
      case WaterQualityStatus.drinkable:
        return 'Air sangat bersih dan memenuhi standar. Aman untuk diminum.';
      case WaterQualityStatus.usable:
        return 'Air cukup bersih untuk kebutuhan MCK, namun tidak disarankan untuk diminum.';
      case WaterQualityStatus.notDrinkable:
        return '⚠️ Air kotor! Tidak aman digunakan baik untuk mandi maupun diminum.';
      case WaterQualityStatus.unknown:
        return 'Data tidak mencukupi untuk analisis.';
    }
  }
}

class FuzzyResult {
  final double qualityScore;
  final WaterQualityStatus status;
  final String statusLabel;
  final String diagnosis;
  final String recommendation;
  final Map<String, double> membershipDegrees;

  FuzzyResult({
    required this.qualityScore,
    required this.status,
    required this.statusLabel,
    required this.diagnosis,
    required this.recommendation,
    required this.membershipDegrees,
  });
}
