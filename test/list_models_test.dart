import 'dart:io';
import 'dart:convert';
import 'package:google_service_app/core/config/env.dart';
import 'package:test/test.dart';

void main() {
  test('List Available Gemini Models', () async {
    final apiKey = Env.geminiApiKeyPaid;
    
    if (apiKey.isEmpty || apiKey.contains('your_paid_api_key_here')) {
      print('⚠️ PAID API Key is not set.');
      return;
    }

    print('🔑 Querying Google API for available models...');
    
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'));
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final json = jsonDecode(responseBody);
      final models = json['models'] as List<dynamic>?;
      
      if (models != null && models.isNotEmpty) {
        print('\n✅ AVAILABLE MODELS:');
        for (var m in models) {
          final name = m['name'].toString().replaceFirst('models/', '');
          final versions = m['version'];
          print('- $name ($versions)');
        }
      } else {
        print('⚠️ No models found in the response list.');
      }
    } else {
      print('❌ API Request Failed: ${response.statusCode}');
      print('Response: $responseBody');
    }
  });
}
