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
        final res = context.responsive;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: res.w(16),
                vertical: res.h(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: res.h(16)),
                  
                  // Top Row: Notifications & Standards
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _buildNotificationCard(provider),
                      ),
                      SizedBox(width: res.w(12)),
                      Expanded(
                        flex: 5,
                        child: _buildStandardsCard(),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: res.h(16)),
                  
                  // Middle: App Info
                  _buildSectionHeader('Informasi Aplikasi'),
                  SizedBox(height: res.h(8)),
                  _buildAppInfoCard(),
                  
                  SizedBox(height: res.h(16)),
                  
                  // Bottom: Fuzzy Configuration (Compact)
                  _buildSectionHeader('Konfigurasi Fuzzy Mamdani'),
                  SizedBox(height: res.h(8)),
                  Expanded(
                    child: _buildFuzzyConfigCard(),
                  ),
                  
                  SizedBox(height: res.h(12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const AwesomeWaterLogo(size: 32, icon: Icons.settings_rounded),
        const SizedBox(width: 12),
        Text(
          'Pengaturan',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: context.responsive.sp(20),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
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
            fontSize: context.responsive.sp(13),
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(SensorProvider provider) {
    return GlassCard(
      padding: EdgeInsets.all(context.responsive.w(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.notifications_active, 
                color: AppColors.accent, 
                size: context.responsive.w(20)
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _notifEnabled,
                  onChanged: (v) {
                    setState(() => _notifEnabled = v);
                    provider.updateSettings(notifications: v);
                  },
                  activeThumbColor: AppColors.accent,
                  activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          SizedBox(height: context.responsive.h(4)),
          Text(
            'Push Notification',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: context.responsive.sp(12),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Alert kualitas air',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: context.responsive.sp(10),
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardsCard() {
    return GlassCard(
      padding: EdgeInsets.all(context.responsive.w(12)),
      child: Column(
        children: [
          _buildCompactStandard('pH', '6.5-8.5', AppColors.chartPH),
          const Divider(color: Colors.white10, height: 12),
          _buildCompactStandard('Kekeruhan', '<5 NTU', AppColors.chartTurbidity),
          const Divider(color: Colors.white10, height: 12),
          _buildCompactStandard('Suhu', '10-30°C', AppColors.chartTemp),
        ],
      ),
    );
  }

  Widget _buildCompactStandard(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: context.responsive.sp(11),
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: context.responsive.sp(11),
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfoCard() {
    final info = [
      {'label': 'App Name', 'value': 'TirtaSmart'},
      {'label': 'Version', 'value': '1.0.0'},
      {'label': 'Hardware', 'value': 'ESP8266'},
      {'label': 'Protocol', 'value': 'Firebase'},
      {'label': 'Method', 'value': 'Fuzzy Logic'},
      {'label': 'Sensors', 'value': '3 Sensors'},
    ];

    return GlassCard(
      padding: EdgeInsets.all(context.responsive.w(12)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: info.length,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                info[index]['label']!,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: context.responsive.sp(9),
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                info[index]['value']!,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: context.responsive.sp(11),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFuzzyConfigCard() {
    final fuzzyData = [
      {
        'title': 'Input Variable',
        'items': ['pH (0-14)', 'Turb (0-20)', 'Temp (0-50)'],
      },
      {
        'title': 'Output Level',
        'items': ['S.Buruk', 'Buruk', 'Cukup', 'Baik', 'S.Baik'],
      },
      {
        'title': 'pH Sets',
        'items': ['S.Asam', 'Asam', 'Normal', 'Basa', 'S.Basa'],
      },
      {
        'title': 'Turb Sets',
        'items': ['Jernih', 'Agak Keruh', 'Keruh', 'S.Keruh'],
      },
      {
        'title': 'Temp Sets',
        'items': ['S.Dingin', 'Dingin', 'Normal', 'Hangat', 'Panas'],
      },
      {
        'title': 'Method',
        'items': ['Centroid / COG'],
      },
    ];

    return GlassCard(
      padding: EdgeInsets.all(context.responsive.w(12)),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: fuzzyData.length,
        itemBuilder: (context, index) {
          final section = fuzzyData[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section['title'] as String,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: context.responsive.sp(10),
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 0,
                  children: (section['items'] as List<String>).map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: context.responsive.sp(8.5),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
