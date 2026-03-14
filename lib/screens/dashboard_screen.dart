import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sensor_provider.dart';
import '../services/mqtt_service.dart';
import '../services/fuzzy_mamdani_service.dart';
import '../models/sensor_data.dart';
import '../utils/app_colors.dart';
import '../widgets/sensor_widgets.dart';
import '../widgets/chart_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, provider, _) {
        final data = provider.currentData;
        final fuzzy = provider.lastFuzzyResult;
        final isConnected =
            provider.connectionStatus == MqttConnectionStatus.connected;
        final isSimulation =
            provider.connectionStatus == MqttConnectionStatus.simulation;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: RefreshIndicator(
            onRefresh: () async => provider.reconnect(),
            color: AppColors.accent,
            backgroundColor: AppColors.bgCard,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(provider, isConnected, isSimulation),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status utama
                        if (data != null) ...[
                          _buildMainQualityCard(data, fuzzy),
                          const SizedBox(height: 16),
                        ] else
                          _buildLoadingCard(),

                        // Sensor cards
                        const SizedBox(height: 4),
                        _buildSectionTitle('Pembacaan Sensor Real-Time'),
                        const SizedBox(height: 12),
                        _buildSensorGrid(data),
                        const SizedBox(height: 16),

                        // Fuzzy detail
                        if (fuzzy != null) ...[
                          _buildSectionTitle('Analisis Fuzzy Mamdani'),
                          const SizedBox(height: 12),
                          _buildFuzzyDetail(fuzzy),
                          const SizedBox(height: 16),
                        ],

                        // Mini chart
                        _buildSectionTitle('Tren 24 Jam Terakhir'),
                        const SizedBox(height: 12),
                        _buildMiniCharts(provider),
                        const SizedBox(height: 16),

                        // Last update
                        if (data != null)
                          Center(
                            child: Text(
                              'Diperbarui: ${DateFormat('dd MMM yyyy, HH:mm:ss').format(data.timestamp)}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(
    SensorProvider provider,
    bool isConnected,
    bool isSimulation,
  ) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.bgDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A0E1A), Color(0xFF0D1B2E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monitor Kualitas Air',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'PDAM - Sistem Fuzzy Mamdani',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      ConnectionStatusChip(
                        status: isSimulation
                            ? 'Simulasi'
                            : isConnected
                                ? 'Terhubung'
                                : 'Terputus',
                        connected: isConnected || isSimulation,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainQualityCard(SensorData? data, FuzzyResult? fuzzy) {
    if (data == null) return const SizedBox();
    return GlassCard(
      gradient: LinearGradient(
        colors: [AppColors.bgCard, AppColors.primary.withValues(alpha: 0.2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(24),
      borderColor: AppColors.accent.withValues(alpha: 0.2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kualitas Air Keseluruhan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                StatusBadge(status: data.status, large: true),
                const SizedBox(height: 12),
                Text(
                  fuzzy?.recommendation ?? '',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ScaleTransition(
            scale: _pulseAnim,
            child: QualityGauge(score: data.qualityScore, status: data.status),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return const GlassCard(
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 12),
            Text(
              'Menunggu data sensor...',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSensorGrid(SensorData? data) {
    final ph = data?.ph ?? 0.0;
    final turbidity = data?.turbidity ?? 0.0;
    final temperature = data?.temperature ?? 0.0;

    return Column(
      children: [
        AnimatedSensorValue(
          label: 'pH Air',
          value: ph.toStringAsFixed(2),
          unit: 'pH',
          color: AppColors.chartPH,
          icon: Icons.water_drop,
          minValue: 0,
          maxValue: 14,
          currentValue: ph,
          safeRange: '6.5 - 8.5',
        ),
        const SizedBox(height: 12),
        AnimatedSensorValue(
          label: 'Kekeruhan (Turbidity)',
          value: turbidity.toStringAsFixed(1),
          unit: 'NTU',
          color: AppColors.chartTurbidity,
          icon: Icons.opacity,
          minValue: 0,
          maxValue: 20,
          currentValue: turbidity,
          safeRange: '< 5 NTU',
        ),
        const SizedBox(height: 12),
        AnimatedSensorValue(
          label: 'Suhu Air',
          value: temperature.toStringAsFixed(1),
          unit: '°C',
          color: AppColors.chartTemp,
          icon: Icons.thermostat,
          minValue: 0,
          maxValue: 50,
          currentValue: temperature,
          safeRange: '10 - 30°C',
        ),
      ],
    );
  }

  Widget _buildFuzzyDetail(FuzzyResult fuzzy) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: AppColors.accent, size: 18),
              SizedBox(width: 8),
              Text(
                'Derajat Keanggotaan Fuzzy',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...fuzzy.membershipDegrees.entries.map((e) {
            final pct = e.value;
            final color = _getMembershipColor(e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getMembershipLabel(e.key),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${(pct * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: pct,
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const Divider(color: AppColors.bgSurface, height: 24),
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fuzzy.diagnosis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getMembershipColor(String key) {
    switch (key) {
      case 'sangatBaik':
        return AppColors.good;
      case 'baik':
        return const Color(0xFF80FF44);
      case 'cukup':
        return AppColors.warning;
      case 'buruk':
        return Colors.orange;
      case 'sangatBuruk':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  String _getMembershipLabel(String key) {
    switch (key) {
      case 'sangatBaik':
        return 'Sangat Baik';
      case 'baik':
        return 'Baik';
      case 'cukup':
        return 'Cukup';
      case 'buruk':
        return 'Buruk';
      case 'sangatBuruk':
        return 'Sangat Buruk';
      default:
        return key;
    }
  }

  Widget _buildMiniCharts(SensorProvider provider) {
    final hourlyData = provider.getHourlyData(hours: 24);
    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'pH',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.chartPH,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: SensorLineChart(data: hourlyData, sensorType: 'ph'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kekeruhan (NTU)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.chartTurbidity,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: SensorLineChart(
                  data: hourlyData,
                  sensorType: 'turbidity',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Suhu (°C)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.chartTemp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: SensorLineChart(
                  data: hourlyData,
                  sensorType: 'temperature',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
