import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/data_sync_notifier.dart';
import '../../services/app_settings.dart';
import '../../services/session_manager.dart';
import '../auth/login_screen.dart';

class LabourPanelScreen extends StatefulWidget {
  final String? initialSiteId;

  const LabourPanelScreen({super.key, this.initialSiteId});

  @override
  State<LabourPanelScreen> createState() => _LabourPanelScreenState();
}

class _LabourPanelScreenState extends State<LabourPanelScreen> {
  // Navigation Index: 0 = Dashboard, 1 = Attendance, 2 = Reports, 3 = Earnings, 4 = Profile
  int _currentTabIndex = 0;
  bool _isLoading = true;
  bool _isRegistered = false;

  String _tr(String key) => AppSettings.instance.tr(key);

  String _formatCurrency(num amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  // Profile & Site State
  Map<String, dynamic>? _labourProfile;
  Map<String, dynamic>? _dashboardData;
  String _selectedSiteName = 'Assigned Project Site';

  // Attendance Marking State
  DateTime _selectedAttendanceDate = DateTime.now();
  double _selectedDihadi = 1.0; // 1.0 = Present, 0.5 = Half Day, 0.0 = Absent
  final TextEditingController _attendanceNotesController = TextEditingController();
  bool _isSavingAttendance = false;
  List<Map<String, dynamic>> _recentAttendance = [];

  // Reports State
  int _reportMonth = DateTime.now().month;
  final int _reportYear = DateTime.now().year;
  String _reportStatusFilter = 'All'; // All, Present, Half Day, Absent
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  Map<String, dynamic> _reportSummary = {};
  List<Map<String, dynamic>> _reportRecords = [];
  bool _isLoadingReport = false;

  // Earnings State
  Map<String, dynamic> _earningsSummary = {};
  List<Map<String, dynamic>> _paymentsList = [];
  bool _isLoadingEarnings = false;

  // Edit Profile / Password State
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editAddressController = TextEditingController();
  final TextEditingController _currPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isUpdatingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadLabourPanelData();
    DataSyncNotifier.instance.addListener(_loadLabourPanelData);
  }

  @override
  void dispose() {
    DataSyncNotifier.instance.removeListener(_loadLabourPanelData);
    _attendanceNotesController.dispose();
    _editNameController.dispose();
    _editAddressController.dispose();
    _currPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadLabourPanelData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Fetch Labour Dashboard Data
      final dashRes = await ApiService.getLabourDashboardData();

      if (dashRes != null && dashRes['success'] == true && dashRes['isRegistered'] == true) {
        _isRegistered = true;
        _dashboardData = dashRes;
        _labourProfile = dashRes['labour'] != null ? Map<String, dynamic>.from(dashRes['labour']) : null;
        _recentAttendance = dashRes['recentAttendance'] is List ? List<Map<String, dynamic>>.from(dashRes['recentAttendance']) : [];

        if (_labourProfile != null) {
          _editNameController.text = _labourProfile!['name'] ?? '';
          _editAddressController.text = _labourProfile!['address'] ?? '';
          if (_labourProfile!['siteName'] != null) {
            _selectedSiteName = _labourProfile!['siteName'];
          }
        }
      } else {
        // Fallback: check profile
        final profRes = await ApiService.getMyLabourProfile();
        if (profRes != null && profRes['isRegistered'] == true) {
          _isRegistered = true;
          _labourProfile = profRes['labour'] != null ? Map<String, dynamic>.from(profRes['labour']) : null;
        } else {
          _isRegistered = false;
        }
      }

      // 3. Load Reports & Earnings for initial state
      if (_isRegistered) {
        await _fetchAttendanceReport();
        await _fetchEarningsAndPayments();
      }
    } catch (e) {
      debugPrint('[LabourPanel] Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAttendanceReport() async {
    setState(() => _isLoadingReport = true);
    final res = await ApiService.getLabourAttendanceReport(
      month: _reportMonth,
      year: _reportYear,
      startDate: _filterStartDate?.toIso8601String().split('T').first,
      endDate: _filterEndDate?.toIso8601String().split('T').first,
      status: _reportStatusFilter == 'All' ? null : _reportStatusFilter,
    );
    if (mounted) {
      setState(() {
        _reportSummary = res['summary'] ?? {};
        _reportRecords = res['records'] ?? [];
        _isLoadingReport = false;
      });
    }
  }

  Future<void> _fetchEarningsAndPayments() async {
    setState(() => _isLoadingEarnings = true);
    final res = await ApiService.getLabourEarningsAndPayments();
    if (mounted) {
      setState(() {
        _earningsSummary = res['summary'] ?? {};
        _paymentsList = res['payments'] ?? [];
        _isLoadingEarnings = false;
      });
    }
  }

  // ─── ATTENDANCE SUBMISSION (SECTION 4) ────────────────────────────────────
  Future<void> _submitAttendance() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedAttendanceDate.year, _selectedAttendanceDate.month, _selectedAttendanceDate.day);

    if (selectedDay.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('Cannot mark attendance for future dates.')),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isSavingAttendance = true);

    final dateStr = _selectedAttendanceDate.toIso8601String().split('T').first;
    final res = await ApiService.labourMarkAttendance(
      dihadi: _selectedDihadi,
      date: dateStr,
      notes: _attendanceNotesController.text.trim(),
    );

    if (mounted) setState(() => _isSavingAttendance = false);

    if (res['success'] == true) {
      _attendanceNotesController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    res['message'] ?? 'Attendance marked successfully!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
      await _loadLabourPanelData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to mark attendance.'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ─── REQUEST CORRECTION DIALOG ────────────────────────────────────────────
  void _showCorrectionDialog(Map<String, dynamic> record) {
    final colors = AppTheme.of(context);
    final reasonController = TextEditingController();
    double correctionDihadi = (record['dihadi'] ?? 1.0).toDouble();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              title: Row(
                children: [
                  Icon(Icons.edit_note, color: colors.primary),
                  const SizedBox(width: 8),
                  Text(_tr('Request Attendance Correction'), style: TextStyle(fontSize: 16, color: colors.textPrimary)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_tr("Date")}: ${record["date"]?.toString().split("T").first}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _tr('Correct Dihadi:'),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        {'val': 1.0, 'label': 'Present (1.0)'},
                        {'val': 0.5, 'label': 'Half Day (0.5)'},
                        {'val': 0.0, 'label': 'Absent (0.0)'},
                      ].map((item) {
                        final val = item['val'] as double;
                        final isSel = correctionDihadi == val;
                        return ChoiceChip(
                          label: Text(item['label'] as String, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : colors.textPrimary)),
                          selected: isSel,
                          selectedColor: colors.primary,
                          backgroundColor: colors.surfaceSubtle,
                          onSelected: (valSel) {
                            if (valSel) setDialogState(() => correctionDihadi = val);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        labelText: _tr('Reason for Correction *'),
                        hintText: 'e.g. Marked half day by mistake, was full day',
                        filled: true,
                        fillColor: colors.surfaceSubtle,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(_tr('Cancel')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final reason = reasonController.text.trim();
                          if (reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_tr('Please provide a correction reason.'))),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          final res = await ApiService.labourRequestAttendanceCorrection(
                            attendanceId: record['_id'].toString(),
                            requestedDihadi: correctionDihadi,
                            reason: reason,
                          );

                          setDialogState(() => isSubmitting = false);

                          if (res['success'] == true) {
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res['message'] ?? 'Correction request sent to Group Admin.'),
                                  backgroundColor: Colors.green.shade700,
                                ),
                              );
                            }
                            await _loadLabourPanelData();
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res['message'] ?? 'Failed to submit correction request.')),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_tr('Submit to Admin')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── LOGOUT ───────────────────────────────────────────────────────────────
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr('Confirm Logout')),
        content: Text(_tr('Are you sure you want to sign out from the Labour Panel?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_tr('Cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_tr('Logout')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SessionManager.clearSession();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // ─── ROOT BUILD WITH RESPONSIVE NAVIGATION ────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: colors.background,
          appBar: _buildAppBar(colors),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: colors.primary))
              : !_isRegistered
                  ? _buildUnregisteredView(colors)
                  : isDesktop
                      ? _buildDesktopLayout(colors)
                      : _buildActiveTabBody(colors),
          bottomNavigationBar: (!_isLoading && _isRegistered && !isDesktop) ? _buildBottomNavigationBar(colors) : null,
        );
      },
    );
  }

  // ─── APP BAR ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(AppSemanticColors colors) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.engineering, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr('Labour Management Panel'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '📍 $_selectedSiteName',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: colors.surface,
      elevation: 1,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: _tr('Refresh Data'),
          onPressed: _loadLabourPanelData,
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          tooltip: _tr('Logout'),
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  // ─── DESKTOP SIDEBAR NAVIGATION (SECTION 8) ────────────────────────────────
  Widget _buildDesktopLayout(AppSemanticColors colors) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _currentTabIndex,
          onDestinationSelected: (idx) {
            if (idx == 5) {
              _handleLogout();
            } else {
              setState(() => _currentTabIndex = idx);
            }
          },
          labelType: NavigationRailLabelType.all,
          backgroundColor: colors.surface,
          selectedIconTheme: IconThemeData(color: colors.primary),
          unselectedIconTheme: IconThemeData(color: colors.textSecondary),
          selectedLabelTextStyle: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelTextStyle: TextStyle(color: colors.textSecondary, fontSize: 12),
          destinations: [
            NavigationRailDestination(icon: const Icon(Icons.space_dashboard_outlined), selectedIcon: const Icon(Icons.space_dashboard), label: Text(_tr('Dashboard'))),
            NavigationRailDestination(icon: const Icon(Icons.how_to_reg_outlined), selectedIcon: const Icon(Icons.how_to_reg), label: Text(_tr('Attendance'))),
            NavigationRailDestination(icon: const Icon(Icons.assessment_outlined), selectedIcon: const Icon(Icons.assessment), label: Text(_tr('Reports'))),
            NavigationRailDestination(icon: const Icon(Icons.account_balance_wallet_outlined), selectedIcon: const Icon(Icons.account_balance_wallet), label: Text(_tr('Earnings'))),
            NavigationRailDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: Text(_tr('Profile'))),
            NavigationRailDestination(icon: const Icon(Icons.logout, color: Colors.redAccent), label: Text(_tr('Logout'), style: const TextStyle(color: Colors.redAccent))),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: _buildActiveTabBody(colors)),
      ],
    );
  }

  // ─── MOBILE BOTTOM NAVIGATION (5 TABS) ─────────────────────────────────────
  Widget _buildBottomNavigationBar(AppSemanticColors colors) {
    return NavigationBar(
      selectedIndex: _currentTabIndex,
      onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
      backgroundColor: colors.surface,
      indicatorColor: colors.primary.withValues(alpha: 0.18),
      elevation: 6,
      destinations: [
        NavigationDestination(icon: const Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard, color: colors.primary), label: _tr('Dashboard')),
        NavigationDestination(icon: const Icon(Icons.how_to_reg_outlined), selectedIcon: Icon(Icons.how_to_reg, color: colors.primary), label: _tr('Attendance')),
        NavigationDestination(icon: const Icon(Icons.assessment_outlined), selectedIcon: Icon(Icons.assessment, color: colors.primary), label: _tr('Reports')),
        NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet, color: colors.primary), label: _tr('Earnings')),
        NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: colors.primary), label: _tr('Profile')),
      ],
    );
  }

  Widget _buildActiveTabBody(AppSemanticColors colors) {
    switch (_currentTabIndex) {
      case 0: return _buildDashboardTab(colors);
      case 1: return _buildAttendanceTab(colors);
      case 2: return _buildReportsTab(colors);
      case 3: return _buildEarningsTab(colors);
      case 4: return _buildProfileTab(colors);
      default: return _buildDashboardTab(colors);
    }
  }

  // ─── 1. LABOUR DASHBOARD TAB (SECTION 3) ───────────────────────────────────
  Widget _buildDashboardTab(AppSemanticColors colors) {
    final labour = _dashboardData?['labour'] ?? _labourProfile ?? {};
    final summary = _dashboardData?['summary'] ?? {};
    final chartData = (_dashboardData?['monthlyChartData'] as List?) ?? [];

    final todayStatus = summary['todayAttendanceStatus'] ?? 'Not Marked';
    final totalPresent = summary['totalPresentDays'] ?? 0;
    final totalHalf = summary['totalHalfDays'] ?? 0;
    final totalAbsent = summary['totalAbsentDays'] ?? 0;
    final totalDihadi = (summary['totalDihadi'] ?? 0).toDouble();
    final totalEarned = (summary['totalDihadiEarned'] ?? 0).toDouble();
    final totalPaid = (summary['totalPaidAmount'] ?? 0).toDouble();
    final pendingPayment = (summary['pendingPayment'] ?? 0).toDouble();
    final lastAttDate = summary['lastAttendanceDate'] != null ? summary['lastAttendanceDate'].toString().split('T').first : 'None';

    Color todayColor = Colors.grey;
    if (todayStatus == 'Present') {
      todayColor = Colors.green;
    } else if (todayStatus == 'Half Day') {
      todayColor = Colors.orange;
    } else if (todayStatus == 'Absent') {
      todayColor = Colors.red;
    }

    return RefreshIndicator(
      onRefresh: _loadLabourPanelData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, const Color(0xFF0453CD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: colors.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              labour['name'] ?? 'Worker',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              'ID: ${labour["labourId"] ?? "LBR-001"} • Group: ${labour["siteName"] ?? _selectedSiteName}',
                              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          labour['labourType'] ?? 'Carigar',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 16, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            '${_tr("Today's Status")}: ',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: todayColor, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              todayStatus,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Wage: ₹${labour["dihadiRate"] ?? 800} / day',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Metrics Summary Grid (Section 3 Cards)
            Text(
              _tr('Attendance & Payment Summary'),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                _buildStatCard(title: _tr('Total Present'), value: '$totalPresent days', icon: Icons.check_circle, iconColor: Colors.green, colors: colors),
                _buildStatCard(title: _tr('Total Half Days'), value: '$totalHalf days', icon: Icons.timelapse, iconColor: Colors.orange, colors: colors),
                _buildStatCard(title: _tr('Total Absent'), value: '$totalAbsent days', icon: Icons.cancel, iconColor: Colors.red, colors: colors),
                _buildStatCard(title: _tr('Total Dihadi'), value: '$totalDihadi days', icon: Icons.calendar_month, iconColor: Colors.blue, colors: colors),
                _buildStatCard(title: _tr('Total Earned'), value: _formatCurrency(totalEarned), icon: Icons.monetization_on, iconColor: Colors.green.shade700, colors: colors),
                _buildStatCard(title: _tr('Total Paid'), value: _formatCurrency(totalPaid), icon: Icons.payments, iconColor: Colors.teal, colors: colors),
                _buildStatCard(title: _tr('Pending Payment'), value: _formatCurrency(pendingPayment), icon: Icons.pending_actions, iconColor: pendingPayment > 0 ? Colors.purple : Colors.grey, colors: colors),
                _buildStatCard(title: _tr('Last Attendance'), value: lastAttDate, icon: Icons.history, iconColor: Colors.indigo, colors: colors),
              ],
            ),
            const SizedBox(height: 20),

            // Monthly Earnings Visual Chart (Section 3)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _tr('Monthly Earnings & Dihadi'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
                      ),
                      Text(
                        _tr('Past 6 Months'),
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (chartData.isEmpty)
                    Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_tr('No monthly history available yet.'))))
                  else
                    SizedBox(
                      height: 140,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: chartData.map((cd) {
                          final mEarn = (cd['earnings'] ?? 0).toDouble();
                          final mDihadi = (cd['dihadi'] ?? 0).toDouble();
                          final monthLabel = cd['month'] ?? '';
                          // Max height normalization
                          final maxEarn = chartData.map((c) => (c['earnings'] ?? 0).toDouble()).reduce((a, b) => a > b ? a : b);
                          final heightRatio = maxEarn > 0 ? (mEarn / maxEarn) : 0.05;

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                _formatCurrency(mEarn),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.primary),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 28,
                                height: (heightRatio * 85).clamp(10.0, 85.0),
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                monthLabel,
                                style: TextStyle(fontSize: 10, color: colors.textSecondary),
                              ),
                              Text(
                                '$mDihadi D',
                                style: TextStyle(fontSize: 9, color: colors.textMuted),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Mark Attendance Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.how_to_reg, size: 20),
                label: Text(_tr('Mark Today\'s Attendance Now'), style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => setState(() => _currentTabIndex = 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 2. ATTENDANCE MANAGEMENT TAB (SECTION 4) ──────────────────────────────
  Widget _buildAttendanceTab(AppSemanticColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendance Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.fact_check, color: colors.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_tr('Mark My Attendance'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                          Text('${_tr("Assigned Group")}: $_selectedSiteName', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedAttendanceDate,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(), // Strictly blocks future dates!
                    );
                    if (picked != null) {
                      setState(() => _selectedAttendanceDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: colors.primary),
                            const SizedBox(width: 10),
                            Text(_formatDate(_selectedAttendanceDate), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                          ],
                        ),
                        Text(_tr('Change Date'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Attendance Dihadi Options
                Text(
                  _tr('Attendance Status:'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text('Present\n(1 Dihadi)', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _selectedDihadi == 1.0 ? Colors.white : colors.textPrimary))),
                        selected: _selectedDihadi == 1.0,
                        selectedColor: Colors.green.shade700,
                        backgroundColor: colors.surfaceSubtle,
                        onSelected: (val) { if (val) setState(() => _selectedDihadi = 1.0); },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text('Half Day\n(0.5 Dihadi)', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _selectedDihadi == 0.5 ? Colors.white : colors.textPrimary))),
                        selected: _selectedDihadi == 0.5,
                        selectedColor: Colors.orange.shade800,
                        backgroundColor: colors.surfaceSubtle,
                        onSelected: (val) { if (val) setState(() => _selectedDihadi = 0.5); },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text('Absent\n(0 Dihadi)', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _selectedDihadi == 0.0 ? Colors.white : colors.textPrimary))),
                        selected: _selectedDihadi == 0.0,
                        selectedColor: Colors.red.shade700,
                        backgroundColor: colors.surfaceSubtle,
                        onSelected: (val) { if (val) setState(() => _selectedDihadi = 0.0); },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Server Wage Calculation Preview
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_tr('Server Wage Rate:'), style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                      Text(
                        '$_selectedDihadi Dihadi × ₹${_labourProfile?["dihadiRate"] ?? 800} = ₹${(_selectedDihadi * (_labourProfile?["dihadiRate"] ?? 800)).toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Remarks / Notes
                TextField(
                  controller: _attendanceNotesController,
                  decoration: InputDecoration(
                    labelText: _tr('Notes / Remarks (Optional)'),
                    hintText: 'e.g. Worked at Block B slab',
                    filled: true,
                    fillColor: colors.surfaceSubtle,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSavingAttendance ? null : _submitAttendance,
                    child: _isSavingAttendance
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_tr('Save Attendance'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Attendance History with Correction Option
          Text(_tr('Recent Attendance History'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary)),
          const SizedBox(height: 10),

          if (_recentAttendance.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_tr('No attendance recorded yet.'))))
          else
            ..._recentAttendance.map((rec) => _buildAttendanceItem(rec, colors)),
        ],
      ),
    );
  }

  // ─── 3. ATTENDANCE REPORT TAB (SECTION 5) ──────────────────────────────────
  Widget _buildReportsTab(AppSemanticColors colors) {
    final totalDays = _reportSummary['totalWorkingDays'] ?? 0;
    final totalD = (_reportSummary['totalDihadi'] ?? 0).toDouble();
    final totalE = (_reportSummary['totalEarnings'] ?? 0).toDouble();
    final totalP = (_reportSummary['totalPaid'] ?? 0).toDouble();
    final remain = (_reportSummary['remainingPayment'] ?? 0).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_tr('Report Filters'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Month Dropdown
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _reportMonth,
                        decoration: InputDecoration(
                          labelText: _tr('Month'),
                          isDense: true,
                          filled: true,
                          fillColor: colors.surfaceSubtle,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: List.generate(12, (i) {
                          const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          return DropdownMenuItem(value: i + 1, child: Text(monthNames[i]));
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _reportMonth = val);
                            _fetchAttendanceReport();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _reportStatusFilter,
                        decoration: InputDecoration(
                          labelText: _tr('Status'),
                          isDense: true,
                          filled: true,
                          fillColor: colors.surfaceSubtle,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: ['All', 'Present', 'Half Day', 'Absent'].map((s) {
                          return DropdownMenuItem(value: s, child: Text(s));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _reportStatusFilter = val);
                            _fetchAttendanceReport();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary Metrics Banner (Section 5)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary.withValues(alpha: 0.12), colors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Working Days: $totalDays', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.textPrimary)),
                    Text('Total Dihadi: $totalD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Earned: ${_formatCurrency(totalE)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade700)),
                    Text('Paid: ${_formatCurrency(totalP)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal)),
                    Text('Balance: ${_formatCurrency(remain)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Records List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_tr("Attendance Records")} (${_reportRecords.length})', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              IconButton(
                icon: const Icon(Icons.share, size: 20),
                tooltip: _tr('Export Report'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_tr('Export report generated: ${_reportRecords.length} records.'))),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_isLoadingReport)
            Center(child: Padding(padding: const EdgeInsets.all(24), child: CircularProgressIndicator(color: colors.primary)))
          else if (_reportRecords.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_tr('No records found for the selected filter.'))))
          else
            ..._reportRecords.map((r) => _buildReportItem(r, colors)),
        ],
      ),
    );
  }

  // ─── 4. EARNINGS & PAYMENT HISTORY TAB (SECTION 6) ─────────────────────────
  Widget _buildEarningsTab(AppSemanticColors colors) {
    final totalE = (_earningsSummary['totalEarnings'] ?? 0).toDouble();
    final totalP = (_earningsSummary['totalPaid'] ?? 0).toDouble();
    final pending = (_earningsSummary['pendingPayment'] ?? 0).toDouble();

    return RefreshIndicator(
      onRefresh: _fetchEarningsAndPayments,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formula Card (Section 6)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.functions, color: colors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(_tr('Earnings & Payment Formula'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Total Earnings = Sum of Approved Attendance Dihadi × Applicable Daily Wage\n• Pending Payment = Total Earnings − Total Payments Recorded',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildFinancialTile(title: _tr('Total Earned'), amount: totalE, color: Colors.green.shade700, colors: colors),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFinancialTile(title: _tr('Total Paid'), amount: totalP, color: Colors.teal, colors: colors),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFinancialTile(title: _tr('Pending Balance'), amount: pending, color: pending > 0 ? Colors.purple : Colors.grey, colors: colors),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Payment History List
            Text(_tr('Payment History Log'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            const SizedBox(height: 10),

            if (_isLoadingEarnings)
              Center(child: Padding(padding: const EdgeInsets.all(24), child: CircularProgressIndicator(color: colors.primary)))
            else if (_paymentsList.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_tr('No payment records logged yet.'))))
            else
              ..._paymentsList.map((p) => _buildPaymentItem(p, colors)),
          ],
        ),
      ),
    );
  }

  // ─── 5. LABOUR PROFILE TAB (SECTION 7) ─────────────────────────────────────
  Widget _buildProfileTab(AppSemanticColors colors) {
    final labour = _labourProfile ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Details Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: colors.primary.withValues(alpha: 0.15),
                  child: Icon(Icons.engineering, size: 40, color: colors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  labour['name'] ?? 'Worker',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${labour["labourType"] ?? "Carigar"} • ID: ${labour["labourId"] ?? "LBR-001"}',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                _buildProfileRow(Icons.phone, _tr('Mobile Number'), labour['mobileNumber'] ?? '-', colors),
                _buildProfileRow(Icons.email, _tr('Email Address'), labour['email'] ?? '-', colors),
                _buildProfileRow(Icons.currency_rupee, _tr('Daily Wage Rate'), '₹${labour["dihadiRate"] ?? 800} / day (Admin Managed)', colors),
                _buildProfileRow(Icons.apartment, _tr('Assigned Project Group'), _selectedSiteName, colors),
                _buildProfileRow(Icons.home, _tr('Address'), labour['address'] ?? 'Not provided', colors),
                _buildProfileRow(Icons.verified, _tr('Account Status'), labour['status'] ?? 'Active', colors),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Edit Permitted Profile Details Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_tr('Update Permitted Profile Details'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                const SizedBox(height: 12),
                TextField(
                  controller: _editNameController,
                  decoration: InputDecoration(
                    labelText: _tr('Full Name'),
                    filled: true,
                    fillColor: colors.surfaceSubtle,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _editAddressController,
                  decoration: InputDecoration(
                    labelText: _tr('Address / City'),
                    filled: true,
                    fillColor: colors.surfaceSubtle,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white),
                    onPressed: _isUpdatingProfile
                        ? null
                        : () async {
                            setState(() => _isUpdatingProfile = true);
                            final res = await ApiService.updateLabourProfile(
                              name: _editNameController.text.trim(),
                              address: _editAddressController.text.trim(),
                            );
                            setState(() => _isUpdatingProfile = false);
                            if (res['success'] == true) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(_tr('Profile updated successfully.')), backgroundColor: Colors.green.shade700),
                                );
                              }
                              await _loadLabourPanelData();
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(res['message'] ?? 'Failed to update profile.')),
                                );
                              }
                            }
                          },
                    child: _isUpdatingProfile
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_tr('Save Profile Changes')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Change Password Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_tr('Change Account Password'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                const SizedBox(height: 12),
                TextField(
                  controller: _currPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _tr('Current Password'),
                    filled: true,
                    fillColor: colors.surfaceSubtle,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _tr('New Password (min 6 chars)'),
                    filled: true,
                    fillColor: colors.surfaceSubtle,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _tr('Confirm New Password'),
                    filled: true,
                    fillColor: colors.surfaceSubtle,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    onPressed: () async {
                      final curr = _currPasswordController.text.trim();
                      final pNew = _newPasswordController.text.trim();
                      final conf = _confirmPasswordController.text.trim();

                      if (curr.isEmpty || pNew.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_tr('Please enter current and new password.'))),
                        );
                        return;
                      }

                      final res = await ApiService.changeLabourPassword(
                        currentPassword: curr,
                        newPassword: pNew,
                        confirmPassword: conf,
                      );

                      if (res['success'] == true) {
                        _currPasswordController.clear();
                        _newPasswordController.clear();
                        _confirmPasswordController.clear();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Password changed successfully.'), backgroundColor: Colors.green.shade700),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Failed to change password.'), backgroundColor: Colors.red.shade700),
                          );
                        }
                      }
                    },
                    child: Text(_tr('Update Password')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Action Tile
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: Text(_tr('Sign Out from Labour Panel')),
              onPressed: _handleLogout,
            ),
          ),
        ],
      ),
    );
  }

  // ─── UNREGISTERED VIEW ────────────────────────────────────────────────────
  Widget _buildUnregisteredView(AppSemanticColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge_outlined, size: 64, color: colors.primary),
            const SizedBox(height: 16),
            Text(
              _tr('No Labour Profile Found'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _tr('Your account is not registered under any group. Please ask your Group Admin or Contractor to register you with your mobile number or email.'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleLogout,
              child: Text(_tr('Return to Main Login')),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HELPER REUSABLE WIDGETS ───────────────────────────────────────────────
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required AppSemanticColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTile({
    required String title,
    required double amount,
    required Color color,
    required AppSemanticColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(amount),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(Map<String, dynamic> rec, AppSemanticColors colors) {
    final d = (rec['dihadi'] ?? 1.0).toDouble();
    final dateStr = rec['date']?.toString().split('T').first ?? '';
    final earned = (rec['earnedAmount'] ?? (d * (rec['dihadiRate'] ?? 800))).toDouble();
    final approvalStatus = rec['approvalStatus'] ?? 'Approved';
    final isPendingCorrection = rec['correctionRequested'] == true || approvalStatus == 'Pending';

    Color badgeColor = Colors.green;
    String badgeText = 'Present (1D)';
    if (d == 0.5) { badgeColor = Colors.orange; badgeText = 'Half Day (0.5D)'; }
    else if (d == 0) { badgeColor = Colors.red; badgeText = 'Absent (0D)'; }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPendingCorrection ? Colors.orange.shade300 : colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(badgeText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                if (isPendingCorrection)
                  Text(_tr('Correction Pending Admin Approval'), style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600))
                else if (rec['notes'] != null && rec['notes'].toString().isNotEmpty)
                  Text(rec['notes'], style: TextStyle(fontSize: 11, color: colors.textSecondary), maxLines: 1),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatCurrency(earned), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              if (!isPendingCorrection)
                InkWell(
                  onTap: () => _showCorrectionDialog(rec),
                  child: Text(_tr('Correction?'), style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(Map<String, dynamic> r, AppSemanticColors colors) {
    final d = (r['dihadi'] ?? 1.0).toDouble();
    final dateStr = r['date']?.toString().split('T').first ?? '';
    final rate = r['dihadiRate'] ?? 800;
    final earned = (r['earnedAmount'] ?? (d * rate)).toDouble();
    final status = r['status'] ?? (d >= 1 ? 'Present' : (d == 0.5 ? 'Half Day' : 'Absent'));
    final approvalStatus = r['approvalStatus'] ?? 'Approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                Text('$status • $d Dihadi • Rate: ₹$rate', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatCurrency(earned), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: approvalStatus == 'Approved' ? Colors.green.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(approvalStatus, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: approvalStatus == 'Approved' ? Colors.green : Colors.orange)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> p, AppSemanticColors colors) {
    final amt = (p['amount'] ?? 0).toDouble();
    final dateStr = p['date']?.toString().split('T').first ?? '';
    final method = p['paymentMethod'] ?? 'Cash';
    final notes = p['notes'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.payment, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                Text('Paid via $method ${notes.isNotEmpty ? "• $notes" : ""}', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
              ],
            ),
          ),
          Text(_formatCurrency(amt), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value, AppSemanticColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary))),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textPrimary)),
        ],
      ),
    );
  }
}
