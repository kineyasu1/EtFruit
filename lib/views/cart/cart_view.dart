import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../payment/payment_checkout_view.dart';

class CartView extends ConsumerStatefulWidget {
  const CartView({super.key});

  @override
  ConsumerState<CartView> createState() => _CartViewState();
}

class _CartViewState extends ConsumerState<CartView> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  void _loadCart() async {
    setState(() => _isLoading = true);
    final items = await FirestoreService().getCartItems();
    setState(() {
      _cartItems = List<Map<String, dynamic>>.from(items);
      _isLoading = false;
    });
  }

  void _removeItem(String listingId) async {
    await FirestoreService().removeFromCart(listingId);
    _loadCart();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    double total = 0.0;
    for (var item in _cartItems) {
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      final qty = double.tryParse(item['quantity'].toString()) ?? 1.0;
      total += (price * qty);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Shopping Cart',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
      ),
      body: _cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final price = double.tryParse(item['price'].toString()) ?? 0.0;
                      final qty = double.tryParse(item['quantity'].toString()) ?? 1.0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.green[50],
                                  child: const Icon(Icons.grass_rounded, color: Colors.green),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? 'Product',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${price.toStringAsFixed(0)} ETB / ${item['unit']}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Quantity: ${qty.toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                onPressed: () => _removeItem(item['listingId']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            '${total.toStringAsFixed(0)} ETB',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final user = ref.read(authProvider)!;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentCheckoutView(
                                listingId: 'cart_checkout_${DateTime.now().millisecondsSinceEpoch}',
                                listingTitle: 'Shopping Cart Checkout',
                                sellerName: 'Multiple Sellers',
                                sellerId: 'multi_sellers',
                                price: total,
                                onSuccessCallback: () async {
                                  for (var item in _cartItems) {
                                    final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}_${item['listingId']}';
                                    await FirestoreService().createOrder({
                                      'id': orderId,
                                      'listingId': item['listingId'],
                                      'title': item['title'],
                                      'price': item['price'],
                                      'unit': item['unit'],
                                      'quantity': item['quantity'],
                                      'photoUrl': item['photoUrl'] ?? '',
                                      'sellerId': item['sellerId'] ?? 'unknown_seller',
                                      'sellerName': item['sellerName'] ?? 'Seller',
                                      'buyerId': user.id,
                                      'buyerName': user.name,
                                      'status': 'pending',
                                      'isRated': false,
                                      'createdAt': DateTime.now().toIso8601String(),
                                      'updatedAt': DateTime.now().toIso8601String(),
                                    });
                                  }
                                  await FirestoreService().clearCart();
                                  _loadCart();
                                },
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                        ),
                        child: const Text(
                          'Proceed to Checkout',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// -----------------------------------------------------------------------------
// BUYER ORDERS SUB-VIEW
// -----------------------------------------------------------------------------
class BuyerOrdersSubView extends ConsumerStatefulWidget {
  const BuyerOrdersSubView({super.key});

  @override
  ConsumerState<BuyerOrdersSubView> createState() => _BuyerOrdersSubViewState();
}

class _BuyerOrdersSubViewState extends ConsumerState<BuyerOrdersSubView> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() async {
    setState(() => _isLoading = true);
    final items = await FirestoreService().getOrders();
    setState(() {
      _orders = List<Map<String, dynamic>>.from(items);
      _isLoading = false;
    });
  }

  void _cancelOrder(String orderId) async {
    await FirestoreService().updateOrderStatus(orderId, 'cancelled');
    _loadOrders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled successfully.')),
      );
    }
  }

  void _showRatingDialog(Map<String, dynamic> order) {
    int selectedRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Rate ${order['sellerName'] ?? 'Seller'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select your rating for this transaction:'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      return IconButton(
                        icon: Icon(
                          starVal <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedRating = starVal;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Add an optional feedback comment...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final buyer = ref.read(authProvider)!;
                    final reviewId = 'rev_${DateTime.now().millisecondsSinceEpoch}_${order['id']}';
                    
                    await FirestoreService().submitReview({
                      'id': reviewId,
                      'orderId': order['id'],
                      'buyerId': buyer.id,
                      'buyerName': buyer.name,
                      'sellerId': order['sellerId'] ?? 'unknown_seller',
                      'rating': selectedRating,
                      'comment': commentController.text.trim(),
                      'createdAt': DateTime.now().toIso8601String(),
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thank you! Your feedback has been submitted.')),
                      );
                      _loadOrders();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange[800]!;
      case 'confirmed':
        return Colors.blue[800]!;
      case 'shipped':
        return Colors.indigo[800]!;
      case 'delivered':
        return Colors.green[800]!;
      case 'cancelled':
        return Colors.red[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Purchase Orders',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
      ),
      body: _orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No orders placed yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final price = double.tryParse(order['price'].toString()) ?? 0.0;
                final qty = double.tryParse(order['quantity'].toString()) ?? 1.0;
                final status = order['status'] ?? 'pending';
                final isRated = order['isRated'] ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                status == 'cancelled'
                                    ? Icons.cancel_rounded
                                    : (status == 'delivered' ? Icons.check_circle_rounded : Icons.pending_rounded),
                                color: _getStatusColor(status),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order['title'] ?? 'Product',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Seller: ${order['sellerName'] ?? 'Seller'}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _getStatusColor(status).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${price.toStringAsFixed(0)} ETB / ${order['unit']} x ${qty.toStringAsFixed(0)}',
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            ),
                            Text(
                              'Total: ${(price * qty).toStringAsFixed(0)} ETB',
                              style: const TextStyle(
                                color: Color(0xFF1B5E20),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        if (status == 'pending' || (status == 'delivered' && !isRated)) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (status == 'pending')
                                TextButton.icon(
                                  onPressed: () => _cancelOrder(order['id']),
                                  icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                                  label: const Text('Cancel Order', style: TextStyle(color: Colors.red, fontSize: 12)),
                                ),
                              if (status == 'delivered' && !isRated)
                                ElevatedButton.icon(
                                  onPressed: () => _showRatingDialog(order),
                                  icon: const Icon(Icons.star_rounded, size: 16),
                                  label: const Text('Rate Seller', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber[700],
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
