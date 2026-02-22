import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sensor_data.dart';
import '../services/mqtt_service.dart';
import '../services/fuzzy_mamdani_service.dart';
import '../services/notification_service.dart';

class SensorProvider extends ChangeNotifier {
  final MqttService _mqttService = MqttService();
  final FuzzyMamdaniService _fuzzyService = FuzzyMamdaniService();
  final NotificationService _notificationService = NotificationService();

  // Current data
  SensorData? _currentData;
  MqttConnectionStatus _connectionStatus = MqttConnectionStatus.disconnected;
  bool _isLoading = false;
  FuzzyResult? _lastFuzzyResult;

  // Historical data
  List<SensorData> _historyData = [];
  List<SensorData> _filteredHistory = [];

  // Settings
  String _mqttBroker = '192.168.1.100';
  int _mqttPort = 1883;
  bool _notificationsEnabled = true;

  // Getters
  SensorData? get currentData => _currentData;
  MqttConnectionStatus get connectionStatus => _connectionStatus;
  bool get isLoading => _isLoading;
  FuzzyResult? get lastFuzzyResult => _lastFuzzyResult;
  List<SensorData> get historyData => _historyData;
  List<SensorData> get filteredHistory => _filteredHistory;
  String get mqttBroker => _mqttBroker;
  int get mqttPort => _mqttPort;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _notificationService.initialize();
    await _loadSettings();
    await _loadHistoryFromPrefs();

    // MOCK DATA: Seed initial data if empty
    if (_historyData.isEmpty) {
      _currentData = SensorData(
        ph: 7.2,
        turbidity: 2.5,
        temperature: 24.5,
        timestamp: DateTime.now(),
        status: WaterQualityStatus.drinkable,
        fuzzyResult: 'Normal',
        qualityScore: 85.0,
      );
      _historyData.add(_currentData!);
    } else {
      _currentData = _historyData.first;
    }

    // Start mock data stream
    _startMockDataStream();

    _isLoading = false;
    notifyListeners();
  }

  void _startMockDataStream() {
    _connectionStatus = MqttConnectionStatus.connected;

    // Simulasikan data masuk setiap 5 detik
    Stream.periodic(const Duration(seconds: 5)).listen((_) {
      final random = DateTime.now().second % 3;
      final newData = SensorData(
        ph: 6.5 + (DateTime.now().second % 20) / 10.0,
        turbidity: 1.0 + (DateTime.now().minute % 10) / 2.0,
        temperature: 24.0 + (DateTime.now().second % 50) / 10.0,
        timestamp: DateTime.now(),
        status: random == 0
            ? WaterQualityStatus.drinkable
            : (random == 1
                ? WaterQualityStatus.usable
                : WaterQualityStatus.notDrinkable),
        fuzzyResult: 'Simulated',
        qualityScore: 50.0 + (DateTime.now().second % 40),
      );
      _onSensorDataReceived(newData);
    });
  }

  void _onSensorDataReceived(SensorData data) async {
    _currentData = data;
    _lastFuzzyResult = _fuzzyService.evaluate(
      data.ph,
      data.turbidity,
      data.temperature,
    );

    // Simpan ke history
    _historyData.insert(0, data);
    if (_historyData.length > 5000) {
      _historyData = _historyData.sublist(0, 5000);
    }
    _filteredHistory = _historyData;

    await _saveHistoryToPrefs();

    // Kirim notifikasi kalau notif diaktifkan
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
    String? broker,
    int? port,
    bool? notifications,
  }) async {
    if (broker != null) _mqttBroker = broker;
    if (port != null) _mqttPort = port;
    if (notifications != null) _notificationsEnabled = notifications;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> reconnect() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _startMockDataStream();
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
    await prefs.setString('mqtt_broker', _mqttBroker);
    await prefs.setInt('mqtt_port', _mqttPort);
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _mqttBroker = prefs.getString('mqtt_broker') ?? '192.168.1.100';
    _mqttPort = prefs.getInt('mqtt_port') ?? 1883;
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
  }

  void clearHistory() async {
    _historyData.clear();
    _filteredHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sensor_history');
    notifyListeners();
  }

  @override
  void dispose() {
    _mqttService.dispose();
    super.dispose();
  }
}
