import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../../utils/order_state_machine.dart';
import '../../services/error_service.dart';

class OrderDetailView extends ConsumerStatefulWidget {
  const OrderDetailView({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends ConsumerState<OrderDetailView> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final orderData = await FirestoreService().getOrderById(widget.orderId);
      setState(() {
        _order = orderData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorService.getReadableError(context, e);
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange[800]!;
      case 'confirmed':
        return Colors.blue[800]!;
      case 'preparing':
        return Colors.amber[900]!;
      case 'shipped':
        return Colors.indigo[800]!;
      case 'delivered':
      case 'completed':
        return Colors.green[800]!;
      case 'cancelled':
        return Colors.red[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  Widget _buildStep(String title, bool isCompleted, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isCompleted
              ? const Color(0xFF1B5E20)
              : isActive
                  ? const Color(0xFFFBC02D)
                  : Colors.grey[300],
          child: isCompleted
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
              : Text(
                  '',
                  style: TextStyle(
                    color: isActive ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
            color: isActive || isCompleted ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTracker(String status) {
    int currentStepIndex = 0;
    if (status == 'confirmed') currentStepIndex = 1;
    if (status == 'preparing') currentStepIndex = 2;
    if (status == 'shipped') currentStepIndex = 3;
    if (status == 'delivered' || status == 'completed') currentStepIndex = 4;
    if (status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'This order has been cancelled.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStep('Pending', currentStepIndex > 0, currentStepIndex == 0),
          _buildLine(currentStepIndex > 0),
          _buildStep('Confirmed', currentStepIndex > 1, currentStepIndex == 1),
          _buildLine(currentStepIndex > 1),
          _buildStep('Preparing', currentStepIndex > 2, currentStepIndex == 2),
          _buildLine(currentStepIndex > 2),
          _buildStep('Shipped', currentStepIndex > 3, currentStepIndex == 3),
          _buildLine(currentStepIndex > 3),
          _buildStep('Delivered', currentStepIndex >= 4, currentStepIndex == 4),
        ],
      ),
    );
  }

  Widget _buildLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? const Color(0xFF1B5E20) : Colors.grey[300],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Tracking',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : _order == null
                  ? const Center(child: Text('Order not found.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Status Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${_order!['id'].toString().substring(0, 8).toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(_order!['status']).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _getStatusColor(_order!['status']).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  _order!['status'].toString().toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(_order!['status']),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Status Steps tracker
                          _buildTracker(_order!['status']),
                          const SizedBox(height: 24),

                          // Items List
                          const Text(
                            'Order Summary',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _order!['title'] ?? 'Product Name',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                      Text(
                                        '${_order!['price']} ETB',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Quantity', style: TextStyle(color: Colors.grey)),
                                      Text('${_order!['quantity']} ${_order!['unit'] ?? ''}'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text(
                                        '${OrderStateMachine.calculateTotal(
                                          double.tryParse(_order!['quantity'].toString()) ?? 0.0,
                                          double.tryParse(_order!['price'].toString()) ?? 0.0,
                                        )} ETB',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Color(0xFF1B5E20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Parties involved
                          const Text(
                            'Merchant Details',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE8F5E9),
                              child: Icon(Icons.storefront_rounded, color: Color(0xFF1B5E20)),
                            ),
                            title: Text(_order!['sellerName'] ?? 'Seller'),
                            subtitle: Text('ID: ${_order!['sellerId']}'),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
