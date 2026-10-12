import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'api_service.dart';

/// Structured result of a biometric authentication attempt.
class BiometricAuthResult {
  final bool success;
  final String? errorMessage;
  final bool isCancelled;
  final bool isNotEnrolled;
  final bool isHardwareUnavailable;

  const BiometricAuthResult({
    required this.success,
    this.errorMessage,
    this.isCancelled = false,
    this.isNotEnrolled = false,
    this.isHardwareUnavailable = false,
  });

  factory BiometricAuthResult.succeeded() => const BiometricAuthResult(success: true);

  factory BiometricAuthResult.cancelled([String? message]) => BiometricAuthResult(
        success: false,
        isCancelled: true,
        errorMessage: message ?? 'Authentication was cancelled',
      );

  factory BiometricAuthResult.notEnrolled([String? message]) => BiometricAuthResult(
        success: false,
        isNotEnrolled: true,
        errorMessage: message ?? 'No biometrics enrolled on this device',
      );

  factory BiometricAuthResult.notAvailable([String? message]) => BiometricAuthResult(
        success: false,
        isHardwareUnavailable: true,
        errorMessage: message ?? 'Biometric hardware is not available',
      );

  factory BiometricAuthResult.failed(String message) => BiometricAuthResult(
        success: false,
        errorMessage: message,
      );
}

/// Service managing device biometrics (Fingerprint and Face ID)
/// and persisting secure preferences using flutter_secure_storage.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _keyBiometricEnabled = 'spendhike_biometric_enabled';
  static bool _isAuthenticating = false;

  /// Check whether biometric authentication prompt is currently active
  static bool get isAuthenticating => _isAuthenticating;

  /// Check whether the device hardware supports biometrics
  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('[BiometricService] isDeviceSupported error: $e');
      return false;
    }
  }

  /// Check whether biometric sensors can be checked
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      debugPrint('[BiometricService] canCheckBiometrics error: $e');
      return false;
    }
  }

  /// Get list of available enrolled biometric types on this device
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('[BiometricService] getAvailableBiometrics error: $e');
      return <BiometricType>[];
    }
  }

  /// Check whether biometrics are fully supported and have at least one enrolled credential
  static Future<bool> isBiometricsAvailable() async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return false;

      final canCheck = await canCheckBiometrics();
      final available = await getAvailableBiometrics();

      return (canCheck || available.isNotEmpty) && available.isNotEmpty;
    } catch (e) {
      debugPrint('[BiometricService] isBiometricsAvailable error: $e');
      return false;
    }
  }

  /// Human-readable label for available biometric type (e.g., "Face ID", "Fingerprint", "Biometrics")
  static Future<String> getBiometricTypeLabel() async {
    try {
      final available = await getAvailableBiometrics();
      if (available.contains(BiometricType.face)) {
        return 'Face ID';
      }
      if (available.contains(BiometricType.fingerprint) || available.contains(BiometricType.strong)) {
        return 'Fingerprint';
      }
      if (available.contains(BiometricType.iris)) {
        return 'Iris';
      }
    } catch (_) {}
    return 'Biometrics';
  }

  /// Check whether biometric unlock has been enabled by user
  static Future<bool> isBiometricEnabled() async {
    try {
      final storedVal = await _storage.read(key: _keyBiometricEnabled);
      if (storedVal != null) {
        if (storedVal != 'true') return false;
      } else {
        // Fallback to user model preference if not yet stored locally
        if (ApiService.currentUser != null && ApiService.currentUser!.biometricEnabled) {
          await _storage.write(key: _keyBiometricEnabled, value: 'true');
        } else {
          return false;
        }
      }

      // Verify that device still has active biometrics enrolled
      final isAvailable = await isBiometricsAvailable();
      return isAvailable;
    } catch (e) {
      debugPrint('[BiometricService] Error checking biometric enabled status: $e');
      return false;
    }
  }

  /// Store user's biometric unlock preference securely and sync with backend
  static Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(key: _keyBiometricEnabled, value: enabled ? 'true' : 'false');

      // Sync with user profile on backend if session is active
      if (ApiService.currentUser != null) {
        ApiService.updateProfile({'biometricEnabled': enabled}).catchError((e) {
          debugPrint('[BiometricService] Non-critical profile sync error: $e');
          return false;
        });
      }
      return true;
    } catch (e) {
      debugPrint('[BiometricService] Error saving biometric preference: $e');
      return false;
    }
  }

  /// Clear biometric preference on logout
  static Future<void> clearBiometricPreference() async {
    try {
      await _storage.delete(key: _keyBiometricEnabled);
    } catch (e) {
      debugPrint('[BiometricService] Error clearing biometric preference: $e');
    }
  }

  /// Trigger biometric authentication prompt
  static Future<BiometricAuthResult> authenticate({
    required String localizedReason,
    bool biometricOnly = true,
  }) async {
    if (_isAuthenticating) {
      debugPrint('[BiometricService] Authentication already in progress, skipping duplicate request.');
      return BiometricAuthResult.cancelled('Authentication in progress');
    }

    final isAvailable = await isBiometricsAvailable();
    if (!isAvailable) {
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        return BiometricAuthResult.notAvailable('Biometric hardware is not available on this device');
      }
      return BiometricAuthResult.notEnrolled('No biometrics enrolled on this device');
    }

    _isAuthenticating = true;
    try {
      final bool authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );

      if (authenticated) {
        return BiometricAuthResult.succeeded();
      } else {
        return BiometricAuthResult.cancelled('Authentication was not completed');
      }
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] PlatformException: code=${e.code}, message=${e.message}');
      if (e.code == auth_error.notEnrolled || e.code == auth_error.passcodeNotSet) {
        return BiometricAuthResult.notEnrolled('No biometrics enrolled. Please set up in device settings.');
      } else if (e.code == auth_error.notAvailable) {
        return BiometricAuthResult.notAvailable('Biometric hardware unavailable');
      } else if (e.code == auth_error.lockedOut || e.code == auth_error.permanentlyLockedOut) {
        return BiometricAuthResult.failed('Biometrics locked due to too many failed attempts. Use your passcode.');
      } else if (e.code == 'auth_in_progress') {
        return BiometricAuthResult.cancelled('Authentication already active');
      } else {
        return BiometricAuthResult.failed(e.message ?? 'Biometric authentication failed');
      }
    } catch (e) {
      debugPrint('[BiometricService] Unexpected error: $e');
      return BiometricAuthResult.failed('An unexpected error occurred during biometric authentication');
    } finally {
      _isAuthenticating = false;
    }
  }
}
