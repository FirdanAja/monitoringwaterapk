import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data.dart';
import '../utils/app_colors.dart';

class SensorLineChart extends StatefulWidget {
  final List<SensorData> data;
  final String sensorType; // 'ph', 'turbidity', 'temperature'
  final int maxPoints;

  const SensorLineChart({
    super.key,
    required this.data,
    required this.sensorType,
    this.maxPoints = 20,
  });

  @override
  State<SensorLineChart> createState() => _SensorLineChartState();
}

class _SensorLineChartState extends State<SensorLineChart> {
  @override
  Widget build(BuildContext context) {
    final displayData = widget.data.length > widget.maxPoints
        ? widget.data.sublist(widget.data.length - widget.maxPoints)
        : widget.data;

    if (displayData.isEmpty) {
      return const Center(
        child: Text(
          'Menunggu data...',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppColors.textMuted,
            fontSize: 13,
          ),
        ),
      );
    }

    final spots = displayData.asMap().entries.map((e) {
      final value = _getValue(e.value);
      return FlSpot(e.key.toDouble(), value);
    }).toList();

    final color = _getColor();
    final minY = _getMinY();
    final maxY = _getMaxY();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.textMuted.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.bgCardLight,
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) => spots.map((s) {
              return LineTooltipItem(
                '${s.y.toStringAsFixed(2)} ${_getUnit()}',
                TextStyle(
                  fontFamily: 'Poppins',
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: displayData.length <= 10,
              getDotPainter: (spot, x, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: color,
                strokeWidth: 2,
                strokeColor: AppColors.bgDark,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.0)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        // Safe zone reference lines
        extraLinesData: ExtraLinesData(horizontalLines: _getSafeZoneLines()),
      ),
    );
  }

  List<HorizontalLine> _getSafeZoneLines() {
    switch (widget.sensorType) {
      case 'ph':
        return [
          HorizontalLine(
            y: 6.5,
            color: AppColors.warning.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              labelResolver: (_) => 'min',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.warning,
                fontSize: 9,
              ),
            ),
          ),
          HorizontalLine(
            y: 8.5,
            color: AppColors.warning.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              labelResolver: (_) => 'max',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.warning,
                fontSize: 9,
              ),
            ),
          ),
        ];
      case 'turbidity':
        return [
          HorizontalLine(
            y: 5.0,
            color: AppColors.warning.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ];
      case 'temperature':
        return [
          HorizontalLine(
            y: 10.0,
            color: AppColors.warning.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
          HorizontalLine(
            y: 30.0,
            color: AppColors.warning.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ];
      default:
        return [];
    }
  }

  double _getValue(SensorData d) {
    switch (widget.sensorType) {
      case 'ph':
        return d.ph;
      case 'turbidity':
        return d.turbidity;
      case 'temperature':
        return d.temperature;
      default:
        return 0;
    }
  }

  Color _getColor() {
    switch (widget.sensorType) {
      case 'ph':
        return AppColors.chartPH;
      case 'turbidity':
        return AppColors.chartTurbidity;
      case 'temperature':
        return AppColors.chartTemp;
      default:
        return AppColors.accent;
    }
  }

  String _getUnit() {
    switch (widget.sensorType) {
      case 'ph':
        return '';
      case 'turbidity':
        return 'NTU';
      case 'temperature':
        return '°C';
      default:
        return '';
    }
  }

  double _getMinY() {
    switch (widget.sensorType) {
      case 'ph':
        return 0;
      case 'turbidity':
        return 0;
      case 'temperature':
        return 0;
      default:
        return 0;
    }
  }

  double _getMaxY() {
    switch (widget.sensorType) {
      case 'ph':
        return 14;
      case 'turbidity':
        return 50;
      case 'temperature':
        return 40;
      default:
        return 100;
    }
  }
}

class QualityBarChart extends StatelessWidget {
  final int drinkable;
  final int usable;
  final int notDrinkable;
  final int total;

  const QualityBarChart({
    super.key,
    required this.drinkable,
    required this.usable,
    required this.notDrinkable,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return const Center(
        child: Text(
          'Tidak ada data',
          style: TextStyle(fontFamily: 'Poppins', color: AppColors.textMuted),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: total.toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.bgCardLight,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final labels = ['Layak Minum', 'Layak Tidak', 'Tidak Layak'];
              return BarTooltipItem(
                '${labels[groupIndex]}\n${rod.toY.toInt()} data',
                const TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final labels = ['Layak Minum', 'Layak Tidak', 'Tidak Layak'];
                if (value.toInt() >= labels.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labels[value.toInt()],
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textSecondary,
                      fontSize: 8,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: [
          _buildBar(0, drinkable.toDouble(), AppColors.good),
          _buildBar(1, usable.toDouble(), AppColors.warning),
          _buildBar(2, notDrinkable.toDouble(), AppColors.danger),
        ],
      ),
    );
  }

  BarChartGroupData _buildBar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 28,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: (drinkable + usable + notDrinkable).toDouble(),
            color: AppColors.bgSurface,
          ),
        ),
      ],
    );
  }
}

class SensorBarChart extends StatelessWidget {
  final List<SensorData> data;
  final String sensorType;
  final int maxPoints;

  const SensorBarChart({
    super.key,
    required this.data,
    required this.sensorType,
    this.maxPoints = 12,
  });

  @override
  Widget build(BuildContext context) {
    final displayData = data.length > maxPoints
        ? data.sublist(data.length - maxPoints)
        : data;

    if (displayData.isEmpty) {
      return const Center(
        child: Text(
          'Menunggu data...',
          style: TextStyle(fontFamily: 'Poppins', color: AppColors.textMuted),
        ),
      );
    }

    final color = _getColor();
    final maxY = _getMaxY();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.bgCardLight,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(1)} ${_getUnit()}',
                TextStyle(fontFamily: 'Poppins', color: color, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= displayData.length) return const SizedBox();
                final d = displayData[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('HH:mm').format(d.timestamp),
                    style: const TextStyle(fontFamily: 'Poppins', color: AppColors.textMuted, fontSize: 8),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: const TextStyle(fontFamily: 'Poppins', color: AppColors.textMuted, fontSize: 9),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (v) => FlLine(color: AppColors.textMuted.withValues(alpha: 0.1), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: displayData.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: _getValue(e.value),
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.5), color],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  double _getValue(SensorData d) {
    switch (sensorType) {
      case 'ph': return d.ph;
      case 'turbidity': return d.turbidity;
      case 'temperature': return d.temperature;
      default: return 0;
    }
  }

  Color _getColor() {
    switch (sensorType) {
      case 'ph': return AppColors.chartPH;
      case 'turbidity': return AppColors.chartTurbidity;
      case 'temperature': return AppColors.chartTemp;
      default: return AppColors.accent;
    }
  }

  String _getUnit() {
    switch (sensorType) {
      case 'ph': return '';
      case 'turbidity': return 'NTU';
      case 'temperature': return '°C';
      default: return '';
    }
  }

  double _getMaxY() {
    switch (sensorType) {
      case 'ph': return 14;
      case 'turbidity': return 50;
      case 'temperature': return 40;
      default: return 100;
    }
  }
}

