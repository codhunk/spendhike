import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../services/app_settings.dart';
import '../services/data_sync_notifier.dart';

class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  late Future<List<InvitationModel>> _invitationsFuture;

  String _tr(String key) => AppSettings.instance.tr(key);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _invitationsFuture = ApiService.getInvitations();
    });
  }

  void _showEnterCodeDialog(BuildContext context) {
    final colors = AppTheme.of(context);
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.key, color: colors.primary),
            const SizedBox(width: 10),
            Text(_tr('Join with Invite Code'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary)),
          ],
        ),
        content: TextField(
          controller: codeController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            labelText: _tr('Invitation Code'),
            labelStyle: TextStyle(color: colors.textSecondary),
            hintText: _tr('e.g. INV-98A7B6'),
            hintStyle: TextStyle(color: colors.textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
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
                  _refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] != null ? _tr(res['message']) : _tr('Group joined successfully!')),
                      backgroundColor: res['success'] == true ? const Color(0xFF10b981) : const Color(0xFFBA1A1A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(_tr('Accept & Join')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final colors = AppTheme.of(context);
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.notifications_active, color: colors.primary, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _tr('Notifications & Invitations'),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showEnterCodeDialog(context),
                        icon: Icon(Icons.key, size: 14, color: colors.primary),
                        label: Text(_tr('Code'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: colors.textSecondary, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              Divider(height: 24, color: colors.border),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                child: FutureBuilder<List<InvitationModel>>(
                  future: _invitationsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        height: 120,
                        child: Center(
                          child: CircularProgressIndicator(color: colors.primary),
                        ),
                      );
                    }

                    final invitations = snapshot.data ?? [];

                    if (invitations.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mark_email_read_outlined, size: 40, color: colors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              _tr('No Pending Group Invitations'),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _tr('When a project admin invites you by Email or WhatsApp, your invitation will appear here to Accept.'),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: invitations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final inv = invitations[index];
                        return _buildInvitationCard(inv);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvitationCard(InvitationModel inv) {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.group_add, color: colors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.groupName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_tr('Invited by')} ${inv.invitedBy} ${_tr('as')} ${_tr(inv.role)}',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final res = await ApiService.rejectInvitation(inv.id);
                    if (mounted) {
                      DataSyncNotifier.instance.notifyDataChanged();
                      _refresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res['message'] != null ? _tr(res['message']) : _tr('Invitation declined')),
                          backgroundColor: const Color(0xFF74777D),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(_tr('Decline')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final res = await ApiService.acceptInvitation(inv.id);
                    if (mounted) {
                      DataSyncNotifier.instance.notifyDataChanged();
                      Navigator.pop(context, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res['message'] != null ? _tr(res['message']) : _tr('Joined project group successfully!')),
                          backgroundColor: const Color(0xFF10b981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(_tr('Accept')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10b981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
