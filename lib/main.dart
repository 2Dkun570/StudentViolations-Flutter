import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/violation_provider.dart';
import 'providers/theme_mode_provider.dart';
import 'services/database_service.dart';
import 'screens/login_screen.dart';
import 'screens/guard_dashboard.dart';
import 'screens/student_dashboard.dart';
import 'models/user.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'theme/app_theme.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseService.initialize();

  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FCMService.initialize();
  }

  runApp(const MyApp());
}

// ── Official ACLC College of Mandaue Brand Colors ─────────────────────────────
class ACLCColors {
  static const red = AppColors.red;
  static const navy = AppColors.navy;
  static const navyLight = AppColors.navyLight;
  static const redDark = AppColors.redDark;
  static const white = AppColors.surface;
  static const gray = AppColors.background;
  static const cardBg = AppColors.surface;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ViolationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeModeProvider()..load()),
      ],
      child: Consumer<ThemeModeProvider>(
        builder: (context, themeModeProvider, _) => MaterialApp(
          title: 'ACLC Student Violation System',
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/dashboard': (context) => const DashboardWrapper(),
          },
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeModeProvider.themeMode,
          themeAnimationDuration: Duration.zero,
        ),
      ),
    );
  }
}

// Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();
    if (!mounted) return;
    if (authProvider.currentUser != null) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F136E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'ACLC Student Violation System',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard Router
class DashboardWrapper extends StatelessWidget {
  const DashboardWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        if (user == null) return const LoginScreen();
        switch (user.role) {
          case UserRole.guard:
            return const GuardDashboard();
          case UserRole.student:
            return const StudentDashboard();
          case UserRole.sao:
            return const LoginScreen();
        }
      },
    );
  }
}
