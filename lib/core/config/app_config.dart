abstract final class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static void validate() {
    validateValues(url: supabaseUrl, publishableKey: supabasePublishableKey);
  }

  static void validateValues({
    required String url,
    required String publishableKey,
  }) {
    if (url.trim().isEmpty) {
      throw StateError('SUPABASE_URL is not configured.');
    }

    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw StateError('SUPABASE_URL must be a valid HTTPS URL.');
    }
    if (uri.host.contains('your-project-ref')) {
      throw StateError('SUPABASE_URL still uses the example placeholder.');
    }

    if (publishableKey.trim().isEmpty) {
      throw StateError('SUPABASE_PUBLISHABLE_KEY is not configured.');
    }

    final normalizedKey = publishableKey.trim().toLowerCase();
    if (normalizedKey == 'your-supabase-publishable-key') {
      throw StateError(
        'SUPABASE_PUBLISHABLE_KEY still uses the example placeholder.',
      );
    }
    if (normalizedKey.startsWith('sb_secret_') ||
        normalizedKey.contains('service_role')) {
      throw StateError(
        'A Supabase secret or service-role key must not be used in the app.',
      );
    }
  }
}
