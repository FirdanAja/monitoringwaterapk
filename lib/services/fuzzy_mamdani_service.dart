import '../models/sensor_data.dart';

class FuzzyMamdaniService {
  double _phAsam(double ph, double phMin) {
    if (ph <= phMin - 1.0) return 1.0;
    if (ph <= phMin) return (phMin - ph) / 1.0;
    return 0.0;
  }

  double _phNormal(double ph, double phMin, double phMax) {
    if (ph <= phMin - 1.0 || ph >= phMax + 1.0) return 0.0;
    if (ph <= phMin) return (ph - (phMin - 1.0)) / 1.0;
    if (ph >= phMin && ph <= phMax) return 1.0;
    if (ph <= phMax + 1.0) return ((phMax + 1.0) - ph) / 1.0;
    return 0.0;
  }

  double _phBasa(double ph, double phMax) {
    if (ph <= phMax) return 0.0;
    if (ph <= phMax + 1.0) return (ph - phMax) / 1.0;
    return 1.0;
  }

  double _turbBersih(double ntu, double turbMax) {
    if (ntu <= 5.0) return 1.0;
    if (ntu <= 7.0) return (7.0 - ntu) / 2.0;
    return 0.0;
  }

  double _turbAgakKeruh(double ntu, double turbMax) {
    if (ntu <= 5.0 || ntu >= 25.0) return 0.0;
    if (ntu <= 15.0) return (ntu - 5.0) / 10.0;
    return (25.0 - ntu) / 10.0;
  }

  double _turbKeruh(double ntu, double turbMax) {
    if (ntu <= 20.0) return 0.0;
    if (ntu < 25.0) return (ntu - 20.0) / 5.0;
    return 1.0;
  }

  double _tempDingin(double temp) {
    if (temp <= 18.0) return 1.0;
    if (temp <= 22.0) return (22.0 - temp) / 4.0;
    return 0.0;
  }

  double _tempSedang(double temp) {
    if (temp <= 18.0) return 0.0;
    if (temp <= 22.0) return (temp - 18.0) / 4.0;
    if (temp <= 28.0) return 1.0;
    if (temp <= 32.0) return (32.0 - temp) / 4.0;
    return 0.0;
  }

  double _tempTinggi(double temp) {
    if (temp <= 28.0) return 0.0;
    if (temp <= 32.0) return (temp - 28.0) / 4.0;
    return 1.0;
  }

  Map<String, double> _getOutputCentroids() {
    return {
      'sangatBuruk': 10.0,
      'buruk': 30.0,
      'cukup': 50.0,
      'baik': 75.0,
      'sangatBaik': 95.0,
    };
  }

  Map<String, double> _applyRules({
    required double ph,
    required double turbidity,
    required double temperature,
    required double phMin,
    required double phMax,
    required double turbMax,
  }) {
    final phAsam = _phAsam(ph, phMin);
    final phNormal = _phNormal(ph, phMin, phMax);
    final phBasa = _phBasa(ph, phMax);

    final tBersih = _turbBersih(turbidity, turbMax);
    final tAgakKeruh = _turbAgakKeruh(turbidity, turbMax);
    final tKeruh = _turbKeruh(turbidity, turbMax);

    final tempDingin = _tempDingin(temperature);
    final tempSedang = _tempSedang(temperature);
    final tempTinggi = _tempTinggi(temperature);

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

    applyRule(_min([tBersih, phNormal, tempSedang]), 'sangatBaik');
    applyRule(_min([tBersih, phNormal, tempDingin]), 'sangatBaik');
    applyRule(_min([tBersih, phNormal, tempTinggi]), 'sangatBaik');
    applyRule(_min([tBersih, phAsam]), 'sangatBaik');
    applyRule(_min([tBersih, phBasa]), 'sangatBaik');

    applyRule(_min([tAgakKeruh, tempSedang]), 'cukup');
    applyRule(_min([tAgakKeruh, tempDingin]), 'cukup');
    applyRule(_min([tAgakKeruh, tempTinggi]), 'cukup');
    applyRule(_min([tAgakKeruh, phNormal]), 'cukup');

    applyRule(tKeruh, 'buruk');
    applyRule(_min([tKeruh, phAsam]), 'sangatBuruk');
    applyRule(_min([tKeruh, phBasa]), 'sangatBuruk');

    return output;
  }

  double _min(List<double> values) {
    double min = values[0];
    for (final v in values) {
      if (v < min) min = v;
    }
    return min;
  }

  FuzzyResult evaluate(
    double ph,
    double turbidity,
    double temperature, {
    double phMin = 6.5,
    double phMax = 8.5,
    double turbMax = 25.0,
  }) {
    final ruleOutput = _applyRules(
      ph: ph,
      turbidity: turbidity,
      temperature: temperature,
      phMin: phMin,
      phMax: phMax,
      turbMax: turbMax,
    );
    final centroids = _getOutputCentroids();

    double numerator = 0.0;
    double denominator = 0.0;

    ruleOutput.forEach((term, strength) {
      final centroid = centroids[term]!;
      numerator += strength * centroid;
      denominator += strength;
    });

    double qualityScore = denominator == 0.0 ? 0.0 : numerator / denominator;

    WaterQualityStatus status;
    String statusLabel;

    if (qualityScore >= 70) {
      status = WaterQualityStatus.drinkable;
      statusLabel = 'Aman';
    } else if (qualityScore >= 35) {
      status = WaterQualityStatus.usable;
      statusLabel = 'Waspada';
    } else {
      status = WaterQualityStatus.notDrinkable;
      statusLabel = 'Bahaya';
    }

    // --- HARD OVERRIDE TURBIDITY ---
    // Memaksa status berdasarkan batas mutlak Kekeruhan (NTU)
    if (turbidity > 25.0) {
      status = WaterQualityStatus.notDrinkable;
      statusLabel = 'Bahaya';
      if (qualityScore >= 35) {
        qualityScore = 34.0; // Turunkan score ke Bahaya
      }
    } else if (turbidity > 5.0) {
      if (status == WaterQualityStatus.drinkable) {
        status = WaterQualityStatus.usable;
        statusLabel = 'Waspada';
        if (qualityScore >= 70) {
          qualityScore = 69.0; // Turunkan score ke Waspada
        }
      }
    }

    final diagnosis =
        _buildDiagnosis(ph, turbidity, temperature, phMin, phMax, turbMax);
    final recommendation =
        _buildRecommendation(status, ph, turbidity, temperature);

    return FuzzyResult(
      qualityScore: qualityScore,
      status: status,
      statusLabel: statusLabel,
      diagnosis: diagnosis,
      recommendation: recommendation,
      membershipDegrees: ruleOutput,
    );
  }

  String _buildDiagnosis(double ph, double turbidity, double temperature,
      double phMin, double phMax, double turbMax) {
    String pHCat = ph < phMin ? 'Asam' : (ph > phMax ? 'Basa' : 'Normal');
    String turbCat = turbidity < turbMax * 0.5
        ? 'Bersih'
        : (turbidity < turbMax ? 'Agak Keruh' : 'Keruh');
    String tempCat =
        temperature < 20 ? 'Dingin' : (temperature < 30 ? 'Sedang' : 'Tinggi');

    return 'Kondisi: pH $pHCat, Kekeruhan $turbCat, Suhu $tempCat';
  }

  String _buildRecommendation(
    WaterQualityStatus status,
    double ph,
    double turbidity,
    double temperature,
  ) {
    switch (status) {
      case WaterQualityStatus.drinkable:
        return 'Kualitas air sangat baik. Aman digunakan untuk kebutuhan sehari-hari.';
      case WaterQualityStatus.usable:
        return 'Kualitas air normal. Masih bisa digunakan untuk MCK.';
      case WaterQualityStatus.notDrinkable:
        return '⚠️ Air tercemar! Hindari penggunaan untuk konsumsi atau mandi.';
      default:
        return 'Menganalisis data...';
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
