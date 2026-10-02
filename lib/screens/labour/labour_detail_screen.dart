import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/data_sync_notifier.dart';

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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Labour Details')),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF0453CD))),
      );
    }

    if (_labourData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Labour Details')),
        body: const Center(child: Text('Labour not found')),
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
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(name, overflow: TextOverflow.ellipsis),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0453CD),
          indicatorColor: const Color(0xFF0453CD),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Ledger'),
            Tab(text: 'Attendance'),
            Tab(text: 'Payments'),
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
                                labourType,
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
                        Text('ID: $customId • Site: $siteName', style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                        Text('Mobile: $mobile • Rate: ₹$dihadiRate / Dihadi', style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Financial Summary Cards - Responsive
          const Text('Financial Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  _buildSummaryTile('Total Dihadi', '$totalDihadi Dihadi', Icons.calendar_today, Colors.blue),
                  _buildSummaryTile('Total Earned', '₹$totalEarned', Icons.monetization_on, Colors.indigo),
                  _buildSummaryTile('Total Paid', '₹$totalPaid', Icons.check_circle, Colors.green),
                  _buildSummaryTile('Total Advance', '₹$totalAdvance', Icons.payment, Colors.orange),
                  _buildSummaryTile('Total Deduction', '₹$totalDeduction', Icons.remove_circle_outline, Colors.purple),
                  _buildSummaryTile('Outstanding Balance', '₹$outstanding', Icons.account_balance_wallet, outstanding > 0 ? Colors.red : Colors.green),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis, maxLines: 1),
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
    if (_ledger.isEmpty) {
      return const Center(child: Text('No ledger entries yet.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF041627)),
          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Dihadi')),
            DataColumn(label: Text('Rate')),
            DataColumn(label: Text('Earned')),
            DataColumn(label: Text('Payment')),
            DataColumn(label: Text('Advance')),
            DataColumn(label: Text('Deduction')),
            DataColumn(label: Text('Adjustment')),
            DataColumn(label: Text('Balance')),
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
              DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
              DataCell(Text(desc, style: const TextStyle(fontSize: 12))),
              DataCell(Text(dihadi, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              DataCell(Text(rate, style: const TextStyle(fontSize: 12))),
              DataCell(Text(earned, style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.w600))),
              DataCell(Text(pmt, style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600))),
              DataCell(Text(adv, style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600))),
              DataCell(Text(ded, style: const TextStyle(fontSize: 12, color: Colors.purple))),
              DataCell(Text(adj, style: const TextStyle(fontSize: 12))),
              DataCell(Text(bal, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0453CD)))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ─── Attendance Tab ──────────────────────────────────────────────────────────
  Widget _buildAttendanceTab() {
    if (_attendance.isEmpty) {
      return const Center(child: Text('No attendance records found.'));
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
            title: Text('Date: $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('Earned Amount: ₹$earned'),
            trailing: Text('$dihadi Dihadi', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0453CD))),
          ),
        );
      },
    );
  }

  // ─── Payments Tab ───────────────────────────────────────────────────────────
  Widget _buildPaymentsTab() {
    if (_payments.isEmpty) {
      return const Center(child: Text('No payments recorded yet.'));
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
            title: Text('$pmtType (₹$amount)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
            subtitle: Text('$dateStr • Method: $method${notes.isNotEmpty ? ' • $notes' : ''}', overflow: TextOverflow.ellipsis),
            trailing: Text('₹$amount', style: TextStyle(fontWeight: FontWeight.bold, color: isAdvance ? Colors.orange : Colors.green)),
          ),
        );
      },
    );
  }
}
