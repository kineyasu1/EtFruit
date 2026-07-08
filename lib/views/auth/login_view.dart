import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/error_service.dart';
import 'package:agrimarketmob/l10n/app_localizations.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _otpSent = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendCountdown--;
        });
      }
    });
  }

  void _sendOtp() async {
    final phone = _phoneController.text.trim();
    String formattedPhone = phone;
    if (phone.startsWith('0')) {
      formattedPhone = '+251${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      formattedPhone = '+251$phone';
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).sendOtp(
        phoneNumber: formattedPhone,
        onCodeSent: (verificationId) {
          setState(() {
            _isLoading = false;
            _otpSent = true;
          });
          _startResendCountdown();
        },
        onFailed: (error) {
          setState(() {
            _isLoading = false;
            _errorMessage = error;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorService.getReadableError(context, e);
      });
    }
  }

  void _verifyOtp() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit code';
      });
      return;
    }

    final phone = _phoneController.text.trim();
    String formattedPhone = phone;
    if (phone.startsWith('0')) {
      formattedPhone = '+251${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      formattedPhone = '+251$phone';
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(authProvider.notifier).verifyOtp(code, formattedPhone);
      setState(() {
        _isLoading = false;
      });
      if (!success) {
        setState(() {
          _errorMessage = 'Invalid verification code. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorService.getReadableError(context, e);
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (AuthService.isFirebaseAvailable) {
      if (!_otpSent) {
        _sendOtp();
      } else {
        _verifyOtp();
      }
      return;
    }

    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    String formattedPhone = phone;
    if (phone.startsWith('0')) {
      formattedPhone = '+251${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      formattedPhone = '+251$phone';
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool success = false;
      final authNotifier = ref.read(authProvider.notifier);

      if (_isSignUp) {
        success = await authNotifier.signUpWithPassword(
          phoneNumber: formattedPhone,
          password: password,
        );
      } else {
        success = await authNotifier.signInWithPassword(
          phoneNumber: formattedPhone,
          password: password,
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (success) {
        // AppRootNavigator will automatically handle switching views based on auth state
      } else {
        setState(() {
          _errorMessage = _isSignUp
              ? 'Registration failed. User may already exist.'
              : 'Invalid phone number or password.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorService.getReadableError(context, e);
      });
    }
  }

  void _showForgotPasswordBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const ForgotPasswordBottomSheetContent(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFF81C784)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.agriculture_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.appName,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (AuthService.isFirebaseAvailable) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'Phone Authentication',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[900],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const Divider(),
                              const SizedBox(height: 16),
                            ] else ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isSignUp = false;
                                        _errorMessage = null;
                                      });
                                    },
                                    child: Text(
                                      'Log In',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: !_isSignUp ? Colors.green[900] : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isSignUp = true;
                                        _errorMessage = null;
                                      });
                                    },
                                    child: Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _isSignUp ? Colors.green[900] : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              const SizedBox(height: 16),
                            ],

                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.phone_rounded, color: Colors.green),
                                labelText: l10n.phoneNumber,
                                hintText: '0911000000 or 911000000',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.enterPhoneNumber;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            if (AuthService.isFirebaseAvailable && _otpSent) ...[
                              TextFormField(
                                controller: _codeController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.pin_rounded, color: Colors.green),
                                  labelText: 'Verification Code',
                                  hintText: '123456',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter verification code';
                                  }
                                  if (value.trim().length != 6) {
                                    return 'Enter a 6-digit code';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _otpSent = false;
                                        _errorMessage = null;
                                        _codeController.clear();
                                      });
                                    },
                                    child: const Text(
                                      'Change Phone Number',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _resendCountdown > 0 ? null : _sendOtp,
                                    child: Text(
                                      _resendCountdown > 0 ? 'Resend in ${_resendCountdown}s' : 'Resend Code',
                                      style: TextStyle(
                                        color: _resendCountdown > 0 ? Colors.grey : Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],

                            if (!AuthService.isFirebaseAvailable) ...[
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.lock_rounded, color: Colors.green),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  labelText: 'Password',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter password';
                                  }
                                  if (value.trim().length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 4),

                              if (!_isSignUp) ...[
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showForgotPasswordBottomSheet,
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Color(0xFF1B5E20),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ] else
                                const SizedBox(height: 12),

                              if (_isSignUp) ...[
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.green),
                                    labelText: 'Confirm Password',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please confirm password';
                                    }
                                    if (value.trim() != _passwordController.text.trim()) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                            ],

                            ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      AuthService.isFirebaseAvailable
                                          ? (_otpSent ? 'Verify & Login' : 'Send Code')
                                          : (_isSignUp ? 'Sign Up' : 'Log In'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FORGOT PASSWORD BOTTOM SHEET CONTENT
// -----------------------------------------------------------------------------
class ForgotPasswordBottomSheetContent extends StatefulWidget {
  const ForgotPasswordBottomSheetContent({super.key});

  @override
  State<ForgotPasswordBottomSheetContent> createState() =>
      _ForgotPasswordBottomSheetContentState();
}

class _ForgotPasswordBottomSheetContentState
    extends State<ForgotPasswordBottomSheetContent> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _step = 1; // 1: phone, 2: code, 3: new password
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _sendCode() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) return;

    String formattedPhone = rawPhone;
    if (rawPhone.startsWith('0')) {
      formattedPhone = '+251${rawPhone.substring(1)}';
    } else if (!rawPhone.startsWith('+')) {
      formattedPhone = '+251$rawPhone';
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await AuthService().sendMockResetOtp(formattedPhone);
    setState(() {
      _isLoading = false;
    });

    if (success) {
      setState(() {
        _step = 2;
      });
    } else {
      setState(() {
        _errorMessage = 'Phone number is not registered.';
      });
    }
  }

  void _verifyCode() async {
    final rawPhone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    String formattedPhone = rawPhone;
    if (rawPhone.startsWith('0')) {
      formattedPhone = '+251${rawPhone.substring(1)}';
    } else if (!rawPhone.startsWith('+')) {
      formattedPhone = '+251$rawPhone';
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await AuthService().verifyMockResetOtp(formattedPhone, code);
    setState(() {
      _isLoading = false;
    });

    if (success) {
      setState(() {
        _step = 3;
      });
    } else {
      setState(() {
        _errorMessage = 'Invalid validation code.';
      });
    }
  }

  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final rawPhone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    String formattedPhone = rawPhone;
    if (rawPhone.startsWith('0')) {
      formattedPhone = '+251${rawPhone.substring(1)}';
    } else if (!rawPhone.startsWith('+')) {
      formattedPhone = '+251$rawPhone';
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await AuthService().resetMockPassword(formattedPhone, password);
    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successfully. Please log in.')),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _errorMessage = 'Failed to reset password. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Forgot Password',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_step == 1) ...[
              const Text(
                'Enter your registered phone number to receive a simulated verification code.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone_rounded, color: Colors.green),
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Send Reset Code'),
              ),
            ],

            if (_step == 2) ...[
              const Text(
                'Enter the validation code sent to your device (use simulated code: 123456).',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.security_rounded, color: Colors.green),
                  labelText: 'Verification Code',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Verify Code'),
              ),
            ],

            if (_step == 3) ...[
              const Text(
                'Enter your new password below.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_rounded, color: Colors.green),
                  labelText: 'New Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter password';
                  if (value.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.green),
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm password';
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save New Password'),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
