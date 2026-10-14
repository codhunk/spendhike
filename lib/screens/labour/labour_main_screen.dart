import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/data_sync_notifier.dart';
import '../../models/app_models.dart';
import '../../services/app_settings.dart';
import 'labour_detail_screen.dart';
import 'labour_panel_screen.dart';

class LabourMainScreen extends StatefulWidget {
  const LabourMainScreen({super.key});

  @override
  State<LabourMainScreen> createState() => _LabourMainScreenState();
}

class _LabourMainScreenState extends State<LabourMainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  String _tr(String key) => AppSettings.instance.tr(key);

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
    final colors = AppTheme.of(context);
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              _tr('Labour Management & Dihadi Ledger'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? colors.surface,
            elevation: 1,
            actions: [
              IconButton(
                icon: const Icon(Icons.fact_check_outlined),
                tooltip: _tr('Attendance Corrections'),
                onPressed: _showAttendanceCorrectionsModal,
              ),
              IconButton(
                icon: const Icon(Icons.badge_outlined),
                tooltip: _tr('Worker / Labour Self Panel'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LabourPanelScreen(initialSiteId: _selectedSiteId),
                    ),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: colors.primary,
              indicatorColor: colors.primary,
              unselectedLabelColor: colors.textSecondary,
              tabs: [
                Tab(icon: const Icon(Icons.dashboard_outlined), text: _tr('Dashboard')),
                Tab(icon: const Icon(Icons.how_to_reg_outlined), text: _tr('Daily Attendance')),
                Tab(icon: const Icon(Icons.people_outline), text: _tr('Labourers')),
                Tab(icon: const Icon(Icons.payment_outlined), text: _tr('Payments & Advances')),
                Tab(icon: const Icon(Icons.receipt_long_outlined), text: _tr('Site Kharcha')),
                Tab(icon: const Icon(Icons.analytics_outlined), text: _tr('Reports')),
              ],
            ),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: colors.primary))
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
      },
    );
  }

  // ─── 1. DASHBOARD TAB ────────────────────────────────────────────────────────
  Widget _buildDashboardTab() {
    final colors = AppTheme.of(context);
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
            // Worker Self-Service Portal Quick Access Card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary.withValues(alpha: 0.12), colors.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.badge_outlined, color: colors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr('Labour Self Panel (Worker View)'),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.textPrimary),
                        ),
                        Text(
                          _tr('Self-mark daily dihadi attendance & submit site kharcha'),
                          style: TextStyle(fontSize: 11, color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LabourPanelScreen(initialSiteId: _selectedSiteId),
                        ),
                      );
                    },
                    child: Text(_tr('Open Panel'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

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
                            Expanded(
                              child: Text(
                                _tr('Labour & Dihadi Ledger Overview'),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppSettings.instance.isHindi
                              ? 'कुल सक्रिय मजदूर: $totalLabour (कारीगर: $carigar | हेल्पर: $helper)'
                              : 'Total Active Labourers: $totalLabour (Carigar: $carigar | Helper: $helper)',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showAddLabourModal,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(_tr('Add Labour')),
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
                            Text(_tr('Labour & Dihadi Ledger Overview'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              AppSettings.instance.isHindi
                                  ? 'कुल सक्रिय मजदूर: $totalLabour (कारीगर: $carigar | हेल्पर: $helper)'
                                  : 'Total Active Labourers: $totalLabour (Carigar: $carigar | Helper: $helper)',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _showAddLabourModal,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(_tr('Add Labour')),
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
            Text(_tr('Labour Counts & Attendance'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    _buildDashCard(_tr('TOTAL LABOUR'), '$totalLabour', Icons.groups, const Color(0xFF0453CD)),
                    _buildDashCard(_tr('CARIGAR'), '$carigar', Icons.engineering, const Color(0xFF2563EB)),
                    _buildDashCard(_tr('HELPER'), '$helper', Icons.handyman, const Color(0xFF10B981)),
                    _buildDashCard(_tr("TODAY'S DIHADI"), '$todayDihadi', Icons.today, const Color(0xFFF59E0B)),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Financial Metric Cards
            Text(_tr('Financial Ledger Summary'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    _buildDashCard(_tr('TOTAL EARNED WAGES'), '₹$totalEarned', Icons.account_balance, const Color(0xFF6366F1)),
                    _buildDashCard(_tr('TOTAL PAID'), '₹$totalPaid', Icons.check_circle, const Color(0xFF10B981)),
                    _buildDashCard(_tr('TOTAL ADVANCE'), '₹$totalAdvance', Icons.payment, const Color(0xFFF97316)),
                    _buildDashCard(_tr('OUTSTANDING'), '₹$totalOutstanding', Icons.account_balance_wallet, totalOutstanding > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Site Kharcha & Total Labour Cost
            Text(_tr('Site Expenses & Total Cost'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    _buildDashCard(_tr('SITE KHARCHA (TEA/FOOD)'), '₹$totalSiteKharcha', Icons.local_cafe, const Color(0xFF8B5CF6)),
                    _buildDashCard(_tr('MONTHLY DIHADI TOTAL'), '$monthlyDihadi Dihadi', Icons.calendar_month, const Color(0xFF0EA5E9)),
                    _buildDashCard(_tr('TOTAL LABOUR COST'), '₹$totalLabourCost', Icons.monetization_on, const Color(0xFF0453CD)),
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
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
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
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colors.textSecondary, letterSpacing: 0.3),
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
    final colors = AppTheme.of(context);
    final dateStr = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';

    return Column(
      children: [
        // Top Selectors - Responsive
        Container(
          padding: const EdgeInsets.all(12),
          color: colors.surface,
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
                          dropdownColor: colors.surface,
                          style: TextStyle(color: colors.textPrimary),
                          decoration: InputDecoration(
                            labelText: _tr('Select Site/Project'),
                            labelStyle: TextStyle(color: colors.textSecondary),
                            prefixIcon: Icon(Icons.construction, color: colors.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                          items: _sites.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.textPrimary)))).toList(),
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
                            icon: Icon(Icons.calendar_month, color: colors.primary),
                            label: Text(AppSettings.instance.isHindi ? 'तारीख: $dateStr' : 'Date: $dateStr', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.border),
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
                          dropdownColor: colors.surface,
                          style: TextStyle(color: colors.textPrimary),
                          decoration: InputDecoration(
                            labelText: _tr('Select Site/Project'),
                            labelStyle: TextStyle(color: colors.textSecondary),
                            prefixIcon: Icon(Icons.construction, color: colors.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: _sites.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.textPrimary)))).toList(),
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
                        icon: Icon(Icons.calendar_month, color: colors.primary),
                        label: Text(dateStr, style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.border),
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
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: _tr('Search Labour...'),
                        hintStyle: TextStyle(color: colors.textMuted),
                        prefixIcon: Icon(Icons.search, size: 18, color: colors.textMuted),
                        filled: true,
                        fillColor: colors.surfaceSubtle,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      ),
                      onChanged: (val) {
                        setState(() => _labourSearch = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    dropdownColor: colors.surface,
                    value: _selectedLabourType,
                    underline: const SizedBox(),
                    items: ['All', 'Carigar', 'Helper'].map((t) => DropdownMenuItem(value: t, child: Text(_tr(t), style: TextStyle(fontSize: 13, color: colors.textPrimary)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLabourType = val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.border),

        // Attendance List - 100% Responsive Item Layout
        Expanded(
          child: _labours.isEmpty
              ? Center(child: Text(_tr('No active labourers assigned to this site.')))
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
                                            Text('${_tr(type)} • ₹$rate/${_tr('Dihadi')}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
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
                                      color: colors.surfaceSubtle,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: colors.border),
                                    ),
                                    child: DropdownButton<double>(
                                      dropdownColor: colors.surface,
                                      value: currentDihadi,
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      items: [
                                        DropdownMenuItem(value: 0.0, child: Text(_tr('0 (Absent)'), style: TextStyle(color: colors.textPrimary))),
                                        DropdownMenuItem(value: 0.5, child: Text(_tr('0.5 (Half Dihadi)'), style: TextStyle(color: colors.textPrimary))),
                                        DropdownMenuItem(value: 1.0, child: Text(_tr('1.0 (Full Dihadi)'), style: TextStyle(color: colors.textPrimary))),
                                        DropdownMenuItem(value: 1.5, child: Text(_tr('1.5 Dihadi'), style: TextStyle(color: colors.textPrimary))),
                                        DropdownMenuItem(value: 2.0, child: Text(_tr('2.0 Dihadi'), style: TextStyle(color: colors.textPrimary))),
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
                                  backgroundColor: isCarigar ? colors.primary.withValues(alpha: 0.12) : colors.success.withValues(alpha: 0.12),
                                  child: Icon(
                                    isCarigar ? Icons.engineering : Icons.handyman,
                                    color: isCarigar ? colors.primary : colors.success,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.textPrimary), overflow: TextOverflow.ellipsis),
                                      Text('${_tr(type)} • ₹$rate/${_tr('Dihadi')}', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceSubtle,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: colors.border),
                                  ),
                                  child: DropdownButton<double>(
                                    dropdownColor: colors.surface,
                                    value: currentDihadi,
                                    underline: const SizedBox(),
                                    items: [
                                      DropdownMenuItem(value: 0.0, child: Text(_tr('0 (Absent)'), style: TextStyle(color: colors.textPrimary))),
                                      DropdownMenuItem(value: 0.5, child: Text(_tr('0.5 (Half)'), style: TextStyle(color: colors.textPrimary))),
                                      DropdownMenuItem(value: 1.0, child: Text(_tr('1 (Full)'), style: TextStyle(color: colors.textPrimary))),
                                      DropdownMenuItem(value: 1.5, child: Text(_tr('1.5 Dihadi'), style: TextStyle(color: colors.textPrimary))),
                                      DropdownMenuItem(value: 2.0, child: Text(_tr('2 Dihadi'), style: TextStyle(color: colors.textPrimary))),
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
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colors.primary),
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
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;
              final totalSiteDihadi = _attendanceMap.values.fold(0.0, (a, b) => a + b);

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppSettings.instance.isHindi
                          ? 'कुल मजदूर: ${_labours.length} | आज की दिहाड़ी: $totalSiteDihadi'
                          : 'Total Labourers: ${_labours.length} | Today\'s Dihadi: $totalSiteDihadi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _saveBulkAttendance,
                      icon: const Icon(Icons.save, size: 18),
                      label: Text(_tr('Save Attendance')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
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
                      AppSettings.instance.isHindi
                          ? 'कुल मजदूर: ${_labours.length} | आज की साइट दिहाड़ी: $totalSiteDihadi'
                          : 'Total Labourers: ${_labours.length} | Today\'s Site Dihadi: $totalSiteDihadi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.textPrimary),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveBulkAttendance,
                    icon: const Icon(Icons.save, size: 18),
                    label: Text(_tr('Save Attendance')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_tr('Please select a site.'))));
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
      SnackBar(content: Text(_tr('Saving daily attendance...')), backgroundColor: const Color(0xFF0453CD)),
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
          SnackBar(content: Text(res['message'] ?? _tr('Attendance saved successfully!')), backgroundColor: Colors.green),
        );
        _refreshAllTabs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? _tr('Failed to save attendance')), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── 3. LABOURERS TAB ──────────────────────────────────────────────────────
  Widget _buildLabourersTab() {
    final colors = AppTheme.of(context);
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
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: _tr('Search by Name or Mobile...'),
                        hintStyle: TextStyle(color: colors.textMuted),
                        prefixIcon: Icon(Icons.search, color: colors.textMuted),
                        filled: true,
                        fillColor: colors.surfaceSubtle,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
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
                      label: Text(_tr('Add Labour')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
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
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: _tr('Search by Name or Mobile...'),
                        hintStyle: TextStyle(color: colors.textMuted),
                        prefixIcon: Icon(Icons.search, color: colors.textMuted),
                        filled: true,
                        fillColor: colors.surfaceSubtle,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
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
                    label: Text(_tr('Add Labour')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
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
              ? Center(child: Text(_tr('No labourers found.')))
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
                        subtitle: Text('${_tr(type)} • ${_tr('Mobile Number')}: $mobile • ₹$rate/${_tr('Dihadi')}', overflow: TextOverflow.ellipsis),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_tr('Outstanding'), style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
    final colors = AppTheme.of(context);
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
                    Text(_tr('Payments & Advances Log'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showRecordPaymentModal,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(_tr('Record Payment / Advance')),
                        style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_tr('Payments & Advances Log'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                  ElevatedButton.icon(
                    onPressed: _showRecordPaymentModal,
                    icon: const Icon(Icons.add),
                    label: Text(_tr('Record Payment / Advance')),
                    style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            AppSettings.instance.isHindi
                ? 'मजदूरों के लिए लेन-देन दर्ज करने के लिए "भुगतान / अग्रिम दर्ज करें" पर टैप करें।'
                : 'Tap "Record Payment / Advance" to record transactions for labourers.',
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─── 5. SITE KHARCHA TAB ──────────────────────────────────────────────────
  Widget _buildSiteKharchaTab() {
    final colors = AppTheme.of(context);
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
                    Text(_tr('Site Kharcha (Labour Expense)'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showRecordKharchaModal,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(_tr('Record Site Kharcha')),
                        style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_tr('Site Kharcha (Labour Expense)'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                  ElevatedButton.icon(
                    onPressed: _showRecordKharchaModal,
                    icon: const Icon(Icons.add),
                    label: Text(_tr('Record Site Kharcha')),
                    style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          if (_expenses.isEmpty)
            Center(child: Text(_tr('No Site Kharcha recorded yet.'), style: TextStyle(color: colors.textSecondary)))
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
                    title: Text('${_tr(category)} (₹$amount)', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary), overflow: TextOverflow.ellipsis),
                    subtitle: Text('$dateStr${desc.isNotEmpty ? ' • $desc' : ''}', style: TextStyle(color: colors.textSecondary), overflow: TextOverflow.ellipsis),
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
    final colors = AppTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_tr('Monthly Labour Ledger Report'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
          const SizedBox(height: 12),
          if (_monthlyReport.isEmpty)
            Text(_tr('No monthly report data available.'), style: TextStyle(color: colors.textSecondary))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(colors.isDark ? colors.surfaceSubtle : const Color(0xFF041627)),
                headingTextStyle: TextStyle(color: colors.isDark ? colors.textPrimary : Colors.white, fontWeight: FontWeight.bold),
                columns: [
                  DataColumn(label: Text(_tr('Labour Name'))),
                  DataColumn(label: Text(_tr('Type'))),
                  DataColumn(label: Text(_tr('Dihadi Rate'))),
                  DataColumn(label: Text(_tr('Total Dihadi'))),
                  DataColumn(label: Text(_tr('Total Earned'))),
                  DataColumn(label: Text(_tr('Total Paid'))),
                  DataColumn(label: Text(_tr('Advance'))),
                  DataColumn(label: Text(_tr('Outstanding'))),
                ],
                rows: _monthlyReport.map((row) {
                  return DataRow(cells: [
                    DataCell(Text(row['name'] ?? '', style: TextStyle(color: colors.textPrimary))),
                    DataCell(Text(_tr(row['labourType'] ?? ''), style: TextStyle(color: colors.textPrimary))),
                    DataCell(Text('₹${row['dihadiRate'] ?? 0}', style: TextStyle(color: colors.textPrimary))),
                    DataCell(Text('${row['totalDihadi'] ?? 0}', style: TextStyle(color: colors.textPrimary))),
                    DataCell(Text('₹${row['totalEarned'] ?? 0}', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold))),
                    DataCell(Text('₹${row['totalPaid'] ?? 0}', style: TextStyle(color: colors.success))),
                    DataCell(Text('₹${row['totalAdvance'] ?? 0}', style: TextStyle(color: colors.warning))),
                    DataCell(Text('₹${row['outstanding'] ?? 0}', style: TextStyle(color: colors.error, fontWeight: FontWeight.bold))),
                  ]);
                }).toList(),
              ),
            ),
          const SizedBox(height: 24),
          Text(_tr('Site-Level Labour & Expense Report'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
          const SizedBox(height: 12),
          if (_siteReport.isEmpty)
            Text(_tr('No site report data available.'), style: TextStyle(color: colors.textSecondary))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(colors.isDark ? colors.surfaceSubtle : const Color(0xFF0453CD)),
                headingTextStyle: TextStyle(color: colors.isDark ? colors.textPrimary : Colors.white, fontWeight: FontWeight.bold),
                columns: [
                  DataColumn(label: Text(_tr('Site Name'))),
                  DataColumn(label: Text(_tr('Total Labour'))),
                  DataColumn(label: Text(_tr('Carigar'))),
                  DataColumn(label: Text(_tr('Helper'))),
                  DataColumn(label: Text(_tr('Total Dihadi'))),
                  DataColumn(label: Text(_tr('Total Earned'))),
                  DataColumn(label: Text(_tr('Total Paid'))),
                  DataColumn(label: Text(_tr('Site Kharcha'))),
                  DataColumn(label: Text(_tr('Total Labour Cost'))),
                ],
                rows: _siteReport.map((row) {
                  return DataRow(cells: [
                    DataCell(Text(row['siteName'] ?? '', style: TextStyle(color: colors.textPrimary))),
                    DataCell(Text('${row['totalLabour'] ?? 0}', style: TextStyle(color: colors.textPrimary))),
                    DataCell(Text('${row['carigar'] ?? 0}', style: TextStyle(color: colors.textPrimary))),
                    DataCell(Text('${row['helper'] ?? 0}', style: TextStyle(color: colors.textPrimary))),
                    DataCell(Text('${row['totalDihadi'] ?? 0}', style: TextStyle(color: colors.textPrimary))),
                    DataCell(Text('₹${row['totalEarned'] ?? 0}', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold))),
                    DataCell(Text('₹${row['totalPaid'] ?? 0}', style: TextStyle(color: colors.success))),
                    DataCell(Text('₹${row['siteKharcha'] ?? 0}', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold))),
                    DataCell(Text('₹${row['totalLabourCost'] ?? 0}', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold))),
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
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final rateCtrl = TextEditingController(text: '800');
    final addressCtrl = TextEditingController();
    final contractorCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String type = 'Carigar';
    String? siteId = _selectedSiteId ?? (_sites.isNotEmpty ? _sites.first.id : null);
    bool isSaving = false;
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(_tr('Register New Labour')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_tr('Basic Information'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: _tr('Full Name *'))),
                  const SizedBox(height: 10),
                  TextField(controller: mobileCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: _tr('Mobile Number *'))),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: InputDecoration(labelText: _tr('Labour Type *')),
                    items: [
                      DropdownMenuItem(value: 'Carigar', child: Text(_tr('Carigar'))),
                      DropdownMenuItem(value: 'Helper', child: Text(_tr('Helper'))),
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
                  const SizedBox(height: 10),
                  TextField(controller: rateCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _tr('Daily Wage / Dihadi Rate (₹) *'))),
                  const SizedBox(height: 10),
                  if (_sites.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: siteId ?? _sites.first.id,
                      decoration: InputDecoration(labelText: _tr('Assigned Group / Site *')),
                      items: _sites.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (val) => setModalState(() => siteId = val),
                    ),
                  const SizedBox(height: 14),
                  Text(_tr('Login & Notification (Optional)'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: _tr('Email Address (for Mail Notification)'),
                      hintText: 'worker@example.com',
                      prefixIcon: const Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: _tr('Password'),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setModalState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(labelText: _tr('Confirm Password')),
                  ),
                  const SizedBox(height: 14),
                  Text(_tr('Additional Details'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(controller: addressCtrl, decoration: InputDecoration(labelText: _tr('Address'))),
                  const SizedBox(height: 10),
                  TextField(controller: contractorCtrl, decoration: InputDecoration(labelText: _tr('Contractor/Supervisor'))),
                  const SizedBox(height: 10),
                  TextField(controller: notesCtrl, decoration: InputDecoration(labelText: _tr('Notes'))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_tr('Cancel'))),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final mobile = mobileCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final pass = passCtrl.text.trim();
                        final confirmPass = confirmPassCtrl.text.trim();

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_tr('Please enter labour full name')), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        if (mobile.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_tr('Please enter mobile number')), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        if (pass.isNotEmpty) {
                          if (pass.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_tr('Password must be at least 6 characters')), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          if (pass != confirmPass) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_tr('Passwords do not match')), backgroundColor: Colors.red),
                            );
                            return;
                          }
                        }

                        setModalState(() => isSaving = true);

                        final payload = {
                          'name': name,
                          'mobileNumber': mobile,
                          'email': email.isNotEmpty ? email : null,
                          'password': pass.isNotEmpty ? pass : null,
                          'labourType': type,
                          'dihadiRate': double.tryParse(rateCtrl.text) ?? (type == 'Helper' ? 600 : 800),
                          'siteId': siteId ?? (_sites.isNotEmpty ? _sites.first.id : null),
                          'address': addressCtrl.text.trim(),
                          'contractor': contractorCtrl.text.trim(),
                          'notes': notesCtrl.text.trim(),
                        };

                        final res = pass.isNotEmpty
                            ? await ApiService.adminRegisterLabour(payload)
                            : await ApiService.createLabour(payload);

                        if (!context.mounted) return;

                        if (res['success'] == true) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? _tr('Labour registered successfully!')),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadInitialData();
                        } else {
                          setModalState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? _tr('Failed to save labour')),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_tr('Register Labour')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAttendanceCorrectionsModal() async {
    final colors = AppTheme.of(context);
    List<Map<String, dynamic>> corrections = await ApiService.adminGetAttendanceCorrections(siteId: _selectedSiteId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _tr('Attendance Corrections'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                Text(
                  _tr('Pending approval requests submitted by labour'),
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: corrections.isEmpty
                      ? Center(
                          child: Text(
                            _tr('No pending corrections.'),
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          itemCount: corrections.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final c = corrections[index];
                            final id = c['_id'].toString();
                            final labour = c['labourId'] is Map ? c['labourId'] : {};
                            final labourName = labour['name'] ?? 'Worker';
                            final labourCode = labour['labourId'] ?? '';
                            final dateStr = (c['date'] ?? '').toString().split('T').first;
                            final currentStatus = c['status'] ?? 'Absent';
                            final requestedStatus = c['correctionRequested'] ?? 'Present';
                            final reason = c['correctionReason'] ?? 'Correction requested';

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$labourName ($labourCode)',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                                      ),
                                      Text(dateStr, style: TextStyle(fontSize: 12, color: colors.textMuted)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_tr('Current')}: $currentStatus → ${_tr('Requested')}: $requestedStatus',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: colors.primary, fontSize: 13),
                                  ),
                                  if (reason.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('${_tr('Reason')}: $reason', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                        ),
                                        onPressed: () async {
                                          final res = await ApiService.adminReviewAttendanceCorrection(id, decision: 'Reject');
                                          if (res['success'] == true) {
                                            final updated = await ApiService.adminGetAttendanceCorrections(siteId: _selectedSiteId);
                                            setSheetState(() => corrections = updated);
                                            _refreshAllTabs();
                                          }
                                        },
                                        child: Text(_tr('Reject')),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () async {
                                          final res = await ApiService.adminReviewAttendanceCorrection(id, decision: 'Approve');
                                          if (res['success'] == true) {
                                            final updated = await ApiService.adminGetAttendanceCorrections(siteId: _selectedSiteId);
                                            setSheetState(() => corrections = updated);
                                            _refreshAllTabs();
                                          }
                                        },
                                        child: Text(_tr('Approve')),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
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
            title: Text(_tr('Record Payment / Advance')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedLabourId,
                    decoration: InputDecoration(labelText: _tr('Select Labour *')),
                    items: _labours.map((l) => DropdownMenuItem(value: l['_id'].toString(), child: Text(l['name']))).toList(),
                    onChanged: (val) => setModalState(() => selectedLabourId = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: pmtType,
                    decoration: InputDecoration(labelText: _tr('Payment Type *')),
                    items: [
                      DropdownMenuItem(value: 'Wage Payment', child: Text(_tr('Wage Payment'))),
                      DropdownMenuItem(value: 'Advance', child: Text(_tr('Advance'))),
                      DropdownMenuItem(value: 'Deduction', child: Text(_tr('Deduction'))),
                      DropdownMenuItem(value: 'Adjustment', child: Text(_tr('Adjustment'))),
                    ],
                    onChanged: (val) => setModalState(() => pmtType = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _tr('Amount (₹) *'))),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: pmtMethod,
                    decoration: InputDecoration(labelText: _tr('Payment Method')),
                    items: [
                      DropdownMenuItem(value: 'Cash', child: Text(_tr('Cash'))),
                      DropdownMenuItem(value: 'UPI', child: Text(_tr('UPI'))),
                      DropdownMenuItem(value: 'Bank Transfer', child: Text(_tr('Bank Transfer'))),
                      DropdownMenuItem(value: 'Cheque', child: Text(_tr('Cheque'))),
                    ],
                    onChanged: (val) => setModalState(() => pmtMethod = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: notesCtrl, decoration: InputDecoration(labelText: _tr('Notes / Description'))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_tr('Cancel'))),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (selectedLabourId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_tr('Please select a labourer')), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        final amt = double.tryParse(amountCtrl.text) ?? 0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_tr('Please enter a valid amount')), backgroundColor: Colors.red),
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
                            SnackBar(content: Text(res['message'] ?? _tr('Payment recorded successfully!')), backgroundColor: Colors.green),
                          );
                          _refreshAllTabs();
                        } else {
                          setModalState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? _tr('Failed to record payment')), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_tr('Record Payment')),
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
            title: Text(_tr('Record Site Kharcha')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(labelText: _tr('Category *')),
                    items: [
                      DropdownMenuItem(value: 'Food', child: Text(_tr('Food'))),
                      DropdownMenuItem(value: 'Tea/Water', child: Text(_tr('Tea/Water'))),
                      DropdownMenuItem(value: 'Transportation', child: Text(_tr('Transportation'))),
                      DropdownMenuItem(value: 'Accommodation', child: Text(_tr('Accommodation'))),
                      DropdownMenuItem(value: 'Tools', child: Text(_tr('Tools'))),
                      DropdownMenuItem(value: 'Safety Equipment', child: Text(_tr('Safety Equipment'))),
                      DropdownMenuItem(value: 'Medical', child: Text(_tr('Medical'))),
                      DropdownMenuItem(value: 'Other', child: Text(_tr('Other'))),
                    ],
                    onChanged: (val) => setModalState(() => category = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _tr('Amount (₹) *'))),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: pmtMethod,
                    decoration: InputDecoration(labelText: _tr('Payment Method')),
                    items: [
                      DropdownMenuItem(value: 'Cash', child: Text(_tr('Cash'))),
                      DropdownMenuItem(value: 'UPI', child: Text(_tr('UPI'))),
                      DropdownMenuItem(value: 'Bank Transfer', child: Text(_tr('Bank Transfer'))),
                    ],
                    onChanged: (val) => setModalState(() => pmtMethod = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, decoration: InputDecoration(labelText: _tr('Description / Notes'))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_tr('Cancel'))),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final amt = double.tryParse(amountCtrl.text) ?? 0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_tr('Please enter a valid amount')), backgroundColor: Colors.red),
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
                            SnackBar(content: Text(res['message'] ?? _tr('Site kharcha saved successfully!')), backgroundColor: Colors.green),
                          );
                          _refreshAllTabs();
                        } else {
                          setModalState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? _tr('Failed to save site kharcha')), backgroundColor: Colors.red),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_tr('Save Kharcha')),
              ),
            ],
          );
        },
      ),
    );
  }
}
