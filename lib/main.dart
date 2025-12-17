import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'screens/welcome/welcome_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_app/main_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'services/persistent_storage_service.dart';
import 'screens/email/email_selection_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sources/sources_spirituelles_screen.dart';
import 'screens/sources/sources_litteraires_screen.dart';
import 'screens/sources/sources_psychologiques_screen.dart';
import 'screens/sources/sources_philosophiques_screen.dart';
import 'screens/sources/sources_philosophes_screen.dart';
import 'screens/daily_mood/daily_mood_entry_screen.dart';
import 'screens/timeline/emotion_timeline_screen.dart';
import 'screens/orientation/orientation_welcome_screen.dart';
import 'screens/demo/brain_gestation_demo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // INITIALISATION UNIFIÉE
  await PersistentStorageService.instance.initialize();
  
  runApp(const UnAutreRegardApp());
}

class UnAutreRegardApp extends StatelessWidget {
  const UnAutreRegardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Un Autre Regard',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const WelcomeScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/email': (context) => const EmailSelectionScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/main': (context) => const MainScreen(),
        '/profile': (context) => ProfileScreen(),
        '/history': (context) => const HistoryScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/sources-spirituelles': (context) => const SourcesSpirituellesScreen(),
        '/sources-litteraires': (context) => const SourcesLitterairesScreen(),
        '/sources-psychologiques': (context) => const SourcesPsychologiquesScreen(),
        '/sources-philosophiques': (context) => const SourcesPhilosophiquesScreen(),
        '/sources-philosophes': (context) => const SourcesPhilosophesScreen(),
        '/daily-mood': (context) => const DailyMoodEntryScreen(),
        '/emotion-timeline': (context) => const EmotionTimelineScreen(),
        '/orientation': (context) => const OrientationWelcomeScreen(),
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF6366F1),
          side: const BorderSide(color: Color(0xFF6366F1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 16),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFEC4899),
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  String _initialRoute = '/welcome';

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    try {
      // ═══════════════════════════════════════════════════════════════════════
      // CORRIGÉ : Utilisateur connecté → /home (au lieu de /main)
      // ═══════════════════════════════════════════════════════════════════════
      if (PersistentStorageService.instance.isUserLoggedIn) {
        _initialRoute = '/home'; // CORRIGÉ: Vers menu principal
      } else {
        _initialRoute = '/welcome';
      }
    
      await Future.delayed(const Duration(milliseconds: 1500));
    
      setState(() => _isLoading = false);
    
      if (mounted) {
        Navigator.pushReplacementNamed(context, _initialRoute);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.visibility, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Text(
                'Un Autre Regard',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Parce qu\'une autre vie est possible',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 48),
              if (_isLoading)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                    strokeWidth: 3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
