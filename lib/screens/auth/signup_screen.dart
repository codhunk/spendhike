import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/spend_hike_logo.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF), // background
      body: Stack(
        children: [
          // Visual Polish: Corner Decoration (Desktop only)
          if (isDesktop) ...[
            Positioned(
              top: 32,
              right: 32,
              child: Opacity(
                opacity: 0.2,
                child: Container(
                  width: 256,
                  height: 256,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFF0453CD), width: 4),
                      right: BorderSide(color: Color(0xFF0453CD), width: 4),
                    ),
                    borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 32,
              left: 32,
              child: Opacity(
                opacity: 0.2,
                child: Container(
                  width: 256,
                  height: 256,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF041627), width: 4),
                      left: BorderSide(color: Color(0xFF041627), width: 4),
                    ),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24)),
                  ),
                ),
              ),
            ),
          ],
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 512),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildSignupForm(),
                    const SizedBox(height: 32),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SpendHikeIcon(
          size: 64,
          walletColor: Color(0xFF041627),
          arrowColor: Color(0xFF0066FF),
        ),
        const SizedBox(height: 16),
        const Text(
          'Create your account',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF041627),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Join SpendHike to start managing your complex financial data with precision.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF44474C), // on-surface-variant
          ),
        ),
      ],
    );
  }

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  Widget _buildSignupForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC4C6CD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
              const SizedBox(height: 16),
            ],
            _buildTextField(
              label: 'FULL NAME',
              hint: 'Enter your full name',
              icon: Icons.person_outline,
              controller: _nameController,
              validator: (val) {
                final clean = (val ?? '').trim();
                if (clean.isEmpty) return 'Please enter your full name';
                if (clean.length < 2) return 'Name must be at least 2 characters long';
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'MOBILE NUMBER',
              hint: '10-digit mobile number (e.g. 9876543210)',
              icon: Icons.smartphone_outlined,
              controller: _mobileController,
              validator: (val) {
                final clean = (val ?? '').replaceAll(RegExp(r'\D'), '');
                if (clean.isEmpty) return 'Please enter your mobile number';
                if (clean.length != 10) return 'Mobile number must be exactly 10 digits';
                return null;
              },
            ),
            const SizedBox(height: 24),
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
              hint: 'Create a strong password (min. 6 characters)',
              icon: Icons.lock_outline,
              isPassword: true,
              controller: _passwordController,
              validator: (val) {
                final clean = (val ?? '').trim();
                if (clean.isEmpty) return 'Please enter a password';
                if (clean.length < 6) return 'Password must be at least 6 characters long';
                return null;
              },
            ),
            const SizedBox(height: 16),
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
                  activeColor: const Color(0xFF0453CD),
                ),
                Expanded(
                  child: Wrap(
                    children: [
                      const Text('I agree to the ', style: TextStyle(color: Color(0xFF44474C), fontSize: 14)),
                      GestureDetector(
                        onTap: () => _showPolicyDialog(
                          title: 'Terms & Conditions',
                          icon: Icons.gavel_outlined,
                          content: 'By using SpendHike, you agree to our terms of service. SpendHike provides financial tracking tools and is not a licensed financial advisor. You are responsible for maintaining the confidentiality of your account credentials. These terms are governed by the laws of India.\n\nContact: legal@spendhike.com',
                        ),
                        child: const Text('Terms & Conditions', style: TextStyle(color: Color(0xFF0453CD), fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      const Text(' and ', style: TextStyle(color: Color(0xFF44474C), fontSize: 14)),
                      GestureDetector(
                        onTap: () => _showPolicyDialog(
                          title: 'Privacy Policy',
                          icon: Icons.privacy_tip_outlined,
                          content: 'SpendHike is committed to protecting your privacy. We collect personal information such as name, email, mobile number, and financial transaction data. All data is encrypted using AES-256. We never sell your personal data to third parties.\n\nContact: privacy@spendhike.com',
                        ),
                        child: const Text('Privacy Policy', style: TextStyle(color: Color(0xFF0453CD), fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      const Text('.', style: TextStyle(color: Color(0xFF44474C), fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _errorMessage = null);
                      if (!_formKey.currentState!.validate()) return;
                      if (!_agreedToTerms) {
                        setState(() {
                          _errorMessage = 'You must agree to the Terms & Conditions and Privacy Policy.';
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
                          const SnackBar(
                            content: Text('Account created successfully! Welcome to SpendHike.'),
                            backgroundColor: Color(0xFF10b981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.pushReplacementNamed(context, '/main');
                      } else if (mounted) {
                        setState(() {
                          _errorMessage = res['message'] ?? 'Signup failed. Please try again.';
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
                        Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
            ),
          const SizedBox(height: 32),
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
                    color: const Color(0xFF44474C), // on-surface-variant
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFC4C6CD))),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDKA_Tq6Q7vEY1n-8LQXlr3tZhqfvEgFU-_xYGhsUMIeX7rGlf8Xq19JHhYRY4CJukM6PcmKtTWarvJ7A2n1FQnZgeI5xzKbtaTta_rl3OYRUWNkN8lXqfnpepIOZs0_8pTVAs7wRx0PjI-SlMh8nnMQMTVtTRxt-q3rJ7NFwILHoO55zDvcwrUX9fN_wT49ToCNILkD_hfpmrAxSCGA_A9rcCIs2mSFx5ZjEZYXlACgyjThN17LaBi',
                  label: 'Google',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSocialButton(
                  imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCLzSiEohfRE87Q1lWN_rDCOPYRWuyCPSeXhewa9K2Gwyj52jZUUd8bhcE6oWaNv4E-OCj-zvZuJI0sR_5IV8IToRoPGtmAmllWjqBcrkSWpKvTIz2jd_TPq1l2YWvKIkkJTgu-TCvyIw4jZiCpE7kW2lMSuvV5W2hgnKKxV9ah0AJg2L0hZZCYXFRDWQ7IcWz6VoqcAUyGbdkbG-IMoofStatjSw50DE4MVWE-HD3n9iERon3TaJTq',
                  label: 'Apple',
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
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF44474C), // on-surface-variant
            letterSpacing: 1.2,
          ),
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
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
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

  Widget _buildSocialButton({required String imageUrl, required String label}) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFC4C6CD)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        foregroundColor: const Color(0xFF0B1C30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(imageUrl, width: 20, height: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Already have an account? ",
          style: TextStyle(color: Color(0xFF44474C)),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: const Text(
            'Login',
            style: TextStyle(
              color: Color(0xFF0453CD),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
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
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF041627))),
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
                  child: Text(content,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF44474C), height: 1.6)),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
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

