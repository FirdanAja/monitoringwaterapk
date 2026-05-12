class SensorData {
  final double ph;
  final double turbidity;
  final double temperature;
  final DateTime timestamp;
  final WaterQualityStatus status;
  final String fuzzyResult;
  final double qualityScore;

  SensorData({
    required this.ph,
    required this.turbidity,
    required this.temperature,
    required this.timestamp,
    required this.status,
    required this.fuzzyResult,
    required this.qualityScore,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      ph: (json['ph'] as num).toDouble(),
      turbidity: (json['turbidity'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      status: WaterQualityStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'unknown'),
        orElse: () => WaterQualityStatus.unknown,
      ),
      fuzzyResult: json['fuzzyResult'] ?? '',
      qualityScore: (json['qualityScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ph': ph,
      'turbidity': turbidity,
      'temperature': temperature,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'fuzzyResult': fuzzyResult,
      'qualityScore': qualityScore,
    };
  }

  SensorData copyWith({
    double? ph,
    double? turbidity,
    double? temperature,
    DateTime? timestamp,
    WaterQualityStatus? status,
    String? fuzzyResult,
    double? qualityScore,
  }) {
    return SensorData(
      ph: ph ?? this.ph,
      turbidity: turbidity ?? this.turbidity,
      temperature: temperature ?? this.temperature,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      fuzzyResult: fuzzyResult ?? this.fuzzyResult,
      qualityScore: qualityScore ?? this.qualityScore,
    );
  }
}

enum WaterQualityStatus { drinkable, usable, notDrinkable, unknown }

extension WaterQualityStatusExtension on WaterQualityStatus {
  String get label {
    switch (this) {
      case WaterQualityStatus.drinkable:
        return 'Aman';
      case WaterQualityStatus.usable:
        return 'Waspada';
      case WaterQualityStatus.notDrinkable:
        return 'Bahaya';
      case WaterQualityStatus.unknown:
        return 'Tidak Diketahui';
    }
  }
}

class MonthlyReport {
  final int year;
  final int month;
  final double avgPh;
  final double avgTurbidity;
  final double avgTemperature;
  final double avgQualityScore;
  final int totalReadings;
  final int goodCount;
  final int moderateCount;
  final int poorCount;
  final int dangerCount;
  final List<SensorData> dailyData;

  MonthlyReport({
    required this.year,
    required this.month,
    required this.avgPh,
    required this.avgTurbidity,
    required this.avgTemperature,
    required this.avgQualityScore,
    required this.totalReadings,
    required this.goodCount,
    required this.moderateCount,
    required this.poorCount,
    required this.dangerCount,
    required this.dailyData,
  });

  String get monthName {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }

  WaterQualityStatus get overallStatus {
    if (avgQualityScore >= 75) return WaterQualityStatus.drinkable;
    if (avgQualityScore >= 35) return WaterQualityStatus.usable;
    return WaterQualityStatus.notDrinkable;
  }
}
