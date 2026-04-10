import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../models/sensor_data.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _lastNotifKey = 'last_notification_time';
  static const int _notifCooldownSeconds = 60; // Minimal 60 detik antara notif

  bool _isInitialized = false;
  WaterQualityStatus? _lastNotifiedStatus;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle tap - bisa navigasi ke halaman tertentu
  }

  /// Kirim notifikasi berdasarkan hasil fuzzy logic
  Future<void> sendWaterQualityAlert({
    required SensorData data,
    required String fuzzyResult,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await initialize();

    // Cek cooldown
    if (!await _canSendNotification(data.status)) return;

    final notifData = _buildNotificationContent(data, fuzzyResult);

    await _flutterLocalNotificationsPlugin.show(
      notifData['id'] as int,
      notifData['title'] as String,
      notifData['body'] as String,
      notifData['details'] as NotificationDetails,
      payload: jsonEncode({
        'ph': data.ph,
        'turbidity': data.turbidity,
        'temperature': data.temperature,
        'status': data.status.name,
        'timestamp': data.timestamp.toIso8601String(),
      }),
    );

    // Simpan waktu notif terakhir
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastNotifKey, DateTime.now().toIso8601String());
    _lastNotifiedStatus = data.status;
  }

  Map<String, dynamic> _buildNotificationContent(
    SensorData data,
    String fuzzyResult,
  ) {
    int notifId;
    String title;
    String body;
    String importance;

    switch (data.status) {
      case WaterQualityStatus.notDrinkable:
        notifId = 1001;
        title = '🚨 Air Tidak Layak Minum';
        body = 'Kualitas air buruk! pH: ${data.ph.toStringAsFixed(2)}, '
            'Kekeruhan: ${data.turbidity.toStringAsFixed(1)} NTU, '
            'Suhu: ${data.temperature.toStringAsFixed(1)}°C. '
            'Air tidak aman digunakan.';
        importance = 'high';
        break;
      case WaterQualityStatus.usable:
        notifId = 1002;
        title = '⚠️ Air Layak Tidak Minum';
        body =
            'Air cukup bersih untuk kebutuhan MCK, namun tidak disarankan untuk diminum. '
            'pH: ${data.ph.toStringAsFixed(2)}, Kekeruhan: ${data.turbidity.toStringAsFixed(1)} NTU.';
        importance = 'default';
        break;
      case WaterQualityStatus.drinkable:
        notifId = 1003;
        title = '✅ Air Layak Minum';
        body =
            'Kualitas air sangat baik. Skor Fuzzy: ${data.qualityScore.toStringAsFixed(1)}. '
            'Air aman untuk diminum.';
        importance = 'low';
        break;
      default:
        notifId = 1004;
        title = 'Kualitas Air PDAM';
        body =
            'Status: ${data.status.label}. Skor: ${data.qualityScore.toStringAsFixed(1)}/100.';
        importance = 'low';
    }

    final androidDetails = AndroidNotificationDetails(
      'water_quality_channel',
      'Water Quality Alerts',
      channelDescription: 'Notifikasi kualitas air PDAM',
      importance: importance == 'high'
          ? Importance.max
          : importance == 'default'
              ? Importance.defaultImportance
              : Importance.low,
      priority: importance == 'high' ? Priority.high : Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      color: _getStatusColor(data.status),
      enableVibration: importance == 'high',
      playSound: importance == 'high',
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

  Future<bool> _canSendNotification(WaterQualityStatus newStatus) async {
    // Selalu kirim kalau status tidak layak minum
    if (newStatus == WaterQualityStatus.notDrinkable) return true;

    // Kalau status sama dengan sebelumnya, cek cooldown
    if (_lastNotifiedStatus == newStatus) {
      final prefs = await SharedPreferences.getInstance();
      final lastTimeStr = prefs.getString(_lastNotifKey);
      if (lastTimeStr != null) {
        final lastTime = DateTime.parse(lastTimeStr);
        final diff = DateTime.now().difference(lastTime).inSeconds;
        if (diff < _notifCooldownSeconds) return false;
      }
    }
    return true;
  }

  /// Batalkan semua notifikasi
  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
