import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/data_sync_notifier.dart';
import '../../models/app_models.dart';
import 'labour_detail_screen.dart';

class LabourMainScreen extends StatefulWidget {
  const LabourMainScreen({super.key});

  @override
  State<LabourMainScreen> createState() => _LabourMainScreenState();
}

class _LabourMainScreenState extends State<LabourMainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Global State
  List<GroupModel> _sites = [];
  String? _selectedSiteId;
  DateTime _selectedDate = DateTime.now();

  // Filters & State for Labour List
  String _labourSearch = '';
  String _selectedLabourType = 'All'; // All, Carigar, Helper
  final String _selectedStatus = 'Active'; // Active, Inactive, All

  // Data Collections
  Map<String, dynamic>? _dashboardData;
  List<Map<String, dynamic>> _labours = [];
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _monthlyReport = [];
  List<Map<String, dynamic>> _siteReport = [];

  // Attendance local edit map: labourId -> dihadi value (0, 0.5, 1, 1.5, 2)
  final Map<String, double> _attendanceMap = {};
  final Map<String, String> _attendanceNotesMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadInitialData();
    DataSyncNotifier.instance.addListener(_loadInitialData);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Fetch Sites/Projects
    _sites = await ApiService.getGroups();
    if (_sites.isNotEmpty && _selectedSiteId == null) {
      _selectedSiteId = _sites.first.id;
    }

    await _refreshAllTabs();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshAllTabs() async {
    final dash = await ApiService.getLabourDashboard();
    final labList = await ApiService.getLabours(
      siteId: _selectedSiteId,
      labourType: _selectedLabourType == 'All' ? null : _selectedLabourType,
      status: _selectedStatus == 'All' ? null : _selectedStatus,
      search: _labourSearch.trim().isEmpty ? null : _labourSearch.trim(),
    );

    final dateStr = _selectedDate.toIso8601String().split('T').first;
    final attList = await ApiService.getAttendance(siteId: _selectedSiteId, date: dateStr);
    final expList = await ApiService.getLabourExpenses(siteId: _selectedSiteId);
    final monthRep = await ApiService.getLabourMonthlyReport(
      month: _selectedDate.month,
      year: _selectedDate.year,
      siteId: _selectedSiteId,
    );
    final siteRep = await ApiService.getLabourSiteReport(siteId: _selectedSiteId);

    if (mounted) {
      setState(() {
        _dashboardData = dash;
        _labours = labList;
        _attendanceRecords = attList;
        _expenses = expList;
        _monthlyReport = monthRep;
        _siteReport = siteRep;

        // Populate local attendance edit state for fast Dihadi selection
        for (final l in _labours) {
          final lId = l['_id'].toString();
          final existingAtt = _attendanceRecords.firstWhere(
            (att) => (att['labourId'] is Map ? att['labourId']['_id'] : att['labourId']) == lId,
            orElse: () => {},
          );
          if (existingAtt.isNotEmpty) {
            _attendanceMap[lId] = (existingAtt['dihadi'] as num).toDouble();
            _attendanceNotesMap[lId] = existingAtt['notes'] ?? '';
          } else {
            _attendanceMap[lId] = _attendanceMap[lId] ?? 1.0; // Default to 1 Dihadi
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text(
          'Labour Management & Dihadi Ledger',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF0453CD),
          indicatorColor: const Color(0xFF0453CD),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Dashboard'),
            Tab(icon: Icon(Icons.how_to_reg_outlined), text: 'Daily Attendance'),
            Tab(icon: Icon(Icons.people_outline), text: 'Labourers'),
            Tab(icon: Icon(Icons.payment_outlined), text: 'Payments & Advances'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Site Kharcha'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Reports'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0453CD)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildAttendanceTab(),
                _buildLabourersTab(),
                _buildPaymentsTab(),
                _buildSiteKharchaTab(),
                _buildReportsTab(),
              ],
            ),
    );
  }

  // ─── 1. DASHBOARD TAB ────────────────────────────────────────────────────────
  Widget _buildDashboardTab() {
    final d = _dashboardData ?? {};
    final totalLabour = d['totalLabour'] ?? 0;
    final carigar = d['totalCarigar'] ?? 0;
    final helper = d['totalHelper'] ?? 0;
    final todayDihadi = d['todayDihadi'] ?? 0;
    final monthlyDihadi = d['monthlyDihadi'] ?? 0;
    final totalEarned = d['totalEarned'] ?? 0;
    final totalPaid = d['totalPaid'] ?? 0;
    final totalAdvance = d['totalAdvance'] ?? 0;
    final totalOutstanding = d['totalOutstanding'] ?? 0;
    final totalSiteKharcha = d['totalSiteKharcha'] ?? 0;
    final totalLabourCost = d['totalLabourCost'] ?? 0;

    return RefreshIndicator(
      onRefresh: _refreshAllTabs,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Header Banner - Responsive Layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 650;
                if (isMobile) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF041627), Color(0xFF0453CD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.engineering, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Labour & Dihadi Ledger Overview',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Active Labourers: $totalLabour (Carigar: $carigar | Helper: $helper)',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showAddLabourModal,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Labour'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0453CD),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF041627), Color(0xFF0453CD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.engineering, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Labour & Dihadi Ledger Overview', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Total Active Labourers: $totalLabour (Carigar: $carigar | Helper: $helper)', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _showAddLabourModal,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Labour'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0453CD),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Top Metric Cards
            const Text('Labour Counts & Attendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossCount = width > 900 ? 4 : (width > 500 ? 2 : 2);
                final ratio = width > 600 ? 2.2 : (width < 380 ? 1.4 : 1.6);

                return GridView.count(
                  crossAxisCount: crossCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: ratio,
                  children: [
                    _buildDashCard('TOTAL LABOUR', '$totalLabour', Icons.groups, const Color(0xFF0453CD)),
                    _buildDashCard('CARIGAR', '$carigar', Icons.engineering, const Color(0xFF2563EB)),
                    _buildDashCard('HELPER', '$helper', Icons.handyman, const Color(0xFF10B981)),
                    _buildDashCard("TODAY'S DIHADI", '$todayDihadi', Icons.today, const Color(0xFFF59E0B)),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Financial Metric Cards
            const Text('Financial Ledger Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossCount = width > 900 ? 4 : (width > 500 ? 2 : 2);
                final ratio = width > 600 ? 2.2 : (width < 380 ? 1.4 : 1.6);

                return GridView.count(
                  crossAxisCount: crossCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: ratio,
                  children: [
                    _buildDashCard('TOTAL EARNED WAGES', '₹$totalEarned', Icons.account_balance, const Color(0xFF6366F1)),
                    _buildDashCard('TOTAL PAID', '₹$totalPaid', Icons.check_circle, const Color(0xFF10B981)),
                    _buildDashCard('TOTAL ADVANCE', '₹$totalAdvance', Icons.payment, const Color(0xFFF97316)),
                    _buildDashCard('OUTSTANDING', '₹$totalOutstanding', Icons.account_balance_wallet, totalOutstanding > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Site Kharcha & Total Labour Cost
            const Text('Site Expenses & Total Cost', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossCount = width > 900 ? 3 : 1;
                final ratio = width > 900 ? 3.2 : (width < 400 ? 2.4 : 3.0);

                return GridView.count(
                  crossAxisCount: crossCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: ratio,
                  children: [
                    _buildDashCard('SITE KHARCHA (TEA/FOOD)', '₹$totalSiteKharcha', Icons.local_cafe, const Color(0xFF8B5CF6)),
                    _buildDashCard('MONTHLY DIHADI TOTAL', '$monthlyDihadi Dihadi', Icons.calendar_month, const Color(0xFF0EA5E9)),
                    _buildDashCard('TOTAL LABOUR COST', '₹$totalLabourCost', Icons.monetization_on, const Color(0xFF0453CD)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.3),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. DAILY ATTENDANCE TAB ───────────────────────────────────────────────
  Widget _buildAttendanceTab() {
    final dateStr = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';

    return Column(
      children: [
        // Top Selectors - Responsive
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 550;
                  if (isMobile) {
                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedSiteId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Select Site/Project',
                            prefixIcon: const Icon(Icons.construction, color: Color(0xFF0453CD)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          items: _sites.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) {
                            setState(() => _selectedSiteId = val);
                            _refreshAllTabs();
                          },
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                                _refreshAllTabs();
                              }
                            },
                            icon: const Icon(Icons.calendar_month, color: Color(0xFF0453CD)),
                            label: Text('Date: $dateStr', style: const TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSiteId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Select Site/Project',
                            prefixIcon: const Icon(Icons.construction, color: Color(0xFF0453CD)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: _sites.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) {
                            setState(() => _selectedSiteId = val);
                            _refreshAllTabs();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                            _refreshAllTabs();
                          }
                        },
                        icon: const Icon(Icons.calendar_month, color: Color(0xFF0453CD)),
                        label: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),

              // Filter & Search
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search Labour...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      ),
                      onChanged: (val) {
                        setState(() => _labourSearch = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedLabourType,
                    underline: const SizedBox(),
                    items: ['All', 'Carigar', 'Helper'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLabourType = val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Attendance List - 100% Responsive Item Layout
        Expanded(
          child: _labours.isEmpty
              ? const Center(child: Text('No active labourers assigned to this site.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _labours.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final labour = _labours[index];
                    final lId = labour['_id'].toString();
                    final name = labour['name'] ?? '';
                    final type = labour['labourType'] ?? 'Helper';
                    final rate = labour['dihadiRate'] ?? 0;
                    final isCarigar = type == 'Carigar';

                    final currentDihadi = _attendanceMap[lId] ?? 1.0;
                    final earnedAmount = currentDihadi * (rate as num);

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 450;
                            if (isNarrow) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: isCarigar ? const Color(0xFF0453CD).withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1),
                                        child: Icon(
                                          isCarigar ? Icons.engineering : Icons.handyman,
                                          color: isCarigar ? const Color(0xFF0453CD) : const Color(0xFF10B981),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                                            Text('$type • ₹$rate/Dihadi', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₹${earnedAmount.toInt()}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0453CD)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFC4C6CD)),
                                    ),
                                    child: DropdownButton<double>(
                                      value: currentDihadi,
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      items: const [
                                        DropdownMenuItem(value: 0.0, child: Text('0 (Absent)')),
                                        DropdownMenuItem(value: 0.5, child: Text('0.5 (Half Dihadi)')),
                                        DropdownMenuItem(value: 1.0, child: Text('1.0 (Full Dihadi)')),
                                        DropdownMenuItem(value: 1.5, child: Text('1.5 Dihadi')),
                                        DropdownMenuItem(value: 2.0, child: Text('2.0 Dihadi')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _attendanceMap[lId] = val);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isCarigar ? const Color(0xFF0453CD).withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1),
                                  child: Icon(
                                    isCarigar ? Icons.engineering : Icons.handyman,
                                    color: isCarigar ? const Color(0xFF0453CD) : const Color(0xFF10B981),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                                      Text('$type • ₹$rate/Dihadi', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFC4C6CD)),
                                  ),
                                  child: DropdownButton<double>(
                                    value: currentDihadi,
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(value: 0.0, child: Text('0 (Absent)')),
                                      DropdownMenuItem(value: 0.5, child: Text('0.5 (Half)')),
                                      DropdownMenuItem(value: 1.0, child: Text('1 (Full)')),
                                      DropdownMenuItem(value: 1.5, child: Text('1.5 Dihadi')),
                                      DropdownMenuItem(value: 2.0, child: Text('2 Dihadi')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _attendanceMap[lId] = val);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    '₹${earnedAmount.toInt()}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0453CD)),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Bulk Save Attendance Bar - Responsive
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;
              final totalSiteDihadi = _attendanceMap.values.fold(0.0, (a, b) => a + b);

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Total Labourers: ${_labours.length} | Today\'s Dihadi: $totalSiteDihadi',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _saveBulkAttendance,
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Save Attendance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0453CD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total Labourers: ${_labours.length} | Today\'s Site Dihadi: $totalSiteDihadi',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveBulkAttendance,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save Attendance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0453CD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _saveBulkAttendance() async {
    if (_selectedSiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a site.')));
      return;
    }

    final dateStr = _selectedDate.toIso8601String().split('T').first;
    final records = _attendanceMap.entries.map((e) {
      return {
        'labourId': e.key,
        'dihadi': e.value,
        'notes': _attendanceNotesMap[e.key] ?? '',
      };
    }).toList();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving daily attendance...'), backgroundColor: Color(0xFF0453CD)),
    );

    final res = await ApiService.saveAttendance(
      siteId: _selectedSiteId!,
      date: dateStr,
      records: records,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Attendance saved successfully!'), backgroundColor: Colors.green),
        );
        _refreshAllTabs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to save attendance'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── 3. LABOURERS TAB ──────────────────────────────────────────────────────
  Widget _buildLabourersTab() {
    return Column(
      children: [
        // Controls - Responsive
        Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by Name or Mobile...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      onChanged: (val) {
                        _labourSearch = val;
                        _refreshAllTabs();
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _showAddLabourModal,
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Add Labour'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0453CD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by Name or Mobile...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (val) {
                        _labourSearch = val;
                        _refreshAllTabs();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddLabourModal,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Labour'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0453CD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // List
        Expanded(
          child: _labours.isEmpty
              ? const Center(child: Text('No labourers found.'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _labours.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _labours[index];
                    final id = item['_id'].toString();
                    final name = item['name'] ?? '';
                    final type = item['labourType'] ?? 'Helper';
                    final rate = item['dihadiRate'] ?? 0;
                    final mobile = item['mobileNumber'] ?? 'N/A';
                    final isCarigar = type == 'Carigar';
                    final summary = item['summary'] ?? {};
                    final outstanding = summary['outstanding'] ?? 0;

                    return Card(
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LabourDetailScreen(labourId: id)),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: isCarigar ? const Color(0xFF0453CD).withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1),
                          child: Icon(isCarigar ? Icons.engineering : Icons.handyman, color: isCarigar ? const Color(0xFF0453CD) : const Color(0xFF10B981)),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        subtitle: Text('$type • Mobile: $mobile • ₹$rate/Dihadi', overflow: TextOverflow.ellipsis),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Outstanding', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text('₹$outstanding', style: TextStyle(fontWeight: FontWeight.bold, color: outstanding > 0 ? Colors.red : Colors.green)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── 4. PAYMENTS & ADVANCES TAB ───────────────────────────────────────────
  Widget _buildPaymentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payments & Advances Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showRecordPaymentModal,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Record Payment / Advance'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0453CD), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payments & Advances Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: _showRecordPaymentModal,
                    icon: const Icon(Icons.add),
                    label: const Text('Record Payment / Advance'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0453CD), foregroundColor: Colors.white),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('Tap "Record Payment / Advance" to record transactions for labourers.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // ─── 5. SITE KHARCHA TAB ──────────────────────────────────────────────────
  Widget _buildSiteKharchaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Site Kharcha (Labour Expense)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showRecordKharchaModal,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Record Site Kharcha'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0453CD), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Site Kharcha (Labour Expense)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: _showRecordKharchaModal,
                    icon: const Icon(Icons.add),
                    label: const Text('Record Site Kharcha'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0453CD), foregroundColor: Colors.white),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          if (_expenses.isEmpty)
            const Center(child: Text('No Site Kharcha recorded yet.'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _expenses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final exp = _expenses[index];
                final category = exp['category'] ?? 'Other';
                final amount = exp['amount'] ?? 0;
                final dateStr = (exp['date'] ?? '').toString().split('T').first;
                final desc = exp['description'] ?? '';

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF8B5CF6),
                      child: Icon(Icons.local_cafe, color: Colors.white),
                    ),
                    title: Text('$category (₹$amount)', style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    subtitle: Text('$dateStr${desc.isNotEmpty ? ' • $desc' : ''}', overflow: TextOverflow.ellipsis),
                    trailing: Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF8B5CF6))),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ─── 6. REPORTS TAB ───────────────────────────────────────────────────────
  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly Labour Ledger Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_monthlyReport.isEmpty)
            const Text('No monthly report data available.')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF041627)),
                headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                columns: const [
                  DataColumn(label: Text('Labour Name')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Dihadi Rate')),
                  DataColumn(label: Text('Total Dihadi')),
                  DataColumn(label: Text('Total Earned')),
                  DataColumn(label: Text('Total Paid')),
                  DataColumn(label: Text('Advance')),
                  DataColumn(label: Text('Outstanding')),
                ],
                rows: _monthlyReport.map((row) {
                  return DataRow(cells: [
                    DataCell(Text(row['name'] ?? '')),
                    DataCell(Text(row['labourType'] ?? '')),
                    DataCell(Text('₹${row['dihadiRate'] ?? 0}')),
                    DataCell(Text('${row['totalDihadi'] ?? 0}')),
                    DataCell(Text('₹${row['totalEarned'] ?? 0}', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold))),
                    DataCell(Text('₹${row['totalPaid'] ?? 0}', style: const TextStyle(color: Colors.green))),
                    DataCell(Text('₹${row['totalAdvance'] ?? 0}', style: const TextStyle(color: Colors.orange))),
                    DataCell(Text('₹${row['outstanding'] ?? 0}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                  ]);
                }).toList(),
              ),
            ),
          const SizedBox(height: 24),
          const Text('Site-Level Labour & Expense Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_siteReport.isEmpty)
            const Text('No site report data available.')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF0453CD)),
                headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                columns: const [
                  DataColumn(label: Text('Site Name')),
                  DataColumn(label: Text('Total Labour')),
                  DataColumn(label: Text('Carigar')),
                  DataColumn(label: Text('Helper')),
                  DataColumn(label: Text('Total Dihadi')),
                  DataColumn(label: Text('Total Earned')),
                  DataColumn(label: Text('Total Paid')),
                  DataColumn(label: Text('Site Kharcha')),
                  DataColumn(label: Text('Total Labour Cost')),
                ],
                rows: _siteReport.map((row) {
                  return DataRow(cells: [
                    DataCell(Text(row['siteName'] ?? '')),
                    DataCell(Text('${row['totalLabour'] ?? 0}')),
                    DataCell(Text('${row['carigar'] ?? 0}')),
                    DataCell(Text('${row['helper'] ?? 0}')),
                    DataCell(Text('${row['totalDihadi'] ?? 0}')),
                    DataCell(Text('₹${row['totalEarned'] ?? 0}', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold))),
                    DataCell(Text('₹${row['totalPaid'] ?? 0}', style: const TextStyle(color: Colors.green))),
                    DataCell(Text('₹${row['siteKharcha'] ?? 0}', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold))),
                    DataCell(Text('₹${row['totalLabourCost'] ?? 0}', style: const TextStyle(color: Color(0xFF0453CD), fontWeight: FontWeight.bold))),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ─── MODALS ───────────────────────────────────────────────────────────────

  void _showAddLabourModal() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '800');
    final contractorCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String type = 'Carigar';
    String? siteId = _selectedSiteId ?? (_sites.isNotEmpty ? _sites.first.id : null);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            
            title: const Text('Add New Labourer'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
                  const SizedBox(height: 12),
                  TextField(controller: mobileCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Number')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Labour Type *'),
                    items: const [
                      DropdownMenuItem(value: 'Carigar', child: Text('Carigar')),
                      DropdownMenuItem(value: 'Helper', child: Text('Helper')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          type = val;
                          rateCtrl.text = val == 'Carigar' ? '800' : '600';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Dihadi Rate (₹) *')),
                  const SizedBox(height: 12),
                  if (_sites.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: siteId ?? _sites.first.id,
                      decoration: const InputDecoration(labelText: 'Site/Project'),
                      items: _sites.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (val) => setModalState(() => siteId = val),
                    ),
                  const SizedBox(height: 12),
                  TextField(controller: contractorCtrl, decoration: const InputDecoration(labelText: 'Contractor/Supervisor')),
                  const SizedBox(height: 12),
                  TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter labour full name'), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        setModalState(() => isSaving = true);

                        final res = await ApiService.createLabour({
                          'name': nameCtrl.text.trim(),
                          'mobileNumber': mobileCtrl.text.trim(),
                          'labourType': type,
                          'dihadiRate': double.tryParse(rateCtrl.text) ?? (type == 'Helper' ? 600 : 800),
                          'siteId': siteId ?? (_sites.isNotEmpty ? _sites.first.id : null),
                          'contractor': contractorCtrl.text.trim(),
                          'notes': notesCtrl.text.trim(),
                        });

                        if (!context.mounted) return;

                        if (res['success'] == true) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Labour added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadInitialData();
                        } else {
                          setModalState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Failed to save labour'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Labour'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRecordPaymentModal() {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String? selectedLabourId = _labours.isNotEmpty ? _labours.first['_id'].toString() : null;
    String pmtType = 'Wage Payment';
    String pmtMethod = 'Cash';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Record Payment / Advance'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedLabourId,
                    decoration: const InputDecoration(labelText: 'Select Labour *'),
                    items: _labours.map((l) => DropdownMenuItem(value: l['_id'].toString(), child: Text(l['name']))).toList(),
                    onChanged: (val) => setModalState(() => selectedLabourId = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: pmtType,
                    decoration: const InputDecoration(labelText: 'Payment Type *'),
                    items: const [
                      DropdownMenuItem(value: 'Wage Payment', child: Text('Wage Payment')),
                      DropdownMenuItem(value: 'Advance', child: Text('Advance')),
                      DropdownMenuItem(value: 'Deduction', child: Text('Deduction')),
                      DropdownMenuItem(value: 'Adjustment', child: Text('Adjustment')),
                    ],
                    onChanged: (val) => setModalState(() => pmtType = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹) *')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: pmtMethod,
                    decoration: const InputDecoration(labelText: 'Payment Method'),
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                      DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                      DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                    ],
                    onChanged: (val) => setModalState(() => pmtMethod = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes / Description')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (selectedLabourId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a labourer'), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        final amt = double.tryParse(amountCtrl.text) ?? 0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        setModalState(() => isSaving = true);

                        final res = await ApiService.recordLabourPayment({
                          'labourId': selectedLabourId,
                          'siteId': _selectedSiteId ?? (_sites.isNotEmpty ? _sites.first.id : null),
                          'amount': amt,
                          'paymentType': pmtType,
                          'paymentMethod': pmtMethod,
                          'notes': notesCtrl.text.trim(),
                        });

                        if (!context.mounted) return;

                        if (res['success'] == true) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Payment recorded successfully!'), backgroundColor: Colors.green),
                          );
                          _refreshAllTabs();
                        } else {
                          setModalState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Failed to record payment'), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Record Payment'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRecordKharchaModal() {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Food';
    String pmtMethod = 'Cash';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Record Site Kharcha'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category *'),
                    items: const [
                      DropdownMenuItem(value: 'Food', child: Text('Food')),
                      DropdownMenuItem(value: 'Tea/Water', child: Text('Tea/Water')),
                      DropdownMenuItem(value: 'Transportation', child: Text('Transportation')),
                      DropdownMenuItem(value: 'Accommodation', child: Text('Accommodation')),
                      DropdownMenuItem(value: 'Tools', child: Text('Tools')),
                      DropdownMenuItem(value: 'Safety Equipment', child: Text('Safety Equipment')),
                      DropdownMenuItem(value: 'Medical', child: Text('Medical')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (val) => setModalState(() => category = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹) *')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: pmtMethod,
                    decoration: const InputDecoration(labelText: 'Payment Method'),
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                      DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                    ],
                    onChanged: (val) => setModalState(() => pmtMethod = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description / Notes')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final amt = double.tryParse(amountCtrl.text) ?? 0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        setModalState(() => isSaving = true);

                        final res = await ApiService.recordLabourExpense({
                          'siteId': _selectedSiteId ?? (_sites.isNotEmpty ? _sites.first.id : null),
                          'category': category,
                          'amount': amt,
                          'paymentMethod': pmtMethod,
                          'description': descCtrl.text.trim(),
                        });

                        if (!context.mounted) return;

                        if (res['success'] == true) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Site kharcha saved successfully!'), backgroundColor: Colors.green),
                          );
                          _refreshAllTabs();
                        } else {
                          setModalState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Failed to save site kharcha'), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Kharcha'),
              ),
            ],
          );
        },
      ),
    );
  }
}
