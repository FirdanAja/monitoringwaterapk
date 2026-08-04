import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';
import '../utils/responsive_helper.dart';
import '../widgets/sensor_widgets.dart';
import '../services/notification_service.dart';
import '../models/sensor_data.dart';

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
    context.watch<ThemeProvider>();
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

                  Row(
                    children: [
                      Expanded(
                        child: _buildNotificationCard(provider),
                      ),
                      SizedBox(width: res.w(12)),
                      Expanded(
                        child: _buildThemeModeCard(),
                      ),
                    ],
                  ),

                  SizedBox(height: res.h(12)),

                  _buildStandardsCard(provider),

                  _buildSectionHeader('Informasi Aplikasi'),
                  SizedBox(height: res.h(8)),
                  _buildAppInfoCard(),

                  SizedBox(height: res.h(16)),

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
                  color: AppColors.accent, size: context.responsive.w(20)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alert kualitas air',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: context.responsive.sp(9.5),
                  color: AppColors.textMuted,
                ),
              ),
              GestureDetector(
                onTap: () {
                  final testData = SensorData(
                    ph: 4.5,
                    turbidity: 35.0,
                    temperature: 24.5,
                    timestamp: DateTime.now(),
                    status: WaterQualityStatus.notDrinkable,
                    fuzzyResult: 'Sangat Buruk',
                    qualityScore: 15.0,
                  );
                  provider.updateSettings(notifications: true);
                  setState(() => _notifEnabled = true);
                  NotificationService().sendWaterQualityAlert(
                    data: testData,
                    fuzzyResult: 'Sangat Buruk',
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Uji Coba',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: context.responsive.sp(8),
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
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

  Widget _buildThemeModeCard() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        return GlassCard(
          padding: EdgeInsets.all(context.responsive.w(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppColors.accent,
                    size: context.responsive.w(20),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isDark,
                      onChanged: (v) {
                        themeProvider.toggleTheme();
                      },
                      activeThumbColor: AppColors.accent,
                      activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.responsive.h(4)),
              Text(
                'Mode Gelap',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: context.responsive.sp(12),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                isDark ? 'Tema Gelap Aktif' : 'Tema Terang Aktif',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: context.responsive.sp(10),
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStandardsCard(SensorProvider provider) {
    final res = context.responsive;
    return GlassCard(
      padding: EdgeInsets.all(res.w(12)),
      child: Row(
        children: [
          Expanded(
            child: _buildEditableStandard(
                'Batas pH',
                '${provider.phAsamLimit} - ${provider.phNormalLimit}',
                AppColors.chartPH,
                () => _showEditThresholdDialog('pH_Detailed', provider)),
          ),
          Container(
            width: 1,
            height: res.h(45),
            color: AppColors.isDarkMode
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
            margin: EdgeInsets.symmetric(horizontal: res.w(4)),
          ),
          Expanded(
            child: _buildEditableStandard(
                'Batas NTU',
                '${provider.turbJernihLimit} - ${provider.turbAgakKeruhLimit}',
                AppColors.chartTurbidity,
                () => _showEditThresholdDialog('Turbidity_Detailed', provider)),
          ),
          Container(
            width: 1,
            height: res.h(45),
            color: AppColors.isDarkMode
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
            margin: EdgeInsets.symmetric(horizontal: res.w(4)),
          ),
          Expanded(
            child: _buildEditableStandard(
                'Batas Suhu',
                '${provider.tempDinginLimit} - ${provider.tempNormalLimit}',
                AppColors.chartTemp,
                () =>
                    _showEditThresholdDialog('Temperature_Detailed', provider)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableStandard(
      String label, String value, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: context.responsive.sp(10),
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: context.responsive.sp(10),
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ketuk untuk ubah',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: context.responsive.sp(7),
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditThresholdDialog(String type, SensorProvider provider) {
    final TextEditingController controller1 = TextEditingController();
    final TextEditingController controller2 = TextEditingController();
    String title = '';
    String label1 = '';
    String label2 = '';
    bool isRange = true;

    if (type == 'pH_Detailed') {
      title = 'Konfigurasi Batas pH';
      label1 = 'Batas Asam (Netral mulai dari)';
      label2 = 'Batas Netral (Basa mulai dari)';
      controller1.text = provider.phAsamLimit.toString();
      controller2.text = provider.phNormalLimit.toString();
    } else if (type == 'Turbidity_Detailed') {
      title = 'Konfigurasi Kekeruhan (NTU)';
      label1 = 'Batas Jernih (Agak Keruh mulai)';
      label2 = 'Batas Agak Keruh (Keruh mulai)';
      controller1.text = provider.turbJernihLimit.toString();
      controller2.text = provider.turbAgakKeruhLimit.toString();
    } else if (type == 'Temperature_Detailed') {
      title = 'Konfigurasi Suhu (°C)';
      label1 = 'Batas Dingin (Sedang mulai)';
      label2 = 'Batas Sedang (Tinggi mulai)';
      controller1.text = provider.tempDinginLimit.toString();
      controller2.text = provider.tempNormalLimit.toString();
    } else if (type == 'pH') {
      title = 'Edit Ambang Batas pH';
      label1 = 'Minimal';
      label2 = 'Maksimal';
      controller1.text = provider.phMin.toString();
      controller2.text = provider.phMax.toString();
    } else if (type == 'Kekeruhan') {
      title = 'Edit Batas Kekeruhan';
      label1 = 'Maksimal (NTU)';
      controller1.text = provider.turbMax.toString();
      isRange = false;
    } else {
      title = 'Edit Ambang Batas Suhu';
      label1 = 'Minimal (°C)';
      label2 = 'Maksimal (°C)';
      controller1.text = provider.tempMin.toString();
      controller2.text = provider.tempMax.toString();
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller1,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: label1,
                labelStyle: TextStyle(color: AppColors.textMuted),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: AppColors.textMuted.withValues(alpha: 0.2))),
              ),
            ),
            if (isRange) ...[
              const SizedBox(height: 12),
              TextField(
                controller: controller2,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: label2,
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: AppColors.textMuted.withValues(alpha: 0.2))),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final val1 = double.tryParse(controller1.text);
              final val2 = isRange ? double.tryParse(controller2.text) : null;

              if (val1 != null && (!isRange || val2 != null)) {
                if (type == 'pH_Detailed') {
                  provider.updateThresholds(
                      phAsamLimit: val1, phNormalLimit: val2);
                } else if (type == 'Turbidity_Detailed') {
                  provider.updateThresholds(
                      turbJernihLimit: val1, turbAgakKeruhLimit: val2);
                } else if (type == 'Temperature_Detailed') {
                  provider.updateThresholds(
                      tempDinginLimit: val1, tempNormalLimit: val2);
                } else if (type == 'pH') {
                  provider.updateThresholds(phMin: val1, phMax: val2);
                } else if (type == 'Kekeruhan') {
                  provider.updateThresholds(turbMax: val1);
                } else {
                  provider.updateThresholds(tempMin: val1, tempMax: val2);
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: const Text('Ambang batas berhasil diperbarui'),
                      backgroundColor: AppColors.good),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Simpan',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
        'items': ['Asam', 'Netral', 'Basa'],
      },
      {
        'title': 'Turb Sets',
        'items': ['Bersih', 'Agak Keruh', 'Keruh'],
      },
      {
        'title': 'Temp Sets',
        'items': ['Dingin', 'Sedang', 'Tinggi'],
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
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
