import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class SellerDashboardSubView extends ConsumerStatefulWidget {
  const SellerDashboardSubView({super.key});

  @override
  ConsumerState<SellerDashboardSubView> createState() => _SellerDashboardSubViewState();
}

class _SellerDashboardSubViewState extends ConsumerState<SellerDashboardSubView> {

  void _refresh() {
    setState(() {});
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

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seller Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().watchMyListings(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final listings = snapshot.data ?? [];
          final activeListings = listings.where((l) => l['status'] == 'active').toList();
          final soldListings = listings.where((l) => l['status'] == 'sold').toList();

          double totalSales = 0.0;
          for (var item in soldListings) {
            final price = double.tryParse(item['price'].toString()) ?? 0.0;
            final quantity = double.tryParse(item['quantity'].toString()) ?? 1.0;
            totalSales += (price * quantity);
          }

          final Map<String, double> categorySales = {};
          for (var item in soldListings) {
            final catName = item['categoryNameEn'] ?? 'Other';
            final quantity = double.tryParse(item['quantity'].toString()) ?? 1.0;
            categorySales[catName] = (categorySales[catName] ?? 0.0) + quantity;
          }

          return Container(
            color: const Color(0xFFF4F6F2),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${user.name}!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Here is your product sales analysis overview:',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Revenue',
                          value: '${totalSales.toStringAsFixed(0)} ETB',
                          icon: Icons.monetization_on_rounded,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Active Products',
                          value: '${activeListings.length}',
                          icon: Icons.grass_rounded,
                          color: Colors.blue[800]!,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Sold Items',
                          value: '${soldListings.length}',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sales by Category (Sold units)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (categorySales.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'No sales data recorded yet.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            ...categorySales.entries.map((entry) {
                              final totalUnits = categorySales.values.fold(0.0, (sum, val) => sum + val);
                              final percentage = totalUnits > 0 ? (entry.value / totalUnits) : 0.0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                        Text(
                                          '${entry.value.toStringAsFixed(0)} units (${(percentage * 100).toStringAsFixed(0)}%)',
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: percentage,
                                        minHeight: 8,
                                        backgroundColor: Colors.grey[200],
                                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ),
                  
                  // INCOMING SALES ORDERS SECTION
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: FirestoreService().getOrders(),
                    builder: (context, orderSnapshot) {
                      if (orderSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final orders = orderSnapshot.data ?? [];
                      final incomingOrders = orders.where((o) => o['sellerId'] == user.id).toList();

                      if (incomingOrders.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            'Incoming Sales Orders',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...incomingOrders.map((order) {
                            final price = double.tryParse(order['price'].toString()) ?? 0.0;
                            final qty = double.tryParse(order['quantity'].toString()) ?? 1.0;
                            final status = order['status'] ?? 'pending';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          order['title'] ?? 'Product',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        _buildStatusBadge(status),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Buyer: ${order['buyerName'] ?? 'Buyer'}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Subtotal: ${(price * qty).toStringAsFixed(0)} ETB (${qty.toStringAsFixed(0)} units)',
                                      style: const TextStyle(
                                        color: Color(0xFF1B5E20),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (status != 'cancelled' && status != 'delivered') ...[
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (status == 'pending' || status == 'confirmed')
                                            TextButton(
                                              onPressed: () async {
                                                await FirestoreService().updateOrderStatus(order['id'], 'cancelled');
                                                _refresh();
                                              },
                                              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                                            ),
                                          const SizedBox(width: 8),
                                          if (status == 'pending')
                                            ElevatedButton(
                                              onPressed: () async {
                                                await FirestoreService().updateOrderStatus(order['id'], 'confirmed');
                                                _refresh();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue[700],
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: const Text('Confirm'),
                                            ),
                                          if (status == 'confirmed')
                                            ElevatedButton(
                                              onPressed: () async {
                                                await FirestoreService().updateOrderStatus(order['id'], 'shipped');
                                                _refresh();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.indigo[700],
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: const Text('Ship'),
                                            ),
                                          if (status == 'shipped')
                                            ElevatedButton(
                                              onPressed: () async {
                                                await FirestoreService().updateOrderStatus(order['id'], 'delivered');
                                                _refresh();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green[700],
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: const Text('Deliver'),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
