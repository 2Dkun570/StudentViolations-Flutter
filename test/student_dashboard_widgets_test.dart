import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:violation/providers/auth_provider.dart';
import 'package:violation/providers/violation_provider.dart';
import 'package:violation/providers/theme_mode_provider.dart';
import 'package:violation/screens/guard_dashboard.dart';
import 'package:violation/screens/login_screen.dart';
import 'package:violation/screens/notifications_screen.dart';
import 'package:violation/screens/student_dashboard.dart';
import 'package:violation/main.dart';
import 'package:violation/services/demo_mode.dart';
import 'package:violation/theme/app_theme.dart';
import 'package:violation/widgets/ui_components.dart';

void main() {
  group('Student Dashboard UI Components & Theme Helpers', () {
    test('theme preference persists across provider instances', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeModeProvider();

      await provider.setDarkMode(true);
      expect(provider.themeMode, ThemeMode.dark);

      final restoredProvider = ThemeModeProvider();
      await restoredProvider.load();
      expect(restoredProvider.themeMode, ThemeMode.dark);
    });

    test('remember me controls whether a demo session is restored', () async {
      SharedPreferences.setMockInitialValues({});
      final authProvider = AuthProvider();

      await authProvider.login(
        DemoMode.studentEmail,
        DemoMode.demoPassword,
        rememberMe: true,
      );
      final rememberedProvider = AuthProvider();
      await rememberedProvider.checkAuthStatus();
      expect(rememberedProvider.currentUser, isNotNull);

      await authProvider.logout();
      await authProvider.login(
        DemoMode.studentEmail,
        DemoMode.demoPassword,
        rememberMe: false,
      );
      final unrememberedProvider = AuthProvider();
      await unrememberedProvider.checkAuthStatus();

      expect(authProvider.currentUser, isNotNull);
      expect(unrememberedProvider.currentUser, isNull);
      expect(
        (await SharedPreferences.getInstance()).getString('user_id'),
        isNull,
      );
    });

    testWidgets('Login form remembers a checked demo session', (tester) async {
      SharedPreferences.setMockInitialValues({});
      DemoMode.setDemoActive(false);
      addTearDown(() => DemoMode.setDemoActive(false));
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authProvider = AuthProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: authProvider,
          child: MaterialApp(
            home: const LoginScreen(),
            routes: {
              '/dashboard': (_) =>
                  const Scaffold(body: Text('Signed in dashboard')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        DemoMode.studentEmail,
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        DemoMode.demoPassword,
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Signed in dashboard'), findsOneWidget);
      final restoredProvider = AuthProvider();
      await restoredProvider.checkAuthStatus();
      expect(restoredProvider.currentUser?.id, DemoMode.studentUser.id);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          key: const ValueKey('app-restart-auth-provider'),
          create: (_) => AuthProvider(),
          child: MaterialApp(
            home: const SplashScreen(),
            routes: {
              '/dashboard': (_) =>
                  const Scaffold(body: Text('Remembered session restored')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Remembered session restored'), findsOneWidget);
    });

    testWidgets('StandingGauge renders 3 segments for safe level', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StandingGauge(level: 'safe')),
        ),
      );

      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);
    });

    testWidgets('StandingGauge renders properly for critical level', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StandingGauge(level: 'critical')),
        ),
      );

      expect(find.text('Critical'), findsOneWidget);
    });

    testWidgets('Portal header action shows badge and responds to taps', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PortalHeaderActionButton(
              icon: Icons.notifications_none_rounded,
              tooltip: '3 unread notifications',
              badgeCount: 3,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      expect(tapped, isTrue);
    });

    testWidgets('Portal clear action exposes a tooltip and clears on tap', (
      tester,
    ) async {
      var cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PortalClearButton(
              tooltip: 'Clear search',
              onPressed: () => cleared = true,
            ),
          ),
        ),
      );

      expect(find.byTooltip('Clear search'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      expect(cleared, isTrue);
    });

    testWidgets('Login omits demo accounts and registration', (tester) async {
      DemoMode.setDemoActive(true);
      addTearDown(() => DemoMode.setDemoActive(false));
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('login-campus-background')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('login-glass-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('login-aclc-logo')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('login-glass-card')),
          matching: find.byKey(const ValueKey('login-aclc-logo')),
        ),
        findsNothing,
      );
      expect(find.text('ACLC College of Mandaue'), findsOneWidget);
      expect(find.text('Student Violation System'), findsOneWidget);
      expect(find.text('Login'), findsNWidgets(2));
      expect(
        find.text('Welcome back, please sign in to your account'),
        findsOneWidget,
      );
      expect(find.text('Demo Accounts'), findsNothing);
      expect(find.text('Password123!'), findsNothing);
      expect(find.text('Student'), findsNothing);
      expect(find.text('Guard'), findsNothing);
      expect(find.text('SAO'), findsNothing);
      expect(find.text('Register'), findsNothing);
      expect(find.text("Don't have an account?"), findsNothing);
    });

    testWidgets('Existing SAO sessions return to login', (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_id': 'demo-sao',
        'user_role': 'sao',
        'user_name': 'SAO Officer',
      });
      DemoMode.setDemoActive(true);
      addTearDown(() => DemoMode.setDemoActive(false));
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final authProvider = AuthProvider();
      await authProvider.checkAuthStatus();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => ViolationProvider()),
          ],
          child: const MaterialApp(home: DashboardWrapper()),
        ),
      );
      await tester.pumpAndSettle();

      expect(authProvider.currentUser, isNull);
      expect(
        find.text('Welcome back, please sign in to your account'),
        findsOneWidget,
      );
      expect(find.text('SAO PORTAL'), findsNothing);
      expect(find.text('Violations'), findsNothing);
    });

    testWidgets('Home shortcut opens the student Digital ID tab', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final themeModeProvider = ThemeModeProvider();
      await themeModeProvider.setDarkMode(true);
      DemoMode.setDemoActive(true);
      addTearDown(() => DemoMode.setDemoActive(false));
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ViolationProvider()),
            ChangeNotifierProvider.value(value: themeModeProvider),
          ],
          child: Consumer<ThemeModeProvider>(
            builder: (context, themeMode, _) => MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode.themeMode,
              themeAnimationDuration: Duration.zero,
              home: const StudentDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ACLC College of Mandaue'), findsOneWidget);
      expect(find.text('STUDENT PORTAL'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(
        find.text(DateFormat('EEEE, MMMM d').format(DateTime.now())),
        findsOneWidget,
      );
      expect(find.text('Record overview'), findsNothing);
      expect(find.text('Quick access'), findsOneWidget);

      await tester.tap(find.text('Records'));
      await tester.pumpAndSettle();
      expect(find.text('Records & appeals'), findsOneWidget);
      expect(
        find.text('Review your violations and appeal eligible records.'),
        findsOneWidget,
      );
      expect(find.text('Eligible for Appeal'), findsOneWidget);
      expect(find.text('Appealed'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('student-record-filters')),
        findsOneWidget,
      );
      expect(find.textContaining('Cleared ('), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Text>(find.text('Records & appeals')).style?.color,
        AppTheme.darkTheme.colorScheme.onSurface,
      );
      expect(
        (tester
                    .widget<Container>(
                      find.byKey(const ValueKey('student-records-summary')),
                    )
                    .decoration!
                as BoxDecoration)
            .color,
        AppColors.darkSurface,
      );
      expect(
        (tester
                    .widget<Container>(
                      find.byKey(const ValueKey('student-records-list')),
                    )
                    .decoration!
                as BoxDecoration)
            .color,
        AppColors.darkSurface,
      );

      await tester.ensureVisible(find.text('Appealed (0)'));
      await tester.tap(find.text('Appealed (0)'));
      await tester.pumpAndSettle();
      expect(find.text('No Records in this Category'), findsOneWidget);
      await tester.ensureVisible(find.text('View all records'));
      await tester.tap(find.text('View all records'));
      await tester.pumpAndSettle();
      expect(find.text('No Records in this Category'), findsNothing);
      expect(find.text('No School ID'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final digitalIdShortcut = find.text('Show your campus QR');
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(digitalIdShortcut);
      await tester.tap(digitalIdShortcut);
      await tester.pumpAndSettle();

      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Profile'), findsOneWidget);
      for (final key in [
        'profile-menu-edit',
        'profile-menu-account',
        'profile-menu-notifications',
        'profile-menu-privacy',
        'profile-menu-help',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      }
      expect(
        tester.widget<Text>(find.text('Edit Profile')).style?.color,
        AppTheme.portalTextPrimary(tester.element(find.text('Edit Profile'))),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Student account settings can switch to dark mode', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final themeModeProvider = ThemeModeProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ViolationProvider()),
            ChangeNotifierProvider.value(value: themeModeProvider),
          ],
          child: Consumer<ThemeModeProvider>(
            builder: (context, themeMode, _) => MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode.themeMode,
              themeAnimationDuration: Duration.zero,
              home: const StudentDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Account Settings'));
      await tester.tap(find.text('Account Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark mode'));
      await tester.pumpAndSettle();

      expect(
        Theme.of(tester.element(find.byType(SwitchListTile))).brightness,
        Brightness.dark,
      );
      expect(
        Theme.of(
          tester.element(find.byType(SwitchListTile)),
        ).colorScheme.surface,
        AppColors.darkSurface,
      );
      final settingsTitle = find.text('Account Settings').last;
      expect(
        tester.widget<Text>(settingsTitle).style?.color,
        AppTheme.portalAccent(tester.element(settingsTitle)),
      );
    });

    testWidgets('Guard manual lookup verifies on a narrow phone layout', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      DemoMode.setDemoActive(true);
      addTearDown(() => DemoMode.setDemoActive(false));
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final themeModeProvider = ThemeModeProvider();
      await themeModeProvider.setDarkMode(true);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ViolationProvider()),
            ChangeNotifierProvider.value(value: themeModeProvider),
          ],
          child: Consumer<ThemeModeProvider>(
            builder: (context, themeMode, _) => MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode.themeMode,
              themeAnimationDuration: Duration.zero,
              home: const GuardDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('guard-campus-background')),
        findsNothing,
      );
      expect(find.text('ACLC College of Mandaue'), findsOneWidget);
      expect(find.text('GUARD PORTAL'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.text('Step 1: Scan QR code or search'))
            .style
            ?.color,
        AppTheme.portalTextPrimary(
          tester.element(find.text('Step 1: Scan QR code or search')),
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('guard-scan-target'))),
        const Size(220, 220),
      );
      expect(find.text('Student verified'), findsNothing);
      final studentNumberField = find.byType(TextFormField).first;
      await tester.enterText(studentNumberField, 'juan');
      await tester.pumpAndSettle();
      expect(find.text('Juan Dela Cruz (Student)'), findsOneWidget);
      expect(find.text('Lookup'), findsNothing);
      final studentMatch = find.byKey(
        const ValueKey('guard-student-match-C26-01-0001-MAN121'),
      );
      await tester.ensureVisible(studentMatch);
      await tester.pumpAndSettle();
      await tester.tap(studentMatch);
      await tester.pumpAndSettle();

      expect(find.text('Step 2: Confirm student match'), findsOneWidget);
      expect(find.textContaining('Juan Dela Cruz'), findsWidgets);
      expect(find.text('ALLOWED TO ENTER CAMPUS'), findsOneWidget);
      expect(find.text('Active Warnings:'), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.text('Select Violation Type:'), findsNothing);
      expect(find.text('Verify'), findsOneWidget);
      await tester.ensureVisible(find.text('Continue to violation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to violation'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3: Record violation'), findsOneWidget);
      expect(find.text('Select Violation Type:'), findsOneWidget);
      await tester.ensureVisible(find.text('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('ALLOWED TO ENTER CAMPUS'), findsOneWidget);
      expect(tester.takeException(), isNull);

      for (final destination in ['Settings']) {
        await tester.tap(find.byTooltip(destination));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$destination tab');
        if (destination == 'Settings') {
          expect(
            tester.getTopLeft(find.text('Settings').first).dx,
            20,
            reason: 'Settings title should align with the guard page',
          );
        }
      }
    });

    testWidgets('Guard Settings tab contains confirmed sign out', (
      tester,
    ) async {
      DemoMode.setDemoActive(true);
      addTearDown(() => DemoMode.setDemoActive(false));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ViolationProvider()),
            ChangeNotifierProvider(create: (_) => ThemeModeProvider()),
          ],
          child: Consumer<ThemeModeProvider>(
            builder: (context, themeMode, _) => MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode.themeMode,
              themeAnimationDuration: Duration.zero,
              home: const GuardDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(
        find.text('Manage your guard account and session.'),
        findsOneWidget,
      );
      expect(find.text('Guard account'), findsOneWidget);
      expect(find.text('Change password'), findsOneWidget);
      expect(find.text('Dark mode'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Contact number'), findsNothing);
      expect(find.text('Session'), findsNothing);
      expect(
        find.text('Sign out when you have finished using the guard portal.'),
        findsNothing,
      );
      expect(find.byTooltip('Back to scan'), findsOneWidget);
      await tester.tap(find.byTooltip('Back to scan'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1: Scan QR code or search'), findsOneWidget);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark mode'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Settings').first)).brightness,
        Brightness.dark,
      );

      await tester.tap(find.text('Change password'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(0), 'current-password');
      await tester.enterText(passwordFields.at(1), 'new-password-123');
      await tester.enterText(passwordFields.at(2), 'new-password-123');
      await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
      await tester.pumpAndSettle();
      expect(
        find.text('Password changes are unavailable in demo mode.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Officer Sign Out'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Officer Sign Out'), findsNothing);
    });

    testWidgets('Guard portal omits notifications', (tester) async {
      SharedPreferences.setMockInitialValues({});
      DemoMode.setDemoActive(true);
      addTearDown(() => DemoMode.setDemoActive(false));
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final themeModeProvider = ThemeModeProvider();
      await themeModeProvider.setDarkMode(true);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ViolationProvider()),
            ChangeNotifierProvider.value(value: themeModeProvider),
          ],
          child: Consumer<ThemeModeProvider>(
            builder: (context, themeMode, _) => MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode.themeMode,
              themeAnimationDuration: Duration.zero,
              home: const GuardDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
      expect(find.text('Notifications'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Notifications page uses the dark portal theme', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      DemoMode.setDemoActive(true);
      addTearDown(() => DemoMode.setDemoActive(false));
      final themeModeProvider = ThemeModeProvider();
      await themeModeProvider.setDarkMode(true);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ViolationProvider()),
            ChangeNotifierProvider.value(value: themeModeProvider),
          ],
          child: Consumer<ThemeModeProvider>(
            builder: (context, themeMode, _) => MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode.themeMode,
              themeAnimationDuration: Duration.zero,
              home: const NotificationsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        const Color(0xFF202124),
      );
      expect(
        tester.widget<AppBar>(find.byType(AppBar)).backgroundColor,
        const Color(0xFF292A2D),
      );
      expect(
        Theme.of(tester.element(find.byType(AppBar))).colorScheme.primary,
        const Color(0xFF8AB4F8),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'ErrorStateWidget renders title, message, and executes retry callback',
      (tester) async {
        bool retried = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorStateWidget(
                title: 'Server Connection Failed',
                message: 'Check your internet connection and try again.',
                onRetry: () {
                  retried = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('Server Connection Failed'), findsOneWidget);
        expect(
          find.text('Check your internet connection and try again.'),
          findsOneWidget,
        );
        expect(find.text('Try Again'), findsOneWidget);

        await tester.tap(find.text('Try Again'));
        await tester.pump();

        expect(retried, isTrue);
      },
    );

    test('AppColors.iconForSeverity maps correctly for a11y', () {
      expect(AppColors.iconForSeverity('critical'), Icons.dangerous_rounded);
      expect(AppColors.iconForSeverity('major'), Icons.warning_rounded);
      expect(AppColors.iconForSeverity('minor'), Icons.info_outline_rounded);
      expect(AppColors.iconForSeverity('unknown'), Icons.help_outline_rounded);
    });
  });
}
