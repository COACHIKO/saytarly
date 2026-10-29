import '../../services/shared_pref/shared_pref.dart';
import '../../services/shared_pref/pref_keys.dart';

/// Base URL resolution for the core networking layer.
///
/// apps may store a server mode ('cloud'/'local') and an override domain in
/// SharedPreferences; otherwise callers must pass a full base URL.
String getBaseUrl() {
  final sharedPref = SharedPref();
  final domain = sharedPref.getString(PrefKeys.myDomain);
  final serverMode = sharedPref.getString(PrefKeys.serverMode);

  final protocol = (serverMode == 'local') ? 'http' : 'https';
  if (domain == null || domain.isEmpty) {
    throw StateError(
      'No base URL configured. Store the server domain in '
      'SharedPref(${PrefKeys.myDomain}) or provide an explicit baseUrl.',
    );
  }
  return '$protocol://$domain';
}

String getBaseOriginUrl() {
  final url = getBaseUrl();
  return Uri.parse(url).origin;
}

String? adjustUrl(String? url) {
  if (url == null) return null;
  final sharedPref = SharedPref();
  final serverMode = sharedPref.getString(PrefKeys.serverMode);

  if (serverMode == 'local') {
    if (url.startsWith('https://')) {
      return url.replaceFirst('https://', 'http://');
    }
  }
  return url;
}
