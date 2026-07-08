import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../views/chat/chat_detail_view.dart';
import '../views/home/home_view.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Safe getter to avoid calling FirebaseMessaging.instance when Firebase is not initialized
  FirebaseMessaging? get _messaging => AuthService.isFirebaseAvailable ? FirebaseMessaging.instance : null;

  Future<void> initialize() async {
    if (!AuthService.isFirebaseAvailable) {
      debugPrint('FCM Notifications: Running in sandbox mode. Registration skipped.');
      return;
    }

    final msg = _messaging;
    if (msg == null) return;

    try {
      // 1. Request notification permissions
      final settings = await msg.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM Notifications: Authorized.');
        
        // 2. Fetch token and register to user profile
        await updateFcmToken();

        // Token change listener
        msg.onTokenRefresh.listen((token) async {
          final uid = AuthService().currentUid;
          if (uid != null) {
            await FirebaseFirestore.instance.collection('users').doc(uid).update({
              'fcmToken': token,
            });
          }
        });
      } else {
        debugPrint('FCM Notifications: User declined permissions.');
      }

      // 3. Listen to foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message received: ${message.notification?.title}');
        final context = NavigationService.navigatorKey.currentContext;
        if (context != null && context.mounted && message.notification != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${message.notification!.title}: ${message.notification!.body}',
              ),
              action: SnackBarAction(
                label: 'View',
                onPressed: () => _handleNotificationTap(message),
              ),
            ),
          );
        }
      });

      // 4. Handle tapping notifications (background/terminated)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

      final initialMessage = await msg.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      debugPrint('FCM Initialization error: $e');
    }
  }

  Future<void> updateFcmToken() async {
    final uid = AuthService().currentUid;
    if (uid == null || !AuthService.isFirebaseAvailable) return;

    final msg = _messaging;
    if (msg == null) return;

    try {
      final token = await msg.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': token,
        });
        debugPrint('FCM Token registered: $token');
      }
    } catch (e) {
      debugPrint('Error updating FCM Token: $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'];
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;

    if (type == 'chat') {
      final chatId = message.data['chatId'];
      final otherUserName = message.data['otherUserName'] ?? 'Seller';
      if (chatId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailView(
              chatId: chatId,
              otherUserName: otherUserName,
            ),
          ),
        );
      }
    } else if (type == 'payment' || type == 'order') {
      final user = refProviderContext?.read(authProvider);
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeView(
              initialTab: user.role == 'seller' ? 2 : 1,
            ),
          ),
        );
      }
    }
  }

  // Ref container context helper for reading user role in push navigation handlers
  ProviderContainer? refProviderContext;
}
