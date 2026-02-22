import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/sensor_data.dart';
import 'fuzzy_mamdani_service.dart';

class MqttService {
  static const String _broker = '192.168.1.100'; // IP ESP8266 / Broker MQTT
  static const int _port = 1883;
  static const String _clientId = 'monitoringwaterapk';
  static const String _topicPH = 'pdam/sensor/ph';
  static const String _topicTurbidity = 'pdam/sensor/turbidity';
  static const String _topicTemperature = 'pdam/sensor/temperature';
  static const String _topicAll = 'pdam/sensor/all';

  MqttServerClient? _client;
  final FuzzyMamdaniService _fuzzyService = FuzzyMamdaniService();

  final StreamController<SensorData> _sensorDataController =
      StreamController<SensorData>.broadcast();
  final StreamController<MqttConnectionStatus> _statusController =
      StreamController<MqttConnectionStatus>.broadcast();

  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<MqttConnectionStatus> get statusStream => _statusController.stream;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  // Buffer nilai sensor terpisah (untuk sinkronisasi)
  double? _lastPh;
  double? _lastTurbidity;
  double? _lastTemperature;
  Timer? _simulationTimer;

  Future<void> connect() async {
    _client = MqttServerClient(_broker, _clientId);
    _client!.port = _port;
    _client!.keepAlivePeriod = 20;
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = _onConnected;
    _client!.onSubscribed = _onSubscribed;
    _client!.logging(on: false);
    _client!.setProtocolV311();

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .withWillTopic('pdam/status')
        .withWillMessage('offline')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client!.connectionMessage = connMessage;

    try {
      _statusController.add(MqttConnectionStatus.connecting);
      await _client!.connect();
    } catch (e) {
      debugPrint('MQTT Connect Error: $e');
      _client!.disconnect();
      _statusController.add(MqttConnectionStatus.disconnected);
      // Mulai simulasi jika tidak bisa konek
      _startSimulation();
      return;
    }

    if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
      _statusController.add(MqttConnectionStatus.connected);
      _subscribeTopics();
      _listenToMessages();
    } else {
      _statusController.add(MqttConnectionStatus.disconnected);
      _startSimulation();
    }
  }

  void _subscribeTopics() {
    _client!.subscribe(_topicPH, MqttQos.atLeastOnce);
    _client!.subscribe(_topicTurbidity, MqttQos.atLeastOnce);
    _client!.subscribe(_topicTemperature, MqttQos.atLeastOnce);
    _client!.subscribe(_topicAll, MqttQos.atLeastOnce);
  }

  void _listenToMessages() {
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final msg in messages) {
        final recMess = msg.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );
        _processMessage(msg.topic, payload);
      }
    });
  }

  void _processMessage(String topic, String payload) {
    try {
      if (topic == _topicAll) {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final ph = (data['ph'] as num).toDouble();
        final turbidity = (data['turbidity'] as num).toDouble();
        final temperature = (data['temperature'] as num).toDouble();
        _emitSensorData(ph, turbidity, temperature);
      } else if (topic == _topicPH) {
        _lastPh = double.tryParse(payload);
      } else if (topic == _topicTurbidity) {
        _lastTurbidity = double.tryParse(payload);
      } else if (topic == _topicTemperature) {
        _lastTemperature = double.tryParse(payload);
        // Emit ketika semua data terkumpul
        if (_lastPh != null && _lastTurbidity != null) {
          _emitSensorData(_lastPh!, _lastTurbidity!, _lastTemperature!);
        }
      }
    } catch (e) {
      debugPrint('Error processing MQTT message: $e');
    }
  }

  void _emitSensorData(double ph, double turbidity, double temperature) {
    final result = _fuzzyService.evaluate(ph, turbidity, temperature);
    final data = SensorData(
      ph: ph,
      turbidity: turbidity,
      temperature: temperature,
      timestamp: DateTime.now(),
      status: result.status,
      fuzzyResult: result.statusLabel,
      qualityScore: result.qualityScore,
    );
    _sensorDataController.add(data);
  }

  // ============================================================
  // MODE SIMULASI (ketika ESP8266 tidak terhubung)
  // ============================================================
  final Random _random = Random();

  void _startSimulation() {
    _statusController.add(MqttConnectionStatus.simulation);
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final ph = 6.0 + _random.nextDouble() * 3.0; // 6.0 - 9.0
      final turbidity = _random.nextDouble() * 15.0; // 0 - 15 NTU
      final temperature = 20.0 + _random.nextDouble() * 15.0; // 20 - 35°C
      _emitSensorData(ph, turbidity, temperature);
    });
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  void _onConnected() {
    debugPrint('MQTT Connected');
    _statusController.add(MqttConnectionStatus.connected);
  }

  void _onDisconnected() {
    debugPrint('MQTT Disconnected');
    _statusController.add(MqttConnectionStatus.disconnected);
    _startSimulation();
  }

  void _onSubscribed(String topic) {
    debugPrint('MQTT Subscribed: $topic');
  }

  void disconnect() {
    stopSimulation();
    _client?.disconnect();
  }

  void dispose() {
    disconnect();
    _sensorDataController.close();
    _statusController.close();
  }
}

enum MqttConnectionStatus { connecting, connected, disconnected, simulation }

extension MqttConnectionStatusExtension on MqttConnectionStatus {
  String get label {
    switch (this) {
      case MqttConnectionStatus.connecting:
        return 'Menghubungkan...';
      case MqttConnectionStatus.connected:
        return 'Terhubung ke ESP8266';
      case MqttConnectionStatus.disconnected:
        return 'Terputus';
      case MqttConnectionStatus.simulation:
        return 'Mode Simulasi';
    }
  }
}
