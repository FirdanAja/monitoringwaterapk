import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sensor_provider.dart';
import '../models/sensor_data.dart';
import '../utils/app_colors.dart';
import '../widgets/sensor_widgets.dart';
import '../widgets/chart_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _fromDate;
  DateTime? _toDate;
  WaterQualityStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                floating: true,
                backgroundColor: AppColors.bgDark,
                title: const Text(
                  'Riwayat Data Sensor',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.filter_list,
                      color: AppColors.accent,
                    ),
                    onPressed: () => _showFilterDialog(context, provider),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.danger,
                    ),
                    onPressed: () => _confirmClear(context, provider),
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.accent,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Data Tabel'),
                    Tab(text: 'Grafik Tren'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [_buildTableView(provider), _buildChartView(provider)],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableView(SensorProvider provider) {
    final data = provider.filteredHistory;

    if (data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'Belum ada data historis',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Data akan muncul saat sensor mulai mengirim',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (ctx, i) => _buildHistoryItem(data[i], i),
    );
  }

  Widget _buildHistoryItem(SensorData d, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderColor: _getStatusColor(d.status).withValues(alpha: 0.2),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(d.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: _getStatusColor(d.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM, HH:mm').format(d.timestamp),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      StatusBadge(status: d.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _sensorChip(
                        'pH',
                        d.ph.toStringAsFixed(2),
                        AppColors.chartPH,
                      ),
                      const SizedBox(width: 8),
                      _sensorChip(
                        'NTU',
                        d.turbidity.toStringAsFixed(1),
                        AppColors.chartTurbidity,
                      ),
                      const SizedBox(width: 8),
                      _sensorChip(
                        '°C',
                        d.temperature.toStringAsFixed(1),
                        AppColors.chartTemp,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Skor Fuzzy: ${d.qualityScore.toStringAsFixed(1)}/100',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sensorChip(String unit, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$value $unit',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildChartView(SensorProvider provider) {
    final data = provider.filteredHistory.reversed.toList();
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tren pH',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.chartPH,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: SensorLineChart(
                    data: data,
                    sensorType: 'ph',
                    maxPoints: 50,
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
                  'Tren Kekeruhan (NTU)',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.chartTurbidity,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: SensorLineChart(
                    data: data,
                    sensorType: 'turbidity',
                    maxPoints: 50,
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
                  'Tren Suhu (°C)',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.chartTemp,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: SensorLineChart(
                    data: data,
                    sensorType: 'temperature',
                    maxPoints: 50,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Color _getStatusColor(WaterQualityStatus s) {
    switch (s) {
      case WaterQualityStatus.drinkable:
        return AppColors.good;
      case WaterQualityStatus.usable:
        return AppColors.warning;
      case WaterQualityStatus.notDrinkable:
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  void _showFilterDialog(BuildContext context, SensorProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        fromDate: _fromDate,
        toDate: _toDate,
        statusFilter: _statusFilter,
        onApply: (from, to, status) {
          setState(() {
            _fromDate = from;
            _toDate = to;
            _statusFilter = status;
          });
          provider.filterHistory(from: from, to: to, status: status);
          Navigator.pop(context);
        },
        onClear: () {
          setState(() {
            _fromDate = null;
            _toDate = null;
            _statusFilter = null;
          });
          provider.clearFilter();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _confirmClear(BuildContext context, SensorProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Semua Data',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Yakin ingin menghapus seluruh riwayat data sensor?',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text(
              'Hapus',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final WaterQualityStatus? statusFilter;
  final Function(DateTime?, DateTime?, WaterQualityStatus?) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.fromDate,
    required this.toDate,
    required this.statusFilter,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  DateTime? _from;
  DateTime? _to;
  WaterQualityStatus? _status;

  @override
  void initState() {
    super.initState();
    _from = widget.fromDate;
    _to = widget.toDate;
    _status = widget.statusFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Data',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _dateButton(
                  'Dari',
                  _from,
                  (d) => setState(() => _from = d),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dateButton(
                  'Sampai',
                  _to,
                  (d) => setState(() => _to = d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Status:',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: WaterQualityStatus.values
                .where((s) => s != WaterQualityStatus.unknown)
                .map(
                  (s) => FilterChip(
                    label: Text(
                      s.label,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: _status == s
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                    selected: _status == s,
                    onSelected: (v) => setState(() => _status = v ? s : null),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.bgCardLight,
                    checkmarkColor: Colors.white,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClear,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.textMuted),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onApply(_from, _to, _status),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    'Terapkan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  Widget _dateButton(
    String label,
    DateTime? date,
    ValueChanged<DateTime> onPicked,
  ) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.accent,
                surface: AppColors.bgCard,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      icon: const Icon(Icons.calendar_today, size: 14, color: AppColors.accent),
      label: Text(
        date != null ? DateFormat('dd/MM/yy').format(date) : label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: date != null ? AppColors.accent : AppColors.textMuted,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: date != null
              ? AppColors.accent.withValues(alpha: 0.5)
              : AppColors.textMuted.withValues(alpha: 0.3),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      ),
    );
  }
}
