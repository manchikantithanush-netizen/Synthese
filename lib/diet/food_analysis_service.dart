import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

enum FoodAnalysisError {
  imageFailed,
  connection,
  emptyText,
  textFailed,
  parseFailed,
}

class FoodAnalysisResult {
  final int estimatedCalories;
  final String description;
  final String foodName;
  final bool success;
  final FoodAnalysisError? errorCode;
  final int protein; // in grams
  final int carbs; // in grams
  final int fats; // in grams
  // Micronutrients
  final int fiber; // g
  final int sugar; // g
  final int sodium; // mg
  final int iron; // mg
  final int calcium; // mg
  final int potassium; // mg
  final int vitaminC; // mg
  final int vitaminD; // μg

  FoodAnalysisResult({
    required this.estimatedCalories,
    required this.description,
    required this.foodName,
    required this.success,
    this.errorCode,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.iron = 0,
    this.calcium = 0,
    this.potassium = 0,
    this.vitaminC = 0,
    this.vitaminD = 0,
  });

  factory FoodAnalysisResult.error(FoodAnalysisError code) {
    return FoodAnalysisResult(
      estimatedCalories: 0,
      description: '',
      foodName: '',
      success: false,
      errorCode: code,
    );
  }
}

class FoodAnalysisService {
  static const String _baseUrl = 'https://synthese-backend.manchikanti-thanush.workers.dev/github';
  static const String _model = 'openai/gpt-4o-mini';
  static const String _appSecret = String.fromEnvironment('APP_SECRET');

  // ── System message ────────────────────────────────────────────────────────
  // Establishes the model as a nutritionist with USDA/FDA grounding.
  // Sent as a separate system turn so it frames every user request.
  static const String _systemMessage =
      'You are a registered dietitian and food scientist with deep knowledge '
      'of USDA FoodData Central and FDA nutritional databases. '
      'Your job is to estimate the nutritional content of meals from photos or '
      'text descriptions as accurately as possible. '
      'Always anchor your estimates to standard USDA database values for the '
      'identified food, then adjust for visible portion size. '
      'Never invent data — if you are uncertain about a micronutrient, use the '
      'known USDA average for a typical serving of that food. '
      'Macronutrients (calories, protein, carbs, fats) must be internally '
      'consistent: calories ≈ (protein × 4) + (carbs × 4) + (fats × 9). '
      'Always respond with valid JSON only — no markdown, no explanation.';

  // ── Image prompt ──────────────────────────────────────────────────────────
  static const String _imagePrompt =
      'Analyze this food photo using the following structured approach:\n\n'
      'STEP 1 — IDENTIFY: What food or dish is this? Be specific '
      '(e.g. "grilled chicken breast" not just "chicken"). '
      'If it is a mixed dish, name the dominant components.\n\n'
      'STEP 2 — PORTION: Estimate the portion size in grams by comparing '
      'the food to visible context clues (plate size, utensils, hands, '
      'packaging). State your estimate explicitly before calculating.\n\n'
      'STEP 3 — CALCULATE: Using USDA FoodData Central values as your '
      'baseline per 100 g, scale all nutrients to your estimated portion. '
      'Verify internal consistency: calories must approximately equal '
      '(protein g × 4) + (carbs g × 4) + (fats g × 9).\n\n'
      'STEP 4 — MICRONUTRIENTS: Use known USDA average values for the '
      'identified food. Do not guess micronutrients visually.\n\n'
      'Respond ONLY in this exact JSON — no markdown, no extra text:\n'
      '{"food_name":"...","portion_g":200,"calories":300,"protein":25,'
      '"carbs":30,"fats":10,"fiber":5,"sugar":8,"sodium":400,"iron":2,'
      '"calcium":150,"potassium":350,"vitamin_c":15,"vitamin_d":1,'
      '"description":"1-2 sentences on nutritional value."}\n\n'
      'If no food is visible, return:\n'
      '{"food_name":"Unknown","portion_g":0,"calories":0,"protein":0,'
      '"carbs":0,"fats":0,"fiber":0,"sugar":0,"sodium":0,"iron":0,'
      '"calcium":0,"potassium":0,"vitamin_c":0,"vitamin_d":0,'
      '"description":"Could not identify food in the image."}';

  // ── Text prompt ───────────────────────────────────────────────────────────
  static String _textPrompt(String foodText) =>
      'Analyze this meal description using the following structured approach:\n\n'
      'STEP 1 — IDENTIFY: What is the most specific food/dish name that '
      'matches this description?\n\n'
      'STEP 2 — PORTION: If a quantity is mentioned (e.g. "2 eggs", '
      '"1 cup rice") use it directly. If not, assume a standard single '
      'serving from USDA FoodData Central.\n\n'
      'STEP 3 — CALCULATE: Use USDA FoodData Central values scaled to the '
      'identified portion. Verify: calories ≈ (protein × 4) + (carbs × 4) '
      '+ (fats × 9).\n\n'
      'STEP 4 — MICRONUTRIENTS: Use known USDA average values for the food. '
      'Do not invent micronutrient data.\n\n'
      'Meal description: "$foodText"\n\n'
      'Respond ONLY in this exact JSON — no markdown, no extra text:\n'
      '{"food_name":"...","portion_g":200,"calories":300,"protein":25,'
      '"carbs":30,"fats":10,"fiber":5,"sugar":8,"sodium":400,"iron":2,'
      '"calcium":150,"potassium":350,"vitamin_c":15,"vitamin_d":1,'
      '"description":"1-2 sentences on nutritional value."}\n\n'
      'If the input is not food or is too vague, return:\n'
      '{"food_name":"Unknown","portion_g":0,"calories":0,"protein":0,'
      '"carbs":0,"fats":0,"fiber":0,"sugar":0,"sodium":0,"iron":0,'
      '"calcium":0,"potassium":0,"vitamin_c":0,"vitamin_d":0,'
      '"description":"Could not estimate from the provided text."}';

  Future<FoodAnalysisResult> analyzeFood(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final extension = imageFile.path.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (extension == 'png') mimeType = 'image/png';
      if (extension == 'gif') mimeType = 'image/gif';
      if (extension == 'webp') mimeType = 'image/webp';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-App-Secret': _appSecret,
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': _systemMessage,
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': _imagePrompt,
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:$mimeType;base64,$base64Image',
                    // 'high' detail gives better portion/food recognition
                    // at the cost of slightly more tokens.
                    'detail': 'high',
                  }
                }
              ]
            }
          ],
          'max_completion_tokens': 400,
        }),
      );

      if (response.statusCode == 200) {
        // Decode as UTF-8 explicitly: the proxy returns `application/json`
        // without a charset, so `response.body` would fall back to latin-1
        // and mangle accented / non-Latin dish names (e.g. "Caffè", 카레).
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'] as String;

        return _parseResponse(content);
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        return FoodAnalysisResult.error(FoodAnalysisError.imageFailed);
      }
    } catch (e) {
      debugPrint('Error analyzing food: $e');
      return FoodAnalysisResult.error(FoodAnalysisError.connection);
    }
  }

  Future<FoodAnalysisResult> analyzeFoodText(String foodText) async {
    final trimmed = foodText.trim();
    if (trimmed.isEmpty) {
      return FoodAnalysisResult.error(FoodAnalysisError.emptyText);
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-App-Secret': _appSecret,
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': _systemMessage,
            },
            {
              'role': 'user',
              'content': _textPrompt(trimmed),
            },
          ],
          'max_completion_tokens': 400,
        }),
      );

      if (response.statusCode == 200) {
        // Decode as UTF-8 explicitly — see note in analyzeFood().
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'] as String;
        return _parseResponse(content);
      } else {
        debugPrint('API Error (text): ${response.statusCode} - ${response.body}');
        return FoodAnalysisResult.error(FoodAnalysisError.textFailed);
      }
    } catch (e) {
      debugPrint('Error analyzing food text: $e');
      return FoodAnalysisResult.error(FoodAnalysisError.connection);
    }
  }

  FoodAnalysisResult _parseResponse(String content) {
    try {
      String jsonStr = content.trim();
      
      // Strip any markdown code fences the model might add despite instructions.
      jsonStr = jsonStr
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .trim();

      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(jsonStr);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(0)!;
      }
      
      final parsed = jsonDecode(jsonStr);
      
      int asInt(dynamic v) {
        if (v is int) return v;
        if (v is num) return v.toInt();
        return int.tryParse(v?.toString() ?? '0') ?? 0;
      }

      final protein  = asInt(parsed['protein']);
      final carbs    = asInt(parsed['carbs']);
      final fats     = asInt(parsed['fats']);
      var   calories = asInt(parsed['calories']);

      // Macro consistency check: if the model's calorie figure diverges
      // more than 20% from the Atwater formula, recalculate from macros.
      // This catches cases where the model miscounts one field.
      final calculatedCals = (protein * 4) + (carbs * 4) + (fats * 9);
      if (calculatedCals > 0 && calories > 0) {
        final deviation = (calories - calculatedCals).abs() / calculatedCals;
        if (deviation > 0.20) {
          // Trust the macro breakdown over the calorie figure.
          calories = calculatedCals;
        }
      } else if (calculatedCals > 0 && calories == 0) {
        calories = calculatedCals;
      }

      return FoodAnalysisResult(
        foodName: parsed['food_name'] ?? 'Unknown Food',
        estimatedCalories: calories,
        protein: protein,
        carbs: carbs,
        fats: fats,
        fiber: asInt(parsed['fiber']),
        sugar: asInt(parsed['sugar']),
        sodium: asInt(parsed['sodium']),
        iron: asInt(parsed['iron']),
        calcium: asInt(parsed['calcium']),
        potassium: asInt(parsed['potassium']),
        vitaminC: asInt(parsed['vitamin_c']),
        vitaminD: asInt(parsed['vitamin_d']),
        description: parsed['description'] ?? 'No description available.',
        success: true,
      );
    } catch (e) {
      debugPrint('Error parsing response: $e');
      debugPrint('Raw content: $content');
      
      // Last-resort fallback: extract any calorie number from free text.
      final calorieMatch = RegExp(
        r'(\d+)\s*(?:cal|kcal|calories)',
        caseSensitive: false,
      ).firstMatch(content);
      if (calorieMatch != null) {
        return FoodAnalysisResult(
          foodName: 'Food Item',
          estimatedCalories: int.parse(calorieMatch.group(1)!),
          description: content.length > 100
              ? '${content.substring(0, 100)}...'
              : content,
          success: true,
        );
      }
      
      return FoodAnalysisResult.error(FoodAnalysisError.parseFailed);
    }
  }
}
