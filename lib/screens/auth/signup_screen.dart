import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/app_settings.dart';
import '../../widgets/spend_hike_logo.dart';
import 'create_passcode_screen.dart';


class SignupScreen extends StatefulWidget {

  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  String _tr(String text) => AppSettings.instance.tr(text);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final colors = AppTheme.of(context);
        return Scaffold(
          backgroundColor: colors.background,
          body: Stack(
            children: [
              // Visual Polish: Corner Decoration (Desktop only)
            if (isDesktop) ...[
              Positioned(
                top: 32,
                right: 32,
                child: Opacity(
                  opacity: 0.15,
                  child: Container(
                    width: 256,
                    height: 256,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: colors.primary, width: 4),
                        right: BorderSide(color: colors.primary, width: 4),
                      ),
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(24)),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 32,
                left: 32,
                child: Opacity(
                  opacity: 0.15,
                  child: Container(
                    width: 256,
                    height: 256,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colors.border, width: 4),
                        left: BorderSide(color: colors.border, width: 4),
                      ),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24)),
                    ),
                  ),
                ),
              ),
            ],
            
            Center(
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 14),
                        _buildSignupForm(),
                        const SizedBox(height: 14),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
    );
  }

  Widget _buildHeader() {
    final colors = AppTheme.of(context);
    return Column(
      children: [
        SpendHikeLogo(
          isVertical: false,
          iconSize: 36,
          fontSize: 26,
          walletColor: colors.textPrimary,
          arrowColor: colors.primary,
          textColor: colors.textPrimary,
        ),
        const SizedBox(height: 6),
        Text(
          _tr('Create your account'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  Widget _buildSignupForm() {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              const SizedBox(height: 12),
            ],
            _buildTextField(
              label: _tr('FULL NAME'),
              hint: _tr('Enter your full name'),
              icon: Icons.person_outline,
              controller: _nameController,
              validator: (val) {
                final clean = (val ?? '').trim();
                if (clean.isEmpty) return _tr('Please enter your full name');
                if (clean.length < 2) return _tr('Name must be at least 2 characters long');
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: _tr('MOBILE NUMBER'),
              hint: _tr('10-digit mobile number'),
              icon: Icons.smartphone_outlined,
              controller: _mobileController,
              validator: (val) {
                final clean = (val ?? '').replaceAll(RegExp(r'\D'), '');
                if (clean.isEmpty) return _tr('Please enter your mobile number');
                if (clean.length != 10) return _tr('Please enter a valid 10-digit mobile number');
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: _tr('EMAIL ADDRESS'),
              hint: 'name@company.com',
              icon: Icons.mail_outline,
              controller: _emailController,
              validator: (val) {
                final clean = (val ?? '').trim();
                if (clean.isEmpty) return _tr('Please enter your email address');
                final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                if (!emailRegex.hasMatch(clean)) return _tr('Please enter a valid email address');
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: _tr('PASSWORD'),
              hint: _tr('Create a strong password'),
              icon: Icons.lock_outline,
              isPassword: true,
              controller: _passwordController,
              validator: (val) {
                final clean = (val ?? '').trim();
                if (clean.isEmpty) return _tr('Please enter your password');
                if (clean.length < 6) return _tr('Password must be at least 6 characters long');
                return null;
              },
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  onChanged: (val) {
                    setState(() {
                      _agreedToTerms = val ?? false;
                    });
                  },
                  activeColor: colors.primary,
                ),
                Expanded(
                  child: Wrap(
                    children: [
                      Text(_tr('I agree to the '), style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                      GestureDetector(
                        onTap: () => _showPolicyDialog(
                          title: 'Terms & Conditions',
                          icon: Icons.gavel_outlined,
                          content: 'By using SpendHike, you agree to our terms of service. SpendHike provides financial tracking tools and is not a licensed financial advisor. You are responsible for maintaining the confidentiality of your account credentials. These terms are governed by the laws of India.\n\nContact: legal@spendhike.com',
                        ),
                        child: Text(_tr('Terms & Conditions'), style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      Text(_tr(' and '), style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                      GestureDetector(
                        onTap: () => _showPolicyDialog(
                          title: 'Privacy Policy',
                          icon: Icons.privacy_tip_outlined,
                          content: 'SpendHike is committed to protecting your privacy. We collect personal information such as name, email, mobile number, and financial transaction data. All data is encrypted using AES-256. We never sell your personal data to third parties.\n\nContact: privacy@spendhike.com',
                        ),
                        child: Text(_tr('Privacy Policy'), style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      Text('.', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _errorMessage = null);
                      if (!_formKey.currentState!.validate()) return;
                      if (!_agreedToTerms) {
                        setState(() {
                          _errorMessage = _tr('You must agree to the Terms & Conditions and Privacy Policy.');
                        });
                        return;
                      }

                      setState(() => _isLoading = true);
                      final res = await ApiService.signup(
                        _nameController.text.trim(),
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                        _mobileController.text.trim(),
                      );
                      if (mounted) setState(() => _isLoading = false);

                      if (res['success'] == true && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_tr('Account created successfully! Welcome to SpendHike.')),
                            backgroundColor: const Color(0xFF10b981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const CreatePasscodeScreen()),
                        );

                      } else if (mounted) {
                        setState(() {
                          _errorMessage = _tr(res['message'] ?? 'Signup failed. Please try again.');
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_tr('Sign Up'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
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
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    final colors = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          validator: validator,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textMuted),
            prefixIcon: Icon(icon, color: colors.textSecondary),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: colors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: colors.surfaceSubtle,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final colors = AppTheme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _tr("Already have an account? "),
              style: TextStyle(color: colors.textSecondary),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text(
                _tr('Login'),
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            children: [
              _buildFooterLink(_tr('Privacy Policy'), () => _showPolicyDialog(
                title: 'Privacy Policy',
                icon: Icons.privacy_tip_outlined,
                content: 'SpendHike is committed to protecting your privacy. We collect personal information such as name, email, mobile number, and financial transaction data. All data is encrypted using AES-256. We never sell your personal data to third parties.\n\nContact: privacy@spendhike.com',
              )),
              _buildFooterLink(_tr('Terms & Conditions'), () => _showPolicyDialog(
                title: 'Terms & Conditions',
                icon: Icons.gavel_outlined,
                content: 'By using SpendHike, you agree to our terms of service. SpendHike provides financial tracking tools and is not a licensed financial advisor. You are responsible for maintaining the confidentiality of your account credentials. These terms are governed by the laws of India.\n\nContact: legal@spendhike.com',
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text, VoidCallback onTap) {
    final colors = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.primary,
          decoration: TextDecoration.underline,
          decorationColor: colors.primary,
        ),
      ),
    );
  }

  void _showPolicyDialog({
    required String title,
    required IconData icon,
    required String content,
  }) {
    final colors = AppTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: colors.primary, size: 28),
                    const SizedBox(width: 12),
                    Text(_tr(title),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Text(content,
                      style: TextStyle(
                          fontSize: 14, color: colors.textSecondary, height: 1.6)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_tr('I Understand')),
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

