class AppConfig {
  AppConfig._();

  static const String defaultServerUrl = String.fromEnvironment(
    'ODOO_DEFAULT_URL',
    defaultValue: '',
  );

  static const String defaultDatabase = String.fromEnvironment(
    'ODOO_DEFAULT_DB',
    defaultValue: '',
  );

  static const String _requireHttpsValue = String.fromEnvironment(
    'ODOO_REQUIRE_HTTPS',
    defaultValue: 'true',
  );

  static bool get requireHttps =>
      _requireHttpsValue.toLowerCase().trim() != 'false';

  static String normalizeServerUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return '';

    final hasScheme = url.startsWith('http://') || url.startsWith('https://');
    if (!hasScheme) {
      url = '${requireHttps ? 'https' : 'http'}://$url';
    }

    return url.replaceFirst(RegExp(r'/+$'), '');
  }
}
