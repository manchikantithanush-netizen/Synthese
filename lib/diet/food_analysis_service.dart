import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FoodAnalysisResult {
  final int estimatedCalories;
  final String description;
  final String foodName;
  final bool success;
  final String? errorMessage;
  final int protein; // in grams
  final int carbs; // in grams
  final int fats; // in grams

  FoodAnalysisResult({
    required this.estimatedCalories,
    required this.description,
    required this.foodName,
    required this.success,
    this.errorMessage,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
  });

  factory FoodAnalysisResult.error(String message) {
    return FoodAnalysisResult(
      estimatedCalories: 0,
      description: '',
      foodName: '',
      success: false,
      errorMessage: message,
      protein: 0,
      carbs: 0,
      fats: 0,
    );
  }
}

class FoodAnalysisService {
  static String get _token => dotenv.env['GITHUB_TOKEN'] ?? '';
  static const String _model = 'meta/llama-4-scout-17b-16e-instruct';
  static const String _baseUrl = 'https://models.github.ai/inference/chat/completions';

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
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/vnd.github+json',
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
6. A brief description (1-2 sentences about nutritional value or what it contains)

Respond ONLY in this exact JSON format:
{"food_name": "...", "calories": 123, "protein": 25, "carbs": 30, "fats": 10, "description": "..."}

Be realistic with estimates. If you cannot identify the food or it's not food, respond with:
{"food_name": "Unknown", "calories": 0, "protein": 0, "carbs": 0, "fats": 0, "description": "Could not identify food in the image."}'''
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
          'max_completion_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        return _parseResponse(content);
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        return FoodAnalysisResult.error('Failed to analyze image. Please try again.');
      }
    } catch (e) {
      debugPrint('Error analyzing food: $e');
      return FoodAnalysisResult.error('An error occurred. Please check your connection.');
    }
  }

  FoodAnalysisResult _parseResponse(String content) {
    try {
      String jsonStr = content.trim();
      
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(jsonStr);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(0)!;
      }
      
      final parsed = jsonDecode(jsonStr);
      
      return FoodAnalysisResult(
        foodName: parsed['food_name'] ?? 'Unknown Food',
        estimatedCalories: (parsed['calories'] is int) 
            ? parsed['calories'] 
            : int.tryParse(parsed['calories'].toString()) ?? 0,
        protein: (parsed['protein'] is int)
            ? parsed['protein']
            : int.tryParse(parsed['protein']?.toString() ?? '0') ?? 0,
        carbs: (parsed['carbs'] is int)
            ? parsed['carbs']
            : int.tryParse(parsed['carbs']?.toString() ?? '0') ?? 0,
        fats: (parsed['fats'] is int)
            ? parsed['fats']
            : int.tryParse(parsed['fats']?.toString() ?? '0') ?? 0,
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
      
      return FoodAnalysisResult.error('Could not parse the analysis result.');
    }
  }
}
