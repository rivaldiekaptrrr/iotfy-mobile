import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'models/broker_config.dart';
import 'models/dashboard_config.dart';
import 'models/panel_widget_config.dart';
import 'models/rule_config.dart';
import 'models/alarm_event.dart';
import 'providers/storage_providers.dart';
import 'screens/dashboard_screen.dart';
import 'screens/broker_list_screen.dart';

//ssssss
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters
  Hive.registerAdapter(BrokerConfigAdapter());
  Hive.registerAdapter(DashboardConfigAdapter());
  Hive.registerAdapter(PanelWidgetConfigAdapter());
  Hive.registerAdapter(WidgetTypeAdapter());
  Hive.registerAdapter(RuleConfigAdapter());
  Hive.registerAdapter(RuleOperatorAdapter());
  Hive.registerAdapter(RuleActionTypeAdapter());
  Hive.registerAdapter(RuleActionAdapter());
  Hive.registerAdapter(AlarmEventAdapter());
  Hive.registerAdapter(AlarmSeverityAdapter());
  Hive.registerAdapter(AlarmStatusAdapter());

  // Open boxes
  await Hive.openBox<RuleConfig>('rule_configs');
  await Hive.openBox<AlarmEvent>('alarm_events');

  // Request notification permission for Android 13+
  await _requestNotificationPermission();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> _requestNotificationPermission() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Request permission on Android 13+ (API 33+)
  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidImplementation != null) {
    final bool? granted = await androidImplementation.requestNotificationsPermission();
    print('[PERMISSION] Notification permission: ${granted ?? false}');
  }
}
  
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'IoT MQTT Panel',
      debugShowCheckedModeBanner: false,
        theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6), // Blue 500
          primary: const Color(0xFF2563EB), // Blue 600
          secondary: const Color(0xFF64748B), // Slate 500
          surface: const Color(0xFFF1F5F9), // Slate 100
          onSurface: const Color(0xFF1E293B), // Slate 800
          surfaceContainerHighest: const Color(0xFFE2E8F0), // Slate 200
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC), // Slate 50
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A), // Slate 900
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: Color(0xFF334155)), // Slate 700
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1), // Slate 200
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)), // Slate 300
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)), // Slate 200
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5), // Blue 500
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Color(0xFF0F172A),
          ),
          titleMedium: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF334155), // Slate 700
            height: 1.4,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B), // Slate 500
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6), // Blue 500
          primary: const Color(0xFF60A5FA), // Blue 400
          secondary: const Color(0xFF94A3B8), // Slate 400
          surface: const Color(0xFF0F172A), // Slate 900
          onSurface: const Color(0xFFF8FAFC), // Slate 50
          surfaceContainerHighest: const Color(0xFF1E293B), // Slate 800
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: Color(0xFF94A3B8)),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B), // Slate 800
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155), width: 1), // Slate 700
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B), // Slate 800
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Color(0xFFF8FAFC),
          ),
          titleMedium: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFFF1F5F9),
            letterSpacing: -0.2,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFFCBD5E1), // Slate 300
            height: 1.4,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8), // Slate 400
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Wait for providers to initialize
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      final currentDashboard = ref.read(currentDashboardIdProvider);
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => currentDashboard != null 
              ? const DashboardScreen() 
              : const BrokerListScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_queue,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'IoT MQTT Panel',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}