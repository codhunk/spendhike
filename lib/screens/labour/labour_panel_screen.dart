import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/data_sync_notifier.dart';
import '../../services/app_settings.dart';
import '../../models/app_models.dart';

class LabourPanelScreen extends StatefulWidget {
  final String? initialSiteId;

  const LabourPanelScreen({super.key, this.initialSiteId});

  @override
  State<LabourPanelScreen> createState() => _LabourPanelScreenState();
}

class _LabourPanelScreenState extends State<LabourPanelScreen> {
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

  // Profile & Site state
  Map<String, dynamic>? _labourProfile;
  Map<String, dynamic>? _dashboardData;
  List<GroupModel> _availableSites = [];
  String? _selectedSiteId;
  String _selectedSiteName = 'Select Project Group';

  // Attendance state
  DateTime _selectedAttendanceDate = DateTime.now();
  double _selectedDihadi = 1.0;
  final TextEditingController _attendanceNotesController = TextEditingController();
  List<Map<String, dynamic>> _myAttendanceList = [];
  bool _isSavingAttendance = false;

  // Expense state
  List<Map<String, dynamic>> _myExpensesList = [];
  bool _isLoadingExpenses = false;

  // Registration form controllers
  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regMobileController = TextEditingController();
  final TextEditingController _regRateController = TextEditingController(text: '800');
  final TextEditingController _regContractorController = TextEditingController();
  final TextEditingController _regNotesController = TextEditingController();
  String _regLabourType = 'Carigar';
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _selectedSiteId = widget.initialSiteId;
    _loadLabourPanelData();
    DataSyncNotifier.instance.addListener(_loadLabourPanelData);
  }

  @override
  void dispose() {
    DataSyncNotifier.instance.removeListener(_loadLabourPanelData);
    _attendanceNotesController.dispose();
    _regNameController.dispose();
    _regMobileController.dispose();
    _regRateController.dispose();
    _regContractorController.dispose();
    _regNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadLabourPanelData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Fetch available project groups
      final groups = await ApiService.getGroups();
      _availableSites = groups;

      // 2. Fetch worker profile
      final profileRes = await ApiService.getMyLabourProfile(siteId: _selectedSiteId);

      if (profileRes != null && profileRes['isRegistered'] == true) {
        _isRegistered = true;
        _labourProfile = profileRes['labour'] != null ? Map<String, dynamic>.from(profileRes['labour']) : null;

        // Resolve current active site
        if (_selectedSiteId == null && _labourProfile?['siteId'] != null) {
          final s = _labourProfile!['siteId'];
          if (s is Map) {
            _selectedSiteId = s['_id']?.toString();
            _selectedSiteName = s['name']?.toString() ?? 'Project Group';
          } else {
            _selectedSiteId = s.toString();
          }
        }

        // 3. Fetch dashboard stats
        final dashRes = await ApiService.getMyLabourDashboard();
        if (dashRes != null && dashRes['success'] == true) {
          _dashboardData = dashRes;
        }

        // 4. Fetch attendance & expenses history
        await _fetchAttendanceHistory();
        await _fetchExpensesHistory();
      } else {
        _isRegistered = false;
        if (profileRes != null && profileRes['user'] != null) {
          final u = profileRes['user'];
          _regNameController.text = u['name'] ?? '';
          _regMobileController.text = u['mobile'] ?? '';
        }
      }

      // Update selected site name from list
      if (_selectedSiteId != null) {
        final match = _availableSites.where((g) => g.id == _selectedSiteId).toList();
        if (match.isNotEmpty) {
          _selectedSiteName = match.first.name;
        }
      } else if (_availableSites.isNotEmpty) {
        _selectedSiteId = _availableSites.first.id;
        _selectedSiteName = _availableSites.first.name;
      }
    } catch (e) {
      debugPrint('[LabourPanel] Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAttendanceHistory() async {
    final list = await ApiService.getMyAttendance(siteId: _selectedSiteId);
    if (mounted) {
      setState(() => _myAttendanceList = list);
    }
  }

  Future<void> _fetchExpensesHistory() async {
    setState(() => _isLoadingExpenses = true);
    final list = await ApiService.getMyExpenses(siteId: _selectedSiteId);
    if (mounted) {
      setState(() {
        _myExpensesList = list;
        _isLoadingExpenses = false;
      });
    }
  }

  void _onSiteChanged(String? newSiteId) {
    if (newSiteId == null || newSiteId == _selectedSiteId) return;
    setState(() {
      _selectedSiteId = newSiteId;
      final match = _availableSites.where((g) => g.id == newSiteId).toList();
      if (match.isNotEmpty) {
        _selectedSiteName = match.first.name;
      }
    });
    _loadLabourPanelData();
  }

  // ─── REGISTRATION SUBMISSION ───────────────────────────────────────────────
  Future<void> _submitRegistration() async {
    if (_selectedSiteId == null || _selectedSiteId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr('Please select a Project Group / Site.')),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
      return;
    }

    final name = _regNameController.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr('Please enter your full name.')),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
      return;
    }

    final rate = double.tryParse(_regRateController.text.trim()) ?? 800;

    setState(() => _isRegistering = true);

    final payload = {
      'siteId': _selectedSiteId,
      'name': name,
      'mobileNumber': _regMobileController.text.trim(),
      'labourType': _regLabourType,
      'dihadiRate': rate,
      'contractor': _regContractorController.text.trim(),
      'notes': _regNotesController.text.trim(),
    };

    final res = await ApiService.registerSelfAsLabour(payload);

    if (mounted) setState(() => _isRegistering = false);

    if (res['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    res['message'] ?? 'Registered successfully! You are now visible to group members.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      await _loadLabourPanelData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Registration failed. Please try again.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // ─── ATTENDANCE SUBMISSION ────────────────────────────────────────────────
  Future<void> _submitAttendance() async {
    setState(() => _isSavingAttendance = true);

    final dateStr = _selectedAttendanceDate.toIso8601String().split('T').first;
    final payload = {
      'siteId': _selectedSiteId,
      'date': dateStr,
      'dihadi': _selectedDihadi,
      'notes': _attendanceNotesController.text.trim(),
    };

    final res = await ApiService.markMyAttendance(payload);

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
                    '${res['message']} Synced with group members.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
      await _fetchAttendanceHistory();
      // Reload dashboard stats
      final dashRes = await ApiService.getMyLabourDashboard();
      if (mounted && dashRes != null) {
        setState(() => _dashboardData = dashRes);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to mark attendance'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  // ─── EXPENSE MODAL ────────────────────────────────────────────────────────
  void _showAddExpenseDialog() {
    final colors = AppTheme.of(context);
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String category = 'Tea & Refreshment';
    String paymentMethod = 'Cash';
    DateTime expenseDate = DateTime.now();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.receipt_long, color: colors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tr('Record Site Kharcha'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                '${_tr("Project")}: $_selectedSiteName',
                                style: TextStyle(fontSize: 12, color: colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Category selection
                    Text(
                      _tr('Kharcha Category'),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Tea & Refreshment',
                        'Hardware & Tools',
                        'Transport / Auto',
                        'Material Purchase',
                        'Misc Expenses',
                      ].map((cat) {
                        final isSel = category == cat;
                        return ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: isSel ? Colors.white : colors.textPrimary,
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: colors.primary,
                          backgroundColor: colors.surfaceSubtle,
                          onSelected: (val) {
                            if (val) setModalState(() => category = cat);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: _tr('Amount (₹)'),
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.primary),
                        filled: true,
                        fillColor: colors.surfaceSubtle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description Field
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: _tr('Description / Details'),
                        hintText: 'e.g. Chai, biscuits & water for 5 workers',
                        filled: true,
                        fillColor: colors.surfaceSubtle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Payment Method & Date row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: paymentMethod,
                            decoration: InputDecoration(
                              labelText: _tr('Paid Via'),
                              filled: true,
                              fillColor: colors.surfaceSubtle,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: colors.border),
                              ),
                            ),
                            items: ['Cash', 'Online / UPI', 'Contractor Balance'].map((m) {
                              return DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => paymentMethod = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: modalCtx,
                                initialDate: expenseDate,
                                firstDate: DateTime(2023),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setModalState(() => expenseDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              decoration: BoxDecoration(
                                color: colors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_month, size: 18, color: colors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _formatDate(expenseDate),
                                      style: TextStyle(fontSize: 13, color: colors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final amt = double.tryParse(amountController.text.trim());
                                if (amt == null || amt <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(_tr('Please enter a valid amount.'))),
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);

                                final payload = {
                                  'siteId': _selectedSiteId,
                                  'category': category,
                                  'amount': amt,
                                  'description': descController.text.trim(),
                                  'paymentMethod': paymentMethod,
                                  'date': expenseDate.toIso8601String(),
                                };

                                final res = await ApiService.recordMyExpense(payload);

                                setModalState(() => isSubmitting = false);

                                if (res['success'] == true) {
                                  if (modalCtx.mounted) {
                                    Navigator.pop(modalCtx);
                                  }
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${res['message']} Updated for group members.',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        backgroundColor: Colors.green.shade700,
                                      ),
                                    );
                                  }
                                  await _fetchExpensesHistory();
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(res['message'] ?? 'Failed to record expense.'),
                                        backgroundColor: Colors.red.shade700,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.sync, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _tr('Save & Sync Kharcha to Group'),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── BUILD ROOT ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _buildAppBar(colors),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: colors.primary))
              : !_isRegistered
                  ? _buildRegistrationView(colors)
                  : _buildActiveTabBody(colors),
          bottomNavigationBar: _isRegistered ? _buildBottomNavigationBar(colors) : null,
        );
      },
    );
  }

  // ─── APP BAR ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(AppSemanticColors colors) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _tr('Labour Self Panel'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colors.textPrimary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade400, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(
                      _tr('Group Sync'),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_availableSites.isNotEmpty)
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSiteId,
                isDense: true,
                dropdownColor: colors.surface,
                icon: Icon(Icons.arrow_drop_down, color: colors.primary, size: 20),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
                items: _availableSites.map((site) {
                  return DropdownMenuItem<String>(
                    value: site.id,
                    child: Text('📍 ${site.name}', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: _onSiteChanged,
              ),
            ),
        ],
      ),
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? colors.surface,
      elevation: 1,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: _tr('Refresh'),
          onPressed: _loadLabourPanelData,
        ),
      ],
    );
  }

  // ─── BOTTOM NAVIGATION BAR (4 TABS) ────────────────────────────────────────
  Widget _buildBottomNavigationBar(AppSemanticColors colors) {
    return NavigationBar(
      selectedIndex: _currentTabIndex,
      onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
      backgroundColor: colors.surface,
      indicatorColor: colors.primary.withValues(alpha: 0.2),
      elevation: 6,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.space_dashboard_outlined),
          selectedIcon: Icon(Icons.space_dashboard, color: colors.primary),
          label: _tr('Dashboard'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.how_to_reg_outlined),
          selectedIcon: Icon(Icons.how_to_reg, color: colors.primary),
          label: _tr('Attendance'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long, color: colors.primary),
          label: _tr('Kharcha'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: colors.primary),
          label: _tr('Profile'),
        ),
      ],
    );
  }

  Widget _buildActiveTabBody(AppSemanticColors colors) {
    switch (_currentTabIndex) {
      case 0:
        return _buildDashboardTab(colors);
      case 1:
        return _buildAttendanceTab(colors);
      case 2:
        return _buildExpenseTab(colors);
      case 3:
        return _buildProfileTab(colors);
      default:
        return _buildDashboardTab(colors);
    }
  }

  // ─── TAB 0: DASHBOARD ──────────────────────────────────────────────────────
  Widget _buildDashboardTab(AppSemanticColors colors) {
    final labour = _dashboardData?['labour'] ?? _labourProfile ?? {};
    final summary = _dashboardData?['summary'] ?? labour['summary'] ?? {};

    final totalDihadi = (summary['totalDihadi'] ?? 0).toDouble();
    final totalEarned = (summary['totalEarned'] ?? 0).toDouble();
    final totalPaid = (summary['totalPaid'] ?? 0).toDouble();
    final totalAdvance = (summary['totalAdvance'] ?? 0).toDouble();
    final outstanding = (summary['outstandingAmount'] ?? (totalEarned - totalPaid - totalAdvance)).toDouble();

    final recentAttendance = (_dashboardData?['recentAttendance'] as List?) ?? [];
    final recentExpenses = (_dashboardData?['recentExpenses'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _loadLabourPanelData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Worker Greeting Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.primary.withBlue(220)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Icon(Icons.handyman, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          labour['name'] ?? 'Worker',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${labour['labourId'] ?? 'LBR-001'}  •  ${labour['labourType'] ?? 'Carigar'}',
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.apartment, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _selectedSiteName,
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text('Rate/Day', style: TextStyle(fontSize: 10, color: Colors.white70)),
                        Text(
                          '₹${labour['dihadiRate'] ?? 800}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Financial Summary Grid
            Text(
              _tr('Earnings & Balance Summary'),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatTile(
                  title: _tr('Total Dihadi'),
                  value: '$totalDihadi days',
                  icon: Icons.calendar_today,
                  iconColor: Colors.blue,
                  colors: colors,
                ),
                _buildStatTile(
                  title: _tr('Total Earned'),
                  value: _formatCurrency(totalEarned),
                  icon: Icons.account_balance_wallet,
                  iconColor: Colors.green,
                  colors: colors,
                ),
                _buildStatTile(
                  title: _tr('Advance Taken'),
                  value: _formatCurrency(totalAdvance),
                  icon: Icons.money_off,
                  iconColor: Colors.orange,
                  colors: colors,
                ),
                _buildStatTile(
                  title: _tr('Pending Balance'),
                  value: _formatCurrency(outstanding),
                  icon: Icons.savings,
                  iconColor: outstanding >= 0 ? Colors.purple : Colors.red,
                  colors: colors,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.touch_app, size: 18),
                    label: Text(_tr('Mark Dihadi')),
                    onPressed: () => setState(() => _currentTabIndex = 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: Text(_tr('+ Site Kharcha')),
                    onPressed: _showAddExpenseDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Attendance Preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tr('Recent Attendance Log'),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentTabIndex = 1),
                  child: Text(_tr('View All')),
                ),
              ],
            ),
            if (recentAttendance.isEmpty)
              _buildEmptyPlaceholder(colors, 'No attendance records yet.')
            else
              ...recentAttendance.take(3).map((att) => _buildAttendanceRow(att, colors)),

            const SizedBox(height: 20),

            // Recent Expenses Preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tr('Recent Site Kharcha'),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentTabIndex = 2),
                  child: Text(_tr('View All')),
                ),
              ],
            ),
            if (recentExpenses.isEmpty)
              _buildEmptyPlaceholder(colors, 'No site expenses recorded yet.')
            else
              ...recentExpenses.take(3).map((exp) => _buildExpenseRow(exp, colors)),
          ],
        ),
      ),
    );
  }

  // ─── TAB 1: ATTENDANCE ─────────────────────────────────────────────────────
  Widget _buildAttendanceTab(AppSemanticColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendance Marking Form Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.fact_check, color: colors.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tr('Mark Daily Attendance'),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                          ),
                          Text(
                            '${_tr("Site")}: $_selectedSiteName',
                            style: TextStyle(fontSize: 12, color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date Picker Tile
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedAttendanceDate,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      setState(() => _selectedAttendanceDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: colors.primary),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(_selectedAttendanceDate),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                            ),
                          ],
                        ),
                        Text(
                          _tr('Change'),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Dihadi Value Selector Buttons
                Text(
                  _tr('Select Dihadi (Work Day Type):'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    {'val': 1.0, 'label': '1.0 Full Day', 'color': Colors.green},
                    {'val': 0.5, 'label': '0.5 Half Day', 'color': Colors.orange},
                    {'val': 1.5, 'label': '1.5 Overtime', 'color': Colors.blue},
                    {'val': 2.0, 'label': '2.0 Double', 'color': Colors.purple},
                    {'val': 0.0, 'label': '0.0 Absent', 'color': Colors.red},
                  ].map((item) {
                    final val = item['val'] as double;
                    final isSel = _selectedDihadi == val;
                    final itemColor = item['color'] as Color;

                    return ChoiceChip(
                      label: Text(
                        item['label'] as String,
                        style: TextStyle(
                          color: isSel ? Colors.white : colors.textPrimary,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: itemColor,
                      backgroundColor: colors.surfaceSubtle,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedDihadi = val);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Attendance Notes Field
                TextField(
                  controller: _attendanceNotesController,
                  decoration: InputDecoration(
                    labelText: _tr('Notes / Remarks (Optional)'),
                    hintText: 'e.g. Worked overtime till 8:30 PM for slab casting',
                    filled: true,
                    fillColor: colors.surfaceSubtle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Save & Sync Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    onPressed: _isSavingAttendance ? null : _submitAttendance,
                    child: _isSavingAttendance
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _tr('Save & Sync Attendance to Group'),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Attendance History List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _tr('My Attendance Log'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
              Text(
                '${_myAttendanceList.length} records',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_myAttendanceList.isEmpty)
            _buildEmptyPlaceholder(colors, 'No attendance logged yet. Mark your first dihadi above!')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _myAttendanceList.length,
              itemBuilder: (context, idx) {
                return _buildAttendanceRow(_myAttendanceList[idx], colors);
              },
            ),
        ],
      ),
    );
  }

  // ─── TAB 2: EXPENSE (SITE KHARCHA) ─────────────────────────────────────────
  Widget _buildExpenseTab(AppSemanticColors colors) {
    double totalKharcha = 0;
    for (final exp in _myExpensesList) {
      totalKharcha += (exp['amount'] ?? 0).toDouble();
    }

    return RefreshIndicator(
      onRefresh: _fetchExpensesHistory,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kharcha Summary Header Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.receipt_long, color: Colors.orange, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr('Total Site Kharcha Logged'),
                          style: TextStyle(fontSize: 13, color: colors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCurrency(totalKharcha),
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.textPrimary),
                        ),
                        Text(
                          '${_tr("Project")}: $_selectedSiteName',
                          style: TextStyle(fontSize: 11, color: colors.primary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(_tr('+ Kharcha')),
                    onPressed: _showAddExpenseDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Expense List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tr('Site Kharcha History'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                Text(
                  '${_myExpensesList.length} items',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoadingExpenses)
              Center(child: Padding(padding: const EdgeInsets.all(24), child: CircularProgressIndicator(color: colors.primary)))
            else if (_myExpensesList.isEmpty)
              _buildEmptyPlaceholder(colors, 'No site kharcha recorded yet. Click "+ Kharcha" to log expenses for chai, transport, or tools!')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _myExpensesList.length,
                itemBuilder: (context, idx) {
                  return _buildExpenseRow(_myExpensesList[idx], colors);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 3: PROFILE ────────────────────────────────────────────────────────
  Widget _buildProfileTab(AppSemanticColors colors) {
    final labour = _labourProfile ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Worker Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: colors.primary.withValues(alpha: 0.15),
                  child: Icon(Icons.person, size: 40, color: colors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  labour['name'] ?? 'Worker',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${labour['labourType'] ?? 'Carigar'}  •  ${labour['labourId'] ?? 'LBR-001'}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Key Info Tiles
                _buildProfileDetailRow(Icons.phone, _tr('Mobile Number'), labour['mobileNumber'] ?? '-', colors),
                _buildProfileDetailRow(Icons.currency_rupee, _tr('Daily Dihadi Rate'), '₹${labour['dihadiRate'] ?? 800} / Day', colors),
                _buildProfileDetailRow(Icons.apartment, _tr('Assigned Project Group'), _selectedSiteName, colors),
                _buildProfileDetailRow(Icons.engineering, _tr('Contractor / Master'), labour['contractor']?.isNotEmpty == true ? labour['contractor'] : 'Direct Site Labour', colors),
                _buildProfileDetailRow(Icons.verified_user, _tr('Status'), labour['status'] ?? 'Active', colors),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Group Integration Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.green.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr('Connected to Group Ledger'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _tr('All your attendance and site kharcha automatically reflect in the group owner & editor dashboards in real time.'),
                        style: TextStyle(fontSize: 12, color: Colors.green.shade900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Change Site / Switch Group
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
                Text(
                  _tr('Switch Project Group / Site'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  _tr('Working at a different site today? Select the active project group to sync:'),
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedSiteId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: colors.surfaceSubtle,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                  ),
                  items: _availableSites.map((g) {
                    return DropdownMenuItem(value: g.id, child: Text(g.name, style: const TextStyle(fontSize: 14)));
                  }).toList(),
                  onChanged: _onSiteChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── REGISTRATION VIEW (IF NOT REGISTERED) ─────────────────────────────────
  Widget _buildRegistrationView(AppSemanticColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Registration Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(Icons.badge, color: Colors.white, size: 34),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr('Labour Self-Registration'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tr('Register your worker profile to join project groups, log daily dihadi, and submit site kharcha.'),
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Project Group Dropdown (Group-wise working)
          Text(
            _tr('1. Select Project Group / Site (Group-wise) *'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSiteId,
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.surfaceSubtle,
              prefixIcon: Icon(Icons.apartment, color: colors.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.border)),
            ),
            hint: Text(_tr('Choose Project Group')),
            items: _availableSites.map((g) {
              return DropdownMenuItem(value: g.id, child: Text(g.name));
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedSiteId = val;
                final match = _availableSites.where((g) => g.id == val).toList();
                if (match.isNotEmpty) _selectedSiteName = match.first.name;
              });
            },
          ),
          const SizedBox(height: 16),

          // Worker Name
          Text(
            _tr('2. Full Name *'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _regNameController,
            decoration: InputDecoration(
              hintText: 'e.g. Ramesh Kumar',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: colors.surfaceSubtle,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.border)),
            ),
          ),
          const SizedBox(height: 16),

          // Mobile Number
          Text(
            _tr('3. Mobile Number'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _regMobileController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'e.g. 9876543210',
              prefixIcon: const Icon(Icons.phone_outlined),
              filled: true,
              fillColor: colors.surfaceSubtle,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.border)),
            ),
          ),
          const SizedBox(height: 16),

          // Trade Category: Carigar vs Helper
          Text(
            _tr('4. Trade Category / Role'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Carigar (कारीगर - Skilled)',
                        style: TextStyle(
                          color: _regLabourType == 'Carigar' ? Colors.white : colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  selected: _regLabourType == 'Carigar',
                  selectedColor: colors.primary,
                  backgroundColor: colors.surfaceSubtle,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _regLabourType = 'Carigar';
                        if (_regRateController.text == '600') _regRateController.text = '800';
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Helper (हेल्पर - Unskilled)',
                        style: TextStyle(
                          color: _regLabourType == 'Helper' ? Colors.white : colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  selected: _regLabourType == 'Helper',
                  selectedColor: colors.primary,
                  backgroundColor: colors.surfaceSubtle,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _regLabourType = 'Helper';
                        if (_regRateController.text == '800') _regRateController.text = '600';
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Daily Dihadi Rate (₹)
          Text(
            _tr('5. Daily Dihadi Rate (₹ / Day) *'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _regRateController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: '₹ ',
              hintText: '800',
              prefixIcon: const Icon(Icons.currency_rupee),
              filled: true,
              fillColor: colors.surfaceSubtle,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.border)),
            ),
          ),
          const SizedBox(height: 16),

          // Contractor Name (Optional)
          Text(
            _tr('6. Contractor / Mistri Name (Optional)'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _regContractorController,
            decoration: InputDecoration(
              hintText: 'e.g. Shyam Contractor',
              prefixIcon: const Icon(Icons.handyman_outlined),
              filled: true,
              fillColor: colors.surfaceSubtle,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.border)),
            ),
          ),
          const SizedBox(height: 24),

          // Register Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              onPressed: _isRegistering ? null : _submitRegistration,
              child: _isRegistering
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      _tr('Register & Join Project Group'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── REUSABLE ROW / TILE WIDGETS ───────────────────────────────────────────
  Widget _buildStatTile({
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(Map<String, dynamic> att, AppSemanticColors colors) {
    final dihadi = (att['dihadi'] ?? 1.0).toDouble();
    final dateStr = att['date']?.toString().split('T').first ?? '';
    final earned = (att['earnedAmount'] ?? 0).toDouble();
    final notes = att['notes']?.toString() ?? '';

    Color badgeColor = Colors.green;
    String badgeText = '$dihadi Dihadi';
    if (dihadi == 0) {
      badgeColor = Colors.red;
      badgeText = 'Absent';
    } else if (dihadi == 0.5) {
      badgeColor = Colors.orange;
      badgeText = '0.5 Half';
    } else if (dihadi == 1.5) {
      badgeColor = Colors.blue;
      badgeText = '1.5 Overtime';
    } else if (dihadi == 2.0) {
      badgeColor = Colors.purple;
      badgeText = '2.0 Double';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              badgeText,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                ),
                if (notes.isNotEmpty)
                  Text(
                    notes,
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            _formatCurrency(earned),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(Map<String, dynamic> exp, AppSemanticColors colors) {
    final amt = (exp['amount'] ?? 0).toDouble();
    final cat = exp['category'] ?? 'Kharcha';
    final desc = exp['description'] ?? '';
    final dateStr = exp['date']?.toString().split('T').first ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                Text(
                  desc.isNotEmpty ? desc : dateStr,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(amt),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value, AppSemanticColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(AppSemanticColors colors, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 36, color: colors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
