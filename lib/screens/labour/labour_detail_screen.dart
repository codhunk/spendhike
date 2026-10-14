import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/data_sync_notifier.dart';
import '../../services/app_settings.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/theme_switcher.dart';

class LabourDetailScreen extends StatefulWidget {
  final String labourId;
  const LabourDetailScreen({super.key, required this.labourId});

  @override
  State<LabourDetailScreen> createState() => _LabourDetailScreenState();
}

class _LabourDetailScreenState extends State<LabourDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _labourData;
  Map<String, dynamic>? _summary;
  List<dynamic> _ledger = [];
  List<dynamic> _attendance = [];
  List<dynamic> _payments = [];

  String _tr(String key) => AppSettings.instance.tr(key);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    DataSyncNotifier.instance.addListener(_loadData);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final ledgerData = await ApiService.getLabourLedger(widget.labourId);
    final attData = await ApiService.getAttendance(labourId: widget.labourId);
    final pmtData = await ApiService.getLabourPayments(widget.labourId);

    if (mounted) {
      setState(() {
        if (ledgerData != null) {
          _labourData = ledgerData['labour'];
          _summary = ledgerData['summary'];
          _ledger = ledgerData['ledger'] ?? [];
        }
        _attendance = attData;
        _payments = pmtData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        if (_isLoading) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(title: Text(_tr('Labour Details'), style: TextStyle(color: colors.textPrimary))),
            body: Center(child: CircularProgressIndicator(color: colors.primary)),
          );
        }

        if (_labourData == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(title: Text(_tr('Labour Details'), style: TextStyle(color: colors.textPrimary))),
            body: Center(child: Text(_tr('Labour not found'), style: TextStyle(color: colors.textSecondary))),
          );
        }

        final name = _labourData!['name'] ?? 'Unknown';
        final labourType = _labourData!['labourType'] ?? 'Helper';
        final mobile = _labourData!['mobileNumber'] ?? 'N/A';
        final dihadiRate = _labourData!['dihadiRate'] ?? 0;
        final customId = _labourData!['labourId'] ?? '';
        final siteName = (_labourData!['siteId'] is Map) ? _labourData!['siteId']['name'] : 'Assigned Site';
        final isCarigar = labourType == 'Carigar';

        final totalDihadi = _summary?['totalDihadi'] ?? 0;
        final totalEarned = _summary?['totalEarned'] ?? 0;
        final totalPaid = _summary?['totalPaid'] ?? 0;
        final totalAdvance = _summary?['totalAdvance'] ?? 0;
        final totalDeduction = _summary?['totalDeduction'] ?? 0;
        final outstanding = _summary?['outstanding'] ?? 0;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? colors.surface,
            title: Text(name, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.textPrimary)),
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: colors.textPrimary),
                tooltip: _tr('Admin Actions'),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showEditLabourModal();
                  } else if (val == 'reset_password') {
                    _showResetPasswordModal();
                  } else if (val == 'toggle_status') {
                    _toggleLabourStatus();
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: colors.primary),
                        const SizedBox(width: 8),
                        Text(_tr('Edit Details')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'reset_password',
                    child: Row(
                      children: [
                        const Icon(Icons.lock_reset, size: 18, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(_tr('Reset Password')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        Icon(
                          (_labourData?['status'] ?? 'Active') == 'Active'
                              ? Icons.block
                              : Icons.check_circle_outline,
                          size: 18,
                          color: (_labourData?['status'] ?? 'Active') == 'Active'
                              ? Colors.red
                              : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (_labourData?['status'] ?? 'Active') == 'Active'
                              ? _tr('Deactivate Account')
                              : _tr('Activate Account'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const ThemeSwitcherButton(),
              const LanguageSwitcherButton(),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: colors.primary,
              indicatorColor: colors.primary,
              unselectedLabelColor: colors.textSecondary,
              tabs: [
                Tab(text: _tr('Overview')),
                Tab(text: _tr('Ledger')),
                Tab(text: _tr('Attendance')),
                Tab(text: _tr('Payments')),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // 1. Overview Tab
              _buildOverviewTab(
                name: name,
                labourType: labourType,
                mobile: mobile,
                dihadiRate: dihadiRate,
                customId: customId,
                siteName: siteName,
                isCarigar: isCarigar,
                totalDihadi: totalDihadi,
                totalEarned: totalEarned,
                totalPaid: totalPaid,
                totalAdvance: totalAdvance,
                totalDeduction: totalDeduction,
                outstanding: outstanding,
              ),

              // 2. Ledger Tab
              _buildLedgerTab(),

              // 3. Attendance Tab
              _buildAttendanceTab(),

              // 4. Payments Tab
              _buildPaymentsTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab({
    required String name,
    required String labourType,
    required String mobile,
    required num dihadiRate,
    required String customId,
    required String siteName,
    required bool isCarigar,
    required num totalDihadi,
    required num totalEarned,
    required num totalPaid,
    required num totalAdvance,
    required num totalDeduction,
    required num outstanding,
  }) {
    final colors = AppTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isCarigar ? const Color(0xFF0453CD).withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1),
                    child: Icon(
                      isCarigar ? Icons.engineering : Icons.handyman,
                      color: isCarigar ? const Color(0xFF0453CD) : const Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCarigar ? const Color(0xFF0453CD).withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _tr(labourType),
                                style: TextStyle(
                                  color: isCarigar ? const Color(0xFF0453CD) : const Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('ID: $customId • ${_tr('Site/Project')}: $siteName', style: TextStyle(color: colors.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis),
                        Text('${_tr('Mobile Number')}: $mobile • ${_tr('Rate')}: ₹$dihadiRate / ${_tr('Dihadi')}', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Financial Summary Cards - Responsive
          Text(_tr('Financial Summary'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossCount = width > 600 ? 3 : 2;
              final ratio = width > 600 ? 2.5 : (width < 380 ? 1.4 : 1.6);

              return GridView.count(
                crossAxisCount: crossCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: ratio,
                children: [
                  _buildSummaryTile(_tr('Total Dihadi'), '$totalDihadi ${_tr('Dihadi')}', Icons.calendar_today, Colors.blue),
                  _buildSummaryTile(_tr('Total Earned'), '₹$totalEarned', Icons.monetization_on, Colors.indigo),
                  _buildSummaryTile(_tr('Total Paid'), '₹$totalPaid', Icons.check_circle, Colors.green),
                  _buildSummaryTile(_tr('Total Advance'), '₹$totalAdvance', Icons.payment, Colors.orange),
                  _buildSummaryTile(_tr('Total Deduction'), '₹$totalDeduction', Icons.remove_circle_outline, Colors.purple),
                  _buildSummaryTile(_tr('Outstanding Balance'), '₹$outstanding', Icons.account_balance_wallet, outstanding > 0 ? Colors.red : Colors.green),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String title, String value, IconData icon, Color color) {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 9, color: colors.textMuted), overflow: TextOverflow.ellipsis, maxLines: 1),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Ledger Table ─────────────────────────────────────────────────────────────
  Widget _buildLedgerTab() {
    final colors = AppTheme.of(context);
    if (_ledger.isEmpty) {
      return Center(child: Text(_tr('No ledger entries yet.')));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(colors.isDark ? colors.surfaceSubtle : const Color(0xFF041627)),
          headingTextStyle: TextStyle(color: colors.isDark ? colors.textPrimary : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          columns: [
            DataColumn(label: Text(_tr('Date'))),
            DataColumn(label: Text(_tr('Description'))),
            DataColumn(label: Text(_tr('Dihadi'))),
            DataColumn(label: Text(_tr('Rate'))),
            DataColumn(label: Text(_tr('Earned'))),
            DataColumn(label: Text(_tr('Payment'))),
            DataColumn(label: Text(_tr('Advance'))),
            DataColumn(label: Text(_tr('Deduction'))),
            DataColumn(label: Text(_tr('Adjustment'))),
            DataColumn(label: Text(_tr('Balance'))),
          ],
          rows: _ledger.map((row) {
            final dateStr = (row['date'] ?? '').toString().split('T').first;
            final desc = row['description'] ?? '';
            final dihadi = row['dihadi'] != null ? row['dihadi'].toString() : '-';
            final rate = row['rate'] != null ? '₹${row['rate']}' : '-';
            final earned = row['earnedAmount'] > 0 ? '₹${row['earnedAmount']}' : '-';
            final pmt = row['payment'] > 0 ? '₹${row['payment']}' : '-';
            final adv = row['advance'] > 0 ? '₹${row['advance']}' : '-';
            final ded = row['deduction'] > 0 ? '₹${row['deduction']}' : '-';
            final adj = row['adjustment'] != 0 ? '₹${row['adjustment']}' : '-';
            final bal = '₹${row['balance'] ?? 0}';

            return DataRow(cells: [
              DataCell(Text(dateStr, style: TextStyle(fontSize: 12, color: colors.textPrimary))),
              DataCell(Text(desc, style: TextStyle(fontSize: 12, color: colors.textPrimary))),
              DataCell(Text(dihadi, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary))),
              DataCell(Text(rate, style: TextStyle(fontSize: 12, color: colors.textPrimary))),
              DataCell(Text(earned, style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.w600))),
              DataCell(Text(pmt, style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600))),
              DataCell(Text(adv, style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600))),
              DataCell(Text(ded, style: const TextStyle(fontSize: 12, color: Colors.purple))),
              DataCell(Text(adj, style: TextStyle(fontSize: 12, color: colors.textPrimary))),
              DataCell(Text(bal, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ─── Attendance Tab ──────────────────────────────────────────────────────────
  Widget _buildAttendanceTab() {
    if (_attendance.isEmpty) {
      return Center(child: Text(_tr('No attendance records found.')));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _attendance.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _attendance[index];
        final dateStr = (item['date'] ?? '').toString().split('T').first;
        final dihadi = item['dihadi'] ?? 0;
        final earned = item['earnedAmount'] ?? 0;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF0453CD).withValues(alpha: 0.1),
              child: Text('$dihadi', style: const TextStyle(color: Color(0xFF0453CD), fontWeight: FontWeight.bold)),
            ),
            title: Text('${_tr('Date')}: $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('${_tr('Earned Amount')}: ₹$earned'),
            trailing: Text('$dihadi ${_tr('Dihadi')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0453CD))),
          ),
        );
      },
    );
  }

  // ─── Payments Tab ───────────────────────────────────────────────────────────
  Widget _buildPaymentsTab() {
    if (_payments.isEmpty) {
      return Center(child: Text(_tr('No payments recorded yet.')));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _payments[index];
        final dateStr = (item['date'] ?? '').toString().split('T').first;
        final pmtType = item['paymentType'] ?? 'Payment';
        final method = item['paymentMethod'] ?? 'Cash';
        final amount = item['amount'] ?? 0;
        final notes = item['notes'] ?? '';

        final isAdvance = pmtType == 'Advance';

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isAdvance ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
              child: Icon(
                isAdvance ? Icons.payment : Icons.check_circle,
                color: isAdvance ? Colors.orange : Colors.green,
              ),
            ),
            title: Text('${_tr(pmtType)} (₹$amount)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
            subtitle: Text('$dateStr • ${_tr('Payment Method')}: ${_tr(method)}${notes.isNotEmpty ? ' • $notes' : ''}', overflow: TextOverflow.ellipsis),
            trailing: Text('₹$amount', style: TextStyle(fontWeight: FontWeight.bold, color: isAdvance ? Colors.orange : Colors.green)),
          ),
        );
      },
    );
  }

  // ─── ADMIN EDIT & PASSWORD MODALS ──────────────────────────────────────────

  void _showEditLabourModal() {
    if (_labourData == null) return;
    final nameCtrl = TextEditingController(text: _labourData!['name'] ?? '');
    final mobileCtrl = TextEditingController(text: _labourData!['mobileNumber'] ?? '');
    final emailCtrl = TextEditingController(text: _labourData!['email'] ?? '');
    final rateCtrl = TextEditingController(text: (_labourData!['dihadiRate'] ?? 0).toString());
    final addressCtrl = TextEditingController(text: _labourData!['address'] ?? '');
    String type = _labourData!['labourType'] ?? 'Helper';
    String status = _labourData!['status'] ?? 'Active';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(_tr('Edit Labour Details')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: _tr('Full Name *'))),
                  const SizedBox(height: 12),
                  TextField(controller: mobileCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: _tr('Mobile Number *'))),
                  const SizedBox(height: 12),
                  TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: _tr('Email Address'))),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: InputDecoration(labelText: _tr('Labour Type *')),
                    items: [
                      DropdownMenuItem(value: 'Carigar', child: Text(_tr('Carigar'))),
                      DropdownMenuItem(value: 'Helper', child: Text(_tr('Helper'))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => type = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: rateCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _tr('Dihadi Rate (₹) *'))),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(labelText: _tr('Account Status *')),
                    items: [
                      DropdownMenuItem(value: 'Active', child: Text(_tr('Active'))),
                      DropdownMenuItem(value: 'Inactive', child: Text(_tr('Inactive'))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => status = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: addressCtrl, decoration: InputDecoration(labelText: _tr('Address'))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_tr('Cancel'))),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_tr('Please enter full name')), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        setModalState(() => isSaving = true);
                        final res = await ApiService.adminUpdateLabour(widget.labourId, {
                          'name': nameCtrl.text.trim(),
                          'mobileNumber': mobileCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'labourType': type,
                          'dihadiRate': double.tryParse(rateCtrl.text) ?? 800,
                          'address': addressCtrl.text.trim(),
                          'status': status,
                        });

                        if (!context.mounted) return;
                        if (res['success'] == true) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? _tr('Updated successfully!')), backgroundColor: Colors.green),
                          );
                          _loadData();
                        } else {
                          setModalState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? _tr('Failed to update')), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_tr('Save Changes')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetPasswordModal() {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isSaving = false;
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(_tr('Reset Labour Password')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newPassCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: _tr('New Password *'),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setModalState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: _tr('Confirm Password *'),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_tr('Cancel'))),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final newP = newPassCtrl.text.trim();
                        final confP = confirmPassCtrl.text.trim();
                        if (newP.isEmpty || newP.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_tr('Password must be at least 6 characters')), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        if (newP != confP) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_tr('Passwords do not match')), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        setModalState(() => isSaving = true);
                        final res = await ApiService.adminResetLabourPassword(widget.labourId, newP, confP);

                        if (!context.mounted) return;
                        if (res['success'] == true) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? _tr('Password reset successfully!')), backgroundColor: Colors.green),
                          );
                        } else {
                          setModalState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? _tr('Failed to reset password')), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_tr('Reset Password')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleLabourStatus() async {
    final currentStatus = _labourData?['status'] ?? 'Active';
    final targetStatus = currentStatus == 'Active' ? 'Inactive' : 'Active';

    final res = await ApiService.adminUpdateLabour(widget.labourId, {'status': targetStatus});
    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_tr('Account status updated to')} ${_tr(targetStatus)}'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? _tr('Failed to update status')), backgroundColor: Colors.red),
      );
    }
  }
}
