import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/config/env.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService()
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: Env.apiKey,
        ) {
    // Verification log (Temporary)
    final keyPrefix = Env.apiKey.length > 5 ? Env.apiKey.substring(0, 7) : 'Invalid';
    debugPrint('GeminiService Initialized with Key starting with: $keyPrefix');
  }

  Future<String> generateTripPlan(String prompt) async {
    final systemPrompt = '''
You are a professional travel planner. 
When a user asks for a trip plan, provide a detailed, friendly, and inspiring response in Markdown.
CRITICAL: Always respond in Traditional Chinese (繁體中文). Do not use English unless specifically asked.
At the end of your response, you MUST include a JSON block enclosed in <PLAN_JSON> and </PLAN_JSON> tags.
The JSON must follow this structure:
{
  "project_name": "Trip Name",
  "days": [
    {
      "label": "Day 1: ...",
      "spots": [
        {
          "name": "Spot Name",
          "description": "Short description",
          "suggested_time": "Time or duration",
          "notes": "Important tips"
        }
      ]
    }
  ]
}
Ensure the JSON is valid and strictly matches the structure.
''';

    final content = [Content.text('$systemPrompt\n\nUser Request: $prompt')];
    try {
      final response = await _model.generateContent(content);
      return response.text ?? 'No response from AI.';
    } catch (e) {
      debugPrint('Gemini Technical Error: $e');
      // Masking key in logs for the user to see without exposing full key
      final keyPreview = Env.apiKey.length > 10 ? "${Env.apiKey.substring(0, 5)}...${Env.apiKey.substring(Env.apiKey.length - 5)}" : "Invalid Key";
      debugPrint('Used Key: $keyPreview');
      
      if (e.toString().contains('blocked')) {
        return '❌ **API 請求被封鎖 (Blocked)**\n\n您看到的技術錯誤為：\n`$e`\n\n**這代表您的 Google Cloud 設定仍有限制。請檢查：**\n1. 是否在 **[GCP Console](https://console.cloud.google.com/apis/credentials)** 完全移除 API 金鑰限制？\n2. 您是否啟用了 **Generative Language API**？\n3. 您的專案是否有結算帳戶 (Billing)？(即使是 Flash 免費版，有時也需要綁定帳戶)。';
      }
      return '❌ **Gemini 發生錯誤**\n\n技術細節：\n`$e`';
    }
  }
}
