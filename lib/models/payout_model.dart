class PayoutModel {
  final String id;
  final String orderId;
  final String sellerId;
  final String buyerId;
  final double totalAmount;
  final double sellerPrice;
  final double commissionAmount;
  final double sellerAmount;
  final String status; // 'pending_delivery', 'ready_for_payout', 'completed'
  final DateTime createdAt;
  final DateTime? deliveryConfirmedAt;
  final DateTime? processedAt;

  PayoutModel({
    required this.id,
    required this.orderId,
    required this.sellerId,
    required this.buyerId,
    required this.totalAmount,
    required this.sellerPrice,
    required this.commissionAmount,
    required this.sellerAmount,
    required this.status,
    required this.createdAt,
    this.deliveryConfirmedAt,
    this.processedAt,
  });

  factory PayoutModel.fromMap(Map<String, dynamic> map) {
    return PayoutModel(
      id: map['id'] ?? '',
      orderId: map['orderId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      sellerPrice: (map['sellerPrice'] as num?)?.toDouble() ?? 0.0,
      commissionAmount: (map['commissionAmount'] as num?)?.toDouble() ?? 0.0,
      sellerAmount: (map['sellerAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending_delivery',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
              ? map['createdAt']
              : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      deliveryConfirmedAt: map['deliveryConfirmedAt'] != null
          ? (map['deliveryConfirmedAt'] is DateTime
              ? map['deliveryConfirmedAt']
              : DateTime.tryParse(map['deliveryConfirmedAt'].toString()))
          : null,
      processedAt: map['processedAt'] != null
          ? (map['processedAt'] is DateTime
              ? map['processedAt']
              : DateTime.tryParse(map['processedAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'totalAmount': totalAmount,
      'sellerPrice': sellerPrice,
      'commissionAmount': commissionAmount,
      'sellerAmount': sellerAmount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (deliveryConfirmedAt != null)
        'deliveryConfirmedAt': deliveryConfirmedAt!.toIso8601String(),
      if (processedAt != null) 'processedAt': processedAt!.toIso8601String(),
    };
  }
}
