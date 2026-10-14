import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../../services/api_service.dart';
import '../../services/app_settings.dart';
import '../../services/passcode_service.dart';
import '../../services/biometric_service.dart';
import '../../widgets/language_switcher.dart';
import '../navigation/main_navigation.dart';

class ConfirmPasscodeScreen extends StatefulWidget {
  final String createdPasscode;
  final int pinLength;
  final bool isResetFlow;

  const ConfirmPasscodeScreen({
    super.key,
    required this.createdPasscode,
    required this.pinLength,
    this.isResetFlow = false,
  });

  @override
  State<ConfirmPasscodeScreen> createState() => _ConfirmPasscodeScreenState();
}

class _ConfirmPasscodeScreenState extends State<ConfirmPasscodeScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  String _tr(String key) => AppSettings.instance.tr(key);

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onConfirm(String pin) async {
    if (pin.length != widget.pinLength) {
      setState(() {
        _errorMessage = _tr('Please enter a complete ${widget.pinLength}-digit passcode');
      });
      return;
    }

    if (pin != widget.createdPasscode) {
      setState(() {
        _errorMessage = _tr('Passcodes do not match. Please try again.');
      });
      _pinController.clear();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await PasscodeService.savePasscode(pin);

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr(widget.isResetFlow ? 'Passcode updated successfully!' : 'Passcode set successfully!')),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _checkAndPromptBiometricSetup();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res['message'] != null ? _tr(res['message']) : _tr('Failed to save passcode. Please try again.');
      });
      _pinController.clear();
    }
  }

  Future<void> _checkAndPromptBiometricSetup() async {
    final isAvailable = await BiometricService.isBiometricsAvailable();
    if (!mounted) return;

    if (!isAvailable) {
      _navigateToMain();
      return;
    }

    final biometricLabel = await BiometricService.getBiometricTypeLabel();
    if (!mounted) return;

    final shouldEnable = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0453CD).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  biometricLabel == 'Face ID' ? Icons.face : Icons.fingerprint,
                  color: const Color(0xFF0453CD),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _tr('Enable Biometric Unlock?'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tr('Unlock SpendHike faster using your fingerprint or Face ID.'),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(
                _tr('Skip'),
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0453CD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(_tr('Enable')),
            ),
          ],
        );
      },
    );

    if (shouldEnable == true) {
      final authResult = await BiometricService.authenticate(
        localizedReason: _tr('Authenticate to enable biometric unlock'),
      );
      if (authResult.success) {
        await BiometricService.setBiometricEnabled(true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_tr('Biometric unlock enabled')),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await BiometricService.setBiometricEnabled(false);
      }
    } else {
      await BiometricService.setBiometricEnabled(false);
    }

    if (!mounted) return;
    _navigateToMain();
  }

  void _navigateToMain() {
    if (ApiService.currentUser?.role == 'Labour') {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/labour-panel',
        (route) => false,
      );
      return;
    }

    if (widget.isResetFlow) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultPinTheme = PinTheme(
      width: widget.pinLength == 6 ? 48 : 58,
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

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_tr('Confirm Passcode')),
            elevation: 0,
            actions: const [
              LanguageSwitcherButton(),
              SizedBox(width: 8),
            ],
          ),
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
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 36,
                          color: Color(0xFF10B981),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        _tr('Confirm Passcode'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _tr('Re-enter your ${widget.pinLength}-digit passcode to confirm.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),

                      const SizedBox(height: 36),

                      Pinput(
                        length: widget.pinLength,
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
                        onCompleted: (pin) => _onConfirm(pin),
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


                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _onConfirm(_pinController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  _tr('Confirm & Finish'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
