import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sensor_data.dart';
import '../services/fuzzy_mamdani_service.dart';
import '../services/notification_service.dart';

enum ConnectionStatus { disconnected, connected }

class SensorProvider extends ChangeNotifier {
  final FuzzyMamdaniService _fuzzyService = FuzzyMamdaniService();
  final NotificationService _notificationService = NotificationService();

  // Current data
  SensorData? _currentData;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  bool _isLoading = false;
  FuzzyResult? _lastFuzzyResult;

  // Historical data
  List<SensorData> _historyData = [];
  List<SensorData> _filteredHistory = [];

  // Settings
  bool _notificationsEnabled = true;

  // Thresholds (Dynamic Configuration)
  double _phMin = 6.5;
  double _phMax = 8.5;
  double _turbMax = 5.0;
  double _tempMin = 10.0;
  double _tempMax = 30.0;

  // Getters (Termasuk dummy MQTT untuk mencegah IDE error dari cache lama)
  SensorData? get currentData => _currentData;
  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isLoading => _isLoading;
  FuzzyResult? get lastFuzzyResult => _lastFuzzyResult;
  List<SensorData> get historyData => _historyData;
  List<SensorData> get filteredHistory => _filteredHistory;
  bool get notificationsEnabled => _notificationsEnabled;
  double get phMin => _phMin;
  double get phMax => _phMax;
  double get turbMax => _turbMax;
  double get tempMin => _tempMin;
  double get tempMax => _tempMax;
  String get mqttBroker => ''; // Deprecated
  int get mqttPort => 1883; // Deprecated

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _notificationService.initialize();
    await _loadSettings();
    await _loadHistoryFromPrefs();

    // Gunakan dummy data karena alat belum ada
    _startDummyStream();

    _isLoading = false;
    notifyListeners();
  }

  void _startDummyStream() {
    _connectionStatus = ConnectionStatus.connected;
    notifyListeners();

    // Timer untuk simulasi data setiap 3 detik
    Stream.periodic(const Duration(seconds: 3)).listen((_) {
      final double ph = 6.5 + (DateTime.now().millisecond % 100) / 50; // Range 6.5 - 8.5
      final double turbidity = (DateTime.now().second % 10).toDouble(); // Range 0 - 10 NTU
      final double temperature = 24.0 + (DateTime.now().second % 5); // Range 24 - 29 C

      final fuzzyResult = _fuzzyService.evaluate(ph, turbidity, temperature);
      
      final newData = SensorData(
        ph: ph,
        turbidity: turbidity,
        temperature: temperature,
        timestamp: DateTime.now(),
        status: _mapStatusToEnum(fuzzyResult.statusLabel),
        fuzzyResult: fuzzyResult.statusLabel,
        qualityScore: fuzzyResult.qualityScore,
      );

      _onSensorDataReceived(newData, fuzzyResult);
    });
  }

  void _startFirebaseStream() {
    // Dimatikan sementara sesuai permintaan user
    /*
    _connectionStatus = ConnectionStatus.connected;
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        // Membaca nilai dari Firebase dengan fallback default
        final double ph = (data['ph'] ?? 7.0).toDouble();
        final double turbidity = (data['turbidity'] ?? 0.0).toDouble();
        final double temperature = (data['temperature'] ?? 25.0).toDouble();

        // Evaluasi fuzzy
        final fuzzyResult = _fuzzyService.evaluate(ph, turbidity, temperature);
        
        // Buat objek SensorData
        final newData = SensorData(
          ph: ph,
          turbidity: turbidity,
          temperature: temperature,
          timestamp: DateTime.now(), // Memakai waktu penerimaan di hp
          status: _mapStatusToEnum(fuzzyResult.statusLabel),
          fuzzyResult: fuzzyResult.statusLabel,
          qualityScore: fuzzyResult.qualityScore,
        );

        _onSensorDataReceived(newData, fuzzyResult);
      }
    }, onError: (error) {
       _connectionStatus = ConnectionStatus.disconnected;
       notifyListeners();
    });
    */
  }
  
  WaterQualityStatus _mapStatusToEnum(String statusLevel) {
    if (statusLevel.toLowerCase().contains("aman") || statusLevel.toLowerCase().contains("baik")) {
      return WaterQualityStatus.drinkable;
    } else if (statusLevel.toLowerCase().contains("waspada") || statusLevel.toLowerCase().contains("sedang")) {
      return WaterQualityStatus.usable;
    } else {
      return WaterQualityStatus.notDrinkable;
    }
  }

  void _onSensorDataReceived(SensorData data, FuzzyResult fuzzyResult) async {
    _currentData = data;
    _lastFuzzyResult = fuzzyResult;

    // Simpan ke history
    _historyData.insert(0, data);
    if (_historyData.length > 5000) {
      _historyData = _historyData.sublist(0, 5000);
    }
    _filteredHistory = _historyData;

    await _saveHistoryToPrefs();

    // Kirim notifikasi kalau notif diaktifkan dan air bahaya
    if (_notificationsEnabled &&
        (data.status == WaterQualityStatus.notDrinkable)) {
      await _notificationService.sendWaterQualityAlert(
        data: data,
        fuzzyResult: data.fuzzyResult,
      );
    }

    notifyListeners();
  }

  // Filter history berdasarkan tanggal
  void filterHistory({
    DateTime? from,
    DateTime? to,
    WaterQualityStatus? status,
  }) {
    _filteredHistory = _historyData.where((d) {
      bool match = true;
      if (from != null) match = match && d.timestamp.isAfter(from);
      if (to != null) match = match && d.timestamp.isBefore(to);
      if (status != null) match = match && d.status == status;
      return match;
    }).toList();
    notifyListeners();
  }

  void clearFilter() {
    _filteredHistory = _historyData;
    notifyListeners();
  }

  // Generate laporan bulanan
  MonthlyReport? generateMonthlyReport(int year, int month) {
    final monthData = _historyData.where((d) {
      return d.timestamp.year == year && d.timestamp.month == month;
    }).toList();

    if (monthData.isEmpty) return null;

    final avgPh =
        monthData.map((d) => d.ph).reduce((a, b) => a + b) / monthData.length;
    final avgTurbidity =
        monthData.map((d) => d.turbidity).reduce((a, b) => a + b) /
            monthData.length;
    final avgTemp =
        monthData.map((d) => d.temperature).reduce((a, b) => a + b) /
            monthData.length;
    final avgScore =
        monthData.map((d) => d.qualityScore).reduce((a, b) => a + b) /
            monthData.length;

    return MonthlyReport(
      year: year,
      month: month,
      avgPh: avgPh,
      avgTurbidity: avgTurbidity,
      avgTemperature: avgTemp,
      avgQualityScore: avgScore,
      totalReadings: monthData.length,
      goodCount: monthData
          .where((d) => d.status == WaterQualityStatus.drinkable)
          .length,
      moderateCount:
          monthData.where((d) => d.status == WaterQualityStatus.usable).length,
      poorCount: monthData
          .where((d) => d.status == WaterQualityStatus.notDrinkable)
          .length,
      dangerCount: 0,
      dailyData: monthData,
    );
  }

  // Get data per jam untuk grafik
  List<SensorData> getHourlyData({int hours = 24}) {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    return _historyData
        .where((d) => d.timestamp.isAfter(cutoff))
        .toList()
        .reversed
        .toList();
  }

  // Settings
  Future<void> updateSettings({
    String? broker, // Deprecated
    int? port, // Deprecated
    bool? notifications,
  }) async {
    if (notifications != null) _notificationsEnabled = notifications;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateThresholds({
    double? phMin,
    double? phMax,
    double? turbMax,
    double? tempMin,
    double? tempMax,
  }) async {
    if (phMin != null) _phMin = phMin;
    if (phMax != null) _phMax = phMax;
    if (turbMax != null) _turbMax = turbMax;
    if (tempMin != null) _tempMin = tempMin;
    if (tempMax != null) _tempMax = tempMax;

    await _saveSettings();
    notifyListeners();
  }

  Future<void> reconnect() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _startFirebaseStream();
    _isLoading = false;
    notifyListeners();
  }

  // Persistence
  Future<void> _saveHistoryToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Simpan hanya 200 terakhir untuk efisiensi
    final toSave = _historyData.take(200).toList();
    final jsonList = toSave.map((d) => jsonEncode(d.toJson())).toList();
    await prefs.setStringList('sensor_history', jsonList);
  }

  Future<void> _loadHistoryFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('sensor_history') ?? [];
    _historyData =
        jsonList.map((json) => SensorData.fromJson(jsonDecode(json))).toList();
    _filteredHistory = _historyData;
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setDouble('ph_min', _phMin);
    await prefs.setDouble('ph_max', _phMax);
    await prefs.setDouble('turb_max', _turbMax);
    await prefs.setDouble('temp_min', _tempMin);
    await prefs.setDouble('temp_max', _tempMax);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _phMin = prefs.getDouble('ph_min') ?? 6.5;
    _phMax = prefs.getDouble('ph_max') ?? 8.5;
    _turbMax = prefs.getDouble('turb_max') ?? 5.0;
    _tempMin = prefs.getDouble('temp_min') ?? 10.0;
    _tempMax = prefs.getDouble('temp_max') ?? 30.0;
  }

  void clearHistory() async {
    _historyData.clear();
    _filteredHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sensor_history');
    notifyListeners();
  }
}
