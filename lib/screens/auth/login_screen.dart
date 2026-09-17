import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/spend_hike_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isMobileAuthMode = false;
  bool _otpSent = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotEmailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _forgotEmailController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: Row(
        children: [
          // Left side: Login Form
          Expanded(
            flex: isDesktop ? 2 : 1,
            child: Stack(
              children: [
                Positioned(
                  top: -100,
                  left: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      color: const Color(0xFF356EE7).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: size.height / 2 - 150,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDAE2FF).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildLoginForm(),
                          const SizedBox(height: 32),
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right side: Visual (Desktop only)
          if (isDesktop)
            Expanded(
              flex: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuA8_4AX0VEvpmTRaTC1r0RvS0cI-UL0dpg12IJ2DFBW4dGqjtlzr6ExpoBnsN4JASc3OZ_DKy0698Gg5eKg6ZIYhib60O39ZDLf4zD43Y-hh2qs9bPY8Yr2L6-aGmGPKkmeWndGLKe3iZaWyXaIwIojKGQWWjK_xNdF7Mb2i9T7bZkBxskm1fgiGabXaBest359tKpN5xRux4-W_FJVy3B-yFMreEjg_QsoszQypyedcmrxRReDMD0K',
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.3),
                    colorBlendMode: BlendMode.darken,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFFF8F9FF),
                          const Color(0xFFF8F9FF).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 48,
                    left: 48,
                    right: 48,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF356EE7).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Real-time Financial Control',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Track site expenses, manage digital ledgers, and automate financial reports seamlessly.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        SpendHikeLogo(
          isVertical: true,
          iconSize: 64,
          fontSize: 32,
          walletColor: Color(0xFF041627),
          arrowColor: Color(0xFF356EE7),
          textColor: Color(0xFF041627),
        ),
        SizedBox(height: 12),
        Text(
          'Smart Finance Intelligence',
          style: TextStyle(fontSize: 16, color: Color(0xFF44474C)),
        ),
      ],
    );
  }

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC4C6CD)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Selector Tabs
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() {
                      _isMobileAuthMode = false;
                      _errorMessage = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: !_isMobileAuthMode ? const Color(0xFF0453CD) : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Email & Password',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: !_isMobileAuthMode ? const Color(0xFF0453CD) : const Color(0xFF74777F),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() {
                      _isMobileAuthMode = true;
                      _errorMessage = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _isMobileAuthMode ? const Color(0xFF0453CD) : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Mobile & OTP',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _isMobileAuthMode ? const Color(0xFF0453CD) : const Color(0xFF74777F),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBA1A1A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFBA1A1A), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFF93000A), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (!_isMobileAuthMode) ...[
              _buildTextField(
                label: 'EMAIL ADDRESS',
                hint: 'name@company.com',
                icon: Icons.mail_outline,
                controller: _emailController,
                validator: (val) {
                  final clean = (val ?? '').trim();
                  if (clean.isEmpty) return 'Please enter your email address';
                  final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                  if (!emailRegex.hasMatch(clean)) return 'Please enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildTextField(
                label: 'PASSWORD',
                hint: '••••••••',
                icon: Icons.lock_outline,
                isPassword: true,
                controller: _passwordController,
                validator: (val) {
                  final clean = (val ?? '').trim();
                  if (clean.isEmpty) return 'Please enter your password';
                  return null;
                },
                trailingAction: GestureDetector(
                  onTap: _showForgotPasswordDialog,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Color(0xFF0453CD), fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _errorMessage = null);
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _isLoading = true);
                        final res = await ApiService.login(
                          _emailController.text.trim(),
                          _passwordController.text.trim(),
                        );
                        if (mounted) setState(() => _isLoading = false);
                        if (res['success'] == true && mounted) {
                          Navigator.pushReplacementNamed(context, '/main');
                        } else if (mounted) {
                          setState(() {
                            _errorMessage = res['message'] ?? 'Login failed. Please check your credentials.';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0453CD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
              ),
            ] else ...[
              if (!_otpSent) ...[
                _buildTextField(
                  label: 'MOBILE NUMBER',
                  hint: '9876543210',
                  icon: Icons.phone_android,
                  controller: _mobileController,
                  validator: (val) {
                    final clean = (val ?? '').replaceAll(RegExp(r'\D'), '');
                    if (clean.length < 10) return 'Please enter a valid 10-digit mobile number';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _errorMessage = null);
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _isLoading = true);
                          final res = await ApiService.sendOtp(_mobileController.text.trim());
                          if (mounted) setState(() => _isLoading = false);
                          if (res['success'] == true && mounted) {
                            setState(() => _otpSent = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res['message'] ?? 'OTP sent successfully! (Demo OTP: ${res['otp'] ?? '123456'})'),
                                backgroundColor: const Color(0xFF0453CD),
                              ),
                            );
                          } else if (mounted) {
                            setState(() {
                              _errorMessage = res['message'] ?? 'Failed to send OTP.';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0453CD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Send OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            SizedBox(width: 8),
                            Icon(Icons.send, size: 18),
                          ],
                        ),
                ),
              ] else ...[
                Text(
                  'OTP sent to +91 ${_mobileController.text.trim()}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0453CD)),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: '6-DIGIT VERIFICATION OTP',
                  hint: '123456',
                  icon: Icons.lock_clock,
                  controller: _otpController,
                  validator: (val) {
                    final clean = (val ?? '').trim();
                    if (clean.length != 6) return 'Enter the 6-digit code';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'YOUR NAME (FOR NEW ACCOUNT)',
                  hint: 'Full Name',
                  icon: Icons.person_outline,
                  controller: _nameController,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _errorMessage = null);
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _isLoading = true);
                          final res = await ApiService.verifyOtp(
                            _mobileController.text.trim(),
                            _otpController.text.trim(),
                            _nameController.text.trim(),
                          );
                          if (mounted) setState(() => _isLoading = false);
                          if (res['success'] == true && mounted) {
                            Navigator.pushReplacementNamed(context, '/main');
                          } else if (mounted) {
                            setState(() {
                              _errorMessage = res['message'] ?? 'Invalid OTP code.';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Verify OTP & Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            SizedBox(width: 8),
                            Icon(Icons.check_circle_outline, size: 20),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() {
                    _otpSent = false;
                    _errorMessage = null;
                  }),
                  child: const Text('Change Number / Resend OTP', style: TextStyle(color: Color(0xFF0453CD))),
                ),
              ],
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFC4C6CD))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR CONTINUE WITH',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF74777D).withOpacity(1),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFC4C6CD))),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildBiometricButton(
                    icon: Icons.fingerprint,
                    label: 'Fingerprint',
                    onPressed: () => _showBiometricSnackBar('Fingerprint'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBiometricButton(
                    icon: Icons.face,
                    label: 'Face ID',
                    onPressed: () => _showBiometricSnackBar('Face ID'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    Widget? trailingAction,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B1C30),
                letterSpacing: 1.2,
              ),
            ),
            if (trailingAction != null) trailingAction,
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: const Color(0xFF74777D).withOpacity(0.5)),
            prefixIcon: Icon(icon, color: const Color(0xFF74777D)),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFF74777D),
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF8F9FF),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFC4C6CD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0453CD), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: Color(0xFFC4C6CD)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: const Color(0xFF0B1C30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF0453CD), size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't have an account? ", style: TextStyle(color: Color(0xFF44474C))),
            GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
              child: const Text(
                'Create an Account',
                style: TextStyle(color: Color(0xFF0453CD), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x4DC4C6CD))),
          ),
          padding: const EdgeInsets.only(top: 16),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 8,
            children: [
              _buildFooterLink('Privacy Policy', _showPrivacyPolicyDialog),
              _buildFooterLink('Terms of Service', _showTermsDialog),
              _buildFooterLink('Help Center', () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0453CD),
          decoration: TextDecoration.underline,
          decorationColor: Color(0xFF0453CD),
        ),
      ),
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────────────

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: Color(0xFF0453CD)),
            SizedBox(width: 10),
            Text('Forgot Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered email address. We will send you a link to reset your password.',
              style: TextStyle(color: Color(0xFF44474C), fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _forgotEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF0453CD)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0453CD), width: 2),
                ),
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
              final email = _forgotEmailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please enter your email address'),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              Navigator.pop(ctx);
              
              // Show sending indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Text('Sending reset link...'),
                    ],
                  ),
                  backgroundColor: const Color(0xFF0453CD),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );

              final res = await ApiService.forgotPassword(email);

              if (!mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        res['success'] == true ? Icons.check_circle : Icons.error_outline,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          res['message'] ?? (res['success'] == true ? 'Reset email sent!' : 'Failed to send reset email'),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: res['success'] == true ? const Color(0xFF10b981) : Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0453CD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  void _showBiometricSnackBar(String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(method == 'Fingerprint' ? Icons.fingerprint : Icons.face, color: Colors.white),
            const SizedBox(width: 10),
            Text('$method authentication initiated...'),
          ],
        ),
        backgroundColor: const Color(0xFF041627),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    _showPolicyDialog(
      title: 'Privacy Policy',
      icon: Icons.privacy_tip_outlined,
      content: '''SpendHike is committed to protecting your privacy.

1. DATA COLLECTION
We collect personal information such as name, email, mobile number, and financial transaction data that you voluntarily provide.

2. DATA USAGE
Your data is used to provide and improve the SpendHike service, generate financial reports, and send relevant notifications.

3. DATA SECURITY
All data is encrypted using AES-256 encryption. We never sell your personal data to third parties.

4. DATA RETENTION
Your data is retained as long as your account is active. You may request deletion at any time.

5. COOKIES
We use minimal cookies for session management and security purposes only.

6. CONTACT US
For privacy concerns, email: privacy@spendhike.com

Last updated: August 2026''',
    );
  }

  void _showTermsDialog() {
    _showPolicyDialog(
      title: 'Terms of Service',
      icon: Icons.gavel_outlined,
      content: '''Welcome to SpendHike. By using this app, you agree to the following terms:

1. ACCEPTANCE
By accessing SpendHike, you agree to be bound by these Terms of Service and applicable laws.

2. USE LICENSE
SpendHike grants you a limited, non-exclusive license to use the application for personal or business financial tracking.

3. DISCLAIMER
SpendHike provides financial tracking tools and is not a licensed financial advisor. Always consult a professional for financial decisions.

4. LIMITATIONS
SpendHike is not liable for any indirect, incidental, or consequential damages arising from use of the service.

5. ACCOUNT RESPONSIBILITY
You are responsible for maintaining the confidentiality of your account credentials.

6. MODIFICATIONS
SpendHike reserves the right to modify these terms at any time with prior notice.

7. GOVERNING LAW
These terms are governed by the laws of India.

Contact: legal@spendhike.com
Last updated: August 2026''',
    );
  }

  void _showPolicyDialog({
    required String title,
    required IconData icon,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: const Color(0xFF0453CD), size: 28),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF041627)),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF44474C)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    content,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF44474C), height: 1.6),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0453CD),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('I Understand'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
