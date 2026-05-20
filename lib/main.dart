import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'providers/sensor_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/report_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'utils/app_colors.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase (try-catch agar tidak crash saat hot restart)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase sudah terinisialisasi (terjadi saat hot restart), abaikan
    debugPrint('Firebase already initialized: $e');
  }

  // Inisialisasi Notifikasi
  await NotificationService().initialize();

  // Inisialisasi Background Service
  await BackgroundService.initialize();

  // Lock orientation portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgCard,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => SensorProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'TirtaSmart',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/home': (context) => const MainNavigationScreen(),
          },
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    HistoryScreen(),
    ReportScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  Future<void> _initializeProvider() async {
    final provider = context.read<SensorProvider>();
    await provider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // Rebuild on theme change

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0)
                    .animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutQuint,
                )),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_currentIndex),
            child: _screens[_currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4), // Even lower (lebih pepet bawah)
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.isDarkMode 
                  ? const Color(0xFF161B22).withValues(alpha: 0.75) 
                  : Colors.white.withValues(alpha: 0.85), // Soft white in light mode
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.isDarkMode 
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.isDarkMode 
                      ? Colors.black.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'Beranda'),
                _buildNavItem(1, Icons.history_rounded, 'Riwayat'),
                _buildNavItem(2, Icons.assessment_rounded, 'Laporan'),
                _buildNavItem(3, Icons.settings_rounded, 'Pengaturan'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              padding: EdgeInsets.all(isSelected ? 10 : 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.accent : AppColors.textMuted,
                size: isSelected ? 22 : 20,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? AppColors.accent : AppColors.textMuted,
              ),
              child: Text(label),
            ),
            // Active dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(top: 2),
              height: 3,
              width: isSelected ? 12 : 0,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(color: AppColors.accent.withValues(alpha: 0.5), blurRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
