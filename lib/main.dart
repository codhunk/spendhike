import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/navigation/main_navigation.dart';
import 'services/api_service.dart';
import 'services/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initSession();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bool hasActiveSession = ApiService.authToken != null && ApiService.authToken!.isNotEmpty;

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, child) {
        final lightTextTheme = ThemeData.light().textTheme;
        final darkTextTheme = ThemeData.dark().textTheme;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SpendHike',
          themeMode: AppSettings.instance.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            textTheme: GoogleFonts.poppinsTextTheme(lightTextTheme),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            cardColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0453CD),
              brightness: Brightness.light,
              surface: Colors.white,
              primary: const Color(0xFF0453CD),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFFF8FAFC),
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0,
              titleTextStyle: GoogleFonts.poppins(
                color: const Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            textTheme: GoogleFonts.poppinsTextTheme(darkTextTheme),
            scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate Light-Dark
            cardColor: const Color(0xFF1E293B),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3B82F6),
              brightness: Brightness.dark,
              surface: const Color(0xFF1E293B),
              primary: const Color(0xFF3B82F6),
              onSurface: const Color(0xFFF8FAFC),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: const Color(0xFFF8FAFC),
              elevation: 0,
              titleTextStyle: GoogleFonts.poppins(
                color: const Color(0xFFF8FAFC),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E293B),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF334155)),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF1E293B),
              surfaceTintColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          initialRoute: hasActiveSession ? '/main' : '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/main': (context) => const MainNavigation(),
          },
        );
      },
    );
  }
}
