import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';
import 'crypto_helper.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _loadSession();
  }

  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Global flag set during main.dart startup
  static bool isFirebaseAvailable = false;

  // Mock state for when Firebase is unavailable
  bool _mockLoggedIn = false;
  String? _mockUid;
  String? _mockPhoneNumber;

  // Sandbox password reset tracking
  final Map<String, String> _mockResetCodes = {};

  // Stream controller to notify auth state changes
  final StreamController<String?> _authStateController =
      StreamController<String?>.broadcast();

  Stream<String?> get authStateChanges {
    if (isFirebaseAvailable) {
      return _auth.authStateChanges().map((user) => user?.uid);
    } else {
      return _authStateController.stream;
    }
  }

  String? get currentUid {
    if (isFirebaseAvailable) {
      return _auth.currentUser?.uid;
    } else {
      return _mockLoggedIn ? _mockUid : null;
    }
  }

  String? get currentPhoneNumber {
    if (isFirebaseAvailable) {
      return _auth.currentUser?.phoneNumber;
    } else {
      return _mockLoggedIn ? _mockPhoneNumber : null;
    }
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getString('mock_logged_in_uid');
      if (savedUid != null) {
        _mockLoggedIn = true;
        _mockUid = savedUid;
        // Seed initial auth state change
        Timer(const Duration(milliseconds: 100), () {
          _authStateController.add(_mockUid);
        });
        
        // Fetch phone number from profile
        final profile = await FirestoreService().getUserProfile(savedUid);
        if (profile != null) {
          _mockPhoneNumber = profile.phoneNumber;
        }
      }
    } catch (e) {
      debugPrint('Error loading mock auth session: $e');
    }
  }

  // Verification ID returned by Firebase for OTP flow
  String? _verificationId;

  // Sends OTP to the specified phone number
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String code) onCodeSent,
    required Function(String error) onFailed,
  }) async {
    if (isFirebaseAvailable) {
      try {
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _auth.signInWithCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            onFailed(e.message ?? 'Verification failed');
          },
          codeSent: (String verificationId, int? resendToken) {
            _verificationId = verificationId;
            onCodeSent(verificationId);
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
          timeout: const Duration(seconds: 60),
        );
      } catch (e) {
        onFailed(e.toString());
      }
    } else {
      debugPrint('MOCK: Sending OTP to $phoneNumber');
      await Future.delayed(const Duration(seconds: 1));
      _mockPhoneNumber = phoneNumber;
      _verificationId = 'mock_verification_id';
      onCodeSent(_verificationId!);
    }
  }

  // Verifies the entered OTP and signs in
  Future<bool> verifyOtp(String smsCode) async {
    if (isFirebaseAvailable) {
      if (_verificationId == null) return false;
      try {
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: smsCode,
        );
        final userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user != null;
      } catch (e) {
        debugPrint('Error verifying OTP: $e');
        return false;
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      if (smsCode == '123456' || smsCode.isNotEmpty) {
        _mockLoggedIn = true;
        _mockUid = 'mock_user_${_mockPhoneNumber?.replaceAll('+', '') ?? '123456'}';
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mock_logged_in_uid', _mockUid!);

        _authStateController.add(_mockUid);
        return true;
      }
      return false;
    }
  }

  // -------------------------------------------------------------
  // Mock Password Register & Login (Hashed with Salted PBKDF2)
  // -------------------------------------------------------------
  Future<bool> mockSignInWithPassword(String phoneNumber, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final mockUser = await FirestoreService().getMockUserByPhoneNumber(phoneNumber);
    if (mockUser != null) {
      // Option A: Real migration-on-login for legacy plaintext passwords
      if (mockUser.salt.isEmpty && mockUser.passwordHash == password) {
        final newSalt = PBKDF2.generateSalt();
        final newHash = PBKDF2.hashPassword(password, newSalt);
        
        final migratedUser = mockUser.copyWith(
          passwordHash: newHash,
          salt: newSalt,
          updatedAt: DateTime.now(),
        );
        await FirestoreService().saveUserProfile(migratedUser);
        
        return _completeSignIn(phoneNumber, migratedUser.id);
      }

      // Standard hashed verification path
      final hashedInput = PBKDF2.hashPassword(password, mockUser.salt);
      if (hashedInput == mockUser.passwordHash) {
        return _completeSignIn(phoneNumber, mockUser.id);
      }
    }
    return false;
  }

  Future<bool> _completeSignIn(String phoneNumber, String uid) async {
    _mockLoggedIn = true;
    _mockUid = uid;
    _mockPhoneNumber = phoneNumber;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mock_logged_in_uid', _mockUid!);

    _authStateController.add(_mockUid);
    return true;
  }

  Future<bool> mockRegisterWithPassword(String phoneNumber, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final uid = 'mock_user_${phoneNumber.replaceAll('+', '').replaceAll(' ', '')}';
    final existingUser = await FirestoreService().getMockUserByPhoneNumber(phoneNumber);
    if (existingUser != null) {
      return false; // User already exists!
    }

    _mockLoggedIn = true;
    _mockUid = uid;
    _mockPhoneNumber = phoneNumber;

    final salt = PBKDF2.generateSalt();
    final passwordHash = PBKDF2.hashPassword(password, salt);

    final newUser = UserModel(
      id: uid,
      name: '',
      phoneNumber: phoneNumber,
      region: '',
      zone: '',
      woreda: '',
      passwordHash: passwordHash,
      salt: salt,
      role: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await FirestoreService().saveUserProfile(newUser);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mock_logged_in_uid', uid);

    _authStateController.add(_mockUid);
    return true;
  }

  // -------------------------------------------------------------
  // Mock Password Reset Flow (Forgot Password)
  // -------------------------------------------------------------
  Future<bool> sendMockResetOtp(String phoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = await FirestoreService().getMockUserByPhoneNumber(phoneNumber);
    if (user == null) return false;

    _mockResetCodes[phoneNumber] = '123456';
    debugPrint('MOCK PASSWORD RESET OTP for $phoneNumber: 123456');
    return true;
  }

  Future<bool> verifyMockResetOtp(String phoneNumber, String smsCode) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_mockResetCodes[phoneNumber] == smsCode) {
      return true;
    }
    return false;
  }

  Future<bool> resetMockPassword(String phoneNumber, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = await FirestoreService().getMockUserByPhoneNumber(phoneNumber);
    if (user == null) return false;

    final newSalt = PBKDF2.generateSalt();
    final newHash = PBKDF2.hashPassword(newPassword, newSalt);

    final updatedUser = user.copyWith(
      passwordHash: newHash,
      salt: newSalt,
      updatedAt: DateTime.now(),
    );
    await FirestoreService().saveUserProfile(updatedUser);
    _mockResetCodes.remove(phoneNumber);
    return true;
  }

  // Logs the user out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mock_logged_in_uid');

    if (isFirebaseAvailable) {
      await _auth.signOut();
    } else {
      _mockLoggedIn = false;
      _mockUid = null;
      _mockPhoneNumber = null;
      _authStateController.add(null);
    }
  }
}
