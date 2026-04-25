import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:synthese/config/firebase_options.dart';
import 'package:synthese/services/app_notifications_service.dart';
import 'package:synthese/services/accent_color_service.dart';

import 'package:synthese/ui/start_page.dart';
import 'package:synthese/onboarding/onboarding_intro.dart';
import 'package:synthese/onboarding/onboarding_permissions.dart';
import 'package:synthese/theme/app_theme.dart';
import 'package:synthese/ui/dashboard.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env only if it exists (dev only, not in production builds)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: .env file not found - using defaults');
  }
  
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Firebase already initialized - ignore
    debugPrint('Firebase initialization: $e');
  }
  await AppNotificationsService.instance.init();
  await AccentColor.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AccentColor.themeNotifier,
      builder: (context, themeMode, _) => MaterialApp(
        title: 'Synthese',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        builder: (context, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor:
                isDark ? const Color(0xFF1A1A1C) : const Color(0xFFF5F5F5),
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
          ));
          return child!;
        },
        home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }
          if (snapshot.hasData) {
            return const AuthWrapper();
          }
          return const StartPage();
        },
      ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data['onboardingCompleted'] == true) {
            // Check privacy policy acceptance
            if (data['privacyPolicyAccepted'] == true) {
              return const DashboardPage();
            }
            return const OnboardingPermissions();
          }
        }
        return const OnboardingIntro();
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: BouncingDotsLoader(),
      ),
    );
  }
}