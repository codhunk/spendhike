import 'package:flutter/material.dart';
import '../../services/app_settings.dart';
import '../../services/api_service.dart';
import '../../services/data_sync_notifier.dart';
import '../../widgets/spend_hike_logo.dart';
import '../../widgets/notifications_sheet.dart';
import '../dashboard/dashboard_screen.dart';
import '../transaction/new_transaction_screen.dart';
import '../profile/profile_screen.dart';
import '../groups/groups_screen.dart';
import '../labour/labour_main_screen.dart';
import '../reports/reports_screen.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/theme_switcher.dart';
import '../../config/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    DataSyncNotifier.instance.addListener(_onDataSyncChanged);
  }

  void _onDataSyncChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  static const _navItems = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    _NavItem(Icons.engineering_outlined, Icons.engineering, 'Labour'),
    _NavItem(Icons.grid_view_outlined, Icons.grid_view, 'Groups'),
    _NavItem(Icons.analytics_outlined, Icons.analytics, 'Reports'),
    _NavItem(Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, child) {
        final colors = AppTheme.of(context);
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: isDesktop ? null : _buildAppBar(),
          body: isDesktop ? _buildDesktopLayout() : _buildMobileBody(),
          floatingActionButton: isDesktop
              ? null
              : (_selectedIndex == 0 || _selectedIndex == 1)
                  ? FloatingActionButton(
                      onPressed: _openNewTransaction,
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.add, size: 32),
                    )
                  : null,
          bottomNavigationBar: isDesktop ? null : _buildBottomNavigationBar(),
        );
      },
    );
  }

  // ─── Desktop Layout ──────────────────────────────────────────────────────────

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        _buildSidebar(),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              _buildDesktopAppBar(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopAppBar() {
    final colors = AppTheme.of(context);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Text(
            AppSettings.instance.tr(_navItems[_selectedIndex].label),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          if (_selectedIndex == 0 || _selectedIndex == 1)
            ElevatedButton.icon(
              onPressed: _openNewTransaction,
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppSettings.instance.tr('New Transaction')),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          const SizedBox(width: 12),
          const LanguageSwitcherButton(),
          const SizedBox(width: 8),
          const ThemeSwitcherButton(),
          const SizedBox(width: 8),
          _buildNotificationBellIcon(),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuCp9kis6KS2n2Ed5PQAiFLuUf0ZIvpxyE5S_J2al4SG_7bMGeCKmEJW3zAA41W7mwaSbiND8odmjtfqdez2y09UuqA8wQRNUq1LMcXjKiewS8AgQMaenW7pFat3wkGNfzT1mGo9F6vWtS23iuAlSi3d6pLI8-9_ieLDY3ZS3sKidSquQl0sUnnB31cWJWLGyaZ7lAtYT77U4VgDWNpGC66gVPUeeaGZoQF7MPGaYzQ1GOGz9Ivi5v-v',
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final colors = AppTheme.of(context);
    final sidebarBg = colors.isDark ? const Color(0xFF1E293B) : const Color(0xFF041627);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: _sidebarExpanded ? 260 : 72,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: colors.isDark ? Border(right: BorderSide(color: colors.border)) : null,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo area
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SpendHikeIcon(
                  size: 36,
                  walletColor: Colors.white,
                  arrowColor: Color(0xFF356EE7),
                ),
                if (_sidebarExpanded) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'SpendHike',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    _sidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Group Search (only when expanded)
          if (_sidebarExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: AppSettings.instance.tr('Search groups...'),
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                  filled: true,
                  fillColor: Colors.white10,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],

          // Nav Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;
                final localizedLabel = AppSettings.instance.tr(item.label);
                return Tooltip(
                  message: _sidebarExpanded ? '' : localizedLabel,
                  child: InkWell(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      padding: EdgeInsets.symmetric(
                          horizontal: _sidebarExpanded ? 16 : 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF356EE7) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: _sidebarExpanded ? MainAxisSize.max : MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected ? Colors.white : Colors.white60,
                            size: 22,
                          ),
                          if (_sidebarExpanded) ...[
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                localizedLabel,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Export Buttons
          if (_sidebarExpanded) ...[
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppSettings.instance.tr('EXPORT REPORT'),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white38,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSidebarExportButton(
                    icon: Icons.picture_as_pdf,
                    label: AppSettings.instance.tr('Export as PDF'),
                    color: const Color(0xFFef4444),
                    onPressed: () => _showExportSnackBar('PDF'),
                  ),
                  const SizedBox(height: 8),
                  _buildSidebarExportButton(
                    icon: Icons.table_view,
                    label: AppSettings.instance.tr('Export as Excel'),
                    color: const Color(0xFF10b981),
                    onPressed: () => _showExportSnackBar('Excel'),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFef4444), size: 22),
                    tooltip: AppSettings.instance.tr('Export as PDF'),
                    onPressed: () => _showExportSnackBar('PDF'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.table_view, color: Color(0xFF10b981), size: 22),
                    tooltip: AppSettings.instance.tr('Export as Excel'),
                    onPressed: () => _showExportSnackBar('Excel'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSidebarExportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 16),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  // ─── Mobile Layout ────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    final colors = AppTheme.of(context);
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: colors.border, height: 1.0),
      ),
      title: const SpendHikeLogo(
        iconSize: 32,
        fontSize: 20,
      ),
      actions: [
        const LanguageSwitcherButton(),
        const ThemeSwitcherButton(),
        _buildNotificationBellIcon(),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildNotificationBellIcon() {
    final colors = AppTheme.of(context);
    return FutureBuilder<int>(
      future: ApiService.getPendingInvitationCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: colors.textPrimary),
              onPressed: _openNotificationsSheet,
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFBA1A1A),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMobileBody() {
    return _buildBody();
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return const DashboardScreen();
      case 1: return const LabourMainScreen();
      case 2: return const GroupsScreen();
      case 3: return const ReportsScreen();
      case 4: return const ProfileScreen();
      default: return const DashboardScreen();
    }
  }

  Widget _buildBottomNavigationBar() {
    final colors = AppTheme.of(context);
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      backgroundColor: colors.surface,
      indicatorColor: colors.primary,
      elevation: 8,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard, color: Colors.white),
          label: AppSettings.instance.tr('Dashboard'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.engineering_outlined),
          selectedIcon: const Icon(Icons.engineering, color: Colors.white),
          label: AppSettings.instance.tr('Labour'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.grid_view_outlined),
          selectedIcon: const Icon(Icons.grid_view, color: Colors.white),
          label: AppSettings.instance.tr('Groups'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.analytics_outlined),
          selectedIcon: const Icon(Icons.analytics, color: Colors.white),
          label: AppSettings.instance.tr('Reports'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person, color: Colors.white),
          label: AppSettings.instance.tr('Profile'),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  void _openNotificationsSheet() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const NotificationsSheet(),
    );
    if (result == true) {
      setState(() {});
    }
  }

  void _openNewTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewTransactionScreen()),
    );
    if (result == true) {
      setState(() {});
    }
  }

  void _showExportSnackBar(String format) {
    final colors = AppTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              format == 'PDF' ? Icons.picture_as_pdf : Icons.table_view,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(AppSettings.instance.isHindi ? '$format के रूप में रिपोर्ट निर्यात कर रहे हैं...' : 'Exporting report as $format...'),
          ],
        ),
        backgroundColor: colors.isDark ? colors.surfaceSubtle : const Color(0xFF041627),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
