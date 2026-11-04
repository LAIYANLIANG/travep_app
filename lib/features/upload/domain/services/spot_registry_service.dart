import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../smart_planning/data/datasources/places_service.dart';

class SpotRegistryService {
  final PlacesService _placesService;
  final SharedPreferences _prefs;
  
  // Database: Spot Name -> {lat, lng} (Verified WGS84 Coordinates)
  final Map<String, Map<String, double>> _registry = {
    '澀谷 SKY': {'lat': 35.6585, 'lng': 139.7022},
    'SHIBUYA SKY': {'lat': 35.6585, 'lng': 139.7022},
    '東京哈利波特影城': {'lat': 35.7450, 'lng': 139.6460},
    '東京哈利波特': {'lat': 35.7450, 'lng': 139.6460},
    '淺草寺雷門': {'lat': 35.7148, 'lng': 139.7967},
    '淺草寺': {'lat': 35.7148, 'lng': 139.7967},
    '東京晴空塔': {'lat': 35.7100, 'lng': 139.8107},
    '東京鐵塔': {'lat': 35.6586, 'lng': 139.7454},
    '明治神宮': {'lat': 35.6764, 'lng': 139.6993},
    '東京國立博物館': {'lat': 35.7188, 'lng': 139.7765},
    '根津神社': {'lat': 35.7202, 'lng': 139.7607},
    '皇居東御苑': {'lat': 35.6868, 'lng': 139.7567},
    '歌舞伎座': {'lat': 35.6696, 'lng': 139.7675},
    '築地場外市場': {'lat': 35.6655, 'lng': 139.7708},
    '上野三井花園飯店': {'lat': 35.7115, 'lng': 139.7780},
    '東京迪士尼': {'lat': 35.6329, 'lng': 139.8804},
    '山下公園': {'lat': 35.4455, 'lng': 139.6506},
    '橫濱紅磚倉庫': {'lat': 35.4526, 'lng': 139.6429},
    '東京車站': {'lat': 35.6812, 'lng': 139.7671},
    '成田國際機場': {'lat': 35.7720, 'lng': 140.3929},
    '羽田機場': {'lat': 35.5494, 'lng': 139.7798},
    '柯南博物館': {'lat': 35.4950, 'lng': 133.7600},
    '川千家': {'lat': 35.7570, 'lng': 139.8770},
  };

  SpotRegistryService(this._placesService, this._prefs) {
    _loadRegistry();
  }

  void _loadRegistry() {
    final String? cached = _prefs.getString('spot_registry_cache');
    if (cached != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(cached);
        decoded.forEach((key, value) {
          _registry[key] = Map<String, double>.from(value);
        });
      } catch (e) {
        // Ignore malformed cache
      }
    }
  }

  Future<void> _saveRegistry() async {
    await _prefs.setString('spot_registry_cache', jsonEncode(_registry));
  }

  String _normalize(String name) {
    final n = name.trim();
    if (n == '明治社宮') return '明治神宮';
    return n;
  }

  Future<Map<String, double>?> lookup(String spotName) async {
    final normalized = _normalize(spotName);

    // 1. Exact match in Registry
    if (_registry.containsKey(normalized)) {
      return _registry[normalized];
    }

    // 2. Fuzzy match in Registry (case-insensitive & bidirectional substring)
    final normLower = normalized.toLowerCase();
    for (var entry in _registry.entries) {
      final kLower = entry.key.toLowerCase();
      if (kLower == normLower || kLower.contains(normLower) || normLower.contains(kLower)) {
        return entry.value;
      }
    }

    // 3. Google Maps Lookup
    try {
      final results = await _placesService.searchPlaces(normalized);
      if (results.isNotEmpty) {
        final first = results.first;
        final coords = {'lat': first.latitude, 'lng': first.longitude};
        
        // Write back (Cache)
        _registry[normalized] = coords;
        _saveRegistry();
        return coords;
      }
    } catch (_) {}

    return null;
  }
  
  void register(String name, double lat, double lng) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    _registry[cleanName] = {'lat': lat, 'lng': lng};

    // Also register base name if it has parentheses (e.g. "聖家堂 (Sagrada Família)" -> "聖家堂")
    if (cleanName.contains('(')) {
      final base = cleanName.split('(')[0].trim();
      if (base.isNotEmpty) {
        _registry[base] = {'lat': lat, 'lng': lng};
      }
    }
    // Also register text inside parentheses (e.g. "Sagrada Família")
    final match = RegExp(r'\((.*?)\)').firstMatch(cleanName);
    if (match != null) {
      final inside = match.group(1)?.trim();
      if (inside != null && inside.isNotEmpty) {
        _registry[inside] = {'lat': lat, 'lng': lng};
      }
    }

    _saveRegistry();
  }

  void registerAll(List<Map<String, dynamic>> spots) {
    for (var s in spots) {
      final name = s['name']?.toString() ?? '';
      final lat = (s['lat'] as num?)?.toDouble();
      final lng = (s['lng'] as num?)?.toDouble();
      if (name.isNotEmpty && lat != null && lng != null && lat != 0.0 && lng != 0.0) {
        final cleanName = name.trim();
        _registry[cleanName] = {'lat': lat, 'lng': lng};
        if (cleanName.contains('(')) {
          final base = cleanName.split('(')[0].trim();
          if (base.isNotEmpty) {
            _registry[base] = {'lat': lat, 'lng': lng};
          }
        }
        final match = RegExp(r'\((.*?)\)').firstMatch(cleanName);
        if (match != null) {
          final inside = match.group(1)?.trim();
          if (inside != null && inside.isNotEmpty) {
            _registry[inside] = {'lat': lat, 'lng': lng};
          }
        }
      }
    }
    _saveRegistry();
  }

  int get count => _registry.length;
  Map<String, Map<String, double>> get allSpots => Map.unmodifiable(_registry);
}
