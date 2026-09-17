import 'package:flutter/material.dart';
import '../../config/responsive_utils.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: _buildAppBar(context),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0453CD)),
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
        backgroundColor: const Color(0xFF041627),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final initials = widget.groupName.isNotEmpty ? widget.groupName.substring(0, 1).toUpperCase() : 'G';

    return AppBar(
      backgroundColor: const Color(0xFFF8F9FF),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF041627)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.groupName,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF041627),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF041627)),
          onPressed: _refreshData,
        ),
        Container(
          margin: const EdgeInsets.only(right: 16, left: 8),
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFD2E4FB),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(color: Color(0xFF041627), fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: const Color(0xFFC4C6CD), height: 1.0),
      ),
    );
  }

  Widget _buildBalanceSummary(BuildContext context, GroupModel? group, int totalTxCount) {
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
              color: const Color(0xFF1A2B3C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF74777D)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REMAINING BALANCE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8192A7),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      balanceText,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Color(0xFFB7C8DE), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      group != null ? 'Status: ${group.status}' : 'Real-time Live Sync',
                      style: const TextStyle(fontSize: 14, color: Color(0xFFB7C8DE)),
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
              color: const Color(0xFFD3E4FE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC4C6CD)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PROJECT LEDGER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF44474C))),
                const SizedBox(height: 4),
                Text(
                  widget.groupName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF041627)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Divider(height: 24, color: Color(0xFFC4C6CD)),
                const Text('TOTAL TRANSACTIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF44474C))),
                const SizedBox(height: 4),
                Text(
                  '$totalTxCount',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF041627)),
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
          color: isActive ? const Color(0xFF041627) : const Color(0xFFEFF4FF),
          borderRadius: BorderRadius.circular(24),
          border: isActive ? null : Border.all(color: const Color(0xFFC4C6CD)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF44474C),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionHistory(List<dynamic> transactions) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC4C6CD)),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFF94A3B8)),
              SizedBox(height: 12),
              Text(
                'No transactions found for this filter.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction History (Tap to Edit)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30)),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC4C6CD)),
          ),
          child: Column(
            children: List.generate(transactions.length, (index) {
              final item = transactions[index];
              return Column(
                children: [
                  _buildDynamicTransactionItem(item),
                  if (index < transactions.length - 1) const Divider(height: 1, color: Color(0xFFE2E8F0)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicTransactionItem(Map<String, dynamic> item) {
    final title = item['description'] ?? item['category'] ?? 'Transaction';
    final category = item['category'] ?? 'OTHER';
    final type = (item['type'] ?? '').toString().toUpperCase();
    final isReceived = type == 'RECEIVED';
    final amountVal = (item['amount'] is num) ? (item['amount'] as num).toDouble() : 0.0;

    final amountStr = isReceived ? '+ ₹${amountVal.toStringAsFixed(2)}' : '- ₹${amountVal.toStringAsFixed(2)}';
    final amountColor = isReceived ? const Color(0xFF0453CD) : const Color(0xFFBA1A1A);
    final iconBg = isReceived ? const Color(0xFFDCE9FF) : const Color(0xFFFFDAD6);
    final iconColor = isReceived ? const Color(0xFF0453CD) : const Color(0xFFBA1A1A);
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0B1C30)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        category.toString(),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF44474C)),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.edit, size: 14, color: Color(0xFF0453CD)),
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
                  style: const TextStyle(fontSize: 12, color: Color(0xFF74777D)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTransactionSheet(Map<String, dynamic> item) {
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
                  const Text(
                    'Edit Transaction (Author)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF041627)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
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
                      label: const Center(child: Text('Received')),
                      selected: selectedType == 'Received',
                      selectedColor: const Color(0xFFDCE9FF),
                      onSelected: (val) {
                        if (val) setModalState(() => selectedType = 'Received');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Spent')),
                      selected: selectedType == 'Spent',
                      selectedColor: const Color(0xFFFFDAD6),
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
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF0453CD)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: ['Labour', 'Material', 'Fuel', 'Equipment', 'Other'].contains(selectedCategory)
                    ? selectedCategory
                    : 'Labour',
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category, color: Color(0xFF0453CD)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: ['Labour', 'Material', 'Fuel', 'Equipment', 'Other']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedCategory = val);
                },
              ),
              const SizedBox(height: 12),

              // Payment Method
              DropdownButtonFormField<String>(
                value: ['Cash', 'UPI', 'Bank Transfer', 'Cheque'].contains(selectedMethod)
                    ? selectedMethod
                    : 'Cash',
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: const Icon(Icons.payments, color: Color(0xFF0453CD)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: ['Cash', 'UPI', 'Bank Transfer', 'Cheque']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedMethod = val);
                },
              ),
              const SizedBox(height: 12),

              // Notes Input
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Notes / Description',
                  prefixIcon: const Icon(Icons.notes, color: Color(0xFF0453CD)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                        content: Text(res['message'] ?? 'Transaction updated'),
                        backgroundColor: res['success'] == true ? const Color(0xFF10b981) : const Color(0xFFBA1A1A),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    _refreshData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0453CD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
