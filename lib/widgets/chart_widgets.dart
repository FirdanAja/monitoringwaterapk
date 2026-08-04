import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data.dart';
import '../utils/app_colors.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import 'dart:math' as math;


class SensorLineChart extends StatefulWidget {
  final List<SensorData> data;
  final String sensorType;
  final int maxPoints;

  const SensorLineChart({
    super.key,
    required this.data,
    required this.sensorType,
    this.maxPoints = 24,
  });

  @override
  State<SensorLineChart> createState() => _SensorLineChartState();
}

class _SensorLineChartState extends State<SensorLineChart> {
  @override
  Widget build(BuildContext context) {
    List<SensorData> displayData = [];
    if (widget.data.length > widget.maxPoints) {
      final step = widget.data.length / widget.maxPoints;
      for (int i = 0; i < widget.maxPoints; i++) {
        displayData.add(widget.data[(i * step).toInt()]);
      }
    } else {
      displayData = widget.data;
    }

    if (displayData.isEmpty) {
      return Center(
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
    const double minX = 0;
    final double maxX = (displayData.isNotEmpty ? displayData.length - 1 : 0).toDouble();

    final spots = displayData.asMap().entries.map((e) {
      final value = _getValue(e.value);
      return FlSpot(e.key.toDouble(), value);
    }).toList();

    final color = _getColor();
    final minY = _getMinY();
    final maxY = _getMaxY();
    final interval = _getInterval();

    final lineBar = LineChartBarData(
      showingIndicators: spots.asMap().keys.toList(),
      spots: spots,
      isCurved: false,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, x, bar, index) => FlDotCirclePainter(
          radius: 3.5,
          color: color,
          strokeWidth: 0,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );

    return LineChart(
      LineChartData(
        clipData: const FlClipData.none(),
        showingTooltipIndicators: spots.asMap().keys.map((index) {
          return ShowingTooltipIndicators([
            LineBarSpot(lineBar, 0, spots[index]),
          ]);
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.textMuted.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              _getYAxisName(),
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            axisNameSize: 24,
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 32, // Diperkecil agar lebih dekat dengan grafik
              getTitlesWidget: (value, meta) {
                final label = widget.sensorType == 'turbidity' 
                    ? value.toStringAsFixed(2) 
                    : value.toStringAsFixed(1);
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 3, // Menampilkan per-tiga jam / titik agar tidak bertumpuk
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= displayData.length) return const SizedBox();
                
                final date = displayData[index].timestamp;

                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Transform.rotate(
                    angle: -math.pi / 4,
                    child: Text(
                      DateFormat('HH:mm').format(date),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.textMuted,
                        fontSize: 9,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.2), width: 1),
            left: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.2), width: 1),
            right: BorderSide.none,
            top: BorderSide.none,
          ),
        ),
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: false, 
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return const TouchedSpotIndicatorData(
                FlLine(color: Colors.transparent),
                FlDotData(show: false),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 4,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map<LineTooltipItem?>((spot) {
                // Format angka
                String text = spot.y.toStringAsFixed(1);
                
                // Trik zig-zag: tambahkan enter (\n) bergantian berdasarkan index titik
                if (spot.spotIndex % 2 == 0) {
                  text = '$text\n'; // Angka agak ke atas
                } else {
                  text = '\n$text'; // Angka agak ke bawah
                }

                return LineTooltipItem(
                  text,
                  const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.black87,
                    fontSize: 9,
                    fontWeight: FontWeight.normal,
                    height: 1.0, // Pastikan jarak spasi enter stabil
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [lineBar],
        extraLinesData: ExtraLinesData(horizontalLines: _getSafeZoneLines(context)),
      ),
    );
  }

  List<HorizontalLine> _getSafeZoneLines(BuildContext context) {
    final provider = Provider.of<SensorProvider>(context, listen: true);

    switch (widget.sensorType) {
      case 'ph':
        return [
          HorizontalLine(
            y: provider.phAsamLimit,
            color: AppColors.warning,
            strokeWidth: 1.5,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              labelResolver: (_) => 'min ${provider.phAsamLimit}',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.warning,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          HorizontalLine(
            y: provider.phNormalLimit,
            color: AppColors.warning,
            strokeWidth: 1.5,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.only(left: 4, top: 4),
              labelResolver: (_) => 'max ${provider.phNormalLimit}',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.warning,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ];
      case 'turbidity':
        return [
          HorizontalLine(
            y: provider.turbJernihLimit,
            color: AppColors.warning,
            strokeWidth: 1.5,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              labelResolver: (_) => 'min ${provider.turbJernihLimit}',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.warning,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          HorizontalLine(
            y: provider.turbAgakKeruhLimit,
            color: AppColors.warning,
            strokeWidth: 1.5,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.only(left: 4, top: 4),
              labelResolver: (_) => 'max ${provider.turbAgakKeruhLimit}',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.warning,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ];
      case 'temperature':
        return [
          HorizontalLine(
            y: provider.tempDinginLimit,
            color: AppColors.warning,
            strokeWidth: 1.5,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              labelResolver: (_) => 'min ${provider.tempDinginLimit} °C',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.warning,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          HorizontalLine(
            y: provider.tempNormalLimit,
            color: AppColors.warning,
            strokeWidth: 1.5,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.only(left: 4, top: 4),
              labelResolver: (_) => 'max ${provider.tempNormalLimit} °C',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.warning,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
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
        return 50.0;
      case 'temperature':
        return 40.0;
      default:
        return 100;
    }
  }

  String _getYAxisName() {
    switch (widget.sensorType) {
      case 'ph':
        return 'pH';
      case 'turbidity':
        return 'Tingkat Kekeruhan (NTU)';
      case 'temperature':
        return 'Suhu (°C)';
      default:
        return '';
    }
  }

  double _getInterval() {
    switch (widget.sensorType) {
      case 'ph':
        return 2.0;
      case 'turbidity':
        return 10.0;
      case 'temperature':
        return 5.0;
      default:
        return 20.0;
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
      return Center(
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
                TextStyle(
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
                    style: TextStyle(
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
      return Center(
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
                  padding: const EdgeInsets.only(top: 12),
                  child: Transform.rotate(
                    angle: -math.pi / 4,
                    child: Text(
                      DateFormat('HH:mm').format(d.timestamp),
                      style: TextStyle(fontFamily: 'Poppins', color: AppColors.textMuted, fontSize: 8),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _getInterval(),
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final label = sensorType == 'ph' ? value.toStringAsFixed(1) : value.toStringAsFixed(0);
                return Text(
                  label,
                  style: TextStyle(fontFamily: 'Poppins', color: AppColors.textMuted, fontSize: 9),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _getInterval(),
          verticalInterval: 1,
          getDrawingHorizontalLine: (v) => FlLine(color: AppColors.textMuted.withValues(alpha: 0.1), strokeWidth: 1),
          getDrawingVerticalLine: (v) => FlLine(color: AppColors.textMuted.withValues(alpha: 0.1), strokeWidth: 1),
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
      case 'temperature': return 35;
      default: return 100;
    }
  }

  double _getInterval() {
    switch (sensorType) {
      case 'ph':
        return 2.0;
      case 'turbidity':
        return 10.0;
      case 'temperature':
        return 5.0;
      default:
        return 20.0;
    }
  }
}

