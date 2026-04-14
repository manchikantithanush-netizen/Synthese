import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/universalclosebutton.dart';
import 'package:synthese/cycles/articles/cycle_article1.dart';
import 'package:synthese/cycles/articles/cycle_article2.dart';
import 'package:synthese/cycles/articles/cycle_article3.dart';
import 'package:synthese/cycles/articles/cycle_article4.dart';
import 'package:synthese/cycles/articles/cycle_article5.dart';
import 'package:synthese/cycles/articles/cycle_article6.dart';

class HelpCyclesPage extends StatefulWidget {
  const HelpCyclesPage({super.key});

  @override
  State<HelpCyclesPage> createState() => _HelpCyclesPageState();
}

class _HelpCyclesPageState extends State<HelpCyclesPage> {
  final PageController _pageController = PageController();
  int _selectedArticleIndex = -1;

  void _slideForward(int index) {
    setState(() => _selectedArticleIndex = index);
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _slideBack() {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _selectedArticleIndex = -1);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color.fromARGB(255, 26, 26, 28)
        : const Color.fromARGB(255, 245, 245, 245);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [_buildMainList(isDark), _buildArticleView(isDark)],
        ),
      ),
    );
  }

  // ============================================================================
  // PAGE 0: THE MAIN ARTICLE LIST
  // ============================================================================
  Widget _buildMainList(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF8E8E93);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 20.0, right: 20.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: Text(
                  "Learn",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: UniversalCloseButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 40,
              top: 10,
            ),
            itemCount: _articles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final article = _articles[index];
              return _buildLargeArticleCard(
                index: index,
                // The ?? fallbacks prevent the 'Null is not a subtype of String' error
                title: article['title'] as String? ?? 'Article Title',
                description: article['desc'] as String? ?? '',
                imagePath: article['image'] as String? ?? 'assets/image1.jpg',
                isDark: isDark,
                textColor: textColor,
                subtitleColor: subtitleColor,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLargeArticleCard({
    required int index,
    required String title,
    required String description,
    required String imagePath,
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final cardBgColor = isDark ? const Color(0xFF252528) : Colors.white;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (index >= 0 && index <= 5) {
          _slideForward(index);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- IMAGE SECTION ---
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: AspectRatio(
                aspectRatio: 1.8,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback just in case the image isn't found
                    return Container(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFE5E5EA),
                      child: Center(
                        child: Icon(
                          CupertinoIcons.photo,
                          color: isDark ? Colors.white30 : Colors.black26,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // --- TEXT SECTION ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // PAGE 1: THE ARTICLE DETAIL
  // ============================================================================
  Widget _buildArticleView(bool isDark) {
    Widget articleContent;
    switch (_selectedArticleIndex) {
      case 0:
        articleContent = ArticleOneView(isDark: isDark);
        break;
      case 1:
        articleContent = ArticleTwoView(isDark: isDark);
        break;
      case 2:
        articleContent = ArticleThreeView(isDark: isDark);
        break;
      case 3:
        articleContent = ArticleFourView(isDark: isDark);
        break;
      case 4:
        articleContent = ArticleFiveView(isDark: isDark);
        break;
      case 5:
        articleContent = ArticleSixView(isDark: isDark);
        break;
      default:
        articleContent = const SizedBox();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 20.0, right: 20.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: UniversalBackButton(onPressed: _slideBack),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: UniversalCloseButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: articleContent),
      ],
    );
  }
}

// --- ARTICLE DATA ---
// NOTE: Ensure this completely replaces the old list at the bottom of your file.
final List<Map<String, dynamic>> _articles = [
  {
    'title': 'What is a menstrual cycle?',
    'desc':
        'The complete beginner\'s guide to understanding your body and what is actually happening every month.',
    'image': 'assets/image1.jpg',
  },
  {
    'title': 'The four phases of your cycle',
    'desc':
        'Breaking down the menstrual, follicular, ovulation, and luteal phases. What your body is doing and what you might feel.',
    'image': 'assets/image2.jpg',
  },
  {
    'title': 'Hormones and your cycle',
    'desc':
        'What estrogen, progesterone, LH, and FSH actually do. How hormone levels rise and fall and cause symptoms.',
    'image': 'assets/image3.jpg',
  },
  {
    'title': 'What is spotting?',
    'desc':
        'The difference between spotting and a period. Common causes like ovulation and stress, and when to mention it.',
    'image': 'assets/image4.jpg',
  },
  {
    'title': 'Things that affect your cycle',
    'desc':
        'Stress, sleep, exercise, diet, and travel. Why your cycle is a reflection of your overall health.',
    'image': 'assets/image5.jpg',
  },
  {
    'title': 'Why cycle tracking matters',
    'desc':
        'What tracking tells you beyond predicting your period. How to use your logs to understand your baseline.',
    'image': 'assets/image6.jpg',
  },
];
