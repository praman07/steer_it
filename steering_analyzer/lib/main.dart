import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'presentation/pages/home_page.dart';
import 'presentation/pages/calibration_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/pages/engineering_page.dart';
import 'presentation/providers/steering_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SchedulerBinding.instance.scheduleFrame();
  runApp(const SteeringAnalyzerApp());
}

class SteeringAnalyzerApp extends StatelessWidget {
  const SteeringAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SteeringProvider>(
      create: (_) => SteeringProvider(),
      child: MaterialApp(
        title: 'Steering Analyzer',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const MainNavigationWrapper(),
      ),
    );
  }

  ThemeData _buildTheme() {
    // Pure monochrome premium theme matching Apple / Tesla guidelines.
    const Color bg = Color(0xFF000000);
    const Color surface = Color(0xFF0A0A0A);
    final ColorScheme cs = const ColorScheme.dark(
      primary: Color(0xFFFFFFFF),
      secondary: Color(0xFF888888),
      surface: surface,
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFFFFFFFF),
      onSurface: Color(0xFFFFFFFF),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFFFFFFFF)),
        labelLarge: TextStyle(color: Color(0xFFFFFFFF)),
      ),
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  SteeringProvider? _provider;

  final List<Widget> _pages = const [
    HomePage(),
    CalibrationPage(),
    SettingsPage(),
    EngineeringPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<SteeringProvider>();
      _provider!.start(); // Start sensors immediately on app startup
    });
  }

  @override
  void dispose() {
    _provider?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF1E1E1E), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF000000),
          selectedItemColor: const Color(0xFFFFFFFF),
          unselectedItemColor: const Color(0xFF555555),
          selectedFontSize: 9,
          unselectedFontSize: 9,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, letterSpacing: 1.0),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'DRIVE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.center_focus_strong_outlined),
              activeIcon: Icon(Icons.center_focus_strong),
              label: 'CALIBRATE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune_outlined),
              activeIcon: Icon(Icons.tune),
              label: 'SETTINGS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.science_outlined),
              activeIcon: Icon(Icons.science),
              label: 'LAB',
            ),
          ],
        ),
      ),
    );
  }
}
