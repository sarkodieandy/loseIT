import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppLinks {
  static Uri? _parseUrl(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return null;
    return uri;
  }

  /// Configure in `.env` (required for App Store review).
  static Uri? get privacyPolicy => _parseUrl(dotenv.env['PRIVACY_POLICY_URL']);

  /// Configure in `.env` (required for App Store review).
  static Uri? get termsOfUse => _parseUrl(dotenv.env['TERMS_OF_USE_URL']);

  /// Apple Standard EULA (useful if you don't provide a custom EULA in
  /// App Store Connect).
  static Uri get appleStandardEula => Uri.parse(
        'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
      );
}
