import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../../services/passcode_service.dart';

enum ChangePasscodeStep { verifyOld, createNew, confirmNew }

class ChangePasscodeScreen extends StatefulWidget {
  const ChangePasscodeScreen({super.key});

  @override
  State<ChangePasscodeScreen> createState() => _ChangePasscodeScreenState();
}

class _ChangePasscodeScreenState extends State<ChangePasscodeScreen> {
  ChangePasscodeStep _currentStep = ChangePasscodeStep.verifyOld;

  String _oldPasscode = '';
  String _newPasscode = '';
  int _newPinLength = 4;
  int _oldPinLength = 4;

  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOldPasscodeLength();
  }

  Future<void> _loadOldPasscodeLength() async {
    final len = await PasscodeService.getPasscodeLength();
    setState(() {
      _oldPinLength = len;
      _newPinLength = len;
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleStepCompleted(String inputPin) async {
    switch (_currentStep) {
      case ChangePasscodeStep.verifyOld:
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
        final isValid = await PasscodeService.verifyPasscode(inputPin);
        if (!mounted) return;

        if (isValid) {
          setState(() {
            _oldPasscode = inputPin;
            _currentStep = ChangePasscodeStep.createNew;
            _pinController.clear();
            _isLoading = false;
          });
          _focusNode.requestFocus();
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Current passcode is incorrect. Please try again.';
          });
          _pinController.clear();
        }
        break;

      case ChangePasscodeStep.createNew:
        if (inputPin.length != _newPinLength) {
          setState(() {
            _errorMessage = 'Please enter a $_newPinLength-digit passcode';
          });
          return;
        }
        setState(() {
          _newPasscode = inputPin;
          _currentStep = ChangePasscodeStep.confirmNew;
          _pinController.clear();
          _errorMessage = null;
        });
        _focusNode.requestFocus();
        break;

      case ChangePasscodeStep.confirmNew:
        if (inputPin != _newPasscode) {
          setState(() {
            _errorMessage = 'Passcodes do not match. Please try again.';
          });
          _pinController.clear();
          return;
        }

        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        final res = await PasscodeService.changePasscode(
          oldPasscode: _oldPasscode,
          newPasscode: _newPasscode,
        );

        if (!mounted) return;

        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passcode changed successfully!'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = res['message'] ?? 'Failed to update passcode';
          });
          _pinController.clear();
        }
        break;
    }
  }

  int get _activePinLength {
    if (_currentStep == ChangePasscodeStep.verifyOld) {
      return _oldPinLength;
    }
    return _newPinLength;
  }

  String get _stepTitle {
    switch (_currentStep) {
      case ChangePasscodeStep.verifyOld:
        return 'Enter Current Passcode';
      case ChangePasscodeStep.createNew:
        return 'Enter New Passcode';
      case ChangePasscodeStep.confirmNew:
        return 'Confirm New Passcode';
    }
  }

  String get _stepSubtitle {
    switch (_currentStep) {
      case ChangePasscodeStep.verifyOld:
        return 'Verify your existing passcode before changing it.';
      case ChangePasscodeStep.createNew:
        return 'Select length and enter your new passcode.';
      case ChangePasscodeStep.confirmNew:
        return 'Re-enter your new passcode to confirm.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultPinTheme = PinTheme(
      width: _activePinLength == 6 ? 48 : 58,
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
      appBar: AppBar(
        title: const Text('Change Passcode'),
        elevation: 0,
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
                  // Progress indicator steps
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepDot(0, ChangePasscodeStep.verifyOld),
                      _buildStepLine(ChangePasscodeStep.createNew),
                      _buildStepDot(1, ChangePasscodeStep.createNew),
                      _buildStepLine(ChangePasscodeStep.confirmNew),
                      _buildStepDot(2, ChangePasscodeStep.confirmNew),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.key_rounded,
                      size: 36,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    _stepTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _stepSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Option to select length during createNew step
                  if (_currentStep == ChangePasscodeStep.createNew) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLengthToggle(4, '4 Digits'),
                          _buildLengthToggle(6, '6 Digits'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  Pinput(
                    length: _activePinLength,
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
                    onCompleted: (pin) => _handleStepCompleted(pin),
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

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _handleStepCompleted(_pinController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _currentStep == ChangePasscodeStep.confirmNew ? 'Save New Passcode' : 'Next',
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
  }

  Widget _buildStepDot(int index, ChangePasscodeStep step) {
    final theme = Theme.of(context);
    final isActive = _currentStep.index >= step.index;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isActive ? theme.colorScheme.primary : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine(ChangePasscodeStep targetStep) {
    final theme = Theme.of(context);
    final isActive = _currentStep.index >= targetStep.index;

    return Container(
      width: 36,
      height: 2,
      color: isActive ? theme.colorScheme.primary : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
    );
  }

  Widget _buildLengthToggle(int length, String label) {
    final isSelected = _newPinLength == length;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        if (_newPinLength != length) {
          setState(() {
            _newPinLength = length;
            _pinController.clear();
            _errorMessage = null;
          });
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}
