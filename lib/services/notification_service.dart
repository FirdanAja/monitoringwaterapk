import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:open_filex/open_filex.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/sensor_data.dart';

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

  // Data untuk mengulang notifikasi bersama suara
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
    );

    // Request permission Android 13+
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Buat Channel secara eksplisit untuk Android 8+ (PENTING untuk Background Service)
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

    // Inisialisasi TTS
    await _flutterTts.setLanguage("id-ID");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    // Looping logic: saat bicara selesai, cek apakah harus mengulang
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() async {
      _isSpeaking = false;
      if (_shouldLoopSpeech && _currentSpeechText.isNotEmpty) {
        await _flutterTts.speak(_currentSpeechText);
        
        // Re-show notification agar "berulang" bersama suaranya
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
    
    // Jika teks sama dan sedang bicara, abaikan agar tidak tumpang tindih
    if (_isSpeaking && _currentSpeechText == text) return;
    
    // Stop dulu yang lama jika ada, baru mulai yang baru
    if (_isSpeaking) {
      await _flutterTts.stop();
    }
    
    _isSpeaking = true;
    _currentSpeechText = text;
    await _flutterTts.speak(text);
  }

  void _onNotificationTapped(NotificationResponse response) async {
    debugPrint('Notification tapped with payload: ${response.payload}');
    
    // Stop suara saat notifikasi diklik/direspon
    stopSpeechLoop();

    if (response.payload != null && response.payload!.endsWith('.xlsx')) {
      debugPrint('Attempting to open Excel file: ${response.payload}');
      final result = await OpenFilex.open(response.payload!);
      debugPrint('Open file result: ${result.message} (Type: ${result.type})');
    }
  }

  /// Kirim notifikasi berdasarkan hasil fuzzy logic
  Future<void> sendWaterQualityAlert({
    required SensorData data,
    required String fuzzyResult,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    // HANYA kirim notifikasi jika statusnya BAHAYA (notDrinkable)
    if (data.status == WaterQualityStatus.notDrinkable) {
      // ID unik berbasis waktu agar notifikasi bertumpuk (tidak menimpa)
      final uniqueId = DateTime.now().millisecondsSinceEpoch % 100000;

      await _showNotification(
        id: uniqueId,
        data: data,
        fuzzyResult: fuzzyResult,
      );

      // Suara orang ngomong
      String speechText = "";
      bool isBahaya = data.status == WaterQualityStatus.notDrinkable;
      if (data.turbidity > 25.0) {
        speechText = isBahaya 
          ? 'Peringatan, air keruh terdeteksi.'
          : 'Waspada. Air agak keruh.';
      } else if (data.status == WaterQualityStatus.usable) {
        speechText = 'Waspada. Air agak keruh.';
      } else {
        speechText = ""; // Diam kalau aman
      }
      
      _currentSpeechText = speechText;
      _shouldLoopSpeech = true;
      
      // Simpan data untuk pengulangan di completion handler
      _lastAlertId = uniqueId;
      _lastAlertData = data;
      _lastFuzzyResult = fuzzyResult;

      _speak(speechText);
    } else {
      // Jika status membaik (Aman/Waspada), stop suara dan jangan kirim notif baru
      stopSpeechLoop();
    }
  }

  /// Helper untuk menampilkan notifikasi
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



    switch (data.status) {
      case WaterQualityStatus.notDrinkable:
        notifId = 1001;
        title = '🚨 BAHAYA: Air Keruh';
        body = 'Status: $fuzzyResult (${data.turbidity.toStringAsFixed(1)} NTU). '
               'Harap periksa kondisi air segera.';
        break;
      case WaterQualityStatus.usable:
        notifId = 1002;
        title = '⚠️ WASPADA: Air Agak Keruh';
        body = 'Status: $fuzzyResult (${data.turbidity.toStringAsFixed(1)} NTU). '
               'Kondisi air mulai menurun.';
        break;
      case WaterQualityStatus.drinkable:
        notifId = 1003;
        title = '✅ AMAN: Air Jernih';
        body = 'Status: $fuzzyResult (${data.turbidity.toStringAsFixed(1)} NTU). '
               'Kualitas air dalam kondisi baik.';
        break;
      default:
        notifId = 1004;
        title = 'Update Kualitas Air';
        body = 'Status: ${data.status.label}.';

    }

    final isHighPriority = data.status == WaterQualityStatus.notDrinkable;

    final androidDetails = AndroidNotificationDetails(
      'water_quality_high_priority',
      'Peringatan Kualitas Air',
      channelDescription: 'Notifikasi penting untuk kondisi air buruk atau keruh',
      importance: isHighPriority ? Importance.max : Importance.low,
      priority: isHighPriority ? Priority.max : Priority.low,
      icon: '@mipmap/launcher_icon',
      color: _getStatusColor(data.status),
      enableVibration: isHighPriority,
      playSound: isHighPriority,
      ticker: title,
      category: isHighPriority ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.status,
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

  /// Kirim notifikasi saat file berhasil diunduh
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
      icon: '@mipmap/launcher_icon',
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
      '✅ Laporan Berhasil Diunduh',
      'File $fileName telah tersimpan di folder Download.',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: filePath,
    );
  }

  /// Batalkan semua notifikasi
  Future<void> cancelAll() async {
    stopSpeechLoop();
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Berhenti bicara dan stop loop
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
