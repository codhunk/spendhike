import 'package:flutter/material.dart';
import '../models/app_models.dart';

/// Central Local Storage Service handling in-memory local data operations.
class LocalStorageService {
  // ─── AUTH OPERATIONS ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      return {
        'success': true,
        'message': 'Login successful',
        'user': _localUser,
      };
    } catch (e) {
      debugPrint('Local Storage Error in login: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> signup(
      String name, String email, String mobile) async {
    try {
      _localUser['name'] = name;
      _localUser['email'] = email;
      _localUser['mobile'] = mobile;
      return {
        'success': true,
        'message': 'Account created successfully',
        'user': _localUser,
      };
    } catch (e) {
      debugPrint('Local Storage Error in signup: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    return {
      'success': true,
      'message': 'Password reset link sent to your email!',
    };
  }

  // ─── DASHBOARD OPERATIONS ─────────────────────────────────────────────────

  static Future<DashboardModel> getDashboard() async {
    return DashboardModel.fromJson(_localDashboardJson);
  }

  // ─── GROUPS OPERATIONS ────────────────────────────────────────────────────

  static Future<List<GroupModel>> getGroups({String searchQuery = ''}) async {
    var list = _localGroupsList;
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where((g) =>
              g.title.toLowerCase().contains(q) ||
              g.status.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  static Future<GroupModel> createGroup(String title) async {
    final newGroup = GroupModel(
      id: 'grp_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      transactionsCount: '0 Transactions this month',
      balance: '₹0.00',
      numericBalance: 0,
      status: 'Active',
      icon: 'group',
      isPrimary: false,
      members: [],
    );
    _localGroupsList.add(newGroup);
    return newGroup;
  }

  static Future<bool> updateGroupMembers(
      String groupId, List<MemberModel> members) async {
    final index = _localGroupsList.indexWhere((g) => g.id == groupId || g.title == groupId);
    if (index != -1) {
      final old = _localGroupsList[index];
      _localGroupsList[index] = GroupModel(
        id: old.id,
        title: old.title,
        transactionsCount: old.transactionsCount,
        balance: old.balance,
        numericBalance: old.numericBalance,
        status: old.status,
        icon: old.icon,
        isPrimary: old.isPrimary,
        members: members,
      );
      return true;
    }
    return false;
  }

  // ─── REPORTS OPERATIONS ───────────────────────────────────────────────────

  static Future<ReportModel> getReports() async {
    return ReportModel.fromJson(_localReportsJson);
  }

  // ─── TRANSACTIONS OPERATIONS ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> saveTransaction({
    required String amount,
    required String type,
    required String category,
    required String paymentMethod,
    required String notes,
    required List<String> attachments,
  }) async {
    final numAmt = double.tryParse(amount) ?? 0.0;
    final formattedAmt = numAmt >= 0 ? '+₹${numAmt.toStringAsFixed(2)}' : '-₹${numAmt.abs().toStringAsFixed(2)}';

    final newActivity = {
      'icon': 'payments',
      'title': notes.isNotEmpty ? notes : '$category Expense',
      'subtitle': '$category • Just now',
      'amount': formattedAmt,
      'statusLabel': 'Settled',
    };

    (_localDashboardJson['recentActivities'] as List).insert(0, newActivity);

    return {
      'success': true,
      'message': 'Transaction saved locally',
      'amount': formattedAmt,
    };
  }

  // ─── PROFILE OPERATIONS ───────────────────────────────────────────────────

  static Future<UserModel> getProfile() async {
    return UserModel.fromJson(_localUser);
  }

  static Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _localUser.addAll(updates);
    return true;
  }

  // ─── LOCAL STORAGE DATA ───────────────────────────────────────────────────

  static final Map<String, dynamic> _localUser = {
    'id': 'user_01',
    'name': 'Alexander Vance',
    'email': 'alex@company.com',
    'mobile': '+91 98765 43210',
    'company': 'Vance Financial Services Inc.',
    'gst': '27AAACV4123F1Z5',
    'address': '402 Financial Plaza, Mumbai',
    'plan': 'Pro Plan',
    'verified': true,
    'currency': 'INR (₹)',
    'language': 'English (IN)',
    'biometricEnabled': true,
    'pinEnabled': true,
    'darkMode': false,
    'lastSync': 'Local Data Active',
  };

  static final Map<String, dynamic> _localDashboardJson = {
    'totalBalance': '₹1,24,560.00',
    'income': '+₹12.4k',
    'debit': '-₹4.2k',
    'credit': '-₹2.8k',
    'weeklyTrend': '+8.4%',
    'pendingTasks': 12,
    'activeSites': [
      {'name': 'North Plaza', 'amount': '₹45,200', 'status': 'ON TRACK', 'progress': 0.65},
      {'name': 'West Bridge', 'amount': '₹12,800', 'status': 'OVER BUDGET', 'progress': 0.85},
      {'name': 'East Tower', 'amount': '₹8,500', 'status': 'STARTING', 'progress': 0.15},
    ],
    'recentActivities': [
      {'icon': 'payments', 'title': 'Project Advance', 'subtitle': 'Labour • Oct 24', 'amount': '+₹2,500', 'statusLabel': 'Settled'},
      {'icon': 'construction', 'title': 'Cement Supply', 'subtitle': 'Material • Oct 23', 'amount': '-₹1,250', 'statusLabel': 'Pending'},
      {'icon': 'diversity_3', 'title': 'Subcontractor Payout', 'subtitle': 'Labour • Oct 22', 'amount': '-₹800', 'statusLabel': 'Scheduled'},
    ],
  };

  static final List<GroupModel> _localGroupsList = [
    GroupModel(
      id: 'grp_1',
      title: 'Site A - Construction',
      transactionsCount: '42 Transactions this month',
      balance: '₹1,42,500.00',
      numericBalance: 142500,
      status: 'Active',
      icon: 'construction',
      isPrimary: true,
      members: [
        MemberModel(id: 'm1', name: 'Ravi Kumar', initials: 'RK', color: const Color(0xFF0453CD)),
        MemberModel(id: 'm2', name: 'Anjali Singh', initials: 'AS', color: const Color(0xFF10b981)),
        MemberModel(id: 'm3', name: 'Mohan Das', initials: 'MD', color: const Color(0xFFf59e0b)),
        MemberModel(id: 'm4', name: 'Priya Nair', initials: 'PN', color: const Color(0xFF8b5cf6)),
      ],
    ),
    GroupModel(
      id: 'grp_2',
      title: 'Client ABC',
      transactionsCount: '12 Transactions this month',
      balance: '₹8,240.50',
      numericBalance: 8240.50,
      status: 'Settled',
      icon: 'corporate_fare',
      isPrimary: false,
      members: [
        MemberModel(id: 'm5', name: 'Suresh Patel', initials: 'SP', color: const Color(0xFF0453CD)),
        MemberModel(id: 'm6', name: 'Meena Joshi', initials: 'MJ', color: const Color(0xFFef4444)),
        MemberModel(id: 'm7', name: 'Vikram Rao', initials: 'VR', color: const Color(0xFF10b981)),
      ],
    ),
    GroupModel(
      id: 'grp_3',
      title: 'Office Expenses',
      transactionsCount: '89 Transactions this month',
      balance: '-₹1,250.00',
      numericBalance: -1250.00,
      status: 'Over Budget',
      icon: 'receipt_long',
      isPrimary: false,
      members: [
        MemberModel(id: 'm8', name: 'Arun Mehta', initials: 'AM', color: const Color(0xFF0453CD)),
        MemberModel(id: 'm9', name: 'Deepa Verma', initials: 'DV', color: const Color(0xFFf59e0b)),
        MemberModel(id: 'm10', name: 'Kiran Shah', initials: 'KS', color: const Color(0xFF10b981)),
        MemberModel(id: 'm11', name: 'Neha Gupta', initials: 'NG', color: const Color(0xFFef4444)),
      ],
    ),
    GroupModel(
      id: 'grp_4',
      title: 'Vendor Ledger',
      transactionsCount: '15 Transactions this month',
      balance: '₹32,000.00',
      numericBalance: 32000,
      status: 'Pending Approval',
      icon: 'payments',
      isPrimary: false,
      members: [
        MemberModel(id: 'm12', name: 'Ramesh Iyer', initials: 'RI', color: const Color(0xFF0453CD)),
        MemberModel(id: 'm13', name: 'Sunita Tiwari', initials: 'ST', color: const Color(0xFF8b5cf6)),
        MemberModel(id: 'm14', name: 'Harish Doshi', initials: 'HD', color: const Color(0xFF10b981)),
      ],
    ),
  ];

  static final Map<String, dynamic> _localReportsJson = {
    'totalIncome': '₹1,42,500.00',
    'totalExpenses': '₹89,420.50',
    'incomeTrend': '+12.5% from last month',
    'expenseTrend': '-4.2% from last month',
    'categories': [
      {'label': 'Labour', 'amount': 40239, 'color': 0xFF0453CD},
      {'label': 'Material', 'amount': 22355, 'color': 0xFF4C8EF7},
      {'label': 'Fuel', 'amount': 26826, 'color': 0xFFADC6FF},
    ],
    'transactionBreakdown': [
      {'category': 'Labour Costs', 'icon': 'engineering', 'current': '₹40,239.00', 'previous': '₹38,100.00', 'variance': '+5.6%'},
      {'category': 'Raw Materials', 'icon': 'inventory_2', 'current': '₹22,355.20', 'previous': '₹24,500.00', 'variance': '-8.7%'},
      {'category': 'Fuel & Logistics', 'icon': 'local_gas_station', 'current': '₹26,826.30', 'previous': '₹25,200.00', 'variance': '+6.4%'},
    ],
    'forecast': {
      'title': 'Automated Forecasts',
      'description': 'Based on current trends, your projected income for Q4 is expected to rise by 15.2% due to operational efficiency.'
    }
  };
}
