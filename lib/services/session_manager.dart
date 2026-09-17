import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Central Session Manager handling persistent login tokens and user sessions across app launches.
class SessionManager {
  static String? _token;
  static Map<String, dynamic>? _userData;

  static String? get token => _token;
  static Map<String, dynamic>? get userData => _userData;
  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  static List<File> _getSessionFiles() {
    final List<File> list = [];
    try {
      final currentDir = Directory.current;
      list.add(File('${currentDir.path}/spendhike_session.json'));
    } catch (_) {}

    try {
      final tempDir = Directory.systemTemp;
      list.add(File('${tempDir.path}/spendhike_session.json'));
    } catch (_) {}

    list.add(File('spendhike_session.json'));
    return list;
  }

  static Future<bool> init() async {
    if (_token != null && _token!.isNotEmpty) {
      return true;
    }

    try {
      final files = _getSessionFiles();
      for (final file in files) {
        if (await file.exists()) {
          final content = await file.readAsString();
          if (content.isNotEmpty) {
            final data = jsonDecode(content);
            if (data is Map && data['token'] != null && data['token'].toString().isNotEmpty) {
              _token = data['token'].toString();
              _userData = data['user'] is Map ? Map<String, dynamic>.from(data['user']) : null;
              debugPrint('[SessionManager] Persistent login session loaded successfully from ${file.path}');
              return true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[SessionManager] Error loading session: $e');
    }
    return false;
  }

  static Future<void> saveSession(String token, Map<String, dynamic>? user) async {
    _token = token;
    _userData = user;
    try {
      final files = _getSessionFiles();
      final data = jsonEncode({
        'token': token,
        'user': user,
        'savedAt': DateTime.now().toIso8601String(),
      });

      for (final file in files) {
        try {
          await file.writeAsString(data);
        } catch (_) {}
      }
      debugPrint('[SessionManager] Login session saved persistently.');
    } catch (e) {
      debugPrint('[SessionManager] Error saving session: $e');
    }
  }

  static Future<void> clearSession() async {
    _token = null;
    _userData = null;
    try {
      final files = _getSessionFiles();
      for (final file in files) {
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
      debugPrint('[SessionManager] Session cleared.');
    } catch (e) {
      debugPrint('[SessionManager] Error clearing session: $e');
    }
  }
}
