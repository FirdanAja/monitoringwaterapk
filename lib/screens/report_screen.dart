import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/theme_provider.dart';
import '../models/sensor_data.dart';
import '../utils/app_colors.dart';
import '../utils/responsive_helper.dart';
import '../widgets/sensor_widgets.dart';
import '../widgets/chart_widgets.dart';
import '../services/notification_service.dart';
import '../services/pdf_service.dart';
import 'package:open_filex/open_filex.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int _selectedView = 0; // 0: Statistik Status, 1: Tren

  static const List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Consumer<SensorProvider>(
      builder: (context, provider, _) {
        final report = provider.generateMonthlyReport(_selectedYear, _selectedMonth);

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Laporan Bulanan',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold),
            ),
            actions: [
              if (report != null && report.dailyData.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.picture_as_pdf_rounded, color: AppColors.accent),
                  onPressed: () => _exportToPdf(report),
                ),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.responsive.w(16)),
            child: Column(
              children: [
                _buildHeaderControls(),
                const SizedBox(height: 12),
                if (report == null)
                  Expanded(child: _buildNoDataView())
                else
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RINGKASAN STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        _buildCompactSummary(report),
                        const SizedBox(height: 12),
                        _buildStatsRow(report),
                        const SizedBox(height: 16),
                        Text('RATA-RATA PARAMETER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1)),
                        const SizedBox(height: 10),
                        _buildParameterAverages(report),
                        const SizedBox(height: 16),
                        Expanded(child: _buildInteractiveChartSection(report)),
                        const SizedBox(height: 80), // Balanced space for floating nav
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderControls() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _compactDropdown<int>(
            value: _selectedMonth,
            items: List.generate(12, (i) => DropdownMenuItem(
              value: i + 1,
              child: Text(_months[i], style: const TextStyle(fontSize: 12)),
            )),
            onChanged: (v) => setState(() => _selectedMonth = v!),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _compactDropdown<int>(
            value: _selectedYear,
            items: List.generate(3, (i) {
              final y = DateTime.now().year - i;
              return DropdownMenuItem(value: y, child: Text('$y', style: const TextStyle(fontSize: 12)));
            }),
            onChanged: (v) => setState(() => _selectedYear = v!),
          ),
        ),
      ],
    );
  }

  Widget _compactDropdown<T>({required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.bgCard,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCompactSummary(MonthlyReport report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.isDarkMode
              ? [AppColors.primary.withValues(alpha: 0.2), AppColors.accent.withValues(alpha: 0.1)]
              : [AppColors.primary.withValues(alpha: 0.1), AppColors.accent.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.isDarkMode
              ? AppColors.accent.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STATUS RATA-RATA', style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 4),
              StatusBadge(status: report.overallStatus),
              const SizedBox(height: 8),
              Text('${report.totalReadings} Data Teranalisis', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                report.avgQualityScore.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold, 
                  color: AppColors.isDarkMode ? Colors.white : AppColors.primary,
                ),
              ),
              Text('SKOR RATA-RATA', style: TextStyle(fontSize: 8, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(MonthlyReport report) {
    return Row(
      children: [
        _miniStat('Baik', report.goodCount, AppColors.good),
        const SizedBox(width: 8),
        _miniStat('Sedang', report.moderateCount, AppColors.warning),
        const SizedBox(width: 8),
        _miniStat('Bahaya', report.poorCount, AppColors.danger),
      ],
    );
  }

  Widget _miniStat(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 8, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterAverages(MonthlyReport report) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _paramCircle('pH', report.avgPh.toStringAsFixed(1), AppColors.chartPH),
        _paramCircle('NTU', report.avgTurbidity.toStringAsFixed(1), AppColors.chartTurbidity),
        _paramCircle('°C', report.avgTemperature.toStringAsFixed(1), AppColors.chartTemp),
      ],
    );
  }

  Widget _paramCircle(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildInteractiveChartSection(MonthlyReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ANALISIS GRAFIK BULANAN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Scrollable Toggles with Icons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _viewToggle(0, 'Statistik Status', Icons.pie_chart_rounded, AppColors.accent),
                      const SizedBox(width: 8),
                      _viewToggle(1, 'pH Air', Icons.water_drop_rounded, AppColors.chartPH),
                      const SizedBox(width: 8),
                      _viewToggle(2, 'Kekeruhan', Icons.opacity_rounded, AppColors.chartTurbidity),
                      const SizedBox(width: 8),
                      _viewToggle(3, 'Suhu Air', Icons.thermostat_rounded, AppColors.chartTemp),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildSelectedChart(report),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedChart(MonthlyReport report) {
    switch (_selectedView) {
      case 0:
        return QualityBarChart(
          drinkable: report.goodCount,
          usable: report.moderateCount,
          notDrinkable: report.poorCount,
          total: report.totalReadings,
        );
      case 1:
        return SensorLineChart(data: report.dailyData, sensorType: 'ph', maxPoints: 31);
      case 2:
        return SensorLineChart(data: report.dailyData, sensorType: 'turbidity', maxPoints: 31);
      case 3:
        return SensorLineChart(data: report.dailyData, sensorType: 'temperature', maxPoints: 31);
      default:
        return const SizedBox();
    }
  }

  Widget _viewToggle(int index, String label, IconData icon, Color color) {
    final isSelected = _selectedView == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedView = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? color : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label, 
              style: TextStyle(
                fontSize: 10, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
                color: isSelected ? color : AppColors.textMuted
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_chart_outlined_rounded, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('Belum ada data untuk periode ini', style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Future<void> _exportToPdf(MonthlyReport report) async {
    try {
      final file = await PdfService.generateMonthlyReport(report);
      
      if (mounted) {
        final fileName = file.path.split('/').last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Laporan PDF disimpan ke: $fileName'),
            backgroundColor: AppColors.good,
            action: SnackBarAction(
              label: 'BUKA',
              textColor: Colors.white,
              onPressed: () async {
                final result = await OpenFilex.open(file.path);
                if (result.type != ResultType.done) {
                  debugPrint('Gagal membuka file: ${result.message}');
                }
              },
            ),
          ),
        );
        
        // Show system notification
        await NotificationService().showFileDownloadedNotification(
          fileName: fileName,
          filePath: file.path,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor PDF: $e'), backgroundColor: AppColors.danger)
        );
      }
    }
  }
}

