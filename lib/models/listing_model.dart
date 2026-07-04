import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String title;
  final String categoryId;
  final String categoryNameEn;
  final String categoryNameAm;
  final String categoryNameOm;
  final String categoryNameSo;
  final String categoryNameTi;
  final double quantity;
  final String unit;
  final double price;
  final bool isNegotiable;
  final String region;
  final String zone;
  final String woreda;
  final List<String> photoUrls;
  final String? description;
  final bool telegramContactEnabled;
  final bool whatsappContactEnabled;
  final bool inAppChatEnabled;
  final String status; // 'active', 'sold', 'deleted'
  final int reportCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ListingModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.categoryId,
    required this.categoryNameEn,
    required this.categoryNameAm,
    required this.categoryNameOm,
    required this.categoryNameSo,
    required this.categoryNameTi,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.isNegotiable,
    required this.region,
    required this.zone,
    required this.woreda,
    required this.photoUrls,
    this.description,
    required this.telegramContactEnabled,
    required this.whatsappContactEnabled,
    required this.inAppChatEnabled,
    this.status = 'active',
    this.reportCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ListingModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ListingModel(
      id: documentId,
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      title: map['title'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryNameEn: map['categoryNameEn'] ?? '',
      categoryNameAm: map['categoryNameAm'] ?? '',
      categoryNameOm: map['categoryNameOm'] ?? '',
      categoryNameSo: map['categoryNameSo'] ?? '',
      categoryNameTi: map['categoryNameTi'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      isNegotiable: map['isNegotiable'] ?? false,
      region: map['region'] ?? '',
      zone: map['zone'] ?? '',
      woreda: map['woreda'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      description: map['description'],
      telegramContactEnabled: map['telegramContactEnabled'] ?? true,
      whatsappContactEnabled: map['whatsappContactEnabled'] ?? true,
      inAppChatEnabled: map['inAppChatEnabled'] ?? true,
      status: map['status'] ?? 'active',
      reportCount: map['reportCount'] ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'title': title,
      'categoryId': categoryId,
      'categoryNameEn': categoryNameEn,
      'categoryNameAm': categoryNameAm,
      'categoryNameOm': categoryNameOm,
      'categoryNameSo': categoryNameSo,
      'categoryNameTi': categoryNameTi,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'isNegotiable': isNegotiable,
      'region': region,
      'zone': zone,
      'woreda': woreda,
      'photoUrls': photoUrls,
      'description': description,
      'telegramContactEnabled': telegramContactEnabled,
      'whatsappContactEnabled': whatsappContactEnabled,
      'inAppChatEnabled': inAppChatEnabled,
      'status': status,
      'reportCount': reportCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
