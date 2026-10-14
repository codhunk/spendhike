import 'package:flutter/material.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/create_passcode_screen.dart';
import 'screens/auth/passcode_lock_screen.dart';
import 'screens/auth/change_passcode_screen.dart';
import 'screens/navigation/main_navigation.dart';
import 'screens/labour/labour_main_screen.dart';
import 'screens/labour/labour_panel_screen.dart';
import 'services/api_service.dart';
import 'services/app_settings.dart';


import 'config/app_theme.dart';
import 'services/passcode_service.dart';
import 'services/biometric_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initSession();
  await AppSettings.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, child) {
        return AppLifecycleLockObserver(
          child: MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'SpendHike',
            locale: Locale(AppSettings.instance.isHindi ? 'hi' : 'en'),
            themeMode: AppSettings.instance.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/main': (context) => const MainNavigation(),
              '/create-passcode': (context) => const CreatePasscodeScreen(),
              '/lock-passcode': (context) => const PasscodeLockScreen(),
              '/change-passcode': (context) => const ChangePasscodeScreen(),
              '/labour': (context) => const LabourMainScreen(),
              '/labour-panel': (context) => const LabourPanelScreen(),
            },
          ),
        );
      },
    );
  }
}

class AppLifecycleLockObserver extends StatefulWidget {
  final Widget child;
  const AppLifecycleLockObserver({super.key, required this.child});

  @override
  State<AppLifecycleLockObserver> createState() => _AppLifecycleLockObserverState();
}

class _AppLifecycleLockObserverState extends State<AppLifecycleLockObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (!BiometricService.isAuthenticating) {
        PasscodeService.recordAppPaused();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (BiometricService.isAuthenticating) return;
      final shouldLock = await PasscodeService.shouldLockOnResume();
      if (shouldLock && ApiService.authToken != null && ApiService.authToken!.isNotEmpty) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/lock-passcode', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}


