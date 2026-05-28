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
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': '''Analyze this food image and provide:
1. The name of the food/dish
2. An estimated calorie count (just the number)
3. Estimated protein in grams (just the number)
4. Estimated carbohydrates in grams (just the number)
5. Estimated fats in grams (just the number)
6. Estimated fiber in grams
7. Estimated sugar in grams
8. Estimated sodium in milligrams
9. Estimated iron in milligrams
10. Estimated calcium in milligrams
11. Estimated potassium in milligrams
12. Estimated vitamin C in milligrams
13. Estimated vitamin D in micrograms
14. A brief description (1-2 sentences about nutritional value or what it contains)

Respond ONLY in this exact JSON format:
{"food_name": "...", "calories": 123, "protein": 25, "carbs": 30, "fats": 10, "fiber": 5, "sugar": 8, "sodium": 400, "iron": 2, "calcium": 150, "potassium": 350, "vitamin_c": 15, "vitamin_d": 1, "description": "..."}

Be realistic with estimates. All numeric fields should be whole numbers. If you cannot identify the food or it's not food, respond with:
{"food_name": "Unknown", "calories": 0, "protein": 0, "carbs": 0, "fats": 0, "fiber": 0, "sugar": 0, "sodium": 0, "iron": 0, "calcium": 0, "potassium": 0, "vitamin_c": 0, "vitamin_d": 0, "description": "Could not identify food in the image."}'''
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:$mimeType;base64,$base64Image'
                  }
                }
              ]
            }
          ],
          'max_completion_tokens': 500,
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
              'role': 'user',
              'content':
                  '''Analyze this meal description and provide:
1. The most likely food/dish name
2. Estimated calorie count (number only)
3. Estimated protein in grams (number only)
4. Estimated carbohydrates in grams (number only)
5. Estimated fats in grams (number only)
6. Estimated fiber in grams
7. Estimated sugar in grams
8. Estimated sodium in milligrams
9. Estimated iron in milligrams
10. Estimated calcium in milligrams
11. Estimated potassium in milligrams
12. Estimated vitamin C in milligrams
13. Estimated vitamin D in micrograms
14. A brief description (1-2 sentences)

Meal description:
"$trimmed"

Respond ONLY in this exact JSON format:
{"food_name": "...", "calories": 123, "protein": 25, "carbs": 30, "fats": 10, "fiber": 5, "sugar": 8, "sodium": 400, "iron": 2, "calcium": 150, "potassium": 350, "vitamin_c": 15, "vitamin_d": 1, "description": "..."}

All numeric fields should be whole numbers. If too vague or not food, respond with:
{"food_name": "Unknown", "calories": 0, "protein": 0, "carbs": 0, "fats": 0, "fiber": 0, "sugar": 0, "sodium": 0, "iron": 0, "calcium": 0, "potassium": 0, "vitamin_c": 0, "vitamin_d": 0, "description": "Could not estimate from the provided text."}''',
            },
          ],
          'max_completion_tokens': 500,
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

      return FoodAnalysisResult(
        foodName: parsed['food_name'] ?? 'Unknown Food',
        estimatedCalories: asInt(parsed['calories']),
        protein: asInt(parsed['protein']),
        carbs: asInt(parsed['carbs']),
        fats: asInt(parsed['fats']),
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
      
      final calorieMatch = RegExp(r'(\d+)\s*(?:cal|kcal|calories)', caseSensitive: false).firstMatch(content);
      if (calorieMatch != null) {
        return FoodAnalysisResult(
          foodName: 'Food Item',
          estimatedCalories: int.parse(calorieMatch.group(1)!),
          description: content.length > 100 ? '${content.substring(0, 100)}...' : content,
          success: true,
        );
      }
      
      return FoodAnalysisResult.error(FoodAnalysisError.parseFailed);
    }
  }
}
