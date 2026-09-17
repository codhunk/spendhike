import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';
import '../../services/app_settings.dart';
import '../../services/cloudinary_service.dart';
import '../../services/data_sync_notifier.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel _user = UserModel(
    id: '',
    name: 'Jalandhar Raur',
    email: 'jalandhar143184@gmail.com',
    mobile: '+91 98765 43210',
    company: 'Vance Construction Ltd.',
    gst: '27AAACV4123F1Z5',
    address: '402 Financial Plaza, Mumbai',
    avatarUrl: '',
    plan: 'Pro Plan',
    verified: true,
    currency: 'INR (₹)',
    language: 'English (IN)',
    biometricEnabled: true,
    pinEnabled: true,
    darkMode: AppSettings.instance.isDarkMode,
    lastSync: 'Live Connected',
  );

  @override
  void initState() {
    super.initState();
    DataSyncNotifier.instance.addListener(_loadProfileFromApi);
    _loadProfileFromApi();
  }

  @override
  void dispose() {
    DataSyncNotifier.instance.removeListener(_loadProfileFromApi);
    super.dispose();
  }

  Future<void> _loadProfileFromApi() async {
    try {
      final user = await ApiService.getProfile();
      if (mounted) {
        setState(() {
          _user = user;
        });

        // Sync local AppSettings
        if (user.darkMode != AppSettings.instance.isDarkMode) {
          AppSettings.instance.setTheme(user.darkMode);
        }
        if (user.language.toLowerCase().contains('hindi') && !AppSettings.instance.isHindi) {
          AppSettings.instance.setLanguage(AppLanguage.hindi);
        } else if (!user.language.toLowerCase().contains('hindi') && AppSettings.instance.isHindi) {
          AppSettings.instance.setLanguage(AppLanguage.english);
        }
      }
    } catch (e) {
      // Ignore API load error, keep local user
    }
  }

  /// Instant Optimistic UI Update + Async MongoDB Backend Save
  Future<void> _updateProfileField(Map<String, dynamic> updates) async {
    // 1. INSTANT LOCAL STATE UPDATE (0ms delay for UI)
    setState(() {
      _user = _user.copyWith(
        name: updates.containsKey('name') ? updates['name'] as String : null,
        mobile: updates.containsKey('mobile') ? updates['mobile'] as String : null,
        company: updates.containsKey('company') ? updates['company'] as String : null,
        gst: updates.containsKey('gst') ? updates['gst'] as String : null,
        address: updates.containsKey('address') ? updates['address'] as String : null,
        avatarUrl: updates.containsKey('avatarUrl') ? updates['avatarUrl'] as String : null,
        biometricEnabled: updates.containsKey('biometricEnabled') ? updates['biometricEnabled'] as bool : null,
        pinEnabled: updates.containsKey('pinEnabled') ? updates['pinEnabled'] as bool : null,
        darkMode: updates.containsKey('darkMode') ? updates['darkMode'] as bool : null,
        language: updates.containsKey('language') ? updates['language'] as String : null,
      );
    });

    // 2. ASYNC MONGODB SAVE IN BACKGROUND
    final success = await ApiService.updateProfile(updates);
    if (success) {
      final freshUser = ApiService.currentUser;
      if (freshUser != null && mounted) {
        setState(() {
          _user = freshUser;
        });
      }
    }
  }

  String _tr(String text) => AppSettings.instance.tr(text);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(context),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 700) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildCompanyDetails(),
                                  const SizedBox(height: 24),
                                  _buildSecurity(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildAppSettings(),
                                  const SizedBox(height: 24),
                                  _buildDataBackup(),
                                  const SizedBox(height: 24),
                                  _buildLegalSection(),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _buildCompanyDetails(),
                          const SizedBox(height: 24),
                          _buildAppSettings(),
                          const SizedBox(height: 24),
                          _buildSecurity(),
                          const SizedBox(height: 24),
                          _buildDataBackup(),
                          const SizedBox(height: 24),
                          _buildLegalSection(),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                  _buildLogoutButton(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFC4C6CD)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 600;
          return Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: isDesktop ? 128 : 96,
                    height: isDesktop ? 128 : 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0453CD), width: 3),
                    ),
                    child: CircleAvatar(
                      radius: isDesktop ? 60 : 45,
                      backgroundColor: const Color(0xFFEFF4FF),
                      backgroundImage: _user.avatarUrl.isNotEmpty
                          ? NetworkImage(_user.avatarUrl)
                          : null,
                      child: _user.avatarUrl.isEmpty
                          ? Text(
                              _user.name.isNotEmpty
                                  ? _user.name.substring(0, 1).toUpperCase()
                                  : 'J',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0453CD),
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showEditProfilePictureDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0453CD),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: isDesktop ? 24 : 0, height: isDesktop ? 0 : 16),
              Expanded(
                flex: isDesktop ? 1 : 0,
                child: Column(
                  crossAxisAlignment:
                      isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    Text(
                      _user.name.isNotEmpty ? _user.name : 'Jalandhar Raur',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0B1C30),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment:
                          isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.corporate_fare, size: 16, color: Color(0xFF0453CD)),
                        const SizedBox(width: 8),
                        Text(
                          _user.company.isNotEmpty ? _user.company : 'Personal Account',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : const Color(0xFF44474C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
                      children: [
                        _buildChip(
                          _user.email.isNotEmpty ? _user.email : 'Verified Account',
                          const Color(0xFFD3E4FE),
                          const Color(0xFF0453CD),
                        ),
                        _buildChip(
                          _user.plan,
                          const Color(0xFF0453CD),
                          Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 0, height: isDesktop ? 0 : 16),
              OutlinedButton.icon(
                onPressed: () => _showEditProfileDialog(context),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(_tr('Edit Profile')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0453CD),
                  side: const BorderSide(color: Color(0xFFC4C6CD)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
    );
  }

  Widget _buildSettingsGroup(String title, IconData icon, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFC4C6CD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A3C) : const Color(0xFFEFF4FF),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFC4C6CD)),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF0453CD)),
                const SizedBox(width: 12),
                Text(
                  _tr(title),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0B1C30),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white70 : const Color(0xFF44474C)),
      title: Text(
        _tr(title),
        style: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white : const Color(0xFF0B1C30),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : const Color(0xFF44474C),
              ),
            )
          : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: isDark ? Colors.white38 : const Color(0xFF74777D)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildCompanyDetails() {
    return _buildSettingsGroup(
      'Business Details',
      Icons.business_center,
      [
        _buildSettingItem(
          icon: Icons.article_outlined,
          title: 'GST Number',
          subtitle: _user.gst.isNotEmpty ? _user.gst : 'Add GST Identification',
          onTap: () => _showEditSingleFieldDialog('GST Number', 'gst', _user.gst),
        ),
        _buildSettingItem(
          icon: Icons.location_on_outlined,
          title: 'Business Address',
          subtitle: _user.address.isNotEmpty ? _user.address : 'Add Business Address',
          onTap: () => _showEditSingleFieldDialog('Business Address', 'address', _user.address),
        ),
        _buildSettingItem(
          icon: Icons.store_outlined,
          title: 'Company Name',
          subtitle: _user.company.isNotEmpty ? _user.company : 'Add Company Name',
          onTap: () => _showEditSingleFieldDialog('Company Name', 'company', _user.company),
        ),
      ],
    );
  }

  Widget _buildAppSettings() {
    return _buildSettingsGroup(
      'App Settings',
      Icons.settings_applications,
      [
        _buildSettingItem(
          icon: Icons.dark_mode_outlined,
          title: 'Dark Mode',
          trailing: Switch(
            value: AppSettings.instance.isDarkMode,
            onChanged: (val) {
              AppSettings.instance.setTheme(val);
              _updateProfileField({'darkMode': val});
              _showSnackBar(val ? 'Dark Mode Enabled' : 'Light Mode Enabled');
            },
            activeColor: const Color(0xFF0453CD),
          ),
        ),
        _buildSettingItem(
          icon: Icons.translate,
          title: 'Language',
          trailing: Text(
            AppSettings.instance.isHindi ? 'Hindi (हिन्दी)' : 'English (IN)',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0453CD),
            ),
          ),
          onTap: () => _showLanguageDialog(),
        ),
      ],
    );
  }

  Widget _buildSecurity() {
    return _buildSettingsGroup(
      'Security & Privacy',
      Icons.security,
      [
        _buildSettingItem(
          icon: Icons.dialpad,
          title: 'PIN Code Unlock',
          trailing: Switch(
            value: _user.pinEnabled,
            onChanged: (val) {
              if (val) {
                _showPinChangeDialog();
              } else {
                _updateProfileField({'pinEnabled': false});
                _showSnackBar('PIN unlock disabled');
              }
            },
            activeColor: const Color(0xFF0453CD),
          ),
          onTap: () => _showPinChangeDialog(),
        ),
        _buildSettingItem(
          icon: Icons.fingerprint,
          title: 'Biometric Unlock',
          trailing: Switch(
            value: _user.biometricEnabled,
            onChanged: (val) {
              _updateProfileField({'biometricEnabled': val});
              _showSnackBar(val ? 'Biometric unlock enabled' : 'Biometric unlock disabled');
            },
            activeColor: const Color(0xFF0453CD),
          ),
        ),
        _buildSettingItem(
          icon: Icons.lock_reset,
          title: 'Forgot / Change Password',
          onTap: () => _showChangePasswordDialog(),
        ),
      ],
    );
  }

  Widget _buildDataBackup() {
    return _buildSettingsGroup(
      'Data & Backup',
      Icons.cloud_sync,
      [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFD3E4FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud_done, color: Color(0xFF0453CD), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr('Automatic Cloud Sync'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_tr('Sync Status')}: MongoDB Atlas',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF0453CD), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  _loadProfileFromApi();
                  _showSnackBar('Cloud database synced!');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0453CD),
                  side: const BorderSide(color: Color(0xFF0453CD)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(_tr('Sync Status')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegalSection() {
    return _buildSettingsGroup(
      'Legal & Support',
      Icons.gavel_outlined,
      [
        _buildSettingItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () => _showPrivacyPolicyDialog(),
        ),
        _buildSettingItem(
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          onTap: () => _showTermsDialog(),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () async {
          await ApiService.logout();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
        icon: const Icon(Icons.logout),
        label: Text(_tr('Log Out'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF93000A),
          backgroundColor: const Color(0xFFFFDAD6),
          side: const BorderSide(color: Color(0xFFBA1A1A)),
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ─── DIALOGS ─────────────────────────────────────────────────────────────



  void _showEditProfileDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: _user.name);
    final mobileCtrl = TextEditingController(text: _user.mobile);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.edit, color: Color(0xFF0453CD)),
            const SizedBox(width: 10),
            Text(_tr('Personal Details')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: _tr('Name'),
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0453CD)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: mobileCtrl,
              decoration: InputDecoration(
                labelText: _tr('Mobile Number'),
                prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF0453CD)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_tr('Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameCtrl.text.trim();
              final newMobile = mobileCtrl.text.trim();
              Navigator.pop(ctx);
              _updateProfileField({
                'name': newName,
                'mobile': newMobile,
              });
              _showSnackBar(_tr('Updated successfully!'));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0453CD),
              foregroundColor: Colors.white,
            ),
            child: Text(_tr('Save Changes')),
          ),
        ],
      ),
    );
  }

  void _showEditSingleFieldDialog(String title, String fieldKey, String initialVal) {
    final ctrl = TextEditingController(text: initialVal);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${_tr('Edit')} ${_tr(title)}'),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: _tr(title),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_tr('Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final newVal = ctrl.text.trim();
              Navigator.pop(ctx);
              _updateProfileField({fieldKey: newVal});
              _showSnackBar(_tr('Updated successfully!'));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0453CD),
              foregroundColor: Colors.white,
            ),
            child: Text(_tr('Save Changes')),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset, color: Color(0xFF0453CD)),
            const SizedBox(width: 10),
            Text(_tr('Forgot / Change Password')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: _tr('Current Password'),
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0453CD)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: _tr('New Password'),
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0453CD)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: _tr('Confirm New Password'),
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0453CD)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_tr('Cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                _showSnackBar(_tr('Passwords do not match'));
                return;
              }
              Navigator.pop(ctx);
              final res = await ApiService.changePassword(
                oldPasswordCtrl.text.trim(),
                newPasswordCtrl.text.trim(),
              );
              _showSnackBar(res['message'] ?? _tr('Password changed successfully!'));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0453CD),
              foregroundColor: Colors.white,
            ),
            child: Text(_tr('Save Changes')),
          ),
        ],
      ),
    );
  }

  void _showPinChangeDialog() {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.dialpad, color: Color(0xFF0453CD)),
            const SizedBox(width: 10),
            Text(_tr('Set PIN Code')),
          ],
        ),
        content: TextField(
          controller: pinCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: InputDecoration(
            labelText: _tr('Enter 4-digit PIN'),
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0453CD)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_tr('Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final newPin = pinCtrl.text.trim();
              Navigator.pop(ctx);
              _updateProfileField({
                'pinEnabled': true,
                'pinCode': newPin,
              });
              _showSnackBar(_tr('Updated successfully!'));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0453CD),
              foregroundColor: Colors.white,
            ),
            child: Text(_tr('Save Changes')),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_tr('Language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.language, color: Color(0xFF0453CD)),
              title: const Text('English (IN)'),
              trailing: !AppSettings.instance.isHindi
                  ? const Icon(Icons.check, color: Color(0xFF0453CD))
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                AppSettings.instance.setLanguage(AppLanguage.english);
                _updateProfileField({'language': 'English'});
                _showSnackBar('Language set to English');
              },
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Color(0xFF0453CD)),
              title: const Text('Hindi (हिन्दी)'),
              trailing: AppSettings.instance.isHindi
                  ? const Icon(Icons.check, color: Color(0xFF0453CD))
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                AppSettings.instance.setLanguage(AppLanguage.hindi);
                _updateProfileField({'language': 'Hindi'});
                _showSnackBar('भाषा हिन्दी चुनी गई');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_tr('Privacy Policy')),
        content: const SingleChildScrollView(
          child: Text(
            'SpendHike is committed to protecting your business data and privacy.\n\n'
            '1. All financial transactions are stored securely.\n'
            '2. We use AES encryption for local and cloud data transmission.\n'
            '3. Your personal information is never shared with third parties.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_tr('Terms of Service')),
        content: const SingleChildScrollView(
          child: Text(
            'Welcome to SpendHike.\n\n'
            '1. Usage: SpendHike is provided for financial and project accounting.\n'
            '2. Responsibility: Users are responsible for maintaining account credential confidentiality.\n'
            '3. Updates: Software updates are pushed regularly to improve security.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditProfilePictureDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF4FF),
                  child: Icon(Icons.camera_alt, color: Color(0xFF0453CD)),
                ),
                title: const Text('Take Photo from Camera'),
                subtitle: const Text('Use camera to take profile photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleAvatarPicker(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF4FF),
                  child: Icon(Icons.photo_library, color: Color(0xFF0453CD)),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Pick photo from phone gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleAvatarPicker(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAvatarPicker(ImageSource source) async {
    final file = source == ImageSource.camera
        ? await CloudinaryService.pickFromCamera()
        : await CloudinaryService.pickFromGallery();

    if (file == null) return;

    _showSnackBar('Uploading photo to Cloudinary...');
    final url = await CloudinaryService.uploadImage(file, folder: 'spendhike_avatars');
    if (url != null && url.isNotEmpty) {
      await _updateProfileField({'avatarUrl': url});
      _showSnackBar('Profile photo updated successfully!');
    } else {
      _showSnackBar('Failed to upload image to Cloudinary.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10b981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
