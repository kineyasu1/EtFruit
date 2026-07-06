import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../payment/payment_checkout_view.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
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
                              // Small thumbnail
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
                              // Title & details
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
                                      '$price ETB / ${item['unit']} x $qty',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Subtotal: ${(price * qty).toStringAsFixed(0)} ETB',
                                      style: const TextStyle(
                                          color: Color(0xFF1B5E20),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              // Remove button
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
                // Footer Checkout Area
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
                                  // Record cart checkouts as purchases in orders history
                                  for (var item in _cartItems) {
                                    await FirestoreService().createOrder({
                                      'listingId': item['listingId'],
                                      'title': item['title'],
                                      'price': item['price'],
                                      'unit': item['unit'],
                                      'quantity': item['quantity'],
                                      'createdAt': DateTime.now().toIso8601String(),
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
class BuyerOrdersSubView extends StatefulWidget {
  const BuyerOrdersSubView({super.key});

  @override
  State<BuyerOrdersSubView> createState() => _BuyerOrdersSubViewState();
}

class _BuyerOrdersSubViewState extends State<BuyerOrdersSubView> {
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

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF1B5E20), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order['title'] ?? 'Product',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$price ETB / ${order['unit']} x $qty',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Paid Subtotal: ${(price * qty).toStringAsFixed(0)} ETB',
                                style: const TextStyle(
                                    color: Color(0xFF1B5E20),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
