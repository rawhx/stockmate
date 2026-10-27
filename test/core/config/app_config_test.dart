import 'package:flutter_test/flutter_test.dart';
import 'package:stockmate/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('accepts a valid URL and publishable key', () {
      expect(
        () => AppConfig.validateValues(
          url: 'https://example.supabase.co',
          publishableKey: 'sb_publishable_example',
        ),
        returnsNormally,
      );
    });

    test('rejects an empty URL', () {
      expect(
        () => AppConfig.validateValues(
          url: '',
          publishableKey: 'sb_publishable_example',
        ),
        throwsStateError,
      );
    });

    test('rejects a non-HTTPS URL', () {
      expect(
        () => AppConfig.validateValues(
          url: 'http://example.supabase.co',
          publishableKey: 'sb_publishable_example',
        ),
        throwsStateError,
      );
    });

    test('rejects an empty publishable key', () {
      expect(
        () => AppConfig.validateValues(
          url: 'https://example.supabase.co',
          publishableKey: '',
        ),
        throwsStateError,
      );
    });

    test('rejects example placeholder values', () {
      expect(
        () => AppConfig.validateValues(
          url: 'https://your-project-ref.supabase.co',
          publishableKey: 'sb_publishable_example',
        ),
        throwsStateError,
      );
      expect(
        () => AppConfig.validateValues(
          url: 'https://example.supabase.co',
          publishableKey: 'your-supabase-publishable-key',
        ),
        throwsStateError,
      );
    });

    test('rejects secret and service-role keys', () {
      expect(
        () => AppConfig.validateValues(
          url: 'https://example.supabase.co',
          publishableKey: 'sb_secret_example',
        ),
        throwsStateError,
      );
      expect(
        () => AppConfig.validateValues(
          url: 'https://example.supabase.co',
          publishableKey: 'service_role_example',
        ),
        throwsStateError,
      );
    });
  });
}
