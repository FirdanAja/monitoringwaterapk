import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import '../services/fuzzy_mamdani_service.dart';
import '../models/sensor_data.dart';
import '../utils/app_colors.dart';
import '../utils/responsive_helper.dart';
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
  int _selectedChart = 0;
  int _selectedChartStyle = 0; // 0 for Line, 1 for Bar

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
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
            provider.connectionStatus == ConnectionStatus.connected;
        const isSimulation = false;

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          body: Stack(
            children: [
              _buildDecorativeBackground(),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          context.responsive.w(16),
                          context.responsive.w(16),
                          context.responsive.w(16),
                          8),
                      child: _buildHeader(provider, isConnected, isSimulation),
                    ),
                    Expanded(
                      child: data != null
                          ? SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.symmetric(
                                  horizontal: context.responsive.w(16)),
                              child: _buildContent(data, fuzzy, provider),
                            )
                          : _buildLoadingView(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(
      SensorData data, FuzzyResult? fuzzy, SensorProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Side-by-side Gauge and Sensors
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: _buildLeftGaugeSection(data, fuzzy),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: _buildVerticalSensorGrid(data),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (fuzzy != null) _buildCompactAnalysis(fuzzy),
        const SizedBox(height: 20),
        _buildInteractiveCharts(provider),
        const SizedBox(height: 100), // Space for floating navbar
      ],
    );
  }

  Widget _buildLeftGaugeSection(SensorData data, FuzzyResult? fuzzy) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.05),
          ),
          child: ScaleTransition(
            scale: _pulseAnim,
            child: QualityGauge(score: data.qualityScore, status: data.status),
          ),
        ),
        const SizedBox(height: 10),
        StatusBadge(status: data.status, large: false),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
          ),
          child: Text(
            fuzzy?.recommendation ?? 'Menganalisis kualitas air...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9.5,
              color: AppColors.textSecondary,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalSensorGrid(SensorData data) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniHorizontalSensorCard('pH Air', data.ph.toStringAsFixed(1), 'pH',
            AppColors.chartPH, Icons.water_drop_rounded),
        const SizedBox(height: 10),
        _miniHorizontalSensorCard(
            'Kekeruhan',
            data.turbidity.toStringAsFixed(1),
            'NTU',
            AppColors.chartTurbidity,
            Icons.opacity_rounded),
        const SizedBox(height: 10),
        _miniHorizontalSensorCard(
            'Suhu Air',
            data.temperature.toStringAsFixed(1),
            '°C',
            AppColors.chartTemp,
            Icons.thermostat_rounded),
      ],
    );
  }

  Widget _miniHorizontalSensorCard(
      String label, String value, String unit, Color color, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      borderRadius: 12,
      borderColor: color.withValues(alpha: 0.15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      unit,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        color: color.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeBackground() {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
      SensorProvider provider, bool isConnected, bool isSimulation) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 2),
                ],
              ),
              child: Image.asset(
                'assets/icons/logo.png',
                width: 40, // Increased size
                height: 40,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TirtaSmart',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (provider.lastUpdateTime != null)
                  Text(
                    'Update: ${provider.lastUpdateTime!.hour.toString().padLeft(2, '0')}:${provider.lastUpdateTime!.minute.toString().padLeft(2, '0')}:${provider.lastUpdateTime!.second.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 8,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  const Text(
                    'Dashboard Monitoring',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ],
        ),
        ConnectionStatusChip(
          status: isSimulation
              ? 'SIMULASI'
              : (isConnected ? 'TERHUBUNG' : 'TERPUTUS'),
          connected: isConnected || isSimulation,
        ),
      ],
    );
  }

  Widget _buildCompactAnalysis(FuzzyResult fuzzy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.analytics_outlined, color: AppColors.accent, size: 14),
            SizedBox(width: 8),
            Text(
              'Analisis Sistem',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: ['sangatBaik', 'baik', 'cukup', 'buruk', 'sangatBuruk']
              .map((key) {
            final value = fuzzy.membershipDegrees[key] ?? 0.0;
            final color = _getMembershipColor(key);
            final isActive = value > 0;

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? color.withValues(alpha: 0.12)
                      : AppColors.bgSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? color.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.05),
                    width: 1,
                  ),
                  boxShadow: isActive
                      ? const [
                          BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 4,
                              spreadRadius: 0),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      _getMembershipAbbreviation(key),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 8,
                        fontWeight:
                            isActive ? FontWeight.w800 : FontWeight.w500,
                        color: isActive ? color : AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(value * 100).toInt()}%',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isActive ? color : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Mini progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        height: 2,
                        width: 20,
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          color: isActive ? color : Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInteractiveCharts(SensorProvider provider) {
    final hourlyData = provider.getHourlyData(hours: 12);
    final chartTypes = ['pH', 'NTU', '°C'];
    final chartColors = [
      AppColors.chartPH,
      AppColors.chartTurbidity,
      AppColors.chartTemp
    ];
    final sensorKeys = ['ph', 'turbidity', 'temperature'];

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Style Toggle Button
              GestureDetector(
                onTap: () => setState(
                    () => _selectedChartStyle = (_selectedChartStyle + 1) % 2),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedChartStyle == 0
                            ? Icons.show_chart_rounded
                            : Icons.bar_chart_rounded,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedChartStyle == 0 ? 'Garis' : 'Batang',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              // Sensor Type Selector
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: List.generate(3, (index) {
                    final isSelected = _selectedChart == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedChart = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? chartColors[index]
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                      color: chartColors[index]
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1),
                                ]
                              : [],
                        ),
                        child: Text(
                          chartTypes[index],
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color:
                                isSelected ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: _selectedChartStyle == 0
                ? SensorLineChart(
                    data: hourlyData, sensorType: sensorKeys[_selectedChart])
                : SensorBarChart(
                    data: hourlyData, sensorType: sensorKeys[_selectedChart]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.accent),
          SizedBox(height: 16),
          Text('Menunggu data...',
              style: TextStyle(
                  fontFamily: 'Poppins', color: AppColors.textSecondary)),
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

  String _getMembershipAbbreviation(String key) {
    switch (key) {
      case 'sangatBaik':
        return 'S. BAIK';
      case 'baik':
        return 'BAIK';
      case 'cukup':
        return 'CUKUP';
      case 'buruk':
        return 'BURUK';
      case 'sangatBuruk':
        return 'S. BURUK';
      default:
        return key.toUpperCase();
    }
  }
}
