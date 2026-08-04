import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../firebase_options.dart';
import 'notification_service.dart';
import '../models/sensor_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fuzzy_mamdani_service.dart';

@pragma('vm:entry-point')
class BackgroundService {
  @pragma('vm:entry-point')
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        autoStartOnBoot: true,
        isForegroundMode: true,
        notificationChannelId: 'water_quality_high_priority',
        initialNotificationTitle: 'TirtaSmart Monitoring',
        initialNotificationContent: 'Memantau kualitas air di background...',
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    
    debugPrint('🚀 Background Isolate Started: ${DateTime.now()}');

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      FirebaseDatabase.instance.goOnline();
    } catch (e) {
      debugPrint('Background Firebase already initialized: $e');
    }

    final NotificationService notificationService = NotificationService();
    final FuzzyMamdaniService fuzzyService = FuzzyMamdaniService();
    await notificationService.initialize();

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
      
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    Timer.periodic(const Duration(seconds: 20), (timer) {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "TirtaSmart Monitoring: Aktif",
          content: "Terakhir diperbarui: ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}",
        );
      }
      debugPrint("💓 Background Service is alive: ${DateTime.now()}");
    });

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    DatabaseReference database = FirebaseDatabase.instance.ref('monitoring/current');
    database.keepSynced(true);
    
    database.onValue.listen((event) {
      debugPrint("🔥 [BACKGROUND] Data received from Firebase!");
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final ph = (data['ph'] as num).toDouble();
        final turbidity = (data['turbidity'] as num).toDouble();
        
        debugPrint("🔥 [BACKGROUND] pH: $ph, Turb: $turbidity");
        
        final fuzzy = fuzzyService.evaluate(ph, turbidity, 25.0);
        
        if (fuzzy.status == WaterQualityStatus.notDrinkable || fuzzy.status == WaterQualityStatus.usable) {
           debugPrint("⚠️ [BACKGROUND] STATUS BAHAYA/WASPADA TERDETEKSI! Mengirim notifikasi...");
           notificationService.sendWaterQualityAlert(
            data: SensorData(
              ph: ph,
              turbidity: turbidity,
              temperature: 25.0,
              timestamp: DateTime.now(),
              status: fuzzy.status,
              fuzzyResult: fuzzy.statusLabel,
              qualityScore: fuzzy.qualityScore,
            ),
            fuzzyResult: fuzzy.statusLabel,
          );
        }
      }
    });
    
    database.onValue.listen((event) async {
      debugPrint('📥 Background Data Received: ${DateTime.now()}');
      if (event.snapshot.value != null) {
        try {
          final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
          
          final double ph = _parseToDouble(data['ph'], 7.0);
          final double turbidity = _parseToDouble(data['turbidity'], 0.0);
          final double temperature = _parseToDouble(data['temperature'], 25.0);

          final prefs = await SharedPreferences.getInstance();
          final bool notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
          
          if (!notificationsEnabled) return;

          final double phMin = prefs.getDouble('ph_min') ?? 6.5;
          final double phMax = prefs.getDouble('ph_max') ?? 8.5;
          final double turbMax = prefs.getDouble('turb_max') ?? 5.0;

          final fuzzyResult = fuzzyService.evaluate(
            ph, turbidity, temperature,
            phMin: phMin, phMax: phMax, turbMax: turbMax
          );

          final status = fuzzyResult.status;
          final statusStr = fuzzyResult.statusLabel;
          
          await notificationService.sendWaterQualityAlert(
            data: SensorData(
              ph: ph,
              turbidity: turbidity,
              temperature: temperature,
              timestamp: DateTime.now(),
              status: status,
              fuzzyResult: statusStr,
              qualityScore: fuzzyResult.qualityScore,
            ),
            fuzzyResult: statusStr,
          );

          if (service is AndroidServiceInstance) {
            String title = "TirtaSmart: Aktif Memantau";
            String content = "Kondisi: $statusStr (NTU: ${turbidity.toStringAsFixed(1)})";
            
            if (status == WaterQualityStatus.notDrinkable) {
              title = "🚨 BAHAYA! AIR BURUK";
              content = "Segera cek kondisi air! Turbidity: $turbidity NTU";
            }

            service.setForegroundNotificationInfo(
              title: title,
              content: content,
            );
          }
        } catch (e) {
          debugPrint('❌ Background parse error: $e');
        }
      }
    });
  }

  static double _parseToDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}
