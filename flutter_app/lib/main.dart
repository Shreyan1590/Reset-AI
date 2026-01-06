import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/context_service.dart';
import 'services/theme_service.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ResetAIApp());
}

class ResetAIApp extends StatelessWidget {
  const ResetAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ContextService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp.router(
            title: 'RESET AI',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeService.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}

ThemeData _buildLightTheme() {
  final baseTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1),
      brightness: Brightness.light,
      surface: Colors.white,
      primary: const Color(0xFF6366F1),
      secondary: const Color(0xFF22D3EE),
      tertiary: const Color(0xFF10B981),
    ),
  );

  return baseTheme.copyWith(
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1A1A2E),
      elevation: 0,
    ),
  );
}

ThemeData _buildDarkTheme() {
  final baseTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1),
      brightness: Brightness.dark,
      surface: const Color(0xFF0F0F23),
      primary: const Color(0xFF6366F1),
      secondary: const Color(0xFF22D3EE),
      tertiary: const Color(0xFF10B981),
    ),
  );

  return baseTheme.copyWith(
    scaffoldBackgroundColor: const Color(0xFF0F0F23),
    textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1A1A2E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
