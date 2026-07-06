import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String region;
  final String zone;
  final String woreda;
  final String? profilePictureUrl;
  final String? telegramUsername;
  final String? whatsappNumber;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String role; // 'buyer' or 'seller' or ''
  final String password;

  UserModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.region,
    required this.zone,
    required this.woreda,
    this.profilePictureUrl,
    this.telegramUsername,
    this.whatsappNumber,
    this.isVerified = true,
    required this.createdAt,
    required this.updatedAt,
    this.role = '',
    this.password = '',
  });

  static DateTime parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      region: map['region'] ?? '',
      zone: map['zone'] ?? '',
      woreda: map['woreda'] ?? '',
      profilePictureUrl: map['profilePictureUrl'],
      telegramUsername: map['telegramUsername'],
      whatsappNumber: map['whatsappNumber'],
      isVerified: map['isVerified'] ?? true,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
      role: map['role'] ?? '',
      password: map['password'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'region': region,
      'zone': zone,
      'woreda': woreda,
      'profilePictureUrl': profilePictureUrl,
      'telegramUsername': telegramUsername,
      'whatsappNumber': whatsappNumber,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'role': role,
      'password': password,
    };
  }

  UserModel copyWith({
    String? name,
    String? phoneNumber,
    String? region,
    String? zone,
    String? woreda,
    String? profilePictureUrl,
    String? telegramUsername,
    String? whatsappNumber,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? role,
    String? password,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      region: region ?? this.region,
      zone: zone ?? this.zone,
      woreda: woreda ?? this.woreda,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      telegramUsername: telegramUsername ?? this.telegramUsername,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
      password: password ?? this.password,
    );
  }
}
