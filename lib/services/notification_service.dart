import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../views/chat/chat_detail_view.dart';
import '../views/home/home_view.dart';
import 'firestore_service.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    if (!AuthService.isFirebaseAvailable) {
      debugPrint('FCM Notifications: Running in sandbox mode. Registration skipped.');
      return;
    }

    try {
      // 1. Request notification permissions
      final settings = await _messaging.requestPermission(
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
        _messaging.onTokenRefresh.listen((token) async {
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
        if (context != null && message.notification != null) {
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

      final initialMessage = await _messaging.getInitialMessage();
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

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': token,
        });
        debugPrint('FCM Token registered: $token');
      }
    } catch (e) {
      debugPrint('FCM Token registration error: $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'];
    final navigator = NavigationService.navigatorKey.currentState;

    if (navigator == null) return;

    if (type == 'chat') {
      final chatId = data['chatId'];
      final otherUserName = data['otherUserName'] ?? 'Chat';
      if (chatId != null) {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => ChatDetailView(
              chatId: chatId,
              otherUserName: otherUserName,
            ),
          ),
        );
      }
    } else if (type == 'payment' || type == 'order') {
      final uid = AuthService().currentUid;
      if (uid == null) return;
      
      final profile = await FirestoreService().getUserProfile(uid);
      if (profile == null) return;

      if (profile.role == 'seller') {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeView(initialTab: 0)), // Dashboard
          (route) => false,
        );
      } else {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeView(initialTab: 2)), // Orders
          (route) => false,
        );
      }
    }
  }
}
