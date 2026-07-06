import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'profile_setup_view.dart';
import '../home/home_view.dart';
import 'package:agrimarketmob/l10n/app_localizations.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _phoneNumber = '';

  // For sandbox testing demonstration
  final bool _isSandbox = !AuthService.isFirebaseAvailable;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) return;

    // Validate phone number format (must fit Ethiopia +251 format)
    String formattedPhone = rawPhone;
    if (rawPhone.startsWith('0')) {
      formattedPhone = '+251${rawPhone.substring(1)}';
    } else if (!rawPhone.startsWith('+')) {
      formattedPhone = '+251$rawPhone';
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _phoneNumber = formattedPhone;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .sendOtp(
            phoneNumber: formattedPhone,
            onCodeSent: (verificationId) {
              setState(() {
                _isLoading = false;
                _isOtpSent = true;
              });
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
        _errorMessage = e.toString();
      });
    }
  }

  void _verifyOtp() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifier = ref.read(authProvider.notifier);

      // If Firebase is available, check if the profile exists in Firestore.
      // Otherwise, the authNotifier mock flow handles this.
      // We will perform a simple verification check
      final success = await AuthService().verifyOtp(smsCode);

      if (success) {
        final currentUid = AuthService().currentUid!;
        final profile = await FirestoreService().getUserProfile(currentUid);

        setState(() {
          _isLoading = false;
        });

        if (profile == null) {
          // If the profile doesn't exist yet, go to setup profile
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProfileSetupView(phoneNumber: _phoneNumber),
              ),
            );
          }
        } else {
          // Re-populate state and go to home
          await notifier.verifyOtpAndSetupProfile(
            smsCode: smsCode,
            name: profile.name,
            region: profile.region,
            zone: profile.zone,
            woreda: profile.woreda,
            telegramUsername: profile.telegramUsername,
            whatsappNumber: profile.whatsappNumber,
          );
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeView()),
            );
          }
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context).invalidOtp;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
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
                          Text(
                            _isOtpSent ? l10n.verifyOtp : l10n.phoneLogin,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isOtpSent
                                ? l10n.enterVerificationCode
                                : l10n.enterPhoneNumber,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          if (_isSandbox)
                            Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Sandbox Mode Active. You can use any phone number and enter "123456" as the OTP code.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (!_isOtpSent) ...[
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.phone_rounded),
                                labelText: l10n.phoneNumber,
                                hintText: '0911000000 or +251911000000',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onFieldSubmitted: (_) => _sendOtp(),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _sendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      l10n.sendOtp,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ] else ...[
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                labelText: l10n.verificationCode,
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onFieldSubmitted: (_) => _verifyOtp(),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      l10n.verify,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isOtpSent = false;
                                  _otpController.clear();
                                });
                              },
                              child: Text(
                                l10n.cancel,
                                style: const TextStyle(
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}
