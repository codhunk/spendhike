import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';
import '../../services/app_settings.dart';
import '../../services/data_sync_notifier.dart';
import '../../services/share_service.dart';
import '../../config/app_theme.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late Future<List<GroupModel>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    DataSyncNotifier.instance.addListener(_refresh);
    _refresh();
  }

  void _refresh() {
    if (mounted) {
      setState(() {
        _groupsFuture = ApiService.getGroups(searchQuery: _searchQuery);
      });
    }
  }

  String _tr(String text) => AppSettings.instance.tr(text);

  void _showCreateGroupDialog() {
    final colors = AppTheme.of(context);
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.group_add, color: colors.primary),
            const SizedBox(width: 12),
            Text(_tr('Create New Group Ledger'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
          ],
        ),
        content: TextField(
          controller: titleController,
          autofocus: true,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: _tr('Group / Site Name'),
            labelStyle: TextStyle(color: colors.textSecondary),
            hintText: AppSettings.instance.isHindi ? 'उदा. साइट B - कमर्शियल प्लाजा' : 'e.g. Site B - Commercial Plaza',
            hintStyle: TextStyle(color: colors.textMuted),
            prefixIcon: Icon(Icons.apartment, color: colors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.primary, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_tr('Cancel'), style: TextStyle(color: colors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                Navigator.pop(ctx);
                await ApiService.createGroup(title);
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(_tr('Create')),
          ),
        ],
      ),
    );
  }

  void _showJoinGroupDialog() {
    final colors = AppTheme.of(context);
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.group_add, color: colors.primary),
            const SizedBox(width: 12),
            Text(_tr('Join Group Ledger'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr('Enter the Invitation Code shared by your project admin (e.g. INV-A1B2C3):'),
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: _tr('Invitation Code'),
                labelStyle: TextStyle(color: colors.textSecondary),
                hintText: 'e.g. INV-98A7B6',
                hintStyle: TextStyle(color: colors.textMuted),
                prefixIcon: Icon(Icons.key, color: colors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.primary, width: 2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_tr('Cancel'), style: TextStyle(color: colors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(ctx);
                final res = await ApiService.acceptInvitation(code);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? _tr('Successfully joined project group!')),
                      backgroundColor: res['success'] == true ? colors.success : colors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(_tr('Join Group')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    DataSyncNotifier.instance.removeListener(_refresh);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, child) {
        return Stack(
      children: [
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: const Color(0xFF0453CD).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: const Color(0xFF041627).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
          ),
        ),
        FutureBuilder<List<GroupModel>>(
          future: _groupsFuture,
          builder: (context, snapshot) {
            final groups = snapshot.data ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 120),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          Text(
                            _tr('Project Ledgers'),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.of(context).textPrimary,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _showJoinGroupDialog,
                                icon: const Icon(Icons.group_add_outlined, size: 18),
                                label: Text(_tr('Join Group')),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.of(context).primary,
                                  side: BorderSide(color: AppTheme.of(context).primary),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: _showCreateGroupDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(_tr('New Group')),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.of(context).primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.of(context).surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.of(context).border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(AppTheme.of(context).isDark ? 0.2 : 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: TextStyle(color: AppTheme.of(context).textPrimary),
                          decoration: InputDecoration(
                            hintText: _tr('Search groups, projects or ledgers...'),
                            hintStyle: TextStyle(color: AppTheme.of(context).textMuted),
                            prefixIcon: Icon(Icons.search, color: AppTheme.of(context).textMuted),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: AppTheme.of(context).textMuted),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (snapshot.connectionState == ConnectionState.waiting)
                        const SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF0453CD)),
                          ),
                        )
                      else if (groups.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Column(
                              children: [
                                const Icon(Icons.folder_open,
                                    size: 64, color: Color(0xFF74777D)),
                                const SizedBox(height: 16),
                                Text(
                                  _tr('No Project Groups Found'),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF041627)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _tr('Create your first group ledger to track site expenses.'),
                                  style: const TextStyle(
                                      fontSize: 14, color: Color(0xFF74777D)),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _showCreateGroupDialog,
                                  icon: const Icon(Icons.add, size: 12),
                                  label: Text(_tr('Create First Group')),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0453CD),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isDesktop = constraints.maxWidth > 600;
                            final cardWidth = isDesktop
                                ? (constraints.maxWidth - 16) / 2
                                : constraints.maxWidth;
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: groups
                                  .map((g) => SizedBox(
                                        width: cardWidth,
                                        child: _buildGroupCard(context, g),
                                      ))
                                  .toList(),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  },
);
  }

  // ─── Group Card ───────────────────────────────────────────────────────────────

  Widget _buildGroupCard(BuildContext context, GroupModel g) {
    final colors = AppTheme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => GroupDetailScreen(
                    groupName: g.title,
                    balance: g.balance,
                  )),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: colors.isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (g.isPrimary)
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: Container(
                  width: 4,
                  color: colors.primary,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // ── Top row: icon + status badge ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.construction, color: colors.primary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _tr(g.status),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Title + transactions ──────────────────────────────────────────
            Text(
              g.title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              _tr(g.transactionsCount),
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),

            const SizedBox(height: 12),

            // ── Balance ──────────────────────────────────────────────────────
            Text(
              _tr('REMAINING BALANCE'),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textMuted,
                  letterSpacing: 1.2),
            ),
            const SizedBox(height: 2),
            Text(
              g.balance,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: colors.primary),
            ),

            const SizedBox(height: 14),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 12),

            // ── Members row ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAvatarStack(context, g.members
                    .map((m) => _MemberData(m.name, m.initials, colors.primary))
                    .toList()),
                TextButton.icon(
                  onPressed: () => _showEditMembersSheet(context, g),
                  icon: Icon(Icons.edit, size: 14, color: colors.primary),
                  label: Text(
                    _tr('Edit'),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.primary),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  ),
),
);
}

  // ─── Overlapping Avatar Stack ─────────────────────────────────────────────────

  Widget _buildAvatarStack(BuildContext context, List<_MemberData> members) {
    const avatarSize = 30.0;
    const overlap = 10.0;
    final visible = members.take(4).toList();
    final extraCount = members.length - 4;
    final surfaceColor = AppTheme.of(context).surface;

    return SizedBox(
      height: avatarSize,
      width: avatarSize + (visible.length - 1) * (avatarSize - overlap) +
          (extraCount > 0 ? avatarSize - overlap : 0),
      child: Stack(
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * (avatarSize - overlap),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: visible[i].color,
                  shape: BoxShape.circle,
                  border: Border.all(color: surfaceColor, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  visible[i].initials,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          if (extraCount > 0)
            Positioned(
              left: visible.length * (avatarSize - overlap),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF74777D),
                  shape: BoxShape.circle,
                  border: Border.all(color: surfaceColor, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$extraCount',
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Edit Members Bottom Sheet ────────────────────────────────────────────────

  void _showEditMembersSheet(BuildContext context, GroupModel g) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _EditMembersSheet(groupId: g.id, groupName: g.title, members: g.members),
    );
    setState(() {});
  }
}

// ─── Edit Members Bottom Sheet Widget ────────────────────────────────────────

class _EditMembersSheet extends StatefulWidget {
  final String groupId;
  final String groupName;
  final List<MemberModel> members;
  const _EditMembersSheet({
    required this.groupId,
    required this.groupName,
    required this.members,
  });

  @override
  State<_EditMembersSheet> createState() => _EditMembersSheetState();
}

class _EditMembersSheetState extends State<_EditMembersSheet> {
  late List<_MemberData> _members;
  final _nameController = TextEditingController();
  String _selectedRole = 'Editor';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Map<String, dynamic>? _selectedUser;

  @override
  void initState() {
    super.initState();
    _members = widget.members
        .map((m) => _MemberData(m.name, m.initials, const Color(0xFF0453CD)))
        .toList();
    _nameController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() async {
    final text = _nameController.text.trim();
    if (text.length < 2) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await ApiService.searchUsers(text);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onSearchChanged);
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.group, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.groupName,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary),
                    ),
                    Text(
                      '${_members.length} member${_members.length != 1 ? 's' : ''}',
                      style: TextStyle(
                          fontSize: 13, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: colors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: colors.border),
          const SizedBox(height: 16),

          // Members list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) => _buildMemberTile(i),
            ),
          ),

          const SizedBox(height: 16),

          // Add member field by Email ID or Name
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppSettings.instance.tr('Add Registered Member'),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary),
              ),
              const SizedBox(height: 6),

              if (_selectedUser != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.primary),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: colors.success, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${AppSettings.instance.tr('Selected')}: ${_selectedUser!['name']} (${_selectedUser!['email']})',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.primary),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedUser = null;
                            _nameController.clear();
                          });
                        },
                        child: Icon(Icons.cancel, size: 18, color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: AppSettings.instance.tr('Mobile No, Email ID or Name...'),
                        hintStyle: TextStyle(color: colors.textMuted),
                        prefixIcon:
                            Icon(Icons.person_search, color: colors.primary),
                        suffixIcon: _isSearching
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: colors.primary),
                                ),
                              )
                            : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colors.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colors.border)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: colors.primary, width: 2),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: colors.surface,
                        value: _selectedRole,
                        items: [
                          DropdownMenuItem(value: 'Admin', child: Text(AppSettings.instance.tr('Admin'), style: TextStyle(color: colors.textPrimary))),
                          DropdownMenuItem(value: 'Manager', child: Text(AppSettings.instance.tr('Manager'), style: TextStyle(color: colors.textPrimary))),
                          DropdownMenuItem(value: 'Editor', child: Text(AppSettings.instance.tr('Editor'), style: TextStyle(color: colors.textPrimary))),
                          DropdownMenuItem(value: 'Viewer', child: Text(AppSettings.instance.tr('Viewer'), style: TextStyle(color: colors.textPrimary))),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedRole = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addMember,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),

              if (_searchResults.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: colors.isDark ? 0.3 : 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: colors.border),
                    itemBuilder: (context, i) {
                      final user = _searchResults[i];
                      final name = user['name'] ?? '';
                      final email = user['email'] ?? '';
                      final parts = name.toString().split(' ');
                      final initials = parts.length >= 2
                          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                          : name.toString().substring(0, name.toString().length >= 2 ? 2 : 1).toUpperCase();

                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: colors.primary.withValues(alpha: 0.15),
                          child: Text(
                            initials,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.primary),
                          ),
                        ),
                        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.textPrimary)),
                        subtitle: Text(email, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                        trailing: Icon(Icons.check_circle_outline, size: 20, color: colors.primary),
                        onTap: () {
                          setState(() {
                            _selectedUser = user;
                            _nameController.text = email;
                            _searchResults = [];
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${AppSettings.instance.tr('Members updated for')} ${widget.groupName}'),
                    backgroundColor: colors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(AppSettings.instance.tr('Save Changes'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(int index) {
    final colors = AppTheme.of(context);
    final m = _members[index];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: m.color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              m.initials,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Text(
              m.name,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary),
            ),
          ),

          // Edit button
          IconButton(
            icon: Icon(Icons.edit_outlined,
                size: 18, color: colors.primary),
            tooltip: '${AppSettings.instance.tr('Edit')} ${m.name}',
            onPressed: () => _showEditMemberDialog(index),
            style: IconButton.styleFrom(
              backgroundColor: colors.primary.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 6),

          // Remove button
          IconButton(
            icon: Icon(Icons.delete_outline,
                size: 18, color: colors.error),
            tooltip: '${AppSettings.instance.tr('Remove')} ${m.name}',
            onPressed: () async {
              final target = m.id.isNotEmpty ? m.id : (m.email.isNotEmpty ? m.email : m.name);
              final removedName = m.name;
              setState(() => _members.removeAt(index));
              final res = await ApiService.removeGroupMember(widget.groupId, target);
              if (!mounted) return;
              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$removedName ${AppSettings.instance.tr('removed from group successfully')}'),
                    backgroundColor: colors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: colors.error.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(32, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  void _addMember() async {
    final query = _nameController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppSettings.instance.tr('Please enter Mobile Number, Email ID or Name')),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final res = await ApiService.addMemberToGroup(widget.groupId, query, _selectedRole);
    if (!mounted) return;

    if (res['success'] == true) {
      DataSyncNotifier.instance.notifyDataChanged();
      _nameController.clear();
      setState(() {
        _selectedUser = null;
        _searchResults = [];
      });

      final invRes = await ApiService.sendGroupInvitation(widget.groupId, query, _selectedRole);
      final inv = invRes['invitation'] ?? {};
      final shareMsg = inv['shareMessage'] ?? 'Join my project group on SpendHike!';

      _showShareInvitationDialog(query, shareMsg, inv['shareLink'] ?? '');
    } else {
      final invRes = await ApiService.sendGroupInvitation(widget.groupId, query, _selectedRole);
      if (!mounted) return;

      if (invRes['success'] == true) {
        DataSyncNotifier.instance.notifyDataChanged();
        final inv = invRes['invitation'] ?? {};
        final shareMsg = inv['shareMessage'] ?? 'Join my project group on SpendHike!';
        _nameController.clear();
        setState(() {
          _selectedUser = null;
          _searchResults = [];
        });

        _showShareInvitationDialog(query, shareMsg, inv['shareLink'] ?? '');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? invRes['message'] ?? 'Failed to send invitation'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showShareInvitationDialog(String recipient, String shareMsg, String shareLink) {
    final colors = AppTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.mark_email_read, color: colors.success, size: 28),
            const SizedBox(width: 10),
            Text(AppSettings.instance.tr('Invitation Created'), style: TextStyle(color: colors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppSettings.instance.tr('Invitation successfully sent to')} $recipient.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              AppSettings.instance.tr('If the user is already on SpendHike, a notification has been sent to their account. If not, share this link via WhatsApp or Email:'),
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: SelectableText(
                shareMsg,
                style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: colors.textPrimary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ShareService.shareToWhatsApp(context, shareMsg, recipient);
            },
            icon: const Icon(Icons.chat_bubble, color: Color(0xFF25D366)),
            label: Text(AppSettings.instance.tr('Share WhatsApp'), style: const TextStyle(color: Color(0xFF25D366))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ShareService.shareToEmail(context, recipient, 'SpendHike Group Invitation', shareMsg);
            },
            icon: const Icon(Icons.email, size: 18),
            label: Text(AppSettings.instance.tr('Share Email')),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditMemberDialog(int index) {
    final colors = AppTheme.of(context);
    final editController = TextEditingController(text: _members[index].name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: colors.primary),
            const SizedBox(width: 10),
            Text(AppSettings.instance.tr('Edit Member'), style: TextStyle(color: colors.textPrimary)),
          ],
        ),
        content: TextField(
          controller: editController,
          autofocus: true,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: AppSettings.instance.tr('Member Name'),
            labelStyle: TextStyle(color: colors.textSecondary),
            prefixIcon: Icon(Icons.person, color: colors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppSettings.instance.tr('Cancel'), style: TextStyle(color: colors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = editController.text.trim();
              if (newName.isNotEmpty) {
                final parts = newName.split(' ');
                final initials = parts.length >= 2
                    ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                    : newName.substring(0, newName.length >= 2 ? 2 : 1).toUpperCase();
                setState(() {
                  _members[index] =
                      _MemberData(newName, initials, _members[index].color);
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(AppSettings.instance.tr('Save')),
          ),
        ],
      ),
    );
  }
}

// ─── Data Models ──────────────────────────────────────────────────────────────

class _MemberData {
  final String id;
  final String name;
  final String email;
  final String initials;
  final Color color;

  const _MemberData(
    this.name,
    this.initials,
    this.color, {
    this.id = '',
    this.email = '',
  });
}


