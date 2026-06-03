import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('hi'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Synthese'**
  String get appTitle;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get commonGoBack;

  /// No description provided for @commonFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get commonFinish;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get commonSkipForNow;

  /// No description provided for @commonLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get commonLetsGo;

  /// No description provided for @commonDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get commonDetails;

  /// No description provided for @commonSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get commonSelectDate;

  /// No description provided for @commonCompleteAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all fields'**
  String get commonCompleteAllFields;

  /// No description provided for @commonSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get commonSaveFailed;

  /// No description provided for @onboardingIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Hello,'**
  String get onboardingIntroTitle;

  /// No description provided for @onboardingIntroBody.
  ///
  /// In en, this message translates to:
  /// **'We are going to collect some data so that you can get the best out of your app.'**
  String get onboardingIntroBody;

  /// No description provided for @onboardingIntroPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy First'**
  String get onboardingIntroPrivacyTitle;

  /// No description provided for @onboardingIntroPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Your data is yours, we will not be using your data for any purpose other than improving your experience.'**
  String get onboardingIntroPrivacyBody;

  /// No description provided for @onboardingLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your\nlanguage'**
  String get onboardingLanguageTitle;

  /// No description provided for @onboardingLanguageBody.
  ///
  /// In en, this message translates to:
  /// **'You can change this any time from Account → Language.'**
  String get onboardingLanguageBody;

  /// No description provided for @onboardingStage1Title.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get\nstarted'**
  String get onboardingStage1Title;

  /// No description provided for @onboardingStage1Body.
  ///
  /// In en, this message translates to:
  /// **'Just the basics so we can personalize your experience.'**
  String get onboardingStage1Body;

  /// No description provided for @onboardingStage1FullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get onboardingStage1FullName;

  /// No description provided for @onboardingStage1Dob.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get onboardingStage1Dob;

  /// No description provided for @onboardingStage1MinorNotice.
  ///
  /// In en, this message translates to:
  /// **'You must be 18 or older to use this app. You won\'t be able to continue.'**
  String get onboardingStage1MinorNotice;

  /// No description provided for @onboardingAgeGateError.
  ///
  /// In en, this message translates to:
  /// **'You must be 18 or older to use Synthese.'**
  String get onboardingAgeGateError;

  /// No description provided for @onboardingStage1Gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get onboardingStage1Gender;

  /// No description provided for @onboardingStage1GenderHint.
  ///
  /// In en, this message translates to:
  /// **'Used to enable cycle tracking for female users.'**
  String get onboardingStage1GenderHint;

  /// No description provided for @onboardingStage1Male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get onboardingStage1Male;

  /// No description provided for @onboardingStage1Female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get onboardingStage1Female;

  /// No description provided for @onboardingStage1Goals.
  ///
  /// In en, this message translates to:
  /// **'Your goals'**
  String get onboardingStage1Goals;

  /// No description provided for @onboardingStage1GoalsHint.
  ///
  /// In en, this message translates to:
  /// **'Pick all that apply'**
  String get onboardingStage1GoalsHint;

  /// No description provided for @onboardingStage1AthleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you an athlete?'**
  String get onboardingStage1AthleteQuestion;

  /// No description provided for @onboardingStage1AthleteNotice.
  ///
  /// In en, this message translates to:
  /// **'Add your sport, experience level and training details from Account → Athlete Details after onboarding.'**
  String get onboardingStage1AthleteNotice;

  /// No description provided for @goalEndurance.
  ///
  /// In en, this message translates to:
  /// **'Endurance'**
  String get goalEndurance;

  /// No description provided for @goalStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get goalStrength;

  /// No description provided for @goalLoseFat.
  ///
  /// In en, this message translates to:
  /// **'Lose Fat'**
  String get goalLoseFat;

  /// No description provided for @goalGainMuscle.
  ///
  /// In en, this message translates to:
  /// **'Gain Muscle'**
  String get goalGainMuscle;

  /// No description provided for @goalSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get goalSpeed;

  /// No description provided for @goalRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get goalRecovery;

  /// No description provided for @goalBetterSleep.
  ///
  /// In en, this message translates to:
  /// **'Better Sleep'**
  String get goalBetterSleep;

  /// No description provided for @goalConsistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get goalConsistency;

  /// No description provided for @onboardingStage2Title.
  ///
  /// In en, this message translates to:
  /// **'Set your\ndaily goals'**
  String get onboardingStage2Title;

  /// No description provided for @onboardingStage2Body.
  ///
  /// In en, this message translates to:
  /// **'Pick targets that feel right. You can change them anytime.'**
  String get onboardingStage2Body;

  /// No description provided for @goalDailySteps.
  ///
  /// In en, this message translates to:
  /// **'Daily Steps'**
  String get goalDailySteps;

  /// No description provided for @goalCaloriesBurnt.
  ///
  /// In en, this message translates to:
  /// **'Calories Burnt'**
  String get goalCaloriesBurnt;

  /// No description provided for @goalCaloriesEaten.
  ///
  /// In en, this message translates to:
  /// **'Calories Eaten'**
  String get goalCaloriesEaten;

  /// No description provided for @goalExerciseTime.
  ///
  /// In en, this message translates to:
  /// **'Exercise Time'**
  String get goalExerciseTime;

  /// No description provided for @goalSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get goalSleep;

  /// No description provided for @unitSteps.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get unitSteps;

  /// No description provided for @unitKcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get unitKcal;

  /// No description provided for @unitMin.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get unitMin;

  /// No description provided for @unitHrs.
  ///
  /// In en, this message translates to:
  /// **'hrs'**
  String get unitHrs;

  /// No description provided for @onboardingStage3Title.
  ///
  /// In en, this message translates to:
  /// **'Anything else\nwe should know?'**
  String get onboardingStage3Title;

  /// No description provided for @onboardingStage3Body.
  ///
  /// In en, this message translates to:
  /// **'Optional details that help us tailor your experience.'**
  String get onboardingStage3Body;

  /// No description provided for @onboardingStage3Supplements.
  ///
  /// In en, this message translates to:
  /// **'Prescription Supplements'**
  String get onboardingStage3Supplements;

  /// No description provided for @onboardingStage3Disabilities.
  ///
  /// In en, this message translates to:
  /// **'Physical Disabilities'**
  String get onboardingStage3Disabilities;

  /// No description provided for @onboardingStage3InjuryHistory.
  ///
  /// In en, this message translates to:
  /// **'Injury & Health History'**
  String get onboardingStage3InjuryHistory;

  /// No description provided for @onboardingStage3InjuryHint.
  ///
  /// In en, this message translates to:
  /// **'Describe past injuries or conditions'**
  String get onboardingStage3InjuryHint;

  /// No description provided for @onboardingStage3AiTitle.
  ///
  /// In en, this message translates to:
  /// **'A note on AI'**
  String get onboardingStage3AiTitle;

  /// No description provided for @onboardingStage3AiBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re not using AI on this information today. In the future, we may add AI-powered insights to help you better understand your goals, spot patterns in your training, and get personalized suggestions.'**
  String get onboardingStage3AiBody;

  /// No description provided for @onboardingStage3AiConsent.
  ///
  /// In en, this message translates to:
  /// **'If we ever do, you\'ll see a clear consent prompt first — fully opt-in, your data stays yours.'**
  String get onboardingStage3AiConsent;

  /// No description provided for @permWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to\nSynthese.'**
  String get permWelcomeTitle;

  /// No description provided for @permWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'A private, ad-free home for every part of your wellbeing — physical, mental, and financial.'**
  String get permWelcomeBody;

  /// No description provided for @permWelcomeDimHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get permWelcomeDimHome;

  /// No description provided for @permWelcomeDimHomeDesc.
  ///
  /// In en, this message translates to:
  /// **'Daily metrics — steps, heart rate, sleep.'**
  String get permWelcomeDimHomeDesc;

  /// No description provided for @permWelcomeDimDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get permWelcomeDimDiet;

  /// No description provided for @permWelcomeDimDietDesc.
  ///
  /// In en, this message translates to:
  /// **'AI nutrition tracking and water intake.'**
  String get permWelcomeDimDietDesc;

  /// No description provided for @permWelcomeDimWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get permWelcomeDimWorkout;

  /// No description provided for @permWelcomeDimWorkoutDesc.
  ///
  /// In en, this message translates to:
  /// **'GPS-tracked runs, rides, swims and more.'**
  String get permWelcomeDimWorkoutDesc;

  /// No description provided for @permWelcomeDimMindfulness.
  ///
  /// In en, this message translates to:
  /// **'Mindfulness'**
  String get permWelcomeDimMindfulness;

  /// No description provided for @permWelcomeDimMindfulnessDesc.
  ///
  /// In en, this message translates to:
  /// **'Mood check-ins and breathing exercises.'**
  String get permWelcomeDimMindfulnessDesc;

  /// No description provided for @permWelcomeDimCycles.
  ///
  /// In en, this message translates to:
  /// **'Cycles'**
  String get permWelcomeDimCycles;

  /// No description provided for @permWelcomeDimCyclesDesc.
  ///
  /// In en, this message translates to:
  /// **'Cycle tracking for female users.'**
  String get permWelcomeDimCyclesDesc;

  /// No description provided for @permWelcomeDimFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get permWelcomeDimFinance;

  /// No description provided for @permWelcomeDimFinanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Expenses, budgeting, and debts.'**
  String get permWelcomeDimFinanceDesc;

  /// No description provided for @permTrustNoAds.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get permTrustNoAds;

  /// No description provided for @permTrustPdpl.
  ///
  /// In en, this message translates to:
  /// **'PDPL'**
  String get permTrustPdpl;

  /// No description provided for @permTrustYourData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get permTrustYourData;

  /// No description provided for @permNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay in the loop'**
  String get permNotificationTitle;

  /// No description provided for @permNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Synthese sends you workout reminders, hydration nudges, and important health alerts. We never send marketing or spam — only things that help you stay on track.'**
  String get permNotificationBody;

  /// No description provided for @permNotificationAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow Notifications'**
  String get permNotificationAllow;

  /// No description provided for @permLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Track your route'**
  String get permLocationTitle;

  /// No description provided for @permLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Location access (coarse + fine) is used only during active workout sessions to map your run, cycle, or walk. Background location keeps your session running even when the screen is off — no interruptions mid-workout.'**
  String get permLocationBody;

  /// No description provided for @permLocationAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow Location'**
  String get permLocationAllow;

  /// No description provided for @permActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Count every step'**
  String get permActivityTitle;

  /// No description provided for @permActivityBody.
  ///
  /// In en, this message translates to:
  /// **'Synthese uses your phone\'s pedometer to count steps automatically — all day in the background and during workouts. You can change either mode anytime in Settings.'**
  String get permActivityBody;

  /// No description provided for @permActivityAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow step tracking'**
  String get permActivityAllow;

  /// No description provided for @permCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'AI calorie analysis'**
  String get permCameraTitle;

  /// No description provided for @permCameraBody.
  ///
  /// In en, this message translates to:
  /// **'Camera access powers the AI food analyser — snap a photo of your meal and Synthese instantly estimates calories, protein, carbs, and fats. Camera is only activated when you choose to use this feature.'**
  String get permCameraBody;

  /// No description provided for @permCameraAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow Camera'**
  String get permCameraAllow;

  /// No description provided for @permPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos & media'**
  String get permPhotosTitle;

  /// No description provided for @permPhotosBody.
  ///
  /// In en, this message translates to:
  /// **'Photo library access lets you upload a profile picture and pick meal images for AI analysis. We only read images you explicitly select — we never scan your gallery.'**
  String get permPhotosBody;

  /// No description provided for @permPhotosAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow Photos & Media'**
  String get permPhotosAllow;

  /// No description provided for @permPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get permPrivacyTitle;

  /// No description provided for @permPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Please read and agree to continue using Synthese.'**
  String get permPrivacyBody;

  /// No description provided for @permPrivacyReadLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap to read the full Privacy Policy'**
  String get permPrivacyReadLabel;

  /// No description provided for @permPrivacyAgreeCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the Privacy Policy'**
  String get permPrivacyAgreeCheckbox;

  /// No description provided for @permPrivacyAgree.
  ///
  /// In en, this message translates to:
  /// **'I Agree'**
  String get permPrivacyAgree;

  /// No description provided for @permPrivacyDecline.
  ///
  /// In en, this message translates to:
  /// **'I Do Not Agree'**
  String get permPrivacyDecline;

  /// No description provided for @permFinishTitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you for\ntrusting Synthese.'**
  String get permFinishTitle;

  /// No description provided for @permFinishBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set. We hope Synthese helps you build a healthier, more balanced life.'**
  String get permFinishBody;

  /// No description provided for @permFinishCheck1.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy agreed'**
  String get permFinishCheck1;

  /// No description provided for @permFinishCheck2.
  ///
  /// In en, this message translates to:
  /// **'Permissions configured'**
  String get permFinishCheck2;

  /// No description provided for @permFinishCheck3.
  ///
  /// In en, this message translates to:
  /// **'Account created & verified'**
  String get permFinishCheck3;

  /// No description provided for @permFinishCheck4.
  ///
  /// In en, this message translates to:
  /// **'Profile set up'**
  String get permFinishCheck4;

  /// No description provided for @permFinishFooter.
  ///
  /// In en, this message translates to:
  /// **'You can review your permissions and privacy settings anytime in the Settings page.'**
  String get permFinishFooter;

  /// No description provided for @accountLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get accountLanguage;

  /// No description provided for @accountLanguageSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get accountLanguageSheetTitle;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get commonTryAgain;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @dietOnboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to\nDiet Tracker'**
  String get dietOnboardingWelcomeTitle;

  /// No description provided for @dietOnboardingFeature1Title.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Analysis'**
  String get dietOnboardingFeature1Title;

  /// No description provided for @dietOnboardingFeature1Desc.
  ///
  /// In en, this message translates to:
  /// **'Snap a photo of your food and get instant calorie estimates powered by advanced AI.'**
  String get dietOnboardingFeature1Desc;

  /// No description provided for @dietOnboardingFeature2Title.
  ///
  /// In en, this message translates to:
  /// **'Daily Tracking'**
  String get dietOnboardingFeature2Title;

  /// No description provided for @dietOnboardingFeature2Desc.
  ///
  /// In en, this message translates to:
  /// **'Effortlessly monitor your calorie intake throughout the day with a simple food log.'**
  String get dietOnboardingFeature2Desc;

  /// No description provided for @dietOnboardingFeature3Title.
  ///
  /// In en, this message translates to:
  /// **'Smart Insights'**
  String get dietOnboardingFeature3Title;

  /// No description provided for @dietOnboardingFeature3Desc.
  ///
  /// In en, this message translates to:
  /// **'Understand your eating patterns over time and make informed nutrition choices.'**
  String get dietOnboardingFeature3Desc;

  /// No description provided for @dietOnboardingFeature4Title.
  ///
  /// In en, this message translates to:
  /// **'Goal Setting'**
  String get dietOnboardingFeature4Title;

  /// No description provided for @dietOnboardingFeature4Desc.
  ///
  /// In en, this message translates to:
  /// **'Set daily calorie targets and track your progress toward your health goals.'**
  String get dietOnboardingFeature4Desc;

  /// No description provided for @dietOnboardingDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Important Notice'**
  String get dietOnboardingDisclaimerTitle;

  /// No description provided for @dietOnboardingDisclaimerPara1.
  ///
  /// In en, this message translates to:
  /// **'This app uses AI to analyze food images and estimate calorie counts. These estimates are approximations and may not be 100% accurate.'**
  String get dietOnboardingDisclaimerPara1;

  /// No description provided for @dietOnboardingDisclaimerPara2.
  ///
  /// In en, this message translates to:
  /// **'AI recognition can be affected by image quality, portion sizes, food preparation methods, and other factors. The calorie estimates provided should be used as a general guide only.'**
  String get dietOnboardingDisclaimerPara2;

  /// No description provided for @dietOnboardingDisclaimerPara3.
  ///
  /// In en, this message translates to:
  /// **'This app is not a substitute for professional nutritional advice. For personalized dietary guidance, consult a registered dietitian or healthcare professional.'**
  String get dietOnboardingDisclaimerPara3;

  /// No description provided for @dietOnboardingDisclaimerPara4.
  ///
  /// In en, this message translates to:
  /// **'Calorie needs vary based on age, gender, activity level, metabolism, and health conditions. Always consult a professional before making significant dietary changes.'**
  String get dietOnboardingDisclaimerPara4;

  /// No description provided for @dietOnboardingDisclaimerAck.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you acknowledge that this app provides estimates for informational purposes only and does not replace professional nutritional advice.'**
  String get dietOnboardingDisclaimerAck;

  /// No description provided for @dietOnboardingUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I Understand'**
  String get dietOnboardingUnderstand;

  /// No description provided for @dietOnboardingWaterGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Water Intake Goal'**
  String get dietOnboardingWaterGoalTitle;

  /// No description provided for @dietOnboardingWaterLoggedDaily.
  ///
  /// In en, this message translates to:
  /// **'You logged {litres}L of water intake daily'**
  String dietOnboardingWaterLoggedDaily(String litres);

  /// No description provided for @dietOnboardingWaterGoalQuestion.
  ///
  /// In en, this message translates to:
  /// **'What\'s your daily water goal?'**
  String get dietOnboardingWaterGoalQuestion;

  /// No description provided for @dietOnboardingGlassesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} glasses'**
  String dietOnboardingGlassesCount(int count);

  /// No description provided for @dietOnboardingFinishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish Setup'**
  String get dietOnboardingFinishSetup;

  /// No description provided for @dietPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Food Tracker'**
  String get dietPageTitle;

  /// No description provided for @dietPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your calories with AI'**
  String get dietPageSubtitle;

  /// No description provided for @dietPageCalorieGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Calorie Goal'**
  String get dietPageCalorieGoalLabel;

  /// No description provided for @dietPageWaterGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Water Goal'**
  String get dietPageWaterGoalLabel;

  /// No description provided for @dietPageTodaysIntake.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Intake'**
  String get dietPageTodaysIntake;

  /// No description provided for @dietPageGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal: {value}'**
  String dietPageGoal(int value);

  /// No description provided for @dietPageCaloriesUnit.
  ///
  /// In en, this message translates to:
  /// **'calories'**
  String get dietPageCaloriesUnit;

  /// No description provided for @dietPageAiInaccurateLabel.
  ///
  /// In en, this message translates to:
  /// **'AI estimates may be inaccurate'**
  String get dietPageAiInaccurateLabel;

  /// No description provided for @dietPageProgressNoGoal.
  ///
  /// In en, this message translates to:
  /// **'Set a goal to track progress'**
  String get dietPageProgressNoGoal;

  /// No description provided for @dietPageProgressRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} cal remaining'**
  String dietPageProgressRemaining(int count);

  /// No description provided for @dietPageProgressGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached!'**
  String get dietPageProgressGoalReached;

  /// No description provided for @dietPageProgressOver.
  ///
  /// In en, this message translates to:
  /// **'{count} cal over goal'**
  String dietPageProgressOver(int count);

  /// No description provided for @dietPageMacroProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get dietPageMacroProtein;

  /// No description provided for @dietPageMacroCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get dietPageMacroCarbs;

  /// No description provided for @dietPageMacroFats.
  ///
  /// In en, this message translates to:
  /// **'Fats'**
  String get dietPageMacroFats;

  /// No description provided for @dietPageMicrosTitle.
  ///
  /// In en, this message translates to:
  /// **'Micronutrients'**
  String get dietPageMicrosTitle;

  /// No description provided for @dietPageMicroFiber.
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get dietPageMicroFiber;

  /// No description provided for @dietPageMicroSugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get dietPageMicroSugar;

  /// No description provided for @dietPageMicroSodium.
  ///
  /// In en, this message translates to:
  /// **'Sodium'**
  String get dietPageMicroSodium;

  /// No description provided for @dietPageMicroIron.
  ///
  /// In en, this message translates to:
  /// **'Iron'**
  String get dietPageMicroIron;

  /// No description provided for @dietPageMicroCalcium.
  ///
  /// In en, this message translates to:
  /// **'Calcium'**
  String get dietPageMicroCalcium;

  /// No description provided for @dietPageMicroPotassium.
  ///
  /// In en, this message translates to:
  /// **'Potassium'**
  String get dietPageMicroPotassium;

  /// No description provided for @dietPageMicroVitaminC.
  ///
  /// In en, this message translates to:
  /// **'Vitamin C'**
  String get dietPageMicroVitaminC;

  /// No description provided for @dietPageMicroVitaminD.
  ///
  /// In en, this message translates to:
  /// **'Vitamin D'**
  String get dietPageMicroVitaminD;

  /// No description provided for @dietPageHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get dietPageHide;

  /// No description provided for @dietPageShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get dietPageShow;

  /// No description provided for @dietPageFrequentFoods.
  ///
  /// In en, this message translates to:
  /// **'Frequent Foods'**
  String get dietPageFrequentFoods;

  /// No description provided for @dietPageFrequentFoodsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to quickly re-log recent meals'**
  String get dietPageFrequentFoodsHint;

  /// No description provided for @dietPageAnalyzeFood.
  ///
  /// In en, this message translates to:
  /// **'Analyze Food'**
  String get dietPageAnalyzeFood;

  /// No description provided for @dietPageAnalyzingFood.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your food...'**
  String get dietPageAnalyzingFood;

  /// No description provided for @dietPageAnalyzingMealText.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your meal text...'**
  String get dietPageAnalyzingMealText;

  /// No description provided for @dietPageAiNutritionalInfo.
  ///
  /// In en, this message translates to:
  /// **'AI-Estimated Nutritional Info'**
  String get dietPageAiNutritionalInfo;

  /// No description provided for @dietPageKcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get dietPageKcal;

  /// No description provided for @dietPageAddToLog.
  ///
  /// In en, this message translates to:
  /// **'Add to Log'**
  String get dietPageAddToLog;

  /// No description provided for @dietPageChooseDifferentImage.
  ///
  /// In en, this message translates to:
  /// **'Choose Different Image'**
  String get dietPageChooseDifferentImage;

  /// No description provided for @dietPageTypeAnotherMeal.
  ///
  /// In en, this message translates to:
  /// **'Type Another Meal'**
  String get dietPageTypeAnotherMeal;

  /// No description provided for @dietPageTypeFoodInstead.
  ///
  /// In en, this message translates to:
  /// **'Type Food Instead'**
  String get dietPageTypeFoodInstead;

  /// No description provided for @dietPageTapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload food image'**
  String get dietPageTapToUpload;

  /// No description provided for @dietPageCameraOrPhotoLibrary.
  ///
  /// In en, this message translates to:
  /// **'Camera or Photo Library'**
  String get dietPageCameraOrPhotoLibrary;

  /// No description provided for @dietPageAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed'**
  String get dietPageAnalysisFailed;

  /// No description provided for @dietPageFoodLog.
  ///
  /// In en, this message translates to:
  /// **'Food Log'**
  String get dietPageFoodLog;

  /// No description provided for @dietPageResetDietDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Diet Data?'**
  String get dietPageResetDietDataTitle;

  /// No description provided for @dietPageResetDietDataMsg.
  ///
  /// In en, this message translates to:
  /// **'This will clear your calorie goal and food log, and send you back to the onboarding screen. This cannot be undone.'**
  String get dietPageResetDietDataMsg;

  /// No description provided for @dietPageResetData.
  ///
  /// In en, this message translates to:
  /// **'Reset Data'**
  String get dietPageResetData;

  /// No description provided for @dietPageDeleteFoodLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Food Log'**
  String get dietPageDeleteFoodLogTitle;

  /// No description provided for @dietPageDeleteFoodLogMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this food entry? This will remove it from your calorie count.'**
  String get dietPageDeleteFoodLogMsg;

  /// No description provided for @dietPageCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get dietPageCamera;

  /// No description provided for @dietPagePhotoLibrary.
  ///
  /// In en, this message translates to:
  /// **'Photo Library'**
  String get dietPagePhotoLibrary;

  /// No description provided for @dietPageTypeYourMeal.
  ///
  /// In en, this message translates to:
  /// **'Type your meal'**
  String get dietPageTypeYourMeal;

  /// No description provided for @dietPageMealHint.
  ///
  /// In en, this message translates to:
  /// **'Example: 2 eggs, 2 slices toast with butter, and a banana'**
  String get dietPageMealHint;

  /// No description provided for @dietPageAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get dietPageAnalyze;

  /// No description provided for @dietPageManualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get dietPageManualEntry;

  /// No description provided for @dietPageManualEntryHint.
  ///
  /// In en, this message translates to:
  /// **'All fields are optional. Fill in at least one.'**
  String get dietPageManualEntryHint;

  /// No description provided for @dietPageName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get dietPageName;

  /// No description provided for @dietPageManuallyAdded.
  ///
  /// In en, this message translates to:
  /// **'Manually Added'**
  String get dietPageManuallyAdded;

  /// No description provided for @dietPageCaloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get dietPageCaloriesLabel;

  /// No description provided for @dietPageAddMicros.
  ///
  /// In en, this message translates to:
  /// **'Add micronutrients'**
  String get dietPageAddMicros;

  /// No description provided for @dietPageFillAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Fill in at least one field'**
  String get dietPageFillAtLeastOne;

  /// No description provided for @dietPageFoodAddedToast.
  ///
  /// In en, this message translates to:
  /// **'{food} added to log'**
  String dietPageFoodAddedToast(String food);

  /// No description provided for @dietPageCalorieGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Daily calorie goal reached'**
  String get dietPageCalorieGoalReached;

  /// No description provided for @dietPageFoodEntryRemoved.
  ///
  /// In en, this message translates to:
  /// **'Food entry removed'**
  String get dietPageFoodEntryRemoved;

  /// No description provided for @dietPageTimeToday.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String dietPageTimeToday(String time);

  /// No description provided for @dietPageTimeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday at {time}'**
  String dietPageTimeYesterday(String time);

  /// No description provided for @dietPageTimeOnDate.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String dietPageTimeOnDate(String date, String time);

  /// No description provided for @waterIntakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Water Intake'**
  String get waterIntakeTitle;

  /// No description provided for @waterGlassCount.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} glasses'**
  String waterGlassCount(int current, int total);

  /// No description provided for @waterOfDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'of daily goal'**
  String get waterOfDailyGoal;

  /// No description provided for @waterStatusGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached!'**
  String get waterStatusGoalReached;

  /// No description provided for @waterStatus1Glass.
  ///
  /// In en, this message translates to:
  /// **'1 glass to go!'**
  String get waterStatus1Glass;

  /// No description provided for @waterStatusAlmostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there!'**
  String get waterStatusAlmostThere;

  /// No description provided for @waterStatusGlassesToGo.
  ///
  /// In en, this message translates to:
  /// **'{count} glasses to go'**
  String waterStatusGlassesToGo(int count);

  /// No description provided for @waterAddGlass.
  ///
  /// In en, this message translates to:
  /// **'+ Add Glass'**
  String get waterAddGlass;

  /// No description provided for @waterGoalReachedToast.
  ///
  /// In en, this message translates to:
  /// **'Water goal reached'**
  String get waterGoalReachedToast;

  /// No description provided for @waterWeeklyTrend.
  ///
  /// In en, this message translates to:
  /// **'Weekly Trend'**
  String get waterWeeklyTrend;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// No description provided for @foodErrorImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to analyze image. Please try again.'**
  String get foodErrorImageFailed;

  /// No description provided for @foodErrorConnection.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please check your connection.'**
  String get foodErrorConnection;

  /// No description provided for @foodErrorEmptyText.
  ///
  /// In en, this message translates to:
  /// **'Please enter what you ate.'**
  String get foodErrorEmptyText;

  /// No description provided for @foodErrorTextFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to analyze text. Please try again.'**
  String get foodErrorTextFailed;

  /// No description provided for @foodErrorParseFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not parse the analysis result.'**
  String get foodErrorParseFailed;

  /// No description provided for @cyclesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cycles'**
  String get cyclesTitle;

  /// No description provided for @cyclesResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset All Data?'**
  String get cyclesResetTitle;

  /// No description provided for @cyclesResetMsg.
  ///
  /// In en, this message translates to:
  /// **'This will wipe all your daily logs and send you back to the onboarding screen. This cannot be undone.'**
  String get cyclesResetMsg;

  /// No description provided for @cyclesWipeData.
  ///
  /// In en, this message translates to:
  /// **'Wipe Data'**
  String get cyclesWipeData;

  /// No description provided for @cyclesPleaseLogIn.
  ///
  /// In en, this message translates to:
  /// **'Please log in'**
  String get cyclesPleaseLogIn;

  /// No description provided for @cyclesPleaseLogInHistory.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view history.'**
  String get cyclesPleaseLogInHistory;

  /// No description provided for @cyclesToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get cyclesToday;

  /// No description provided for @cyclesSimulatedDate.
  ///
  /// In en, this message translates to:
  /// **'Simulated Date'**
  String get cyclesSimulatedDate;

  /// No description provided for @cyclesResetToPresent.
  ///
  /// In en, this message translates to:
  /// **'Reset to Present'**
  String get cyclesResetToPresent;

  /// No description provided for @cyclesTodaysLogSummary.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Log Summary'**
  String get cyclesTodaysLogSummary;

  /// No description provided for @cyclesFlow.
  ///
  /// In en, this message translates to:
  /// **'Flow'**
  String get cyclesFlow;

  /// No description provided for @cyclesMucus.
  ///
  /// In en, this message translates to:
  /// **'Mucus'**
  String get cyclesMucus;

  /// No description provided for @cyclesSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get cyclesSymptoms;

  /// No description provided for @cyclesMood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get cyclesMood;

  /// No description provided for @cyclesWhatsHappening.
  ///
  /// In en, this message translates to:
  /// **'What\'s happening right now?'**
  String get cyclesWhatsHappening;

  /// No description provided for @cyclesEditTodaysLog.
  ///
  /// In en, this message translates to:
  /// **'Edit Today\'s Log'**
  String get cyclesEditTodaysLog;

  /// No description provided for @cyclesLogSymptomsToday.
  ///
  /// In en, this message translates to:
  /// **'Log Symptoms Today'**
  String get cyclesLogSymptomsToday;

  /// No description provided for @cyclesDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get cyclesDismiss;

  /// No description provided for @cyclesLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get cyclesLearnMore;

  /// No description provided for @cyclePhasePeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get cyclePhasePeriod;

  /// No description provided for @cyclePhaseFollicular.
  ///
  /// In en, this message translates to:
  /// **'Follicular'**
  String get cyclePhaseFollicular;

  /// No description provided for @cyclePhaseOvulation.
  ///
  /// In en, this message translates to:
  /// **'Ovulation'**
  String get cyclePhaseOvulation;

  /// No description provided for @cyclePhaseLuteal.
  ///
  /// In en, this message translates to:
  /// **'Luteal'**
  String get cyclePhaseLuteal;

  /// No description provided for @cyclePhasePeriodDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Period due soon'**
  String get cyclePhasePeriodDueSoon;

  /// No description provided for @cycleHormonePeriod.
  ///
  /// In en, this message translates to:
  /// **'Estrogen & progesterone dropping'**
  String get cycleHormonePeriod;

  /// No description provided for @cycleHormoneFollicular.
  ///
  /// In en, this message translates to:
  /// **'Estrogen rising'**
  String get cycleHormoneFollicular;

  /// No description provided for @cycleHormoneOvulation.
  ///
  /// In en, this message translates to:
  /// **'LH surge · Estrogen peak'**
  String get cycleHormoneOvulation;

  /// No description provided for @cycleHormoneLuteal.
  ///
  /// In en, this message translates to:
  /// **'Progesterone dominant'**
  String get cycleHormoneLuteal;

  /// No description provided for @cycleHormoneLateLuteal.
  ///
  /// In en, this message translates to:
  /// **'Progesterone dropping'**
  String get cycleHormoneLateLuteal;

  /// No description provided for @cyclePhaseTextPeriod.
  ///
  /// In en, this message translates to:
  /// **'Your period is here'**
  String get cyclePhaseTextPeriod;

  /// No description provided for @cyclePhaseTextFollicular.
  ///
  /// In en, this message translates to:
  /// **'Your egg is growing'**
  String get cyclePhaseTextFollicular;

  /// No description provided for @cyclePhaseTextOvulation.
  ///
  /// In en, this message translates to:
  /// **'Ovulation today'**
  String get cyclePhaseTextOvulation;

  /// No description provided for @cyclePhaseTextLuteal.
  ///
  /// In en, this message translates to:
  /// **'Body is waiting'**
  String get cyclePhaseTextLuteal;

  /// No description provided for @cyclePhaseTextPeriodDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Period due soon'**
  String get cyclePhaseTextPeriodDueSoon;

  /// No description provided for @cycleHealthScore.
  ///
  /// In en, this message translates to:
  /// **'Health Score: {value}'**
  String cycleHealthScore(String value);

  /// No description provided for @cycleCurrentDay.
  ///
  /// In en, this message translates to:
  /// **'Current Cycle Day'**
  String get cycleCurrentDay;

  /// No description provided for @cycleNextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String cycleNextLabel(String date);

  /// No description provided for @cycleCalLegendPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get cycleCalLegendPeriod;

  /// No description provided for @cycleCalLegendPredicted.
  ///
  /// In en, this message translates to:
  /// **'Predicted'**
  String get cycleCalLegendPredicted;

  /// No description provided for @cycleCalLegendOvulation.
  ///
  /// In en, this message translates to:
  /// **'Ovulation'**
  String get cycleCalLegendOvulation;

  /// No description provided for @cycleCalLegendFertile.
  ///
  /// In en, this message translates to:
  /// **'Fertile'**
  String get cycleCalLegendFertile;

  /// No description provided for @cycleHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Cycle History'**
  String get cycleHistoryTitle;

  /// No description provided for @cycleHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cycles logged yet.'**
  String get cycleHistoryEmpty;

  /// No description provided for @cycleHistoryAvgCycle.
  ///
  /// In en, this message translates to:
  /// **'Avg Cycle'**
  String get cycleHistoryAvgCycle;

  /// No description provided for @cycleHistoryAvgPeriod.
  ///
  /// In en, this message translates to:
  /// **'Avg Period'**
  String get cycleHistoryAvgPeriod;

  /// No description provided for @cycleHistoryLongest.
  ///
  /// In en, this message translates to:
  /// **'Longest'**
  String get cycleHistoryLongest;

  /// No description provided for @cycleHistoryShortest.
  ///
  /// In en, this message translates to:
  /// **'Shortest'**
  String get cycleHistoryShortest;

  /// No description provided for @cycleHistoryRecentCycles.
  ///
  /// In en, this message translates to:
  /// **'Recent Cycles'**
  String get cycleHistoryRecentCycles;

  /// No description provided for @cycleHistoryAverageDays.
  ///
  /// In en, this message translates to:
  /// **'Average ({days} d)'**
  String cycleHistoryAverageDays(int days);

  /// No description provided for @cycleHistoryUnknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown Date'**
  String get cycleHistoryUnknownDate;

  /// No description provided for @cycleHistoryShortCycle.
  ///
  /// In en, this message translates to:
  /// **'Short Cycle'**
  String get cycleHistoryShortCycle;

  /// No description provided for @cycleHistoryLongCycle.
  ///
  /// In en, this message translates to:
  /// **'Long Cycle'**
  String get cycleHistoryLongCycle;

  /// No description provided for @cycleHistoryNormalCycle.
  ///
  /// In en, this message translates to:
  /// **'Normal Cycle'**
  String get cycleHistoryNormalCycle;

  /// No description provided for @cycleHistoryNoSymptoms.
  ///
  /// In en, this message translates to:
  /// **'No symptoms logged'**
  String get cycleHistoryNoSymptoms;

  /// No description provided for @cycleHistoryDaysSummary.
  ///
  /// In en, this message translates to:
  /// **'Cycle: {cycleDays} days  •  Period: {periodDays} days'**
  String cycleHistoryDaysSummary(int cycleDays, int periodDays);

  /// No description provided for @cycleHistoryTopSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Top Symptoms: {symptoms}'**
  String cycleHistoryTopSymptoms(String symptoms);

  /// No description provided for @cycleHelpLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get cycleHelpLearn;

  /// No description provided for @cycleHelpArticleTitle.
  ///
  /// In en, this message translates to:
  /// **'Article Title'**
  String get cycleHelpArticleTitle;

  /// No description provided for @cycleHelpArticle1Title.
  ///
  /// In en, this message translates to:
  /// **'What is a menstrual cycle?'**
  String get cycleHelpArticle1Title;

  /// No description provided for @cycleHelpArticle1Desc.
  ///
  /// In en, this message translates to:
  /// **'The complete beginner\'s guide to understanding your body and what is actually happening every month.'**
  String get cycleHelpArticle1Desc;

  /// No description provided for @cycleHelpArticle2Title.
  ///
  /// In en, this message translates to:
  /// **'The four phases of your cycle'**
  String get cycleHelpArticle2Title;

  /// No description provided for @cycleHelpArticle2Desc.
  ///
  /// In en, this message translates to:
  /// **'Breaking down the menstrual, follicular, ovulation, and luteal phases. What your body is doing and what you might feel.'**
  String get cycleHelpArticle2Desc;

  /// No description provided for @cycleHelpArticle3Title.
  ///
  /// In en, this message translates to:
  /// **'Hormones and your cycle'**
  String get cycleHelpArticle3Title;

  /// No description provided for @cycleHelpArticle3Desc.
  ///
  /// In en, this message translates to:
  /// **'What estrogen, progesterone, LH, and FSH actually do. How hormone levels rise and fall and cause symptoms.'**
  String get cycleHelpArticle3Desc;

  /// No description provided for @cycleHelpArticle4Title.
  ///
  /// In en, this message translates to:
  /// **'What is spotting?'**
  String get cycleHelpArticle4Title;

  /// No description provided for @cycleHelpArticle4Desc.
  ///
  /// In en, this message translates to:
  /// **'The difference between spotting and a period. Common causes like ovulation and stress, and when to mention it.'**
  String get cycleHelpArticle4Desc;

  /// No description provided for @cycleHelpArticle5Title.
  ///
  /// In en, this message translates to:
  /// **'Things that affect your cycle'**
  String get cycleHelpArticle5Title;

  /// No description provided for @cycleHelpArticle5Desc.
  ///
  /// In en, this message translates to:
  /// **'Stress, sleep, exercise, diet, and travel. Why your cycle is a reflection of your overall health.'**
  String get cycleHelpArticle5Desc;

  /// No description provided for @cycleHelpArticle6Title.
  ///
  /// In en, this message translates to:
  /// **'Why cycle tracking matters'**
  String get cycleHelpArticle6Title;

  /// No description provided for @cycleHelpArticle6Desc.
  ///
  /// In en, this message translates to:
  /// **'What tracking tells you beyond predicting your period. How to use your logs to understand your baseline.'**
  String get cycleHelpArticle6Desc;

  /// No description provided for @cycleConfidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'High Confidence'**
  String get cycleConfidenceHigh;

  /// No description provided for @cycleConfidenceMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium Confidence'**
  String get cycleConfidenceMedium;

  /// No description provided for @cycleConfidenceLow.
  ///
  /// In en, this message translates to:
  /// **'Low Confidence'**
  String get cycleConfidenceLow;

  /// No description provided for @cycleCountdownInDays.
  ///
  /// In en, this message translates to:
  /// **'Your next period is in {days} days'**
  String cycleCountdownInDays(int days);

  /// No description provided for @cycleCountdownDueToday.
  ///
  /// In en, this message translates to:
  /// **'Your period is due today'**
  String get cycleCountdownDueToday;

  /// No description provided for @cycleCountdownDaysLate.
  ///
  /// In en, this message translates to:
  /// **'Your period is {days} days late'**
  String cycleCountdownDaysLate(int days);

  /// No description provided for @cycleInsightLate.
  ///
  /// In en, this message translates to:
  /// **'Your period is running late. This is more common than you think and doesn\'t always mean something is wrong. Stress, changes in sleep, illness, sudden weight changes, and intense exercise can all delay your cycle by several days or even weeks. If it\'s been over 2 weeks, it\'s worth taking a moment to check in with a trusted adult or doctor.'**
  String get cycleInsightLate;

  /// No description provided for @cycleInsightPeriodSoon.
  ///
  /// In en, this message translates to:
  /// **'Your period could arrive any day now. Progesterone levels are dropping which is what triggers menstruation to begin. You might feel more emotional, tired, or notice lower back discomfort — these are signs your body is getting ready. Keep a pad or period product nearby just in case.'**
  String get cycleInsightPeriodSoon;

  /// No description provided for @cycleInsightPeriod.
  ///
  /// In en, this message translates to:
  /// **'Your period is here because your body didn\'t need the uterine lining it built up this month, so it\'s shedding it. This is driven by a drop in estrogen and progesterone — your two main cycle hormones. Cramps happen because your uterus is contracting to push the lining out. Rest, heat pads, and staying hydrated can genuinely help right now.'**
  String get cycleInsightPeriod;

  /// No description provided for @cycleInsightFollicular.
  ///
  /// In en, this message translates to:
  /// **'Your body is now growing and maturing an egg inside your ovaries. Rising estrogen levels are doing a lot of good work — rebuilding your uterine lining and boosting your mood and energy. Most people feel their best during this phase. It\'s a great time to be active, social, and take on things that need focus.'**
  String get cycleInsightFollicular;

  /// No description provided for @cycleInsightOvulation.
  ///
  /// In en, this message translates to:
  /// **'Your body is releasing an egg today. A surge in a hormone called LH triggered this, and your estrogen is at its peak. You might notice clearer, stretchy discharge — this is completely normal and actually helps the reproductive system function. Some people feel a slight twinge or pain on one side of their lower abdomen during ovulation, which is also normal.'**
  String get cycleInsightOvulation;

  /// No description provided for @cycleInsightLuteal.
  ///
  /// In en, this message translates to:
  /// **'After ovulation, your body produces more progesterone to prepare for a possible pregnancy. This hormone is responsible for most PMS symptoms — bloating, breast tenderness, mood swings, and fatigue are all very common in this phase. If your period isn\'t coming, these symptoms will peak around 5 to 7 days before it arrives. You\'re not imagining it, it\'s hormonal.'**
  String get cycleInsightLuteal;

  /// No description provided for @cycleAlertMissing90Title.
  ///
  /// In en, this message translates to:
  /// **'Period Over 3 Months Late'**
  String get cycleAlertMissing90Title;

  /// No description provided for @cycleAlertMissing90Msg.
  ///
  /// In en, this message translates to:
  /// **'Your period is over 3 months late. This could indicate PCOS or hormonal changes. Please consult a healthcare provider.'**
  String get cycleAlertMissing90Msg;

  /// No description provided for @cycleAlertLate14Title.
  ///
  /// In en, this message translates to:
  /// **'Period 14 Days Late'**
  String get cycleAlertLate14Title;

  /// No description provided for @cycleAlertLate14Msg.
  ///
  /// In en, this message translates to:
  /// **'Your period is 14 days late. You may want to speak to a doctor if this is unusual for you.'**
  String get cycleAlertLate14Msg;

  /// No description provided for @cycleAlertLate7Title.
  ///
  /// In en, this message translates to:
  /// **'Period 7 Days Late'**
  String get cycleAlertLate7Title;

  /// No description provided for @cycleAlertLate7Msg.
  ///
  /// In en, this message translates to:
  /// **'Your period is 7 days late. This can happen due to stress, illness or changes in routine.'**
  String get cycleAlertLate7Msg;

  /// No description provided for @cycleAlertIrregularTitle.
  ///
  /// In en, this message translates to:
  /// **'Highly Irregular Cycles'**
  String get cycleAlertIrregularTitle;

  /// No description provided for @cycleAlertIrregularMsg.
  ///
  /// In en, this message translates to:
  /// **'Your cycles have been highly irregular recently. While this can be normal, consider speaking to a doctor if concerned.'**
  String get cycleAlertIrregularMsg;

  /// No description provided for @cycleAlertShortCycleTitle.
  ///
  /// In en, this message translates to:
  /// **'Unusually Short Cycles'**
  String get cycleAlertShortCycleTitle;

  /// No description provided for @cycleAlertShortCycleMsg.
  ///
  /// In en, this message translates to:
  /// **'Your last 3 cycles have been unusually short. Stress, travel, and illness can affect this.'**
  String get cycleAlertShortCycleMsg;

  /// No description provided for @cycleAlertLongCycleTitle.
  ///
  /// In en, this message translates to:
  /// **'Unusually Long Cycles'**
  String get cycleAlertLongCycleTitle;

  /// No description provided for @cycleAlertLongCycleMsg.
  ///
  /// In en, this message translates to:
  /// **'Your last 3 cycles have been unusually long. If this keeps happening, mention it to a doctor.'**
  String get cycleAlertLongCycleMsg;

  /// No description provided for @cycleAlertLongPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Long Periods'**
  String get cycleAlertLongPeriodTitle;

  /// No description provided for @cycleAlertLongPeriodMsg.
  ///
  /// In en, this message translates to:
  /// **'Your period has been lasting longer than usual (over 8 days). If this continues, check in with a doctor.'**
  String get cycleAlertLongPeriodMsg;

  /// No description provided for @cycleAlertHeavyBleedingTitle.
  ///
  /// In en, this message translates to:
  /// **'Very Heavy Bleeding'**
  String get cycleAlertHeavyBleedingTitle;

  /// No description provided for @cycleAlertHeavyBleedingMsg.
  ///
  /// In en, this message translates to:
  /// **'Your last period had 5 or more days of very heavy bleeding. If this is unusual or causes fatigue, consult a doctor.'**
  String get cycleAlertHeavyBleedingMsg;

  /// No description provided for @cycleDeviationInsightTitle.
  ///
  /// In en, this message translates to:
  /// **'Cycle Insight'**
  String get cycleDeviationInsightTitle;

  /// No description provided for @cycleDeviationSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get cycleDeviationSources;

  /// No description provided for @cycleDeviationFallbackBody.
  ///
  /// In en, this message translates to:
  /// **'More information about this insight will be available soon.'**
  String get cycleDeviationFallbackBody;

  /// No description provided for @mindfulnessOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Mindfulness'**
  String get mindfulnessOnboardingTitle;

  /// No description provided for @mindfulnessOnboardingFeature1Title.
  ///
  /// In en, this message translates to:
  /// **'Guided Meditations'**
  String get mindfulnessOnboardingFeature1Title;

  /// No description provided for @mindfulnessOnboardingFeature1Desc.
  ///
  /// In en, this message translates to:
  /// **'Relax and refocus with science-backed sessions.'**
  String get mindfulnessOnboardingFeature1Desc;

  /// No description provided for @mindfulnessOnboardingFeature2Title.
  ///
  /// In en, this message translates to:
  /// **'Mindful Reminders'**
  String get mindfulnessOnboardingFeature2Title;

  /// No description provided for @mindfulnessOnboardingFeature2Desc.
  ///
  /// In en, this message translates to:
  /// **'Gentle nudges to help you stay present throughout your day.'**
  String get mindfulnessOnboardingFeature2Desc;

  /// No description provided for @mindfulnessOnboardingFeature3Title.
  ///
  /// In en, this message translates to:
  /// **'Mood & Reflection'**
  String get mindfulnessOnboardingFeature3Title;

  /// No description provided for @mindfulnessOnboardingFeature3Desc.
  ///
  /// In en, this message translates to:
  /// **'Track your mood and reflect on your mental well-being.'**
  String get mindfulnessOnboardingFeature3Desc;

  /// No description provided for @mindfulnessOnboardingFeature4Title.
  ///
  /// In en, this message translates to:
  /// **'Progress Insights'**
  String get mindfulnessOnboardingFeature4Title;

  /// No description provided for @mindfulnessOnboardingFeature4Desc.
  ///
  /// In en, this message translates to:
  /// **'See your mindfulness journey and growth over time.'**
  String get mindfulnessOnboardingFeature4Desc;

  /// No description provided for @mindfulnessOnboardingBegin.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get mindfulnessOnboardingBegin;

  /// No description provided for @mindfulnessPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Mental Health'**
  String get mindfulnessPageTitle;

  /// No description provided for @mindfulnessResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Mental Health Data?'**
  String get mindfulnessResetTitle;

  /// No description provided for @mindfulnessResetMsg.
  ///
  /// In en, this message translates to:
  /// **'This will delete all your mood check-ins and mental health history. This cannot be undone.'**
  String get mindfulnessResetMsg;

  /// No description provided for @mindfulnessDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get mindfulnessDeleteAll;

  /// No description provided for @mindfulnessDeletedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'All mental health data has been deleted'**
  String get mindfulnessDeletedSnackbar;

  /// No description provided for @mindfulnessMoodHistory.
  ///
  /// In en, this message translates to:
  /// **'Mood History'**
  String get mindfulnessMoodHistory;

  /// No description provided for @mindfulnessMorningReadiness.
  ///
  /// In en, this message translates to:
  /// **'Morning Readiness'**
  String get mindfulnessMorningReadiness;

  /// No description provided for @mindfulnessReadinessSummary.
  ///
  /// In en, this message translates to:
  /// **'Sleep {sleep} · Energy {energy} · Stress {stress}'**
  String mindfulnessReadinessSummary(
    String sleep,
    String energy,
    String stress,
  );

  /// No description provided for @mindfulnessReadinessPrompt.
  ///
  /// In en, this message translates to:
  /// **'How ready are you today?'**
  String get mindfulnessReadinessPrompt;

  /// No description provided for @mindfulnessEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get mindfulnessEdit;

  /// No description provided for @mindfulnessTodaysCheckin.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Check-in'**
  String get mindfulnessTodaysCheckin;

  /// No description provided for @mindfulnessDailyCheckin.
  ///
  /// In en, this message translates to:
  /// **'Daily Check-in'**
  String get mindfulnessDailyCheckin;

  /// No description provided for @mindfulnessFeelingLabel.
  ///
  /// In en, this message translates to:
  /// **'Feeling {label}'**
  String mindfulnessFeelingLabel(String label);

  /// No description provided for @mindfulnessHowFeeling.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling?'**
  String get mindfulnessHowFeeling;

  /// No description provided for @mindfulnessLogButton.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get mindfulnessLogButton;

  /// No description provided for @mindfulnessBreathing.
  ///
  /// In en, this message translates to:
  /// **'Breathing'**
  String get mindfulnessBreathing;

  /// No description provided for @mindfulnessBreathingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Take a moment to breathe'**
  String get mindfulnessBreathingPrompt;

  /// No description provided for @mindfulnessAssessmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Mental Health Assessment'**
  String get mindfulnessAssessmentTitle;

  /// No description provided for @mindfulnessAssessmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'15 questions inspired by PHQ-9, GAD-7, and Maslach Burnout Inventory'**
  String get mindfulnessAssessmentSubtitle;

  /// No description provided for @mindfulnessStartAssessment.
  ///
  /// In en, this message translates to:
  /// **'Start Assessment'**
  String get mindfulnessStartAssessment;

  /// No description provided for @mindfulnessMoodInsights.
  ///
  /// In en, this message translates to:
  /// **'Mood Insights'**
  String get mindfulnessMoodInsights;

  /// No description provided for @mindfulnessLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get mindfulnessLast30Days;

  /// No description provided for @mindfulnessLogMoodPrompt.
  ///
  /// In en, this message translates to:
  /// **'Log your mood to see insights'**
  String get mindfulnessLogMoodPrompt;

  /// No description provided for @mindfulnessNoMoodData.
  ///
  /// In en, this message translates to:
  /// **'No mood data yet'**
  String get mindfulnessNoMoodData;

  /// No description provided for @mindfulnessLegendVeryHappy.
  ///
  /// In en, this message translates to:
  /// **'Very Happy'**
  String get mindfulnessLegendVeryHappy;

  /// No description provided for @mindfulnessLegendNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get mindfulnessLegendNeutral;

  /// No description provided for @mindfulnessLegendUnpleasant.
  ///
  /// In en, this message translates to:
  /// **'Unpleasant'**
  String get mindfulnessLegendUnpleasant;

  /// No description provided for @disclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Not for Professional Use'**
  String get disclaimerTitle;

  /// No description provided for @disclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'Synthese is a general wellness tracking tool. Nothing in this app constitutes medical, nutritional, psychological, or financial advice. Always consult a qualified professional before making decisions about your health or finances.'**
  String get disclaimerBody;

  /// No description provided for @disclaimerCredits.
  ///
  /// In en, this message translates to:
  /// **'This questionnaire covers 15 carefully researched questions inspired by validated tools like the PHQ-9, GAD-7, and Maslach Burnout Inventory.'**
  String get disclaimerCredits;

  /// No description provided for @disclaimerDuration.
  ///
  /// In en, this message translates to:
  /// **'Takes about 3-5 minutes to complete.'**
  String get disclaimerDuration;

  /// No description provided for @disclaimerStartTest.
  ///
  /// In en, this message translates to:
  /// **'Start Test'**
  String get disclaimerStartTest;

  /// No description provided for @questionnaireTitle.
  ///
  /// In en, this message translates to:
  /// **'Mental Health Assessment'**
  String get questionnaireTitle;

  /// No description provided for @questionnaireProgress.
  ///
  /// In en, this message translates to:
  /// **'QUESTION {current} OF {total}'**
  String questionnaireProgress(int current, int total);

  /// No description provided for @questionnaireViewResults.
  ///
  /// In en, this message translates to:
  /// **'View Results'**
  String get questionnaireViewResults;

  /// No description provided for @questionnaireBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get questionnaireBack;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultsTitle;

  /// No description provided for @resultsWellbeingSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Your Wellbeing Snapshot'**
  String get resultsWellbeingSnapshot;

  /// No description provided for @resultsWellbeingBody.
  ///
  /// In en, this message translates to:
  /// **'Based on your responses, here\'s a breakdown across eight dimensions of mental health.'**
  String get resultsWellbeingBody;

  /// No description provided for @resultsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This assessment is for personal reflection only and does not constitute a clinical diagnosis. If you are experiencing distress, please speak with a qualified mental health professional.'**
  String get resultsDisclaimer;

  /// No description provided for @resultsRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake Assessment'**
  String get resultsRetake;

  /// No description provided for @resultsInsightCrisisTitle.
  ///
  /// In en, this message translates to:
  /// **'A note of care'**
  String get resultsInsightCrisisTitle;

  /// No description provided for @resultsInsightCrisisBody.
  ///
  /// In en, this message translates to:
  /// **'Some of your responses suggest you may be experiencing thoughts that are difficult to carry. Please consider reaching out to a mental health professional, a trusted person, or a crisis line — you don\'t have to manage this alone.'**
  String get resultsInsightCrisisBody;

  /// No description provided for @resultsInsightHighTitle.
  ///
  /// In en, this message translates to:
  /// **'Where to focus'**
  String get resultsInsightHighTitle;

  /// No description provided for @resultsInsightHighBody.
  ///
  /// In en, this message translates to:
  /// **'Your results suggest elevated indicators in: {areas}. These areas may benefit from intentional support — whether through rest, professional guidance, or mindfulness practice.'**
  String resultsInsightHighBody(String areas);

  /// No description provided for @resultsInsightModerateTitle.
  ///
  /// In en, this message translates to:
  /// **'Worth watching'**
  String get resultsInsightModerateTitle;

  /// No description provided for @resultsInsightModerateBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re showing moderate indicators in: {areas}. Small, consistent habits — quality sleep, connection, movement — can make a meaningful difference.'**
  String resultsInsightModerateBody(String areas);

  /// No description provided for @resultsInsightGoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Looking good overall'**
  String get resultsInsightGoodTitle;

  /// No description provided for @resultsInsightGoodBody.
  ///
  /// In en, this message translates to:
  /// **'Your responses suggest a relatively balanced state of mental wellbeing. Keep up your healthy habits, and check in regularly — mental health can shift with life circumstances.'**
  String get resultsInsightGoodBody;

  /// No description provided for @resultsRiskIndicator.
  ///
  /// In en, this message translates to:
  /// **'RISK INDICATOR'**
  String get resultsRiskIndicator;

  /// No description provided for @resultsRiskLow.
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get resultsRiskLow;

  /// No description provided for @resultsRiskModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate Risk'**
  String get resultsRiskModerate;

  /// No description provided for @resultsRiskHigh.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get resultsRiskHigh;

  /// No description provided for @dimDepression.
  ///
  /// In en, this message translates to:
  /// **'Depression'**
  String get dimDepression;

  /// No description provided for @dimAnxiety.
  ///
  /// In en, this message translates to:
  /// **'Anxiety'**
  String get dimAnxiety;

  /// No description provided for @dimSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep Quality'**
  String get dimSleep;

  /// No description provided for @dimStress.
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get dimStress;

  /// No description provided for @dimSocial.
  ///
  /// In en, this message translates to:
  /// **'Social Connection'**
  String get dimSocial;

  /// No description provided for @dimEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy & Burnout'**
  String get dimEnergy;

  /// No description provided for @dimSelfEsteem.
  ///
  /// In en, this message translates to:
  /// **'Self-Esteem'**
  String get dimSelfEsteem;

  /// No description provided for @dimCrisis.
  ///
  /// In en, this message translates to:
  /// **'Crisis Indicators'**
  String get dimCrisis;

  /// No description provided for @dimCoping.
  ///
  /// In en, this message translates to:
  /// **'Coping & Resilience'**
  String get dimCoping;

  /// No description provided for @questFreqRarely.
  ///
  /// In en, this message translates to:
  /// **'Rarely or not at all'**
  String get questFreqRarely;

  /// No description provided for @questFreqSeveral.
  ///
  /// In en, this message translates to:
  /// **'Several days'**
  String get questFreqSeveral;

  /// No description provided for @questFreqMoreHalf.
  ///
  /// In en, this message translates to:
  /// **'More than half the days'**
  String get questFreqMoreHalf;

  /// No description provided for @questFreqNearly.
  ///
  /// In en, this message translates to:
  /// **'Nearly every day'**
  String get questFreqNearly;

  /// No description provided for @questQ1Text.
  ///
  /// In en, this message translates to:
  /// **'Over the past two weeks, how often have you felt little interest or pleasure in doing things you normally enjoy?'**
  String get questQ1Text;

  /// No description provided for @questQ2Text.
  ///
  /// In en, this message translates to:
  /// **'How often have you felt down, hopeless, or like things will never improve?'**
  String get questQ2Text;

  /// No description provided for @questQ3Text.
  ///
  /// In en, this message translates to:
  /// **'How often have you felt nervous, on edge, or unable to stop worrying?'**
  String get questQ3Text;

  /// No description provided for @questQ4Text.
  ///
  /// In en, this message translates to:
  /// **'When faced with a challenging situation, how do you typically respond?'**
  String get questQ4Text;

  /// No description provided for @questQ4O1.
  ///
  /// In en, this message translates to:
  /// **'I stay calm and handle it well'**
  String get questQ4O1;

  /// No description provided for @questQ4O2.
  ///
  /// In en, this message translates to:
  /// **'I feel some stress but manage'**
  String get questQ4O2;

  /// No description provided for @questQ4O3.
  ///
  /// In en, this message translates to:
  /// **'I feel quite anxious and overwhelmed'**
  String get questQ4O3;

  /// No description provided for @questQ4O4.
  ///
  /// In en, this message translates to:
  /// **'I avoid the situation entirely'**
  String get questQ4O4;

  /// No description provided for @questQ5Text.
  ///
  /// In en, this message translates to:
  /// **'How would you describe your sleep over the past month?'**
  String get questQ5Text;

  /// No description provided for @questQ5O1.
  ///
  /// In en, this message translates to:
  /// **'Restful, 7-9 hours most nights'**
  String get questQ5O1;

  /// No description provided for @questQ5O2.
  ///
  /// In en, this message translates to:
  /// **'Occasionally disrupted but manageable'**
  String get questQ5O2;

  /// No description provided for @questQ5O3.
  ///
  /// In en, this message translates to:
  /// **'Frequently poor - trouble falling or staying asleep'**
  String get questQ5O3;

  /// No description provided for @questQ5O4.
  ///
  /// In en, this message translates to:
  /// **'Very poor - consistently exhausted'**
  String get questQ5O4;

  /// No description provided for @questQ6Text.
  ///
  /// In en, this message translates to:
  /// **'How would you rate your overall stress level in your daily life right now?'**
  String get questQ6Text;

  /// No description provided for @questQ6O1.
  ///
  /// In en, this message translates to:
  /// **'Low - I feel mostly at ease'**
  String get questQ6O1;

  /// No description provided for @questQ6O2.
  ///
  /// In en, this message translates to:
  /// **'Moderate - manageable most days'**
  String get questQ6O2;

  /// No description provided for @questQ6O3.
  ///
  /// In en, this message translates to:
  /// **'High - it\'s affecting my routine'**
  String get questQ6O3;

  /// No description provided for @questQ6O4.
  ///
  /// In en, this message translates to:
  /// **'Very high - I feel overwhelmed regularly'**
  String get questQ6O4;

  /// No description provided for @questQ7Text.
  ///
  /// In en, this message translates to:
  /// **'How connected do you feel to the people around you - friends, family, teammates?'**
  String get questQ7Text;

  /// No description provided for @questQ7O1.
  ///
  /// In en, this message translates to:
  /// **'Very connected and supported'**
  String get questQ7O1;

  /// No description provided for @questQ7O2.
  ///
  /// In en, this message translates to:
  /// **'Mostly connected, with some distance'**
  String get questQ7O2;

  /// No description provided for @questQ7O3.
  ///
  /// In en, this message translates to:
  /// **'Often isolated or misunderstood'**
  String get questQ7O3;

  /// No description provided for @questQ7O4.
  ///
  /// In en, this message translates to:
  /// **'Very alone and disconnected'**
  String get questQ7O4;

  /// No description provided for @questQ8Text.
  ///
  /// In en, this message translates to:
  /// **'How would you describe your energy and motivation levels lately?'**
  String get questQ8Text;

  /// No description provided for @questQ8O1.
  ///
  /// In en, this message translates to:
  /// **'High - I feel driven and engaged'**
  String get questQ8O1;

  /// No description provided for @questQ8O2.
  ///
  /// In en, this message translates to:
  /// **'Steady - some ups and downs'**
  String get questQ8O2;

  /// No description provided for @questQ8O3.
  ///
  /// In en, this message translates to:
  /// **'Low - getting started is a struggle'**
  String get questQ8O3;

  /// No description provided for @questQ8O4.
  ///
  /// In en, this message translates to:
  /// **'Very low - I feel fatigued most of the time'**
  String get questQ8O4;

  /// No description provided for @questQ9Text.
  ///
  /// In en, this message translates to:
  /// **'How often do you catch yourself thinking negatively about yourself or your abilities?'**
  String get questQ9Text;

  /// No description provided for @questQ9O1.
  ///
  /// In en, this message translates to:
  /// **'Rarely - I generally feel confident'**
  String get questQ9O1;

  /// No description provided for @questQ9O2.
  ///
  /// In en, this message translates to:
  /// **'Occasionally, but I brush it off'**
  String get questQ9O2;

  /// No description provided for @questQ9O3.
  ///
  /// In en, this message translates to:
  /// **'Often - I doubt myself frequently'**
  String get questQ9O3;

  /// No description provided for @questQ9O4.
  ///
  /// In en, this message translates to:
  /// **'Almost always - it holds me back'**
  String get questQ9O4;

  /// No description provided for @questQ10Text.
  ///
  /// In en, this message translates to:
  /// **'Do you experience physical symptoms - like a racing heart, tightness in your chest, or shortness of breath - during everyday situations?'**
  String get questQ10Text;

  /// No description provided for @questQ10O1.
  ///
  /// In en, this message translates to:
  /// **'Never or very rarely'**
  String get questQ10O1;

  /// No description provided for @questQ10O2.
  ///
  /// In en, this message translates to:
  /// **'Sometimes, but only under real pressure'**
  String get questQ10O2;

  /// No description provided for @questQ10O3.
  ///
  /// In en, this message translates to:
  /// **'Fairly often, even in routine situations'**
  String get questQ10O3;

  /// No description provided for @questQ10O4.
  ///
  /// In en, this message translates to:
  /// **'Very often - it disrupts my day'**
  String get questQ10O4;

  /// No description provided for @questQ11Text.
  ///
  /// In en, this message translates to:
  /// **'How often do you feel emotionally drained or used up by the end of the day?'**
  String get questQ11Text;

  /// No description provided for @questQ11O1.
  ///
  /// In en, this message translates to:
  /// **'Rarely - I usually have energy left'**
  String get questQ11O1;

  /// No description provided for @questQ11O2.
  ///
  /// In en, this message translates to:
  /// **'Sometimes after tough days'**
  String get questQ11O2;

  /// No description provided for @questQ11O3.
  ///
  /// In en, this message translates to:
  /// **'Often - I feel depleted most days'**
  String get questQ11O3;

  /// No description provided for @questQ11O4.
  ///
  /// In en, this message translates to:
  /// **'Almost always - I\'m running on empty'**
  String get questQ11O4;

  /// No description provided for @questQ12Text.
  ///
  /// In en, this message translates to:
  /// **'In the past two weeks, have you had thoughts that you\'d be better off not being here, or of hurting yourself?'**
  String get questQ12Text;

  /// No description provided for @questQ12O1.
  ///
  /// In en, this message translates to:
  /// **'Not at all'**
  String get questQ12O1;

  /// No description provided for @questQ12O2.
  ///
  /// In en, this message translates to:
  /// **'Briefly, but it passed quickly'**
  String get questQ12O2;

  /// No description provided for @questQ12O3.
  ///
  /// In en, this message translates to:
  /// **'Somewhat - these thoughts recur'**
  String get questQ12O3;

  /// No description provided for @questQ12O4.
  ///
  /// In en, this message translates to:
  /// **'Yes, frequently or seriously'**
  String get questQ12O4;

  /// No description provided for @questQ13Text.
  ///
  /// In en, this message translates to:
  /// **'When you\'re going through a hard time, which of the following best describes how you cope?'**
  String get questQ13Text;

  /// No description provided for @questQ13O1.
  ///
  /// In en, this message translates to:
  /// **'I reach out for support and use healthy strategies'**
  String get questQ13O1;

  /// No description provided for @questQ13O2.
  ///
  /// In en, this message translates to:
  /// **'I manage on my own but it takes effort'**
  String get questQ13O2;

  /// No description provided for @questQ13O3.
  ///
  /// In en, this message translates to:
  /// **'I withdraw and tend to bottle things up'**
  String get questQ13O3;

  /// No description provided for @questQ13O4.
  ///
  /// In en, this message translates to:
  /// **'I turn to unhealthy habits or avoidance'**
  String get questQ13O4;

  /// No description provided for @questQ14Text.
  ///
  /// In en, this message translates to:
  /// **'How would you describe your ability to concentrate and make decisions lately?'**
  String get questQ14Text;

  /// No description provided for @questQ14O1.
  ///
  /// In en, this message translates to:
  /// **'Sharp - I feel clear and focused'**
  String get questQ14O1;

  /// No description provided for @questQ14O2.
  ///
  /// In en, this message translates to:
  /// **'Decent - occasional lapses'**
  String get questQ14O2;

  /// No description provided for @questQ14O3.
  ///
  /// In en, this message translates to:
  /// **'Struggling - my mind feels foggy often'**
  String get questQ14O3;

  /// No description provided for @questQ14O4.
  ///
  /// In en, this message translates to:
  /// **'Very difficult - I can\'t stay on task'**
  String get questQ14O4;

  /// No description provided for @questQ15Text.
  ///
  /// In en, this message translates to:
  /// **'When something difficult happens, how quickly do you tend to recover emotionally?'**
  String get questQ15Text;

  /// No description provided for @questQ15O1.
  ///
  /// In en, this message translates to:
  /// **'Quickly - I bounce back with perspective'**
  String get questQ15O1;

  /// No description provided for @questQ15O2.
  ///
  /// In en, this message translates to:
  /// **'Takes a day or two but I get there'**
  String get questQ15O2;

  /// No description provided for @questQ15O3.
  ///
  /// In en, this message translates to:
  /// **'Slowly - I carry it for a long time'**
  String get questQ15O3;

  /// No description provided for @questQ15O4.
  ///
  /// In en, this message translates to:
  /// **'I rarely feel like I\'ve fully recovered'**
  String get questQ15O4;

  /// No description provided for @cyArtKeyPoints.
  ///
  /// In en, this message translates to:
  /// **'Key points:'**
  String get cyArtKeyPoints;

  /// No description provided for @cyArtSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviewed sources & bibliography'**
  String get cyArtSourcesTitle;

  /// No description provided for @cyArtPrimaryResearch.
  ///
  /// In en, this message translates to:
  /// **'Primary research:'**
  String get cyArtPrimaryResearch;

  /// No description provided for @cyArtClinicalResources.
  ///
  /// In en, this message translates to:
  /// **'Clinical and educational resources:'**
  String get cyArtClinicalResources;

  /// No description provided for @cyA1Title.
  ///
  /// In en, this message translates to:
  /// **'What Is a Menstrual Cycle?'**
  String get cyA1Title;

  /// No description provided for @cyA1Sub.
  ///
  /// In en, this message translates to:
  /// **'The complete beginner\'s guide to understanding your body'**
  String get cyA1Sub;

  /// No description provided for @cyA1S1H.
  ///
  /// In en, this message translates to:
  /// **'What is actually happening?'**
  String get cyA1S1H;

  /// No description provided for @cyA1S1P1.
  ///
  /// In en, this message translates to:
  /// **'Every month, your body goes through a series of changes designed to prepare for a possible pregnancy. This sequence of events is called the menstrual cycle. It involves your brain, your ovaries, your uterus, and a carefully timed series of hormonal signals that all work together in a coordinated rhythm.'**
  String get cyA1S1P1;

  /// No description provided for @cyA1S1P2.
  ///
  /// In en, this message translates to:
  /// **'The menstrual cycle is a series of natural changes in hormone production and the structures of the uterus and ovaries of the female reproductive system. The ovarian cycle controls the production and release of eggs, and the uterine cycle governs the preparation and maintenance of the lining of the uterus to receive an embryo. These two cycles run concurrently and are coordinated with each other.'**
  String get cyA1S1P2;

  /// No description provided for @cyA1S1P3.
  ///
  /// In en, this message translates to:
  /// **'In simple terms: your ovaries grow and release an egg. Your uterus builds up a thick, soft lining in case that egg gets fertilised. If it doesn\'t, the lining sheds. That shedding is your period. Then the whole process starts again.'**
  String get cyA1S1P3;

  /// No description provided for @cyA1S2H.
  ///
  /// In en, this message translates to:
  /// **'The organs involved'**
  String get cyA1S2H;

  /// No description provided for @cyA1S2P1.
  ///
  /// In en, this message translates to:
  /// **'Understanding your cycle starts with knowing which parts of your body are involved:'**
  String get cyA1S2P1;

  /// No description provided for @cyA1S2B1T.
  ///
  /// In en, this message translates to:
  /// **'The ovaries'**
  String get cyA1S2B1T;

  /// No description provided for @cyA1S2B1B.
  ///
  /// In en, this message translates to:
  /// **'Two small, almond-shaped organs on either side of your uterus. They store your eggs and produce the hormones estrogen and progesterone. You are born with all the eggs you will ever have — roughly 1 to 2 million at birth, which reduces to around 300,000 by puberty.'**
  String get cyA1S2B1B;

  /// No description provided for @cyA1S2B2T.
  ///
  /// In en, this message translates to:
  /// **'The uterus'**
  String get cyA1S2B2T;

  /// No description provided for @cyA1S2B2B.
  ///
  /// In en, this message translates to:
  /// **'A pear-shaped muscular organ where a baby grows during pregnancy. Its inner lining, called the endometrium, builds up and sheds every cycle.'**
  String get cyA1S2B2B;

  /// No description provided for @cyA1S2B3T.
  ///
  /// In en, this message translates to:
  /// **'The fallopian tubes'**
  String get cyA1S2B3T;

  /// No description provided for @cyA1S2B3B.
  ///
  /// In en, this message translates to:
  /// **'Two narrow tubes connecting the ovaries to the uterus. When an egg is released, it travels down the fallopian tube toward the uterus.'**
  String get cyA1S2B3B;

  /// No description provided for @cyA1S2B4T.
  ///
  /// In en, this message translates to:
  /// **'The hypothalamus and pituitary gland'**
  String get cyA1S2B4T;

  /// No description provided for @cyA1S2B4B.
  ///
  /// In en, this message translates to:
  /// **'Located in your brain. These send out the hormonal signals that start and control the entire cycle.'**
  String get cyA1S2B4B;

  /// No description provided for @cyA1S3H.
  ///
  /// In en, this message translates to:
  /// **'When does it all begin?'**
  String get cyA1S3H;

  /// No description provided for @cyA1S3P1.
  ///
  /// In en, this message translates to:
  /// **'Menarche — the first menstrual period — typically occurs between the ages of 10 and 16, with the average age of onset being 12.4 years.'**
  String get cyA1S3P1;

  /// No description provided for @cyA1S3P2.
  ///
  /// In en, this message translates to:
  /// **'Another way to predict when your period will come is to think back to when breast development began — menarche usually happens about 2 to 2.5 years after breasts start developing.'**
  String get cyA1S3P2;

  /// No description provided for @cyA1S3P3.
  ///
  /// In en, this message translates to:
  /// **'The age varies widely from person to person and is influenced by genetics, body composition, nutrition, and general health. People commonly get their periods at around the same time their mother did. Getting your first period any time between ages 9 and 15 is considered within the normal range.'**
  String get cyA1S3P3;

  /// No description provided for @cyA1S4H.
  ///
  /// In en, this message translates to:
  /// **'How long is a normal cycle?'**
  String get cyA1S4H;

  /// No description provided for @cyA1S4P1.
  ///
  /// In en, this message translates to:
  /// **'This is where a lot of confusion starts. Most people have heard that a cycle is 28 days. That number is an average — not a rule.'**
  String get cyA1S4P1;

  /// No description provided for @cyA1S4P2.
  ///
  /// In en, this message translates to:
  /// **'For teenagers, a normal menstrual cycle can be anywhere between 21 and 45 days. The average menstrual cycle length is approximately 28 days.'**
  String get cyA1S4P2;

  /// No description provided for @cyA1S4P3.
  ///
  /// In en, this message translates to:
  /// **'A large-scale real-world study published in npj Digital Medicine analysed data from over 600,000 cycles and found that the mean cycle length across ovulatory cycles was 29.3 days, with a mean follicular phase length of 16.9 days and a mean luteal phase length of 12.4 days.'**
  String get cyA1S4P3;

  /// No description provided for @cyA1S4P4.
  ///
  /// In en, this message translates to:
  /// **'Research from the Apple Women\'s Health Study — one of the largest studies of its kind, conducted by Harvard T.H. Chan School of Public Health — analysed 165,668 cycles across 12,608 participants and found that cycle variability is considerably higher — by 46% — among those aged under 20 compared to those aged 35 to 39. In other words, irregular cycles are the norm for teenagers, not the exception.'**
  String get cyA1S4P4;

  /// No description provided for @cyA1S5H.
  ///
  /// In en, this message translates to:
  /// **'How long does a period last?'**
  String get cyA1S5H;

  /// No description provided for @cyA1S5P1.
  ///
  /// In en, this message translates to:
  /// **'According to the International Federation of Gynecology and Obstetrics (FIGO), normal menstrual cycles should have consistent frequency, regularity, duration, and volume of flow.'**
  String get cyA1S5P1;

  /// No description provided for @cyA1S5P2.
  ///
  /// In en, this message translates to:
  /// **'A period typically lasts between 3 and 7 days, though anywhere in that range is normal. The amount of blood lost during a typical period is around 30 to 80 mL — roughly 2 to 6 tablespoons.'**
  String get cyA1S5P2;

  /// No description provided for @cyA1S6H.
  ///
  /// In en, this message translates to:
  /// **'Why are teenage cycles so irregular?'**
  String get cyA1S6H;

  /// No description provided for @cyA1S6P1.
  ///
  /// In en, this message translates to:
  /// **'In the first 1 to 2 years following your first period, it is very common and normal to have irregular cycles. In fact, in the first year after your first period, up to 80% of your menstrual cycles may be anovulatory — meaning no egg is released.'**
  String get cyA1S6P1;

  /// No description provided for @cyA1S6P2.
  ///
  /// In en, this message translates to:
  /// **'This happens because the hormonal communication system between your brain and ovaries — called the HPO axis — is still maturing. It takes time for this system to find its rhythm. During the first two years following menarche, ovulation is absent in around half of cycles. Five years after menarche, ovulation occurs in around 75% of cycles.'**
  String get cyA1S6P2;

  /// No description provided for @cyA1S6P3.
  ///
  /// In en, this message translates to:
  /// **'A 2024 study published in ScienceDirect, analysing 38,916 cycles from 6,486 adolescents aged 13–18 using the Clue app, found that individuals less than 1 year post-menarche had a 2.6 times higher odds of having a highly variable cycle and 5 times higher odds of short cycles compared to those further along in their reproductive development.'**
  String get cyA1S6P3;

  /// No description provided for @cyA1S6KP1.
  ///
  /// In en, this message translates to:
  /// **'Irregular cycles in your teens are biological, not a sign something is wrong.'**
  String get cyA1S6KP1;

  /// No description provided for @cyA1S6KP2.
  ///
  /// In en, this message translates to:
  /// **'It can take 2 to 5 years after your first period for cycles to stabilise.'**
  String get cyA1S6KP2;

  /// No description provided for @cyA1S6KP3.
  ///
  /// In en, this message translates to:
  /// **'The 28-day average applies to adults, not teenagers.'**
  String get cyA1S6KP3;

  /// No description provided for @cyA1S6KP4.
  ///
  /// In en, this message translates to:
  /// **'Your cycle length may vary by several days from month to month and that is completely normal.'**
  String get cyA1S6KP4;

  /// No description provided for @cyA1S7H.
  ///
  /// In en, this message translates to:
  /// **'What does \"Day 1\" mean?'**
  String get cyA1S7H;

  /// No description provided for @cyA1S7P1.
  ///
  /// In en, this message translates to:
  /// **'When discussing timing within the menstrual cycle, the first day of heavy menstrual flow is considered Day 1. This is the standard used by doctors and researchers worldwide. Every cycle is measured from Day 1 of one period to Day 1 of the next.'**
  String get cyA1S7P1;

  /// No description provided for @cyA1S8H.
  ///
  /// In en, this message translates to:
  /// **'When should you talk to a doctor?'**
  String get cyA1S8H;

  /// No description provided for @cyA1S8P1.
  ///
  /// In en, this message translates to:
  /// **'Most cycle irregularities in teenagers are normal. However, there are specific situations where it is worth speaking to a doctor or a trusted adult:'**
  String get cyA1S8P1;

  /// No description provided for @cyA1S8L1.
  ///
  /// In en, this message translates to:
  /// **'Your first period has not arrived by age 15.'**
  String get cyA1S8L1;

  /// No description provided for @cyA1S8L2.
  ///
  /// In en, this message translates to:
  /// **'Your periods stop for 3 or more months in a row and you are not pregnant.'**
  String get cyA1S8L2;

  /// No description provided for @cyA1S8L3.
  ///
  /// In en, this message translates to:
  /// **'Your cycle is consistently shorter than 21 days or longer than 45 days.'**
  String get cyA1S8L3;

  /// No description provided for @cyA1S8L4.
  ///
  /// In en, this message translates to:
  /// **'Your period lasts longer than 7 days regularly.'**
  String get cyA1S8L4;

  /// No description provided for @cyA1S8L5.
  ///
  /// In en, this message translates to:
  /// **'You are soaking through a pad or tampon in under 2 hours.'**
  String get cyA1S8L5;

  /// No description provided for @cyA1S8L6.
  ///
  /// In en, this message translates to:
  /// **'Your periods cause pain severe enough to miss school or daily activities.'**
  String get cyA1S8L6;

  /// No description provided for @cyA1GraphTitle.
  ///
  /// In en, this message translates to:
  /// **'Average cycle length by age group — Apple Women\'s Health Study, 2023 (n = 165,668 cycles)'**
  String get cyA1GraphTitle;

  /// No description provided for @cyA1GraphUnder20.
  ///
  /// In en, this message translates to:
  /// **'Under\n20'**
  String get cyA1GraphUnder20;

  /// No description provided for @cyA1GraphYourAge.
  ///
  /// In en, this message translates to:
  /// **'Your age group'**
  String get cyA1GraphYourAge;

  /// No description provided for @cyA1GraphOtherAge.
  ///
  /// In en, this message translates to:
  /// **'Other age groups'**
  String get cyA1GraphOtherAge;

  /// No description provided for @cyA1GraphCaption.
  ///
  /// In en, this message translates to:
  /// **'Cycles are longest and most variable in the teenage years and gradually shorten and stabilise into the late twenties and thirties.'**
  String get cyA1GraphCaption;

  /// No description provided for @cyA2Title.
  ///
  /// In en, this message translates to:
  /// **'The Four Phases of Your Cycle'**
  String get cyA2Title;

  /// No description provided for @cyA2Sub.
  ///
  /// In en, this message translates to:
  /// **'What your body is doing every single day of the month'**
  String get cyA2Sub;

  /// No description provided for @cyA2OvH.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get cyA2OvH;

  /// No description provided for @cyA2OvP1.
  ///
  /// In en, this message translates to:
  /// **'Most people think of their menstrual cycle as just their period — a few uncomfortable days every month. But your period is only one of four distinct phases that your body moves through every single cycle. Each phase has its own hormonal environment, its own physical changes, and its own emotional signature.'**
  String get cyA2OvP1;

  /// No description provided for @cyA2OvP2.
  ///
  /// In en, this message translates to:
  /// **'The menstrual cycle comprises two distinct cycles — one within the ovary and another within the endometrium. The phases of the ovarian cycle include the follicular phase, ovulation, and the luteal phase, while the endometrial cycle consists of the proliferative phase, the secretory phase, and the menstrual phase. These phases are coordinated with each other and run simultaneously.'**
  String get cyA2OvP2;

  /// No description provided for @cyA2OvP3.
  ///
  /// In en, this message translates to:
  /// **'In everyday language, these are grouped into four phases: menstrual, follicular, ovulation, and the luteal phase. Here is what happens in each one.'**
  String get cyA2OvP3;

  /// No description provided for @cyA2P1H.
  ///
  /// In en, this message translates to:
  /// **'Phase 1 — The Menstrual Phase'**
  String get cyA2P1H;

  /// No description provided for @cyA2P1Meta.
  ///
  /// In en, this message translates to:
  /// **'Days 1 to 3–7  |  Hormone profile: Estrogen low, progesterone low'**
  String get cyA2P1Meta;

  /// No description provided for @cyA2P1P1.
  ///
  /// In en, this message translates to:
  /// **'This is Day 1. The first day of your period is officially the first day of your entire cycle — not the end of it.'**
  String get cyA2P1P1;

  /// No description provided for @cyA2P1P2.
  ///
  /// In en, this message translates to:
  /// **'The menstrual phase starts with the shedding of the uterine lining, which occurs when a drop in estrogen and progesterone signals the uterus to shed its endometrial lining. The average blood loss during a period is around 2 to 3 tablespoons.'**
  String get cyA2P1P2;

  /// No description provided for @cyA2P1P3.
  ///
  /// In en, this message translates to:
  /// **'How long a period lasts varies by person, but most periods last 3 to 7 days, with 5 to 6 days being most common. If your period consistently lasts longer than 8 days or is very heavy, consult your healthcare provider.'**
  String get cyA2P1P3;

  /// No description provided for @cyA2PhysLabel.
  ///
  /// In en, this message translates to:
  /// **'What you might feel physically:'**
  String get cyA2PhysLabel;

  /// No description provided for @cyA2P1Phys1.
  ///
  /// In en, this message translates to:
  /// **'Cramping in the lower abdomen and back — caused by prostaglandins, chemicals that trigger uterine contractions.'**
  String get cyA2P1Phys1;

  /// No description provided for @cyA2P1Phys2.
  ///
  /// In en, this message translates to:
  /// **'Fatigue and low energy — your body is doing real physiological work.'**
  String get cyA2P1Phys2;

  /// No description provided for @cyA2P1Phys3.
  ///
  /// In en, this message translates to:
  /// **'Flow that is heavier at the start and lighter toward the end.'**
  String get cyA2P1Phys3;

  /// No description provided for @cyA2EmoLabel.
  ///
  /// In en, this message translates to:
  /// **'What you might feel emotionally:'**
  String get cyA2EmoLabel;

  /// No description provided for @cyA2P1Emo1.
  ///
  /// In en, this message translates to:
  /// **'Lower mood and reduced motivation as both estrogen and progesterone are at their lowest point.'**
  String get cyA2P1Emo1;

  /// No description provided for @cyA2P1Emo2.
  ///
  /// In en, this message translates to:
  /// **'Increased sensitivity and a desire to rest and withdraw.'**
  String get cyA2P1Emo2;

  /// No description provided for @cyA2P2H.
  ///
  /// In en, this message translates to:
  /// **'Phase 2 — The Follicular Phase'**
  String get cyA2P2H;

  /// No description provided for @cyA2P2Meta.
  ///
  /// In en, this message translates to:
  /// **'Days 1 to ~14  |  Hormone profile: Estrogen rising, FSH active'**
  String get cyA2P2Meta;

  /// No description provided for @cyA2P2P1.
  ///
  /// In en, this message translates to:
  /// **'The follicular phase begins on the same day as your period and runs until ovulation. The name comes from follicles: tiny fluid-filled sacs in your ovaries, each containing an immature egg.'**
  String get cyA2P2P1;

  /// No description provided for @cyA2P2P2.
  ///
  /// In en, this message translates to:
  /// **'This phase starts when the brain releases follicle-stimulating hormone (FSH). This stimulates the ovaries to produce around 5 to 20 small follicles. Only the healthiest egg will eventually mature — the rest are reabsorbed. The average follicular phase lasts about 16 days, ranging from 11 to 27 days depending on the cycle.'**
  String get cyA2P2P2;

  /// No description provided for @cyA2P2P3.
  ///
  /// In en, this message translates to:
  /// **'The development of the dominant follicle happens in three stages: recruitment (days 1 to 4), selection (days 5 to 7), and dominance (from day 8 onward). By cycle day 8, one follicle exerts dominance by promoting its own growth and suppressing others.'**
  String get cyA2P2P3;

  /// No description provided for @cyA2P2P4.
  ///
  /// In en, this message translates to:
  /// **'A groundbreaking 2024 study found that during the pre-ovulatory phase (the end of the follicular phase), brain network connectivity and complexity are at their highest. You\'re not just having a good week by chance — your brain is operating in its most responsive state.'**
  String get cyA2P2P4;

  /// No description provided for @cyA2P2KeyT.
  ///
  /// In en, this message translates to:
  /// **'Key point'**
  String get cyA2P2KeyT;

  /// No description provided for @cyA2P2KeyB.
  ///
  /// In en, this message translates to:
  /// **'The length of this phase varies most between individuals. The luteal phase is usually stable at 14 days — so variability in overall cycle length comes almost entirely from the follicular phase.'**
  String get cyA2P2KeyB;

  /// No description provided for @cyA2P3H.
  ///
  /// In en, this message translates to:
  /// **'Phase 3 — Ovulation'**
  String get cyA2P3H;

  /// No description provided for @cyA2P3Meta.
  ///
  /// In en, this message translates to:
  /// **'Day ~14  |  Hormone profile: LH surge, estrogen peaks then drops'**
  String get cyA2P3Meta;

  /// No description provided for @cyA2P3P1.
  ///
  /// In en, this message translates to:
  /// **'Ovulation is a single event, not a phase — it lasts only 12 to 24 hours. But it is the central event of the entire cycle. Everything before it builds toward it, and everything after is a response to it.'**
  String get cyA2P3P1;

  /// No description provided for @cyA2P3P2.
  ///
  /// In en, this message translates to:
  /// **'Ovulation typically occurs approximately 36 to 44 hours after the onset of the LH surge. At the end of ovulation, levels of estradiol decrease. Cervical changes result in increased, watery cervical mucus to facilitate sperm entry.'**
  String get cyA2P3P2;

  /// No description provided for @cyA2P3P3.
  ///
  /// In en, this message translates to:
  /// **'In the middle of the cycle, a surge of luteinizing hormone triggers the release of a mature egg from the dominant follicle in one of the ovaries. The egg travels down the fallopian tube where it stays for 12 to 24 hours.'**
  String get cyA2P3P3;

  /// No description provided for @cyA2P3P4.
  ///
  /// In en, this message translates to:
  /// **'Only about 13% of people have exactly 28-day cycles, so significant variation in ovulation timing is completely normal.'**
  String get cyA2P3P4;

  /// No description provided for @cyA2P4H.
  ///
  /// In en, this message translates to:
  /// **'Phase 4 — The Luteal Phase'**
  String get cyA2P4H;

  /// No description provided for @cyA2P4Meta.
  ///
  /// In en, this message translates to:
  /// **'Days ~15 to 28  |  Hormone profile: Progesterone dominant'**
  String get cyA2P4Meta;

  /// No description provided for @cyA2P4P1.
  ///
  /// In en, this message translates to:
  /// **'After ovulation, the follicle that released the egg transforms into a temporary gland called the corpus luteum, which begins producing progesterone. This is the phase most people feel the most.'**
  String get cyA2P4P1;

  /// No description provided for @cyA2P4P2.
  ///
  /// In en, this message translates to:
  /// **'The empty follicle produces progesterone and some estrogen to support a potential pregnancy. If no pregnancy occurs, it breaks down after about 9 to 11 days. The luteal phase often lasts about 14 days but can range between 9 and 16 days.'**
  String get cyA2P4P2;

  /// No description provided for @cyA2P4P3.
  ///
  /// In en, this message translates to:
  /// **'PMS is likely influenced by the action of progesterone on neurotransmitters including GABA, serotonin, and dopamine. Clinical trials show that serotonin levels shift significantly during this phase, linking PMS to mood changes.'**
  String get cyA2P4P3;

  /// No description provided for @cyA2P4P4.
  ///
  /// In en, this message translates to:
  /// **'A 2024 study published in Nature Neuroscience found measurable structural changes in the brain during the luteal phase. Luteal phase symptoms aren\'t \"all in your head\" — they\'re rooted in real neurobiological changes driven by hormones.'**
  String get cyA2P4P4;

  /// No description provided for @cyA2P4P5.
  ///
  /// In en, this message translates to:
  /// **'Food cravings, especially for carbohydrates and sugar, are common as progesterone and serotonin fluctuations drive appetite during this phase.'**
  String get cyA2P4P5;

  /// No description provided for @cyA2P4P6.
  ///
  /// In en, this message translates to:
  /// **'Large surveys show up to 90% of people who menstruate experience at least one PMS symptom like anger, irritability, or bloating.'**
  String get cyA2P4P6;

  /// No description provided for @cyA2S8H.
  ///
  /// In en, this message translates to:
  /// **'When should you talk to a doctor?'**
  String get cyA2S8H;

  /// No description provided for @cyA2S8L1.
  ///
  /// In en, this message translates to:
  /// **'Your periods are consistently causing pain severe enough to miss school or daily activities.'**
  String get cyA2S8L1;

  /// No description provided for @cyA2S8L2.
  ///
  /// In en, this message translates to:
  /// **'Luteal phase mood symptoms are significantly affecting your relationships or mental health.'**
  String get cyA2S8L2;

  /// No description provided for @cyA2S8L3.
  ///
  /// In en, this message translates to:
  /// **'You experience no recognisable phase pattern (no energy shifts or mucus changes).'**
  String get cyA2S8L3;

  /// No description provided for @cyA2S8P1.
  ///
  /// In en, this message translates to:
  /// **'In some cases, ovulation may not occur, resulting in anovulatory cycles. These are common in the first 12 to 18 months after the first period. If you are well past your first year and symptoms suggest you aren\'t ovulating, a doctor can investigate.'**
  String get cyA2S8P1;

  /// No description provided for @cyA2GraphTitle.
  ///
  /// In en, this message translates to:
  /// **'Hormone levels across a 28-day menstrual cycle'**
  String get cyA2GraphTitle;

  /// No description provided for @cyA2GraphMenstrual.
  ///
  /// In en, this message translates to:
  /// **'Menstrual'**
  String get cyA2GraphMenstrual;

  /// No description provided for @cyA2GraphFollicular.
  ///
  /// In en, this message translates to:
  /// **'Follicular'**
  String get cyA2GraphFollicular;

  /// No description provided for @cyA2GraphOv.
  ///
  /// In en, this message translates to:
  /// **'Ov.'**
  String get cyA2GraphOv;

  /// No description provided for @cyA2GraphLuteal.
  ///
  /// In en, this message translates to:
  /// **'Luteal'**
  String get cyA2GraphLuteal;

  /// No description provided for @cyA2GraphEstrogen.
  ///
  /// In en, this message translates to:
  /// **'Estrogen'**
  String get cyA2GraphEstrogen;

  /// No description provided for @cyA2GraphProgesterone.
  ///
  /// In en, this message translates to:
  /// **'Progesterone'**
  String get cyA2GraphProgesterone;

  /// No description provided for @cyA2GraphLH.
  ///
  /// In en, this message translates to:
  /// **'LH surge'**
  String get cyA2GraphLH;

  /// No description provided for @cyA2GraphCaption.
  ///
  /// In en, this message translates to:
  /// **'Estrogen peaks just before ovulation, the LH surge triggers egg release, then progesterone takes over for the luteal phase.'**
  String get cyA2GraphCaption;

  /// No description provided for @cyA3Title.
  ///
  /// In en, this message translates to:
  /// **'Hormones and Your Cycle'**
  String get cyA3Title;

  /// No description provided for @cyA3Sub.
  ///
  /// In en, this message translates to:
  /// **'What estrogen, progesterone, LH, and FSH actually do — and why they affect your entire life'**
  String get cyA3Sub;

  /// No description provided for @cyA3S1H.
  ///
  /// In en, this message translates to:
  /// **'Why hormones matter beyond reproduction'**
  String get cyA3S1H;

  /// No description provided for @cyA3S1P1.
  ///
  /// In en, this message translates to:
  /// **'Most people think of reproductive hormones as purely physical — they control your period, full stop. The reality is far more interesting. The hormones that drive your menstrual cycle are neuroactive steroids: they cross the blood-brain barrier, act directly on the brain, and shape your mood, memory, motivation, sleep, appetite, and pain sensitivity throughout the month.'**
  String get cyA3S1P1;

  /// No description provided for @cyA3S1P2.
  ///
  /// In en, this message translates to:
  /// **'The menstrual cycle is an intricate biological process governed by hormonal changes that affect different facets of the female reproductive system — but also broad effects on psychology, cognition, and emotional experience across each phase.'**
  String get cyA3S1P2;

  /// No description provided for @cyA3S1P3.
  ///
  /// In en, this message translates to:
  /// **'There are four primary hormones to understand. Two are produced in the brain. Two are produced in the ovaries. Together they form a continuous feedback loop that runs without stopping from your first period to your last.'**
  String get cyA3S1P3;

  /// No description provided for @cyA3S2H.
  ///
  /// In en, this message translates to:
  /// **'The hormonal command chain'**
  String get cyA3S2H;

  /// No description provided for @cyA3S2P1.
  ///
  /// In en, this message translates to:
  /// **'Before getting to the four main hormones, it helps to understand that the system has a clear hierarchy. It starts in the brain, not the ovaries.'**
  String get cyA3S2P1;

  /// No description provided for @cyA3S2P2.
  ///
  /// In en, this message translates to:
  /// **'Hormonal regulation begins in the hypothalamus, where gonadotropin-releasing hormone (GnRH) is secreted in a pulsatile fashion starting at puberty. GnRH is transported to the anterior pituitary, where it signals the pituitary gland to release follicle-stimulating hormone (FSH) and luteinizing hormone (LH). FSH and LH then travel through the bloodstream to the ovaries, stimulating the production of sex steroid hormones from follicular cells.'**
  String get cyA3S2P2;

  /// No description provided for @cyA3S2P3.
  ///
  /// In en, this message translates to:
  /// **'In plain terms: your brain sends a signal, which tells your pituitary gland to release two hormones, which travel to your ovaries, which produce estrogen and progesterone, which feed back to the brain to regulate the next signal. This loop repeats every cycle.'**
  String get cyA3S2P3;

  /// No description provided for @cyA3FshH.
  ///
  /// In en, this message translates to:
  /// **'Hormone 1 — FSH (Follicle-Stimulating Hormone)'**
  String get cyA3FshH;

  /// No description provided for @cyA3FshMeta.
  ///
  /// In en, this message translates to:
  /// **'Produced by: The pituitary gland, located at the base of the brain\nPrimary role: Stimulating egg development'**
  String get cyA3FshMeta;

  /// No description provided for @cyA3FshP1.
  ///
  /// In en, this message translates to:
  /// **'FSH\'s main function is to help regulate the menstrual cycle. Specifically, FSH stimulates follicles on the ovary to grow and prepare the eggs for ovulation. As the follicles increase in size, they begin to release estrogen and a low level of progesterone into the bloodstream.'**
  String get cyA3FshP1;

  /// No description provided for @cyA3FshP2.
  ///
  /// In en, this message translates to:
  /// **'FSH is highest at the very start of your cycle, when estrogen is at its lowest. This is the brain\'s response to the hormonal drop at the end of the previous cycle — it detects low estrogen and sends FSH to restart follicle development.'**
  String get cyA3FshP2;

  /// No description provided for @cyA3FshP3.
  ///
  /// In en, this message translates to:
  /// **'One follicle will soon begin to grow faster than the others. This is called the dominant follicle. As the follicle grows, blood levels of estrogen rise significantly by cycle day seven. This increase in estrogen begins to inhibit the secretion of FSH. The fall in FSH allows smaller follicles to die off — they are, in effect, starved of FSH.'**
  String get cyA3FshP3;

  /// No description provided for @cyA3FshL1.
  ///
  /// In en, this message translates to:
  /// **'FSH rises at the start of each cycle to kickstart follicle growth.'**
  String get cyA3FshL1;

  /// No description provided for @cyA3FshL2.
  ///
  /// In en, this message translates to:
  /// **'Only the strongest follicle survives the natural FSH drop — all others are reabsorbed.'**
  String get cyA3FshL2;

  /// No description provided for @cyA3FshL3.
  ///
  /// In en, this message translates to:
  /// **'FSH also induces the development of LH receptors within the dominant follicle, preparing it for the next step — ovulation.'**
  String get cyA3FshL3;

  /// No description provided for @cyA3FshL4.
  ///
  /// In en, this message translates to:
  /// **'Abnormally high FSH levels can indicate reduced ovarian reserve — something doctors check during fertility investigations.'**
  String get cyA3FshL4;

  /// No description provided for @cyA3LhH.
  ///
  /// In en, this message translates to:
  /// **'Hormone 2 — LH (Luteinizing Hormone)'**
  String get cyA3LhH;

  /// No description provided for @cyA3LhMeta.
  ///
  /// In en, this message translates to:
  /// **'Produced by: The pituitary gland\nPrimary role: Triggering ovulation and supporting the corpus luteum'**
  String get cyA3LhMeta;

  /// No description provided for @cyA3LhP1.
  ///
  /// In en, this message translates to:
  /// **'LH is the hormone responsible for the single most important event in the cycle: the release of the egg.'**
  String get cyA3LhP1;

  /// No description provided for @cyA3LhP2.
  ///
  /// In en, this message translates to:
  /// **'Levels of estrogen, particularly estradiol, increase exponentially in the late follicular phase. When high levels of estradiol trigger LH secretion by gonadotropes — a positive feedback mechanism — this results in a massive LH surge, usually over 36 to 48 hours.'**
  String get cyA3LhP2;

  /// No description provided for @cyA3LhP3.
  ///
  /// In en, this message translates to:
  /// **'The onset of the LH surge usually precedes ovulation by 36 hours. The peak of the LH surge precedes ovulation by 10 to 12 hours. The LH surge stimulates luteinization of the granulosa cells and stimulates the synthesis of progesterone.'**
  String get cyA3LhP3;

  /// No description provided for @cyA3LhP4.
  ///
  /// In en, this message translates to:
  /// **'This is why ovulation predictor kits (OPKs) work — they detect the LH surge in urine, giving you a 24 to 36 hour window of advance warning before ovulation occurs.'**
  String get cyA3LhP4;

  /// No description provided for @cyA3LhP5.
  ///
  /// In en, this message translates to:
  /// **'After ovulation, LH\'s role shifts. After ovulation, the ruptured follicle forms a corpus luteum — a temporary endocrine gland — that produces high levels of progesterone. Progesterone blocks the release of FSH and helps prepare the uterine lining.'**
  String get cyA3LhP5;

  /// No description provided for @cyA3LhL1.
  ///
  /// In en, this message translates to:
  /// **'The LH surge is the direct trigger for ovulation.'**
  String get cyA3LhL1;

  /// No description provided for @cyA3LhL2.
  ///
  /// In en, this message translates to:
  /// **'It can be detected in urine using OPK tests 24 to 36 hours before egg release.'**
  String get cyA3LhL2;

  /// No description provided for @cyA3LhL3.
  ///
  /// In en, this message translates to:
  /// **'After ovulation, LH maintains the corpus luteum and its progesterone production.'**
  String get cyA3LhL3;

  /// No description provided for @cyA3LhL4.
  ///
  /// In en, this message translates to:
  /// **'If no pregnancy occurs, LH drops, the corpus luteum dies, and the cycle resets.'**
  String get cyA3LhL4;

  /// No description provided for @cyA3EstH.
  ///
  /// In en, this message translates to:
  /// **'Hormone 3 — Estrogen (Estradiol)'**
  String get cyA3EstH;

  /// No description provided for @cyA3EstMeta.
  ///
  /// In en, this message translates to:
  /// **'Produced by: The ovarian follicles, and later the corpus luteum\nPrimary role: Building uterine lining and acting as a powerful brain modulator'**
  String get cyA3EstMeta;

  /// No description provided for @cyA3EstP1.
  ///
  /// In en, this message translates to:
  /// **'Estrogen is the hormone most people have heard of, but its effects are far broader than most people realise. It does not just prepare the uterus — it acts directly on the brain, influencing mood, cognition, and emotional regulation.'**
  String get cyA3EstP1;

  /// No description provided for @cyA3EstP2.
  ///
  /// In en, this message translates to:
  /// **'During the follicular phase, rising estrogen levels increase serotonin synthesis, enhancing mood, cognition, and pain tolerance. Estrogen may also influence dopamine levels, promoting motivation and reward sensitivity. GABA, involved in anxiety regulation, may be modulated by estrogen, inducing relaxation.'**
  String get cyA3EstP2;

  /// No description provided for @cyA3EstP3.
  ///
  /// In en, this message translates to:
  /// **'A landmark 2024 study published in Frontiers in Neuroscience confirmed that estradiol functions as a neuroactive steroid, playing a crucial role in modulating neurotransmitter systems affecting neuronal circuits and brain functions including learning, memory, reward, and social behaviour.'**
  String get cyA3EstP3;

  /// No description provided for @cyA3EstP4.
  ///
  /// In en, this message translates to:
  /// **'A separate study published in Nature Neuroscience in 2025 found that estrogen boosts dopamine-driven learning signals in the brain — providing a biological reason behind why motivation, focus, and mental clarity naturally ebb and flow throughout the month.'**
  String get cyA3EstP4;

  /// No description provided for @cyA3EstBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'What rising estrogen does to your body:'**
  String get cyA3EstBodyLabel;

  /// No description provided for @cyA3EstBody1.
  ///
  /// In en, this message translates to:
  /// **'Thickens and builds the uterine lining (endometrium).'**
  String get cyA3EstBody1;

  /// No description provided for @cyA3EstBody2.
  ///
  /// In en, this message translates to:
  /// **'Changes cervical mucus from thick and sticky to clear and stretchy.'**
  String get cyA3EstBody2;

  /// No description provided for @cyA3EstBody3.
  ///
  /// In en, this message translates to:
  /// **'Improves skin clarity in the follicular phase.'**
  String get cyA3EstBody3;

  /// No description provided for @cyA3EstBody4.
  ///
  /// In en, this message translates to:
  /// **'Increases bone density and cardiovascular protection over time.'**
  String get cyA3EstBody4;

  /// No description provided for @cyA3EstBrainLabel.
  ///
  /// In en, this message translates to:
  /// **'What rising estrogen does to your brain:'**
  String get cyA3EstBrainLabel;

  /// No description provided for @cyA3EstBrain1.
  ///
  /// In en, this message translates to:
  /// **'Boosts serotonin production — the neurotransmitter most associated with stable mood.'**
  String get cyA3EstBrain1;

  /// No description provided for @cyA3EstBrain2.
  ///
  /// In en, this message translates to:
  /// **'Increases dopamine sensitivity — driving motivation, confidence, and reward-seeking.'**
  String get cyA3EstBrain2;

  /// No description provided for @cyA3EstBrain3.
  ///
  /// In en, this message translates to:
  /// **'Enhances verbal memory, verbal fluency, and creative thinking.'**
  String get cyA3EstBrain3;

  /// No description provided for @cyA3EstBrain4.
  ///
  /// In en, this message translates to:
  /// **'Reduces anxiety through its modulation of GABA.'**
  String get cyA3EstBrain4;

  /// No description provided for @cyA3EstKey1.
  ///
  /// In en, this message translates to:
  /// **'Estrogen peaks twice: once just before ovulation (its highest point) and once mid-luteal phase.'**
  String get cyA3EstKey1;

  /// No description provided for @cyA3EstKey2.
  ///
  /// In en, this message translates to:
  /// **'The follicular phase energy and mood boost most people feel is directly caused by rising estrogen.'**
  String get cyA3EstKey2;

  /// No description provided for @cyA3EstKey3.
  ///
  /// In en, this message translates to:
  /// **'During the luteal phase, where estrogen levels are lower and progesterone levels are high, there is a corresponding decrease in serotonin levels — which is the neurobiological mechanism behind PMS mood symptoms.'**
  String get cyA3EstKey3;

  /// No description provided for @cyA3EstKey4.
  ///
  /// In en, this message translates to:
  /// **'Estrogen acts on over 300 different tissues in the body — it is not just a reproductive hormone.'**
  String get cyA3EstKey4;

  /// No description provided for @cyA3ProgH.
  ///
  /// In en, this message translates to:
  /// **'Hormone 4 — Progesterone'**
  String get cyA3ProgH;

  /// No description provided for @cyA3ProgMeta.
  ///
  /// In en, this message translates to:
  /// **'Produced by: The corpus luteum\nPrimary role: Maintaining uterine lining and producing most PMS symptoms'**
  String get cyA3ProgMeta;

  /// No description provided for @cyA3ProgP1.
  ///
  /// In en, this message translates to:
  /// **'Progesterone is the dominant hormone of the luteal phase and the hormone most responsible for the physical and emotional symptoms that most people associate with the days before their period.'**
  String get cyA3ProgP1;

  /// No description provided for @cyA3ProgP2.
  ///
  /// In en, this message translates to:
  /// **'After ovulation, the empty follicle transforms into the corpus luteum, which produces progesterone and some estrogen to support a potential pregnancy. The luteal phase is characterised by changes to hormone levels including a dramatic increase in progesterone, a decrease in FSH and LH, and changes to the endometrial lining.'**
  String get cyA3ProgP2;

  /// No description provided for @cyA3ProgP3.
  ///
  /// In en, this message translates to:
  /// **'Progesterone\'s effect on the brain is significant and often misunderstood. It does not simply cause bad moods — it acts on GABA receptors, the same receptors targeted by anti-anxiety medications. Progesterone and its metabolites interact with the GABAergic system, producing calming and sedating effects — which explains the fatigue and low motivation many people feel in the luteal phase.'**
  String get cyA3ProgP3;

  /// No description provided for @cyA3ProgP4.
  ///
  /// In en, this message translates to:
  /// **'The problem occurs at the end of the luteal phase, when both progesterone and estrogen drop sharply. A 2023 study published in Biological Psychiatry found an 18% change in serotonin transporter density in the midbrain between the periovulatory and premenstrual phase — directly correlating with the severity of depressed mood premenstrually.'**
  String get cyA3ProgP4;

  /// No description provided for @cyA3ProgBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'What progesterone does to your body:'**
  String get cyA3ProgBodyLabel;

  /// No description provided for @cyA3ProgBody1.
  ///
  /// In en, this message translates to:
  /// **'Maintains and matures the uterine lining for a possible pregnancy.'**
  String get cyA3ProgBody1;

  /// No description provided for @cyA3ProgBody2.
  ///
  /// In en, this message translates to:
  /// **'Increases basal body temperature slightly after ovulation.'**
  String get cyA3ProgBody2;

  /// No description provided for @cyA3ProgBody3.
  ///
  /// In en, this message translates to:
  /// **'Causes water retention and bloating.'**
  String get cyA3ProgBody3;

  /// No description provided for @cyA3ProgBody4.
  ///
  /// In en, this message translates to:
  /// **'Increases sebum production — often causing pre-period breakouts.'**
  String get cyA3ProgBody4;

  /// No description provided for @cyA3ProgBody5.
  ///
  /// In en, this message translates to:
  /// **'Raises appetite, particularly for carbohydrates and fats.'**
  String get cyA3ProgBody5;

  /// No description provided for @cyA3ProgBrainLabel.
  ///
  /// In en, this message translates to:
  /// **'What progesterone does to your brain:'**
  String get cyA3ProgBrainLabel;

  /// No description provided for @cyA3ProgBrain1.
  ///
  /// In en, this message translates to:
  /// **'Acts on GABA receptors, producing sedation and fatigue.'**
  String get cyA3ProgBrain1;

  /// No description provided for @cyA3ProgBrain2.
  ///
  /// In en, this message translates to:
  /// **'Reduces serotonin availability — contributing to low mood, irritability, and sensitivity.'**
  String get cyA3ProgBrain2;

  /// No description provided for @cyA3ProgBrain3.
  ///
  /// In en, this message translates to:
  /// **'Interacts with the dopaminergic system in complex ways — with varying effects on executive function.'**
  String get cyA3ProgBrain3;

  /// No description provided for @cyA3ProgBrain4.
  ///
  /// In en, this message translates to:
  /// **'Drives carbohydrate cravings through its influence on serotonin precursors.'**
  String get cyA3ProgBrain4;

  /// No description provided for @cyA3ProgKey1.
  ///
  /// In en, this message translates to:
  /// **'Progesterone is not the villain — it is doing its biological job correctly.'**
  String get cyA3ProgKey1;

  /// No description provided for @cyA3ProgKey2.
  ///
  /// In en, this message translates to:
  /// **'PMS symptoms are the result of your brain\'s sensitivity to progesterone\'s effects on neurotransmitters, not a hormonal imbalance per se.'**
  String get cyA3ProgKey2;

  /// No description provided for @cyA3ProgKey3.
  ///
  /// In en, this message translates to:
  /// **'The drop in progesterone at the end of the cycle is what triggers menstruation.'**
  String get cyA3ProgKey3;

  /// No description provided for @cyA3ProgKey4.
  ///
  /// In en, this message translates to:
  /// **'If the corpus luteum persists (due to pregnancy), progesterone stays high — this is why periods stop during pregnancy.'**
  String get cyA3ProgKey4;

  /// No description provided for @cyA3FbH.
  ///
  /// In en, this message translates to:
  /// **'How it all connects — the feedback loop'**
  String get cyA3FbH;

  /// No description provided for @cyA3FbP1.
  ///
  /// In en, this message translates to:
  /// **'The four hormones do not operate independently. They regulate each other through a continuous feedback system:'**
  String get cyA3FbP1;

  /// No description provided for @cyA3FbL1.
  ///
  /// In en, this message translates to:
  /// **'Low estrogen at cycle start → hypothalamus releases GnRH → pituitary releases FSH and LH.'**
  String get cyA3FbL1;

  /// No description provided for @cyA3FbL2.
  ///
  /// In en, this message translates to:
  /// **'FSH stimulates follicle growth → follicles produce estrogen → estrogen rises.'**
  String get cyA3FbL2;

  /// No description provided for @cyA3FbL3.
  ///
  /// In en, this message translates to:
  /// **'High estrogen triggers LH surge → LH triggers ovulation.'**
  String get cyA3FbL3;

  /// No description provided for @cyA3FbL4.
  ///
  /// In en, this message translates to:
  /// **'After ovulation, corpus luteum produces progesterone → progesterone and estrogen suppress FSH and LH.'**
  String get cyA3FbL4;

  /// No description provided for @cyA3FbL5.
  ///
  /// In en, this message translates to:
  /// **'If no pregnancy: corpus luteum breaks down → progesterone and estrogen drop → FSH begins rising again → cycle restarts.'**
  String get cyA3FbL5;

  /// No description provided for @cyA3FbP2.
  ///
  /// In en, this message translates to:
  /// **'Both estradiol and progesterone are secreted into the bloodstream and affect various tissues, including the uterus and pituitary gland. At the anterior pituitary, these hormones provide negative feedback, reducing the secretion of FSH and LH, which subsequently reduces their own production.'**
  String get cyA3FbP2;

  /// No description provided for @cyA3StressH.
  ///
  /// In en, this message translates to:
  /// **'Why stress, sleep, and food affect your hormones'**
  String get cyA3StressH;

  /// No description provided for @cyA3StressP1.
  ///
  /// In en, this message translates to:
  /// **'The hormonal command chain starts in the hypothalamus — and the hypothalamus is directly connected to the brain\'s stress response system. This is why life circumstances can directly disrupt your cycle.'**
  String get cyA3StressP1;

  /// No description provided for @cyA3StressP2.
  ///
  /// In en, this message translates to:
  /// **'Chronic stress and dysregulation of the HPA (hypothalamic-pituitary-adrenal) axis can lead to alterations in cortisol levels, which are linked to both menstrual disorders and mood disorders. Elevated cortisol can suppress the release of GnRH, interfering with FSH and LH production and disrupting the entire hormonal cascade.'**
  String get cyA3StressP2;

  /// No description provided for @cyA3StressP3.
  ///
  /// In en, this message translates to:
  /// **'The same mechanism explains why extreme caloric restriction, overtraining, illness, and significant weight changes can delay or stop ovulation — the hypothalamus detects physiological stress and downregulates the reproductive system as a protective response. Your body is not malfunctioning. It is prioritising survival.'**
  String get cyA3StressP3;

  /// No description provided for @cyA3DocH.
  ///
  /// In en, this message translates to:
  /// **'When should you talk to a doctor?'**
  String get cyA3DocH;

  /// No description provided for @cyA3DocL1.
  ///
  /// In en, this message translates to:
  /// **'You have severe mood symptoms in the 1 to 2 weeks before your period that significantly affect your daily life (possible PMDD).'**
  String get cyA3DocL1;

  /// No description provided for @cyA3DocL2.
  ///
  /// In en, this message translates to:
  /// **'Your periods are consistently absent.'**
  String get cyA3DocL2;

  /// No description provided for @cyA3DocL3.
  ///
  /// In en, this message translates to:
  /// **'You experience hot flashes, night sweats, or significant mood changes unrelated to your cycle.'**
  String get cyA3DocL3;

  /// No description provided for @cyA3DocL4.
  ///
  /// In en, this message translates to:
  /// **'You have been diagnosed with depression or anxiety and notice symptoms worsening significantly in the premenstrual phase.'**
  String get cyA3DocL4;

  /// No description provided for @cyA3GridTitle.
  ///
  /// In en, this message translates to:
  /// **'How hormones affect mood and cognition across the cycle'**
  String get cyA3GridTitle;

  /// No description provided for @cyA3GridMenstrual.
  ///
  /// In en, this message translates to:
  /// **'Menstrual'**
  String get cyA3GridMenstrual;

  /// No description provided for @cyA3GridFollicular.
  ///
  /// In en, this message translates to:
  /// **'Follicular'**
  String get cyA3GridFollicular;

  /// No description provided for @cyA3GridOvulation.
  ///
  /// In en, this message translates to:
  /// **'Ovulation'**
  String get cyA3GridOvulation;

  /// No description provided for @cyA3GridLuteal.
  ///
  /// In en, this message translates to:
  /// **'Luteal'**
  String get cyA3GridLuteal;

  /// No description provided for @cyA3GridEstrogenT.
  ///
  /// In en, this message translates to:
  /// **'Estrogen ↑'**
  String get cyA3GridEstrogenT;

  /// No description provided for @cyA3GridEst1.
  ///
  /// In en, this message translates to:
  /// **'↑ Serotonin synthesis'**
  String get cyA3GridEst1;

  /// No description provided for @cyA3GridEst2.
  ///
  /// In en, this message translates to:
  /// **'↑ Dopamine sensitivity'**
  String get cyA3GridEst2;

  /// No description provided for @cyA3GridEst3.
  ///
  /// In en, this message translates to:
  /// **'↑ Mood, memory, focus'**
  String get cyA3GridEst3;

  /// No description provided for @cyA3GridEst4.
  ///
  /// In en, this message translates to:
  /// **'↓ Anxiety via GABA'**
  String get cyA3GridEst4;

  /// No description provided for @cyA3GridProgesteroneT.
  ///
  /// In en, this message translates to:
  /// **'Progesterone ↑'**
  String get cyA3GridProgesteroneT;

  /// No description provided for @cyA3GridProg1.
  ///
  /// In en, this message translates to:
  /// **'↓ Serotonin availability'**
  String get cyA3GridProg1;

  /// No description provided for @cyA3GridProg2.
  ///
  /// In en, this message translates to:
  /// **'↑ GABA — sedating effect'**
  String get cyA3GridProg2;

  /// No description provided for @cyA3GridProg3.
  ///
  /// In en, this message translates to:
  /// **'↑ Bloating, fatigue'**
  String get cyA3GridProg3;

  /// No description provided for @cyA3GridProg4.
  ///
  /// In en, this message translates to:
  /// **'↑ Food cravings'**
  String get cyA3GridProg4;

  /// No description provided for @cyA3GridFshT.
  ///
  /// In en, this message translates to:
  /// **'FSH ↑'**
  String get cyA3GridFshT;

  /// No description provided for @cyA3GridFsh1.
  ///
  /// In en, this message translates to:
  /// **'↑ Follicle recruitment'**
  String get cyA3GridFsh1;

  /// No description provided for @cyA3GridFsh2.
  ///
  /// In en, this message translates to:
  /// **'↑ Estrogen production'**
  String get cyA3GridFsh2;

  /// No description provided for @cyA3GridFsh3.
  ///
  /// In en, this message translates to:
  /// **'Highest at cycle start'**
  String get cyA3GridFsh3;

  /// No description provided for @cyA3GridFsh4.
  ///
  /// In en, this message translates to:
  /// **'Falls as estrogen rises'**
  String get cyA3GridFsh4;

  /// No description provided for @cyA3GridLhT.
  ///
  /// In en, this message translates to:
  /// **'LH surge'**
  String get cyA3GridLhT;

  /// No description provided for @cyA3GridLh1.
  ///
  /// In en, this message translates to:
  /// **'→ Triggers ovulation'**
  String get cyA3GridLh1;

  /// No description provided for @cyA3GridLh2.
  ///
  /// In en, this message translates to:
  /// **'↑ Progesterone begins'**
  String get cyA3GridLh2;

  /// No description provided for @cyA3GridLh3.
  ///
  /// In en, this message translates to:
  /// **'Detectable in urine'**
  String get cyA3GridLh3;

  /// No description provided for @cyA3GridLh4.
  ///
  /// In en, this message translates to:
  /// **'Peaks ~10–12h pre-ovulation'**
  String get cyA3GridLh4;

  /// No description provided for @cyA4Title.
  ///
  /// In en, this message translates to:
  /// **'What Is Spotting and Why Does It Happen?'**
  String get cyA4Title;

  /// No description provided for @cyA4Sub.
  ///
  /// In en, this message translates to:
  /// **'Everything you need to know about bleeding between periods'**
  String get cyA4Sub;

  /// No description provided for @cyA4S1H.
  ///
  /// In en, this message translates to:
  /// **'What spotting actually is'**
  String get cyA4S1H;

  /// No description provided for @cyA4S1P1.
  ///
  /// In en, this message translates to:
  /// **'Spotting is light vaginal bleeding that occurs outside of your normal period. It is not a flow — it is small amounts of blood, often noticed only when wiping or as light staining on underwear. The colour is usually pink, light red, or brown rather than the bright or deep red of a typical period. It does not require a pad or tampon in most cases, only a panty liner at most.'**
  String get cyA4S1P1;

  /// No description provided for @cyA4S1P2.
  ///
  /// In en, this message translates to:
  /// **'Spotting is one of the most common and most misunderstood experiences in the menstrual cycle. It can feel alarming the first time it happens, but in the majority of cases it has a completely benign hormonal cause. Spotting, or light vaginal discharge, can be a totally normal part of the menstrual cycle.'**
  String get cyA4S1P2;

  /// No description provided for @cyA4S1P3.
  ///
  /// In en, this message translates to:
  /// **'Understanding the timing and context of spotting — specifically where you are in your cycle when it occurs — is the single most useful tool for interpreting what it means.'**
  String get cyA4S1P3;

  /// No description provided for @cyA4S2H.
  ///
  /// In en, this message translates to:
  /// **'Spotting vs. a period — the key differences'**
  String get cyA4S2H;

  /// No description provided for @cyA4S2P1.
  ///
  /// In en, this message translates to:
  /// **'Many people confuse spotting with the start of a light period. Here is how to tell them apart:'**
  String get cyA4S2P1;

  /// No description provided for @cyA4S2P2.
  ///
  /// In en, this message translates to:
  /// **'Spotting before your period may appear only when wiping or as a few drops on a panty liner. Menstrual bleeding, in contrast, lasts about 2 to 7 days and is continuous, often increasing in intensity before tapering off.'**
  String get cyA4S2P2;

  /// No description provided for @cyA4S3H.
  ///
  /// In en, this message translates to:
  /// **'The most common causes of spotting'**
  String get cyA4S3H;

  /// No description provided for @cyA4Sub1.
  ///
  /// In en, this message translates to:
  /// **'1. Ovulation spotting'**
  String get cyA4Sub1;

  /// No description provided for @cyA4Sub1P1.
  ///
  /// In en, this message translates to:
  /// **'Mid-cycle bleeding, which generally takes the form of light spotting, is most commonly associated with ovulation. In a BioCycle Study, approximately 5% of women self-reported mid-cycle bleeding during or around the time of expected ovulation. Since ovulation bleeding is relatively uncommon, and can occur randomly or infrequently, it can easily be mistaken as a sign of something else.'**
  String get cyA4Sub1P1;

  /// No description provided for @cyA4Sub1P2.
  ///
  /// In en, this message translates to:
  /// **'Changes in estrogen levels often cause this type of bleeding — some people refer to ovulation bleeding as estrogen breakthrough bleeding. Right before ovulation, estrogen rises sharply. Then immediately after the egg is released, estrogen drops suddenly while progesterone begins rising. This rapid hormonal shift can cause a small amount of the uterine lining to shed briefly, producing light spotting.'**
  String get cyA4Sub1P2;

  /// No description provided for @cyA4Sub1P3.
  ///
  /// In en, this message translates to:
  /// **'You tend to release eggs from alternating ovaries — your left one cycle and your right the next. Some people notice spotting when they\'re ovulating on one side but not the other, which is why it may show up every other cycle.'**
  String get cyA4Sub1P3;

  /// No description provided for @cyA4LooksLabel.
  ///
  /// In en, this message translates to:
  /// **'What it looks like:'**
  String get cyA4LooksLabel;

  /// No description provided for @cyA4Sub1L1.
  ///
  /// In en, this message translates to:
  /// **'Light pink or red, very small amount.'**
  String get cyA4Sub1L1;

  /// No description provided for @cyA4Sub1L2.
  ///
  /// In en, this message translates to:
  /// **'Lasts a few hours to 1–2 days maximum.'**
  String get cyA4Sub1L2;

  /// No description provided for @cyA4Sub1L3.
  ///
  /// In en, this message translates to:
  /// **'Occurs around the middle of your cycle — roughly days 11 to 16 in a 28-day cycle.'**
  String get cyA4Sub1L3;

  /// No description provided for @cyA4Sub1L4.
  ///
  /// In en, this message translates to:
  /// **'May be accompanied by mild one-sided pelvic cramping (mittelschmerz) and egg-white cervical mucus.'**
  String get cyA4Sub1L4;

  /// No description provided for @cyA4Sub2.
  ///
  /// In en, this message translates to:
  /// **'2. Pre-period spotting (late luteal spotting)'**
  String get cyA4Sub2;

  /// No description provided for @cyA4Sub2P1.
  ///
  /// In en, this message translates to:
  /// **'Some people experience light brown or pink spotting in the 1 to 3 days before their period properly begins. This is caused by progesterone dropping at the end of the luteal phase, which causes the uterine lining to begin breaking down before the full menstrual flow starts. It is considered normal when it lasts no more than 3 days and is followed by a normal period.'**
  String get cyA4Sub2P1;

  /// No description provided for @cyA4Sub3.
  ///
  /// In en, this message translates to:
  /// **'3. Hormonal fluctuations and anovulatory cycles'**
  String get cyA4Sub3;

  /// No description provided for @cyA4Sub3P1.
  ///
  /// In en, this message translates to:
  /// **'In cycles where ovulation does not occur — which is common in teenagers — the hormonal patterns are less predictable. Without the LH surge and subsequent progesterone rise, estrogen can fluctuate erratically, causing what is called estrogen breakthrough bleeding. This type of spotting is common in the first 2 to 3 years after your first period as the hormonal system matures.'**
  String get cyA4Sub3P1;

  /// No description provided for @cyA4Sub4.
  ///
  /// In en, this message translates to:
  /// **'4. Stress, illness, and significant lifestyle changes'**
  String get cyA4Sub4;

  /// No description provided for @cyA4Sub4P1.
  ///
  /// In en, this message translates to:
  /// **'The hypothalamus — the part of the brain that controls your hormonal cycle — is highly sensitive to psychological and physiological stress. Significant stress, illness, disrupted sleep, extreme exercise, or sudden weight changes can all disrupt hormonal signalling and cause mid-cycle spotting. This is one of the most common causes of unexplained spotting in teenagers.'**
  String get cyA4Sub4P1;

  /// No description provided for @cyA4Sub5.
  ///
  /// In en, this message translates to:
  /// **'5. Cervical ectropion'**
  String get cyA4Sub5;

  /// No description provided for @cyA4Sub5P1.
  ///
  /// In en, this message translates to:
  /// **'Cervical ectropion is a benign gynaecological condition regarded as a normal variant that frequently occurs in women of reproductive age. It occurs due to increased exposure of the cervical epithelium to estrogen.'**
  String get cyA4Sub5P1;

  /// No description provided for @cyA4Sub5P2.
  ///
  /// In en, this message translates to:
  /// **'In simple terms: cells that are normally found inside the cervical canal migrate to the outside of the cervix, where they are more fragile and prone to light bleeding — particularly after physical activity, sex, or even a cervical exam.'**
  String get cyA4Sub5P2;

  /// No description provided for @cyA4Sub5P3.
  ///
  /// In en, this message translates to:
  /// **'Ectropion is particularly common in adolescents, pregnant women, or those taking estrogen-containing contraceptives. Vaginal discharge is the most common symptom. Postcoital bleeding may also occur.'**
  String get cyA4Sub5P3;

  /// No description provided for @cyA4Sub5P4.
  ///
  /// In en, this message translates to:
  /// **'Importantly, cervical ectropion has no links to cervical cancer or cancer-causing health problems. It is a benign condition that often resolves on its own without any treatment.'**
  String get cyA4Sub5P4;

  /// No description provided for @cyA4S4H.
  ///
  /// In en, this message translates to:
  /// **'Less common but important causes'**
  String get cyA4S4H;

  /// No description provided for @cyA4Sub6.
  ///
  /// In en, this message translates to:
  /// **'Sexually transmitted infections (STIs)'**
  String get cyA4Sub6;

  /// No description provided for @cyA4Sub6P1.
  ///
  /// In en, this message translates to:
  /// **'Sexually transmitted infections such as gonorrhoea or chlamydia may cause the cervical tissue to become inflamed and bleed easily.'**
  String get cyA4Sub6P1;

  /// No description provided for @cyA4Sub6P2.
  ///
  /// In en, this message translates to:
  /// **'Chlamydia in particular is often completely symptomless — the only sign may be unexpected spotting or bleeding after sex. Cervical ectropion (19–34%), cervical or endometrial polyps (5–18%), and infection including vaginitis and cervicitis are common causes of irregular spotting in premenopausal patients.'**
  String get cyA4Sub6P2;

  /// No description provided for @cyA4Sub6P3.
  ///
  /// In en, this message translates to:
  /// **'This is one of the reasons why regular STI screening is recommended for sexually active teenagers — not because it assumes anything, but because chlamydia is the most commonly reported STI in the under-25 age group and is entirely treatable with a short course of antibiotics.'**
  String get cyA4Sub6P3;

  /// No description provided for @cyA4Sub7.
  ///
  /// In en, this message translates to:
  /// **'Cervical polyps'**
  String get cyA4Sub7;

  /// No description provided for @cyA4Sub7P1.
  ///
  /// In en, this message translates to:
  /// **'Cervical polyps are small growths that develop on the cervix. Most are benign but could cause bleeding after intercourse or between periods.'**
  String get cyA4Sub7P1;

  /// No description provided for @cyA4Sub7P2.
  ///
  /// In en, this message translates to:
  /// **'They are more common in older adults but can occasionally occur in teenagers. They are usually found incidentally during a pelvic examination and can be removed easily in a clinical setting.'**
  String get cyA4Sub7P2;

  /// No description provided for @cyA4Sub8.
  ///
  /// In en, this message translates to:
  /// **'Anovulatory cycles'**
  String get cyA4Sub8;

  /// No description provided for @cyA4Sub8P1.
  ///
  /// In en, this message translates to:
  /// **'In cycles where no egg is released, progesterone is not produced — because progesterone only comes from the corpus luteum that forms after ovulation. Without progesterone to stabilise the uterine lining, estrogen alone controls the endometrium, causing it to thicken unevenly and shed irregularly. This produces unpredictable spotting that does not follow a clear pattern.'**
  String get cyA4Sub8P1;

  /// No description provided for @cyA4S5H.
  ///
  /// In en, this message translates to:
  /// **'What colour is spotting and what does it mean?'**
  String get cyA4S5H;

  /// No description provided for @cyA4S5P1.
  ///
  /// In en, this message translates to:
  /// **'The colour of spotting carries information:'**
  String get cyA4S5P1;

  /// No description provided for @cyA4ColorPinkT.
  ///
  /// In en, this message translates to:
  /// **'Light pink'**
  String get cyA4ColorPinkT;

  /// No description provided for @cyA4ColorPinkB.
  ///
  /// In en, this message translates to:
  /// **'Fresh blood mixed with cervical mucus. Common with ovulation spotting or very early menstruation.'**
  String get cyA4ColorPinkB;

  /// No description provided for @cyA4ColorRedT.
  ///
  /// In en, this message translates to:
  /// **'Bright red'**
  String get cyA4ColorRedT;

  /// No description provided for @cyA4ColorRedB.
  ///
  /// In en, this message translates to:
  /// **'Fresh active bleeding. More associated with the start of a period or ovulation spotting during a heavy estrogen shift.'**
  String get cyA4ColorRedB;

  /// No description provided for @cyA4ColorBrownT.
  ///
  /// In en, this message translates to:
  /// **'Brown or rust'**
  String get cyA4ColorBrownT;

  /// No description provided for @cyA4ColorBrownB.
  ///
  /// In en, this message translates to:
  /// **'Older blood that has taken time to travel through the cervical canal. Very common with pre-period spotting, the end of a period, or post-ovulation spotting.'**
  String get cyA4ColorBrownB;

  /// No description provided for @cyA4ColorDarkT.
  ///
  /// In en, this message translates to:
  /// **'Dark brown or almost black'**
  String get cyA4ColorDarkT;

  /// No description provided for @cyA4ColorDarkB.
  ///
  /// In en, this message translates to:
  /// **'Very old blood, often from the tail end of a period or from blood that was briefly retained. Not inherently concerning on its own.'**
  String get cyA4ColorDarkB;

  /// No description provided for @cyA4S5K1.
  ///
  /// In en, this message translates to:
  /// **'Brown spotting is almost always old blood — not an emergency.'**
  String get cyA4S5K1;

  /// No description provided for @cyA4S5K2.
  ///
  /// In en, this message translates to:
  /// **'Pink spotting mid-cycle is one of the clearest signs of ovulation spotting.'**
  String get cyA4S5K2;

  /// No description provided for @cyA4S5K3.
  ///
  /// In en, this message translates to:
  /// **'Bright red bleeding outside of your period window is worth noting and monitoring.'**
  String get cyA4S5K3;

  /// No description provided for @cyA4S5K4.
  ///
  /// In en, this message translates to:
  /// **'Colour alone is not diagnostic — timing and context matter far more.'**
  String get cyA4S5K4;

  /// No description provided for @cyA4S6H.
  ///
  /// In en, this message translates to:
  /// **'Spotting that is almost always normal'**
  String get cyA4S6H;

  /// No description provided for @cyA4S6L1.
  ///
  /// In en, this message translates to:
  /// **'Light pink or brown spotting for 1–2 days around your expected ovulation window.'**
  String get cyA4S6L1;

  /// No description provided for @cyA4S6L2.
  ///
  /// In en, this message translates to:
  /// **'Brown spotting in the 1–3 days before your period begins.'**
  String get cyA4S6L2;

  /// No description provided for @cyA4S6L3.
  ///
  /// In en, this message translates to:
  /// **'Very light spotting in the first 1–2 days after your period ends.'**
  String get cyA4S6L3;

  /// No description provided for @cyA4S6L4.
  ///
  /// In en, this message translates to:
  /// **'Occasional mid-cycle spotting in the first 2–3 years after your first period.'**
  String get cyA4S6L4;

  /// No description provided for @cyA4S7H.
  ///
  /// In en, this message translates to:
  /// **'When should you talk to a doctor?'**
  String get cyA4S7H;

  /// No description provided for @cyA4S7P1.
  ///
  /// In en, this message translates to:
  /// **'Most spotting is harmless. But there are specific patterns that are worth getting checked:'**
  String get cyA4S7P1;

  /// No description provided for @cyA4S7L1.
  ///
  /// In en, this message translates to:
  /// **'Spotting that lasts more than 3 days outside of your period.'**
  String get cyA4S7L1;

  /// No description provided for @cyA4S7L2.
  ///
  /// In en, this message translates to:
  /// **'Spotting that occurs consistently after sex — this should always be investigated, even if it turns out to be something benign like cervical ectropion.'**
  String get cyA4S7L2;

  /// No description provided for @cyA4S7L3.
  ///
  /// In en, this message translates to:
  /// **'Spotting accompanied by pelvic pain, unusual discharge, or an unpleasant odour — these can be signs of an infection.'**
  String get cyA4S7L3;

  /// No description provided for @cyA4S7L4.
  ///
  /// In en, this message translates to:
  /// **'Spotting that is getting heavier over time rather than staying light.'**
  String get cyA4S7L4;

  /// No description provided for @cyA4S7L5.
  ///
  /// In en, this message translates to:
  /// **'Spotting that occurs in a completely unpredictable pattern with no connection to your cycle phases across several months.'**
  String get cyA4S7L5;

  /// No description provided for @cyA4S7P2.
  ///
  /// In en, this message translates to:
  /// **'Any abnormal bleeding that causes significant anxiety or concern — even if the clinical cause turns out to be benign — is a valid reason to seek a medical opinion. A 2023 study reported the prevalence of abnormal uterine bleeding assessed by self-perception was 31.4%'**
  String get cyA4S7P2;

  /// No description provided for @cyA4S7P3.
  ///
  /// In en, this message translates to:
  /// **'Meaning nearly one in three people who menstruate report some form of abnormal bleeding at some point. You are not being dramatic by asking a doctor about it.'**
  String get cyA4S7P3;

  /// No description provided for @cyA4S7P4.
  ///
  /// In en, this message translates to:
  /// **'A note on spotting after sex specifically: Cervical ectropion, cervical polyps, and infection are the most common causes of postcoital bleeding in premenopausal patients — the majority of which are benign and treatable.'**
  String get cyA4S7P4;

  /// No description provided for @cyA4S7P5.
  ///
  /// In en, this message translates to:
  /// **'Spotting after sex once is not necessarily cause for concern. Spotting after sex repeatedly is worth mentioning to a doctor, not because it is likely to be serious, but because it is easy to assess and easy to treat.'**
  String get cyA4S7P5;

  /// No description provided for @cyA4TblSpotting.
  ///
  /// In en, this message translates to:
  /// **'Spotting'**
  String get cyA4TblSpotting;

  /// No description provided for @cyA4TblPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get cyA4TblPeriod;

  /// No description provided for @cyA4TblVolumeF.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get cyA4TblVolumeF;

  /// No description provided for @cyA4TblVolumeS.
  ///
  /// In en, this message translates to:
  /// **'Very light — only requires a panty liner'**
  String get cyA4TblVolumeS;

  /// No description provided for @cyA4TblVolumeP.
  ///
  /// In en, this message translates to:
  /// **'Moderate to heavy — requires a pad or tampon'**
  String get cyA4TblVolumeP;

  /// No description provided for @cyA4TblColourF.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get cyA4TblColourF;

  /// No description provided for @cyA4TblColourS.
  ///
  /// In en, this message translates to:
  /// **'Light pink, brown, or rust'**
  String get cyA4TblColourS;

  /// No description provided for @cyA4TblColourP.
  ///
  /// In en, this message translates to:
  /// **'Bright red to deep red'**
  String get cyA4TblColourP;

  /// No description provided for @cyA4TblDurationF.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get cyA4TblDurationF;

  /// No description provided for @cyA4TblDurationS.
  ///
  /// In en, this message translates to:
  /// **'Hours to 1–2 days'**
  String get cyA4TblDurationS;

  /// No description provided for @cyA4TblDurationP.
  ///
  /// In en, this message translates to:
  /// **'3 to 7 days'**
  String get cyA4TblDurationP;

  /// No description provided for @cyA4TblClotsF.
  ///
  /// In en, this message translates to:
  /// **'Clots'**
  String get cyA4TblClotsF;

  /// No description provided for @cyA4TblClotsS.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get cyA4TblClotsS;

  /// No description provided for @cyA4TblClotsP.
  ///
  /// In en, this message translates to:
  /// **'Possible, especially on heavy days'**
  String get cyA4TblClotsP;

  /// No description provided for @cyA4TblTimingF.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get cyA4TblTimingF;

  /// No description provided for @cyA4TblTimingS.
  ///
  /// In en, this message translates to:
  /// **'Between periods, mid-cycle, or just before/after'**
  String get cyA4TblTimingS;

  /// No description provided for @cyA4TblTimingP.
  ///
  /// In en, this message translates to:
  /// **'Follows your regular cycle rhythm'**
  String get cyA4TblTimingP;

  /// No description provided for @cyA4TblCrampingF.
  ///
  /// In en, this message translates to:
  /// **'Cramping'**
  String get cyA4TblCrampingF;

  /// No description provided for @cyA4TblCrampingS.
  ///
  /// In en, this message translates to:
  /// **'Minimal or none'**
  String get cyA4TblCrampingS;

  /// No description provided for @cyA4TblCrampingP.
  ///
  /// In en, this message translates to:
  /// **'Common, especially day 1–2'**
  String get cyA4TblCrampingP;

  /// No description provided for @cyA5Title.
  ///
  /// In en, this message translates to:
  /// **'Things That Can Affect Your Cycle'**
  String get cyA5Title;

  /// No description provided for @cyA5Sub.
  ///
  /// In en, this message translates to:
  /// **'Why your period is one of the most accurate reflections of your overall health'**
  String get cyA5Sub;

  /// No description provided for @cyA5PracticeLabel.
  ///
  /// In en, this message translates to:
  /// **'What this looks like in practice:'**
  String get cyA5PracticeLabel;

  /// No description provided for @cyA5S1H.
  ///
  /// In en, this message translates to:
  /// **'Your cycle as a health barometer'**
  String get cyA5S1H;

  /// No description provided for @cyA5S1P1.
  ///
  /// In en, this message translates to:
  /// **'The American College of Obstetricians and Gynecologists (ACOG) officially designated the menstrual cycle as a vital sign in 2015 — placing it alongside blood pressure, heart rate, temperature, and respiratory rate as a core indicator of overall health. This is not symbolic. It reflects a clinical reality: your cycle responds to almost everything happening in your body and your life.'**
  String get cyA5S1P1;

  /// No description provided for @cyA5S1P2.
  ///
  /// In en, this message translates to:
  /// **'When your period is late, heavy, lighter than usual, or simply different from normal, it is almost never random. It is your body\'s hormonal system communicating that something has shifted — internally or externally. Understanding what can cause those shifts gives you the ability to interpret your cycle instead of just reacting to it.'**
  String get cyA5S1P2;

  /// No description provided for @cyA5S1P3.
  ///
  /// In en, this message translates to:
  /// **'The hormonal command chain that runs your cycle starts in the hypothalamus — a part of the brain that sits at the intersection of your nervous system, your endocrine system, and your stress response. Elevated cortisol levels suppress gonadotropin-releasing hormone (GnRH), leading to disrupted follicular development, anovulation, and alterations in cycle length. Psychological factors such as anxiety and depression further contribute to menstrual disturbances, while lifestyle factors — including poor sleep, diet, and excessive workload — exacerbate stress-related dysfunctions.'**
  String get cyA5S1P3;

  /// No description provided for @cyA5S1P4.
  ///
  /// In en, this message translates to:
  /// **'Everything in this article comes back to that one mechanism. Different inputs, same pathway.'**
  String get cyA5S1P4;

  /// No description provided for @cyA5StressH.
  ///
  /// In en, this message translates to:
  /// **'1. Stress'**
  String get cyA5StressH;

  /// No description provided for @cyA5StressP1.
  ///
  /// In en, this message translates to:
  /// **'Stress is the single most well-documented disruptor of the menstrual cycle, and for good reason — the biological pathway is direct and well understood.'**
  String get cyA5StressP1;

  /// No description provided for @cyA5StressP2.
  ///
  /// In en, this message translates to:
  /// **'Chronic stress can interfere with the hormones that regulate the menstrual cycle, specifically gonadotropin-releasing hormone (GnRH). This disruption can lead to irregular periods or even amenorrhea. Elevated cortisol can affect ovulation by suppressing the LH surge necessary for ovulation, leading to anovulatory cycles. Under stress, the body may also divert the precursors for progesterone to produce more cortisol — a phenomenon known as pregnenolone steal — which can further disrupt menstrual regularity.'**
  String get cyA5StressP2;

  /// No description provided for @cyA5StressP3.
  ///
  /// In en, this message translates to:
  /// **'The research in this area is robust. A 2023 study published in the Journal of Family Medicine and Primary Care, analysing 341 participants, found that women who experienced moderate to severe stress also experienced more PMS symptoms including mood swings, anger, fatigue, and depression — a finding that was statistically significant across both the luteal and menstrual phases.'**
  String get cyA5StressP3;

  /// No description provided for @cyA5StressP4.
  ///
  /// In en, this message translates to:
  /// **'A 2024 study following women in the aftermath of the 2023 earthquake in Turkey demonstrated just how powerfully acute stress can disrupt cycle patterns. Earthquake-related trauma and stress affected the nervous and endocrine system, leading to increased cortisol levels that disrupted hormonal balance by acting on the hypothalamic-pituitary-ovarian axis and inducing irregular menstrual cycles in a significant proportion of women studied.'**
  String get cyA5StressP4;

  /// No description provided for @cyA5StressP5.
  ///
  /// In en, this message translates to:
  /// **'You do not need to experience a disaster for this to apply to you. Exam periods, family difficulties, relationship stress, bereavement, and sustained academic pressure all activate the same biological pathway. The hypothalamus does not distinguish between a natural disaster and a set of final exams. It responds to perceived threat.'**
  String get cyA5StressP5;

  /// No description provided for @cyA5StressPr1.
  ///
  /// In en, this message translates to:
  /// **'Period arrives later than usual or skips entirely.'**
  String get cyA5StressPr1;

  /// No description provided for @cyA5StressPr2.
  ///
  /// In en, this message translates to:
  /// **'Cycle becomes shorter or longer than your normal pattern.'**
  String get cyA5StressPr2;

  /// No description provided for @cyA5StressPr3.
  ///
  /// In en, this message translates to:
  /// **'Flow becomes heavier or lighter than usual.'**
  String get cyA5StressPr3;

  /// No description provided for @cyA5StressPr4.
  ///
  /// In en, this message translates to:
  /// **'PMS symptoms intensify before the period.'**
  String get cyA5StressPr4;

  /// No description provided for @cyA5StressPr5.
  ///
  /// In en, this message translates to:
  /// **'Spotting mid-cycle during unusually high-stress periods.'**
  String get cyA5StressPr5;

  /// No description provided for @cyA5StressK1.
  ///
  /// In en, this message translates to:
  /// **'Short-term stress usually causes a one-cycle disruption — things return to normal once the stress resolves.'**
  String get cyA5StressK1;

  /// No description provided for @cyA5StressK2.
  ///
  /// In en, this message translates to:
  /// **'Chronic ongoing stress can cause sustained irregularity over multiple cycles.'**
  String get cyA5StressK2;

  /// No description provided for @cyA5StressK3.
  ///
  /// In en, this message translates to:
  /// **'The stress does not need to feel extreme to have a hormonal effect — sustained low-level stress (like academic pressure over weeks) is equally disruptive.'**
  String get cyA5StressK3;

  /// No description provided for @cyA5StressK4.
  ///
  /// In en, this message translates to:
  /// **'Stress management is not optional for cycle health — it is one of the most direct levers you have.'**
  String get cyA5StressK4;

  /// No description provided for @cyA5SleepH.
  ///
  /// In en, this message translates to:
  /// **'2. Sleep'**
  String get cyA5SleepH;

  /// No description provided for @cyA5SleepP1.
  ///
  /// In en, this message translates to:
  /// **'Sleep and the menstrual cycle are in a bidirectional relationship — each affects the other, and disruption in one reliably disrupts the other.'**
  String get cyA5SleepP1;

  /// No description provided for @cyA5SleepP2.
  ///
  /// In en, this message translates to:
  /// **'A population-based study of 801 Korean female adolescents found that sleeping five hours or less per night was significantly associated with increased risk of menstrual cycle irregularity compared to sleeping eight or more hours, even after adjusting for age, BMI, depressive mood, and other confounding variables. The odds of irregularity increased steadily as sleep duration decreased.'**
  String get cyA5SleepP2;

  /// No description provided for @cyA5SleepP3.
  ///
  /// In en, this message translates to:
  /// **'A systematic review published in BMC Women\'s Health in 2023, analysing multiple studies across different populations, confirmed the pattern: short sleep duration — typically defined as less than six hours — was consistently linked to abnormal menstrual cycle length and heavier bleeding during periods.'**
  String get cyA5SleepP3;

  /// No description provided for @cyA5SleepP4.
  ///
  /// In en, this message translates to:
  /// **'The mechanism works through cortisol and the reproductive hormones simultaneously. Increased stress hormone production derived from sleep loss can reduce the production of FSH and LH — two hormones essential to menstrual function. If sleep disturbances persist, this may lead to irregular or even missing periods, known as Functional Hypothalamic Amenorrhoea (FHA).'**
  String get cyA5SleepP4;

  /// No description provided for @cyA5SleepP5.
  ///
  /// In en, this message translates to:
  /// **'Women with less than 8 hours of sleep secrete 20% less FSH compared to women with longer sleep durations. FSH is the hormone that starts the follicle development process at the beginning of each cycle. Less FSH means slower, less reliable follicle development — which delays ovulation and therefore delays the period.'**
  String get cyA5SleepP5;

  /// No description provided for @cyA5SleepP6.
  ///
  /// In en, this message translates to:
  /// **'The relationship also runs in the other direction. Sleep is most commonly disrupted in the late luteal phase — the days before a period — when progesterone drops and body temperature remains elevated. Approximately 70% of women with PMDD experience sleep disturbances during this window.'**
  String get cyA5SleepP6;

  /// No description provided for @cyA5SleepPr1.
  ///
  /// In en, this message translates to:
  /// **'Consistently short sleep delays ovulation, which delays the period.'**
  String get cyA5SleepPr1;

  /// No description provided for @cyA5SleepPr2.
  ///
  /// In en, this message translates to:
  /// **'Poor sleep quality — even at normal duration — is associated with heavier bleeding.'**
  String get cyA5SleepPr2;

  /// No description provided for @cyA5SleepPr3.
  ///
  /// In en, this message translates to:
  /// **'Sleep disruption worsens PMS and PMDD symptoms.'**
  String get cyA5SleepPr3;

  /// No description provided for @cyA5SleepPr4.
  ///
  /// In en, this message translates to:
  /// **'Irregular sleep schedules (different bedtimes each night) are associated with more irregular cycles than simply sleeping less.'**
  String get cyA5SleepPr4;

  /// No description provided for @cyA5SleepK1.
  ///
  /// In en, this message translates to:
  /// **'The National Sleep Foundation recommends 8 to 10 hours of sleep for teenagers.'**
  String get cyA5SleepK1;

  /// No description provided for @cyA5SleepK2.
  ///
  /// In en, this message translates to:
  /// **'Going to bed and waking at consistent times matters as much as total duration.'**
  String get cyA5SleepK2;

  /// No description provided for @cyA5SleepK3.
  ///
  /// In en, this message translates to:
  /// **'Screen light (phones, laptops) suppresses melatonin and disrupts the hormonal signals that regulate both sleep and the cycle.'**
  String get cyA5SleepK3;

  /// No description provided for @cyA5SleepK4.
  ///
  /// In en, this message translates to:
  /// **'Improving sleep is one of the most accessible and evidence-supported interventions for cycle regularity.'**
  String get cyA5SleepK4;

  /// No description provided for @cyA5ExH.
  ///
  /// In en, this message translates to:
  /// **'3. Exercise'**
  String get cyA5ExH;

  /// No description provided for @cyA5ExP1.
  ///
  /// In en, this message translates to:
  /// **'Exercise has a dual relationship with the menstrual cycle that is worth understanding carefully — because the type and intensity matter enormously.'**
  String get cyA5ExP1;

  /// No description provided for @cyA5ExP2.
  ///
  /// In en, this message translates to:
  /// **'Moderate exercise is protective. Regular moderate physical activity reduces inflammation, improves insulin sensitivity, lowers cortisol, and supports the hormonal balance needed for regular ovulation. Multiple studies show that moderate exercise reduces PMS symptom severity, decreases menstrual pain, and is associated with more regular cycles.'**
  String get cyA5ExP2;

  /// No description provided for @cyA5ExP3.
  ///
  /// In en, this message translates to:
  /// **'Excessive exercise is disruptive. When exercise intensity or volume becomes too high — particularly when combined with insufficient caloric intake — the body interprets this as a physiological threat and begins to downregulate the reproductive system. This is the mechanism behind what is called the Female Athlete Triad: the combination of low energy availability, disrupted menstrual function, and reduced bone density that affects athletes who train very hard without eating enough.'**
  String get cyA5ExP3;

  /// No description provided for @cyA5ExP4.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle factors including excessive exercise exacerbate stress-related menstrual dysfunctions through the neuroendocrine pathway, contributing to elevated cortisol, suppressed GnRH, and anovulatory cycles.'**
  String get cyA5ExP4;

  /// No description provided for @cyA5ExP5.
  ///
  /// In en, this message translates to:
  /// **'The threshold is not fixed — it depends on your overall energy balance. Running 5km a day while eating adequately is unlikely to affect your cycle. Running 15km a day while significantly undereating can cause your period to disappear within weeks.'**
  String get cyA5ExP5;

  /// No description provided for @cyA5ExPr1.
  ///
  /// In en, this message translates to:
  /// **'Sudden dramatic increase in training intensity → delayed period or missed cycle.'**
  String get cyA5ExPr1;

  /// No description provided for @cyA5ExPr2.
  ///
  /// In en, this message translates to:
  /// **'Sustained intense training combined with low caloric intake → cycle stops (amenorrhea).'**
  String get cyA5ExPr2;

  /// No description provided for @cyA5ExPr3.
  ///
  /// In en, this message translates to:
  /// **'Starting or resuming regular moderate exercise → cycle may become more regular over time.'**
  String get cyA5ExPr3;

  /// No description provided for @cyA5ExPr4.
  ///
  /// In en, this message translates to:
  /// **'Reducing training after a heavy athletic season → period returns within 1 to 3 cycles.'**
  String get cyA5ExPr4;

  /// No description provided for @cyA5ExK1.
  ///
  /// In en, this message translates to:
  /// **'The key variable is energy availability, not exercise volume alone.'**
  String get cyA5ExK1;

  /// No description provided for @cyA5ExK2.
  ///
  /// In en, this message translates to:
  /// **'Dance, gymnastics, distance running, and rowing carry the highest risk due to combining high output with aesthetic body pressures.'**
  String get cyA5ExK2;

  /// No description provided for @cyA5ExK3.
  ///
  /// In en, this message translates to:
  /// **'Losing your period due to exercise is not normal and is not a sign of fitness — it is a sign of physiological stress.'**
  String get cyA5ExK3;

  /// No description provided for @cyA5ExK4.
  ///
  /// In en, this message translates to:
  /// **'Bone density loss from exercise-related amenorrhea can be permanent if not addressed.'**
  String get cyA5ExK4;

  /// No description provided for @cyA5DietH.
  ///
  /// In en, this message translates to:
  /// **'4. Diet and nutrition'**
  String get cyA5DietH;

  /// No description provided for @cyA5DietP1.
  ///
  /// In en, this message translates to:
  /// **'What you eat affects your hormones more directly than most people realise. The menstrual cycle requires adequate energy, fat, and specific micronutrients to function. When any of these are deficient, the reproductive system is one of the first systems to be downregulated.'**
  String get cyA5DietP1;

  /// No description provided for @cyA5DietB1T.
  ///
  /// In en, this message translates to:
  /// **'Caloric restriction and low body weight'**
  String get cyA5DietB1T;

  /// No description provided for @cyA5DietB1B.
  ///
  /// In en, this message translates to:
  /// **'The hypothalamus monitors body fat levels through hormones including leptin. When body fat drops too low — from restrictive eating, rapid weight loss, or eating disorders — leptin falls, and the hypothalamus reduces GnRH production, effectively pausing the cycle. This is the same mechanism as exercise-related amenorrhea.'**
  String get cyA5DietB1B;

  /// No description provided for @cyA5MicroLabel.
  ///
  /// In en, this message translates to:
  /// **'Specific micronutrients that matter:'**
  String get cyA5MicroLabel;

  /// No description provided for @cyA5Micro1.
  ///
  /// In en, this message translates to:
  /// **'Iron — heavy periods deplete iron rapidly. Iron deficiency causes fatigue, brain fog, and dizziness.'**
  String get cyA5Micro1;

  /// No description provided for @cyA5Micro2.
  ///
  /// In en, this message translates to:
  /// **'Magnesium — low magnesium is associated with more severe PMS symptoms, particularly cramping and mood changes.'**
  String get cyA5Micro2;

  /// No description provided for @cyA5Micro3.
  ///
  /// In en, this message translates to:
  /// **'Omega-3 fatty acids — anti-inflammatory. Research consistently shows omega-3 supplementation reduces menstrual pain severity.'**
  String get cyA5Micro3;

  /// No description provided for @cyA5Micro4.
  ///
  /// In en, this message translates to:
  /// **'Vitamin D — low vitamin D is associated with more irregular cycles and more severe dysmenorrhoea.'**
  String get cyA5Micro4;

  /// No description provided for @cyA5Micro5.
  ///
  /// In en, this message translates to:
  /// **'Zinc — involved in progesterone production and immune function. Low zinc is linked to more severe PMS.'**
  String get cyA5Micro5;

  /// No description provided for @cyA5DietB2T.
  ///
  /// In en, this message translates to:
  /// **'Ultra-processed food and blood sugar'**
  String get cyA5DietB2T;

  /// No description provided for @cyA5DietB2B.
  ///
  /// In en, this message translates to:
  /// **'Diets high in refined carbohydrates and ultra-processed foods cause rapid spikes and crashes in blood sugar, which trigger cortisol release. A 2023 study found that dietary patterns characterised by high processed food intake were independently associated with more irregular cycles and more severe menstrual symptoms in adolescents.'**
  String get cyA5DietB2B;

  /// No description provided for @cyA5DietK1.
  ///
  /// In en, this message translates to:
  /// **'You do not need to eat a perfect diet for a regular cycle — but extreme restriction is harmful.'**
  String get cyA5DietK1;

  /// No description provided for @cyA5DietK2.
  ///
  /// In en, this message translates to:
  /// **'Eating enough fat is specifically important — steroid hormones including estrogen and progesterone are made from cholesterol.'**
  String get cyA5DietK2;

  /// No description provided for @cyA5DietK3.
  ///
  /// In en, this message translates to:
  /// **'Crash diets and cleanses are among the fastest ways to disrupt your cycle.'**
  String get cyA5DietK3;

  /// No description provided for @cyA5DietK4.
  ///
  /// In en, this message translates to:
  /// **'If you suspect your diet is affecting your cycle, a blood test checking iron, vitamin D, and ferritin levels is a reasonable starting point.'**
  String get cyA5DietK4;

  /// No description provided for @cyA5TravelH.
  ///
  /// In en, this message translates to:
  /// **'5. Travel and jet lag'**
  String get cyA5TravelH;

  /// No description provided for @cyA5TravelP1.
  ///
  /// In en, this message translates to:
  /// **'Travel disrupts the menstrual cycle through a specific and well-understood mechanism: circadian rhythm disruption.'**
  String get cyA5TravelP1;

  /// No description provided for @cyA5TravelP2.
  ///
  /// In en, this message translates to:
  /// **'Your menstrual cycle is regulated by the hypothalamus, which is deeply integrated with your circadian clock — the 24-hour biological timing system that controls sleep, hormone release, digestion, and body temperature. When your circadian rhythm gets disrupted, the timing and amount of GnRH, FSH, and LH releases can change, potentially delaying ovulation or altering your cycle length. Jet lag goes beyond feeling tired after a flight — it affects multiple body systems simultaneously including sleep-wake cycles, digestion, mood, immune function, and reproductive hormones.'**
  String get cyA5TravelP2;

  /// No description provided for @cyA5TravelP3.
  ///
  /// In en, this message translates to:
  /// **'Research shows that how long jet lag can delay your period typically ranges from 3 to 7 days, though some people experience longer delays. Eastward travel disrupts circadian rhythms more severely than westward travel — eastward jet lag can last over twice as long because shortening your day feels harder than lengthening one.'**
  String get cyA5TravelP3;

  /// No description provided for @cyA5TravelP4.
  ///
  /// In en, this message translates to:
  /// **'A study published in PubMed on social jet lag — the mismatch between your body clock and your daily schedule, even without actual travel — found that students with larger social jet lag of 1 hour or more experienced more severe menstrual symptoms including pain, behavioural changes, and water retention, compared to those with smaller social jet lag.'**
  String get cyA5TravelP4;

  /// No description provided for @cyA5TravelP5.
  ///
  /// In en, this message translates to:
  /// **'This means that simply having irregular sleep and wake times across the week — staying up late on weekends and waking early on weekdays — can affect your cycle.'**
  String get cyA5TravelP5;

  /// No description provided for @cyA5TravelPr1.
  ///
  /// In en, this message translates to:
  /// **'Period arrives 3 to 7 days later than expected after a long-haul flight.'**
  String get cyA5TravelPr1;

  /// No description provided for @cyA5TravelPr2.
  ///
  /// In en, this message translates to:
  /// **'Period arrives earlier than expected in some cases — the circadian disruption can push ovulation in either direction.'**
  String get cyA5TravelPr2;

  /// No description provided for @cyA5TravelPr3.
  ///
  /// In en, this message translates to:
  /// **'Flow may be heavier or lighter than usual for one cycle after significant travel.'**
  String get cyA5TravelPr3;

  /// No description provided for @cyA5TravelPr4.
  ///
  /// In en, this message translates to:
  /// **'Things usually return to normal within one to two cycles.'**
  String get cyA5TravelPr4;

  /// No description provided for @cyA5TravelK1.
  ///
  /// In en, this message translates to:
  /// **'The disruption is almost always temporary — one to two cycles.'**
  String get cyA5TravelK1;

  /// No description provided for @cyA5TravelK2.
  ///
  /// In en, this message translates to:
  /// **'Eastward travel (e.g. flying from Europe to Asia) causes more disruption than westward.'**
  String get cyA5TravelK2;

  /// No description provided for @cyA5TravelK3.
  ///
  /// In en, this message translates to:
  /// **'The stress and sleep disruption of travel compound the effect — it is rarely just one mechanism.'**
  String get cyA5TravelK3;

  /// No description provided for @cyA5TravelK4.
  ///
  /// In en, this message translates to:
  /// **'Staying hydrated, keeping to your home time zone for the first 24 hours where possible, and getting morning light exposure in the new time zone all help speed up circadian resynchronisation.'**
  String get cyA5TravelK4;

  /// No description provided for @cyA5IllH.
  ///
  /// In en, this message translates to:
  /// **'6. Illness and fever'**
  String get cyA5IllH;

  /// No description provided for @cyA5IllP1.
  ///
  /// In en, this message translates to:
  /// **'Illness disrupts the cycle through two overlapping pathways: the immune-inflammatory response and the stress response. Both activate cortisol and inflammatory cytokines that suppress GnRH and disrupt ovulation.'**
  String get cyA5IllP1;

  /// No description provided for @cyA5IllP2.
  ///
  /// In en, this message translates to:
  /// **'Fever specifically has a direct effect on the timing of ovulation. Elevated body temperature interferes with the precise hormonal timing required for the LH surge. A fever during the follicular phase — particularly in the week before expected ovulation — can delay ovulation by several days, pushing the period back by the same amount.'**
  String get cyA5IllP2;

  /// No description provided for @cyA5IllP3.
  ///
  /// In en, this message translates to:
  /// **'Common viral illnesses including influenza, COVID-19, and other febrile infections have all been associated with cycle disruption in research. A delayed or skipped period after a significant illness is extremely common and almost always resolves in the following cycle.'**
  String get cyA5IllP3;

  /// No description provided for @cyA5IllK1.
  ///
  /// In en, this message translates to:
  /// **'One disrupted cycle after illness is completely normal and expected.'**
  String get cyA5IllK1;

  /// No description provided for @cyA5IllK2.
  ///
  /// In en, this message translates to:
  /// **'The more severe the illness and the longer it lasted, the more disruption to expect.'**
  String get cyA5IllK2;

  /// No description provided for @cyA5IllK3.
  ///
  /// In en, this message translates to:
  /// **'COVID-19 specifically has been associated with cycle changes in multiple studies — both short-term disruption and, in some cases, longer-term changes.'**
  String get cyA5IllK3;

  /// No description provided for @cyA5IllK4.
  ///
  /// In en, this message translates to:
  /// **'If your cycle does not return to normal within two cycles after recovering from illness, mention it to a doctor.'**
  String get cyA5IllK4;

  /// No description provided for @cyA5MedH.
  ///
  /// In en, this message translates to:
  /// **'7. Medications'**
  String get cyA5MedH;

  /// No description provided for @cyA5MedP1.
  ///
  /// In en, this message translates to:
  /// **'Several categories of medication can affect the menstrual cycle either directly or indirectly:'**
  String get cyA5MedP1;

  /// No description provided for @cyA5MedB1T.
  ///
  /// In en, this message translates to:
  /// **'Hormonal contraceptives'**
  String get cyA5MedB1T;

  /// No description provided for @cyA5MedB1B.
  ///
  /// In en, this message translates to:
  /// **'By design, these override the natural hormonal cycle. After stopping hormonal contraception, it can take 1 to 3 months for natural cycles to resume, though this varies significantly by person and by the type of contraception used.'**
  String get cyA5MedB1B;

  /// No description provided for @cyA5MedB2T.
  ///
  /// In en, this message translates to:
  /// **'Antidepressants and antipsychotics'**
  String get cyA5MedB2T;

  /// No description provided for @cyA5MedB2B.
  ///
  /// In en, this message translates to:
  /// **'Some medications in these classes, particularly those that raise prolactin levels, can suppress ovulation and affect cycle regularity. If you have started a new psychiatric medication and notice cycle changes, mention it to your prescribing doctor.'**
  String get cyA5MedB2B;

  /// No description provided for @cyA5MedB3T.
  ///
  /// In en, this message translates to:
  /// **'Corticosteroids'**
  String get cyA5MedB3T;

  /// No description provided for @cyA5MedB3B.
  ///
  /// In en, this message translates to:
  /// **'Anti-inflammatory steroids used for conditions like asthma or eczema can affect cortisol balance and temporarily disrupt cycles with prolonged use.'**
  String get cyA5MedB3B;

  /// No description provided for @cyA5MedB4T.
  ///
  /// In en, this message translates to:
  /// **'Chemotherapy'**
  String get cyA5MedB4T;

  /// No description provided for @cyA5MedB4B.
  ///
  /// In en, this message translates to:
  /// **'Can temporarily or permanently disrupt cycle function depending on the type and duration.'**
  String get cyA5MedB4B;

  /// No description provided for @cyA5MedB5T.
  ///
  /// In en, this message translates to:
  /// **'Non-prescription'**
  String get cyA5MedB5T;

  /// No description provided for @cyA5MedB5B.
  ///
  /// In en, this message translates to:
  /// **'High doses of vitamin C, certain herbal supplements (particularly those marketed for \"hormonal balance\"), and significant changes in caffeine intake have all been anecdotally associated with cycle changes, though the research evidence is variable.'**
  String get cyA5MedB5B;

  /// No description provided for @cyA5MedK1.
  ///
  /// In en, this message translates to:
  /// **'Always mention cycle changes to your doctor when starting a new medication.'**
  String get cyA5MedK1;

  /// No description provided for @cyA5MedK2.
  ///
  /// In en, this message translates to:
  /// **'Never stop a prescribed medication because of cycle changes without speaking to your doctor first.'**
  String get cyA5MedK2;

  /// No description provided for @cyA5MedK3.
  ///
  /// In en, this message translates to:
  /// **'The interaction between medications and cycle function is under-researched — your experience is valid even if your doctor is not immediately familiar with the connection.'**
  String get cyA5MedK3;

  /// No description provided for @cyA5DocH.
  ///
  /// In en, this message translates to:
  /// **'When should you talk to a doctor?'**
  String get cyA5DocH;

  /// No description provided for @cyA5DocP1.
  ///
  /// In en, this message translates to:
  /// **'Most cycle disruptions caused by lifestyle factors resolve on their own within one to two cycles once the cause is addressed. However, speak to a doctor if:'**
  String get cyA5DocP1;

  /// No description provided for @cyA5DocL1.
  ///
  /// In en, this message translates to:
  /// **'Your period has been absent for 3 or more consecutive cycles.'**
  String get cyA5DocL1;

  /// No description provided for @cyA5DocL2.
  ///
  /// In en, this message translates to:
  /// **'Your cycle has been consistently irregular for more than 6 months with no identifiable lifestyle cause.'**
  String get cyA5DocL2;

  /// No description provided for @cyA5DocL3.
  ///
  /// In en, this message translates to:
  /// **'You have lost your period in the context of intense exercise and low food intake — bone density loss begins quickly and is partially irreversible.'**
  String get cyA5DocL3;

  /// No description provided for @cyA5DocL4.
  ///
  /// In en, this message translates to:
  /// **'You are experiencing significant fatigue, dizziness, or breathlessness during your period — this can indicate iron deficiency anaemia from heavy bleeding.'**
  String get cyA5DocL4;

  /// No description provided for @cyA5DocL5.
  ///
  /// In en, this message translates to:
  /// **'A new medication has caused your cycle to change significantly and the change is affecting your quality of life.'**
  String get cyA5DocL5;

  /// No description provided for @cyA5DocL6.
  ///
  /// In en, this message translates to:
  /// **'You are experiencing severe mood symptoms in the premenstrual phase that are affecting your daily functioning — this is treatable.'**
  String get cyA5DocL6;

  /// No description provided for @cyA5ChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Relative strength of evidence linking lifestyle factors to cycle disruption'**
  String get cyA5ChartTitle;

  /// No description provided for @cyA5ChartSub.
  ///
  /// In en, this message translates to:
  /// **'Based on systematic reviews and meta-analyses 2020–2024'**
  String get cyA5ChartSub;

  /// No description provided for @cyA5ChartLStress.
  ///
  /// In en, this message translates to:
  /// **'Chronic stress'**
  String get cyA5ChartLStress;

  /// No description provided for @cyA5ChartLSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep <6hrs'**
  String get cyA5ChartLSleep;

  /// No description provided for @cyA5ChartLLowWt.
  ///
  /// In en, this message translates to:
  /// **'Low body wt.'**
  String get cyA5ChartLLowWt;

  /// No description provided for @cyA5ChartLOverEx.
  ///
  /// In en, this message translates to:
  /// **'Over-exercise'**
  String get cyA5ChartLOverEx;

  /// No description provided for @cyA5ChartLIllness.
  ///
  /// In en, this message translates to:
  /// **'Illness / fever'**
  String get cyA5ChartLIllness;

  /// No description provided for @cyA5ChartLTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel / jet lag'**
  String get cyA5ChartLTravel;

  /// No description provided for @cyA5ChartLDiet.
  ///
  /// In en, this message translates to:
  /// **'Poor diet'**
  String get cyA5ChartLDiet;

  /// No description provided for @cyA5ChartLMildEx.
  ///
  /// In en, this message translates to:
  /// **'Mild exercise'**
  String get cyA5ChartLMildEx;

  /// No description provided for @cyA5StrVeryStrong.
  ///
  /// In en, this message translates to:
  /// **'Very strong'**
  String get cyA5StrVeryStrong;

  /// No description provided for @cyA5StrStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get cyA5StrStrong;

  /// No description provided for @cyA5StrModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get cyA5StrModerate;

  /// No description provided for @cyA5StrEmerging.
  ///
  /// In en, this message translates to:
  /// **'Emerging'**
  String get cyA5StrEmerging;

  /// No description provided for @cyA5StrProtective.
  ///
  /// In en, this message translates to:
  /// **'Protective'**
  String get cyA5StrProtective;

  /// No description provided for @cyA5ChartCaption.
  ///
  /// In en, this message translates to:
  /// **'Stress and sleep have the strongest and most consistent evidence base. Exercise is the only factor that can be protective rather than disruptive — but only at moderate intensity.'**
  String get cyA5ChartCaption;

  /// No description provided for @cyA6Title.
  ///
  /// In en, this message translates to:
  /// **'How to Track Your Cycle and Why It Matters'**
  String get cyA6Title;

  /// No description provided for @cyA6Sub.
  ///
  /// In en, this message translates to:
  /// **'What your data is really telling you — and how to use it'**
  String get cyA6Sub;

  /// No description provided for @cyA6S1H.
  ///
  /// In en, this message translates to:
  /// **'Tracking is not about predicting your period'**
  String get cyA6S1H;

  /// No description provided for @cyA6S1P1.
  ///
  /// In en, this message translates to:
  /// **'Most people start tracking their cycle for one reason: to know when their period is coming. That is a completely valid reason. But it is also the least interesting thing your cycle data can tell you.'**
  String get cyA6S1P1;

  /// No description provided for @cyA6S1P2.
  ///
  /// In en, this message translates to:
  /// **'When you track consistently over time, you build something far more valuable than a prediction. You build a personal health baseline — a record of what is normal for your body specifically, not what is average for a population. That baseline becomes one of the most useful tools you can have in any healthcare conversation, at any age.'**
  String get cyA6S1P2;

  /// No description provided for @cyA6S1P3.
  ///
  /// In en, this message translates to:
  /// **'Timely self-monitoring of menstrual health is valuable as it provides insight and self-awareness of one\'s general health and how one\'s body responds to different phases of the cycle — insight that can directly inform conversations with healthcare providers.'**
  String get cyA6S1P3;

  /// No description provided for @cyA6S1P4.
  ///
  /// In en, this message translates to:
  /// **'Period tracker apps empower people by helping them gain a better understanding of their bodies, ultimately enhancing their social, academic, and health-related lives.'**
  String get cyA6S1P4;

  /// No description provided for @cyA6S1P5.
  ///
  /// In en, this message translates to:
  /// **'A 2024 mixed methods study published in the Journal of Medical Internet Research, surveying Gen Z and millennial users, found that the primary reported benefit of cycle tracking was not period prediction — it was body literacy: understanding why they felt the way they felt at different points in the month.'**
  String get cyA6S1P5;

  /// No description provided for @cyA6S1P6.
  ///
  /// In en, this message translates to:
  /// **'This article covers what each piece of data you log actually reveals, why starting early matters more than most people realise, and how to turn your tracked data into something a doctor can actually use.'**
  String get cyA6S1P6;

  /// No description provided for @cyA6FlowH.
  ///
  /// In en, this message translates to:
  /// **'What your flow data reveals'**
  String get cyA6FlowH;

  /// No description provided for @cyA6FlowP1.
  ///
  /// In en, this message translates to:
  /// **'Flow level is the most basic thing you can track and the first thing most doctors ask about. But it tells you more than just \"heavy\" or \"light.\"'**
  String get cyA6FlowP1;

  /// No description provided for @cyA6FlowPatternsLabel.
  ///
  /// In en, this message translates to:
  /// **'Patterns over time:'**
  String get cyA6FlowPatternsLabel;

  /// No description provided for @cyA6FlowPat1.
  ///
  /// In en, this message translates to:
  /// **'Consistently light flow can indicate low estrogen or a thin uterine lining — sometimes caused by hormonal imbalances or certain medications.'**
  String get cyA6FlowPat1;

  /// No description provided for @cyA6FlowPat2.
  ///
  /// In en, this message translates to:
  /// **'Consistently heavy flow is one of the primary indicators of conditions like endometriosis, fibroids, or a bleeding disorder — conditions that are significantly underdiagnosed, in part because people assume heavy periods are just normal for them.'**
  String get cyA6FlowPat2;

  /// No description provided for @cyA6FlowPat3.
  ///
  /// In en, this message translates to:
  /// **'Flow that gets progressively heavier over several cycles is more clinically significant than a single heavy cycle.'**
  String get cyA6FlowPat3;

  /// No description provided for @cyA6FlowResearchLabel.
  ///
  /// In en, this message translates to:
  /// **'What the research shows:'**
  String get cyA6FlowResearchLabel;

  /// No description provided for @cyA6FlowResP1.
  ///
  /// In en, this message translates to:
  /// **'The Apple Women\'s Health Study found that the most frequently tracked symptoms were abdominal cramps, bloating, and tiredness — all experienced by more than 60 percent of participants who logged symptoms. More than half reported acne and headaches. Notably, less widely recognised symptoms like diarrhoea and sleep changes were also tracked by 37 percent of participants.'**
  String get cyA6FlowResP1;

  /// No description provided for @cyA6FlowResP2.
  ///
  /// In en, this message translates to:
  /// **'Many of these people had normalised these symptoms for years. Tracking made the pattern visible.'**
  String get cyA6FlowResP2;

  /// No description provided for @cyA6FlowK1.
  ///
  /// In en, this message translates to:
  /// **'Log flow every day of your period, not just the first day.'**
  String get cyA6FlowK1;

  /// No description provided for @cyA6FlowK2.
  ///
  /// In en, this message translates to:
  /// **'Note the difference between heavy days and very heavy days — this distinction matters clinically.'**
  String get cyA6FlowK2;

  /// No description provided for @cyA6FlowK3.
  ///
  /// In en, this message translates to:
  /// **'Changes in your personal flow pattern are more significant than absolute volume — a change from your normal is the signal.'**
  String get cyA6FlowK3;

  /// No description provided for @cyA6FlowK4.
  ///
  /// In en, this message translates to:
  /// **'If you are consistently soaking through protection in under 2 hours, this warrants medical attention regardless of what you have been told is \"normal\" for your family.'**
  String get cyA6FlowK4;

  /// No description provided for @cyA6SympH.
  ///
  /// In en, this message translates to:
  /// **'What your symptom data reveals'**
  String get cyA6SympH;

  /// No description provided for @cyA6SympP1.
  ///
  /// In en, this message translates to:
  /// **'Symptoms logged over multiple cycles reveal patterns that are completely invisible in a single cycle.'**
  String get cyA6SympP1;

  /// No description provided for @cyA6SympCrampsT.
  ///
  /// In en, this message translates to:
  /// **'Cramps'**
  String get cyA6SympCrampsT;

  /// No description provided for @cyA6SympCrampsB.
  ///
  /// In en, this message translates to:
  /// **'Mild cramping on day 1–2 is normal. Cramping that starts before your period, lasts beyond day 2–3, or radiates to the lower back and legs consistently is not — and is one of the primary presenting symptoms of endometriosis. A study analysing 4.9 million natural cycles from over 378,000 users of the Clue app found that period flow and pain are among the highest-signal self-tracked symptoms for identifying health conditions including endometriosis and PCOS.'**
  String get cyA6SympCrampsB;

  /// No description provided for @cyA6SympCrampsP.
  ///
  /// In en, this message translates to:
  /// **'Endometriosis currently takes an average of 7 to 10 years to diagnose. Tracked symptom data documenting a consistent pain pattern is one of the most powerful tools for shortening that timeline.'**
  String get cyA6SympCrampsP;

  /// No description provided for @cyA6SympHeadT.
  ///
  /// In en, this message translates to:
  /// **'Headaches'**
  String get cyA6SympHeadT;

  /// No description provided for @cyA6SympHeadB.
  ///
  /// In en, this message translates to:
  /// **'Headaches that consistently appear in the same phase of your cycle — most commonly in the late luteal phase or around menstruation — are called menstrual migraines and are a recognised medical condition. Showing a doctor they are hormonally triggered opens up targeted treatment options.'**
  String get cyA6SympHeadB;

  /// No description provided for @cyA6SympDigT.
  ///
  /// In en, this message translates to:
  /// **'Digestive symptoms'**
  String get cyA6SympDigT;

  /// No description provided for @cyA6SympDigB.
  ///
  /// In en, this message translates to:
  /// **'Bloating, diarrhoea, and constipation that follow a consistent cycle pattern are driven by prostaglandins — chemicals produced during menstruation that affect the gut. These are often dismissed as coincidental until someone sees the pattern.'**
  String get cyA6SympDigB;

  /// No description provided for @cyA6SympAcneT.
  ///
  /// In en, this message translates to:
  /// **'Acne'**
  String get cyA6SympAcneT;

  /// No description provided for @cyA6SympAcneB.
  ///
  /// In en, this message translates to:
  /// **'Acne that consistently appears in the same phase — typically the late luteal phase — is hormonally driven and responds to different interventions than non-hormonal acne.'**
  String get cyA6SympAcneB;

  /// No description provided for @cyA6SympK1.
  ///
  /// In en, this message translates to:
  /// **'Symptoms logged in isolation are anecdotes — symptoms logged across 3 or more cycles become a pattern.'**
  String get cyA6SympK1;

  /// No description provided for @cyA6SympK2.
  ///
  /// In en, this message translates to:
  /// **'The phase in which a symptom appears is as important as the symptom itself.'**
  String get cyA6SympK2;

  /// No description provided for @cyA6SympK3.
  ///
  /// In en, this message translates to:
  /// **'You do not need to log every symptom every day — logging when something feels notable is enough to build a useful picture.'**
  String get cyA6SympK3;

  /// No description provided for @cyA6SympK4.
  ///
  /// In en, this message translates to:
  /// **'Consistent pre-menstrual symptom patterns that significantly affect your quality of life may indicate PMDD, which is treatable.'**
  String get cyA6SympK4;

  /// No description provided for @cyA6MoodH.
  ///
  /// In en, this message translates to:
  /// **'What your mood data reveals'**
  String get cyA6MoodH;

  /// No description provided for @cyA6MoodP1.
  ///
  /// In en, this message translates to:
  /// **'Mood tracking is arguably the most under-appreciated aspect of cycle logging. The connection between hormonal phase and emotional state is real, biological, and well-researched — but because most people experience it without any framework, it remains invisible and is frequently attributed to personality or external circumstances.'**
  String get cyA6MoodP1;

  /// No description provided for @cyA6MoodP2.
  ///
  /// In en, this message translates to:
  /// **'A concern in menstrual self-tracking research is that data reflects not only physiological behaviour but also the engagement dynamics of users — context is necessary for interpretation. A note of a headache during the cycle does not spur personal reflection if it is not contextualised. What happened on this day? How was sleep? These interrelated data are necessary to provide any personal insights.'**
  String get cyA6MoodP2;

  /// No description provided for @cyA6MoodP3.
  ///
  /// In en, this message translates to:
  /// **'When you log mood consistently across cycles, several things become visible:'**
  String get cyA6MoodP3;

  /// No description provided for @cyA6MoodL1.
  ///
  /// In en, this message translates to:
  /// **'The follicular phase lift — most people notice improved mood, motivation, and sociability in the week after their period ends. Seeing this pattern consistently helps you plan around it.'**
  String get cyA6MoodL1;

  /// No description provided for @cyA6MoodL2.
  ///
  /// In en, this message translates to:
  /// **'The luteal phase drop — the irritability, sensitivity, and low mood that often appears 5 to 10 days before a period follows a predictable pattern. When you can see it in your data, it stops feeling random and starts feeling manageable.'**
  String get cyA6MoodL2;

  /// No description provided for @cyA6MoodL3.
  ///
  /// In en, this message translates to:
  /// **'PMDD identification — premenstrual dysphoric disorder is characterised by severe mood disruption in the luteal phase that resolves within a few days of menstruation beginning. It affects 3 to 8 percent of people who menstruate and is significantly underdiagnosed. A pattern of consistently severe premenstrual mood changes tracked across cycles is the primary diagnostic tool.'**
  String get cyA6MoodL3;

  /// No description provided for @cyA6MoodK1.
  ///
  /// In en, this message translates to:
  /// **'You do not need to document every mood every day — simply logging when you feel notably good or notably difficult is enough to reveal the pattern.'**
  String get cyA6MoodK1;

  /// No description provided for @cyA6MoodK2.
  ///
  /// In en, this message translates to:
  /// **'Seeing the pattern changes your relationship to it — instead of \"I am anxious today,\" it becomes \"I am in the late luteal phase and this is temporary.\"'**
  String get cyA6MoodK2;

  /// No description provided for @cyA6MoodK3.
  ///
  /// In en, this message translates to:
  /// **'Mood data logged across cycles is clinically useful — bring it to any mental health or gynaecology appointment.'**
  String get cyA6MoodK3;

  /// No description provided for @cyA6CardTitle.
  ///
  /// In en, this message translates to:
  /// **'What each data point reveals over time'**
  String get cyA6CardTitle;

  /// No description provided for @cyA6CardSub.
  ///
  /// In en, this message translates to:
  /// **'Value increases significantly after 3+ cycles of consistent logging'**
  String get cyA6CardSub;

  /// No description provided for @cyA6DpFlowT.
  ///
  /// In en, this message translates to:
  /// **'Flow level'**
  String get cyA6DpFlowT;

  /// No description provided for @cyA6DpFlowD.
  ///
  /// In en, this message translates to:
  /// **'Identifies heavy bleeding patterns, endometriosis risk, anaemia, and hormonal imbalances over time'**
  String get cyA6DpFlowD;

  /// No description provided for @cyA6DpSympT.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get cyA6DpSympT;

  /// No description provided for @cyA6DpSympD.
  ///
  /// In en, this message translates to:
  /// **'Phase-correlated pain and digestive symptoms are primary diagnostic signals for endometriosis, PCOS, and PMDD'**
  String get cyA6DpSympD;

  /// No description provided for @cyA6DpMoodT.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get cyA6DpMoodT;

  /// No description provided for @cyA6DpMoodD.
  ///
  /// In en, this message translates to:
  /// **'Reveals luteal phase mood patterns, supports PMDD identification, and helps contextualise emotional experiences'**
  String get cyA6DpMoodD;

  /// No description provided for @cyA6DpMucusT.
  ///
  /// In en, this message translates to:
  /// **'Cervical mucus'**
  String get cyA6DpMucusT;

  /// No description provided for @cyA6DpMucusD.
  ///
  /// In en, this message translates to:
  /// **'Confirms ovulation timing independently of calendar prediction. Egg-white mucus is the most reliable natural ovulation indicator'**
  String get cyA6DpMucusD;

  /// No description provided for @cyA6DpLenT.
  ///
  /// In en, this message translates to:
  /// **'Cycle length history'**
  String get cyA6DpLenT;

  /// No description provided for @cyA6DpLenD.
  ///
  /// In en, this message translates to:
  /// **'Enables PCOS screening, detects short/long cycle patterns, and improves prediction accuracy significantly after 3+ cycles'**
  String get cyA6DpLenD;

  /// No description provided for @cyA6PillHigh.
  ///
  /// In en, this message translates to:
  /// **'High clinical value'**
  String get cyA6PillHigh;

  /// No description provided for @cyA6PillMedHigh.
  ///
  /// In en, this message translates to:
  /// **'Medium-high value'**
  String get cyA6PillMedHigh;

  /// No description provided for @cyA6PillMed.
  ///
  /// In en, this message translates to:
  /// **'Medium value'**
  String get cyA6PillMed;

  /// No description provided for @cyA6PillTime.
  ///
  /// In en, this message translates to:
  /// **'Increases with time'**
  String get cyA6PillTime;

  /// No description provided for @cyA6CardCaption.
  ///
  /// In en, this message translates to:
  /// **'The clinical value of your tracked data compounds over time. Flow and symptom data have the highest immediate value. Cycle length history becomes more powerful after 3 or more cycles. All of it is most useful when it is consistent.'**
  String get cyA6CardCaption;

  /// No description provided for @cyA6MucusH.
  ///
  /// In en, this message translates to:
  /// **'What cervical mucus data reveals'**
  String get cyA6MucusH;

  /// No description provided for @cyA6MucusP1.
  ///
  /// In en, this message translates to:
  /// **'Cervical mucus is the most underlogged data point in cycle tracking — and one of the most informative. Changes in mucus consistency are directly driven by estrogen and are one of the most reliable natural indicators of where you are in your cycle.'**
  String get cyA6MucusP1;

  /// No description provided for @cyA6MucusL1.
  ///
  /// In en, this message translates to:
  /// **'Dry or no mucus — early follicular phase and post-ovulation luteal phase. Estrogen is low.'**
  String get cyA6MucusL1;

  /// No description provided for @cyA6MucusL2.
  ///
  /// In en, this message translates to:
  /// **'Sticky or crumbly — early to mid follicular phase. Estrogen beginning to rise.'**
  String get cyA6MucusL2;

  /// No description provided for @cyA6MucusL3.
  ///
  /// In en, this message translates to:
  /// **'Creamy or lotion-like — mid follicular phase. Estrogen rising. Getting closer to ovulation.'**
  String get cyA6MucusL3;

  /// No description provided for @cyA6MucusL4.
  ///
  /// In en, this message translates to:
  /// **'Egg-white: clear, stretchy, slippery — the peak fertility sign. Indicates you are at or very close to ovulation. This is the most important mucus type to recognise.'**
  String get cyA6MucusL4;

  /// No description provided for @cyA6MucusL5.
  ///
  /// In en, this message translates to:
  /// **'Dry again — post-ovulation. Progesterone thickens mucus to create a barrier.'**
  String get cyA6MucusL5;

  /// No description provided for @cyA6MucusP2.
  ///
  /// In en, this message translates to:
  /// **'If you never notice egg-white mucus across multiple cycles, it can indicate that ovulation is not occurring, or that it is occurring at a different time than calendar predictions suggest. This is worth mentioning to a doctor.'**
  String get cyA6MucusP2;

  /// No description provided for @cyA6EarlyH.
  ///
  /// In en, this message translates to:
  /// **'Why starting early creates a baseline that is impossible to replicate later'**
  String get cyA6EarlyH;

  /// No description provided for @cyA6EarlyP1.
  ///
  /// In en, this message translates to:
  /// **'The most important reason to start tracking young — ideally in the first year or two after your first period — is that you are recording your baseline. The normal that exists before anything has had a chance to change it.'**
  String get cyA6EarlyP1;

  /// No description provided for @cyA6EarlyP2.
  ///
  /// In en, this message translates to:
  /// **'The Apple Women\'s Health Study found that participants whose cycles took 5 or more years to reach regularity after their first period had more than twice the risk of endometrial hyperplasia and more than 3.5 times the risk of uterine cancer compared to those who reached regularity within one year. These findings highlight the importance of understanding cycle regularity early, and encouraging people to have conversations with their healthcare providers about cycle irregularity earlier.'**
  String get cyA6EarlyP2;

  /// No description provided for @cyA6EarlyP3.
  ///
  /// In en, this message translates to:
  /// **'Dr. Shruthi Mahalingaiah, MD MS — Associate Professor of Environmental, Reproductive and Women\'s Health at Harvard — has stated that more awareness of menstrual cycle physiology and the impact of irregular periods on uterine health is needed, and that cycle tracking data is central to building that awareness at a population level.'**
  String get cyA6EarlyP3;

  /// No description provided for @cyA6EarlyP4.
  ///
  /// In en, this message translates to:
  /// **'A baseline established in your teens gives you a reference point for the rest of your life. If something changes — your flow gets heavier, your cycle length shifts, a new symptom appears — you will know it is a change because you have data showing what your normal used to look like. Without that baseline, changes are much harder to detect and much harder to communicate to a doctor.'**
  String get cyA6EarlyP4;

  /// No description provided for @cyA6DocAptH.
  ///
  /// In en, this message translates to:
  /// **'How to use tracked data in a doctor\'s appointment'**
  String get cyA6DocAptH;

  /// No description provided for @cyA6DocAptP1.
  ///
  /// In en, this message translates to:
  /// **'Most people go to a doctor and say \"my periods have been irregular lately.\" This gives the doctor very little to work with. A person who brings 3 to 6 months of tracked cycle data can say something entirely different — and get a much more targeted response.'**
  String get cyA6DocAptP1;

  /// No description provided for @cyA6DocAptP2.
  ///
  /// In en, this message translates to:
  /// **'Women with PCOS, endometriosis, and infertility in a 2023 survey reported that the use of tracking technologies directly aided in the diagnosis of their conditions — 61.8% for endometriosis, 63.6% for PCOS, and 75% for infertility.'**
  String get cyA6DocAptP2;

  /// No description provided for @cyA6DocAptP3.
  ///
  /// In en, this message translates to:
  /// **'Tracked data shortens the diagnostic path because it replaces recall-based estimates with actual longitudinal records.'**
  String get cyA6DocAptP3;

  /// No description provided for @cyA6BringLabel.
  ///
  /// In en, this message translates to:
  /// **'What to bring to a doctor\'s appointment:'**
  String get cyA6BringLabel;

  /// No description provided for @cyA6Bring1.
  ///
  /// In en, this message translates to:
  /// **'Your average cycle length and how much it varies month to month.'**
  String get cyA6Bring1;

  /// No description provided for @cyA6Bring2.
  ///
  /// In en, this message translates to:
  /// **'Your typical period length and flow pattern.'**
  String get cyA6Bring2;

  /// No description provided for @cyA6Bring3.
  ///
  /// In en, this message translates to:
  /// **'Any symptoms that appear consistently in the same phase, especially pain, mood changes, and digestive symptoms.'**
  String get cyA6Bring3;

  /// No description provided for @cyA6Bring4.
  ///
  /// In en, this message translates to:
  /// **'Any changes from your previous normal — even if you cannot articulate why it feels different.'**
  String get cyA6Bring4;

  /// No description provided for @cyA6Bring5.
  ///
  /// In en, this message translates to:
  /// **'How many cycles you have tracked and how consistently.'**
  String get cyA6Bring5;

  /// No description provided for @cyA6ConvLabel.
  ///
  /// In en, this message translates to:
  /// **'Specific conversations tracked data enables:'**
  String get cyA6ConvLabel;

  /// No description provided for @cyA6Conv1.
  ///
  /// In en, this message translates to:
  /// **'\"My period has been getting progressively heavier over the last 4 cycles\" — this is the opening to an investigation for endometriosis or fibroids.'**
  String get cyA6Conv1;

  /// No description provided for @cyA6Conv2.
  ///
  /// In en, this message translates to:
  /// **'\"I have severe mood symptoms for exactly 8 days before every period that resolve within 2 days of my period starting\" — this is the clinical description of PMDD.'**
  String get cyA6Conv2;

  /// No description provided for @cyA6Conv3.
  ///
  /// In en, this message translates to:
  /// **'\"My cycle has been consistently over 35 days for the past 6 cycles\" — this is the basis for a PCOS screening conversation.'**
  String get cyA6Conv3;

  /// No description provided for @cyA6Conv4.
  ///
  /// In en, this message translates to:
  /// **'\"I have never noticed egg-white cervical mucus across 4 cycles\" — this is a flag for possible anovulation.'**
  String get cyA6Conv4;

  /// No description provided for @cyA6DocAptP4.
  ///
  /// In en, this message translates to:
  /// **'Participants in a qualitative study on period tracking app use stated that exporting their data as a document and sharing it with doctors was one of the most helpful features of cycle tracking apps — giving doctors a concrete record rather than a memory-based estimate.'**
  String get cyA6DocAptP4;

  /// No description provided for @cyA6PredH.
  ///
  /// In en, this message translates to:
  /// **'How accurate is cycle tracking for prediction?'**
  String get cyA6PredH;

  /// No description provided for @cyA6PredP1.
  ///
  /// In en, this message translates to:
  /// **'Prediction accuracy is one of the most common questions about cycle tracking — and it is worth being honest about. Calendar-based prediction works reasonably well for people with very regular cycles, and improves substantially with more data.'**
  String get cyA6PredP1;

  /// No description provided for @cyA6PredP2.
  ///
  /// In en, this message translates to:
  /// **'A large-scale validation study of the Flo app\'s algorithm, published in JMIR mHealth and uHealth in 2023 and analysing over 3 million cycles, found that app-based menstrual cycle tracking data has significant potential for epidemiological research and clinical applications, particularly for identifying cycle characteristics associated with conditions like endometriosis and PCOS — with accuracy improving substantially as more cycles are logged.'**
  String get cyA6PredP2;

  /// No description provided for @cyA6PredP3.
  ///
  /// In en, this message translates to:
  /// **'For teenagers specifically, prediction is less reliable than for adults — because the follicular phase length is more variable. The most honest framework is:'**
  String get cyA6PredP3;

  /// No description provided for @cyA6PredL1.
  ///
  /// In en, this message translates to:
  /// **'1 to 3 cycles logged: Prediction is a rough estimate — useful for planning but not for precision.'**
  String get cyA6PredL1;

  /// No description provided for @cyA6PredL2.
  ///
  /// In en, this message translates to:
  /// **'3 to 6 cycles logged: Prediction improves significantly. Your personal average starts to emerge.'**
  String get cyA6PredL2;

  /// No description provided for @cyA6PredL3.
  ///
  /// In en, this message translates to:
  /// **'6+ cycles logged: Prediction is meaningfully personalised. The app knows your cycle, not just the population average.'**
  String get cyA6PredL3;

  /// No description provided for @cyA6PredL4.
  ///
  /// In en, this message translates to:
  /// **'Irregular cycles: Prediction will always have more variance. This is not a failure of the technology — it is an accurate reflection of your biology.'**
  String get cyA6PredL4;

  /// No description provided for @cyA6PracH.
  ///
  /// In en, this message translates to:
  /// **'Practical guidance — how to actually track effectively'**
  String get cyA6PracH;

  /// No description provided for @cyA6LogDailyLabel.
  ///
  /// In en, this message translates to:
  /// **'What to log every day of your period:'**
  String get cyA6LogDailyLabel;

  /// No description provided for @cyA6LogDaily1.
  ///
  /// In en, this message translates to:
  /// **'Flow level — consistently, every day.'**
  String get cyA6LogDaily1;

  /// No description provided for @cyA6LogDaily2.
  ///
  /// In en, this message translates to:
  /// **'Any symptoms, even mild ones.'**
  String get cyA6LogDaily2;

  /// No description provided for @cyA6LogNoticeLabel.
  ///
  /// In en, this message translates to:
  /// **'What to log when you notice it:'**
  String get cyA6LogNoticeLabel;

  /// No description provided for @cyA6LogNotice1.
  ///
  /// In en, this message translates to:
  /// **'Cervical mucus changes — particularly when you notice egg-white consistency.'**
  String get cyA6LogNotice1;

  /// No description provided for @cyA6LogNotice2.
  ///
  /// In en, this message translates to:
  /// **'Mood changes that feel notably different from your baseline.'**
  String get cyA6LogNotice2;

  /// No description provided for @cyA6LogNotice3.
  ///
  /// In en, this message translates to:
  /// **'Spotting — note the amount and colour.'**
  String get cyA6LogNotice3;

  /// No description provided for @cyA6LogCycleLabel.
  ///
  /// In en, this message translates to:
  /// **'What to log at least once per cycle:'**
  String get cyA6LogCycleLabel;

  /// No description provided for @cyA6LogCycle1.
  ///
  /// In en, this message translates to:
  /// **'The first day of your period — this is the most critical data point and should never be missed.'**
  String get cyA6LogCycle1;

  /// No description provided for @cyA6LogNotLabel.
  ///
  /// In en, this message translates to:
  /// **'What you do not need to log:'**
  String get cyA6LogNotLabel;

  /// No description provided for @cyA6LogNot1.
  ///
  /// In en, this message translates to:
  /// **'Everything, every day — this level of logging is not sustainable and is not necessary for useful data.'**
  String get cyA6LogNot1;

  /// No description provided for @cyA6LogNot2.
  ///
  /// In en, this message translates to:
  /// **'Symptoms you have to invent because you feel like you should be logging something — inaccurate data is worse than no data.'**
  String get cyA6LogNot2;

  /// No description provided for @cyA6PracK1.
  ///
  /// In en, this message translates to:
  /// **'Consistency matters more than comprehensiveness — a partial log every cycle is more valuable than a perfect log for one cycle and nothing for three cycles.'**
  String get cyA6PracK1;

  /// No description provided for @cyA6PracK2.
  ///
  /// In en, this message translates to:
  /// **'The first day of your period is the single most important data point — prioritise it above everything else.'**
  String get cyA6PracK2;

  /// No description provided for @cyA6PracK3.
  ///
  /// In en, this message translates to:
  /// **'Start now — even one cycle of data is more than zero, and the baseline you build now will be relevant for decades.'**
  String get cyA6PracK3;

  /// No description provided for @cyA6WhenH.
  ///
  /// In en, this message translates to:
  /// **'When should you talk to a doctor?'**
  String get cyA6WhenH;

  /// No description provided for @cyA6WhenP1.
  ///
  /// In en, this message translates to:
  /// **'Tracking itself will not tell you when something is wrong — but it will tell you when something has changed. Bring your tracked data to a doctor if:'**
  String get cyA6WhenP1;

  /// No description provided for @cyA6WhenL1.
  ///
  /// In en, this message translates to:
  /// **'Your cycle length has shifted by more than 7 days from your previous consistent pattern across 3 or more cycles.'**
  String get cyA6WhenL1;

  /// No description provided for @cyA6WhenL2.
  ///
  /// In en, this message translates to:
  /// **'Your flow has become consistently heavier or you are experiencing more pain than before.'**
  String get cyA6WhenL2;

  /// No description provided for @cyA6WhenL3.
  ///
  /// In en, this message translates to:
  /// **'You notice mood symptoms that follow a clear premenstrual pattern and significantly affect your daily life.'**
  String get cyA6WhenL3;

  /// No description provided for @cyA6WhenL4.
  ///
  /// In en, this message translates to:
  /// **'You have never noticed egg-white cervical mucus across 3 or more cycles.'**
  String get cyA6WhenL4;

  /// No description provided for @cyA6WhenL5.
  ///
  /// In en, this message translates to:
  /// **'Your period has been absent for 3 or more consecutive cycles.'**
  String get cyA6WhenL5;

  /// No description provided for @cyA6WhenL6.
  ///
  /// In en, this message translates to:
  /// **'You simply feel like something is different from before — even if you cannot articulate exactly what — and your tracked data confirms a change in pattern.'**
  String get cyA6WhenL6;

  /// No description provided for @cyA6WhenP2.
  ///
  /// In en, this message translates to:
  /// **'Your tracked data is not a diagnosis. It is evidence. Bring it to someone who can interpret it.'**
  String get cyA6WhenP2;

  /// No description provided for @cyDevMissing90B1.
  ///
  /// In en, this message translates to:
  /// **'Going 3 or more months without a period is a condition called secondary amenorrhea. In an adolescent, amenorrhea can be a sign of a medical problem or a side effect of certain medications. (Children\'s Hospital of Philadelphia)'**
  String get cyDevMissing90B1;

  /// No description provided for @cyDevMissing90B2.
  ///
  /// In en, this message translates to:
  /// **'The most common causes in young people include significant mental or physical stress, low body weight, and excessive exercise. The body can essentially \"shut down\" its reproductive system when it is severely malnourished, and young athletes often experience amenorrhea due to excessive exercise, low body fat, and stress.'**
  String get cyDevMissing90B2;

  /// No description provided for @cyDevMissing90B3.
  ///
  /// In en, this message translates to:
  /// **'Most cases of amenorrhea are caused by dysfunction of the hypothalamic-pituitary-ovarian (HPO) axis, which is the major regulator of the female reproductive hormones estrogen and progesterone. Other possible causes include thyroid disorders, a condition called PCOS (polycystic ovary syndrome), or in rare cases, a pituitary adenoma — a small, usually benign growth near the brain that disrupts hormone signalling.'**
  String get cyDevMissing90B3;

  /// No description provided for @cyDevMissing90B4.
  ///
  /// In en, this message translates to:
  /// **'A healthcare provider may recommend blood tests to look at hormone levels, and a pelvic ultrasound, which is a painless test that uses sound waves to create images of the reproductive system. Treatment depends on the underlying cause and may involve lifestyle changes, hormonal therapy, or other medicines. Please speak to a doctor or a trusted adult as soon as possible — the earlier this is investigated, the easier it is to manage.'**
  String get cyDevMissing90B4;

  /// No description provided for @cyDevLate14B1.
  ///
  /// In en, this message translates to:
  /// **'A period that is two weeks late is worth paying attention to, even if it turns out to be nothing serious. At your age, the most common causes are stress, changes in sleep or diet, intense exercise, or illness — all of which can disrupt the hormonal signals that control your cycle.'**
  String get cyDevLate14B1;

  /// No description provided for @cyDevLate14B2.
  ///
  /// In en, this message translates to:
  /// **'However, a 14-day delay can also be an early sign of an underlying hormonal condition. PCOS (polycystic ovary syndrome) is a common health problem that can affect teen girls and young women. It can cause irregular menstrual periods, make periods heavier, or even make periods stop.'**
  String get cyDevLate14B2;

  /// No description provided for @cyDevLate14B3.
  ///
  /// In en, this message translates to:
  /// **'Thyroid dysfunction was found in 13.6% of girls with menstrual disorders compared to 3.5% in those without — a statistically significant difference. Both conditions are very common and very treatable once diagnosed.'**
  String get cyDevLate14B3;

  /// No description provided for @cyDevLate14B4.
  ///
  /// In en, this message translates to:
  /// **'A doctor can run simple blood tests to check your hormone levels, thyroid function, and rule out other causes. You don\'t need to panic — but getting it checked early is always the right move.'**
  String get cyDevLate14B4;

  /// No description provided for @cyDevLate7B1.
  ///
  /// In en, this message translates to:
  /// **'A period that is up to 7 days late is considered within the normal range of variation for most people, especially teenagers. Your cycle is controlled by a sensitive hormonal system involving your brain, pituitary gland, and ovaries — and this system responds strongly to what is happening in your life.'**
  String get cyDevLate7B1;

  /// No description provided for @cyDevLate7B2.
  ///
  /// In en, this message translates to:
  /// **'Emotional or physical stress may cause amenorrhea for as long as the stress remains. Rapid weight loss or gain, medications, and chronic illness can also cause missed or delayed periods.'**
  String get cyDevLate7B2;

  /// No description provided for @cyDevLate7B3.
  ///
  /// In en, this message translates to:
  /// **'Common triggers at your age include exam pressure, disrupted sleep, skipping meals, travel, or recovering from an illness.'**
  String get cyDevLate7B3;

  /// No description provided for @cyDevLate7B4.
  ///
  /// In en, this message translates to:
  /// **'Approximately 75% of menstruating adolescents report their cycle to be between 21 and 45 days in the first year post-menarche. Your body is still learning its rhythm. If this keeps happening across multiple cycles, consistent tracking will help you and any doctor you see understand your pattern much faster.'**
  String get cyDevLate7B4;

  /// No description provided for @cyDevIrregularB1.
  ///
  /// In en, this message translates to:
  /// **'Cycle irregularity means the number of days between your periods varies significantly from month to month. Some variation — a few days either way — is completely normal. High irregularity over many cycles is more noteworthy.'**
  String get cyDevIrregularB1;

  /// No description provided for @cyDevIrregularB2.
  ///
  /// In en, this message translates to:
  /// **'During adolescence, the most common cause of irregular menstrual cycles is immaturity of the hypothalamic-pituitary-ovarian (HPO) axis — the hormonal control system that regulates your cycle. This is normal in the first few years after your first period.'**
  String get cyDevIrregularB2;

  /// No description provided for @cyDevIrregularB3.
  ///
  /// In en, this message translates to:
  /// **'However, other causes should also be considered. In the first year after menarche, only 20% of menstrual cycles are ovulatory. This increases to 25–35% in the second year, 45% in the fourth year, and up to 70% during years 5 to 9 after menarche.'**
  String get cyDevIrregularB3;

  /// No description provided for @cyDevIrregularB4.
  ///
  /// In en, this message translates to:
  /// **'As many as one in four people who menstruate have menstrual irregularities. Your menstrual cycle could be considered irregular if your cycles are unpredictably short (fewer than 21 days), long (more than 35 days), or spaced out by more than three months.'**
  String get cyDevIrregularB4;

  /// No description provided for @cyDevIrregularB5.
  ///
  /// In en, this message translates to:
  /// **'If irregularity persists beyond 2–3 years after your first period, a doctor can run hormone tests to get a clearer picture. It is a straightforward investigation that can rule out PCOS, thyroid issues, and other common and treatable conditions.'**
  String get cyDevIrregularB5;

  /// No description provided for @cyDevShortCycleB1.
  ///
  /// In en, this message translates to:
  /// **'A cycle shorter than 21 days means your period is arriving more frequently than what is considered typical. For teenagers this can sometimes be normal, particularly in the early years after your first period when the hormonal system is still maturing.'**
  String get cyDevShortCycleB1;

  /// No description provided for @cyDevShortCycleB2.
  ///
  /// In en, this message translates to:
  /// **'According to international evidence-based guidelines, cycles shorter than 21 days in the period between 1 and 3 years after menarche are defined as irregular and worth monitoring.'**
  String get cyDevShortCycleB2;

  /// No description provided for @cyDevShortCycleB3.
  ///
  /// In en, this message translates to:
  /// **'Consistently short cycles can sometimes be linked to a condition called a luteal phase defect, where the phase after ovulation is too short, or to low progesterone levels. They can also simply reflect your body responding to stress, significant changes in weight, or nutritional deficiencies.'**
  String get cyDevShortCycleB3;

  /// No description provided for @cyDevShortCycleB4.
  ///
  /// In en, this message translates to:
  /// **'Additional causes to consider include PCOS, hypothyroidism, elevated prolactin levels, and functional hypothalamic dysfunction. If your cycles have consistently been shorter than 21 days for 3 or more cycles, mention it to a doctor. A simple blood hormone panel can identify or rule out most causes quickly.'**
  String get cyDevShortCycleB4;

  /// No description provided for @cyDevLongCycleB1.
  ///
  /// In en, this message translates to:
  /// **'A cycle longer than 35 days means your body is taking more time than usual between periods. This is actually one of the most common menstrual patterns seen in teenagers, because the hormonal axis that controls ovulation takes several years to fully regulate after your first period.'**
  String get cyDevLongCycleB1;

  /// No description provided for @cyDevLongCycleB2.
  ///
  /// In en, this message translates to:
  /// **'According to international clinical guidelines, cycles longer than 45 days in the first 1 to 3 years after menarche, or longer than 35 days from 3 years post-menarche onwards, are considered irregular and warrant evaluation.'**
  String get cyDevLongCycleB2;

  /// No description provided for @cyDevLongCycleB3.
  ///
  /// In en, this message translates to:
  /// **'Studies have indicated that irregular menstrual cycles during puberty are predictive of future PCOS development — though this does not mean every long cycle is a sign of PCOS. Stress, thyroid dysfunction, elevated prolactin, and nutritional factors are all equally common causes.'**
  String get cyDevLongCycleB3;

  /// No description provided for @cyDevLongCycleB4.
  ///
  /// In en, this message translates to:
  /// **'Research from the Apple Women\'s Health Study, analysing 160,206 menstrual cycles across 15,586 participants, found that those with early-life irregular cycles consistently had longer mean cycle lengths in early reproductive years, with differences diminishing with age through the twenties and thirties.'**
  String get cyDevLongCycleB4;

  /// No description provided for @cyDevLongCycleB5.
  ///
  /// In en, this message translates to:
  /// **'If cycles are consistently over 35 days across 3 or more cycles, a doctor can do blood tests to check hormone levels including LH, FSH, thyroid function, and androgens.'**
  String get cyDevLongCycleB5;

  /// No description provided for @cyDevLongPeriodB1.
  ///
  /// In en, this message translates to:
  /// **'A typical period lasts between 3 and 7 days. Bleeding consistently beyond 8 days is worth investigating. Heavy menstrual bleeding (HMB) is defined as blood loss exceeding 80 mL or bleeding lasting longer than 7 days per cycle.'**
  String get cyDevLongPeriodB1;

  /// No description provided for @cyDevLongPeriodB2.
  ///
  /// In en, this message translates to:
  /// **'Extended periods in teenagers are most commonly caused by anovulatory cycles — cycles where ovulation does not occur — which leads to an overgrown uterine lining that takes longer to shed. Menstrual cycles are often irregular and anovulatory in the first few years after menarche, and the time to establish regular ovulatory cycles increases with increasing age at menarche.'**
  String get cyDevLongPeriodB2;

  /// No description provided for @cyDevLongPeriodB3.
  ///
  /// In en, this message translates to:
  /// **'Other causes include thyroid dysfunction, PCOS, and in some cases an underlying bleeding disorder. Anovulation is the most common cause of heavy menstrual bleeding in adolescents; an underlying bleeding disorder is the second most common cause.'**
  String get cyDevLongPeriodB3;

  /// No description provided for @cyDevLongPeriodB4.
  ///
  /// In en, this message translates to:
  /// **'Approximately 20% of all adolescent girls with heavy menstrual bleeding and 33% of those hospitalised for it have an underlying bleeding disorder. If your periods are consistently lasting more than 8 days, a doctor can check your iron levels — prolonged bleeding can lead to iron deficiency anaemia, which causes fatigue and difficulty concentrating.'**
  String get cyDevLongPeriodB4;

  /// No description provided for @cyDevHeavyB1.
  ///
  /// In en, this message translates to:
  /// **'Heavy menstrual bleeding — clinically called menorrhagia — is defined as excessive blood loss that interferes with your physical, social, or emotional quality of life. It is estimated to occur in approximately 37% of adolescent females. So while it can feel alarming, you are far from alone.'**
  String get cyDevHeavyB1;

  /// No description provided for @cyDevHeavyB2.
  ///
  /// In en, this message translates to:
  /// **'The most common cause of heavy menstrual bleeding in adolescents is ovulatory dysfunction, followed by coagulopathies — conditions where the blood does not clot properly. The most common inherited bleeding disorder is von Willebrand disease.'**
  String get cyDevHeavyB2;

  /// No description provided for @cyDevHeavyB3.
  ///
  /// In en, this message translates to:
  /// **'Even in the absence of anaemia, iron depletion from heavy menstrual bleeding can cause fatigue and decreased cognition, especially in verbal learning and memory.'**
  String get cyDevHeavyB3;

  /// No description provided for @cyDevHeavyB4.
  ///
  /// In en, this message translates to:
  /// **'Research advocates for conducting a comprehensive bleeding evaluation in all adolescents with heavy menstrual bleeding, even within their first year post-menarche. If you are soaking through a pad or tampon in under 2 hours, passing large clots, or feeling dizzy and fatigued during your period, speak to a doctor. Effective treatments are available — including iron supplementation, hormonal options, and other medications — that can significantly improve quality of life.'**
  String get cyDevHeavyB4;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get navDiet;

  /// No description provided for @navWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get navWorkout;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @dashScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get dashScoreLabel;

  /// No description provided for @dashTapForMore.
  ///
  /// In en, this message translates to:
  /// **'Tap for more'**
  String get dashTapForMore;

  /// No description provided for @dashSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get dashSteps;

  /// No description provided for @dashStepsUnit.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get dashStepsUnit;

  /// No description provided for @dashGoalShort.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get dashGoalShort;

  /// No description provided for @dashGoalValue.
  ///
  /// In en, this message translates to:
  /// **'Goal {value}'**
  String dashGoalValue(String value);

  /// No description provided for @dashHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get dashHeartRate;

  /// No description provided for @dashBpm.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get dashBpm;

  /// No description provided for @dashExerciseTime.
  ///
  /// In en, this message translates to:
  /// **'Exercise Time'**
  String get dashExerciseTime;

  /// No description provided for @dashCaloriesBurned.
  ///
  /// In en, this message translates to:
  /// **'Calories Burned'**
  String get dashCaloriesBurned;

  /// No description provided for @dashKcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get dashKcal;

  /// No description provided for @dashBurned.
  ///
  /// In en, this message translates to:
  /// **'Burned'**
  String get dashBurned;

  /// No description provided for @dashEaten.
  ///
  /// In en, this message translates to:
  /// **'Eaten'**
  String get dashEaten;

  /// No description provided for @dashNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get dashNet;

  /// No description provided for @dashSleepAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Sleep Analysis'**
  String get dashSleepAnalysis;

  /// No description provided for @dashSleepToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get dashSleepToday;

  /// No description provided for @dashSleepAvg.
  ///
  /// In en, this message translates to:
  /// **'(avg {value})'**
  String dashSleepAvg(String value);

  /// No description provided for @dashScore90.
  ///
  /// In en, this message translates to:
  /// **'Top 5% of adults globally'**
  String get dashScore90;

  /// No description provided for @dashScore75.
  ///
  /// In en, this message translates to:
  /// **'Healthier than ~80% of adults'**
  String get dashScore75;

  /// No description provided for @dashScore50.
  ///
  /// In en, this message translates to:
  /// **'Around average for most adults'**
  String get dashScore50;

  /// No description provided for @dashScore25.
  ///
  /// In en, this message translates to:
  /// **'Below average — most adults score higher'**
  String get dashScore25;

  /// No description provided for @dashScore0.
  ///
  /// In en, this message translates to:
  /// **'In the bottom 15% — you\'ve got room to grow'**
  String get dashScore0;

  /// No description provided for @dashStepsGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Steps goal reached — {steps} steps'**
  String dashStepsGoalReached(String steps);

  /// No description provided for @dashCaloriesGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Calories burned goal reached — {kcal} kcal'**
  String dashCaloriesGoalReached(int kcal);

  /// No description provided for @detailAddData.
  ///
  /// In en, this message translates to:
  /// **'Add data'**
  String get detailAddData;

  /// No description provided for @detailLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get detailLess;

  /// No description provided for @detailMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get detailMore;

  /// No description provided for @detailDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get detailDate;

  /// No description provided for @detailTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get detailTime;

  /// No description provided for @detailSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save. Please try again.'**
  String get detailSaveFailed;

  /// No description provided for @exDetExerciseToday.
  ///
  /// In en, this message translates to:
  /// **'Exercise today'**
  String get exDetExerciseToday;

  /// No description provided for @exDetJustStarting.
  ///
  /// In en, this message translates to:
  /// **'Just starting'**
  String get exDetJustStarting;

  /// No description provided for @exDetGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached'**
  String get exDetGoalReached;

  /// No description provided for @exDetErrorMinutes.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number of minutes greater than 0.'**
  String get exDetErrorMinutes;

  /// No description provided for @exDetMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get exDetMinutes;

  /// No description provided for @exDetMinUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get exDetMinUnit;

  /// No description provided for @exDetInsNoneP.
  ///
  /// In en, this message translates to:
  /// **'No exercise '**
  String get exDetInsNoneP;

  /// No description provided for @exDetInsNoneK.
  ///
  /// In en, this message translates to:
  /// **'recorded'**
  String get exDetInsNoneK;

  /// No description provided for @exDetInsNoneS.
  ///
  /// In en, this message translates to:
  /// **' yet today.'**
  String get exDetInsNoneS;

  /// No description provided for @exDetInsGoalP.
  ///
  /// In en, this message translates to:
  /// **'You\'ve '**
  String get exDetInsGoalP;

  /// No description provided for @exDetInsGoalK.
  ///
  /// In en, this message translates to:
  /// **'hit your goal'**
  String get exDetInsGoalK;

  /// No description provided for @exDetInsGoalS.
  ///
  /// In en, this message translates to:
  /// **' today!'**
  String get exDetInsGoalS;

  /// No description provided for @exDetInsAlmostP.
  ///
  /// In en, this message translates to:
  /// **'Almost there — '**
  String get exDetInsAlmostP;

  /// No description provided for @exDetInsAlmostK.
  ///
  /// In en, this message translates to:
  /// **'keep going'**
  String get exDetInsAlmostK;

  /// No description provided for @exDetInsAlmostS.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get exDetInsAlmostS;

  /// No description provided for @exDetInsHalfP.
  ///
  /// In en, this message translates to:
  /// **'You\'re '**
  String get exDetInsHalfP;

  /// No description provided for @exDetInsHalfK.
  ///
  /// In en, this message translates to:
  /// **'halfway to your goal'**
  String get exDetInsHalfK;

  /// No description provided for @exDetInsHalfS.
  ///
  /// In en, this message translates to:
  /// **' today.'**
  String get exDetInsHalfS;

  /// No description provided for @exDetInsStartP.
  ///
  /// In en, this message translates to:
  /// **'You\'ve made a '**
  String get exDetInsStartP;

  /// No description provided for @exDetInsStartK.
  ///
  /// In en, this message translates to:
  /// **'solid start'**
  String get exDetInsStartK;

  /// No description provided for @exDetInsStartS.
  ///
  /// In en, this message translates to:
  /// **' today.'**
  String get exDetInsStartS;

  /// No description provided for @exDetInsEveryP.
  ///
  /// In en, this message translates to:
  /// **'Every minute '**
  String get exDetInsEveryP;

  /// No description provided for @exDetInsEveryK.
  ///
  /// In en, this message translates to:
  /// **'counts'**
  String get exDetInsEveryK;

  /// No description provided for @exDetInsEveryS.
  ///
  /// In en, this message translates to:
  /// **' — keep moving.'**
  String get exDetInsEveryS;

  /// No description provided for @detailDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get detailDaily;

  /// No description provided for @detailWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get detailWeekly;

  /// No description provided for @detailDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get detailDailyGoal;

  /// No description provided for @detailKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get detailKm;

  /// No description provided for @stepsDetGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hey {name},'**
  String stepsDetGreeting(String name);

  /// No description provided for @stepsDetWalkedPrefix.
  ///
  /// In en, this message translates to:
  /// **'You walked '**
  String get stepsDetWalkedPrefix;

  /// No description provided for @stepsDetWalkedSuffix.
  ///
  /// In en, this message translates to:
  /// **' steps today'**
  String get stepsDetWalkedSuffix;

  /// No description provided for @stepsDetErrorCount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid step count greater than 0.'**
  String get stepsDetErrorCount;

  /// No description provided for @detailDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get detailDistance;

  /// No description provided for @detailToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get detailToday;

  /// No description provided for @stepsDetTodaysSteps.
  ///
  /// In en, this message translates to:
  /// **'Today\'s steps'**
  String get stepsDetTodaysSteps;

  /// No description provided for @stepsDetAvgDaily.
  ///
  /// In en, this message translates to:
  /// **'Avg. daily steps'**
  String get stepsDetAvgDaily;

  /// No description provided for @stepsDetEmpty.
  ///
  /// In en, this message translates to:
  /// **'No steps recorded yet today'**
  String get stepsDetEmpty;

  /// No description provided for @stepsDetDistanceSub.
  ///
  /// In en, this message translates to:
  /// **'≈ {meters} m  ·  {steps} steps'**
  String stepsDetDistanceSub(int meters, int steps);

  /// No description provided for @hrDetBpm.
  ///
  /// In en, this message translates to:
  /// **'BPM'**
  String get hrDetBpm;

  /// No description provided for @hrDetEnterBpm.
  ///
  /// In en, this message translates to:
  /// **'Enter BPM'**
  String get hrDetEnterBpm;

  /// No description provided for @hrDetAvgToday.
  ///
  /// In en, this message translates to:
  /// **'Avg today'**
  String get hrDetAvgToday;

  /// No description provided for @hrDetNoDataToday.
  ///
  /// In en, this message translates to:
  /// **'No heart rate data today'**
  String get hrDetNoDataToday;

  /// No description provided for @hrDetLowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get hrDetLowest;

  /// No description provided for @hrDetHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get hrDetHighest;

  /// No description provided for @hrDetRange.
  ///
  /// In en, this message translates to:
  /// **'RANGE'**
  String get hrDetRange;

  /// No description provided for @hrDetZonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate Zones'**
  String get hrDetZonesTitle;

  /// No description provided for @hrDetZoneResting.
  ///
  /// In en, this message translates to:
  /// **'Resting'**
  String get hrDetZoneResting;

  /// No description provided for @hrDetZoneNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get hrDetZoneNormal;

  /// No description provided for @hrDetZoneElevated.
  ///
  /// In en, this message translates to:
  /// **'Elevated'**
  String get hrDetZoneElevated;

  /// No description provided for @hrDetZoneHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get hrDetZoneHigh;

  /// No description provided for @hrDetReadNow.
  ///
  /// In en, this message translates to:
  /// **'Read your heart now'**
  String get hrDetReadNow;

  /// No description provided for @hrDetReadNowSub.
  ///
  /// In en, this message translates to:
  /// **'Use camera & flashlight to measure BPM'**
  String get hrDetReadNowSub;

  /// No description provided for @hrDetInsNoneP.
  ///
  /// In en, this message translates to:
  /// **'No heart rate data recorded '**
  String get hrDetInsNoneP;

  /// No description provided for @hrDetInsNoneK.
  ///
  /// In en, this message translates to:
  /// **'yet today'**
  String get hrDetInsNoneK;

  /// No description provided for @hrDetInsNoneS.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get hrDetInsNoneS;

  /// No description provided for @hrDetInsElevatedP.
  ///
  /// In en, this message translates to:
  /// **'Your average rate has been '**
  String get hrDetInsElevatedP;

  /// No description provided for @hrDetInsElevatedK.
  ///
  /// In en, this message translates to:
  /// **'elevated'**
  String get hrDetInsElevatedK;

  /// No description provided for @hrDetInsElevatedS.
  ///
  /// In en, this message translates to:
  /// **' today.'**
  String get hrDetInsElevatedS;

  /// No description provided for @hrDetInsManyP.
  ///
  /// In en, this message translates to:
  /// **'You had '**
  String get hrDetInsManyP;

  /// No description provided for @hrDetInsManyK.
  ///
  /// In en, this message translates to:
  /// **'several active spikes'**
  String get hrDetInsManyK;

  /// No description provided for @hrDetInsManyS.
  ///
  /// In en, this message translates to:
  /// **' today.'**
  String get hrDetInsManyS;

  /// No description provided for @hrDetInsFewP.
  ///
  /// In en, this message translates to:
  /// **'You had a few '**
  String get hrDetInsFewP;

  /// No description provided for @hrDetInsFewK.
  ///
  /// In en, this message translates to:
  /// **'active spikes'**
  String get hrDetInsFewK;

  /// No description provided for @hrDetInsFewS.
  ///
  /// In en, this message translates to:
  /// **' today.'**
  String get hrDetInsFewS;

  /// No description provided for @hrDetInsWideP.
  ///
  /// In en, this message translates to:
  /// **'Your heart rate had a '**
  String get hrDetInsWideP;

  /// No description provided for @hrDetInsWideK.
  ///
  /// In en, this message translates to:
  /// **'wide range'**
  String get hrDetInsWideK;

  /// No description provided for @hrDetInsWideS.
  ///
  /// In en, this message translates to:
  /// **' today.'**
  String get hrDetInsWideS;

  /// No description provided for @hrDetInsCalmP.
  ///
  /// In en, this message translates to:
  /// **'You have been '**
  String get hrDetInsCalmP;

  /// No description provided for @hrDetInsCalmK.
  ///
  /// In en, this message translates to:
  /// **'very calm'**
  String get hrDetInsCalmK;

  /// No description provided for @hrDetInsCalmS.
  ///
  /// In en, this message translates to:
  /// **' today.'**
  String get hrDetInsCalmS;

  /// No description provided for @hrDetInsSteadyP.
  ///
  /// In en, this message translates to:
  /// **'Your heart rate has been '**
  String get hrDetInsSteadyP;

  /// No description provided for @hrDetInsSteadyK.
  ///
  /// In en, this message translates to:
  /// **'steady'**
  String get hrDetInsSteadyK;

  /// No description provided for @hrDetInsSteadyS.
  ///
  /// In en, this message translates to:
  /// **' today.'**
  String get hrDetInsSteadyS;

  /// No description provided for @hrDetInsNormalP.
  ///
  /// In en, this message translates to:
  /// **'Your average rate is in a '**
  String get hrDetInsNormalP;

  /// No description provided for @hrDetInsNormalK.
  ///
  /// In en, this message translates to:
  /// **'normal range'**
  String get hrDetInsNormalK;

  /// No description provided for @hrDetInsNormalS.
  ///
  /// In en, this message translates to:
  /// **' today.'**
  String get hrDetInsNormalS;

  /// No description provided for @calDetCaloriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calDetCaloriesTitle;

  /// No description provided for @calDetBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Calorie Balance'**
  String get calDetBalanceTitle;

  /// No description provided for @calDetActiveEnergyToday.
  ///
  /// In en, this message translates to:
  /// **'Active energy today'**
  String get calDetActiveEnergyToday;

  /// No description provided for @calDetCaloriesConsumedToday.
  ///
  /// In en, this message translates to:
  /// **'Calories consumed today'**
  String get calDetCaloriesConsumedToday;

  /// No description provided for @calDetBurnGoalOf.
  ///
  /// In en, this message translates to:
  /// **'of {goal} burn goal'**
  String calDetBurnGoalOf(int goal);

  /// No description provided for @calDetSurplus.
  ///
  /// In en, this message translates to:
  /// **'Surplus'**
  String get calDetSurplus;

  /// No description provided for @calDetExtremeDeficit.
  ///
  /// In en, this message translates to:
  /// **'Extreme deficit'**
  String get calDetExtremeDeficit;

  /// No description provided for @calDetMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get calDetMaintenance;

  /// No description provided for @calDetDeficit.
  ///
  /// In en, this message translates to:
  /// **'Deficit'**
  String get calDetDeficit;

  /// No description provided for @calDetErrorAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid calorie amount greater than 0.'**
  String get calDetErrorAmount;

  /// No description provided for @calDetGainedNote.
  ///
  /// In en, this message translates to:
  /// **'To log gained (eaten) calories, use the Diet section.'**
  String get calDetGainedNote;

  /// No description provided for @calDetInsNoneP.
  ///
  /// In en, this message translates to:
  /// **'No activity '**
  String get calDetInsNoneP;

  /// No description provided for @calDetInsNoneK.
  ///
  /// In en, this message translates to:
  /// **'recorded'**
  String get calDetInsNoneK;

  /// No description provided for @calDetInsNoneS.
  ///
  /// In en, this message translates to:
  /// **' yet today.'**
  String get calDetInsNoneS;

  /// No description provided for @calDetInsNoBurnP.
  ///
  /// In en, this message translates to:
  /// **'You\'ve eaten but haven\'t '**
  String get calDetInsNoBurnP;

  /// No description provided for @calDetInsNoBurnK.
  ///
  /// In en, this message translates to:
  /// **'burned any calories'**
  String get calDetInsNoBurnK;

  /// No description provided for @calDetInsNoBurnS.
  ///
  /// In en, this message translates to:
  /// **' yet.'**
  String get calDetInsNoBurnS;

  /// No description provided for @calDetInsGoalP.
  ///
  /// In en, this message translates to:
  /// **'You\'ve '**
  String get calDetInsGoalP;

  /// No description provided for @calDetInsGoalK.
  ///
  /// In en, this message translates to:
  /// **'hit your burn goal'**
  String get calDetInsGoalK;

  /// No description provided for @calDetInsGoalS.
  ///
  /// In en, this message translates to:
  /// **' today!'**
  String get calDetInsGoalS;

  /// No description provided for @calDetInsDeficitP.
  ///
  /// In en, this message translates to:
  /// **'You\'re in a '**
  String get calDetInsDeficitP;

  /// No description provided for @calDetInsDeficitK.
  ///
  /// In en, this message translates to:
  /// **'solid deficit'**
  String get calDetInsDeficitK;

  /// No description provided for @calDetInsDeficitS.
  ///
  /// In en, this message translates to:
  /// **' today.'**
  String get calDetInsDeficitS;

  /// No description provided for @calDetInsSurplusP.
  ///
  /// In en, this message translates to:
  /// **'You\'re in a '**
  String get calDetInsSurplusP;

  /// No description provided for @calDetInsSurplusK.
  ///
  /// In en, this message translates to:
  /// **'calorie surplus'**
  String get calDetInsSurplusK;

  /// No description provided for @calDetInsSurplusS.
  ///
  /// In en, this message translates to:
  /// **' today.'**
  String get calDetInsSurplusS;

  /// No description provided for @calDetInsMaintP.
  ///
  /// In en, this message translates to:
  /// **'You\'re close to '**
  String get calDetInsMaintP;

  /// No description provided for @calDetInsMaintK.
  ///
  /// In en, this message translates to:
  /// **'maintenance'**
  String get calDetInsMaintK;

  /// No description provided for @calDetInsMaintS.
  ///
  /// In en, this message translates to:
  /// **' today.'**
  String get calDetInsMaintS;

  /// No description provided for @calDetInsHalfP.
  ///
  /// In en, this message translates to:
  /// **'You\'re '**
  String get calDetInsHalfP;

  /// No description provided for @calDetInsHalfK.
  ///
  /// In en, this message translates to:
  /// **'halfway to your burn goal'**
  String get calDetInsHalfK;

  /// No description provided for @calDetInsHalfS.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get calDetInsHalfS;

  /// No description provided for @calDetInsKeepP.
  ///
  /// In en, this message translates to:
  /// **'Keep moving to '**
  String get calDetInsKeepP;

  /// No description provided for @calDetInsKeepK.
  ///
  /// In en, this message translates to:
  /// **'reach your goal'**
  String get calDetInsKeepK;

  /// No description provided for @calDetInsKeepS.
  ///
  /// In en, this message translates to:
  /// **' today.'**
  String get calDetInsKeepS;

  /// No description provided for @slpStageInBed.
  ///
  /// In en, this message translates to:
  /// **'In Bed'**
  String get slpStageInBed;

  /// No description provided for @slpStageAsleep.
  ///
  /// In en, this message translates to:
  /// **'Asleep'**
  String get slpStageAsleep;

  /// No description provided for @slpStageAwake.
  ///
  /// In en, this message translates to:
  /// **'Awake'**
  String get slpStageAwake;

  /// No description provided for @slpStageCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get slpStageCore;

  /// No description provided for @slpStageDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get slpStageDeep;

  /// No description provided for @slpStageRem.
  ///
  /// In en, this message translates to:
  /// **'REM'**
  String get slpStageRem;

  /// No description provided for @slpStageTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get slpStageTotal;

  /// No description provided for @slpYouSleptFor.
  ///
  /// In en, this message translates to:
  /// **'You slept for'**
  String get slpYouSleptFor;

  /// No description provided for @slpTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get slpTitle;

  /// No description provided for @slpStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get slpStarts;

  /// No description provided for @slpEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get slpEnds;

  /// No description provided for @slpErrorEndAfter.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time.'**
  String get slpErrorEndAfter;

  /// No description provided for @slpStagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleep Stages'**
  String get slpStagesTitle;

  /// No description provided for @slpStagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a sleep entry to see your chart'**
  String get slpStagesEmpty;

  /// No description provided for @slpInsNoneP.
  ///
  /// In en, this message translates to:
  /// **'No sleep data '**
  String get slpInsNoneP;

  /// No description provided for @slpInsNoneK.
  ///
  /// In en, this message translates to:
  /// **'recorded'**
  String get slpInsNoneK;

  /// No description provided for @slpInsNoneS.
  ///
  /// In en, this message translates to:
  /// **' yet.'**
  String get slpInsNoneS;

  /// No description provided for @slpInsGreatP.
  ///
  /// In en, this message translates to:
  /// **'You got a '**
  String get slpInsGreatP;

  /// No description provided for @slpInsGreatK.
  ///
  /// In en, this message translates to:
  /// **'great night\'s sleep'**
  String get slpInsGreatK;

  /// No description provided for @slpInsGreatS.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get slpInsGreatS;

  /// No description provided for @slpInsWellP.
  ///
  /// In en, this message translates to:
  /// **'You slept '**
  String get slpInsWellP;

  /// No description provided for @slpInsWellK.
  ///
  /// In en, this message translates to:
  /// **'well'**
  String get slpInsWellK;

  /// No description provided for @slpInsWellS.
  ///
  /// In en, this message translates to:
  /// **' last night.'**
  String get slpInsWellS;

  /// No description provided for @slpInsDecentP.
  ///
  /// In en, this message translates to:
  /// **'You got '**
  String get slpInsDecentP;

  /// No description provided for @slpInsDecentK.
  ///
  /// In en, this message translates to:
  /// **'decent sleep'**
  String get slpInsDecentK;

  /// No description provided for @slpInsDecentS.
  ///
  /// In en, this message translates to:
  /// **' last night.'**
  String get slpInsDecentS;

  /// No description provided for @slpInsShortP.
  ///
  /// In en, this message translates to:
  /// **'You had a '**
  String get slpInsShortP;

  /// No description provided for @slpInsShortK.
  ///
  /// In en, this message translates to:
  /// **'short night'**
  String get slpInsShortK;

  /// No description provided for @slpInsShortS.
  ///
  /// In en, this message translates to:
  /// **' — try to rest more.'**
  String get slpInsShortS;

  /// No description provided for @slpInsNeedP.
  ///
  /// In en, this message translates to:
  /// **'You need '**
  String get slpInsNeedP;

  /// No description provided for @slpInsNeedK.
  ///
  /// In en, this message translates to:
  /// **'more sleep'**
  String get slpInsNeedK;

  /// No description provided for @slpInsNeedS.
  ///
  /// In en, this message translates to:
  /// **' tonight.'**
  String get slpInsNeedS;

  /// No description provided for @hrMeasYourHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Your heart rate'**
  String get hrMeasYourHeartRate;

  /// No description provided for @hrMeasCouldntRead.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read your pulse'**
  String get hrMeasCouldntRead;

  /// No description provided for @hrMeasWaitingFinger.
  ///
  /// In en, this message translates to:
  /// **'Waiting for finger…'**
  String get hrMeasWaitingFinger;

  /// No description provided for @hrMeasHoldStill.
  ///
  /// In en, this message translates to:
  /// **'Hold still…'**
  String get hrMeasHoldStill;

  /// No description provided for @hrMeasPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get hrMeasPaused;

  /// No description provided for @hrMeasReadYourHeart.
  ///
  /// In en, this message translates to:
  /// **'Read your heart'**
  String get hrMeasReadYourHeart;

  /// No description provided for @hrMeasSubDone.
  ///
  /// In en, this message translates to:
  /// **'Tap Save to add this reading to today.'**
  String get hrMeasSubDone;

  /// No description provided for @hrMeasSubWaiting.
  ///
  /// In en, this message translates to:
  /// **'Place your fingertip over the rear camera and flash. The reading will start automatically.'**
  String get hrMeasSubWaiting;

  /// No description provided for @hrMeasSubMeasuring.
  ///
  /// In en, this message translates to:
  /// **'Hold your finger steady over the camera and flash.'**
  String get hrMeasSubMeasuring;

  /// No description provided for @hrMeasSubPaused.
  ///
  /// In en, this message translates to:
  /// **'Place your finger back on the camera to continue.'**
  String get hrMeasSubPaused;

  /// No description provided for @hrMeasSubIdle.
  ///
  /// In en, this message translates to:
  /// **'We use your phone\'s camera and flashlight to detect your pulse through your fingertip.'**
  String get hrMeasSubIdle;

  /// No description provided for @hrMeasFailLifted.
  ///
  /// In en, this message translates to:
  /// **'You lifted your finger. Hold it steady over the camera and flash for the full reading.'**
  String get hrMeasFailLifted;

  /// No description provided for @hrMeasFailNoFrames.
  ///
  /// In en, this message translates to:
  /// **'No camera frames received. Try again.'**
  String get hrMeasFailNoFrames;

  /// No description provided for @hrMeasFailNoFinger.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t see your finger on the camera. Cover the rear camera and flash with your fingertip, then try again.'**
  String get hrMeasFailNoFinger;

  /// No description provided for @hrMeasFailNoSignal.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t detect a clear pulse signal. Make sure your finger fully covers the camera and flash.'**
  String get hrMeasFailNoSignal;

  /// No description provided for @hrMeasFailNoSteady.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t detect a steady pulse. Hold your finger still over the camera and flash, then try again.'**
  String get hrMeasFailNoSteady;

  /// No description provided for @hrMeasFailLockOn.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t lock onto your pulse.'**
  String get hrMeasFailLockOn;

  /// No description provided for @hrMeasCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable: {error}'**
  String hrMeasCameraUnavailable(String error);

  /// No description provided for @hrMeasDidYouKnow.
  ///
  /// In en, this message translates to:
  /// **'Did you know?'**
  String get hrMeasDidYouKnow;

  /// No description provided for @hrMeasTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get hrMeasTryAgain;

  /// No description provided for @hrMeasRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get hrMeasRetry;

  /// No description provided for @hrMeasSave.
  ///
  /// In en, this message translates to:
  /// **'Save {bpm} BPM'**
  String hrMeasSave(int bpm);

  /// No description provided for @hrMeasCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get hrMeasCancel;

  /// No description provided for @hrMeasStart.
  ///
  /// In en, this message translates to:
  /// **'Start measurement'**
  String get hrMeasStart;

  /// No description provided for @hrMeasPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing camera…'**
  String get hrMeasPreparing;

  /// No description provided for @hrTip1.
  ///
  /// In en, this message translates to:
  /// **'Your heart beats around 100,000 times a day.'**
  String get hrTip1;

  /// No description provided for @hrTip2.
  ///
  /// In en, this message translates to:
  /// **'A typical adult resting heart rate is 60–100 BPM.'**
  String get hrTip2;

  /// No description provided for @hrTip3.
  ///
  /// In en, this message translates to:
  /// **'Athletes often have resting heart rates below 60 BPM.'**
  String get hrTip3;

  /// No description provided for @hrTip4.
  ///
  /// In en, this message translates to:
  /// **'Deep, slow breaths can lower your heart rate.'**
  String get hrTip4;

  /// No description provided for @hrTip5.
  ///
  /// In en, this message translates to:
  /// **'Sit upright and relax your shoulders for a cleaner reading.'**
  String get hrTip5;

  /// No description provided for @hrTip6.
  ///
  /// In en, this message translates to:
  /// **'Try not to talk or move while we measure.'**
  String get hrTip6;

  /// No description provided for @hrTip7.
  ///
  /// In en, this message translates to:
  /// **'Your heart pumps about 2,000 gallons of blood every day.'**
  String get hrTip7;

  /// No description provided for @hrTip8.
  ///
  /// In en, this message translates to:
  /// **'Hydration helps your heart pump more efficiently.'**
  String get hrTip8;

  /// No description provided for @hrTip9.
  ///
  /// In en, this message translates to:
  /// **'Caffeine can raise your resting heart rate for hours.'**
  String get hrTip9;

  /// No description provided for @hrTip10.
  ///
  /// In en, this message translates to:
  /// **'The “lub-dub” sound is your heart valves snapping shut.'**
  String get hrTip10;

  /// No description provided for @hrTip11.
  ///
  /// In en, this message translates to:
  /// **'Laughter has been shown to lower blood pressure.'**
  String get hrTip11;

  /// No description provided for @hrTip12.
  ///
  /// In en, this message translates to:
  /// **'Cold hands? Warm them up — it gives a stronger signal.'**
  String get hrTip12;

  /// No description provided for @hrTip13.
  ///
  /// In en, this message translates to:
  /// **'Press gently. Squeezing too hard cuts off the pulse.'**
  String get hrTip13;

  /// No description provided for @hrTip14.
  ///
  /// In en, this message translates to:
  /// **'Your heart is roughly the size of your fist.'**
  String get hrTip14;

  /// No description provided for @hrMeasCoverCamera.
  ///
  /// In en, this message translates to:
  /// **'Cover the camera fully with your fingertip'**
  String get hrMeasCoverCamera;

  /// No description provided for @woTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get woTitle;

  /// No description provided for @woHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get woHistory;

  /// No description provided for @woHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout History'**
  String get woHistoryTitle;

  /// No description provided for @woChooseActivity.
  ///
  /// In en, this message translates to:
  /// **'Choose an activity'**
  String get woChooseActivity;

  /// No description provided for @woModeRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get woModeRunning;

  /// No description provided for @woModeTrailRun.
  ///
  /// In en, this message translates to:
  /// **'Trail Run'**
  String get woModeTrailRun;

  /// No description provided for @woModeOutdoorWalking.
  ///
  /// In en, this message translates to:
  /// **'Outdoor Walking'**
  String get woModeOutdoorWalking;

  /// No description provided for @woModeCycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get woModeCycling;

  /// No description provided for @woModeMountainBike.
  ///
  /// In en, this message translates to:
  /// **'Mountain Bike Ride'**
  String get woModeMountainBike;

  /// No description provided for @woModeEBike.
  ///
  /// In en, this message translates to:
  /// **'E-Bike Ride'**
  String get woModeEBike;

  /// No description provided for @woModeSwimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get woModeSwimming;

  /// No description provided for @woSubRunning.
  ///
  /// In en, this message translates to:
  /// **'GPS route, speed (km/h), calories, and active time.'**
  String get woSubRunning;

  /// No description provided for @woSubTrailRun.
  ///
  /// In en, this message translates to:
  /// **'Trail run with GPS, pace (min/km), and higher-intensity calorie estimate.'**
  String get woSubTrailRun;

  /// No description provided for @woSubOutdoorWalking.
  ///
  /// In en, this message translates to:
  /// **'Outdoor walk with live GPS route and speed.'**
  String get woSubOutdoorWalking;

  /// No description provided for @woSubCycling.
  ///
  /// In en, this message translates to:
  /// **'Ride with GPS speed (km/h), distance, and calorie estimate.'**
  String get woSubCycling;

  /// No description provided for @woSubMountainBike.
  ///
  /// In en, this message translates to:
  /// **'Off-road ride with GPS; calories tuned for higher MTB effort.'**
  String get woSubMountainBike;

  /// No description provided for @woSubEBike.
  ///
  /// In en, this message translates to:
  /// **'Assisted ride with GPS; calories reflect lighter effort vs. standard cycling.'**
  String get woSubEBike;

  /// No description provided for @woSubSwimming.
  ///
  /// In en, this message translates to:
  /// **'Open-water or pool-side GPS; distance in meters, swim pace (/100m), time-based calories.'**
  String get woSubSwimming;

  /// No description provided for @woPace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get woPace;

  /// No description provided for @woSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get woSpeed;

  /// No description provided for @woDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get woDistance;

  /// No description provided for @woDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get woDuration;

  /// No description provided for @woCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get woCalories;

  /// No description provided for @woActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get woActive;

  /// No description provided for @woKcalValue.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String woKcalValue(int kcal);

  /// No description provided for @woCaloriesLine.
  ///
  /// In en, this message translates to:
  /// **'Calories: {kcal} kcal'**
  String woCaloriesLine(int kcal);

  /// No description provided for @woSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get woSteps;

  /// No description provided for @woStepsLine.
  ///
  /// In en, this message translates to:
  /// **'Steps: {count}'**
  String woStepsLine(int count);

  /// No description provided for @settingsBackgroundStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Background step tracking'**
  String get settingsBackgroundStepsTitle;

  /// No description provided for @settingsBackgroundStepsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Count steps automatically all day. When off, steps are only counted during workouts.'**
  String get settingsBackgroundStepsSubtitle;

  /// No description provided for @settingsBackgroundStepsDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow the Physical activity permission to track your steps.'**
  String get settingsBackgroundStepsDenied;

  /// No description provided for @woMinValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String woMinValue(int minutes);

  /// No description provided for @woLoadingWeather.
  ///
  /// In en, this message translates to:
  /// **'Loading weather...'**
  String get woLoadingWeather;

  /// No description provided for @woLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get woLocationUnavailable;

  /// No description provided for @woUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get woUnknown;

  /// No description provided for @woTempCondition.
  ///
  /// In en, this message translates to:
  /// **'{temp}°C • {condition}'**
  String woTempCondition(String temp, String condition);

  /// No description provided for @woLatLng.
  ///
  /// In en, this message translates to:
  /// **'Lat {lat} • Lng {lng}'**
  String woLatLng(String lat, String lng);

  /// No description provided for @woWeatherFull.
  ///
  /// In en, this message translates to:
  /// **'Feels {feels}°C • Humidity {humidity}% • Wind {wind} kph'**
  String woWeatherFull(String feels, String humidity, String wind);

  /// No description provided for @woWeatherCompact.
  ///
  /// In en, this message translates to:
  /// **'Feels {feels}° • Hum {humidity}% • Wind {wind} kph'**
  String woWeatherCompact(String feels, String humidity, String wind);

  /// No description provided for @woStopRoute.
  ///
  /// In en, this message translates to:
  /// **'Stop Route'**
  String get woStopRoute;

  /// No description provided for @woPreparingGps.
  ///
  /// In en, this message translates to:
  /// **'Preparing GPS...'**
  String get woPreparingGps;

  /// No description provided for @woStartRoute.
  ///
  /// In en, this message translates to:
  /// **'Start Route'**
  String get woStartRoute;

  /// No description provided for @woResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get woResume;

  /// No description provided for @woPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get woPause;

  /// No description provided for @woReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get woReset;

  /// No description provided for @woGo.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get woGo;

  /// No description provided for @woShowUi.
  ///
  /// In en, this message translates to:
  /// **'Show UI'**
  String get woShowUi;

  /// No description provided for @woHideUi.
  ///
  /// In en, this message translates to:
  /// **'Hide UI'**
  String get woHideUi;

  /// No description provided for @woRecenterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Recenter map on your location'**
  String get woRecenterTooltip;

  /// No description provided for @woMapFollows.
  ///
  /// In en, this message translates to:
  /// **'Map follows your location (pan map to explore freely)'**
  String get woMapFollows;

  /// No description provided for @woStatusPluginNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Location plugin not loaded. Fully restart the app (stop and run again).'**
  String get woStatusPluginNotLoaded;

  /// No description provided for @woStatusPlatformError.
  ///
  /// In en, this message translates to:
  /// **'Location platform error: {error}'**
  String woStatusPlatformError(String error);

  /// No description provided for @woStatusTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timed out while getting your current location.'**
  String get woStatusTimeout;

  /// No description provided for @woStatusServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled.'**
  String get woStatusServicesDisabled;

  /// No description provided for @woStatusUnableLocation.
  ///
  /// In en, this message translates to:
  /// **'Unable to get current location: {error}'**
  String woStatusUnableLocation(String error);

  /// No description provided for @woStatusPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get woStatusPermissionDenied;

  /// No description provided for @woStatusPermissionPermanent.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied.'**
  String get woStatusPermissionPermanent;

  /// No description provided for @woStatusGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting your live location...'**
  String get woStatusGettingLocation;

  /// No description provided for @woStatusGettingLocationMode.
  ///
  /// In en, this message translates to:
  /// **'Getting your live location for {mode}...'**
  String woStatusGettingLocationMode(String mode);

  /// No description provided for @woStatusLiveReady.
  ///
  /// In en, this message translates to:
  /// **'Live location ready.'**
  String get woStatusLiveReady;

  /// No description provided for @woStatusStreamError.
  ///
  /// In en, this message translates to:
  /// **'Location stream error: {error}'**
  String woStatusStreamError(String error);

  /// No description provided for @woStatusTrackingStarted.
  ///
  /// In en, this message translates to:
  /// **'Tracking started.'**
  String get woStatusTrackingStarted;

  /// No description provided for @woStatusStartCancelled.
  ///
  /// In en, this message translates to:
  /// **'Start cancelled.'**
  String get woStatusStartCancelled;

  /// No description provided for @woStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused. Tap Resume to continue.'**
  String get woStatusPaused;

  /// No description provided for @woStatusResumed.
  ///
  /// In en, this message translates to:
  /// **'Tracking resumed.'**
  String get woStatusResumed;

  /// No description provided for @woToastStarted.
  ///
  /// In en, this message translates to:
  /// **'Workout started — let\'s go!'**
  String get woToastStarted;

  /// No description provided for @woToastSaved.
  ///
  /// In en, this message translates to:
  /// **'Workout saved'**
  String get woToastSaved;

  /// No description provided for @woToastDeleted.
  ///
  /// In en, this message translates to:
  /// **'Workout deleted'**
  String get woToastDeleted;

  /// No description provided for @woEndRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'End route?'**
  String get woEndRouteTitle;

  /// No description provided for @woEndRouteBody.
  ///
  /// In en, this message translates to:
  /// **'Your current tracking session will stop.'**
  String get woEndRouteBody;

  /// No description provided for @woEndRouteConfirm.
  ///
  /// In en, this message translates to:
  /// **'End Route'**
  String get woEndRouteConfirm;

  /// No description provided for @woNotifInProgress.
  ///
  /// In en, this message translates to:
  /// **'{mode} in progress'**
  String woNotifInProgress(String mode);

  /// No description provided for @woNotifStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout started'**
  String get woNotifStartedTitle;

  /// No description provided for @woNotifStartedBody.
  ///
  /// In en, this message translates to:
  /// **'{mode} tracking is live. Keep your pace steady.'**
  String woNotifStartedBody(String mode);

  /// No description provided for @woNotifWeatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout weather advisory'**
  String get woNotifWeatherTitle;

  /// No description provided for @woNotifWeatherHot.
  ///
  /// In en, this message translates to:
  /// **'High heat detected ({temp}°C). Hydrate and ease intensity.'**
  String woNotifWeatherHot(String temp);

  /// No description provided for @woNotifWeatherSevere.
  ///
  /// In en, this message translates to:
  /// **'Current weather is {condition}. Consider safer indoor training.'**
  String woNotifWeatherSevere(String condition);

  /// No description provided for @woWeatherUnfavorable.
  ///
  /// In en, this message translates to:
  /// **'unfavorable'**
  String get woWeatherUnfavorable;

  /// No description provided for @woNotifWeatherWind.
  ///
  /// In en, this message translates to:
  /// **'Strong wind detected ({wind} kph). Adjust your route and effort.'**
  String woNotifWeatherWind(String wind);

  /// No description provided for @woNotifDistanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Distance milestone'**
  String get woNotifDistanceTitle;

  /// No description provided for @woNotifDistanceBody.
  ///
  /// In en, this message translates to:
  /// **'Great work! You just crossed {km} km.'**
  String woNotifDistanceBody(int km);

  /// No description provided for @woNotifTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Time milestone'**
  String get woNotifTimeTitle;

  /// No description provided for @woNotifTimeBody.
  ///
  /// In en, this message translates to:
  /// **'You have trained for {minutes} minutes.'**
  String woNotifTimeBody(int minutes);

  /// No description provided for @woNotifGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal reached'**
  String get woNotifGoalTitle;

  /// No description provided for @woNotifGoalBody.
  ///
  /// In en, this message translates to:
  /// **'Workout goal complete: {kcal} kcal and {minutes} min.'**
  String woNotifGoalBody(int kcal, int minutes);

  /// No description provided for @woNotifForegroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Synthese workout tracking'**
  String get woNotifForegroundTitle;

  /// No description provided for @woNotifForegroundBody.
  ///
  /// In en, this message translates to:
  /// **'Tracking your {mode} in background'**
  String woNotifForegroundBody(String mode);

  /// No description provided for @woSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search workouts...'**
  String get woSearchHint;

  /// No description provided for @woSignInHistory.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view history.'**
  String get woSignInHistory;

  /// No description provided for @woNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No workout history yet.'**
  String get woNoHistory;

  /// No description provided for @woNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No workouts match your search.'**
  String get woNoMatch;

  /// No description provided for @woDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete workout?'**
  String get woDeleteTitle;

  /// No description provided for @woDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This workout session will be removed from your history.'**
  String get woDeleteBody;

  /// No description provided for @woWeatherLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load weather'**
  String get woWeatherLoadError;

  /// No description provided for @authGoogleNoToken.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in did not return an auth token.'**
  String get authGoogleNoToken;

  /// No description provided for @authGoogleFailedCode.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In failed ({code})'**
  String authGoogleFailedCode(String code);

  /// No description provided for @authGoogleAndroidConfig.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In Android config is incomplete. Add SHA-1/SHA-256 for this app in Firebase, enable Google provider, then download the updated google-services.json.'**
  String get authGoogleAndroidConfig;

  /// No description provided for @authGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In failed'**
  String get authGoogleFailed;

  /// No description provided for @authGoogleFailedType.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In failed ({type}).'**
  String authGoogleFailedType(String type);

  /// No description provided for @authContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueGoogle;

  /// No description provided for @loginErrEnterCredentials.
  ///
  /// In en, this message translates to:
  /// **'Please enter email and password'**
  String get loginErrEnterCredentials;

  /// No description provided for @loginErrVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email before logging in.'**
  String get loginErrVerifyEmail;

  /// No description provided for @loginErrLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginErrLoginFailed;

  /// No description provided for @loginErrResetEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email above to reset password.'**
  String get loginErrResetEnterEmail;

  /// No description provided for @loginMsgResetSent.
  ///
  /// In en, this message translates to:
  /// **'Reset email sent! Check your inbox.'**
  String get loginMsgResetSent;

  /// No description provided for @loginErrResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email.'**
  String get loginErrResetFailed;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginTitle;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgot;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get loginNoAccount;

  /// No description provided for @loginSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get loginSignUp;

  /// No description provided for @signupErrFillFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get signupErrFillFields;

  /// No description provided for @signupErrPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get signupErrPasswordMismatch;

  /// No description provided for @signupErrFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed'**
  String get signupErrFailed;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signupTitle;

  /// No description provided for @signupConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get signupConfirmPassword;

  /// No description provided for @signupCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupCreateAccount;

  /// No description provided for @signupHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get signupHaveAccount;

  /// No description provided for @verifyResent.
  ///
  /// In en, this message translates to:
  /// **'Verification email resent!'**
  String get verifyResent;

  /// No description provided for @verifyWaitResend.
  ///
  /// In en, this message translates to:
  /// **'Wait a moment before resending.'**
  String get verifyWaitResend;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyTitle;

  /// No description provided for @verifyBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to your email.\nPlease click it to continue.'**
  String get verifyBody;

  /// No description provided for @verifyChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for verification...'**
  String get verifyChecking;

  /// No description provided for @verifySpamNotice.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find the email? Check your spam or junk folder.'**
  String get verifySpamNotice;

  /// No description provided for @verifyResendButton.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get verifyResendButton;

  /// No description provided for @verifyVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified!'**
  String get verifyVerified;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @moreSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search sections...'**
  String get moreSearchHint;

  /// No description provided for @moreNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get moreNoResults;

  /// No description provided for @moreMindfulness.
  ///
  /// In en, this message translates to:
  /// **'Mindfulness'**
  String get moreMindfulness;

  /// No description provided for @moreFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get moreFinance;

  /// No description provided for @moreCycles.
  ///
  /// In en, this message translates to:
  /// **'Cycles'**
  String get moreCycles;

  /// No description provided for @startSignUp.
  ///
  /// In en, this message translates to:
  /// **'Continue with Sign Up'**
  String get startSignUp;

  /// No description provided for @startSignIn.
  ///
  /// In en, this message translates to:
  /// **'Continue with Sign In'**
  String get startSignIn;

  /// No description provided for @startGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get startGuest;

  /// No description provided for @startTestingNote.
  ///
  /// In en, this message translates to:
  /// **'For testing only — data may be reset at any time.'**
  String get startTestingNote;

  /// No description provided for @startLegalPrefix.
  ///
  /// In en, this message translates to:
  /// **'By pressing Continue you agree with our\n'**
  String get startLegalPrefix;

  /// No description provided for @startPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'privacy policy'**
  String get startPrivacyPolicy;

  /// No description provided for @startAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get startAnd;

  /// No description provided for @startTerms.
  ///
  /// In en, this message translates to:
  /// **'terms and conditions'**
  String get startTerms;

  /// No description provided for @startAnonFailed.
  ///
  /// In en, this message translates to:
  /// **'Anonymous sign-in failed'**
  String get startAnonFailed;

  /// No description provided for @startGuestFailed.
  ///
  /// In en, this message translates to:
  /// **'Guest access failed: {error}'**
  String startGuestFailed(String error);

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutCheckForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get aboutCheckForUpdates;

  /// No description provided for @updateReadyRestart.
  ///
  /// In en, this message translates to:
  /// **'Update downloaded — restart to install'**
  String get updateReadyRestart;

  /// No description provided for @updateRestartAction.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get updateRestartAction;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the latest version'**
  String get updateUpToDate;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates'**
  String get updateCheckFailed;

  /// No description provided for @aboutSecDeveloper.
  ///
  /// In en, this message translates to:
  /// **'DEVELOPER'**
  String get aboutSecDeveloper;

  /// No description provided for @aboutDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get aboutDeveloper;

  /// No description provided for @aboutSecLegal.
  ///
  /// In en, this message translates to:
  /// **'LEGAL'**
  String get aboutSecLegal;

  /// No description provided for @aboutPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get aboutPrivacyPolicy;

  /// No description provided for @aboutTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get aboutTermsAndConditions;

  /// No description provided for @aboutSecPermissions.
  ///
  /// In en, this message translates to:
  /// **'PERMISSIONS'**
  String get aboutSecPermissions;

  /// No description provided for @aboutPermNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get aboutPermNotifications;

  /// No description provided for @aboutPermLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get aboutPermLocation;

  /// No description provided for @aboutPermActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity Recognition'**
  String get aboutPermActivity;

  /// No description provided for @aboutPermCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get aboutPermCamera;

  /// No description provided for @aboutPermPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos & Media'**
  String get aboutPermPhotos;

  /// No description provided for @aboutSecContact.
  ///
  /// In en, this message translates to:
  /// **'CONTACT THE DEVELOPER'**
  String get aboutSecContact;

  /// No description provided for @aboutEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get aboutEmail;

  /// No description provided for @aboutMadeWith.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️'**
  String get aboutMadeWith;

  /// No description provided for @metricEnterValid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid {label}.'**
  String metricEnterValid(String label);

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get commonSaving;

  /// No description provided for @commonSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get commonSaved;

  /// No description provided for @mrTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning Readiness'**
  String get mrTitle;

  /// No description provided for @mrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling this morning?'**
  String get mrSubtitle;

  /// No description provided for @mrLogged.
  ///
  /// In en, this message translates to:
  /// **'Morning readiness logged'**
  String get mrLogged;

  /// No description provided for @mrSleepQuality.
  ///
  /// In en, this message translates to:
  /// **'Sleep Quality'**
  String get mrSleepQuality;

  /// No description provided for @mrEnergyLevel.
  ///
  /// In en, this message translates to:
  /// **'Energy Level'**
  String get mrEnergyLevel;

  /// No description provided for @mrStressLevel.
  ///
  /// In en, this message translates to:
  /// **'Stress Level'**
  String get mrStressLevel;

  /// No description provided for @mrSleepPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get mrSleepPoor;

  /// No description provided for @mrSleepFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get mrSleepFair;

  /// No description provided for @mrSleepOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get mrSleepOkay;

  /// No description provided for @mrSleepGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get mrSleepGood;

  /// No description provided for @mrSleepGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get mrSleepGreat;

  /// No description provided for @mrEnergyExhausted.
  ///
  /// In en, this message translates to:
  /// **'Exhausted'**
  String get mrEnergyExhausted;

  /// No description provided for @mrEnergyLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get mrEnergyLow;

  /// No description provided for @mrEnergyModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get mrEnergyModerate;

  /// No description provided for @mrEnergyHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get mrEnergyHigh;

  /// No description provided for @mrEnergyEnergized.
  ///
  /// In en, this message translates to:
  /// **'Energized'**
  String get mrEnergyEnergized;

  /// No description provided for @mrStressOverwhelming.
  ///
  /// In en, this message translates to:
  /// **'Overwhelming'**
  String get mrStressOverwhelming;

  /// No description provided for @mrStressHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get mrStressHigh;

  /// No description provided for @mrStressModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get mrStressModerate;

  /// No description provided for @mrStressLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get mrStressLow;

  /// No description provided for @mrStressMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get mrStressMinimal;

  /// No description provided for @moodHowFeeling.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling?'**
  String get moodHowFeeling;

  /// No description provided for @moodLogFor.
  ///
  /// In en, this message translates to:
  /// **'Log for {time}'**
  String moodLogFor(String time);

  /// No description provided for @moodYoureFeeling.
  ///
  /// In en, this message translates to:
  /// **'You\'re feeling'**
  String get moodYoureFeeling;

  /// No description provided for @moodScaleUnpleasant.
  ///
  /// In en, this message translates to:
  /// **'Unpleasant'**
  String get moodScaleUnpleasant;

  /// No description provided for @moodScalePleasant.
  ///
  /// In en, this message translates to:
  /// **'Pleasant'**
  String get moodScalePleasant;

  /// No description provided for @moodNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get moodNext;

  /// No description provided for @moodDescribeFeeling.
  ///
  /// In en, this message translates to:
  /// **'Describe your feeling'**
  String get moodDescribeFeeling;

  /// No description provided for @moodWhatDescribes.
  ///
  /// In en, this message translates to:
  /// **'What best describes this feeling?'**
  String get moodWhatDescribes;

  /// No description provided for @moodFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get moodFinish;

  /// No description provided for @moodLogged.
  ///
  /// In en, this message translates to:
  /// **'Mood logged'**
  String get moodLogged;

  /// No description provided for @moodLoggedOverlay.
  ///
  /// In en, this message translates to:
  /// **'Logged'**
  String get moodLoggedOverlay;

  /// No description provided for @moodLblVeryUnpleasant.
  ///
  /// In en, this message translates to:
  /// **'Very Unpleasant'**
  String get moodLblVeryUnpleasant;

  /// No description provided for @moodLblUnpleasant.
  ///
  /// In en, this message translates to:
  /// **'Unpleasant'**
  String get moodLblUnpleasant;

  /// No description provided for @moodLblSlightlyUnpleasant.
  ///
  /// In en, this message translates to:
  /// **'Slightly Unpleasant'**
  String get moodLblSlightlyUnpleasant;

  /// No description provided for @moodLblNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get moodLblNeutral;

  /// No description provided for @moodLblSlightlyPleasant.
  ///
  /// In en, this message translates to:
  /// **'Slightly Pleasant'**
  String get moodLblSlightlyPleasant;

  /// No description provided for @moodLblPleasant.
  ///
  /// In en, this message translates to:
  /// **'Pleasant'**
  String get moodLblPleasant;

  /// No description provided for @moodLblVeryPleasant.
  ///
  /// In en, this message translates to:
  /// **'Very Pleasant'**
  String get moodLblVeryPleasant;

  /// No description provided for @moodDescVeryUnpleasant.
  ///
  /// In en, this message translates to:
  /// **'It\'s rough right now. Give yourself grace — you\'re doing what you can.'**
  String get moodDescVeryUnpleasant;

  /// No description provided for @moodDescUnpleasant.
  ///
  /// In en, this message translates to:
  /// **'Things feel heavy. Take it one step at a time.'**
  String get moodDescUnpleasant;

  /// No description provided for @moodDescSlightlyUnpleasant.
  ///
  /// In en, this message translates to:
  /// **'A little off-track. Not great, but you\'re hanging in there.'**
  String get moodDescSlightlyUnpleasant;

  /// No description provided for @moodDescNeutral.
  ///
  /// In en, this message translates to:
  /// **'Balanced and centered. Ready for what\'s next.'**
  String get moodDescNeutral;

  /// No description provided for @moodDescSlightlyPleasant.
  ///
  /// In en, this message translates to:
  /// **'Doing alright! A steady, positive energy is building.'**
  String get moodDescSlightlyPleasant;

  /// No description provided for @moodDescPleasant.
  ///
  /// In en, this message translates to:
  /// **'Feeling solid and on track. You\'ve got a good flow going.'**
  String get moodDescPleasant;

  /// No description provided for @moodDescVeryPleasant.
  ///
  /// In en, this message translates to:
  /// **'Absolutely great! You\'re in peak form and feeling energized.'**
  String get moodDescVeryPleasant;

  /// No description provided for @moodFeelAngry.
  ///
  /// In en, this message translates to:
  /// **'Angry'**
  String get moodFeelAngry;

  /// No description provided for @moodFeelAnxious.
  ///
  /// In en, this message translates to:
  /// **'Anxious'**
  String get moodFeelAnxious;

  /// No description provided for @moodFeelScared.
  ///
  /// In en, this message translates to:
  /// **'Scared'**
  String get moodFeelScared;

  /// No description provided for @moodFeelOverwhelmed.
  ///
  /// In en, this message translates to:
  /// **'Overwhelmed'**
  String get moodFeelOverwhelmed;

  /// No description provided for @moodFeelAshamed.
  ///
  /// In en, this message translates to:
  /// **'Ashamed'**
  String get moodFeelAshamed;

  /// No description provided for @moodFeelDevastated.
  ///
  /// In en, this message translates to:
  /// **'Devastated'**
  String get moodFeelDevastated;

  /// No description provided for @moodFeelPanicked.
  ///
  /// In en, this message translates to:
  /// **'Panicked'**
  String get moodFeelPanicked;

  /// No description provided for @moodFeelHopeless.
  ///
  /// In en, this message translates to:
  /// **'Hopeless'**
  String get moodFeelHopeless;

  /// No description provided for @moodFeelFurious.
  ///
  /// In en, this message translates to:
  /// **'Furious'**
  String get moodFeelFurious;

  /// No description provided for @moodFeelTerrified.
  ///
  /// In en, this message translates to:
  /// **'Terrified'**
  String get moodFeelTerrified;

  /// No description provided for @moodFeelDisgusted.
  ///
  /// In en, this message translates to:
  /// **'Disgusted'**
  String get moodFeelDisgusted;

  /// No description provided for @moodFeelResentful.
  ///
  /// In en, this message translates to:
  /// **'Resentful'**
  String get moodFeelResentful;

  /// No description provided for @moodFeelMiserable.
  ///
  /// In en, this message translates to:
  /// **'Miserable'**
  String get moodFeelMiserable;

  /// No description provided for @moodFeelFrustrated.
  ///
  /// In en, this message translates to:
  /// **'Frustrated'**
  String get moodFeelFrustrated;

  /// No description provided for @moodFeelWorried.
  ///
  /// In en, this message translates to:
  /// **'Worried'**
  String get moodFeelWorried;

  /// No description provided for @moodFeelSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get moodFeelSad;

  /// No description provided for @moodFeelStressed.
  ///
  /// In en, this message translates to:
  /// **'Stressed'**
  String get moodFeelStressed;

  /// No description provided for @moodFeelLonely.
  ///
  /// In en, this message translates to:
  /// **'Lonely'**
  String get moodFeelLonely;

  /// No description provided for @moodFeelDisappointed.
  ///
  /// In en, this message translates to:
  /// **'Disappointed'**
  String get moodFeelDisappointed;

  /// No description provided for @moodFeelInsecure.
  ///
  /// In en, this message translates to:
  /// **'Insecure'**
  String get moodFeelInsecure;

  /// No description provided for @moodFeelIrritated.
  ///
  /// In en, this message translates to:
  /// **'Irritated'**
  String get moodFeelIrritated;

  /// No description provided for @moodFeelGuilty.
  ///
  /// In en, this message translates to:
  /// **'Guilty'**
  String get moodFeelGuilty;

  /// No description provided for @moodFeelHurt.
  ///
  /// In en, this message translates to:
  /// **'Hurt'**
  String get moodFeelHurt;

  /// No description provided for @moodFeelNervous.
  ///
  /// In en, this message translates to:
  /// **'Nervous'**
  String get moodFeelNervous;

  /// No description provided for @moodFeelJealous.
  ///
  /// In en, this message translates to:
  /// **'Jealous'**
  String get moodFeelJealous;

  /// No description provided for @moodFeelEmbarrassed.
  ///
  /// In en, this message translates to:
  /// **'Embarrassed'**
  String get moodFeelEmbarrassed;

  /// No description provided for @moodFeelTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get moodFeelTired;

  /// No description provided for @moodFeelBored.
  ///
  /// In en, this message translates to:
  /// **'Bored'**
  String get moodFeelBored;

  /// No description provided for @moodFeelUneasy.
  ///
  /// In en, this message translates to:
  /// **'Uneasy'**
  String get moodFeelUneasy;

  /// No description provided for @moodFeelDistracted.
  ///
  /// In en, this message translates to:
  /// **'Distracted'**
  String get moodFeelDistracted;

  /// No description provided for @moodFeelRestless.
  ///
  /// In en, this message translates to:
  /// **'Restless'**
  String get moodFeelRestless;

  /// No description provided for @moodFeelApathetic.
  ///
  /// In en, this message translates to:
  /// **'Apathetic'**
  String get moodFeelApathetic;

  /// No description provided for @moodFeelDrained.
  ///
  /// In en, this message translates to:
  /// **'Drained'**
  String get moodFeelDrained;

  /// No description provided for @moodFeelImpatient.
  ///
  /// In en, this message translates to:
  /// **'Impatient'**
  String get moodFeelImpatient;

  /// No description provided for @moodFeelDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get moodFeelDisconnected;

  /// No description provided for @moodFeelSluggish.
  ///
  /// In en, this message translates to:
  /// **'Sluggish'**
  String get moodFeelSluggish;

  /// No description provided for @moodFeelUncertain.
  ///
  /// In en, this message translates to:
  /// **'Uncertain'**
  String get moodFeelUncertain;

  /// No description provided for @moodFeelUnfocused.
  ///
  /// In en, this message translates to:
  /// **'Unfocused'**
  String get moodFeelUnfocused;

  /// No description provided for @moodFeelMelancholic.
  ///
  /// In en, this message translates to:
  /// **'Melancholic'**
  String get moodFeelMelancholic;

  /// No description provided for @moodFeelContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get moodFeelContent;

  /// No description provided for @moodFeelCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get moodFeelCalm;

  /// No description provided for @moodFeelPeaceful.
  ///
  /// In en, this message translates to:
  /// **'Peaceful'**
  String get moodFeelPeaceful;

  /// No description provided for @moodFeelIndifferent.
  ///
  /// In en, this message translates to:
  /// **'Indifferent'**
  String get moodFeelIndifferent;

  /// No description provided for @moodFeelSteady.
  ///
  /// In en, this message translates to:
  /// **'Steady'**
  String get moodFeelSteady;

  /// No description provided for @moodFeelBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get moodFeelBalanced;

  /// No description provided for @moodFeelAccepting.
  ///
  /// In en, this message translates to:
  /// **'Accepting'**
  String get moodFeelAccepting;

  /// No description provided for @moodFeelPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get moodFeelPresent;

  /// No description provided for @moodFeelMellow.
  ///
  /// In en, this message translates to:
  /// **'Mellow'**
  String get moodFeelMellow;

  /// No description provided for @moodFeelComposed.
  ///
  /// In en, this message translates to:
  /// **'Composed'**
  String get moodFeelComposed;

  /// No description provided for @moodFeelGrounded.
  ///
  /// In en, this message translates to:
  /// **'Grounded'**
  String get moodFeelGrounded;

  /// No description provided for @moodFeelReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get moodFeelReserved;

  /// No description provided for @moodFeelThoughtful.
  ///
  /// In en, this message translates to:
  /// **'Thoughtful'**
  String get moodFeelThoughtful;

  /// No description provided for @moodFeelHopeful.
  ///
  /// In en, this message translates to:
  /// **'Hopeful'**
  String get moodFeelHopeful;

  /// No description provided for @moodFeelRelaxed.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get moodFeelRelaxed;

  /// No description provided for @moodFeelFocused.
  ///
  /// In en, this message translates to:
  /// **'Focused'**
  String get moodFeelFocused;

  /// No description provided for @moodFeelGrateful.
  ///
  /// In en, this message translates to:
  /// **'Grateful'**
  String get moodFeelGrateful;

  /// No description provided for @moodFeelOptimistic.
  ///
  /// In en, this message translates to:
  /// **'Optimistic'**
  String get moodFeelOptimistic;

  /// No description provided for @moodFeelCurious.
  ///
  /// In en, this message translates to:
  /// **'Curious'**
  String get moodFeelCurious;

  /// No description provided for @moodFeelRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Refreshed'**
  String get moodFeelRefreshed;

  /// No description provided for @moodFeelRelieved.
  ///
  /// In en, this message translates to:
  /// **'Relieved'**
  String get moodFeelRelieved;

  /// No description provided for @moodFeelComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get moodFeelComfortable;

  /// No description provided for @moodFeelOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get moodFeelOpen;

  /// No description provided for @moodFeelEncouraged.
  ///
  /// In en, this message translates to:
  /// **'Encouraged'**
  String get moodFeelEncouraged;

  /// No description provided for @moodFeelInterested.
  ///
  /// In en, this message translates to:
  /// **'Interested'**
  String get moodFeelInterested;

  /// No description provided for @moodFeelSerene.
  ///
  /// In en, this message translates to:
  /// **'Serene'**
  String get moodFeelSerene;

  /// No description provided for @moodFeelHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get moodFeelHappy;

  /// No description provided for @moodFeelConfident.
  ///
  /// In en, this message translates to:
  /// **'Confident'**
  String get moodFeelConfident;

  /// No description provided for @moodFeelEnergized.
  ///
  /// In en, this message translates to:
  /// **'Energized'**
  String get moodFeelEnergized;

  /// No description provided for @moodFeelMotivated.
  ///
  /// In en, this message translates to:
  /// **'Motivated'**
  String get moodFeelMotivated;

  /// No description provided for @moodFeelJoyful.
  ///
  /// In en, this message translates to:
  /// **'Joyful'**
  String get moodFeelJoyful;

  /// No description provided for @moodFeelProud.
  ///
  /// In en, this message translates to:
  /// **'Proud'**
  String get moodFeelProud;

  /// No description provided for @moodFeelFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Fulfilled'**
  String get moodFeelFulfilled;

  /// No description provided for @moodFeelCheerful.
  ///
  /// In en, this message translates to:
  /// **'Cheerful'**
  String get moodFeelCheerful;

  /// No description provided for @moodFeelPlayful.
  ///
  /// In en, this message translates to:
  /// **'Playful'**
  String get moodFeelPlayful;

  /// No description provided for @moodFeelEmpowered.
  ///
  /// In en, this message translates to:
  /// **'Empowered'**
  String get moodFeelEmpowered;

  /// No description provided for @moodFeelCreative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get moodFeelCreative;

  /// No description provided for @moodFeelAppreciated.
  ///
  /// In en, this message translates to:
  /// **'Appreciated'**
  String get moodFeelAppreciated;

  /// No description provided for @moodFeelLoving.
  ///
  /// In en, this message translates to:
  /// **'Loving'**
  String get moodFeelLoving;

  /// No description provided for @moodFeelAmazed.
  ///
  /// In en, this message translates to:
  /// **'Amazed'**
  String get moodFeelAmazed;

  /// No description provided for @moodFeelExcited.
  ///
  /// In en, this message translates to:
  /// **'Excited'**
  String get moodFeelExcited;

  /// No description provided for @moodFeelSurprised.
  ///
  /// In en, this message translates to:
  /// **'Surprised'**
  String get moodFeelSurprised;

  /// No description provided for @moodFeelPassionate.
  ///
  /// In en, this message translates to:
  /// **'Passionate'**
  String get moodFeelPassionate;

  /// No description provided for @moodFeelInspired.
  ///
  /// In en, this message translates to:
  /// **'Inspired'**
  String get moodFeelInspired;

  /// No description provided for @moodFeelEuphoric.
  ///
  /// In en, this message translates to:
  /// **'Euphoric'**
  String get moodFeelEuphoric;

  /// No description provided for @moodFeelThrilled.
  ///
  /// In en, this message translates to:
  /// **'Thrilled'**
  String get moodFeelThrilled;

  /// No description provided for @moodFeelElated.
  ///
  /// In en, this message translates to:
  /// **'Elated'**
  String get moodFeelElated;

  /// No description provided for @moodFeelEcstatic.
  ///
  /// In en, this message translates to:
  /// **'Ecstatic'**
  String get moodFeelEcstatic;

  /// No description provided for @moodFeelBlissful.
  ///
  /// In en, this message translates to:
  /// **'Blissful'**
  String get moodFeelBlissful;

  /// No description provided for @moodFeelRadiant.
  ///
  /// In en, this message translates to:
  /// **'Radiant'**
  String get moodFeelRadiant;

  /// No description provided for @moodFeelAlive.
  ///
  /// In en, this message translates to:
  /// **'Alive'**
  String get moodFeelAlive;

  /// No description provided for @breatheTitle.
  ///
  /// In en, this message translates to:
  /// **'Breathing Exercise'**
  String get breatheTitle;

  /// No description provided for @breatheBox.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get breatheBox;

  /// No description provided for @breatheSimple.
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get breatheSimple;

  /// No description provided for @breatheInhale.
  ///
  /// In en, this message translates to:
  /// **'Breathe In'**
  String get breatheInhale;

  /// No description provided for @breatheHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get breatheHold;

  /// No description provided for @breatheExhale.
  ///
  /// In en, this message translates to:
  /// **'Breathe Out'**
  String get breatheExhale;

  /// No description provided for @breatheTapStart.
  ///
  /// In en, this message translates to:
  /// **'Tap Start'**
  String get breatheTapStart;

  /// No description provided for @breathePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get breathePause;

  /// No description provided for @breatheStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get breatheStart;

  /// No description provided for @acctLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Log additional info'**
  String get acctLogTitle;

  /// No description provided for @acctLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These are your current readings, not your goals.'**
  String get acctLogSubtitle;

  /// No description provided for @acctLogHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get acctLogHeight;

  /// No description provided for @acctLogWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get acctLogWeight;

  /// No description provided for @acctLogSleep.
  ///
  /// In en, this message translates to:
  /// **'Average sleep duration'**
  String get acctLogSleep;

  /// No description provided for @acctLogWater.
  ///
  /// In en, this message translates to:
  /// **'Daily water intake'**
  String get acctLogWater;

  /// No description provided for @acctLogAthleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Athlete profile'**
  String get acctLogAthleteProfile;

  /// No description provided for @acctLogAthleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your training so we can tailor your experience.'**
  String get acctLogAthleteSubtitle;

  /// No description provided for @acctLogTypeOfAthlete.
  ///
  /// In en, this message translates to:
  /// **'Type of athlete'**
  String get acctLogTypeOfAthlete;

  /// No description provided for @acctLogExperienceLevel.
  ///
  /// In en, this message translates to:
  /// **'Experience level'**
  String get acctLogExperienceLevel;

  /// No description provided for @acctLogSportsProfile.
  ///
  /// In en, this message translates to:
  /// **'Sports profile'**
  String get acctLogSportsProfile;

  /// No description provided for @acctLogSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all you train in'**
  String get acctLogSelectAll;

  /// No description provided for @acctLogTypeStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get acctLogTypeStudent;

  /// No description provided for @acctLogTypeClub.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get acctLogTypeClub;

  /// No description provided for @acctLogTypeCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get acctLogTypeCasual;

  /// No description provided for @acctLogTypeCompetitive.
  ///
  /// In en, this message translates to:
  /// **'Competitive'**
  String get acctLogTypeCompetitive;

  /// No description provided for @acctLogExpBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get acctLogExpBeginner;

  /// No description provided for @acctLogExpIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get acctLogExpIntermediate;

  /// No description provided for @acctLogExpAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get acctLogExpAdvanced;

  /// No description provided for @acctLogSportFootball.
  ///
  /// In en, this message translates to:
  /// **'Football'**
  String get acctLogSportFootball;

  /// No description provided for @acctLogSportTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get acctLogSportTrack;

  /// No description provided for @acctLogSportCricket.
  ///
  /// In en, this message translates to:
  /// **'Cricket'**
  String get acctLogSportCricket;

  /// No description provided for @acctLogSportBasketball.
  ///
  /// In en, this message translates to:
  /// **'Basketball'**
  String get acctLogSportBasketball;

  /// No description provided for @acctLogSportMotorSport.
  ///
  /// In en, this message translates to:
  /// **'Motor sport'**
  String get acctLogSportMotorSport;

  /// No description provided for @acctLogSportGolf.
  ///
  /// In en, this message translates to:
  /// **'Golf'**
  String get acctLogSportGolf;

  /// No description provided for @acctLogSportBadminton.
  ///
  /// In en, this message translates to:
  /// **'Badminton'**
  String get acctLogSportBadminton;

  /// No description provided for @acctLogSportTennis.
  ///
  /// In en, this message translates to:
  /// **'Tennis'**
  String get acctLogSportTennis;

  /// No description provided for @acctLogSportGymnastics.
  ///
  /// In en, this message translates to:
  /// **'Gymnastics'**
  String get acctLogSportGymnastics;

  /// No description provided for @acctLogSportVolleyball.
  ///
  /// In en, this message translates to:
  /// **'Volleyball'**
  String get acctLogSportVolleyball;

  /// No description provided for @acctLogSportMartialArts.
  ///
  /// In en, this message translates to:
  /// **'Martial arts'**
  String get acctLogSportMartialArts;

  /// No description provided for @acctLogSportSwimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get acctLogSportSwimming;

  /// No description provided for @acctLogSportCycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get acctLogSportCycling;

  /// No description provided for @acctLogSportRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get acctLogSportRunning;

  /// No description provided for @acctLogSportRugby.
  ///
  /// In en, this message translates to:
  /// **'Rugby'**
  String get acctLogSportRugby;

  /// No description provided for @acctLogSportHockey.
  ///
  /// In en, this message translates to:
  /// **'Hockey'**
  String get acctLogSportHockey;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @dlogFlowLevel.
  ///
  /// In en, this message translates to:
  /// **'FLOW LEVEL'**
  String get dlogFlowLevel;

  /// No description provided for @dlogSymptoms.
  ///
  /// In en, this message translates to:
  /// **'SYMPTOMS'**
  String get dlogSymptoms;

  /// No description provided for @dlogMood.
  ///
  /// In en, this message translates to:
  /// **'MOOD'**
  String get dlogMood;

  /// No description provided for @dlogCervicalMucus.
  ///
  /// In en, this message translates to:
  /// **'CERVICAL MUCUS'**
  String get dlogCervicalMucus;

  /// No description provided for @dlogFlowNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get dlogFlowNone;

  /// No description provided for @dlogFlowSpotting.
  ///
  /// In en, this message translates to:
  /// **'Spotting'**
  String get dlogFlowSpotting;

  /// No description provided for @dlogFlowLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get dlogFlowLight;

  /// No description provided for @dlogFlowMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get dlogFlowMedium;

  /// No description provided for @dlogFlowHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get dlogFlowHeavy;

  /// No description provided for @dlogFlowVeryHeavy.
  ///
  /// In en, this message translates to:
  /// **'Very Heavy'**
  String get dlogFlowVeryHeavy;

  /// No description provided for @dlogSympCrampsMild.
  ///
  /// In en, this message translates to:
  /// **'Cramps (mild)'**
  String get dlogSympCrampsMild;

  /// No description provided for @dlogSympCrampsSevere.
  ///
  /// In en, this message translates to:
  /// **'Cramps (severe)'**
  String get dlogSympCrampsSevere;

  /// No description provided for @dlogSympBloating.
  ///
  /// In en, this message translates to:
  /// **'Bloating'**
  String get dlogSympBloating;

  /// No description provided for @dlogSympBreastTenderness.
  ///
  /// In en, this message translates to:
  /// **'Breast tenderness'**
  String get dlogSympBreastTenderness;

  /// No description provided for @dlogSympHeadache.
  ///
  /// In en, this message translates to:
  /// **'Headache'**
  String get dlogSympHeadache;

  /// No description provided for @dlogSympFatigue.
  ///
  /// In en, this message translates to:
  /// **'Fatigue'**
  String get dlogSympFatigue;

  /// No description provided for @dlogSympLowerBackPain.
  ///
  /// In en, this message translates to:
  /// **'Lower back pain'**
  String get dlogSympLowerBackPain;

  /// No description provided for @dlogSympNausea.
  ///
  /// In en, this message translates to:
  /// **'Nausea'**
  String get dlogSympNausea;

  /// No description provided for @dlogSympAcne.
  ///
  /// In en, this message translates to:
  /// **'Acne'**
  String get dlogSympAcne;

  /// No description provided for @dlogSympFoodCravings.
  ///
  /// In en, this message translates to:
  /// **'Food cravings'**
  String get dlogSympFoodCravings;

  /// No description provided for @dlogMoodHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get dlogMoodHappy;

  /// No description provided for @dlogMoodCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get dlogMoodCalm;

  /// No description provided for @dlogMoodConfident.
  ///
  /// In en, this message translates to:
  /// **'Confident'**
  String get dlogMoodConfident;

  /// No description provided for @dlogMoodIrritable.
  ///
  /// In en, this message translates to:
  /// **'Irritable'**
  String get dlogMoodIrritable;

  /// No description provided for @dlogMoodAnxious.
  ///
  /// In en, this message translates to:
  /// **'Anxious'**
  String get dlogMoodAnxious;

  /// No description provided for @dlogMoodSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get dlogMoodSad;

  /// No description provided for @dlogMoodSensitive.
  ///
  /// In en, this message translates to:
  /// **'Sensitive'**
  String get dlogMoodSensitive;

  /// No description provided for @dlogMoodStressed.
  ///
  /// In en, this message translates to:
  /// **'Stressed'**
  String get dlogMoodStressed;

  /// No description provided for @dlogMoodBrainFog.
  ///
  /// In en, this message translates to:
  /// **'Brain fog'**
  String get dlogMoodBrainFog;

  /// No description provided for @dlogMoodTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get dlogMoodTired;

  /// No description provided for @dlogMucusDry.
  ///
  /// In en, this message translates to:
  /// **'Dry'**
  String get dlogMucusDry;

  /// No description provided for @dlogMucusSticky.
  ///
  /// In en, this message translates to:
  /// **'Sticky'**
  String get dlogMucusSticky;

  /// No description provided for @dlogMucusCreamy.
  ///
  /// In en, this message translates to:
  /// **'Creamy'**
  String get dlogMucusCreamy;

  /// No description provided for @dlogMucusEggWhite.
  ///
  /// In en, this message translates to:
  /// **'Egg white'**
  String get dlogMucusEggWhite;

  /// No description provided for @dlogMucusWatery.
  ///
  /// In en, this message translates to:
  /// **'Watery'**
  String get dlogMucusWatery;

  /// No description provided for @dlogEarlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Did your period start early?'**
  String get dlogEarlyTitle;

  /// No description provided for @dlogEarlySpotting.
  ///
  /// In en, this message translates to:
  /// **'You logged spotting. Is this the start of a new period?'**
  String get dlogEarlySpotting;

  /// No description provided for @dlogEarlyBleeding.
  ///
  /// In en, this message translates to:
  /// **'You logged bleeding, but your period isn\'t due yet.'**
  String get dlogEarlyBleeding;

  /// No description provided for @dlogNoJustSpotting.
  ///
  /// In en, this message translates to:
  /// **'No, just spotting'**
  String get dlogNoJustSpotting;

  /// No description provided for @dlogYesStarted.
  ///
  /// In en, this message translates to:
  /// **'Yes, it started'**
  String get dlogYesStarted;

  /// No description provided for @dlogDueTitle.
  ///
  /// In en, this message translates to:
  /// **'Did your period start?'**
  String get dlogDueTitle;

  /// No description provided for @dlogDueBody.
  ///
  /// In en, this message translates to:
  /// **'You logged spotting around the time your period is due. Is this the start of your period?'**
  String get dlogDueBody;

  /// No description provided for @dlogSaved.
  ///
  /// In en, this message translates to:
  /// **'Cycle log saved'**
  String get dlogSaved;

  /// No description provided for @dlogLoggedOverlay.
  ///
  /// In en, this message translates to:
  /// **'Logged'**
  String get dlogLoggedOverlay;

  /// No description provided for @dlogTodayPrefix.
  ///
  /// In en, this message translates to:
  /// **'Today, {date}'**
  String dlogTodayPrefix(String date);

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @accountDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get accountDeleteAccount;

  /// No description provided for @accountDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This will permanently delete all your data and cannot be undone.'**
  String get accountDeleteBody;

  /// No description provided for @accountErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get accountErrorTitle;

  /// No description provided for @accountDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account. Please try again or contact support.'**
  String get accountDeleteFailed;

  /// No description provided for @accountPhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get accountPhotoUpdated;

  /// No description provided for @accountPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo'**
  String get accountPhotoFailed;

  /// No description provided for @accountDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetailsTitle;

  /// No description provided for @accountHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Details'**
  String get accountHealthTitle;

  /// No description provided for @accountAthleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Athlete Details'**
  String get accountAthleteTitle;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get accountSettings;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get accountSignOut;

  /// No description provided for @accountNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get accountNotProvided;

  /// No description provided for @accountFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get accountFullName;

  /// No description provided for @accountDob.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get accountDob;

  /// No description provided for @accountCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get accountCountry;

  /// No description provided for @accountNoneSelected.
  ///
  /// In en, this message translates to:
  /// **'None selected'**
  String get accountNoneSelected;

  /// No description provided for @accountPhysicalStats.
  ///
  /// In en, this message translates to:
  /// **'PHYSICAL STATS'**
  String get accountPhysicalStats;

  /// No description provided for @accountAvgSleep.
  ///
  /// In en, this message translates to:
  /// **'Avg sleep'**
  String get accountAvgSleep;

  /// No description provided for @accountDailyWater.
  ///
  /// In en, this message translates to:
  /// **'Daily water'**
  String get accountDailyWater;

  /// No description provided for @accountMedical.
  ///
  /// In en, this message translates to:
  /// **'MEDICAL'**
  String get accountMedical;

  /// No description provided for @accountSupplements.
  ///
  /// In en, this message translates to:
  /// **'Supplements'**
  String get accountSupplements;

  /// No description provided for @accountYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get accountYes;

  /// No description provided for @accountNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get accountNone;

  /// No description provided for @accountDisabilities.
  ///
  /// In en, this message translates to:
  /// **'Disabilities'**
  String get accountDisabilities;

  /// No description provided for @accountInjuryHistory.
  ///
  /// In en, this message translates to:
  /// **'Injury History'**
  String get accountInjuryHistory;

  /// No description provided for @accountYourGoals.
  ///
  /// In en, this message translates to:
  /// **'YOUR GOALS'**
  String get accountYourGoals;

  /// No description provided for @accountSelectedGoals.
  ///
  /// In en, this message translates to:
  /// **'Selected goals'**
  String get accountSelectedGoals;

  /// No description provided for @accountProfile.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get accountProfile;

  /// No description provided for @accountSports.
  ///
  /// In en, this message translates to:
  /// **'SPORTS'**
  String get accountSports;

  /// No description provided for @accountLogAthleteInfo.
  ///
  /// In en, this message translates to:
  /// **'Log athlete info'**
  String get accountLogAthleteInfo;

  /// No description provided for @accountChangeTheme.
  ///
  /// In en, this message translates to:
  /// **'Change Theme'**
  String get accountChangeTheme;

  /// No description provided for @accountThemeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Theme colour updated'**
  String get accountThemeUpdated;

  /// No description provided for @accountAppearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get accountAppearance;

  /// No description provided for @accountSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get accountSystemDefault;

  /// No description provided for @accountFollowingSystem.
  ///
  /// In en, this message translates to:
  /// **'Following system theme'**
  String get accountFollowingSystem;

  /// No description provided for @accountLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get accountLightMode;

  /// No description provided for @accountLightModeOn.
  ///
  /// In en, this message translates to:
  /// **'Light mode on'**
  String get accountLightModeOn;

  /// No description provided for @accountDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get accountDarkMode;

  /// No description provided for @accountDarkModeOn.
  ///
  /// In en, this message translates to:
  /// **'Dark mode on'**
  String get accountDarkModeOn;

  /// No description provided for @accountPresets.
  ///
  /// In en, this message translates to:
  /// **'PRESETS'**
  String get accountPresets;

  /// No description provided for @accountCustomRgb.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM RGB'**
  String get accountCustomRgb;

  /// No description provided for @accountRgbError.
  ///
  /// In en, this message translates to:
  /// **'Enter values 0–255 for each channel'**
  String get accountRgbError;

  /// No description provided for @accountApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get accountApply;

  /// No description provided for @accountSupportDev.
  ///
  /// In en, this message translates to:
  /// **'Enjoying Synthese? Support development'**
  String get accountSupportDev;

  /// No description provided for @finDebts.
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get finDebts;

  /// No description provided for @finYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You Owe'**
  String get finYouOwe;

  /// No description provided for @finOwedToYou.
  ///
  /// In en, this message translates to:
  /// **'Owed to You'**
  String get finOwedToYou;

  /// No description provided for @finPaydownProgress.
  ///
  /// In en, this message translates to:
  /// **'Paydown Progress'**
  String get finPaydownProgress;

  /// No description provided for @finTapViewAllDebts.
  ///
  /// In en, this message translates to:
  /// **'Tap to view all debts'**
  String get finTapViewAllDebts;

  /// No description provided for @finTitle.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finTitle;

  /// No description provided for @finTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get finTransfer;

  /// No description provided for @finAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get finAddTransaction;

  /// No description provided for @finRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get finRecentTransactions;

  /// No description provided for @finTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get finTotalBalance;

  /// No description provided for @finNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get finNoTransactions;

  /// No description provided for @finNoMatching.
  ///
  /// In en, this message translates to:
  /// **'No matching transactions'**
  String get finNoMatching;

  /// No description provided for @finTapAddToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap \'Add Transaction\' to get started'**
  String get finTapAddToStart;

  /// No description provided for @finTryAdjustFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get finTryAdjustFilters;

  /// No description provided for @finUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get finUnknown;

  /// No description provided for @finSearchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search transactions...'**
  String get finSearchTransactions;

  /// No description provided for @finAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get finAllCategories;

  /// No description provided for @finOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get finOther;

  /// No description provided for @finOtherExpense.
  ///
  /// In en, this message translates to:
  /// **'Other (Expense)'**
  String get finOtherExpense;

  /// No description provided for @finOtherIncome.
  ///
  /// In en, this message translates to:
  /// **'Other (Income)'**
  String get finOtherIncome;

  /// No description provided for @finSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get finSelectCategory;

  /// No description provided for @finDeleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get finDeleteTransaction;

  /// No description provided for @finDeleteTransactionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction?'**
  String get finDeleteTransactionConfirm;

  /// No description provided for @finDebtDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Debt'**
  String get finDebtDeleteTitle;

  /// No description provided for @finDebtDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this debt? This action cannot be undone.'**
  String get finDebtDeleteConfirm;

  /// No description provided for @finDebtAddDebt.
  ///
  /// In en, this message translates to:
  /// **'Add Debt'**
  String get finDebtAddDebt;

  /// No description provided for @finDebtIOwe.
  ///
  /// In en, this message translates to:
  /// **'I Owe'**
  String get finDebtIOwe;

  /// No description provided for @finDebtOweMe.
  ///
  /// In en, this message translates to:
  /// **'Owe Me'**
  String get finDebtOweMe;

  /// No description provided for @finDebtSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view debts'**
  String get finDebtSignIn;

  /// No description provided for @finDebtPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get finDebtPaid;

  /// No description provided for @finDebtNoneYouOwe.
  ///
  /// In en, this message translates to:
  /// **'No debts you owe'**
  String get finDebtNoneYouOwe;

  /// No description provided for @finDebtNoneOwedToYou.
  ///
  /// In en, this message translates to:
  /// **'No debts owed to you'**
  String get finDebtNoneOwedToYou;

  /// No description provided for @finDebtTapAddOwe.
  ///
  /// In en, this message translates to:
  /// **'Tap \'Add Debt\' to track money you owe'**
  String get finDebtTapAddOwe;

  /// No description provided for @finDebtTapAddOwedToYou.
  ///
  /// In en, this message translates to:
  /// **'Tap \'Add Debt\' to track money owed to you'**
  String get finDebtTapAddOwedToYou;

  /// No description provided for @finDebtDeleted.
  ///
  /// In en, this message translates to:
  /// **'Debt deleted'**
  String get finDebtDeleted;

  /// No description provided for @finTrInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get finTrInvalidAmount;

  /// No description provided for @finTrSelectSource.
  ///
  /// In en, this message translates to:
  /// **'Please select a source account'**
  String get finTrSelectSource;

  /// No description provided for @finTrSelectDest.
  ///
  /// In en, this message translates to:
  /// **'Please select a destination account'**
  String get finTrSelectDest;

  /// No description provided for @finTrSameAccount.
  ///
  /// In en, this message translates to:
  /// **'Cannot transfer to the same account'**
  String get finTrSameAccount;

  /// No description provided for @finTrSourceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Source account not found'**
  String get finTrSourceNotFound;

  /// No description provided for @finTrInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Funds'**
  String get finTrInsufficient;

  /// No description provided for @finTrCompleted.
  ///
  /// In en, this message translates to:
  /// **'Transfer completed'**
  String get finTrCompleted;

  /// No description provided for @finTrFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to transfer funds'**
  String get finTrFailed;

  /// No description provided for @finTrFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get finTrFrom;

  /// No description provided for @finTrTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get finTrTo;

  /// No description provided for @finTrSelectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select account'**
  String get finTrSelectAccount;

  /// No description provided for @finTrSelectAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Account'**
  String get finTrSelectAccountTitle;

  /// No description provided for @finTxSelectAccount.
  ///
  /// In en, this message translates to:
  /// **'Please select an account'**
  String get finTxSelectAccount;

  /// No description provided for @finTxSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get finTxSelectCategory;

  /// No description provided for @finTxSaved.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved'**
  String get finTxSaved;

  /// No description provided for @finTxFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save transaction'**
  String get finTxFailed;

  /// No description provided for @finTxAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get finTxAccount;

  /// No description provided for @finTxNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get finTxNoteOptional;

  /// No description provided for @finTxAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get finTxAddExpense;

  /// No description provided for @finTxAddIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get finTxAddIncome;

  /// No description provided for @finTxExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get finTxExpense;

  /// No description provided for @finTxIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get finTxIncome;

  /// No description provided for @finTxNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts available'**
  String get finTxNoAccounts;

  /// No description provided for @finTxNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get finTxNoCategories;

  /// No description provided for @finTxCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get finTxCategory;

  /// No description provided for @finTxToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get finTxToday;

  /// No description provided for @finTxRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get finTxRecurring;

  /// No description provided for @finTxDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get finTxDaily;

  /// No description provided for @finTxWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get finTxWeekly;

  /// No description provided for @finTxMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get finTxMonthly;

  /// No description provided for @finTxAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note...'**
  String get finTxAddNote;

  /// No description provided for @finAddDebtEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get finAddDebtEnterTitle;

  /// No description provided for @finAddDebtValidInstallment.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid installment amount'**
  String get finAddDebtValidInstallment;

  /// No description provided for @finAddDebtInstallmentExceed.
  ///
  /// In en, this message translates to:
  /// **'Installment cannot exceed total amount'**
  String get finAddDebtInstallmentExceed;

  /// No description provided for @finAddDebtAdded.
  ///
  /// In en, this message translates to:
  /// **'Debt added'**
  String get finAddDebtAdded;

  /// No description provided for @finAddDebtFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save debt'**
  String get finAddDebtFailed;

  /// No description provided for @finAddDebtTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get finAddDebtTitleLabel;

  /// No description provided for @finAddDebtTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get finAddDebtTotalAmount;

  /// No description provided for @finAddDebtDueDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Due Date (optional)'**
  String get finAddDebtDueDateOptional;

  /// No description provided for @finAddDebtNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get finAddDebtNotesOptional;

  /// No description provided for @finAddDebtTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Car Loan, Credit Card Balance...'**
  String get finAddDebtTitleHint;

  /// No description provided for @finAddDebtNoDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get finAddDebtNoDueDate;

  /// No description provided for @finAddDebtInstallments.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get finAddDebtInstallments;

  /// No description provided for @finAddDebtInstallmentAmount.
  ///
  /// In en, this message translates to:
  /// **'Installment Amount'**
  String get finAddDebtInstallmentAmount;

  /// No description provided for @finAddDebtAddNotes.
  ///
  /// In en, this message translates to:
  /// **'Add notes...'**
  String get finAddDebtAddNotes;

  /// No description provided for @finInsForYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get finInsForYou;

  /// No description provided for @finInsDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get finInsDismiss;

  /// No description provided for @finInsSpendingSpikeTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending Spike'**
  String get finInsSpendingSpikeTitle;

  /// No description provided for @finInsSpendingSpikeBody.
  ///
  /// In en, this message translates to:
  /// **'You spent {percent}% more on {category} this month compared to last month.'**
  String finInsSpendingSpikeBody(String percent, String category);

  /// No description provided for @finInsBudgetAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Alert'**
  String get finInsBudgetAlertTitle;

  /// No description provided for @finInsBudgetAlertBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used {percent}% of your monthly budget with {days} days left.'**
  String finInsBudgetAlertBody(String percent, String days);

  /// No description provided for @finInsTopSpendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Spending'**
  String get finInsTopSpendingTitle;

  /// No description provided for @finInsTopSpendingBody.
  ///
  /// In en, this message translates to:
  /// **'{category} is your biggest expense this month — {percent}% of total spending.'**
  String finInsTopSpendingBody(String category, String percent);

  /// No description provided for @finInsOverspendTitle.
  ///
  /// In en, this message translates to:
  /// **'Overspending Alert'**
  String get finInsOverspendTitle;

  /// No description provided for @finInsOverspendBody.
  ///
  /// In en, this message translates to:
  /// **'You spent more than you earned this month. Consider reducing expenses.'**
  String get finInsOverspendBody;

  /// No description provided for @finInsGreatSavingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Great Savings!'**
  String get finInsGreatSavingsTitle;

  /// No description provided for @finInsGreatSavingsBody.
  ///
  /// In en, this message translates to:
  /// **'You saved {percent}% of your income this month — keep it up! 🎉'**
  String finInsGreatSavingsBody(String percent);

  /// No description provided for @finInsUnusualTitle.
  ///
  /// In en, this message translates to:
  /// **'Unusual Spending'**
  String get finInsUnusualTitle;

  /// No description provided for @finInsUnusualBody.
  ///
  /// In en, this message translates to:
  /// **'Your {amount} {category} purchase was {multiplier}x your usual spending there.'**
  String finInsUnusualBody(String amount, String category, String multiplier);

  /// No description provided for @finInsOverdueTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Overdue'**
  String get finInsOverdueTitle;

  /// No description provided for @finInsOverdueBody.
  ///
  /// In en, this message translates to:
  /// **'Your payment for \"{title}\" was due {days} days ago.'**
  String finInsOverdueBody(String title, String days);

  /// No description provided for @finInsHighDebtTitle.
  ///
  /// In en, this message translates to:
  /// **'High Debt Load'**
  String get finInsHighDebtTitle;

  /// No description provided for @finInsHighDebtBody.
  ///
  /// In en, this message translates to:
  /// **'Your total debt is {percent}% of your monthly income. Consider paying down debt.'**
  String finInsHighDebtBody(String percent);

  /// No description provided for @finInsBudgetStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Streak!'**
  String get finInsBudgetStreakTitle;

  /// No description provided for @finInsBudgetStreakBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve stayed under budget for {months} months in a row 🎉'**
  String finInsBudgetStreakBody(String months);

  /// No description provided for @finInsNoSpendTitle.
  ///
  /// In en, this message translates to:
  /// **'No-Spend Days'**
  String get finInsNoSpendTitle;

  /// No description provided for @finInsNoSpendBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve had {days} no-spend days this week — nice discipline!'**
  String finInsNoSpendBody(String days);

  /// No description provided for @finInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get finInsightsTitle;

  /// No description provided for @finInsightsMonthlySummary.
  ///
  /// In en, this message translates to:
  /// **'Monthly Summary'**
  String get finInsightsMonthlySummary;

  /// No description provided for @finInsightsSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get finInsightsSpent;

  /// No description provided for @finInsightsEarned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get finInsightsEarned;

  /// No description provided for @finInsightsNetPrefix.
  ///
  /// In en, this message translates to:
  /// **'Net:'**
  String get finInsightsNetPrefix;

  /// No description provided for @finInsightsMonthlyTrends.
  ///
  /// In en, this message translates to:
  /// **'Monthly Trends'**
  String get finInsightsMonthlyTrends;

  /// No description provided for @finInsightsNoData.
  ///
  /// In en, this message translates to:
  /// **'No transaction data yet'**
  String get finInsightsNoData;

  /// No description provided for @finInsightsIncomeVsExpense.
  ///
  /// In en, this message translates to:
  /// **'Income vs Expense'**
  String get finInsightsIncomeVsExpense;

  /// No description provided for @finInsightsSpendingInsights.
  ///
  /// In en, this message translates to:
  /// **'Spending Insights'**
  String get finInsightsSpendingInsights;

  /// No description provided for @finInsightsBiggestExpense.
  ///
  /// In en, this message translates to:
  /// **'Biggest Expense'**
  String get finInsightsBiggestExpense;

  /// No description provided for @finInsightsVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'vs Last Month'**
  String get finInsightsVsLastMonth;

  /// No description provided for @finInsightsTrendMore.
  ///
  /// In en, this message translates to:
  /// **'↑{percent}% more'**
  String finInsightsTrendMore(String percent);

  /// No description provided for @finInsightsTrendLess.
  ///
  /// In en, this message translates to:
  /// **'↓{percent}% less'**
  String finInsightsTrendLess(String percent);

  /// No description provided for @finInsightsTotalDebtLoad.
  ///
  /// In en, this message translates to:
  /// **'Total Debt Load'**
  String get finInsightsTotalDebtLoad;

  /// No description provided for @finInsightsDebtToIncome.
  ///
  /// In en, this message translates to:
  /// **'Debt-to-Income Ratio'**
  String get finInsightsDebtToIncome;

  /// No description provided for @finInsightsDebtPaidOff.
  ///
  /// In en, this message translates to:
  /// **'You\'ve paid off {percent}% of your debt this month 🎉'**
  String finInsightsDebtPaidOff(String percent);

  /// No description provided for @finInsightsSpendingAlert.
  ///
  /// In en, this message translates to:
  /// **'Spending Alert'**
  String get finInsightsSpendingAlert;

  /// No description provided for @finInsightsAddToSee.
  ///
  /// In en, this message translates to:
  /// **'Add transactions to see insights'**
  String get finInsightsAddToSee;

  /// No description provided for @finInsightsBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get finInsightsBudget;

  /// No description provided for @finInsightsHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get finInsightsHealthy;

  /// No description provided for @finInsightsStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get finInsightsStable;

  /// No description provided for @finInsightsNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get finInsightsNeedsAttention;

  /// No description provided for @finInsightsNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Net Worth'**
  String get finInsightsNetWorth;

  /// No description provided for @finInsightsTotalAccounts.
  ///
  /// In en, this message translates to:
  /// **'Total across {count, plural, =1{1 account} other{{count} accounts}}'**
  String finInsightsTotalAccounts(int count);

  /// No description provided for @finInsightsSpendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get finInsightsSpendingByCategory;

  /// No description provided for @finInsightsAlertItem.
  ///
  /// In en, this message translates to:
  /// **'{category} +{percent}%'**
  String finInsightsAlertItem(String category, String percent);

  /// No description provided for @finInsightsCategoryAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} ({percent}%)'**
  String finInsightsCategoryAmount(String amount, String percent);

  /// No description provided for @finDDPaymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get finDDPaymentRecorded;

  /// No description provided for @finDDMarkedReceived.
  ///
  /// In en, this message translates to:
  /// **'Marked as received'**
  String get finDDMarkedReceived;

  /// No description provided for @finDDMarkedPaid.
  ///
  /// In en, this message translates to:
  /// **'Marked as paid'**
  String get finDDMarkedPaid;

  /// No description provided for @finDDMarkedComplete.
  ///
  /// In en, this message translates to:
  /// **'Debt marked as complete'**
  String get finDDMarkedComplete;

  /// No description provided for @finDDRecordPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Record Payment Received'**
  String get finDDRecordPaymentReceived;

  /// No description provided for @finDDMakePayment.
  ///
  /// In en, this message translates to:
  /// **'Make a Payment'**
  String get finDDMakePayment;

  /// No description provided for @finDDRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {amount}'**
  String finDDRemaining(String amount);

  /// No description provided for @finDDFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get finDDFull;

  /// No description provided for @finDDHalf.
  ///
  /// In en, this message translates to:
  /// **'Half'**
  String get finDDHalf;

  /// No description provided for @finDDInstallment.
  ///
  /// In en, this message translates to:
  /// **'Installment'**
  String get finDDInstallment;

  /// No description provided for @finDDAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get finDDAddNote;

  /// No description provided for @finDDRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get finDDRecordPayment;

  /// No description provided for @finDDSubmitPayment.
  ///
  /// In en, this message translates to:
  /// **'Submit Payment'**
  String get finDDSubmitPayment;

  /// No description provided for @finDDCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get finDDCompleted;

  /// No description provided for @finDDProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get finDDProgress;

  /// No description provided for @finDDPaidOf.
  ///
  /// In en, this message translates to:
  /// **'{paid} paid of {total}'**
  String finDDPaidOf(String paid, String total);

  /// No description provided for @finDDDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get finDDDueDate;

  /// No description provided for @finDDNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get finDDNotes;

  /// No description provided for @finDDPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get finDDPaymentHistory;

  /// No description provided for @finDDNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get finDDNoPayments;

  /// No description provided for @finDDMarkReceived.
  ///
  /// In en, this message translates to:
  /// **'Mark as Received'**
  String get finDDMarkReceived;

  /// No description provided for @finDDMarkPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get finDDMarkPaid;

  /// No description provided for @finDDPaymentReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Received!'**
  String get finDDPaymentReceivedTitle;

  /// No description provided for @finDDDebtPaidOff.
  ///
  /// In en, this message translates to:
  /// **'Debt Paid Off!'**
  String get finDDDebtPaidOff;

  /// No description provided for @finDDYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get finDDYesterday;

  /// No description provided for @finDDTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get finDDTomorrow;

  /// No description provided for @finCatFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get finCatFood;

  /// No description provided for @finCatTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get finCatTransport;

  /// No description provided for @finCatShopping.
  ///
  /// In en, this message translates to:
  /// **'Gear & Shopping'**
  String get finCatShopping;

  /// No description provided for @finCatEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get finCatEntertainment;

  /// No description provided for @finCatBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get finCatBills;

  /// No description provided for @finCatHealth.
  ///
  /// In en, this message translates to:
  /// **'Health & Recovery'**
  String get finCatHealth;

  /// No description provided for @finCatSalary.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get finCatSalary;

  /// No description provided for @finCatFreelance.
  ///
  /// In en, this message translates to:
  /// **'Appearance Fee'**
  String get finCatFreelance;

  /// No description provided for @finCatInvestment.
  ///
  /// In en, this message translates to:
  /// **'Sponsorship'**
  String get finCatInvestment;

  /// No description provided for @finCatGift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get finCatGift;

  /// No description provided for @finAccCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get finAccCash;

  /// No description provided for @finAccBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get finAccBank;

  /// No description provided for @finAccCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get finAccCard;

  /// No description provided for @finOnbWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to\nFinance Tracker'**
  String get finOnbWelcome;

  /// No description provided for @finOnbTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Track expenses'**
  String get finOnbTrackTitle;

  /// No description provided for @finOnbTrackDesc.
  ///
  /// In en, this message translates to:
  /// **'Log every transaction and see where your money goes. Categorize spending to understand your habits.'**
  String get finOnbTrackDesc;

  /// No description provided for @finOnbBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set budgets'**
  String get finOnbBudgetTitle;

  /// No description provided for @finOnbBudgetDesc.
  ///
  /// In en, this message translates to:
  /// **'Set monthly spending limits and get alerts when you\'re close to reaching them.'**
  String get finOnbBudgetDesc;

  /// No description provided for @finOnbPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy first'**
  String get finOnbPrivacyTitle;

  /// No description provided for @finOnbPrivacyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your financial data stays on your device and is never shared with third parties.'**
  String get finOnbPrivacyDesc;

  /// No description provided for @finOnbDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This app is for personal finance tracking only and does not provide financial advice.'**
  String get finOnbDisclaimer;

  /// No description provided for @finOnbGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get finOnbGetStarted;

  /// No description provided for @finOnbSetupAccounts.
  ///
  /// In en, this message translates to:
  /// **'Set up your accounts'**
  String get finOnbSetupAccounts;

  /// No description provided for @finOnbSetupAccountsDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose which accounts you want to track. You can rename them or add more later.'**
  String get finOnbSetupAccountsDesc;

  /// No description provided for @finOnbContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get finOnbContinue;

  /// No description provided for @finOnbSetBudget.
  ///
  /// In en, this message translates to:
  /// **'Set your monthly budget'**
  String get finOnbSetBudget;

  /// No description provided for @finOnbSetBudgetDesc.
  ///
  /// In en, this message translates to:
  /// **'How much do you want to spend each month? We\'ll help you stay on track.'**
  String get finOnbSetBudgetDesc;

  /// No description provided for @finOnbFinishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish Setup'**
  String get finOnbFinishSetup;

  /// No description provided for @dashStepTrackingOn.
  ///
  /// In en, this message translates to:
  /// **'Phone step tracking on'**
  String get dashStepTrackingOn;

  /// No description provided for @dashStepTrackingOff.
  ///
  /// In en, this message translates to:
  /// **'Phone step tracking off'**
  String get dashStepTrackingOff;

  /// No description provided for @stepsDetTrackOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone step tracking is on'**
  String get stepsDetTrackOnTitle;

  /// No description provided for @stepsDetTrackOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone step tracking is off'**
  String get stepsDetTrackOffTitle;

  /// No description provided for @stepsDetTrackOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your phone is counting steps all day in the background.'**
  String get stepsDetTrackOnSubtitle;

  /// No description provided for @stepsDetTrackOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Steps are only counted during workouts right now.'**
  String get stepsDetTrackOffSubtitle;

  /// No description provided for @stepsDetTrackHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How to turn it on or off'**
  String get stepsDetTrackHowTitle;

  /// No description provided for @stepsDetTrackStep1.
  ///
  /// In en, this message translates to:
  /// **'Open the Account tab, then Settings.'**
  String get stepsDetTrackStep1;

  /// No description provided for @stepsDetTrackStep2.
  ///
  /// In en, this message translates to:
  /// **'Find “Background step tracking”.'**
  String get stepsDetTrackStep2;

  /// No description provided for @stepsDetTrackStep3.
  ///
  /// In en, this message translates to:
  /// **'Toggle it on or off.'**
  String get stepsDetTrackStep3;

  /// No description provided for @stepsDetTrackInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'How step tracking works'**
  String get stepsDetTrackInfoTitle;

  /// No description provided for @stepsDetTrackInfoP1.
  ///
  /// In en, this message translates to:
  /// **'When background tracking is on, Synthese reads your phone’s built-in step counter to total your steps all day — even while the app is closed. The count is reconciled each time you open the app.'**
  String get stepsDetTrackInfoP1;

  /// No description provided for @stepsDetTrackInfoP2.
  ///
  /// In en, this message translates to:
  /// **'When it’s off, steps are only recorded during an active walking, running, or trail-run workout. Your all-day steps won’t update in the background.'**
  String get stepsDetTrackInfoP2;

  /// No description provided for @stepsDetTrackInfoP3.
  ///
  /// In en, this message translates to:
  /// **'Step data stays on your device and in your account. You can switch background tracking on or off anytime from Settings.'**
  String get stepsDetTrackInfoP3;

  /// No description provided for @guestDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest?'**
  String get guestDialogTitle;

  /// No description provided for @guestDialogIntro.
  ///
  /// In en, this message translates to:
  /// **'Guest mode lets you try Synthese without creating an account.'**
  String get guestDialogIntro;

  /// No description provided for @guestDialogPoint1.
  ///
  /// In en, this message translates to:
  /// **'Your data is saved only on this device — it won’t be synced or backed up.'**
  String get guestDialogPoint1;

  /// No description provided for @guestDialogPoint2.
  ///
  /// In en, this message translates to:
  /// **'If you sign out or switch devices, your data will be lost.'**
  String get guestDialogPoint2;

  /// No description provided for @guestDialogPoint3.
  ///
  /// In en, this message translates to:
  /// **'Your guest account is automatically signed out after 3 days.'**
  String get guestDialogPoint3;

  /// No description provided for @guestDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get guestDialogCancel;

  /// No description provided for @guestDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get guestDialogConfirm;

  /// No description provided for @guestBannerLabel.
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get guestBannerLabel;

  /// No description provided for @guestBannerDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day left} other{{days} days left}}'**
  String guestBannerDaysLeft(int days);

  /// No description provided for @stepNotifChannelOngoing.
  ///
  /// In en, this message translates to:
  /// **'Step tracking'**
  String get stepNotifChannelOngoing;

  /// No description provided for @stepNotifChannelMilestone.
  ///
  /// In en, this message translates to:
  /// **'Step milestones'**
  String get stepNotifChannelMilestone;

  /// No description provided for @stepNotifOngoingTitle.
  ///
  /// In en, this message translates to:
  /// **'Step tracking active'**
  String get stepNotifOngoingTitle;

  /// No description provided for @stepNotifOngoingBody.
  ///
  /// In en, this message translates to:
  /// **'{steps} steps today'**
  String stepNotifOngoingBody(String steps);

  /// No description provided for @stepNotif1kTitle.
  ///
  /// In en, this message translates to:
  /// **'1,000 steps!'**
  String get stepNotif1kTitle;

  /// No description provided for @stepNotif1kBody.
  ///
  /// In en, this message translates to:
  /// **'Great start — you\'ve passed 1,000 steps today.'**
  String get stepNotif1kBody;

  /// No description provided for @stepNotif5kTitle.
  ///
  /// In en, this message translates to:
  /// **'5,000 steps!'**
  String get stepNotif5kTitle;

  /// No description provided for @stepNotif5kBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re on a roll — 5,000 steps and counting.'**
  String get stepNotif5kBody;

  /// No description provided for @stepNotifGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal reached!'**
  String get stepNotifGoalTitle;

  /// No description provided for @stepNotifGoalBody.
  ///
  /// In en, this message translates to:
  /// **'You hit your {goal}-step goal for today. Amazing!'**
  String stepNotifGoalBody(String goal);

  /// No description provided for @settingsStepMilestonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Step milestone alerts'**
  String get settingsStepMilestonesTitle;

  /// No description provided for @settingsStepMilestonesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified when you pass 1,000, 5,000 and your daily goal — even with the app closed.'**
  String get settingsStepMilestonesSubtitle;

  /// No description provided for @settingsStepMilestonesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Turn on background step tracking to use milestone alerts.'**
  String get settingsStepMilestonesDisabled;

  /// No description provided for @sessionSignedOutOtherDevice.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been signed out because your account was signed in on another device.'**
  String get sessionSignedOutOtherDevice;

  /// No description provided for @notifDietMealTitle.
  ///
  /// In en, this message translates to:
  /// **'Log today\'s meals'**
  String get notifDietMealTitle;

  /// No description provided for @notifDietMealBody.
  ///
  /// In en, this message translates to:
  /// **'Keep your nutrition streak alive by logging at least one meal.'**
  String get notifDietMealBody;

  /// No description provided for @notifDietWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Hydration check'**
  String get notifDietWaterTitle;

  /// No description provided for @notifDietWaterBody.
  ///
  /// In en, this message translates to:
  /// **'You are at {current}/{goal} glasses today. Drink a glass now.'**
  String notifDietWaterBody(int current, int goal);

  /// No description provided for @notifDietCalorieNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re close to your calorie goal'**
  String get notifDietCalorieNudgeTitle;

  /// No description provided for @notifDietCalorieNudgeBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve logged {logged}/{goal} kcal. Finish strong.'**
  String notifDietCalorieNudgeBody(int logged, int goal);

  /// No description provided for @notifDietStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition streak: {days} days'**
  String notifDietStreakTitle(int days);

  /// No description provided for @notifDietStreakBody.
  ///
  /// In en, this message translates to:
  /// **'You have hit your calorie goal for {days} days in a row.'**
  String notifDietStreakBody(int days);

  /// No description provided for @notifMindfulnessMoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood check-in'**
  String get notifMindfulnessMoodTitle;

  /// No description provided for @notifMindfulnessMoodBody.
  ///
  /// In en, this message translates to:
  /// **'Take 10 seconds to log your mood today.'**
  String get notifMindfulnessMoodBody;

  /// No description provided for @notifMindfulnessReadinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning readiness'**
  String get notifMindfulnessReadinessTitle;

  /// No description provided for @notifMindfulnessReadinessBody.
  ///
  /// In en, this message translates to:
  /// **'Log sleep, energy and stress to tune your day better.'**
  String get notifMindfulnessReadinessBody;

  /// No description provided for @notifMindfulnessBreatheTitle.
  ///
  /// In en, this message translates to:
  /// **'Take a short breathing break'**
  String get notifMindfulnessBreatheTitle;

  /// No description provided for @notifMindfulnessBreatheBody.
  ///
  /// In en, this message translates to:
  /// **'A 2-minute breathing session can help close your day calmly.'**
  String get notifMindfulnessBreatheBody;

  /// No description provided for @notifCyclesDailyLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cycle log reminder'**
  String get notifCyclesDailyLogTitle;

  /// No description provided for @notifCyclesDailyLogBody.
  ///
  /// In en, this message translates to:
  /// **'Log today\'s flow/symptoms to keep cycle predictions accurate.'**
  String get notifCyclesDailyLogBody;

  /// No description provided for @notifCyclesPeriodSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Period likely in ~2 days'**
  String get notifCyclesPeriodSoonTitle;

  /// No description provided for @notifCyclesPeriodSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Keep products handy and track symptoms today.'**
  String get notifCyclesPeriodSoonBody;

  /// No description provided for @notifCyclesPeriodDueTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Period due today'**
  String get notifCyclesPeriodDueTodayTitle;

  /// No description provided for @notifCyclesPeriodDueTodayBody.
  ///
  /// In en, this message translates to:
  /// **'Your cycle suggests today may be day 1 of your period.'**
  String get notifCyclesPeriodDueTodayBody;

  /// No description provided for @notifCyclesLate7Title.
  ///
  /// In en, this message translates to:
  /// **'Period is 7+ days late'**
  String get notifCyclesLate7Title;

  /// No description provided for @notifCyclesLate7Body.
  ///
  /// In en, this message translates to:
  /// **'Stress and routine changes can delay periods. Keep tracking.'**
  String get notifCyclesLate7Body;

  /// No description provided for @notifCyclesLate14Title.
  ///
  /// In en, this message translates to:
  /// **'Period is 14+ days late'**
  String get notifCyclesLate14Title;

  /// No description provided for @notifCyclesLate14Body.
  ///
  /// In en, this message translates to:
  /// **'If this is unusual for you, consider checking with a doctor.'**
  String get notifCyclesLate14Body;

  /// No description provided for @notifCyclesLate90Title.
  ///
  /// In en, this message translates to:
  /// **'Period over 3 months late'**
  String get notifCyclesLate90Title;

  /// No description provided for @notifCyclesLate90Body.
  ///
  /// In en, this message translates to:
  /// **'Please consult a healthcare provider as soon as possible.'**
  String get notifCyclesLate90Body;

  /// No description provided for @notifCyclesOvulationWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'Fertile window likely starting'**
  String get notifCyclesOvulationWindowTitle;

  /// No description provided for @notifCyclesOvulationWindowBody.
  ///
  /// In en, this message translates to:
  /// **'You may be entering your ovulation window.'**
  String get notifCyclesOvulationWindowBody;

  /// No description provided for @notifCyclesOvulationPeakTitle.
  ///
  /// In en, this message translates to:
  /// **'Ovulation likely today'**
  String get notifCyclesOvulationPeakTitle;

  /// No description provided for @notifCyclesOvulationPeakBody.
  ///
  /// In en, this message translates to:
  /// **'Your cycle indicates ovulation is likely around today.'**
  String get notifCyclesOvulationPeakBody;

  /// No description provided for @notifCyclesShortCycleTitle.
  ///
  /// In en, this message translates to:
  /// **'Pattern: short cycles'**
  String get notifCyclesShortCycleTitle;

  /// No description provided for @notifCyclesShortCycleBody.
  ///
  /// In en, this message translates to:
  /// **'Your last 3 cycles were unusually short. Keep monitoring.'**
  String get notifCyclesShortCycleBody;

  /// No description provided for @notifCyclesLongCycleTitle.
  ///
  /// In en, this message translates to:
  /// **'Pattern: long cycles'**
  String get notifCyclesLongCycleTitle;

  /// No description provided for @notifCyclesLongCycleBody.
  ///
  /// In en, this message translates to:
  /// **'Your last 3 cycles were unusually long. Track closely.'**
  String get notifCyclesLongCycleBody;

  /// No description provided for @notifCyclesLongPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Long periods detected'**
  String get notifCyclesLongPeriodTitle;

  /// No description provided for @notifCyclesLongPeriodBody.
  ///
  /// In en, this message translates to:
  /// **'Your period length has been above 8 days recently.'**
  String get notifCyclesLongPeriodBody;

  /// No description provided for @notifCyclesHeavyBleedingTitle.
  ///
  /// In en, this message translates to:
  /// **'Heavy bleeding trend'**
  String get notifCyclesHeavyBleedingTitle;

  /// No description provided for @notifCyclesHeavyBleedingBody.
  ///
  /// In en, this message translates to:
  /// **'Your last cycle had 5+ very heavy flow days.'**
  String get notifCyclesHeavyBleedingBody;

  /// No description provided for @notifFinanceDebtClearedTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt cleared'**
  String get notifFinanceDebtClearedTitle;

  /// No description provided for @notifFinanceDebtClearedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} has been marked as fully paid. Great progress!'**
  String notifFinanceDebtClearedBody(String name);

  /// No description provided for @notifFinanceDebtDueTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt reminder: {name}'**
  String notifFinanceDebtDueTitle(String name);

  /// No description provided for @notifFinanceDebtDueTodayBody.
  ///
  /// In en, this message translates to:
  /// **'This payment is due today.'**
  String get notifFinanceDebtDueTodayBody;

  /// No description provided for @notifFinanceDebtDueDaysBody.
  ///
  /// In en, this message translates to:
  /// **'Payment due in {days} day{days, plural, =1{} other{s}}.'**
  String notifFinanceDebtDueDaysBody(int days);

  /// No description provided for @notifFinanceDebtOverdueTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment overdue'**
  String get notifFinanceDebtOverdueTitle;

  /// No description provided for @notifFinanceDebtOverdueBody.
  ///
  /// In en, this message translates to:
  /// **'{name} is overdue by {days} day{days, plural, =1{} other{s}}.'**
  String notifFinanceDebtOverdueBody(String name, int days);

  /// No description provided for @notifFinanceInstallmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Installment reminder'**
  String get notifFinanceInstallmentTitle;

  /// No description provided for @notifFinanceInstallmentBody.
  ///
  /// In en, this message translates to:
  /// **'{name} installment is coming up soon.'**
  String notifFinanceInstallmentBody(String name);

  /// No description provided for @notifFinanceLowBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Low balance alert'**
  String get notifFinanceLowBalanceTitle;

  /// No description provided for @notifFinanceLowBalanceBody.
  ///
  /// In en, this message translates to:
  /// **'{name} is at {balance}. Consider topping up soon.'**
  String notifFinanceLowBalanceBody(String name, String balance);

  /// No description provided for @notifFinanceLargeExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Large expense detected'**
  String get notifFinanceLargeExpenseTitle;

  /// No description provided for @notifFinanceLargeExpenseBody.
  ///
  /// In en, this message translates to:
  /// **'A large spend of {amount} was recorded.'**
  String notifFinanceLargeExpenseBody(String amount);

  /// No description provided for @notifFinanceBudgetPacingTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget pacing alert'**
  String get notifFinanceBudgetPacingTitle;

  /// No description provided for @notifFinanceBudgetPacingBody.
  ///
  /// In en, this message translates to:
  /// **'You are spending faster than this month\'s pace ({spent} used).'**
  String notifFinanceBudgetPacingBody(String spent);

  /// No description provided for @notifDashboardHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily health score reminder'**
  String get notifDashboardHealthTitle;

  /// No description provided for @notifDashboardHealthBody.
  ///
  /// In en, this message translates to:
  /// **'No health update yet today. Log activity to refresh your score.'**
  String get notifDashboardHealthBody;

  /// No description provided for @disclaimerShort.
  ///
  /// In en, this message translates to:
  /// **'Not a substitute for professional medical, nutritional, mental health, or financial advice. Always consult a qualified professional.'**
  String get disclaimerShort;

  /// No description provided for @disclaimerAiTitle.
  ///
  /// In en, this message translates to:
  /// **'⚠️ AI Estimates — Not for Professional Use'**
  String get disclaimerAiTitle;

  /// No description provided for @disclaimerAiBody.
  ///
  /// In en, this message translates to:
  /// **'Nutritional values are estimated by AI and may not be accurate. AI can and does make mistakes. This is not professional dietary or medical advice. Always consult a registered dietitian or healthcare provider for nutritional guidance.'**
  String get disclaimerAiBody;

  /// No description provided for @disclaimerAiShort.
  ///
  /// In en, this message translates to:
  /// **'Nutritional values are AI estimates and may be inaccurate. Not a substitute for professional dietary or medical advice.'**
  String get disclaimerAiShort;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report inaccurate result'**
  String get reportTitle;

  /// No description provided for @reportSelectIssue.
  ///
  /// In en, this message translates to:
  /// **'What\'s wrong?'**
  String get reportSelectIssue;

  /// No description provided for @reportIssueWrongFood.
  ///
  /// In en, this message translates to:
  /// **'Wrong food identified'**
  String get reportIssueWrongFood;

  /// No description provided for @reportIssueCaloriesOff.
  ///
  /// In en, this message translates to:
  /// **'Calories way off'**
  String get reportIssueCaloriesOff;

  /// No description provided for @reportIssueMacrosOff.
  ///
  /// In en, this message translates to:
  /// **'Macros incorrect'**
  String get reportIssueMacrosOff;

  /// No description provided for @reportIssueMicronutrientsOff.
  ///
  /// In en, this message translates to:
  /// **'Micronutrients incorrect'**
  String get reportIssueMicronutrientsOff;

  /// No description provided for @reportIssueOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportIssueOther;

  /// No description provided for @reportNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)'**
  String get reportNoteLabel;

  /// No description provided for @reportNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. It identified this as pasta but it\'s rice...'**
  String get reportNoteHint;

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportSubmit;

  /// No description provided for @reportSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get reportSuccessTitle;

  /// No description provided for @reportSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Thanks for helping improve Synthese. We\'ll review this AI result.'**
  String get reportSuccessBody;

  /// No description provided for @reportSuccessDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get reportSuccessDone;

  /// No description provided for @reportFlagButton.
  ///
  /// In en, this message translates to:
  /// **'Flag inaccurate result'**
  String get reportFlagButton;

  /// No description provided for @disclaimerGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Before You Continue'**
  String get disclaimerGateTitle;

  /// No description provided for @disclaimerGateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Synthese is a personal wellness tracking tool — not a medical, clinical, or financial service. Please read this before using the app.'**
  String get disclaimerGateSubtitle;

  /// No description provided for @disclaimerGatePoint1Title.
  ///
  /// In en, this message translates to:
  /// **'Not a medical device'**
  String get disclaimerGatePoint1Title;

  /// No description provided for @disclaimerGatePoint1Body.
  ///
  /// In en, this message translates to:
  /// **'Health tracking features (heart rate, steps, sleep, cycles) use algorithms for general wellness purposes only. Always consult a doctor for medical concerns.'**
  String get disclaimerGatePoint1Body;

  /// No description provided for @disclaimerGatePoint2Title.
  ///
  /// In en, this message translates to:
  /// **'Not a mental health service'**
  String get disclaimerGatePoint2Title;

  /// No description provided for @disclaimerGatePoint2Body.
  ///
  /// In en, this message translates to:
  /// **'Mood tracking and mindfulness features are for personal reflection only. They are not a substitute for professional psychological or psychiatric care.'**
  String get disclaimerGatePoint2Body;

  /// No description provided for @disclaimerGatePoint3Title.
  ///
  /// In en, this message translates to:
  /// **'AI nutritional estimates'**
  String get disclaimerGatePoint3Title;

  /// No description provided for @disclaimerGatePoint3Body.
  ///
  /// In en, this message translates to:
  /// **'Food detection uses AI to estimate nutritional values. These estimates may be inaccurate. Consult a registered dietitian for dietary guidance.'**
  String get disclaimerGatePoint3Body;

  /// No description provided for @disclaimerGatePoint4Title.
  ///
  /// In en, this message translates to:
  /// **'Not financial advice'**
  String get disclaimerGatePoint4Title;

  /// No description provided for @disclaimerGatePoint4Body.
  ///
  /// In en, this message translates to:
  /// **'Finance tracking features are for personal budgeting only. They are not a substitute for professional financial or legal advice.'**
  String get disclaimerGatePoint4Body;

  /// No description provided for @disclaimerGateAiNote.
  ///
  /// In en, this message translates to:
  /// **'AI can and does make mistakes. Never make health, dietary, or financial decisions based solely on information from this app.'**
  String get disclaimerGateAiNote;

  /// No description provided for @disclaimerGateAccept.
  ///
  /// In en, this message translates to:
  /// **'I Understand'**
  String get disclaimerGateAccept;

  /// No description provided for @disclaimerGateFooter.
  ///
  /// In en, this message translates to:
  /// **'By continuing you acknowledge that Synthese is not a professional service and agree to use it responsibly.'**
  String get disclaimerGateFooter;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'es', 'hi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
