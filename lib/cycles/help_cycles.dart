import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:synthese/l10n/generated/app_localizations.dart';
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
    final t = AppLocalizations.of(context);
    final articles = _articlesFor(t);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 16.0, start: 20.0, end: 20.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: Text(
                  t.cycleHelpLearn,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
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
            itemCount: articles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final article = articles[index];
              return _buildLargeArticleCard(
                index: index,
                title: article['title'] as String? ?? t.cycleHelpArticleTitle,
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
          padding: const EdgeInsetsDirectional.only(top: 16.0, start: 20.0, end: 20.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: UniversalBackButton(onPressed: _slideBack),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
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

List<Map<String, dynamic>> _articlesFor(AppLocalizations t) => [
  {
    'title': t.cycleHelpArticle1Title,
    'desc': t.cycleHelpArticle1Desc,
    'image': 'assets/image1.jpg',
  },
  {
    'title': t.cycleHelpArticle2Title,
    'desc': t.cycleHelpArticle2Desc,
    'image': 'assets/image2.jpg',
  },
  {
    'title': t.cycleHelpArticle3Title,
    'desc': t.cycleHelpArticle3Desc,
    'image': 'assets/image3.jpg',
  },
  {
    'title': t.cycleHelpArticle4Title,
    'desc': t.cycleHelpArticle4Desc,
    'image': 'assets/image4.jpg',
  },
  {
    'title': t.cycleHelpArticle5Title,
    'desc': t.cycleHelpArticle5Desc,
    'image': 'assets/image5.jpg',
  },
  {
    'title': t.cycleHelpArticle6Title,
    'desc': t.cycleHelpArticle6Desc,
    'image': 'assets/image6.jpg',
  },
];
