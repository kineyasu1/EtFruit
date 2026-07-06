import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<UserModel?> {
  AuthNotifier() : super(null) {
    _init();
  }

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  void _init() {
    _authService.authStateChanges.listen((uid) async {
      if (uid == null) {
        state = null;
      } else {
        await _loadProfile(uid);
      }
    });

    // Check initial user
    final initialUid = _authService.currentUid;
    if (initialUid != null) {
      _loadProfile(initialUid);
    }
  }

  Future<void> _loadProfile(String uid) async {
    final profile = await _firestoreService.getUserProfile(uid);
    if (profile != null) {
      state = profile;
      NotificationService().updateFcmToken();
    }
  }

  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onFailed,
  }) async {
    await _authService.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onFailed: onFailed,
    );
  }

  Future<bool> verifyOtpAndSetupProfile({
    required String smsCode,
    required String name,
    required String region,
    required String zone,
    required String woreda,
    String? telegramUsername,
    String? whatsappNumber,
    String? profilePictureUrl,
  }) async {
    final success = await _authService.verifyOtp(smsCode);
    if (!success) return false;

    final uid = _authService.currentUid;
    if (uid == null) return false;

    // Check if profile already exists, if not create new one
    var existingProfile = await _firestoreService.getUserProfile(uid);
    if (existingProfile == null) {
      final newUser = UserModel(
        id: uid,
        name: name,
        phoneNumber: _authService.currentPhoneNumber ?? '',
        region: region,
        zone: zone,
        woreda: woreda,
        profilePictureUrl: profilePictureUrl,
        telegramUsername: telegramUsername,
        whatsappNumber: whatsappNumber,
        isVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _firestoreService.saveUserProfile(newUser);
      state = newUser;
    } else {
      state = existingProfile;
    }
    return true;
  }

  Future<bool> signInWithPassword({
    required String phoneNumber,
    required String password,
  }) async {
    final success = await _authService.mockSignInWithPassword(phoneNumber, password);
    if (success) {
      final uid = _authService.currentUid;
      if (uid != null) {
        await _loadProfile(uid);
        return true;
      }
    }
    return false;
  }

  Future<bool> signUpWithPassword({
    required String phoneNumber,
    required String password,
  }) async {
    final success = await _authService.mockRegisterWithPassword(phoneNumber, password);
    if (success) {
      final uid = _authService.currentUid;
      if (uid != null) {
        await _loadProfile(uid);
        return true;
      }
    }
    return false;
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    await _firestoreService.saveUserProfile(updatedUser);
    state = updatedUser;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = null;
  }
}
