import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // production Firebase Cloud Functions URL (to be replaced by developer)
  static const String _functionsBaseUrl = 'https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net';

  // Initiates a payment session
  Future<Map<String, dynamic>> initializePayment({
    required String listingId,
    required String listingTitle,
    required double amount,
    required String buyerId,
    required String sellerId,
    required String paymentMethod, // 'Telebirr', 'CBE Birr', 'HelloCash'
  }) async {
    final txId = 'tx_${DateTime.now().millisecondsSinceEpoch}';

    // Create local transaction record in Firestore
    final txDoc = {
      'id': txId,
      'amount': amount,
      'currency': 'ETB',
      'buyerId': buyerId,
      'sellerId': sellerId,
      'listingId': listingId,
      'paymentMethod': paymentMethod,
      'status': 'pending',
      'gatewayReferenceId': '',
      'checkoutUrl': '',
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };

    await FirestoreService().saveTransaction(txDoc);

    if (AuthService.isFirebaseAvailable) {
      try {
        // Production Call to Cloud Function wrapper
        final response = await http.post(
          Uri.parse('$_functionsBaseUrl/initiatePayment'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'txId': txId,
            'amount': amount,
            'email': 'buyer@farmlink.com', // Chapa requires an email address
            'buyerId': buyerId,
            'sellerId': sellerId,
            'listingId': listingId,
            'title': listingTitle,
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'success') {
            final checkoutUrl = data['data']['checkout_url'];
            
            // Update transaction record with checkout URL
            txDoc['checkoutUrl'] = checkoutUrl;
            await FirestoreService().saveTransaction(txDoc);
            
            return {
              'success': true,
              'txId': txId,
              'checkoutUrl': checkoutUrl,
              'isMock': false,
            };
          }
        }
        
        debugPrint('Cloud Function payment init failed, falling back to mock sandbox: ${response.body}');
      } catch (e) {
        debugPrint('Error calling backend, falling back to mock sandbox: $e');
      }
    }

    // FALLBACK / SANDBOX SIMULATION MODE
    // Generate a mock checkout URL pointing to a simulator
    final mockCheckoutUrl = 'https://chapa-sandbox-simulator.web.app/pay/$txId';
    txDoc['checkoutUrl'] = mockCheckoutUrl;
    await FirestoreService().saveTransaction(txDoc);

    return {
      'success': true,
      'txId': txId,
      'checkoutUrl': mockCheckoutUrl,
      'isMock': true,
    };
  }

  // Simulates a webhook success trigger for sandbox testing
  Future<void> simulatePaymentSuccess(String txId) async {
    final tx = await FirestoreService().getTransaction(txId);
    if (tx != null) {
      tx['status'] = 'completed';
      tx['gatewayReferenceId'] = 'chapa_ref_${DateTime.now().millisecondsSinceEpoch}';
      tx['updatedAt'] = DateTime.now();
      await FirestoreService().saveTransaction(tx);
      
      // Send receipt notification message to the in-app chat thread if active
      final chatId = '${tx['listingId']}_${tx['buyerId']}_${tx['sellerId']}';
      await FirestoreService().sendMessage(
        chatId: chatId,
        senderId: 'system',
        text: '🔔 PAYMENT CONFIRMED RECEIPT:\nAmount: ${tx['amount']} ETB\nPayment Method: ${tx['paymentMethod']}\nTransaction ID: ${tx['id']}',
      );
    }
  }

  // Simulates a webhook failure trigger for sandbox testing
  Future<void> simulatePaymentFailure(String txId) async {
    final tx = await FirestoreService().getTransaction(txId);
    if (tx != null) {
      tx['status'] = 'failed';
      tx['updatedAt'] = DateTime.now();
      await FirestoreService().saveTransaction(tx);
    }
  }
}
