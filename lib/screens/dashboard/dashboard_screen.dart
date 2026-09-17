import 'package:flutter/material.dart';
import '../../config/responsive_utils.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';
import '../../services/app_settings.dart';
import '../../services/data_sync_notifier.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardModel> _dashboardFuture;
  String _selectedFilter = ResponsiveUtils.filterAll;

  @override
  void initState() {
    super.initState();
    DataSyncNotifier.instance.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    DataSyncNotifier.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {
        _dashboardFuture = ApiService.getDashboard();
      });
    }
  }

  String _tr(String text) => AppSettings.instance.tr(text);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, child) {
        return FutureBuilder<DashboardModel>(
          future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0453CD)),
          );
        }

        final data = snapshot.data ??
            DashboardModel(
              totalBalance: '₹0.00',
              income: '+₹0.00',
              debit: '-₹0.00',
              credit: '-₹0.00',
              weeklyTrend: '0.0%',
              pendingTasks: 0,
              activeSites: [],
              recentActivities: [],
            );

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: isWide ? 32 : 120,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 900 : 576),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroCard(context, data),
                  const SizedBox(height: 32),
                  _buildQuickWidgets(context, data),
                  const SizedBox(height: 32),
                  _buildActiveSites(context, data),
                  const SizedBox(height: 32),
                  _buildRecentActivity(context, data),
                ],
              ),
            ),
          ),
        );
      },
    );
  },
);
  }

  // ─── Hero Card ──────────────────────────────────────────────────────────────

  Widget _buildHeroCard(BuildContext context, DashboardModel data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF041627), Color(0xFF062C52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF041627).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL BALANCE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB7C8DE).withOpacity(0.7),
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.totalBalance,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFFB7C8DE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            padding: const EdgeInsets.only(top: 24),
            child: Row(
              children: [
                Expanded(child: _buildHeroStat('Income', data.income, Icons.south_west, const Color(0xFF4ADE80))),
                Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                Expanded(child: _buildHeroStat('Debit', data.debit, Icons.north_east, const Color(0xFFF87171))),
                Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                Expanded(child: _buildHeroStat('Credit', data.credit, Icons.credit_card, const Color(0xFF60A5FA))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 12),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ─── Quick Widgets ───────────────────────────────────────────────────────────

  Widget _buildQuickWidgets(BuildContext context, DashboardModel data) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC4C6CD)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Weekly Trend',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF44474C))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(data.weeklyTrend,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700])),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar(0.40, false),
                      _buildBar(0.60, false),
                      _buildBar(0.45, false),
                      _buildBar(0.80, false),
                      _buildBar(1.00, true),
                      _buildBar(0.70, false),
                      _buildBar(0.90, false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC4C6CD)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDAD6).withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment_late_outlined,
                      color: Color(0xFFBA1A1A)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pending\nTasks',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF44474C),
                            height: 1.3)),
                    const SizedBox(height: 4),
                    Text('${data.pendingTasks}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF041627))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBar(double heightFraction, bool isActive) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        height: 40 * heightFraction,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0453CD)
              : const Color(0xFF041627).withOpacity(0.1),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
      ),
    );
  }

  // ─── Active Sites ──────────────────────────────────────────────────────────

  Widget _buildActiveSites(BuildContext context, DashboardModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_tr('Active Sites / Projects'),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B1C30))),
            TextButton(
              onPressed: () => _showSiteLocationsMapDialog(context, data),
              child: const Text('See Map',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0453CD))),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: data.activeSites.map((site) {
              final status = site['status'] as String? ?? 'ON TRACK';
              final isOver = status.contains('OVER');
              final isStarting = status.contains('STARTING');
              final color = isOver
                  ? const Color(0xFFBA1A1A)
                  : isStarting
                      ? Colors.blue[700]!
                      : Colors.green[700]!;
              final bg = isOver
                  ? const Color(0xFFFFDAD6)
                  : isStarting
                      ? Colors.blue[50]!
                      : Colors.green[50]!;

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildSiteCard(
                  site['name'] ?? '',
                  site['amount'] ?? '',
                  status,
                  (site['progress'] as num? ?? 0.5).toDouble(),
                  color,
                  bg,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSiteCard(
    String name,
    String amount,
    String status,
    double progress,
    Color statusColor,
    Color statusBg,
  ) {
    final double safeProgress =
        (progress.isFinite && !progress.isNaN) ? progress.clamp(0.0, 1.0) : 0.0;
    final progressColor = statusColor;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC4C6CD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF041627)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                    color: statusBg, borderRadius: BorderRadius.circular(4)),
                child: Text(status,
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(amount,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF041627))),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: safeProgress,
              backgroundColor: const Color(0xFFC4C6CD),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Recent Activity ──────────────────────────────────────────────────────────

  Widget _buildRecentActivity(BuildContext context, DashboardModel data) {
    final filteredActivities = data.recentActivities.where((act) {
      final amt = act['amount'] as String? ?? '₹0';
      final type = act['type'] as String?;
      return ResponsiveUtils.matchesFilter(
        filter: _selectedFilter,
        amountText: amt,
        type: type,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Activity',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B1C30))),
            TextButton(
              onPressed: () => _showAllRecentActivitiesDialog(context, data),
              child: const Text('View All',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0453CD))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildFilterBar(),
        const SizedBox(height: 12),
        if (filteredActivities.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'No ${_selectedFilter.toLowerCase()} transactions found.',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          )
        else
          ...filteredActivities.map((act) {
          final amt = act['amount'] as String? ?? '₹0';
          final isPositive = amt.startsWith('+');
          final memberName = act['memberName'] ?? 'Author';
          final groupName = act['groupName'] ?? 'Project Group';
          final timing = act['timing'] ?? '';
          final title = act['title'] ?? 'Transaction';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC4C6CD)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isPositive ? Icons.payments : Icons.construction,
                    color: isPositive ? Colors.green[600] : Colors.red[600],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B1C30)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 13, color: Color(0xFF0453CD)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$memberName • $groupName',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF44474C)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (timing.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(
                              timing,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF74777D)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amt,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green[600] : Colors.red[600]),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5EEFF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        (act['statusLabel'] ?? 'Settled').toUpperCase(),
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0453CD),
                            letterSpacing: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showSiteLocationsMapDialog(BuildContext context, DashboardModel data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.map_outlined, color: Color(0xFF0453CD), size: 28),
            SizedBox(width: 10),
            Text('Project Sites & Map Ledger',style: TextStyle(fontSize: 16,fontWeight:FontWeight.bold),),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0453CD)),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.15,
                        child: CustomPaint(painter: _GridPatternPainter()),
                      ),
                    ),
                    const Center(
                      child: Text(
                        'LIVE SATELLITE MAP VIEW',
                        style: TextStyle(
                          color: Colors.white24,
                          letterSpacing: 3,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      left: 60,
                      child: _buildMapPin(context, 'North Plaza', '₹45,200', Colors.green),
                    ),
                    Positioned(
                      top: 110,
                      right: 80,
                      child: _buildMapPin(context, 'West Bridge', '₹12,800', Colors.red),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 140,
                      child: _buildMapPin(context, 'East Tower', '₹8,500', Colors.blue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('ACTIVE SITE LOCATIONS:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF44474C))),
              const SizedBox(height: 8),
              ...data.activeSites.map((site) {
                final status = site['status'] as String? ?? 'ON TRACK';
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on, color: Color(0xFF0453CD)),
                  title: Text(site['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Budget Status: $status'),
                  trailing: Text(site['amount'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF041627))),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close Map', style: TextStyle(color: Color(0xFF0453CD))),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin(BuildContext context, String title, String amount, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected Site: $title ($amount)'),
            backgroundColor: const Color(0xFF0453CD),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Text(
              '$title • $amount',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF041627)),
            ),
          ),
          Icon(Icons.location_on, color: color, size: 28),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', ResponsiveUtils.filterAll, Icons.tune),
          const SizedBox(width: 8),
          _buildFilterChip('Received (+)', ResponsiveUtils.filterReceived, Icons.arrow_downward, color: const Color(0xFF10B981)),
          const SizedBox(width: 8),
          _buildFilterChip('Spent (-)', ResponsiveUtils.filterSpent, Icons.arrow_upward, color: const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon, {Color? color}) {
    final isSelected = _selectedFilter == value;
    final activeColor = color ?? const Color(0xFF0453CD);

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? Colors.white : (color ?? const Color(0xFF64748B)),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      selectedColor: activeColor,
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? activeColor : const Color(0xFFE2E8F0),
        ),
      ),
      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }

  void _showAllRecentActivitiesDialog(BuildContext context, DashboardModel data) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filtered = data.recentActivities.where((act) {
            final amt = act['amount'] as String? ?? '₹0';
            final type = act['type'] as String?;
            return ResponsiveUtils.matchesFilter(
              filter: _selectedFilter,
              amountText: amt,
              type: type,
            );
          }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_outlined, color: Color(0xFF0453CD), size: 26),
                    SizedBox(width: 10),
                    Text('Full Activity Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('All', style: TextStyle(fontSize: 11)),
                        selected: _selectedFilter == ResponsiveUtils.filterAll,
                        onSelected: (sel) {
                          if (sel) {
                            setState(() => _selectedFilter = ResponsiveUtils.filterAll);
                            setDialogState(() {});
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Received (+)', style: TextStyle(fontSize: 11, color: Color(0xFF10B981))),
                        selected: _selectedFilter == ResponsiveUtils.filterReceived,
                        onSelected: (sel) {
                          if (sel) {
                            setState(() => _selectedFilter = ResponsiveUtils.filterReceived);
                            setDialogState(() {});
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Spent (-)', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
                        selected: _selectedFilter == ResponsiveUtils.filterSpent,
                        onSelected: (sel) {
                          if (sel) {
                            setState(() => _selectedFilter = ResponsiveUtils.filterSpent);
                            setDialogState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 550,
              height: 400,
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('No matching transactions found.',
                          style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final act = filtered[i];
                        final amt = act['amount'] as String? ?? '₹0';
                        final isPositive = amt.startsWith('+');
                        final memberName = act['memberName'] ?? 'Author';
                        final groupName = act['groupName'] ?? 'Project Group';
                        final timing = act['timing'] ?? '';
                        final title = act['title'] ?? 'Transaction';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPositive ? Colors.green[50] : Colors.red[50],
                            child: Icon(
                              isPositive ? Icons.payments : Icons.construction,
                              color: isPositive ? Colors.green[600] : Colors.red[600],
                            ),
                          ),
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('$memberName • $groupName\n$timing', style: const TextStyle(fontSize: 11)),
                          trailing: Text(
                            amt,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isPositive ? const Color(0xFF10B981) : const Color(0xFFBA1A1A),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(color: Color(0xFF0453CD))),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
