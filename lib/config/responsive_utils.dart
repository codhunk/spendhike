import 'package:flutter/material.dart';

/// Screen break points and helper utilities for mobile and tablet screens.
class ResponsiveUtils {
  /// Screen size categories
  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  static bool isStandardMobile(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 360 && w < 600;
  }

  static bool isTabletOrWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  /// Adaptive horizontal padding based on screen width
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 12.0;
    if (width < 600) return 16.0;
    return 24.0;
  }

  /// Adaptive grid column count
  static int getGridColumnCount(BuildContext context, {int minWidthPerColumn = 160}) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 1;
    if (width < 700) return 2;
    return (width / minWidthPerColumn).floor().clamp(2, 4);
  }

  /// Adaptive font size multiplier
  static double getFontScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 340) return 0.88;
    if (width < 380) return 0.95;
    return 1.0;
  }

  /// Filter types enum / constants
  static const String filterAll = 'all';
  static const String filterReceived = 'received';
  static const String filterSpent = 'spent';

  /// Helper to test if a transaction matches the active filter
  static bool matchesFilter({
    required String filter,
    required String amountText,
    String? type, // 'INCOME', 'EXPENSE', 'CREDIT', 'DEBIT', etc.
  }) {
    if (filter == filterAll) return true;

    final isIncome = amountText.trim().startsWith('+') ||
        (type != null && (type.toUpperCase() == 'INCOME' || type.toUpperCase() == 'CREDIT'));

    final isExpense = amountText.trim().startsWith('-') ||
        (type != null && (type.toUpperCase() == 'EXPENSE' || type.toUpperCase() == 'DEBIT'));

    if (filter == filterReceived) {
      return isIncome || (!isExpense && !amountText.trim().startsWith('-'));
    }

    if (filter == filterSpent) {
      return isExpense || (!isIncome && amountText.trim().startsWith('-'));
    }

    return true;
  }
}
