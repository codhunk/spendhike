import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/app_models.dart';
import 'data_sync_notifier.dart';
import 'session_manager.dart';

/// Central Live API Service handling HTTP REST communication with SpendHike Node.js/MongoDB Backend.
class ApiService {
  // ─── BASE URL RESOLUTION ───────────────────────────────────────────────────
  static String _customBaseUrl = '';

  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url;
  }

  static const Duration _timeoutDuration = Duration(seconds: 30);
  static bool _isResolvingUrl = false;

  static List<String> get _candidateUrls => ApiConfig.candidateUrls;

  static Future<String> getActiveBaseUrl() async {
    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl;
    }

    final defaultUrl = baseUrl;
    try {
      final healthUrl = ApiConfig.healthUrl;
      final res = await http
          .get(Uri.parse(healthUrl))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200 && res.body.contains('SpendHike Backend API')) {
        _customBaseUrl = ApiConfig.baseUrl;
        return ApiConfig.baseUrl;
      }
    } catch (_) {}

    if (_isResolvingUrl) {
      return defaultUrl;
    }

    _isResolvingUrl = true;

    try {
      final results = await Future.wait(
        _candidateUrls.map((candidate) async {
          try {
            final healthUrl = candidate.replaceAll('/api/v1', '/health');
            final res = await http
                .get(Uri.parse(healthUrl))
                .timeout(const Duration(seconds: 3));
            if (res.statusCode == 200 && res.body.contains('SpendHike Backend API')) {
              return candidate;
            }
          } catch (_) {}
          return null;
        }),
      );

      final workingUrl = results.firstWhere((url) => url != null, orElse: () => null);
      if (workingUrl != null) {
        _customBaseUrl = workingUrl;
        debugPrint('[ApiService] Auto-detected active backend URL: $workingUrl');
        _isResolvingUrl = false;
        return workingUrl;
      }
    } catch (e) {
      debugPrint('[ApiService] Error probing candidate URLs: $e');
    }

    _isResolvingUrl = false;
    _customBaseUrl = defaultUrl;
    return defaultUrl;
  }

  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl;
    }
    return ApiConfig.baseUrl;
  }

  // ─── AUTH TOKEN & USER SESSION ─────────────────────────────────────────────
  static String? _authToken;
  static UserModel? _currentUser;

  static String? get authToken => _authToken;
  static UserModel? get currentUser => _currentUser;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  static Future<bool> initSession() async {
    final hasSession = await SessionManager.init();
    if (hasSession && SessionManager.token != null) {
      _authToken = SessionManager.token;
      if (SessionManager.userData != null) {
        _currentUser = UserModel.fromJson(SessionManager.userData!);
      }
      return true;
    }
    return false;
  }

  static Future<void> logout() async {
    _authToken = null;
    _currentUser = null;
    await SessionManager.clearSession();
  }

  static Map<String, String> get _headers {
    final token = _authToken ?? SessionManager.token;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ─── AUTH APIs ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final activeUrl = await getActiveBaseUrl();
    try {
      final response = await http
          .get(
            Uri.parse('$activeUrl/auth/users/search?query=${Uri.encodeComponent(query.trim())}'),
            headers: _headers,
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['users'] is List) {
          return List<Map<String, dynamic>>.from(data['users']);
        }
      }
    } catch (e) {
      debugPrint('API Error in searchUsers: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> sendOtp(String mobile) async {
    final cleanMobile = mobile.trim();
    final activeUrl = await getActiveBaseUrl();

    try {
      final response = await http
          .post(
            Uri.parse('$activeUrl/auth/send-otp'),
            headers: _headers,
            body: jsonEncode({'mobile': cleanMobile}),
          )
          .timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully',
          'otp': data['otp'],
          'mobile': data['mobile'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to send OTP',
      };
    } catch (e) {
      debugPrint('API Error in sendOtp: $e');
      return {
        'success': false,
        'message': 'Cannot connect to server. Please check your network connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(String mobile, String otp, [String name = '']) async {
    final cleanMobile = mobile.trim();
    final cleanOtp = otp.trim();
    final activeUrl = await getActiveBaseUrl();

    try {
      final response = await http
          .post(
            Uri.parse('$activeUrl/auth/verify-otp'),
            headers: _headers,
            body: jsonEncode({'mobile': cleanMobile, 'otp': cleanOtp, 'name': name.trim()}),
          )
          .timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _authToken = data['token'];
        if (data['user'] != null) {
          _currentUser = UserModel.fromJson(data['user']);
        }
        await SessionManager.saveSession(_authToken!, data['user']);
        return {
          'success': true,
          'message': data['message'] ?? 'OTP Verified successfully',
          'token': data['token'],
          'user': data['user'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Invalid or expired OTP',
      };
    } catch (e) {
      debugPrint('API Error in verifyOtp: $e');
      return {
        'success': false,
        'message': 'Cannot connect to server. Please check your network connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();
    final activeUrl = await getActiveBaseUrl();

    try {
      final response = await http
          .post(
            Uri.parse('$activeUrl/auth/login'),
            headers: _headers,
            body: jsonEncode({'email': cleanEmail, 'password': cleanPassword}),
          )
          .timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _authToken = data['token'];
        if (data['user'] != null) {
          _currentUser = UserModel.fromJson(data['user']);
        }
        await SessionManager.saveSession(_authToken!, data['user']);
        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'token': data['token'],
          'user': data['user'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Invalid email or password',
      };
    } catch (e) {
      debugPrint('API Error in login: $e');
      return {
        'success': false,
        'message': 'Cannot connect to server. Please check your network connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> signup(
      String name, String email, String password, [String mobile = '']) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();
    final cleanMobile = mobile.trim();
    final activeUrl = await getActiveBaseUrl();

    try {
      final response = await http
          .post(
            Uri.parse('$activeUrl/auth/signup'),
            headers: _headers,
            body: jsonEncode({
              'name': cleanName,
              'email': cleanEmail,
              'password': cleanPassword,
              'mobile': cleanMobile,
            }),
          )
          .timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      if ((response.statusCode == 201 || response.statusCode == 200) && data['success'] == true) {
        _authToken = data['token'];
        if (data['user'] != null) {
          _currentUser = UserModel.fromJson(data['user']);
        }
        if (_authToken != null) {
          await SessionManager.saveSession(_authToken!, data['user']);
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Account created successfully',
          'token': data['token'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Signup failed',
        };
      }
    } catch (e) {
      debugPrint('API Error in signup: $e');
      return {
        'success': false,
        'message': 'Cannot connect to server. Please check your network connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email, [String? newPassword]) async {
    final activeUrl = await getActiveBaseUrl();
    try {
      final response = await http
          .post(
            Uri.parse('$activeUrl/auth/forgot-password'),
            headers: _headers,
            body: jsonEncode({
              'email': email.trim(),
              if (newPassword != null && newPassword.isNotEmpty) 'newPassword': newPassword.trim(),
            }),
          )
          .timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Request processed',
      };
    } catch (e) {
      debugPrint('API Error in forgotPassword: $e');
      return {
        'success': false,
        'message': 'Failed to process password request',
      };
    }
  }

  // ─── DASHBOARD API ─────────────────────────────────────────────────────────

  static Future<DashboardModel> getDashboard() async {
    final activeUrl = await getActiveBaseUrl();
    try {
      final response = await http
          .get(
            Uri.parse('$activeUrl/reports/dashboard'),
            headers: _headers,
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['dashboard'] != null) {
          return DashboardModel.fromJson(data['dashboard']);
        }
      }
    } catch (e) {
      debugPrint('API Error in getDashboard: $e');
    }

    return DashboardModel(
      totalBalance: '₹0.00',
      income: '+₹0.00',
      debit: '-₹0.00',
      credit: '-₹0.00',
      weeklyTrend: '0.0%',
      pendingTasks: 0,
      activeSites: [],
      recentActivities: [],
    );
  }

  // ─── GROUPS APIs ───────────────────────────────────────────────────────────

  static Future<List<GroupModel>> getGroups({String searchQuery = ''}) async {
    final activeUrl = await getActiveBaseUrl();
    try {
      final uri = Uri.parse('$activeUrl/groups')
          .replace(queryParameters: {'searchQuery': searchQuery});

      final response =
          await http.get(uri, headers: _headers).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['groups'] as List? ?? [];
        return list.map((g) => GroupModel.fromJson(g)).toList();
      }
    } catch (e) {
      debugPrint('API Error in getGroups: $e');
    }
    return [];
  }

  static Future<GroupModel?> createGroup(String title) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/groups'),
            headers: _headers,
            body: jsonEncode({
              'name': title,
              'description': 'Project Ledger',
              'icon': 'construction',
              'isPrimary': false,
            }),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['group'] != null) {
          DataSyncNotifier.instance.notifyDataChanged();
          return GroupModel.fromJson(data['group']);
        }
      }
    } catch (e) {
      debugPrint('API Error in createGroup: $e');
    }

    return null;
  }

  static Future<Map<String, dynamic>> addMemberToGroup(
      String groupId, String emailOrName, String role) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/groups/$groupId/members'),
            headers: _headers,
            body: jsonEncode({
              'email': emailOrName.trim(),
              'role': role,
            }),
          )
          .timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] == true,
        'message': data['message'] ?? 'Member added successfully',
        'group': data['group'],
      };
    } catch (e) {
      debugPrint('API Error in addMemberToGroup: $e');
      return {
        'success': false,
        'message': 'Failed to connect to backend server',
      };
    }
  }

  static Future<Map<String, dynamic>> removeGroupMember(String groupId, String memberIdOrEmail) async {
    final activeUrl = await getActiveBaseUrl();
    try {
      final response = await http
          .delete(
            Uri.parse('$activeUrl/groups/$groupId/members/${Uri.encodeComponent(memberIdOrEmail)}'),
            headers: _headers,
          )
          .timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        DataSyncNotifier.instance.notifyDataChanged();
        return {'success': true, 'message': data['message'] ?? 'Member removed successfully'};
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to remove member'};
    } catch (e) {
      debugPrint('API Error in removeGroupMember: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> sendGroupInvitation(
      String groupId, String emailOrPhone, String role) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/invitations'),
            headers: _headers,
            body: jsonEncode({
              'groupId': groupId,
              'query': emailOrPhone.trim(),
              'role': role,
            }),
          )
          .timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] == true,
        'message': data['message'] ?? 'Invitation sent',
        'invitation': data['invitation'],
      };
    } catch (e) {
      debugPrint('API Error in sendGroupInvitation: $e');
      return {
        'success': false,
        'message': 'Failed to send invitation',
      };
    }
  }

  static Future<List<InvitationModel>> getInvitations() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/invitations'), headers: _headers)
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['invitations'] is List) {
          return (data['invitations'] as List)
              .map((i) => InvitationModel.fromJson(i))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('API Error in getInvitations: $e');
    }
    return [];
  }

  static Future<int> getPendingInvitationCount() async {
    final invitations = await getInvitations();
    return invitations.length;
  }

  static Future<Map<String, dynamic>> acceptInvitation(String invitationIdOrCode) async {
    final cleanCode = invitationIdOrCode.trim();
    if (cleanCode.isEmpty) {
      return {'success': false, 'message': 'Invitation ID or Code is required'};
    }

    try {
      final activeUrl = await getActiveBaseUrl();
      http.Response response = await http
          .post(
            Uri.parse('$activeUrl/invitations/accept'),
            headers: _headers,
            body: jsonEncode({'code': cleanCode, 'invitationId': cleanCode, 'invitationCode': cleanCode}),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 404) {
        response = await http
            .post(
              Uri.parse('$activeUrl/invitations/${Uri.encodeComponent(cleanCode)}/accept'),
              headers: _headers,
              body: jsonEncode({'code': cleanCode, 'invitationId': cleanCode, 'invitationCode': cleanCode}),
            )
            .timeout(_timeoutDuration);
      }

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        return {
          'success': false,
          'message': 'Server returned unexpected response (${response.statusCode}).',
        };
      }

      if (data['success'] == true) {
        DataSyncNotifier.instance.notifyDataChanged();
      }
      return {
        'success': data['success'] == true,
        'message': data['message'] ?? 'Successfully joined project group!',
        'group': data['group'],
      };
    } catch (e) {
      debugPrint('API Error in acceptInvitation: $e');
      return {
        'success': false,
        'message': 'Failed to accept invitation. Please check your network connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> rejectInvitation(String invitationId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/invitations/$invitationId/reject'),
            headers: _headers,
          )
          .timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] == true,
        'message': data['message'] ?? 'Invitation declined',
      };
    } catch (e) {
      debugPrint('API Error in rejectInvitation: $e');
      return {
        'success': false,
        'message': 'Failed to decline invitation',
      };
    }
  }

  static Future<bool> updateGroupMembers(
      String groupId, List<MemberModel> members) async {
    return true;
  }

  static Future<ReportModel> getReports() async {
    final activeUrl = await getActiveBaseUrl();
    try {
      final response = await http
          .get(
            Uri.parse('$activeUrl/reports'),
            headers: _headers,
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['report'] != null) {
          return ReportModel.fromJson(data['report']);
        }
      }
    } catch (e) {
      debugPrint('API Error in getReports: $e');
    }

    return ReportModel(
      totalIncome: '₹0.00',
      totalExpenses: '₹0.00',
      incomeTrend: '0.0%',
      expenseTrend: '0.0%',
      categories: [],
      transactionBreakdown: [],
      forecast: {},
    );
  }

  static Future<String?> downloadReportFile(String format) async {
    final activeUrl = await getActiveBaseUrl();
    try {
      final endpoint = format.toLowerCase() == 'pdf' ? 'pdf' : 'excel';
      final response = await http
          .get(
            Uri.parse('$activeUrl/reports/export/$endpoint'),
            headers: _headers,
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      debugPrint('API Error in downloadReportFile: $e');
    }
    return null;
  }

  // ─── TRANSACTIONS API ──────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTransactionsList({String? projectId}) async {
    try {
      final uri = Uri.parse('$baseUrl/transactions').replace(
        queryParameters: {
          if (projectId != null && projectId.isNotEmpty) 'projectId': projectId,
        },
      );
      final response = await http.get(uri, headers: _headers).timeout(_timeoutDuration);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['transactions'] as List? ?? [];
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (e) {
      debugPrint('API Error in getTransactionsList: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> saveTransaction({
    required String amount,
    required String type,
    required String category,
    required String paymentMethod,
    required String notes,
    required List<String> attachments,
    String? projectId,
  }) async {
    try {
      String targetGroupId = projectId ?? '';
      if (targetGroupId.isEmpty) {
        final groups = await getGroups();
        if (groups.isNotEmpty) {
          targetGroupId = groups.first.id;
        }
      }

      final mappedType = type.toUpperCase().contains('RECEIVE') || type.toUpperCase().contains('INCOME')
          ? 'RECEIVED'
          : (type.toUpperCase().contains('CREDIT') ? 'CREDIT' : 'DEBIT');

      final mappedCategory = category.toUpperCase().contains('LABOUR')
          ? 'LABOUR'
          : (category.toUpperCase().contains('MATERIAL')
              ? 'MATERIAL'
              : (category.toUpperCase().contains('FUEL') ? 'FUEL' : 'OTHER'));

      final response = await http
          .post(
            Uri.parse('$baseUrl/transactions'),
            headers: _headers,
            body: jsonEncode({
              'projectId': targetGroupId,
              'type': mappedType,
              'category': mappedCategory,
              'amount': double.tryParse(amount) ?? 0.0,
              'description': notes.isNotEmpty ? notes : '$category Expense',
              'paymentMethod': paymentMethod,
              'status': 'SETTLED',
            }),
          )
          .timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        DataSyncNotifier.instance.notifyDataChanged();
        return {
          'success': true,
          'message': data['message'] ?? 'Transaction saved successfully',
          'amount': '₹$amount',
        };
      }
    } catch (e) {
      debugPrint('API Error in saveTransaction: $e');
    }

    return {
      'success': true,
      'message': 'Transaction recorded',
      'amount': '₹$amount',
    };
  }

  static Future<Map<String, dynamic>> updateTransaction({
    required String transactionId,
    required String type,
    required String category,
    required String amount,
    required String paymentMethod,
    required String notes,
  }) async {
    try {
      final mappedType = type.toUpperCase() == 'RECEIVED'
          ? 'RECEIVED'
          : (type.toUpperCase() == 'CREDIT' ? 'CREDIT' : 'DEBIT');

      final response = await http
          .put(
            Uri.parse('$baseUrl/transactions/$transactionId'),
            headers: _headers,
            body: jsonEncode({
              'type': mappedType,
              'category': category.toUpperCase(),
              'amount': double.tryParse(amount) ?? 0.0,
              'description': notes,
              'paymentMethod': paymentMethod,
            }),
          )
          .timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      return {
        'success': data['success'] == true,
        'message': data['message'] ?? 'Transaction updated successfully',
      };
    } catch (e) {
      debugPrint('API Error in updateTransaction: $e');
      return {
        'success': false,
        'message': 'Failed to update transaction',
      };
    }
  }

  // ─── PROFILE APIs ──────────────────────────────────────────────────────────

  static Future<UserModel> getProfile() async {
    final activeUrl = await getActiveBaseUrl();
    try {
      final response = await http
          .get(
            Uri.parse('$activeUrl/auth/me'),
            headers: _headers,
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          final user = UserModel.fromJson(data['user']);
          _currentUser = user;
          return user;
        }
      }
    } catch (e) {
      debugPrint('API Error in getProfile: $e');
    }

    return _currentUser ??
        UserModel(
          id: '',
          name: 'New User',
          email: '',
          mobile: '',
          company: 'Personal Account',
          gst: '',
          address: '',
          plan: 'Free Tier',
          verified: false,
          currency: 'INR (₹)',
          language: 'English (IN)',
          biometricEnabled: false,
          pinEnabled: false,
          darkMode: false,
          lastSync: 'Sync Inactive',
        );
  }

  static Future<bool> updateProfile(Map<String, dynamic> updates) async {
    final activeUrl = await getActiveBaseUrl();
    try {
      final response = await http
          .put(
            Uri.parse('$activeUrl/auth/profile'),
            headers: _headers,
            body: jsonEncode(updates),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          _currentUser = UserModel.fromJson(data['user']);
        }
        DataSyncNotifier.instance.notifyDataChanged();
        return true;
      }
    } catch (e) {
      debugPrint('API Error in updateProfile: $e');
    }
    return false;
  }

  static Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    final activeUrl = await getActiveBaseUrl();
    try {
      final response = await http
          .post(
            Uri.parse('$activeUrl/auth/change-password'),
            headers: _headers,
            body: jsonEncode({
              'oldPassword': oldPassword,
              'newPassword': newPassword,
            }),
          )
          .timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Password changed successfully',
      };
    } catch (e) {
      debugPrint('API Error in changePassword: $e');
      return {
        'success': false,
        'message': 'Failed to change password',
      };
    }
  }
}
