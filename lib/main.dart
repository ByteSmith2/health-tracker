import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'utils/app_theme.dart';
import 'services/database_service.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Sign in anonymously and wait for auth state to be ready
  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    if (userCredential.user == null) {
      debugPrint('Firebase auth: user is null after sign in');
    }
  } catch (e) {
    debugPrint('Firebase auth error: $e');
    // Retry once after a short delay
    try {
      await Future.delayed(const Duration(seconds: 2));
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e2) {
      debugPrint('Firebase auth retry failed: $e2');
    }
  }

  // Wait until currentUser is available
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.authStateChanges().firstWhere((user) => user != null)
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
  }

  await initializeDateFormatting('vi', null);

  bool hasProfile = false;
  if (FirebaseAuth.instance.currentUser != null) {
    try {
      hasProfile = await DatabaseService.instance.hasProfile();
    } catch (e) {
      debugPrint('Profile check error: $e');
    }
  }

  runApp(HealthTrackerApp(showOnboarding: !hasProfile));
}

class HealthTrackerApp extends StatelessWidget {
  final bool showOnboarding;

  const HealthTrackerApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Theo Dõi Sức Khỏe',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: showOnboarding
                ? const OnboardingScreen()
                : const HomeScreen(),
          );
        },
      ),
    );
  }
}
