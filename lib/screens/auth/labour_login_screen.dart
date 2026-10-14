import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/app_settings.dart';
import '../../services/passcode_service.dart';
import '../labour/labour_panel_screen.dart';

class LabourLoginScreen extends StatefulWidget {
  const LabourLoginScreen({super.key});

  @override
  State<LabourLoginScreen> createState() => _LabourLoginScreenState();
}

class _LabourLoginScreenState extends State<LabourLoginScreen> {
  // Mode: true = Mobile OTP, false = Email & Password
  bool _isOtpMode = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSendingOtp = false;
  bool _otpSent = false;
  String? _errorMessage;

  // Controllers
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Resend Timer
  int _resendCooldown = 0;
  Timer? _timer;

  String _tr(String text) => AppSettings.instance.tr(text);

  @override
  void dispose() {
    _timer?.cancel();
    _mobileController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _handlePostLogin() async {
    final hasPasscode = await PasscodeService.isPasscodeConfigured();
    if (!mounted) return;

    if (hasPasscode) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LabourPanelScreen()),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LabourPanelScreen()),
        (route) => false,
      );
    }
  }

  // ─── SEND OTP ──────────────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    final mobile = _mobileController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (mobile.length != 10) {
      setState(() => _errorMessage = _tr('Please enter a valid 10-digit mobile number.'));
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });

    final res = await ApiService.sendOtp(mobile);

    if (mounted) setState(() => _isSendingOtp = false);

    if (res['success'] == true) {
      setState(() => _otpSent = true);
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'OTP sent to mobile number.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } else {
      setState(() => _errorMessage = res['message'] ?? 'Failed to send OTP.');
    }
  }

  // ─── VERIFY OTP & LOGIN ────────────────────────────────────────────────────
  Future<void> _verifyOtpAndLogin() async {
    final mobile = _mobileController.text.trim().replaceAll(RegExp(r'\D'), '');
    final otp = _otpController.text.trim();

    if (mobile.length != 10) {
      setState(() => _errorMessage = _tr('Please enter a valid 10-digit mobile number.'));
      return;
    }

    if (otp.length != 6) {
      setState(() => _errorMessage = _tr('Please enter a 6-digit OTP.'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.labourLoginWithOtp(mobile, otp);

    if (mounted) setState(() => _isLoading = false);

    if (res['success'] == true) {
      await _handlePostLogin();
    } else {
      setState(() => _errorMessage = res['message'] ?? 'OTP verification failed.');
    }
  }

  // ─── EMAIL & PASSWORD LOGIN ────────────────────────────────────────────────
  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _errorMessage = _tr('Please enter a valid email address.'));
      return;
    }

    if (password.isEmpty) {
      setState(() => _errorMessage = _tr('Please enter your password.'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.labourLoginWithEmail(email, password);

    if (mounted) setState(() => _isLoading = false);

    if (res['success'] == true) {
      await _handlePostLogin();
    } else {
      setState(() => _errorMessage = res['message'] ?? 'Invalid credentials or inactive account.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          _tr('Labour & Worker Login'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colors.textPrimary),
        ),
        backgroundColor: colors.surface,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Icon / Badge
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, const Color(0xFF0453CD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.engineering, size: 44, color: Colors.white),
                ),
                const SizedBox(height: 18),

                Text(
                  _tr('Labour Portal Login'),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  _tr('Sign in to mark daily attendance, view dihadi earnings, and check payment records.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
                const SizedBox(height: 24),

                // Auth Mode Toggle (Option A vs Option B)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            _isOtpMode = true;
                            _errorMessage = null;
                          }),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isOtpMode ? colors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                _tr('Mobile + OTP'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _isOtpMode ? Colors.white : colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            _isOtpMode = false;
                            _errorMessage = null;
                          }),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isOtpMode ? colors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                _tr('Email + Password'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: !_isOtpMode ? Colors.white : colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Error Banner
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(fontSize: 13, color: Colors.red.shade900, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // ─── OPTION A: MOBILE + OTP ─────────────────────────────────
                if (_isOtpMode) ...[
                  // Mobile Input Field
                  TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    enabled: !_otpSent,
                    decoration: InputDecoration(
                      labelText: _tr('Registered Mobile Number'),
                      prefixText: '+91 ',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      counterText: '',
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!_otpSent) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSendingOtp ? null : _sendOtp,
                        child: _isSendingOtp
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                _tr('Send Verification OTP'),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ] else ...[
                    // OTP Input Field
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: _tr('Enter 6-Digit OTP'),
                        hintText: '123456',
                        prefixIcon: const Icon(Icons.lock_clock_outlined),
                        counterText: '',
                        filled: true,
                        fillColor: colors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _verifyOtpAndLogin,
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                _tr('Verify OTP & Enter Labour Panel'),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => setState(() {
                            _otpSent = false;
                            _otpController.clear();
                            _errorMessage = null;
                          }),
                          child: Text(_tr('Change Mobile Number'), style: TextStyle(color: colors.primary)),
                        ),
                        TextButton(
                          onPressed: _resendCooldown > 0 ? null : _sendOtp,
                          child: Text(
                            _resendCooldown > 0 ? '${_tr("Resend in")} ${_resendCooldown}s' : _tr('Resend OTP'),
                            style: TextStyle(color: _resendCooldown > 0 ? colors.textMuted : colors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ]

                // ─── OPTION B: EMAIL + PASSWORD ─────────────────────────────
                else ...[
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: _tr('Registered Email Address'),
                      hintText: 'name@labour.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: _tr('Password'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _loginWithEmail,
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _tr('Sign In to Labour Panel'),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),

                // Note for contractor registration
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _tr('Not registered yet? Your Group Admin or Contractor will register you under your assigned project group.'),
                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
