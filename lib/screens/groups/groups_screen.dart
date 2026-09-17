import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';
import '../../services/app_settings.dart';
import '../../services/data_sync_notifier.dart';
import '../../services/share_service.dart';
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
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.group_add, color: Color(0xFF0453CD)),
            SizedBox(width: 12),
            Text('Create New Group Ledger',style: TextStyle(fontSize:16,fontWeight:FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Group / Site Name',
            hintText: 'e.g. Site B - Commercia  l Plaza',
            prefixIcon: const Icon(Icons.apartment, color: Color(0xFF0453CD)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF74777D))),
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
              backgroundColor: const Color(0xFF0453CD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinGroupDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.group_add, color: Color(0xFF0453CD)),
            SizedBox(width: 12),
            Text('Join Group Ledger', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the Invitation Code shared by your project admin (e.g. INV-A1B2C3):',
              style: TextStyle(fontSize: 13, color: Color(0xFF44474C)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Invitation Code',
                hintText: 'e.g. INV-98A7B6',
                prefixIcon: const Icon(Icons.key, color: Color(0xFF0453CD)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF74777D))),
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
                      content: Text(res['message'] ?? 'Successfully joined project group!'),
                      backgroundColor: res['success'] == true ? const Color(0xFF10b981) : const Color(0xFFBA1A1A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0453CD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Join Group'),
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
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF041627),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _showJoinGroupDialog,
                                icon: const Icon(Icons.group_add_outlined, size: 18),
                                label: const Text('Join Group'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0453CD),
                                  side: const BorderSide(color: Color(0xFF0453CD)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: _showCreateGroupDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('New Group'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF0453CD),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC4C6CD)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Search groups, projects or ledgers...',
                            hintStyle: const TextStyle(color: Color(0xFF74777D)),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF74777D)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Color(0xFF74777D)),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
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
                                const Text(
                                  'No Project Groups Found',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF041627)),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Create your first group ledger to track site expenses.',
                                  style: TextStyle(
                                      fontSize: 14, color: Color(0xFF74777D)),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _showCreateGroupDialog,
                                  icon: const Icon(Icons.add, size: 12),
                                  label: const Text('Create First Group'),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                  color: const Color(0xFF0453CD),
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
                    color: const Color(0xFFDAE2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.construction, color: Color(0xFF0453CD)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5EEFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    g.status,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0453CD)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Title + transactions ──────────────────────────────────────────
            Text(
              g.title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF041627)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              g.transactionsCount,
              style: const TextStyle(fontSize: 13, color: Color(0xFF44474C)),
            ),

            const SizedBox(height: 12),

            // ── Balance ──────────────────────────────────────────────────────
            const Text(
              'REMAINING BALANCE',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF74777D),
                  letterSpacing: 1.2),
            ),
            const SizedBox(height: 2),
            Text(
              g.balance,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0453CD)),
            ),

            const SizedBox(height: 14),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 12),

            // ── Members row ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAvatarStack(g.members
                    .map((m) => _MemberData(m.name, m.initials, const Color(0xFF0453CD)))
                    .toList()),
                TextButton.icon(
                  onPressed: () => _showEditMembersSheet(context, g),
                  icon: const Icon(Icons.edit, size: 14, color: Color(0xFF0453CD)),
                  label: const Text(
                    'Edit',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0453CD)),
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

  Widget _buildAvatarStack(List<_MemberData> members) {
    const avatarSize = 30.0;
    const overlap = 10.0;
    final visible = members.take(4).toList();
    final extraCount = members.length - 4;

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
                  border: Border.all(color: Colors.white, width: 2),
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
                  border: Border.all(color: Colors.white, width: 2),
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
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.group, color: Color(0xFF0453CD)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.groupName,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF041627)),
                    ),
                    Text(
                      '${_members.length} member${_members.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF44474C)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF44474C)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE2E8F0)),
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
              const Text(
                'Add Registered Member',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF44474C)),
              ),
              const SizedBox(height: 6),

              if (_selectedUser != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5EEFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0453CD)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF10b981), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Selected: ${_selectedUser!['name']} (${_selectedUser!['email']})',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0453CD)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedUser = null;
                            _nameController.clear();
                          });
                        },
                        child: const Icon(Icons.cancel, size: 18, color: Color(0xFF74777D)),
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
                      decoration: InputDecoration(
                        hintText: 'Mobile No, Email ID or Name...',
                        prefixIcon:
                            const Icon(Icons.person_search, color: Color(0xFF0453CD)),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Color(0xFF0453CD)),
                                ),
                              )
                            : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: Color(0xFF0453CD), width: 2),
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
                      border: Border.all(color: const Color(0xFFC4C6CD)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        items: const [
                          DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                          DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                          DropdownMenuItem(value: 'Editor', child: Text('Editor')),
                          DropdownMenuItem(value: 'Viewer', child: Text('Viewer')),
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
                      backgroundColor: const Color(0xFF0453CD),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0453CD).withOpacity(0.3)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
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
                          backgroundColor: const Color(0xFFE5EEFF),
                          child: Text(
                            initials,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0453CD)),
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFF44474C))),
                        trailing: const Icon(Icons.check_circle_outline, size: 20, color: Color(0xFF0453CD)),
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
                        'Members updated for ${widget.groupName}'),
                    backgroundColor: const Color(0xFF10b981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF041627),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(int index) {
    final m = _members[index];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF041627)),
            ),
          ),

          // Edit button
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: Color(0xFF0453CD)),
            tooltip: 'Edit ${m.name}',
            onPressed: () => _showEditMemberDialog(index),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEFF4FF),
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
            icon: const Icon(Icons.delete_outline,
                size: 18, color: Color(0xFFBA1A1A)),
            tooltip: 'Remove ${m.name}',
            onPressed: () async {
              final target = m.id.isNotEmpty ? m.id : (m.email.isNotEmpty ? m.email : m.name);
              final removedName = m.name;
              setState(() => _members.removeAt(index));
              final res = await ApiService.removeGroupMember(widget.groupId, target);
              if (!mounted) return;
              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$removedName removed from group successfully'),
                    backgroundColor: const Color(0xFF10b981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFFDAD6),
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
        const SnackBar(
          content: Text('Please enter Mobile Number, Email ID or Name'),
          backgroundColor: Color(0xFFBA1A1A),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.mark_email_read, color: Color(0xFF10b981), size: 28),
            SizedBox(width: 10),
            Text('Invitation Created'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invitation successfully sent to $recipient.',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF041627)),
            ),
            const SizedBox(height: 8),
            const Text(
              'If the user is already on SpendHike, a notification has been sent to their account. If not, share this link via WhatsApp or Email:',
              style: TextStyle(fontSize: 13, color: Color(0xFF44474C)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC4C6CD)),
              ),
              child: SelectableText(
                shareMsg,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF041627)),
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
            label: const Text('Share WhatsApp', style: TextStyle(color: Color(0xFF25D366))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ShareService.shareToEmail(context, recipient, 'SpendHike Group Invitation', shareMsg);
            },
            icon: const Icon(Icons.email, size: 18),
            label: const Text('Share Email'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0453CD),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditMemberDialog(int index) {
    final editController = TextEditingController(text: _members[index].name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFF0453CD)),
            SizedBox(width: 10),
            Text('Edit Member'),
          ],
        ),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Member Name',
            prefixIcon: const Icon(Icons.person, color: Color(0xFF0453CD)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0453CD), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF74777D))),
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
              backgroundColor: const Color(0xFF0453CD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
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


