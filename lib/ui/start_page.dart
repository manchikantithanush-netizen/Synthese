import 'package:flutter/cupertino.dart'; // REQUIRED for CupertinoTheme
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:cupertino_native/cupertino_native.dart'; 
import 'package:synthese/ui/components/premium_button.dart';
import 'package:synthese/ui/auth/login_page.dart';
import 'package:synthese/ui/auth/signup_page.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  // --- TEXT CONSTANTS ---
  final String _introText = 'Hello,\nWelcome to Synthese';
  
  // Dictionary parts broken down for dynamic styling during typing
  final String _defWord = 'Synthese\n';
  final String _defPron = '/ˈsɪnθɪsiːz/\n';
  final String _defPos = 'noun\n\n';
  final String _defMeaning = 'The synthesis of athletic health data into clear, instantly understandable insights, designed to help young athletes view performance, recovery, and lifestyle information without unnecessary complexity.\n\n';
  final String _defOrigin = 'From Greek: synthesis — a combining of elements to form a unified whole.';
  
  late final String _dictText;

  // --- STATE ---
  String _displayedText = '';
  int _phase = 0; // 0: Typing Intro, 1: Backspacing Intro, 2: Typing Dictionary
  
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    _dictText = '$_defWord$_defPron$_defPos$_defMeaning$_defOrigin';
    _startSequence();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  Future<void> _startSequence() async {
    // PHASE 0: Type Intro
    await Future.delayed(const Duration(milliseconds: 600));
    for (int i = 0; i < _introText.length; i++) {
      if (!mounted) return;
      setState(() => _displayedText = _introText.substring(0, i + 1));
      
      String char = _introText[i];
      if (_route?.isCurrent == true && char != ' ' && char != '\n') {
        HapticFeedback.lightImpact(); 
      }
      
      int delay = (char == ',' || char == '\n') ? 400 : 50;
      await Future.delayed(Duration(milliseconds: delay));
    }

    await Future.delayed(const Duration(milliseconds: 1600));

    // PHASE 1: Backspace Intro
    _phase = 1;
    for (int i = _introText.length; i >= 0; i--) {
      if (!mounted) return;
      setState(() => _displayedText = _introText.substring(0, i));
      
      if (_route?.isCurrent == true && i > 0) {
        HapticFeedback.selectionClick(); 
      }
      await Future.delayed(const Duration(milliseconds: 20)); 
    }

    await Future.delayed(const Duration(milliseconds: 600));

    // PHASE 2: Type Dictionary
    _phase = 2;
    for (int i = 0; i < _dictText.length; i++) {
      if (!mounted) return;
      setState(() => _displayedText = _dictText.substring(0, i + 1));
      
      String char = _dictText[i];
      if (_route?.isCurrent == true && char != ' ' && char != '\n') {
        HapticFeedback.lightImpact(); 
      }
      
      int delay = 15; 
      if (char == '.' || char == ',') delay = 150;
      else if (char == '\n') delay = 200;
      
      await Future.delayed(Duration(milliseconds: delay));
    }
  }

  List<InlineSpan> _buildTextSpans() {
    final textColor = Theme.of(context).colorScheme.onSurface;

    if (_phase < 2) {
      return [
        TextSpan(
          text: _displayedText,
          style: TextStyle(
            color: textColor,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            height: 1.1,
          ),
        ),
        TextSpan(
          text: '|',
          style: TextStyle(
            color: textColor,
            fontSize: 40,
            fontWeight: FontWeight.w300,
          ),
        ),
      ];
    } else {
      List<InlineSpan> spans = [];
      int currentIndex = 0;

      void addPart(String partText, TextStyle style) {
        if (currentIndex >= _displayedText.length) return;
        int endIndex = currentIndex + partText.length;
        if (endIndex > _displayedText.length) endIndex = _displayedText.length;
        
        spans.add(TextSpan(
          text: _displayedText.substring(currentIndex, endIndex),
          style: style,
        ));
        currentIndex += partText.length;
      }

      addPart(_defWord, TextStyle(
        color: textColor, fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: -0.5)); 
      addPart(_defPron, TextStyle(
        color: textColor.withOpacity(0.7), fontSize: 18, fontStyle: FontStyle.italic)); 
      addPart(_defPos, TextStyle(
        color: textColor.withOpacity(0.5), fontSize: 16, fontStyle: FontStyle.italic)); 
      addPart(_defMeaning, TextStyle(
        color: textColor.withOpacity(0.95), fontSize: 18, height: 1.5, fontWeight: FontWeight.w400)); 
      addPart(_defOrigin, TextStyle(
        color: textColor.withOpacity(0.5), fontSize: 14, height: 1.4, fontStyle: FontStyle.italic)); 

      spans.add(TextSpan(
        text: '|',
        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w300), 
      ));

      return spans;
    }
  }

  Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        return FadeTransition(opacity: fadeAnimation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // DEFINED isDark here so the CupertinoTheme knows what color to use
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: Text.rich(
                      TextSpan(children: _buildTextSpans()),
                      textAlign: _phase < 2 ? TextAlign.center : TextAlign.left,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  // Continue with Sign In Button
// Continue with Sign In Button
// Continue with Sign In Button
// Sign In Button
PremiumButton(
  text: 'Continue with Sign In',
  onPressed: () {
    Navigator.push(context, _fadeRoute(const LoginPage()));
  },
),

const SizedBox(height: 14),

// Sign Up Button
ClipRRect(
  borderRadius: BorderRadius.circular(50),
  child: SizedBox(
    height: 56,
    width: double.infinity,
    child: Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: Colors.green,
        ),
      ),
      child: CNButton(
        label: 'Continue with Sign Up',
        style: CNButtonStyle.bordered,
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(context, _fadeRoute(const SignupPage()));
        },
      ),
    ),
  ),
),

                  const SizedBox(height: 24),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        color: textColor.withOpacity(0.54),
                        fontSize: 12,
                        height: 1.6,
                        letterSpacing: 0.2,
                      ),
                      children: [
                        const TextSpan(text: 'By pressing Continue you agree with our\n'),
                        TextSpan(
                          text: 'privacy policy',
                          style: TextStyle(
                              color: textColor, fontWeight: FontWeight.bold), 
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'terms and conditions',
                          style: TextStyle(
                              color: textColor, fontWeight: FontWeight.bold), 
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}