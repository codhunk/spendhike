import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

/// Service for managing passcode security using flutter_secure_storage and backend APIs.
class PasscodeService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _keyPasscode = 'spendhike_secure_passcode';
  static const String _keyPasscodeEnabled = 'spendhike_passcode_enabled';
  static const String _keyPasscodeLength = 'spendhike_passcode_length';

  /// Check whether passcode has been configured locally or on backend
  static Future<bool> isPasscodeConfigured() async {
    try {
      final enabledStr = await _storage.read(key: _keyPasscodeEnabled);
      final storedPasscode = await _storage.read(key: _keyPasscode);

      if (enabledStr == 'true' && storedPasscode != null && storedPasscode.isNotEmpty) {
        return true;
      }

      if (ApiService.currentUser != null && ApiService.currentUser!.passcodeConfigured) {
        return true;
      }
    } catch (e) {
      debugPrint('[PasscodeService] Error checking passcode status: $e');
    }

    return false;
  }

  /// Read configured passcode length (4 or 6)
  static Future<int> getPasscodeLength() async {
    try {
      final storedPasscode = await _storage.read(key: _keyPasscode);
      if (storedPasscode != null && storedPasscode.isNotEmpty) {
        return storedPasscode.length;
      }
      final lenStr = await _storage.read(key: _keyPasscodeLength);
      if (lenStr == '6') return 6;
    } catch (_) {}
    return 4;
  }

  /// Store passcode securely locally & sync with backend API
  static Future<Map<String, dynamic>> savePasscode(String passcode) async {
    try {
      await _storage.write(key: _keyPasscode, value: passcode);
      await _storage.write(key: _keyPasscodeEnabled, value: 'true');
      await _storage.write(key: _keyPasscodeLength, value: passcode.length.toString());

      // Sync with backend API silently
      final apiResult = await ApiService.setPasscode(passcode);
      return {
        'success': true,
        'message': 'Passcode stored securely',
        'apiResult': apiResult,
      };
    } catch (e) {
      debugPrint('[PasscodeService] Error saving passcode: $e');
      return {
        'success': false,
        'message': 'Failed to save passcode securely: $e',
      };
    }
  }

  /// Verify entered passcode against stored passcode & backend
  static Future<bool> verifyPasscode(String inputPasscode) async {
    try {
      final storedPasscode = await _storage.read(key: _keyPasscode);
      if (storedPasscode != null && storedPasscode.isNotEmpty) {
        return storedPasscode == inputPasscode;
      }

      // Fallback: Verify via backend API if not found locally
      final apiRes = await ApiService.verifyPasscode(inputPasscode);
      if (apiRes['success'] == true) {
        await savePasscode(inputPasscode);
        return true;
      }
    } catch (e) {
      debugPrint('[PasscodeService] Error verifying passcode: $e');
    }
    return false;
  }

  /// Change passcode: verify old passcode, then save new passcode
  static Future<Map<String, dynamic>> changePasscode({
    required String oldPasscode,
    required String newPasscode,
  }) async {
    final isValidOld = await verifyPasscode(oldPasscode);
    if (!isValidOld) {
      return {
        'success': false,
        'message': 'Current passcode is incorrect',
      };
    }

    final saveRes = await savePasscode(newPasscode);
    final apiRes = await ApiService.changePasscode(oldPasscode, newPasscode);

    return {
      'success': saveRes['success'] == true,
      'message': apiRes['message'] ?? 'Passcode updated successfully',
    };
  }

  /// Re-authenticate user using original password for forgot passcode flow
  static Future<Map<String, dynamic>> verifyPasswordForReset(String password) async {
    try {
      final res = await ApiService.verifyPasswordForReset(password);
      if (res['success'] == true) {
        return {'success': true, 'message': 'Password verified'};
      }

      // Fallback: Verify with login API if user is logged in
      if (ApiService.currentUser != null && ApiService.currentUser!.email.isNotEmpty) {
        final loginRes = await ApiService.login(ApiService.currentUser!.email, password);
        if (loginRes['success'] == true) {
          return {'success': true, 'message': 'Password verified'};
        }
      }
    } catch (e) {
      debugPrint('[PasscodeService] Error verifying password for reset: $e');
    }

    return {'success': false, 'message': 'Incorrect password. Please enter your valid account password.'};
  }

  /// Clear stored passcode from secure storage (e.g. on logout)
  static Future<void> clearPasscode() async {
    try {
      await _storage.delete(key: _keyPasscode);
      await _storage.delete(key: _keyPasscodeEnabled);
      await _storage.delete(key: _keyPasscodeLength);
      _pausedTime = null;
    } catch (e) {
      debugPrint('[PasscodeService] Error clearing passcode: $e');
    }
  }

  // ─── APP BACKGROUND AUTO-LOCK TRACKING ────────────────────────────────────
  static DateTime? _pausedTime;

  /// Record timestamp when app enters background / paused state
  static void recordAppPaused() {
    _pausedTime = DateTime.now();
  }

  /// Check if app should trigger Passcode Lock on app resume (default 10 seconds of background inactivity)
  static Future<bool> shouldLockOnResume({int autoLockThresholdSeconds = 10}) async {
    if (_pausedTime == null) return false;
    final elapsed = DateTime.now().difference(_pausedTime!).inSeconds;
    _pausedTime = null;

    if (elapsed >= autoLockThresholdSeconds) {
      return await isPasscodeConfigured();
    }
    return false;
  }
}

