import 'dart:ui';

/// Represents a single questionnaire question
class Question {
  final int id;
  final String text;
  final List<String> options; // A, B, C, D
  final List<String> dimensions; // Which dimensions this affects

  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.dimensions,
  });
}

/// Represents a scoring dimension
class Dimension {
  final String id;
  final String name;
  final Color color;

  const Dimension({
    required this.id,
    required this.name,
    required this.color,
  });
}

/// Risk level classification
enum RiskLevel { low, moderate, high }

/// All scoring dimensions
const List<Dimension> dimensions = [
  Dimension(id: 'depression', name: 'Depression', color: Color(0xFF5C6BC0)),
  Dimension(id: 'anxiety', name: 'Anxiety', color: Color(0xFFFF7043)),
  Dimension(id: 'sleep', name: 'Sleep Quality', color: Color(0xFF42A5F5)),
  Dimension(id: 'stress', name: 'Stress', color: Color(0xFFEF5350)),
  Dimension(id: 'social', name: 'Social Connection', color: Color(0xFF66BB6A)),
  Dimension(id: 'energy', name: 'Energy & Burnout', color: Color(0xFFFFA726)),
  Dimension(id: 'selfEsteem', name: 'Self-Esteem', color: Color(0xFFAB47BC)),
  Dimension(id: 'crisis', name: 'Crisis Indicators', color: Color(0xFFE53935)),
  Dimension(id: 'coping', name: 'Coping & Resilience', color: Color(0xFF26A69A)),
];

/// All 15 questionnaire questions
const List<Question> questions = [
  Question(
    id: 1,
    text:
        'Over the past two weeks, how often have you felt little interest or pleasure in doing things you normally enjoy?',
    options: [
      'Rarely or not at all',
      'Several days',
      'More than half the days',
      'Nearly every day',
    ],
    dimensions: ['depression'],
  ),
  Question(
    id: 2,
    text:
        'How often have you felt down, hopeless, or like things will never improve?',
    options: [
      'Rarely or not at all',
      'Several days',
      'More than half the days',
      'Nearly every day',
    ],
    dimensions: ['depression'],
  ),
  Question(
    id: 3,
    text: 'How often have you felt nervous, on edge, or unable to stop worrying?',
    options: [
      'Rarely or not at all',
      'Several days',
      'More than half the days',
      'Nearly every day',
    ],
    dimensions: ['anxiety'],
  ),
  Question(
    id: 4,
    text: 'When faced with a challenging situation, how do you typically respond?',
    options: [
      'I stay calm and handle it well',
      'I feel some stress but manage',
      'I feel quite anxious and overwhelmed',
      'I avoid the situation entirely',
    ],
    dimensions: ['anxiety', 'coping'],
  ),
  Question(
    id: 5,
    text: 'How would you describe your sleep over the past month?',
    options: [
      'Restful, 7-9 hours most nights',
      'Occasionally disrupted but manageable',
      'Frequently poor - trouble falling or staying asleep',
      'Very poor - consistently exhausted',
    ],
    dimensions: ['sleep'],
  ),
  Question(
    id: 6,
    text:
        'How would you rate your overall stress level in your daily life right now?',
    options: [
      'Low - I feel mostly at ease',
      'Moderate - manageable most days',
      'High - it\'s affecting my routine',
      'Very high - I feel overwhelmed regularly',
    ],
    dimensions: ['stress'],
  ),
  Question(
    id: 7,
    text:
        'How connected do you feel to the people around you - friends, family, teammates?',
    options: [
      'Very connected and supported',
      'Mostly connected, with some distance',
      'Often isolated or misunderstood',
      'Very alone and disconnected',
    ],
    dimensions: ['social'],
  ),
  Question(
    id: 8,
    text: 'How would you describe your energy and motivation levels lately?',
    options: [
      'High - I feel driven and engaged',
      'Steady - some ups and downs',
      'Low - getting started is a struggle',
      'Very low - I feel fatigued most of the time',
    ],
    dimensions: ['energy'],
  ),
  Question(
    id: 9,
    text:
        'How often do you catch yourself thinking negatively about yourself or your abilities?',
    options: [
      'Rarely - I generally feel confident',
      'Occasionally, but I brush it off',
      'Often - I doubt myself frequently',
      'Almost always - it holds me back',
    ],
    dimensions: ['selfEsteem'],
  ),
  Question(
    id: 10,
    text:
        'Do you experience physical symptoms - like a racing heart, tightness in your chest, or shortness of breath - during everyday situations?',
    options: [
      'Never or very rarely',
      'Sometimes, but only under real pressure',
      'Fairly often, even in routine situations',
      'Very often - it disrupts my day',
    ],
    dimensions: ['anxiety'],
  ),
  Question(
    id: 11,
    text:
        'How often do you feel emotionally drained or used up by the end of the day?',
    options: [
      'Rarely - I usually have energy left',
      'Sometimes after tough days',
      'Often - I feel depleted most days',
      'Almost always - I\'m running on empty',
    ],
    dimensions: ['energy', 'burnout'],
  ),
  Question(
    id: 12,
    text:
        'In the past two weeks, have you had thoughts that you\'d be better off not being here, or of hurting yourself?',
    options: [
      'Not at all',
      'Briefly, but it passed quickly',
      'Somewhat - these thoughts recur',
      'Yes, frequently or seriously',
    ],
    dimensions: ['crisis'],
  ),
  Question(
    id: 13,
    text:
        'When you\'re going through a hard time, which of the following best describes how you cope?',
    options: [
      'I reach out for support and use healthy strategies',
      'I manage on my own but it takes effort',
      'I withdraw and tend to bottle things up',
      'I turn to unhealthy habits or avoidance',
    ],
    dimensions: ['coping'],
  ),
  Question(
    id: 14,
    text:
        'How would you describe your ability to concentrate and make decisions lately?',
    options: [
      'Sharp - I feel clear and focused',
      'Decent - occasional lapses',
      'Struggling - my mind feels foggy often',
      'Very difficult - I can\'t stay on task',
    ],
    dimensions: ['coping'],
  ),
  Question(
    id: 15,
    text:
        'When something difficult happens, how quickly do you tend to recover emotionally?',
    options: [
      'Quickly - I bounce back with perspective',
      'Takes a day or two but I get there',
      'Slowly - I carry it for a long time',
      'I rarely feel like I\'ve fully recovered',
    ],
    dimensions: ['coping', 'resilience'],
  ),
];

/// Calculate scores for each dimension based on answers.
/// 
/// [answers] maps questionId to selectedOptionIndex (0-3).
/// Returns a map of dimensionId to scorePercentage (0.0-1.0).
Map<String, double> calculateDimensionScores(Map<int, int> answers) {
  // Track total points and question count for each dimension
  final Map<String, int> dimensionPoints = {};
  final Map<String, int> dimensionQuestionCount = {};

  // Initialize all dimensions
  for (final dimension in dimensions) {
    dimensionPoints[dimension.id] = 0;
    dimensionQuestionCount[dimension.id] = 0;
  }

  // Process each answer
  for (final question in questions) {
    final answer = answers[question.id];
    if (answer == null) continue;

    // Each answer contributes 0-3 points (index value)
    for (final dimensionId in question.dimensions) {
      dimensionPoints[dimensionId] =
          (dimensionPoints[dimensionId] ?? 0) + answer;
      dimensionQuestionCount[dimensionId] =
          (dimensionQuestionCount[dimensionId] ?? 0) + 1;
    }
  }

  // Calculate percentage scores (0.0-1.0)
  final Map<String, double> scores = {};
  for (final dimension in dimensions) {
    final points = dimensionPoints[dimension.id] ?? 0;
    final count = dimensionQuestionCount[dimension.id] ?? 0;
    if (count > 0) {
      // Max points per question is 3, so max total is count * 3
      scores[dimension.id] = points / (count * 3);
    } else {
      scores[dimension.id] = 0.0;
    }
  }

  return scores;
}

/// Get risk level based on score percentage
RiskLevel getRiskLevel(double score) {
  if (score <= 0.33) return RiskLevel.low;
  if (score <= 0.66) return RiskLevel.moderate;
  return RiskLevel.high;
}

/// Check if user has crisis indicators (Q12 answer is C or D)
bool hasCrisisIndicator(Map<int, int> answers) {
  return (answers[12] ?? 0) >= 2;
}

/// Get overall wellness score (inverse of average risk)
double getOverallWellnessScore(Map<int, int> answers) {
  final scores = calculateDimensionScores(answers);
  if (scores.isEmpty) return 1.0;

  final totalScore = scores.values.reduce((a, b) => a + b);
  final averageRisk = totalScore / scores.length;

  // Invert so higher = better wellness
  return 1.0 - averageRisk;
}

/// Get dimension by ID
Dimension? getDimensionById(String id) {
  try {
    return dimensions.firstWhere((d) => d.id == id);
  } catch (e) {
    return null;
  }
}
