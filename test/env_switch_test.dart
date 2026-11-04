import 'package:flutter_test/flutter_test.dart';
import 'package:google_service_app/core/config/env.dart';

void main() {
  test('Env Switching Mechanism Test', () {
    // 1. Test Default (Free)
    Env.usePaidKey = false;
    final freeKey = Env.apiKey;
    print('Default/Free Key Prefix: ${freeKey.substring(0, 4)}...');
    
    // 2. Test Switch to Paid
    Env.usePaidKey = true;
    final paidKey = Env.apiKey;
    print('Switch to Paid Key Prefix: ${paidKey.substring(0, 4)}...');

    // 3. Verify they are different (assuming user provided different keys)
    if (freeKey == paidKey) {
      print('⚠️ Warning: Free and Paid keys appear identical. (Did you set them to the same value?)');
    } else {
      print('✅ Success: Keys switched successfully.');
    }
    
    expect(Env.apiKey, equals(Env.geminiApiKeyPaid));
    
    // 4. Switch back
    Env.usePaidKey = false;
    expect(Env.apiKey, equals(Env.geminiApiKeyFree));
  });
}
