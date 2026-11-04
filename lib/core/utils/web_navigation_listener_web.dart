// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

int? _extractPageIndexFromUrl() {
  try {
    final uri = Uri.base;
    // 1. Check query parameters (?page=11 or ?p=11)
    final pageParam = uri.queryParameters['page'] ?? uri.queryParameters['p'];
    if (pageParam != null) {
      final idx = int.tryParse(pageParam);
      if (idx != null) return idx;
    }

    // 2. Check hash fragment (#page=11, #11, #/11)
    final frag = uri.fragment;
    if (frag.isNotEmpty) {
      String cleanFrag = frag;
      if (cleanFrag.startsWith('/')) cleanFrag = cleanFrag.substring(1);
      if (cleanFrag.startsWith('page=')) cleanFrag = cleanFrag.substring(5);
      final idx = int.tryParse(cleanFrag);
      if (idx != null) return idx;
    }
  } catch (e) {
    debugPrint('[WebNavigation] Error parsing URL: $e');
  }
  return null;
}

void setupWebNavigationListener(void Function(int pageIndex) onNavigate) {
  // 1. Check initial URL query parameters or hash fragment
  final initialIndex = _extractPageIndexFromUrl();
  if (initialIndex != null) {
    debugPrint('[WebNavigation] Initial page from URL: $initialIndex');
    onNavigate(initialIndex);
  }

  // 2. Listen for dynamic hash changes (#page=11)
  html.window.onHashChange.listen((event) {
    final idx = _extractPageIndexFromUrl();
    if (idx != null) {
      debugPrint('[WebNavigation] onHashChange to page: $idx');
      onNavigate(idx);
    }
  });

  // 3. Listen for browser back / forward / popstate changes
  html.window.onPopState.listen((event) {
    final idx = _extractPageIndexFromUrl();
    if (idx != null) {
      debugPrint('[WebNavigation] onPopState to page: $idx');
      onNavigate(idx);
    }
  });

  // 4. Listen for window postMessage events (sent from parent Astro/Qiankun host)
  html.window.onMessage.listen((event) {
    try {
      final data = event.data;
      if (data is Map && data['type'] == 'trivep:navigate') {
        final targetIndex = data['pageIndex'];
        int? parsedIndex;
        if (targetIndex is int) {
          parsedIndex = targetIndex;
        } else if (targetIndex is String) {
          parsedIndex = int.tryParse(targetIndex);
        }
        if (parsedIndex != null) {
          debugPrint('[WebNavigation] Received postMessage navigate to pageIndex: $parsedIndex');
          onNavigate(parsedIndex);
        }
      }
    } catch (e) {
      debugPrint('[WebNavigation] Error handling onMessage: $e');
    }
  });

  // 5. Check initial page index from sessionStorage
  try {
    final stored = html.window.sessionStorage['trivepInitialPage'];
    if (stored != null) {
      final idx = int.tryParse(stored);
      if (idx != null) {
        debugPrint('[WebNavigation] Found initial page in sessionStorage: $idx');
        onNavigate(idx);
      }
      html.window.sessionStorage.remove('trivepInitialPage');
    }
  } catch (e) {
    debugPrint('[WebNavigation] Error reading sessionStorage: $e');
  }

  // 6. Notify parent that Flutter is mounted and ready
  try {
    html.window.parent?.postMessage({'type': 'trivep:ready'}, '*');
  } catch (_) {}
}

/// Updates the browser address bar (?page=X) when navigation occurs on web
void syncWebUrl(int pageIndex) {
  try {
    final currentSearch = html.window.location.search ?? '';
    final newParam = 'page=$pageIndex';
    if (!currentSearch.contains(newParam)) {
      html.window.history.pushState(null, '', '?page=$pageIndex');
    }
  } catch (e) {
    debugPrint('[WebNavigation] Error syncing URL: $e');
  }
}
