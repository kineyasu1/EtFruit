import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // Standard app commission rate (5%)
  static const double defaultCommissionRate = 0.05;

  // Production Firebase Cloud Functions URL
  static const String _functionsBaseUrl = String.fromEnvironment(
    'CLOUD_FUNCTIONS_URL',
    defaultValue: 'https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net',
  );

  /// 1 & 2: Initiates payment with commission calculation and Chapa link generation.
  /// Computes: commissionAmount = sellerPrice * commissionRate
  ///           totalAmount = sellerPrice + commissionAmount
  Future<Map<String, dynamic>> initializePayment({
    required String listingId,
    required String listingTitle,
    required double amount, // Seller price
    double? commissionRate,
    required String buyerId,
    required String sellerId,
    required String paymentMethod, // 'Telebirr', 'CBE Birr', 'e-Birr'
    String? email,
  }) async {
    final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
    final commRate = commissionRate ?? defaultCommissionRate;
    final sellerPrice = amount;
    final commissionAmount = double.parse((sellerPrice * commRate).toStringAsFixed(2));
    final totalAmount = double.parse((sellerPrice + commissionAmount).toStringAsFixed(2));

    // 1. Create Transaction record in Firestore
    final txDoc = {
      'id': orderId,
      'orderId': orderId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'sellerPrice': sellerPrice,
      'commissionRate': commRate,
      'commissionAmount': commissionAmount,
      'amount': totalAmount,
      'currency': 'ETB',
      'paymentMethod': paymentMethod,
      'status': 'pending',
      'gatewayReferenceId': '',
      'checkoutUrl': '',
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };

    // Create Order record in Firestore
    final orderDoc = {
      'id': orderId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'sellerPrice': sellerPrice,
      'commissionRate': commRate,
      'commissionAmount': commissionAmount,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'status': 'Pending Payment',
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };

    await FirestoreService().saveTransaction(txDoc);
    await FirestoreService().createOrder(orderDoc);

    if (AuthService.isFirebaseAvailable) {
      try {
        final response = await http.post(
          Uri.parse('$_functionsBaseUrl/initiatePayment'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'orderId': orderId,
            'txId': orderId,
            'sellerPrice': sellerPrice,
            'commissionRate': commRate,
            'amount': totalAmount,
            'email': email ?? 'buyer@agrimarket.com',
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

            txDoc['checkoutUrl'] = checkoutUrl;
            await FirestoreService().saveTransaction(txDoc);

            return {
              'success': true,
              'txId': orderId,
              'orderId': orderId,
              'totalAmount': totalAmount,
              'sellerPrice': sellerPrice,
              'commissionAmount': commissionAmount,
              'checkoutUrl': checkoutUrl,
              'isMock': false,
            };
          }
        }

        throw Exception('Cloud Function initiation failed with status: ${response.statusCode}');
      } catch (e) {
        debugPrint('Production payment initialization failed: $e');
        rethrow;
      }
    } else {
      // SANDBOX / MOCK MODE
      final mockCheckoutUrl = 'https://chapa-sandbox-simulator.web.app/pay/$orderId';
      txDoc['checkoutUrl'] = mockCheckoutUrl;
      await FirestoreService().saveTransaction(txDoc);

      return {
        'success': true,
        'txId': orderId,
        'orderId': orderId,
        'totalAmount': totalAmount,
        'sellerPrice': sellerPrice,
        'commissionAmount': commissionAmount,
        'checkoutUrl': mockCheckoutUrl,
        'isMock': true,
      };
    }
  }

  /// 3. Simulates Webhook payment confirmation (for Sandbox/Local Testing)
  /// - Marks order as "Payment Confirmed"
  /// - Creates pending seller payout record (status: "pending_delivery")
  Future<void> simulatePaymentSuccess(String txId) async {
    if (AuthService.isFirebaseAvailable) {
      debugPrint('Simulation skipped: Firebase live environment active.');
      return;
    }

    final tx = await FirestoreService().getTransaction(txId);
    if (tx != null) {
      tx['status'] = 'completed';
      tx['gatewayReferenceId'] = 'chapa_ref_${DateTime.now().millisecondsSinceEpoch}';
      tx['updatedAt'] = DateTime.now();
      await FirestoreService().saveTransaction(tx);

      // Update Order Status to "Payment Confirmed"
      await FirestoreService().updateOrderStatus(txId, 'Payment Confirmed');

      // Create Pending Payout record for seller
      final totalAmount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      final sellerPrice = (tx['sellerPrice'] as num?)?.toDouble() ?? totalAmount;
      final commissionAmount = (tx['commissionAmount'] as num?)?.toDouble() ?? 0.0;

      final payoutDoc = {
        'id': 'payout_$txId',
        'orderId': txId,
        'sellerId': tx['sellerId'],
        'buyerId': tx['buyerId'],
        'totalAmount': totalAmount,
        'sellerPrice': sellerPrice,
        'commissionAmount': commissionAmount,
        'sellerAmount': 0.0, // Calculated upon delivery
        'status': 'pending_delivery',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };
      await FirestoreService().createPayoutRecord(payoutDoc);

      // Send receipt to in-app chat thread
      final chatId = '${tx['listingId']}_${tx['buyerId']}_${tx['sellerId']}';
      await FirestoreService().sendMessage(
        chatId: chatId,
        senderId: 'system',
        text:
            '🔔 PAYMENT CONFIRMED:\nOrder ID: $txId\nTotal Amount: $totalAmount ETB\nSeller Payout Pending Delivery Confirmation.',
      );
    }
  }

  /// 4. Handles Delivery Confirmation & Calculates Seller Amount
  /// - Marks Order as "delivered"
  /// - Calculates seller_amount = total_amount - commission_amount
  /// - Updates Seller Payout status to "ready_for_payout"
  Future<void> confirmDelivery(String orderId) async {
    await FirestoreService().updateOrderStatus(orderId, 'delivered');

    final payout = await FirestoreService().getPayoutByOrderId(orderId);
    if (payout != null) {
      final totalAmount = (payout['totalAmount'] as num?)?.toDouble() ?? 0.0;
      final commissionAmount = (payout['commissionAmount'] as num?)?.toDouble() ?? 0.0;
      final sellerAmount = double.parse((totalAmount - commissionAmount).toStringAsFixed(2));

      payout['sellerAmount'] = sellerAmount;
      payout['status'] = 'ready_for_payout';
      payout['deliveryConfirmedAt'] = DateTime.now();
      payout['updatedAt'] = DateTime.now();

      await FirestoreService().savePayoutRecord(payout);
    }
  }

  /// 4b. Runs Batch Payout disbursement for sandbox testing
  Future<void> processBatchPayoutsMock() async {
    await FirestoreService().processBatchPayoutsMock();
  }

  Future<void> simulatePaymentFailure(String txId) async {
    if (AuthService.isFirebaseAvailable) return;
    final tx = await FirestoreService().getTransaction(txId);
    if (tx != null) {
      tx['status'] = 'failed';
      tx['updatedAt'] = DateTime.now();
      await FirestoreService().saveTransaction(tx);
      await FirestoreService().updateOrderStatus(txId, 'Payment Failed');
    }
  }
}
