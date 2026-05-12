import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';
import '../services/fuzzy_mamdani_service.dart';
import '../services/notification_service.dart';

enum ConnectionStatus { disconnected, connected }

class SensorProvider extends ChangeNotifier {
  final FuzzyMamdaniService _fuzzyService = FuzzyMamdaniService();
  final NotificationService _notificationService = NotificationService();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Current data
  SensorData? _currentData;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  bool _isLoading = false;
  FuzzyResult? _lastFuzzyResult;
  DateTime? _lastUpdateTime;
  StreamSubscription<DatabaseEvent>? _sensorSubscription;
  StreamSubscription<DatabaseEvent>? _statusSubscription;
  Timer? _heartbeatTimer;

  // Historical data
  List<SensorData> _historyData = [];
  List<SensorData> _filteredHistory = [];

  // Settings
  bool _notificationsEnabled = true;

  // Thresholds (Dynamic Configuration)
  double _phMin = 6.5;
  double _phMax = 8.5;
  double _turbMax = 25.0;
  double _tempMin = 10.0;
  double _tempMax = 30.0;

  // New detailed thresholds
  double _turbJernihLimit = 12.5;
  double _turbAgakKeruhLimit = 25.0;
  double _tempDinginLimit = 18.0;
  double _tempNormalLimit = 26.0;
  double _phAsamLimit = 6.0;
  double _phNormalLimit = 8.0;

  // Getters (Termasuk dummy MQTT untuk mencegah IDE error dari cache lama)
  SensorData? get currentData => _currentData;
  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isLoading => _isLoading;
  FuzzyResult? get lastFuzzyResult => _lastFuzzyResult;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  List<SensorData> get historyData => _historyData;
  List<SensorData> get filteredHistory => _filteredHistory;
  bool get notificationsEnabled => _notificationsEnabled;
  double get phMin => _phMin;
  double get phMax => _phMax;
  double get turbMax => _turbMax;
  double get tempMin => _tempMin;
  double get tempMax => _tempMax;
  
  // Getters for detailed thresholds
  double get turbJernihLimit => _turbJernihLimit;
  double get turbAgakKeruhLimit => _turbAgakKeruhLimit;
  double get tempDinginLimit => _tempDinginLimit;
  double get tempNormalLimit => _tempNormalLimit;
  double get phAsamLimit => _phAsamLimit;
  double get phNormalLimit => _phNormalLimit;
  String get mqttBroker => ''; // Deprecated
  int get mqttPort => 1883; // Deprecated

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _notificationService.initialize();
    await _loadSettings();
    await _loadHistoryFromPrefs();

    // Aktifkan Firebase Realtime Stream
    _startFirebaseStream();

    _isLoading = false;
    notifyListeners();
  }



  void _startFirebaseStream() {
    debugPrint('🔥 Starting Firebase Stream...');
    
    // Batalkan subscription lama jika ada
    _sensorSubscription?.cancel();
    _statusSubscription?.cancel();
    _heartbeatTimer?.cancel();
    
    // 1. Listen to Connection Status (Presence System)
    _statusSubscription = _database.child('monitoring/status/online').onValue.listen((event) {
      final bool isOnline = event.snapshot.value == true;
      debugPrint('📡 Device Online Status: $isOnline');
      
      if (!isOnline) {
        _connectionStatus = ConnectionStatus.disconnected;
        _notificationService.cancelAll(); // Stop notif & TTS saat terputus
        notifyListeners();
      } else {
        // If it says online, we still wait for real data to confirm
        _connectionStatus = ConnectionStatus.connected;
        notifyListeners();
      }
    });

    // 2. Listen to Sensor Data
    _database.child('monitoring/current').keepSynced(true);
    _sensorSubscription = _database.child('monitoring/current').onValue.listen((event) {
      debugPrint('\n📥 Firebase Data Received at ${DateTime.now().toString()}');
      
      if (event.snapshot.value != null) {
        _connectionStatus = ConnectionStatus.connected;
        
        try {
          final dynamic rawValue = event.snapshot.value;
          Map<String, dynamic> data = {};
          
          if (rawValue is Map) {
            data = Map<String, dynamic>.from(rawValue.map(
              (key, value) => MapEntry(key.toString(), value),
            ));
          }
          
          final double ph = _parseToDouble(data['ph'], 7.0);
          final double turbidity = _parseToDouble(data['turbidity'], 0.0);
          final double temperature = _parseToDouble(data['temperature'], 25.0);


          final fuzzyResult = _fuzzyService.evaluate(
            ph, turbidity, temperature,
            phMin: _phMin,
            phMax: _phMax,
            turbMax: _turbMax,
          );
          
          final newData = SensorData(
            ph: ph,
            turbidity: turbidity,
            temperature: temperature,
            timestamp: DateTime.now(),
            status: fuzzyResult.status,
            fuzzyResult: fuzzyResult.statusLabel,
            qualityScore: fuzzyResult.qualityScore,
          );

          _lastUpdateTime = DateTime.now();
          _onSensorDataReceived(newData, fuzzyResult);
        } catch (e) {
          debugPrint('❌ Error parsing Firebase data: $e');
          _connectionStatus = ConnectionStatus.disconnected;
          notifyListeners();
        }
      } else {
        _connectionStatus = ConnectionStatus.disconnected;
        notifyListeners();
      }
    }, onError: (error) {
      debugPrint('❌ Firebase Stream Error: $error');
      _connectionStatus = ConnectionStatus.disconnected;
      _notificationService.cancelAll(); // Stop notif & TTS saat error
      notifyListeners();
    });

    // 3. Fallback Heartbeat Check (Every 10 seconds)
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_lastUpdateTime != null) {
        final difference = DateTime.now().difference(_lastUpdateTime!);
        // Jika sudah lebih dari 20 detik tidak ada data baru, anggap terputus
        if (difference.inSeconds > 20 && _connectionStatus == ConnectionStatus.connected) {
          debugPrint('⚠️ Heartbeat timeout: No data for ${difference.inSeconds}s. Marking as disconnected.');
          _connectionStatus = ConnectionStatus.disconnected;
          _notificationService.cancelAll(); // Stop notif & TTS saat timeout
          notifyListeners();
        }
      }
    });
  }

  double _parseToDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _statusSubscription?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }
  


  void _onSensorDataReceived(SensorData data, FuzzyResult fuzzyResult) async {
    debugPrint('📲 _onSensorDataReceived called');
    debugPrint('   Temperature: ${data.temperature} °C');
    debugPrint('   pH: ${data.ph}');
    debugPrint('   Turbidity: ${data.turbidity}');
    
    _currentData = data;
    _lastFuzzyResult = fuzzyResult;

    // Simpan ke history
    _historyData.insert(0, data);
    if (_historyData.length > 5000) {
      _historyData = _historyData.sublist(0, 5000);
    }
    _filteredHistory = _historyData;

    await _saveHistoryToPrefs();

    // Kirim notifikasi jika status Waspada atau Bahaya
    if (_notificationsEnabled && (data.status == WaterQualityStatus.notDrinkable || data.status == WaterQualityStatus.usable)) {
      await _notificationService.sendWaterQualityAlert(
        data: data,
        fuzzyResult: data.fuzzyResult,
      );
    } else {
      // Stop suara jika status membaik
      _notificationService.stopSpeechLoop();
    }

    debugPrint('🔔 Calling notifyListeners()...');
    notifyListeners();
    debugPrint('✅ notifyListeners() called - UI should rebuild!\n');
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
    if (notifications != null) {
      _notificationsEnabled = notifications;
      if (!notifications) {
        _notificationService.stopSpeechLoop();
      } else if (_currentData != null) {
        // Langsung munculkan notifikasi status saat ini ketika dinyalakan
        await _notificationService.sendWaterQualityAlert(
          data: _currentData!,
          fuzzyResult: _currentData!.fuzzyResult,
        );
      }
    }
    await _saveSettings();
    notifyListeners();
  }
  Future<void> updateThresholds({
    double? phMin,
    double? phMax,
    double? turbMax,
    double? tempMin,
    double? tempMax,
    double? turbJernihLimit,
    double? turbAgakKeruhLimit,
    double? tempDinginLimit,
    double? tempNormalLimit,
    double? phAsamLimit,
    double? phNormalLimit,
  }) async {
    // Sinkronisasi agar perubahan di Pengaturan Langsung Ngefek
    if (phMin != null) _phMin = phMin;
    if (phMax != null) _phMax = phMax;
    
    // Jika user edit via 'Detailed' dialog di Settings, update juga phMin/phMax-nya
    if (phAsamLimit != null) {
      _phAsamLimit = phAsamLimit;
      _phMin = phAsamLimit; 
    }
    if (phNormalLimit != null) {
      _phNormalLimit = phNormalLimit;
      _phMax = phNormalLimit;
    }
    
    if (turbMax != null) _turbMax = turbMax;
    if (turbJernihLimit != null) {
      _turbJernihLimit = turbJernihLimit;
      // Gunakan batas jernih sebagai turbMax dasar jika tidak ada input turbMax
      if (turbMax == null) _turbMax = turbJernihLimit;
    }
    if (turbAgakKeruhLimit != null) _turbAgakKeruhLimit = turbAgakKeruhLimit;
    
    if (tempMin != null) _tempMin = tempMin;
    if (tempMax != null) _tempMax = tempMax;
    if (tempDinginLimit != null) {
      _tempDinginLimit = tempDinginLimit;
      _tempMin = tempDinginLimit;
    }
    if (tempNormalLimit != null) {
      _tempNormalLimit = tempNormalLimit;
      _tempMax = tempNormalLimit;
    }

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
    await prefs.setDouble('turb_jernih_limit', _turbJernihLimit);
    await prefs.setDouble('turb_agak_keruh_limit', _turbAgakKeruhLimit);
    await prefs.setDouble('temp_dingin_limit', _tempDinginLimit);
    await prefs.setDouble('temp_normal_limit', _tempNormalLimit);
    await prefs.setDouble('ph_asam_limit', _phAsamLimit);
    await prefs.setDouble('ph_normal_limit', _phNormalLimit);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _phMin = prefs.getDouble('ph_min') ?? 6.5;
    _phMax = prefs.getDouble('ph_max') ?? 8.5;
    _turbMax = prefs.getDouble('turb_max') ?? 25.0;
    _tempMin = prefs.getDouble('temp_min') ?? 10.0;
    _tempMax = prefs.getDouble('temp_max') ?? 30.0;
    _turbJernihLimit = prefs.getDouble('turb_jernih_limit') ?? 12.5;
    _turbAgakKeruhLimit = prefs.getDouble('turb_agak_keruh_limit') ?? 25.0;
    _tempDinginLimit = prefs.getDouble('temp_dingin_limit') ?? 18.0;
    _tempNormalLimit = prefs.getDouble('temp_normal_limit') ?? 26.0;
    _phAsamLimit = prefs.getDouble('ph_asam_limit') ?? 6.0;
    _phNormalLimit = prefs.getDouble('ph_normal_limit') ?? 8.0;
  }

  void clearHistory() async {
    _historyData.clear();
    _filteredHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sensor_history');
    notifyListeners();
  }
}
