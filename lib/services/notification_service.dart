import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:open_filex/open_filex.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/sensor_data.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  debugPrint('Background Notification tapped with payload: ${response.payload}');
  if (response.payload != null && (response.payload!.endsWith('.xlsx') || response.payload!.endsWith('.pdf'))) {
    debugPrint('Attempting to open file in background: ${response.payload}');
    await OpenFilex.open(response.payload!);
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _shouldLoopSpeech = false;
  bool _isSpeaking = false;
  String _currentSpeechText = "";

  int? _lastAlertId;
  SensorData? _lastAlertData;
  String? _lastFuzzyResult;


  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'water_quality_high_priority',
          'Peringatan Kualitas Air',
          description: 'Notifikasi penting untuk kondisi air buruk atau keruh',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          enableLights: true,
        ),
      );

      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'file_download_channel',
          'Unduhan File',
          description: 'Notifikasi unduhan laporan excel',
          importance: Importance.max,
        ),
      );
    }

    await _flutterTts.setLanguage("id-ID");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() async {
      _isSpeaking = false;
      if (_shouldLoopSpeech && _currentSpeechText.isNotEmpty) {
        await _flutterTts.speak(_currentSpeechText);
        
        if (_lastAlertId != null && _lastAlertData != null && _lastFuzzyResult != null) {
          await _showNotification(
            id: _lastAlertId!,
            data: _lastAlertData!,
            fuzzyResult: _lastFuzzyResult!,
          );
        }
      }
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
    });

    _isInitialized = true;
  }

  Future<void> _speak(String text) async {
    if (kIsWeb) return;
    
    if (_isSpeaking && _currentSpeechText == text) return;
    
    if (_isSpeaking) {
      await _flutterTts.stop();
    }
    
    _isSpeaking = true;
    _currentSpeechText = text;
    await _flutterTts.speak(text);
  }

  void _onNotificationTapped(NotificationResponse response) async {
    debugPrint('Notification tapped with payload: ${response.payload}');
    
    stopSpeechLoop();

    if (response.payload != null && (response.payload!.endsWith('.xlsx') || response.payload!.endsWith('.pdf'))) {
      debugPrint('Attempting to open file: ${response.payload}');
      final result = await OpenFilex.open(response.payload!);
      debugPrint('Open file result: ${result.message} (Type: ${result.type})');
    }
  }

  DateTime? _lastNotifTime;

  Future<void> sendWaterQualityAlert({
    required SensorData data,
    required String fuzzyResult,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    if (data.status == WaterQualityStatus.notDrinkable || data.status == WaterQualityStatus.usable) {
      final uniqueId = data.status == WaterQualityStatus.notDrinkable ? 1001 : 1002;

      final now = DateTime.now();
      if (_lastNotifTime == null || now.difference(_lastNotifTime!).inSeconds >= 10 || _lastAlertId != uniqueId) {
        _lastNotifTime = now;
        await _showNotification(
          id: uniqueId,
          data: data,
          fuzzyResult: fuzzyResult,
        );
      }

      String speechText = "";
      bool isBahaya = data.status == WaterQualityStatus.notDrinkable;
      
      if (isBahaya) {
        speechText = 'Peringatan, kualitas air dalam kondisi bahaya.';
      } else {
        speechText = '';
      }
      
      _currentSpeechText = speechText;
      _shouldLoopSpeech = true;
      
      _lastAlertId = uniqueId;
      _lastAlertData = data;
      _lastFuzzyResult = fuzzyResult;

      _speak(speechText);
    } else {
      stopSpeechLoop();
    }
  }

  Future<void> _showNotification({
    required int id,
    required SensorData data,
    required String fuzzyResult,
  }) async {
    final notifData = _buildNotificationContent(data, fuzzyResult);
    
    await _flutterLocalNotificationsPlugin.show(
      id,
      notifData['title'] as String,
      notifData['body'] as String,
      notifData['details'] as NotificationDetails,
      payload: jsonEncode(data.toJson()),
    );
  }

  Map<String, dynamic> _buildNotificationContent(
    SensorData data,
    String fuzzyResult,
  ) {
    int notifId;
    String title;
    String body;



    String sensorDetails = 'pH: ${data.ph.toStringAsFixed(1)} | NTU: ${data.turbidity.toStringAsFixed(1)} | Suhu: ${data.temperature.toStringAsFixed(1)}°C';

    switch (data.status) {
      case WaterQualityStatus.notDrinkable:
        notifId = 1001;
        title = '🚨 BAHAYA: Kualitas Air $fuzzyResult';
        body = 'Harap periksa kondisi air segera!\n$sensorDetails';
        break;
      case WaterQualityStatus.usable:
        notifId = 1002;
        title = '⚠️ WASPADA: Kualitas Air $fuzzyResult';
        body = 'Kondisi air mulai menurun.\n$sensorDetails';
        break;
      case WaterQualityStatus.drinkable:
        notifId = 1003;
        title = '✅ AMAN: Air $fuzzyResult';
        body = 'Kualitas air dalam kondisi baik.\n$sensorDetails';
        break;
      default:
        notifId = 1004;
        title = 'Update Kualitas Air';
        body = 'Status: ${data.status.label}.\n$sensorDetails';

    }

    final isHighPriority = data.status == WaterQualityStatus.notDrinkable || data.status == WaterQualityStatus.usable;

    final androidDetails = AndroidNotificationDetails(
      'water_quality_high_priority',
      'Peringatan Kualitas Air',
      channelDescription: 'Notifikasi penting untuk kondisi air buruk atau keruh',
      importance: isHighPriority ? Importance.max : Importance.defaultImportance,
      priority: isHighPriority ? Priority.max : Priority.defaultPriority,
      color: _getStatusColor(data.status),
      enableVibration: isHighPriority,
      playSound: isHighPriority,
      ticker: title,
      category: AndroidNotificationCategory.alarm,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Detail Sensor',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return {
      'id': notifId,
      'title': title,
      'body': body,
      'details': NotificationDetails(android: androidDetails, iOS: iosDetails),
    };
  }

  Color _getStatusColor(WaterQualityStatus status) {
    switch (status) {
      case WaterQualityStatus.notDrinkable:
        return const Color(0xFFFF0000);
      case WaterQualityStatus.usable:
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  Future<void> showFileDownloadedNotification({
    required String fileName,
    required String filePath,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'file_download_channel',
      'Unduhan File',
      channelDescription: 'Notifikasi unduhan laporan excel',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFF00C6FF),
      styleInformation: BigTextStyleInformation(
        'Laporan $fileName siap dibuka. Klik untuk melihat detail kualitas air.',
        contentTitle: '✅ Laporan Berhasil Diunduh',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _flutterLocalNotificationsPlugin.show(
      2001,
      '✅ Laporan Berhasil Dibuat',
      'File $fileName telah berhasil disimpan. Tap untuk membuka.',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: filePath,
    );
  }

  Future<void> cancelAll() async {
    stopSpeechLoop();
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  void stopSpeechLoop() {
    _shouldLoopSpeech = false;
    _currentSpeechText = "";
    _lastAlertId = null;
    _lastAlertData = null;
    _lastFuzzyResult = null;
    _isSpeaking = false;
    _flutterTts.stop();
  }
}
