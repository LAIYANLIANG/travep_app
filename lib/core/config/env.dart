import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'GEMINI_API_KEY_FREE', obfuscate: true)
  static final String geminiApiKeyFree = _Env.geminiApiKeyFree;

  @EnviedField(varName: 'GEMINI_API_KEY_PAID', obfuscate: true)
  static final String geminiApiKeyPaid = _Env.geminiApiKeyPaid;
  
  @EnviedField(varName: 'GOOGLE_MAPS_API_KEY', obfuscate: true)
  static final String googleMapsApiKey = _Env.googleMapsApiKey;

  @EnviedField(varName: 'GOOGLE_PLACES_API_KEY', obfuscate: true)
  static final String googlePlacesApiKey = _Env.googlePlacesApiKey;

  // --- Switching Mechanism ---
  static bool usePaidKey = false; // Default to Free Key

  static String get apiKey => usePaidKey ? geminiApiKeyPaid : geminiApiKeyFree;

  // Ensure 'Places API (New)' is enabled in GCP.
  static String get placesApiKey => googlePlacesApiKey;
}
