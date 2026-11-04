import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_service_app/core/config/env.dart';

void main() {
  test('Gemini API Connection Test (FREE)', () async {
    final apiKey = Env.geminiApiKeyFree;
    print('🔑 Testing with FREE API Key (prefix): ${apiKey.substring(0, 4)}...');

    if (apiKey.isEmpty || apiKey.contains('your_free_api_key_here')) {
      fail('FREE API Key is not set or is still the default value.');
    }

    try {
      // Create a model just to get the client, but actually use listModels method if available 
      // or try a different approach. The SDK generic client isn't exposed easily from GenerativeModel.
      // Actually, GenerativeModel doesn't have listModels. We need to use the static method if available or just try a different known model.
      
      // Since SDK structure is simple:
    final modelsToTest = [
      'gemini-2.5-flash',
      'gemini-2.5-pro',
      'gemini-3-pro-preview'
    ];

    bool success = false;

    for (final modelName in modelsToTest) {
      print('\n🧪 Attempting model: $modelName...');
      try {
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        final content = [Content.text('Hello, are you online?')];
        final response = await model.generateContent(content);
        
        print('✅ SUCCESS with $modelName!');
        print('🤖 Response: ${response.text}');
        success = true;
        break; // Exit loop on first success
      } catch (e) {
        print('❌ Failed with $modelName: $e');
      }
    }

    if (!success) {
      fail('All models failed to connect.');
    }
      
    } catch (e) {
      print('Error detail: $e');
      fail('Still failing: $e');
    }
  });
}
