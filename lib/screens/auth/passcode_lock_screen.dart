import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../../services/api_service.dart';
import '../../services/passcode_service.dart';
import '../../widgets/spend_hike_logo.dart';
import '../navigation/main_navigation.dart';
import 'create_passcode_screen.dart';
import 'login_screen.dart';

class PasscodeLockScreen extends StatefulWidget {
  const PasscodeLockScreen({super.key});

  @override
  State<PasscodeLockScreen> createState() => _PasscodeLockScreenState();
}

class _PasscodeLockScreenState extends State<PasscodeLockScreen> {
  int _pinLength = 4;
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadPasscodeConfig();
  }

  Future<void> _loadPasscodeConfig() async {
    final length = await PasscodeService.getPasscodeLength();
    final user = ApiService.currentUser;
    setState(() {
      _pinLength = length;
      _userName = user?.name ?? '';
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onVerifyPasscode(String pin) async {
    if (pin.length != _pinLength) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isValid = await PasscodeService.verifyPasscode(pin);

    if (!mounted) return;

    if (isValid) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Incorrect passcode. Please try again.';
      });
      _pinController.clear();
      _focusNode.requestFocus();
    }
  }

  void _showForgotPasscodeDialog() {
    final passwordController = TextEditingController();
    bool isVerifyingPassword = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0453CD).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.security, color: Color(0xFF0453CD)),
                  ),
                  const SizedBox(width: 12),
                  const Text('Reset Passcode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'For your security, please enter your account password to verify your identity before setting a new passcode.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Account Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        dialogError!,
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isVerifyingPassword ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isVerifyingPassword
                      ? null
                      : () async {
                          final pwd = passwordController.text.trim();
                          if (pwd.isEmpty) {
                            setDialogState(() {
                              dialogError = 'Password is required';
                            });
                            return;
                          }

                          setDialogState(() {
                            isVerifyingPassword = true;
                            dialogError = null;
                          });

                          final res = await PasscodeService.verifyPasswordForReset(pwd);

                          if (!dialogContext.mounted) return;

                          if (res['success'] == true) {
                            Navigator.pop(dialogContext);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreatePasscodeScreen(isResetFlow: true),
                              ),
                            );
                          } else {
                            setDialogState(() {
                              isVerifyingPassword = false;
                              dialogError = res['message'] ?? 'Incorrect password. Please try again.';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0453CD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isVerifyingPassword
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Verify Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultPinTheme = PinTheme(
      width: _pinLength == 6 ? 48 : 58,
      height: 60,
      textStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 2.5,
        ),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(
          color: const Color(0xFFEF4444),
          width: 2,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SpendHikeLogo(
                    isVertical: false,
                    iconSize: 38,
                    fontSize: 24,
                  ),

                  const SizedBox(height: 36),

                  // Avatar / Welcome User
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    _userName.isNotEmpty ? 'Welcome Back, $_userName' : 'App Locked',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Enter your passcode to unlock SpendHike',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 36),

                  Pinput(
                    length: _pinLength,
                    controller: _pinController,
                    focusNode: _focusNode,
                    autofocus: true,
                    obscureText: true,
                    obscuringCharacter: '●',
                    defaultPinTheme: _errorMessage != null ? errorPinTheme : defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    onChanged: (val) {
                      if (_errorMessage != null) {
                        setState(() {
                          _errorMessage = null;
                        });
                      }
                    },
                    onCompleted: (pin) => _onVerifyPasscode(pin),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],


                  if (_isLoading) ...[
                    const SizedBox(height: 20),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // Actions: Forgot Passcode & Logout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _showForgotPasscodeDialog,
                        icon: const Icon(Icons.help_outline, size: 18),
                        label: const Text(
                          'Forgot Passcode?',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout, size: 18, color: Color(0xFFEF4444)),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
