import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import '../utils/app_colors.dart';
import '../utils/responsive_helper.dart';
import '../widgets/sensor_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifEnabled = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SensorProvider>();
    _notifEnabled = provider.notificationsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.bgDark,
                title: Text(
                  'Pengaturan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: context.responsive.sp(18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(context.responsive.w(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notifikasi
                      _buildSectionHeader('Notifikasi'),
                      const SizedBox(height: 12),
                      GlassCard(
                        child: Column(
                          children: [
                            _buildSwitchTile(
                              title: 'Push Notification',
                              subtitle:
                                  'Terima peringatan saat kualitas air buruk',
                              value: _notifEnabled,
                              onChanged: (v) {
                                setState(() => _notifEnabled = v);
                                provider.updateSettings(notifications: v);
                              },
                              icon: Icons.notifications_active,
                              color: AppColors.accent,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Standar Kualitas Air
                      _buildSectionHeader('Standar Kualitas Air (WHO/PDAM)'),
                      const SizedBox(height: 12),
                      GlassCard(
                        child: Column(
                          children: [
                            _buildStandardRow(
                              'pH',
                              '6.5 - 8.5',
                              AppColors.chartPH,
                            ),
                            const Divider(
                              color: AppColors.bgSurface,
                              height: 24,
                            ),
                            _buildStandardRow(
                              'Kekeruhan',
                              '< 5 NTU',
                              AppColors.chartTurbidity,
                            ),
                            const Divider(
                              color: AppColors.bgSurface,
                              height: 24,
                            ),
                            _buildStandardRow(
                              'Suhu',
                              '10 - 30°C',
                              AppColors.chartTemp,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Informasi Aplikasi
                      _buildSectionHeader('Informasi Aplikasi'),
                      const SizedBox(height: 12),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow(
                              'Nama Aplikasi',
                              'TirtaSmart',
                            ),
                            const Divider(
                              color: AppColors.bgSurface,
                              height: 20,
                            ),
                            _infoRow('Versi', '1.0.0'),
                            const Divider(
                              color: AppColors.bgSurface,
                              height: 20,
                            ),
                            _infoRow('Metode Analisis', 'Fuzzy Logic Mamdani'),
                            const Divider(
                              color: AppColors.bgSurface,
                              height: 20,
                            ),
                            _infoRow(
                                'Protokol IoT', 'Firebase Realtime Database'),
                            const Divider(
                              color: AppColors.bgSurface,
                              height: 20,
                            ),
                            _infoRow('Platform Hardware', 'ESP8266'),
                            const Divider(
                              color: AppColors.bgSurface,
                              height: 20,
                            ),
                            _infoRow('Sensor', 'pH, Turbidity, Temperature'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Fuzzy Logic Info
                      _buildSectionHeader('Konfigurasi Fuzzy Mamdani'),
                      const SizedBox(height: 12),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [_buildFuzzyInfo()],
                        ),
                      ),
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

  Widget _buildSectionHeader(String title) {
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
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: context.responsive.sp(14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: context.responsive.w(40),
          height: context.responsive.w(40),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: context.responsive.w(20)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: context.responsive.sp(13),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: context.responsive.sp(11),
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.accent,
          activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
          inactiveThumbColor: AppColors.textMuted,
          inactiveTrackColor: AppColors.bgSurface,
        ),
      ],
    );
  }

  Widget _buildStandardRow(String param, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          param,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: context.responsive.sp(13),
            color: AppColors.textSecondary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: context.responsive.sp(13),
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: context.responsive.sp(12),
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: context.responsive.sp(12),
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFuzzyInfo() {
    final items = [
      {
        'title': 'Variabel Input',
        'items': ['pH (0-14)', 'Turbidity (0-20 NTU)', 'Suhu (0-50°C)'],
      },
      {
        'title': 'Himpunan Fuzzy pH',
        'items': [
          'Sangat Asam (<4)',
          'Asam (5.5-7)',
          'Normal (6.5-8.5)',
          'Basa (7.5-9.5)',
          'Sangat Basa (>8.5)',
        ],
      },
      {
        'title': 'Himpunan Fuzzy Kekeruhan',
        'items': [
          'Jernih (<3 NTU)',
          'Agak Keruh (1-7 NTU)',
          'Keruh (5-15 NTU)',
          'S.Keruh (>10 NTU)',
        ],
      },
      {
        'title': 'Himpunan Fuzzy Suhu',
        'items': [
          'S.Dingin (<15°C)',
          'Dingin (10-22°C)',
          'Normal (18-28°C)',
          'Hangat (25-33°C)',
          'Panas (>28°C)',
        ],
      },
      {
        'title': 'Output Fuzzy',
        'items': [
          'Sangat Buruk (0-20)',
          'Buruk (20-40)',
          'Cukup (40-60)',
          'Baik (60-80)',
          'Sangat Baik (80-100)',
        ],
      },
      {
        'title': 'Defuzzifikasi',
        'items': ['Metode Centroid (Center of Gravity)'],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section['title'] as String,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 4),
              ...(section['items'] as List<String>).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(left: 12, top: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
// Force VS Code reload event 1
