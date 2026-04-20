import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'models/broker_config.dart';
import 'models/dashboard_config.dart';
import 'models/panel_widget_config.dart';
import 'models/rule_config.dart';
import 'models/alarm_event.dart';
import 'screens/splash_screen.dart';
import 'services/rule_evaluator_service.dart';
import 'services/rule_schedule_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters - HANYA SEKALI, tanpa duplikasi!
  Hive.registerAdapter(BrokerConfigAdapter());
  Hive.registerAdapter(CertificateTypeAdapter());
  Hive.registerAdapter(SslConfigAdapter());
  Hive.registerAdapter(DashboardConfigAdapter());
  Hive.registerAdapter(PanelWidgetConfigAdapter());
  Hive.registerAdapter(WidgetTypeAdapter());
  Hive.registerAdapter(RuleConfigAdapter());
  Hive.registerAdapter(RuleOperatorAdapter());
  Hive.registerAdapter(RuleActionTypeAdapter());
  Hive.registerAdapter(RuleActionAdapter());
  Hive.registerAdapter(RuleTriggerTypeAdapter());
  Hive.registerAdapter(ScheduleTypeAdapter());
  Hive.registerAdapter(ScheduleConfigAdapter());
  Hive.registerAdapter(AlarmEventAdapter());
  Hive.registerAdapter(AlarmSeverityAdapter());
  Hive.registerAdapter(AlarmStatusAdapter());

  // Open boxes
  await Hive.openBox<RuleConfig>('rule_configs');
  await Hive.openBox<AlarmEvent>('alarm_events');

  // Request notification permission for Android 13+
  await _requestNotificationPermission();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _requestNotificationPermission() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Request permission on Android 13+ (API 33+)
  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

  if (androidImplementation != null) {
    final bool? granted = await androidImplementation
        .requestNotificationsPermission();
    debugPrint('[PERMISSION] Notification permission: ${granted ?? false}');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize background services
    ref.watch(ruleEvaluatorProvider);
    ref.watch(ruleScheduleProvider);

    return MaterialApp(
      title: 'IoT MQTT Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo
          primary: const Color(0xFF4F46E5), // Indigo 600
          secondary: const Color(0xFF0EA5E9), // Sky 500
          surface: const Color(0xFFF8FAFC), // Slate 50
          onSurface: const Color(0xFF1E293B), // Slate 800
          surfaceContainerHighest: const Color(0xFFE2E8F0), // Slate 200
          outline: const Color(0xFFCBD5E1),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Slate 100
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            fontFamily: 'Plus Jakarta Sans', // Fallback handled by system
          ),
          iconTheme: IconThemeData(color: Color(0xFF1E293B)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: Color(0xFF1E293B),
          ),
          displayMedium: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Color(0xFF1E293B),
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFF1E293B),
          ),
          titleMedium: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF1E293B),
          ),
          bodyLarge: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Color(0xFF334155),
          ),
          bodyMedium: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF475569),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: const Color(0x404F46E5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          primary: const Color(0xFF818CF8), // Indigo 400
          secondary: const Color(0xFF38BDF8), // Sky 400
          surface: const Color(0xFF0F172A), // Slate 900
          onSurface: const Color(0xFFF8FAFC), // Slate 50
          surfaceContainerHighest: const Color(0xFF1E293B), // Slate 800
          outline: const Color(0xFF334155),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(
          0xFF020617,
        ), // Slate 950 (Deep Dark)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            fontFamily: 'Plus Jakarta Sans',
          ),
          iconTheme: IconThemeData(color: Color(0xFF94A3B8)),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF334155), width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: Color(0xFFF8FAFC),
          ),
          displayMedium: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Color(0xFFF8FAFC),
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFFF8FAFC),
          ),
          titleMedium: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFFF1F5F9),
          ),
          bodyLarge: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Color(0xFFCBD5E1),
          ),
          bodyMedium: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF94A3B8),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: const Color(0x406366F1),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0F172A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
