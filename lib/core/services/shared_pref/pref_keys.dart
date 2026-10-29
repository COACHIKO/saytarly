/// Storage keys used by the core app.
///
/// Each feature app may extend this by adding its own key class
/// (e.g. `CafeKeys`) alongside these core keys.
class PrefKeys {
  // ── Theme & language ────────────────────────────────────────────────────────
  static const String themeMode = 'themeMode';
  static const String accentColorIndex = 'accentColorIndex';
  static const String language = 'language';

  // ── Auth (generic) ──────────────────────────────────────────────────────────
  static const String accessToken = 'accessToken';
  static const String isRemember = 'rememberMe';
  static const String token = 'token';
  static const String isAuthenticated = 'isAuthenticated';
  static const String userId = 'userId';
  static const String userRole = 'userRole';

  // ── Profile (generic) ───────────────────────────────────────────────────────
  static const String firstName = 'firstName';
  static const String lastName = 'lastName';
  static const String email = 'email';

  // ── Networking (generic) ────────────────────────────────────────────────────
  static const String myDomain = 'myDomain';
  static const String serverMode = 'serverMode';
}
