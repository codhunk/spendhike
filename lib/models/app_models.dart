import 'package:flutter/material.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String company;
  final String gst;
  final String address;
  final String avatarUrl;
  final String plan;
  final bool verified;
  final String currency;
  final String language;
  final bool biometricEnabled;
  final bool pinEnabled;
  final bool darkMode;
  final String lastSync;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.company,
    required this.gst,
    required this.address,
    this.avatarUrl = '',
    required this.plan,
    required this.verified,
    required this.currency,
    required this.language,
    required this.biometricEnabled,
    required this.pinEnabled,
    required this.darkMode,
    required this.lastSync,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      company: json['company'] ?? '',
      gst: json['gst'] ?? '',
      address: json['address'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      plan: json['plan'] ?? 'Pro Plan',
      verified: json['verified'] ?? true,
      currency: json['currency'] ?? 'INR (₹)',
      language: json['language'] ?? 'English (IN)',
      biometricEnabled: json['biometricEnabled'] ?? true,
      pinEnabled: json['pinEnabled'] ?? true,
      darkMode: json['darkMode'] ?? false,
      lastSync: json['lastSync'] ?? 'Live Server Connected',
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? mobile,
    String? company,
    String? gst,
    String? address,
    String? avatarUrl,
    String? plan,
    bool? verified,
    String? currency,
    String? language,
    bool? biometricEnabled,
    bool? pinEnabled,
    bool? darkMode,
    String? lastSync,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      company: company ?? this.company,
      gst: gst ?? this.gst,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      plan: plan ?? this.plan,
      verified: verified ?? this.verified,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      darkMode: darkMode ?? this.darkMode,
      lastSync: lastSync ?? this.lastSync,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'mobile': mobile,
        'company': company,
        'gst': gst,
        'address': address,
        'avatarUrl': avatarUrl,
        'plan': plan,
        'verified': verified,
        'currency': currency,
        'language': language,
        'biometricEnabled': biometricEnabled,
        'pinEnabled': pinEnabled,
        'darkMode': darkMode,
        'lastSync': lastSync,
      };
}

class MemberModel {
  final String id;
  final String name;
  final String initials;
  final Color color;

  MemberModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.color,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> userObj = {};
    if (json['userId'] != null && json['userId'] is Map) {
      userObj = Map<String, dynamic>.from(json['userId']);
    } else {
      userObj = json;
    }

    final name = userObj['name'] ?? json['name'] ?? 'Member';
    final id = userObj['_id'] ?? userObj['id'] ?? json['id'] ?? '';

    String initials = 'MB';
    if (name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }

    Color parsedColor = const Color(0xFF0453CD);
    if (json['color'] != null && json['color'] is String) {
      final hexString = (json['color'] as String).replaceAll('#', '');
      parsedColor = Color(int.parse('FF$hexString', radix: 16));
    }

    return MemberModel(
      id: id,
      name: name,
      initials: initials,
      color: parsedColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initials': initials,
      };
}

class GroupModel {
  final String id;
  final String title;
  final String transactionsCount;
  final String balance;
  final double numericBalance;
  final String status;
  final String icon;
  final bool isPrimary;
  final List<MemberModel> members;

  GroupModel({
    required this.id,
    required this.title,
    required this.transactionsCount,
    required this.balance,
    required this.numericBalance,
    required this.status,
    required this.icon,
    required this.isPrimary,
    required this.members,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    var rawMembers = json['members'] as List? ?? [];
    List<MemberModel> memberList =
        rawMembers.map((m) => MemberModel.fromJson(Map<String, dynamic>.from(m))).toList();

    final title = json['name'] ?? json['title'] ?? '';
    final id = json['_id'] ?? json['id'] ?? '';

    double numBal = 0.0;
    if (json['totalBalance'] != null) {
      numBal = (json['totalBalance'] as num).toDouble();
    } else if (json['numericBalance'] != null) {
      numBal = (json['numericBalance'] as num).toDouble();
    }
    final formattedBalance = numBal >= 0
        ? '₹${numBal.toStringAsFixed(2)}'
        : '-₹${numBal.abs().toStringAsFixed(2)}';

    return GroupModel(
      id: id,
      title: title,
      transactionsCount: json['transactionsCount'] ?? 'Active Ledger',
      balance: json['balance']?.toString() ?? formattedBalance,
      numericBalance: numBal,
      status: json['status'] ?? 'Active',
      icon: json['icon'] ?? 'construction',
      isPrimary: json['isPrimary'] ?? false,
      members: memberList,
    );
  }
}

class DashboardModel {
  final String totalBalance;
  final String income;
  final String debit;
  final String credit;
  final String weeklyTrend;
  final int pendingTasks;
  final List<Map<String, dynamic>> activeSites;
  final List<Map<String, dynamic>> recentActivities;

  DashboardModel({
    required this.totalBalance,
    required this.income,
    required this.debit,
    required this.credit,
    required this.weeklyTrend,
    required this.pendingTasks,
    required this.activeSites,
    required this.recentActivities,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      totalBalance: json['totalBalance'] ?? '₹0.00',
      income: formatCompactCurrency(json['income'], prefix: '+'),
      debit: formatCompactCurrency(json['debit'], prefix: '-'),
      credit: formatCompactCurrency(json['credit'], prefix: '-'),
      weeklyTrend: json['weeklyTrend'] ?? '+0.0%',
      pendingTasks: json['pendingTasks'] ?? (json['activeGroupsCount'] ?? 0),
      activeSites: List<Map<String, dynamic>>.from(json['activeSites'] ?? []),
      recentActivities: List<Map<String, dynamic>>.from(json['recentActivities'] ?? []),
    );
  }
}

class ReportModel {
  final String totalIncome;
  final String totalExpenses;
  final String incomeTrend;
  final String expenseTrend;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> transactionBreakdown;
  final Map<String, dynamic> forecast;

  ReportModel({
    required this.totalIncome,
    required this.totalExpenses,
    required this.incomeTrend,
    required this.expenseTrend,
    required this.categories,
    required this.transactionBreakdown,
    required this.forecast,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      totalIncome: formatCompactCurrency(json['totalIncome']),
      totalExpenses: formatCompactCurrency(json['totalExpenses']),
      incomeTrend: json['incomeTrend'] ?? '+0.0% from last month',
      expenseTrend: json['expenseTrend'] ?? '-0.0% from last month',
      categories: List<Map<String, dynamic>>.from(json['categories'] ?? []),
      transactionBreakdown: List<Map<String, dynamic>>.from(json['transactionBreakdown'] ?? []),
      forecast: Map<String, dynamic>.from(json['forecast'] ?? {}),
    );
  }
}

class InvitationModel {
  final String id;
  final String groupId;
  final String groupName;
  final String description;
  final String invitedBy;
  final String role;
  final String invitationCode;
  final String status;
  final String shareMessage;

  InvitationModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.description,
    required this.invitedBy,
    required this.role,
    required this.invitationCode,
    required this.status,
    required this.shareMessage,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id'] ?? json['_id'] ?? '',
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? 'Project Group',
      description: json['description'] ?? '',
      invitedBy: json['invitedBy'] ?? 'SpendHike User',
      role: json['role'] ?? 'Editor',
      invitationCode: json['invitationCode'] ?? '',
      status: json['status'] ?? 'PENDING',
      shareMessage: json['shareMessage'] ?? '',
    );
  }
}

String formatCompactCurrency(dynamic amountVal, {String prefix = ''}) {
  if (amountVal == null) return '${prefix}₹0.00K';

  double valNum = 0.0;
  if (amountVal is double) {
    valNum = amountVal;
  } else if (amountVal is int) {
    valNum = amountVal.toDouble();
  } else if (amountVal != null) {
    final str = amountVal.toString().trim();
    if (str.isEmpty) return '${prefix}₹0.00K';

    // If the string is already formatted with a compact suffix (K, M, B, T), preserve it!
    if (RegExp(r'[KMBT]$').hasMatch(str)) {
      if (prefix.isNotEmpty && !str.startsWith('+') && !str.startsWith('-')) {
        return '$prefix$str';
      }
      return str;
    }

    final cleaned = str.replaceAll(RegExp(r'[^0-9.]'), '');
    valNum = double.tryParse(cleaned) ?? 0.0;
    if (str.startsWith('-')) valNum = -valNum;
  }

  final abs = valNum.abs();
  final sign = valNum < 0 ? '-' : prefix;
  String formatted = '';

  if (abs >= 1e12) {
    formatted = '${(abs / 1e12).toStringAsFixed(2)}T';
  } else if (abs >= 1e9) {
    formatted = '${(abs / 1e9).toStringAsFixed(2)}B';
  } else if (abs >= 1e6) {
    formatted = '${(abs / 1e6).toStringAsFixed(2)}M';
  } else {
    // ALWAYS retain K suffix with 2 decimal places!
    formatted = '${(abs / 1e3).toStringAsFixed(2)}K';
  }

  return '$sign₹$formatted';
}
