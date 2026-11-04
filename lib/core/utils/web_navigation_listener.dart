import 'web_navigation_listener_stub.dart'
    if (dart.library.html) 'web_navigation_listener_web.dart';

/// Listens for web cross-frame navigation messages from Qiankun / Astro host or URL changes.
void listenToWebNavigation(void Function(int pageIndex) onNavigate) {
  setupWebNavigationListener(onNavigate);
}

/// Updates the browser address bar (?page=X) when navigation occurs on web.
void updateWebUrl(int pageIndex) {
  syncWebUrl(pageIndex);
}
