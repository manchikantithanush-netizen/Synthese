import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:synthese/config/firebase_options.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';
import 'package:synthese/services/app_notifications_service.dart';
import 'package:synthese/services/accent_color_service.dart';
import 'package:synthese/services/locale_service.dart';
import 'package:synthese/services/step_tracker_service.dart';
import 'package:synthese/services/session_guard_service.dart';

import 'package:synthese/ui/start_page.dart';
import 'package:synthese/onboarding/onboarding_intro.dart';
import 'package:synthese/onboarding/onboarding_permissions.dart';
import 'package:synthese/theme/app_theme.dart';
import 'package:synthese/ui/dashboard.dart';
import 'package:synthese/ui/components/bouncing_dots_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use the modern Android system Photo Picker app-wide for gallery selection.
  // It runs out-of-process and needs no storage permission — the user hands
  // over only the photos they pick, so we don't ship READ_MEDIA_IMAGES.
  final ImagePickerPlatform imagePickerPlatform = ImagePickerPlatform.instance;
  if (imagePickerPlatform is ImagePickerAndroid) {
    imagePickerPlatform.useAndroidPhotoPicker = true;
  }

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
  await LocaleService.init();
  await StepTracker.instance.init();

  // Single-active-session enforcement. Watch the signed-in user's session token
  // so this device signs out if the account logs in elsewhere; if it was
  // superseded while closed, the watcher catches it on this launch.
  final existingUser = FirebaseAuth.instance.currentUser;
  if (existingUser != null) {
    unawaited(SessionGuardService.instance.attach(existingUser.uid));
  }
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user == null) {
      SessionGuardService.instance.detach();
    }
  });

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
      builder: (context, themeMode, _) => ValueListenableBuilder<Locale>(
        valueListenable: LocaleService.localeNotifier,
        builder: (context, locale, _) => MaterialApp(
          title: 'Synthese',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
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
          // Sync cloud-stored language preference if present.
          final remoteLang = data?['language'];
          if (remoteLang is String) {
            LocaleService.applyFromRemote(remoteLang);
          }
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