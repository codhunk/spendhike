import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/responsive_utils.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';
import '../../services/app_settings.dart';
import '../../services/data_sync_notifier.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  late Future<ReportModel> _reportsFuture;
  String _selectedFilter = ResponsiveUtils.filterAll;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    DataSyncNotifier.instance.addListener(_refresh);
    _refresh();
  }

  void _refresh() {
    if (mounted) {
      setState(() {
        _reportsFuture = ApiService.getReports();
      });
    }
  }

  String _tr(String text) => AppSettings.instance.tr(text);

  @override
  void dispose() {
    DataSyncNotifier.instance.removeListener(_refresh);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, child) {
        return FutureBuilder<ReportModel>(
          future: _reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF0453CD)),
            ),
          );
        }

        final report = snapshot.data ??
            ReportModel(
              totalIncome: '₹0.00',
              totalExpenses: '₹0.00',
              incomeTrend: '0.0%',
              expenseTrend: '0.0%',
              categories: [],
              transactionBreakdown: [],
              forecast: {},
            );

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildBentoGrid(context, report),
                  const SizedBox(height: 48),
                  _buildForecastCard(),
                  const SizedBox(height: 100),
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

  Widget _buildHeader(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Flex(
      direction: isDesktop ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FINANCIAL ANALYSIS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0453CD),
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _tr('Financial Analytics & Reports'),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF041627),
              ),
            ),
          ],
        ),
        if (!isDesktop) const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _downloadReport('PDF'),
              icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFef4444), size: 18),
              label: const Text('Export PDF', style: TextStyle(color: Color(0xFF041627))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF74777D)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _downloadReport('Excel'),
              icon: const Icon(Icons.table_view, color: Colors.white, size: 18),
              label: const Text('Export Excel', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0453CD),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _downloadReport(String format) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $format report from live API...'),
        duration: const Duration(seconds: 1),
      ),
    );

    final content = await ApiService.downloadReportFile(format);
    if (!mounted) return;

    if (content != null && content.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                format == 'PDF' ? Icons.picture_as_pdf : Icons.table_view,
                color: format == 'PDF' ? const Color(0xFFef4444) : const Color(0xFF10b981),
              ),
              const SizedBox(width: 10),
              Text('$format Report Ready'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File: SpendHike_Financial_Report.${format == 'PDF' ? 'pdf' : 'csv'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                height: 160,
                width: double.maxFinite,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$format Report downloaded successfully!'),
                    backgroundColor: const Color(0xFF10b981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Download File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0453CD),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to generate report. Please try again.'),
          backgroundColor: Color(0xFFBA1A1A),
        ),
      );
    }
  }

  Widget _buildBentoGrid(BuildContext context, ReportModel report) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: _buildProfitLossSummary(report)),
              const SizedBox(width: 24),
              Expanded(flex: 5, child: _buildExpenseCategories(report)),
            ],
          )
        else ...[
          _buildProfitLossSummary(report),
          const SizedBox(height: 24),
          _buildExpenseCategories(report),
        ],
        const SizedBox(height: 24),
        _buildTransactionTable(report),
      ],
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildProfitLossSummary(ReportModel report) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const Text(
                'Profit & Loss Summary',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF041627)),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                        color: Color(0xFF10b981), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  const Text('Income',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF44474C))),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                        color: Color(0xFFef4444), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  const Text('Expenses',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF44474C))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 400;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                children: [
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: _buildStatBox(
                      title: 'Total Income',
                      amount: report.totalIncome,
                      amountColor: const Color(0xFF10b981),
                      trendText: '${report.incomeTrend} this period',
                      trendIcon: Icons.trending_up,
                    ),
                  ),
                  SizedBox(
                      width: isWide ? 24 : 0, height: isWide ? 0 : 16),
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: _buildStatBox(
                      title: 'Total Expenses',
                      amount: report.totalExpenses,
                      amountColor: const Color(0xFFef4444),
                      trendText: '${report.expenseTrend} this period',
                      trendIcon: Icons.trending_down,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          // Trend Chart
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFD3E4FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Simulated line chart bars
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (_, __) => CustomPaint(
                        painter: _TrendChartPainter(_animation.value),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('JAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0453CD))),
                      Text('FEB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0453CD))),
                      Text('MAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0453CD))),
                      Text('APR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0453CD))),
                      Text('MAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0453CD))),
                      Text('JUN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0453CD))),
                      Text('JUL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0453CD))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String title,
    required String amount,
    required Color amountColor,
    required String trendText,
    required IconData trendIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF44474C))),
          const SizedBox(height: 4),
          Text(amount,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: amountColor)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(trendIcon, size: 14, color: amountColor),
              const SizedBox(width: 4),
              Text(trendText,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: amountColor)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Expense Categories – Large Animated Donut Chart ──────────────────────────

  Widget _buildExpenseCategories(ReportModel report) {
    final List<Color> categoryColors = [
      const Color(0xFF0453CD), // Royal Blue
      const Color(0xFF10B981), // Emerald Green
      const Color(0xFFF59E0B), // Vibrant Amber
      const Color(0xFF8B5CF6), // Deep Purple
      const Color(0xFFEC4899), // Bright Pink
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFF43F5E), // Coral Rose
      const Color(0xFF14B8A6), // Teal
    ];

    final categories = report.categories.isNotEmpty
        ? List.generate(report.categories.length, (i) {
            final c = report.categories[i];
            final label = c['category'] ?? c['label'] ?? 'General Expense';
            final val = (c['total'] is num
                ? (c['total'] as num).toDouble()
                : (c['amount'] is num ? (c['amount'] as num).toDouble() : 0.0));
            final color = categoryColors[i % categoryColors.length];
            return _ChartSegment(label, val, color);
          })
        : [
            const _ChartSegment('Labour Costs', 40239.00, Color(0xFF0453CD)),
            const _ChartSegment('Raw Materials', 22355.20, Color(0xFF10B981)),
            const _ChartSegment('Fuel & Logistics', 26826.30, Color(0xFFF59E0B)),
            const _ChartSegment('Equipment Maintenance', 12400.00, Color(0xFF8B5CF6)),
          ];
    final total = categories.fold<double>(0, (s, c) => s + c.value);

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expense Categories',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF041627)),
          ),
          const SizedBox(height: 8),
          Text(
            'Total: ₹${_formatAmount(total)}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF44474C)),
          ),
          const SizedBox(height: 24),
          Center(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (_, __) => SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(240, 240),
                      painter: _DonutChartPainter(
                        segments: categories,
                        animationValue: _animation.value,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF44474C),
                              letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${_formatAmount(total)}',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF041627)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'expenses',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF44474C)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildCategoryLegendItem(
                  cat.label,
                  '₹${_formatAmount(cat.value)}',
                  cat.color,
                  total > 0 ? (cat.value / total) : 0.0,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryLegendItem(
      String label, String amount, Color color, double fraction) {
    final double safeFraction =
        (fraction.isFinite && !fraction.isNaN) ? fraction.clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
            Text(amount,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF44474C))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (_, __) {
              final progressVal = (safeFraction * _animation.value).clamp(0.0, 1.0);
              return LinearProgressIndicator(
                value: progressVal.isFinite ? progressVal : 0.0,
                backgroundColor: const Color(0xFFE5EEFF),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTable(ReportModel report) {
    final rawRows = report.transactionBreakdown.isNotEmpty
        ? report.transactionBreakdown
        : [
            {
              'category': 'Client Payments',
              'current': '+₹85,000.00',
              'previous': '+₹72,000.00',
              'variance': '+18.0%',
              'isIncrease': true,
              'type': 'INCOME',
            },
            {
              'category': 'Labour Costs',
              'current': '-₹40,239.00',
              'previous': '-₹38,100.00',
              'variance': '+5.6%',
              'isIncrease': true,
              'type': 'EXPENSE',
            },
            {
              'category': 'Raw Materials',
              'current': '-₹22,355.20',
              'previous': '-₹24,500.00',
              'variance': '-8.7%',
              'isIncrease': false,
              'type': 'EXPENSE',
            },
            {
              'category': 'Fuel & Logistics',
              'current': '-₹26,826.30',
              'previous': '-₹25,200.00',
              'variance': '+6.4%',
              'isIncrease': true,
              'type': 'EXPENSE',
            },
          ];

    final rowsData = rawRows.where((item) {
      final amt = (item['current'] as String? ?? '');
      final type = (item['type'] as String? ?? (amt.startsWith('+') ? 'INCOME' : 'EXPENSE'));
      return ResponsiveUtils.matchesFilter(
        filter: _selectedFilter,
        amountText: amt,
        type: type,
      );
    }).toList();

    return _buildGlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF4FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Color(0xFFC4C6CD))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    const Text(
                      'Transaction Breakdown',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF041627)),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF041627),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'CURRENT PERIOD',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        selected: _selectedFilter == ResponsiveUtils.filterAll,
                        label: const Text('All Breakdown', style: TextStyle(fontSize: 11)),
                        onSelected: (_) => setState(() => _selectedFilter = ResponsiveUtils.filterAll),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _selectedFilter == ResponsiveUtils.filterReceived,
                        avatar: const Icon(Icons.arrow_downward, size: 12, color: Color(0xFF10B981)),
                        label: const Text('Received (+)', style: TextStyle(fontSize: 11)),
                        onSelected: (_) => setState(() => _selectedFilter = ResponsiveUtils.filterReceived),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _selectedFilter == ResponsiveUtils.filterSpent,
                        avatar: const Icon(Icons.arrow_upward, size: 12, color: Color(0xFFEF4444)),
                        label: const Text('Spent (-)', style: TextStyle(fontSize: 11)),
                        onSelected: (_) => setState(() => _selectedFilter = ResponsiveUtils.filterSpent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(const Color(0xFFE5EEFF)),
              columns: const [
                DataColumn(
                    label: Text('CATEGORY',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF44474C)))),
                DataColumn(
                    label: Text('CURRENT PERIOD',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF44474C)))),
                DataColumn(
                    label: Text('PREVIOUS PERIOD',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF44474C)))),
                DataColumn(
                    label: Text('VARIANCE',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF44474C)))),
              ],
              rows: rowsData.map((item) {
                final category = item['category']?.toString() ?? 'General Expense';
                final current = item['current']?.toString() ?? '₹0.00';
                final previous = item['previous']?.toString() ?? '₹0.00';
                final variance = item['variance']?.toString() ?? '0.0%';
                final isIncrease = item['isIncrease'] == true;
                final varColor = isIncrease ? const Color(0xFFef4444) : const Color(0xFF10b981);
                IconData icon = Icons.category;
                if (category.toLowerCase().contains('labour') || category.toLowerCase().contains('labor')) {
                  icon = Icons.engineering;
                } else if (category.toLowerCase().contains('material') || category.toLowerCase().contains('inventory')) {
                  icon = Icons.inventory_2;
                } else if (category.toLowerCase().contains('fuel') || category.toLowerCase().contains('transport')) {
                  icon = Icons.local_gas_station;
                }

                return _buildTableRow(
                  category,
                  icon,
                  current,
                  previous,
                  variance,
                  varColor,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildTableRow(String category, IconData icon, String current,
      String previous, String variance, Color varianceColor) {
    return DataRow(
      cells: [
        DataCell(Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFDAE2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF0453CD), size: 18),
            ),
            const SizedBox(width: 12),
            Text(category),
          ],
        )),
        DataCell(Text(current,
            style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(previous,
            style: const TextStyle(color: Color(0xFF74777D)))),
        DataCell(Text(variance,
            style:
                TextStyle(fontWeight: FontWeight.bold, color: varianceColor))),
      ],
    );
  }

  Widget _buildForecastCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
        image: const DecorationImage(
          image: NetworkImage(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuDbPqXxmOu9zK85zS9R2xw2O3lULuza2DuvBU-FuU_BKnWyB28gPvXlFoili5S6bAnAP6RFqCvKZu7sOLYAzpnl-UdiKwsEyH28YUBXTIA4pNIVe3JU0uBOFjAh-hSQdLwcIh3cnkuRJ_9LUa6Tb83XQq4diV1AhUwcoj9ra0yZbJklxlrKWzdxIQxSZMS5Hxj1uTZkA3uoKBaCQAUPXnld7UA2cQaU6r7X-jKTZnOvpW3AZgEjqqUg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF041627).withOpacity(0.85),
              Colors.transparent,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.all(32),
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Automated Forecasts',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'Based on current trends, your projected income for Q4 is expected to rise by 15.2% due to operational efficiency.',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      // Indian number format
      return amount.toStringAsFixed(2).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return amount.toStringAsFixed(2);
  }

  void _showExportSnackBar(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              format == 'PDF' ? Icons.picture_as_pdf : Icons.table_view,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text('Exporting report as $format...'),
          ],
        ),
        backgroundColor: const Color(0xFF041627),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Chart Data Model ─────────────────────────────────────────────────────────

class _ChartSegment {
  final String label;
  final double value;
  final Color color;
  const _ChartSegment(this.label, this.value, this.color);
}

// ─── Donut Chart Painter ──────────────────────────────────────────────────────

class _DonutChartPainter extends CustomPainter {
  final List<_ChartSegment> segments;
  final double animationValue;

  _DonutChartPainter({required this.segments, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (s, c) => s + c.value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 36.0;
    final outerRadius = radius - strokeWidth / 2;

    const gapAngle = 0.04; // radians gap between segments
    double startAngle = -math.pi / 2;

    for (final seg in segments) {
      final sweepAngle =
          (seg.value / total) * 2 * math.pi * animationValue - gapAngle;

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (sweepAngle > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outerRadius),
          startAngle,
          sweepAngle,
          false,
          paint,
        );
      }
      startAngle += (seg.value / total) * 2 * math.pi;
    }

    // Background ring
    final bgPaint = Paint()
      ..color = const Color(0xFFE5EEFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Draw faint background ring only before animation completes
    if (animationValue < 1.0) {
      canvas.drawCircle(center, outerRadius, bgPaint);
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

// ─── Trend Chart Painter ──────────────────────────────────────────────────────

class _TrendChartPainter extends CustomPainter {
  final double animationValue;

  _TrendChartPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final incomePoints = [0.55, 0.60, 0.50, 0.70, 0.65, 0.80, 0.75];
    final expensePoints = [0.40, 0.45, 0.55, 0.45, 0.50, 0.55, 0.60];

    _drawLine(canvas, size, incomePoints, const Color(0xFF10b981), animationValue);
    _drawLine(canvas, size, expensePoints, const Color(0xFFef4444), animationValue);
  }

  void _drawLine(Canvas canvas, Size size, List<double> points, Color color, double progress) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final step = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * step;
      final y = size.height * (1 - points[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * step;
        final prevY = size.height * (1 - points[i - 1]);
        path.cubicTo(
          prevX + step / 2, prevY,
          x - step / 2, y,
          x, y,
        );
      }
    }

    // Clip by progress
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress),
        paint,
      );
    }

    // Draw dots
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final progressDots = (points.length * progress).floor();
    for (int i = 0; i <= progressDots && i < points.length; i++) {
      canvas.drawCircle(
        Offset(i * step, size.height * (1 - points[i])),
        3,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TrendChartPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
