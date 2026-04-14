import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import '../models/sensor_data.dart';
import '../utils/app_colors.dart';
import '../widgets/sensor_widgets.dart';
import '../widgets/chart_widgets.dart';
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, provider, _) {
        final report = provider.generateMonthlyReport(
          _selectedYear,
          _selectedMonth,
        );

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.bgDark,
                title: const Text(
                  'Laporan Bulanan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  if (report != null && report.dailyData.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.download, color: AppColors.accent),
                      tooltip: 'Export ke Excel',
                      onPressed: () => _exportToExcel(report),
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month selector
                      _buildMonthSelector(),
                      const SizedBox(height: 20),

                      if (report == null)
                        _buildNoDataCard()
                      else ...[
                        // Summary card
                        _buildSummaryCard(report),
                        const SizedBox(height: 16),

                        // Stats grid
                        _buildStatsGrid(report),
                        const SizedBox(height: 16),

                        // Bar chart
                        _buildSectionTitle('Distribusi Kualitas Air'),
                        const SizedBox(height: 12),
                        GlassCard(
                          child: SizedBox(
                            height: 200,
                            child: QualityBarChart(
                              drinkable: report.goodCount,
                              usable: report.moderateCount,
                              notDrinkable: report.poorCount,
                              total: report.totalReadings,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Trend charts
                        _buildSectionTitle('Tren Sensor Bulanan'),
                        const SizedBox(height: 12),
                        _buildMonthlyTrendCharts(report),
                        const SizedBox(height: 16),

                        // Parameter averages
                        _buildSectionTitle('Rata-rata Parameter'),
                        const SizedBox(height: 12),
                        _buildParameterSummary(report),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Periode Laporan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Year selector
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      dropdownColor: AppColors.bgCard,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      items: List.generate(3, (i) {
                        final y = DateTime.now().year - i;
                        return DropdownMenuItem(
                          value: y,
                          child: Text(
                            '$y',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }),
                      onChanged: (v) => setState(() => _selectedYear = v!),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Month selector
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedMonth,
                      dropdownColor: AppColors.bgCard,
                      isExpanded: true,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      items: List.generate(12, (i) {
                        return DropdownMenuItem(
                          value: i + 1,
                          child: Text(
                            _months[i],
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }),
                      onChanged: (v) => setState(() => _selectedMonth = v!),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.bar_chart, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Tidak ada data untuk ${_months[_selectedMonth - 1]} $_selectedYear',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(MonthlyReport report) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.6),
            AppColors.accent.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${report.monthName} ${report.year}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${report.totalReadings} pembacaan sensor',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              StatusBadge(status: report.overallStatus, large: true),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                report.avgQualityScore.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Rata-rata Skor',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(MonthlyReport report) {
    return Row(
      children: [
        Expanded(
          child: _statCard('✅ Layak Minum', report.goodCount, AppColors.good),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCard(
            '🟡 Layak Tidak',
            report.moderateCount,
            AppColors.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child:
              _statCard('🔴 Tidak Layak', report.poorCount, AppColors.danger),
        ),
      ],
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendCharts(MonthlyReport report) {
    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'pH Bulanan',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.chartPH,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: SensorLineChart(
                  data: report.dailyData,
                  sensorType: 'ph',
                  maxPoints: 60,
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
                'Kekeruhan Bulanan (NTU)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.chartTurbidity,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: SensorLineChart(
                  data: report.dailyData,
                  sensorType: 'turbidity',
                  maxPoints: 60,
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
                'Suhu Bulanan (°C)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.chartTemp,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: SensorLineChart(
                  data: report.dailyData,
                  sensorType: 'temperature',
                  maxPoints: 60,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParameterSummary(MonthlyReport report) {
    return GlassCard(
      child: Column(
        children: [
          _paramRow(
            'pH rata-rata',
            report.avgPh.toStringAsFixed(2),
            'pH',
            '6.5 - 8.5',
            AppColors.chartPH,
          ),
          const Divider(color: AppColors.bgSurface, height: 20),
          _paramRow(
            'Kekeruhan rata-rata',
            report.avgTurbidity.toStringAsFixed(1),
            'NTU',
            '< 5 NTU',
            AppColors.chartTurbidity,
          ),
          const Divider(color: AppColors.bgSurface, height: 20),
          _paramRow(
            'Suhu rata-rata',
            report.avgTemperature.toStringAsFixed(1),
            '°C',
            '10 - 30°C',
            AppColors.chartTemp,
          ),
        ],
      ),
    );
  }

  Widget _paramRow(
    String label,
    String value,
    String unit,
    String standard,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'Standar: $standard',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
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

  Future<void> _exportToExcel(MonthlyReport report) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Laporan Kualitas Air'];
      excel.setDefaultSheet('Laporan Kualitas Air');

      // Add Headers
      sheetObject.appendRow([
        TextCellValue('Tanggal & Waktu'),
        TextCellValue('pH'),
        TextCellValue('Kekeruhan (NTU)'),
        TextCellValue('Suhu (°C)'),
        TextCellValue('Skor Kualitas'),
        TextCellValue('Status'),
      ]);

      // Add Data
      for (var data in report.dailyData) {
        sheetObject.appendRow([
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm:ss').format(data.timestamp)),
          TextCellValue(data.ph.toStringAsFixed(2)),
          TextCellValue(data.turbidity.toStringAsFixed(1)),
          TextCellValue(data.temperature.toStringAsFixed(1)),
          TextCellValue(data.qualityScore.toStringAsFixed(1)),
          TextCellValue(data.status.label),
        ]);
      }

      // Save to temporary file
      var fileBytes = excel.save();
      if (fileBytes == null) throw Exception("Failed to generate excel file bytes.");
      
      // Request Storage Permission just in case
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String filePath = '';
      if (Platform.isAndroid) {
        Directory downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory() ?? Directory('/storage/emulated/0/Download');
        }
        filePath = '${downloadDir.path}/Laporan_Kualitas_Air_$timestamp.xlsx';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/Laporan_Kualitas_Air_$timestamp.xlsx';
      }
      
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengunduh Laporan!\nTersimpan di:\n$filePath'),
            duration: const Duration(seconds: 5),
            backgroundColor: AppColors.good,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor laporan: $e')),
        );
      }
    }
  }
}
