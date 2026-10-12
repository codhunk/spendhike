import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/responsive_utils.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';
import '../../services/app_settings.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/theme_switcher.dart';
import '../transaction/new_transaction_screen.dart';
import '../../services/data_sync_notifier.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupName;
  final String balance;

  const GroupDetailScreen({
    super.key,
    required this.groupName,
    required this.balance,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late Future<Map<String, dynamic>> _dataFuture;
  String _activeFilter = 'All';

  String _tr(String text) => AppSettings.instance.tr(text);

  @override
  void initState() {
    super.initState();
    DataSyncNotifier.instance.addListener(_refreshData);
    _refreshData();
  }

  @override
  void dispose() {
    DataSyncNotifier.instance.removeListener(_refreshData);
    super.dispose();
  }

  void _refreshData() {
    if (mounted) {
      setState(() {
        _dataFuture = _fetchGroupDetailData();
      });
    }
  }

  Future<Map<String, dynamic>> _fetchGroupDetailData() async {
    final groups = await ApiService.getGroups();
    GroupModel? matchedGroup;
    for (final g in groups) {
      if (g.title.toLowerCase().trim() == widget.groupName.toLowerCase().trim()) {
        matchedGroup = g;
        break;
      }
    }

    final targetGroupId = matchedGroup?.id ?? '';
    final transactions = await ApiService.getTransactionsList(
      projectId: targetGroupId.isNotEmpty ? targetGroupId : null,
    );

    return {
      'group': matchedGroup,
      'transactions': transactions,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(context),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colors.primary),
            );
          }

          final group = snapshot.data?['group'] as GroupModel?;
          final rawTransactions = (snapshot.data?['transactions'] as List?) ?? [];

          // Filter transactions matching Received/Spent filter
          final filterKey = _activeFilter == 'Received'
              ? ResponsiveUtils.filterReceived
              : (_activeFilter == 'Spent'
                  ? ResponsiveUtils.filterSpent
                  : ResponsiveUtils.filterAll);

          final transactions = rawTransactions.where((t) {
            final amt = (t['amount'] ?? '').toString();
            final type = (t['type'] ?? '').toString();
            return ResponsiveUtils.matchesFilter(
              filter: filterKey,
              amountText: amt,
              type: type,
            );
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBalanceSummary(context, group, transactions.length),
                    const SizedBox(height: 16),
                    _buildFilterBar(),
                    const SizedBox(height: 16),
                    _buildTransactionHistory(transactions),
                  ],
                ),
              ),
            ),
          );
        },
      ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewTransactionScreen()),
            );
            _refreshData();
          },
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add, size: 32),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colors = AppTheme.of(context);
    final initials = widget.groupName.isNotEmpty ? widget.groupName.substring(0, 1).toUpperCase() : 'G';

    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? colors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.groupName,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
      ),
      actions: [
        const ThemeSwitcherButton(),
        const LanguageSwitcherButton(),
        IconButton(
          icon: Icon(Icons.refresh, color: colors.textPrimary),
          onPressed: _refreshData,
        ),
        Container(
          margin: const EdgeInsets.only(right: 16, left: 8),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: colors.border, height: 1.0),
      ),
    );
  }

  Widget _buildBalanceSummary(BuildContext context, GroupModel? group, int totalTxCount) {
    final colors = AppTheme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 768;
    final balanceText = group?.balance ?? '₹0.00';

    return Flex(
      direction: isDesktop ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: isDesktop ? 2 : 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.isDark ? colors.surface : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.isDark ? colors.border : const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr('REMAINING BALANCE'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.isDark ? colors.textMuted : const Color(0xFF94A3B8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      balanceText,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: colors.isDark ? colors.primary : Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet,
                        color: colors.isDark ? colors.textMuted : const Color(0xFF94A3B8),
                        size: 16),
                    const SizedBox(width: 8),
                    Text(
                      group != null ? '${_tr('Status')}: ${_tr(group.status)}' : _tr('Real-time Live Sync'),
                      style: TextStyle(
                          fontSize: 14,
                          color: colors.isDark ? colors.textMuted : const Color(0xFFCBD5E1)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: isDesktop ? 16 : 0, height: isDesktop ? 0 : 16),
        Expanded(
          flex: isDesktop ? 1 : 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_tr('PROJECT LEDGER'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  widget.groupName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Divider(height: 24, color: colors.border),
                Text(_tr('TOTAL TRANSACTIONS'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  '$totalTxCount',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All'),
            const SizedBox(width: 8),
            _buildFilterChip('Received'),
            const SizedBox(width: 8),
            _buildFilterChip('Spent'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final colors = AppTheme.of(context);
    final isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colors.primary : colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(24),
          border: isActive ? null : Border.all(color: colors.border),
        ),
        child: Text(
          _tr(label),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionHistory(List<dynamic> transactions) {
    final colors = AppTheme.of(context);
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 48, color: colors.textMuted),
              const SizedBox(height: 12),
              Text(
                _tr('No transactions found for this filter.'),
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tr('Transaction History (Tap to Edit)'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: List.generate(transactions.length, (index) {
              final item = transactions[index];
              return Column(
                children: [
                  _buildDynamicTransactionItem(item),
                  if (index < transactions.length - 1) Divider(height: 1, color: colors.border),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicTransactionItem(Map<String, dynamic> item) {
    final colors = AppTheme.of(context);
    final title = item['description'] ?? item['category'] ?? 'Transaction';
    final category = item['category'] ?? 'OTHER';
    final type = (item['type'] ?? '').toString().toUpperCase();
    final isReceived = type == 'RECEIVED';
    final amountVal = (item['amount'] is num) ? (item['amount'] as num).toDouble() : 0.0;

    final amountStr = isReceived ? '+ ₹${amountVal.toStringAsFixed(2)}' : '- ₹${amountVal.toStringAsFixed(2)}';
    final amountColor = isReceived ? colors.success : colors.error;
    final iconBg = isReceived ? colors.success.withValues(alpha: 0.12) : colors.error.withValues(alpha: 0.12);
    final iconColor = isReceived ? colors.success : colors.error;
    final iconData = isReceived ? Icons.download : Icons.outbound;

    final dateStr = item['createdAt'] != null
        ? DateTime.tryParse(item['createdAt'].toString())?.toLocal().toString().split('.')[0] ?? ''
        : '';

    return InkWell(
      onTap: () => _showEditTransactionSheet(item),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(iconData, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toString(),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        category.toString(),
                        style: TextStyle(fontSize: 13, color: colors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.edit, size: 14, color: colors.primary),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountStr,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: amountColor),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTransactionSheet(Map<String, dynamic> item) {
    final colors = AppTheme.of(context);
    final txId = item['_id'] ?? item['id'] ?? '';
    final currentAmount = (item['amount'] != null) ? item['amount'].toString() : '';
    final currentType = (item['type'] ?? '').toString().toUpperCase() == 'RECEIVED' ? 'Received' : 'Spent';
    final currentCategory = item['category'] ?? 'Labour';
    final currentMethod = item['paymentMethod'] ?? 'Cash';
    final currentNotes = item['description'] ?? '';

    final amountCtrl = TextEditingController(text: currentAmount);
    final notesCtrl = TextEditingController(text: currentNotes);
    String selectedType = currentType;
    String selectedCategory = currentCategory;
    String selectedMethod = currentMethod;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _tr('Edit Transaction (Author)'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Transaction Type Toggle
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text(_tr('Received'))),
                      selected: selectedType == 'Received',
                      selectedColor: colors.success.withValues(alpha: 0.15),
                      onSelected: (val) {
                        if (val) setModalState(() => selectedType = 'Received');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text(_tr('Spent'))),
                      selected: selectedType == 'Spent',
                      selectedColor: colors.error.withValues(alpha: 0.15),
                      onSelected: (val) {
                        if (val) setModalState(() => selectedType = 'Spent');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Amount Input
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: _tr('Amount (₹)'),
                  labelStyle: TextStyle(color: colors.textSecondary),
                  prefixIcon: Icon(Icons.currency_rupee, color: colors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 12),

              // Category Dropdown
              DropdownButtonFormField<String>(
                dropdownColor: colors.surface,
                style: TextStyle(color: colors.textPrimary),
                value: ['Labour', 'Material', 'Fuel', 'Equipment', 'Other'].contains(selectedCategory)
                    ? selectedCategory
                    : 'Labour',
                decoration: InputDecoration(
                  labelText: _tr('Category'),
                  labelStyle: TextStyle(color: colors.textSecondary),
                  prefixIcon: Icon(Icons.category, color: colors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.primary, width: 2)),
                ),
                items: ['Labour', 'Material', 'Fuel', 'Equipment', 'Other']
                    .map((c) => DropdownMenuItem(value: c, child: Text(_tr(c), style: TextStyle(color: colors.textPrimary))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedCategory = val);
                },
              ),
              const SizedBox(height: 12),

              // Payment Method
              DropdownButtonFormField<String>(
                dropdownColor: colors.surface,
                style: TextStyle(color: colors.textPrimary),
                value: ['Cash', 'UPI', 'Bank Transfer', 'Cheque'].contains(selectedMethod)
                    ? selectedMethod
                    : 'Cash',
                decoration: InputDecoration(
                  labelText: _tr('Payment Method'),
                  labelStyle: TextStyle(color: colors.textSecondary),
                  prefixIcon: Icon(Icons.payments, color: colors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.primary, width: 2)),
                ),
                items: ['Cash', 'UPI', 'Bank Transfer', 'Cheque']
                    .map((m) => DropdownMenuItem(value: m, child: Text(_tr(m), style: TextStyle(color: colors.textPrimary))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedMethod = val);
                },
              ),
              const SizedBox(height: 12),

              // Notes Input
              TextField(
                controller: notesCtrl,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: _tr('Notes / Description'),
                  labelStyle: TextStyle(color: colors.textSecondary),
                  prefixIcon: Icon(Icons.notes, color: colors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (amountCtrl.text.trim().isEmpty) return;
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    final res = await ApiService.updateTransaction(
                      transactionId: txId,
                      type: selectedType,
                      category: selectedCategory,
                      amount: amountCtrl.text.trim(),
                      paymentMethod: selectedMethod,
                      notes: notesCtrl.text.trim(),
                    );

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(_tr(res['message'] ?? 'Transaction updated')),
                        backgroundColor: res['success'] == true ? colors.success : colors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    _refreshData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_tr('Save Changes'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
