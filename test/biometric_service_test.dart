import 'package:flutter_test/flutter_test.dart';
import 'package:spendhike/services/biometric_service.dart';
import 'package:spendhike/config/app_translations.dart';
import 'package:spendhike/config/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BiometricAuthResult Unit Tests', () {
    test('succeeded factory creates a successful result', () {
      final res = BiometricAuthResult.succeeded();
      expect(res.success, isTrue);
      expect(res.isCancelled, isFalse);
      expect(res.isNotEnrolled, isFalse);
      expect(res.isHardwareUnavailable, isFalse);
      expect(res.errorMessage, isNull);
    });

    test('cancelled factory creates cancelled result with message', () {
      final res = BiometricAuthResult.cancelled('User tapped cancel');
      expect(res.success, isFalse);
      expect(res.isCancelled, isTrue);
      expect(res.errorMessage, equals('User tapped cancel'));
    });

    test('notEnrolled factory creates not enrolled result', () {
      final res = BiometricAuthResult.notEnrolled('No fingerprints registered');
      expect(res.success, isFalse);
      expect(res.isNotEnrolled, isTrue);
      expect(res.errorMessage, equals('No fingerprints registered'));
    });

    test('notAvailable factory creates hardware unavailable result', () {
      final res = BiometricAuthResult.notAvailable('Device has no biometric sensor');
      expect(res.success, isFalse);
      expect(res.isHardwareUnavailable, isTrue);
      expect(res.errorMessage, equals('Device has no biometric sensor'));
    });

    test('failed factory creates error result', () {
      final res = BiometricAuthResult.failed('Too many failed attempts');
      expect(res.success, isFalse);
      expect(res.errorMessage, equals('Too many failed attempts'));
    });
  });

  group('Biometric Bilingual Translations Tests', () {
    test('English translations contain required biometric strings', () {
      expect(AppTranslations.en['Unlock with Biometrics'], equals('Unlock with Biometrics'));
      expect(AppTranslations.en['Enable Biometric Unlock?'], equals('Enable Biometric Unlock?'));
      expect(AppTranslations.en['Biometric Unlock Enabled'], equals('Biometric Unlock Enabled'));
      expect(AppTranslations.en['Biometric Unlock Disabled'], equals('Biometric Unlock Disabled'));
      expect(AppTranslations.en['Not supported on this device'], equals('Not supported on this device'));
      expect(AppTranslations.en['No biometrics enrolled'], equals('No biometrics enrolled'));
      expect(AppTranslations.en['Fingerprint'], equals('Fingerprint'));
      expect(AppTranslations.en['Face ID'], equals('Face ID'));
    });

    test('Hindi translations contain required biometric strings', () {
      expect(AppTranslations.hi['Unlock with Biometrics'], equals('बायोमेट्रिक्स से अनलॉक करें'));
      expect(AppTranslations.hi['Enable Biometric Unlock?'], equals('बायोमेट्रिक अनलॉक सक्षम करें?'));
      expect(AppTranslations.hi['Biometric Unlock Enabled'], equals('बायोमेट्रिक अनलॉक सक्रिय'));
      expect(AppTranslations.hi['Biometric Unlock Disabled'], equals('बायोमेट्रिक अनलॉक अक्षम'));
      expect(AppTranslations.hi['Not supported on this device'], equals('इस डिवाइस पर समर्थित नहीं'));
      expect(AppTranslations.hi['No biometrics enrolled'], equals('कोई बायोमेट्रिक नामांकित नहीं'));
    });
  });

  group('Theme Integration Tests for Biometric Components', () {
    test('Light theme provides valid colors for biometric lock widgets', () {
      final light = AppTheme.lightSemantic;
      expect(light.isDark, isFalse);
      expect(light.primary, equals(AppTheme.primaryBlue));
      expect(light.background, equals(AppTheme.lightBg));
      expect(light.surface, equals(AppTheme.lightSurface));
    });

    test('Dark theme provides valid colors for biometric lock widgets', () {
      final dark = AppTheme.darkSemantic;
      expect(dark.isDark, isTrue);
      expect(dark.primary, equals(AppTheme.primaryBlueDark));
      expect(dark.background, equals(AppTheme.darkBg));
      expect(dark.surface, equals(AppTheme.darkSurface));
    });
  });
}
