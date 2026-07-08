import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal() {
    _seedMockCategories();
    _loadLocalData();
  }

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Mock Database in memory
  final Map<String, UserModel> _mockUsers = {};
  final Map<String, Map<String, dynamic>> _mockListings = {};
  final List<Map<String, dynamic>> _mockCategories = [];
  final Map<String, Map<String, dynamic>> _mockChats = {};
  final Map<String, List<Map<String, dynamic>>> _mockMessages = {};
  final Map<String, Map<String, dynamic>> _mockTransactions = {};

  // Shopping Cart & Orders local storage caches
  final List<Map<String, dynamic>> _mockCart = [];
  final List<Map<String, dynamic>> _mockOrders = [];
  final List<Map<String, dynamic>> _mockReviews = [];

  // Stream controllers for mock real-time updates
  final StreamController<List<Map<String, dynamic>>> _listingsStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _chatsStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final Map<String, StreamController<List<Map<String, dynamic>>>>
      _messagesStreamControllers = {};

  // -------------------------------------------------------------
  // Categories (Seed Data)
  // -------------------------------------------------------------
  void _seedMockCategories() {
    final categoriesSeed = [
      {
        'id': 'cereals_grains',
        'nameEn': 'Cereals & Grains',
        'nameAm': 'እህል እና ጥራጥሬዎች',
        'nameOm': 'Midhaan',
        'nameSo': 'Mishaarka & Firileyda',
        'nameTi': 'ጥረታት',
        'suggestedUnits': ['quintal', 'kg'],
      },
      {
        'id': 'pulses_oilseeds',
        'nameEn': 'Pulses & Oilseeds',
        'nameAm': 'የቅባት እህሎች እና ባቄላዎች',
        'nameOm': 'Kuduraa fi Muka',
        'nameSo': 'Saliidaha & Digirta',
        'nameTi': 'ጥረታት ዘይቲ',
        'suggestedUnits': ['quintal', 'kg'],
      },
      {
        'id': 'coffee_cash_crops',
        'nameEn': 'Coffee & Cash Crops',
        'nameAm': 'ቡና እና የገንዘብ ሰብሎች',
        'nameOm': 'Buna fi Oomishaalee Gabaa',
        'nameSo': 'Bunka & Dalagyada Lacagta',
        'nameTi': 'ቡናን ካልኦት ዘፈርን',
        'suggestedUnits': ['kg', 'quintal', 'crate'],
      },
      {
        'id': 'vegetables',
        'nameEn': 'Vegetables',
        'nameAm': 'አትክልቶች',
        'nameOm': 'Muduraa',
        'nameSo': 'Khudaarta',
        'nameTi': 'ኣሕምልቲ',
        'suggestedUnits': ['kg', 'crate', 'sack'],
      },
      {
        'id': 'fruits',
        'nameEn': 'Fruits',
        'nameAm': 'ፍራፍሬዎች',
        'nameOm': 'Fuduraalee',
        'nameSo': 'Miroha',
        'nameTi': 'ፍራፍረታት',
        'suggestedUnits': ['kg', 'crate', 'piece'],
      },
      {
        'id': 'livestock',
        'nameEn': 'Livestock',
        'nameAm': 'ከብት እና እንስሳት',
        'nameOm': 'Horii',
        'nameSo': 'Xoolaha',
        'nameTi': 'ኸብቲ',
        'suggestedUnits': ['head'],
      },
      {
        'id': 'dairy_animal_products',
        'nameEn': 'Dairy & Animal Products',
        'nameAm': 'የወተት እና የእንስሳት ተዋጽኦዎች',
        'nameOm': 'Aanan fi Oomisha Hori',
        'nameSo': 'Caanaha & Waxyaabaha Xoolaha',
        'nameTi': 'ፍርያት ጸባን ከብትን',
        'suggestedUnits': ['liter', 'kg', 'piece'],
      },
    ];
    _mockCategories.addAll(categoriesSeed);
  }

  // -------------------------------------------------------------
  // Local Database Persistence (JSON/SharedPreferences)
  // -------------------------------------------------------------
  static dynamic _convertJsonToFirestoreTypes(dynamic value) {
    if (value is Map) {
      final Map<String, dynamic> result = {};
      value.forEach((key, val) {
        if ((key == 'createdAt' || key == 'updatedAt' || key == 'lastMessageTime') && val is String) {
          final dt = DateTime.tryParse(val);
          if (dt != null) {
            result[key] = Timestamp.fromDate(dt);
          } else {
            result[key] = val;
          }
        } else {
          result[key] = _convertJsonToFirestoreTypes(val);
        }
      });
      return result;
    } else if (value is List) {
      return value.map((item) => _convertJsonToFirestoreTypes(item)).toList();
    }
    return value;
  }

  static dynamic _convertFirestoreTypesToJson(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is Map) {
      final Map<String, dynamic> result = {};
      value.forEach((key, val) {
        result[key] = _convertFirestoreTypesToJson(val);
      });
      return result;
    } else if (value is List) {
      return value.map((item) => _convertFirestoreTypesToJson(item)).toList();
    }
    return value;
  }

  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final usersJson = prefs.getString('mock_users');
      if (usersJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(usersJson);
        _mockUsers.clear();
        decoded.forEach((key, value) {
          _mockUsers[key] = UserModel.fromMap(Map<String, dynamic>.from(value), key);
        });
      }

      final listingsJson = prefs.getString('mock_listings');
      if (listingsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(listingsJson);
        _mockListings.clear();
        decoded.forEach((key, value) {
          _mockListings[key] = Map<String, dynamic>.from(_convertJsonToFirestoreTypes(value));
        });
      }

      final chatsJson = prefs.getString('mock_chats');
      if (chatsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(chatsJson);
        _mockChats.clear();
        decoded.forEach((key, value) {
          _mockChats[key] = Map<String, dynamic>.from(_convertJsonToFirestoreTypes(value));
        });
      }

      final messagesJson = prefs.getString('mock_messages');
      if (messagesJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(messagesJson);
        _mockMessages.clear();
        decoded.forEach((key, value) {
          final list = (value as List).map((item) => Map<String, dynamic>.from(_convertJsonToFirestoreTypes(item))).toList();
          _mockMessages[key] = list;
        });
      }

      final txJson = prefs.getString('mock_transactions');
      if (txJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(txJson);
        _mockTransactions.clear();
        decoded.forEach((key, value) {
          _mockTransactions[key] = Map<String, dynamic>.from(_convertJsonToFirestoreTypes(value));
        });
      }

      final cartJson = prefs.getString('mock_cart');
      if (cartJson != null) {
        final List decoded = jsonDecode(cartJson);
        _mockCart.clear();
        _mockCart.addAll(decoded.map((item) => Map<String, dynamic>.from(item)).toList());
      }

      final ordersJson = prefs.getString('mock_orders');
      if (ordersJson != null) {
        final List decoded = jsonDecode(ordersJson);
        _mockOrders.clear();
        _mockOrders.addAll(decoded.map((item) => Map<String, dynamic>.from(_convertJsonToFirestoreTypes(item))).toList());
      }

      final reviewsJson = prefs.getString('mock_reviews');
      if (reviewsJson != null) {
        final List decoded = jsonDecode(reviewsJson);
        _mockReviews.clear();
        _mockReviews.addAll(decoded.map((item) => Map<String, dynamic>.from(_convertJsonToFirestoreTypes(item))).toList());
      }

      _notifyListingsChanged();
      _notifyChatsChanged();
    } catch (e) {
      debugPrint('Error loading local data: $e');
    }
  }

  Future<void> _saveLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final Map<String, dynamic> usersMap = {};
      _mockUsers.forEach((key, value) {
        usersMap[key] = value.toMap();
        usersMap[key]['createdAt'] = value.createdAt.toIso8601String();
        usersMap[key]['updatedAt'] = value.updatedAt.toIso8601String();
      });
      await prefs.setString('mock_users', jsonEncode(usersMap));
      await prefs.setString('mock_listings', jsonEncode(_convertFirestoreTypesToJson(_mockListings)));
      await prefs.setString('mock_chats', jsonEncode(_convertFirestoreTypesToJson(_mockChats)));
      await prefs.setString('mock_messages', jsonEncode(_convertFirestoreTypesToJson(_mockMessages)));
      await prefs.setString('mock_transactions', jsonEncode(_convertFirestoreTypesToJson(_mockTransactions)));
      await prefs.setString('mock_cart', jsonEncode(_mockCart));
      await prefs.setString('mock_orders', jsonEncode(_convertFirestoreTypesToJson(_mockOrders)));
      await prefs.setString('mock_reviews', jsonEncode(_convertFirestoreTypesToJson(_mockReviews)));
    } catch (e) {
      debugPrint('Error saving local data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    if (AuthService.isFirebaseAvailable) {
      final snap = await _firestore.collection('categories').get();
      if (snap.docs.isEmpty) {
        for (var cat in _mockCategories) {
          await _firestore.collection('categories').doc(cat['id']).set(cat);
        }
        return _mockCategories;
      }
      return snap.docs.map((doc) => doc.data()).toList();
    } else {
      return _mockCategories;
    }
  }

  // -------------------------------------------------------------
  // User Profile
  // -------------------------------------------------------------
  Future<UserModel?> getUserProfile(String uid) async {
    if (AuthService.isFirebaseAvailable) {
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!, doc.id);
        }
      } catch (e) {
        debugPrint('Error getting user profile: $e');
      }
      return null;
    } else {
      await _loadLocalData();
      return _mockUsers[uid];
    }
  }

  Future<UserModel?> getMockUserByPhoneNumber(String phoneNumber) async {
    await _loadLocalData();
    for (var user in _mockUsers.values) {
      if (user.phoneNumber == phoneNumber) {
        return user;
      }
    }
    return null;
  }

  Future<void> saveUserProfile(UserModel user) async {
    if (AuthService.isFirebaseAvailable) {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } else {
      _mockUsers[user.id] = user;
      await _saveLocalData();
    }
  }

  // -------------------------------------------------------------
  // Listings
  // -------------------------------------------------------------
  Future<void> saveListing(Map<String, dynamic> listingData) async {
    final id = listingData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    listingData['id'] = id;
    listingData['createdAt'] = listingData['createdAt'] ?? Timestamp.now();
    listingData['updatedAt'] = Timestamp.now();

    if (AuthService.isFirebaseAvailable) {
      await _firestore.collection('listings').doc(id).set(listingData);
    } else {
      _mockListings[id] = listingData;
      await _saveLocalData();
      _notifyListingsChanged();
    }
  }

  Future<void> updateListingStatus(String listingId, String status) async {
    if (AuthService.isFirebaseAvailable) {
      await _firestore.collection('listings').doc(listingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      if (_mockListings.containsKey(listingId)) {
        _mockListings[listingId]!['status'] = status;
        _mockListings[listingId]!['updatedAt'] = Timestamp.now();
        await _saveLocalData();
        _notifyListingsChanged();
      }
    }
  }

  void _notifyListingsChanged() {
    final list = _mockListings.values.toList();
    list.sort(
      (a, b) => (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp),
    );
    _listingsStreamController.add(list);
  }

  Stream<List<Map<String, dynamic>>> watchListings({
    String? categoryId,
    String? region,
    String? searchKeyword,
  }) {
    if (AuthService.isFirebaseAvailable) {
      Query query = _firestore.collection('listings').where('status', isEqualTo: 'active');
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }
      if (region != null && region.isNotEmpty) {
        query = query.where('region', isEqualTo: region);
      }
      return query.snapshots().map((snap) {
        var list = snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

        if (searchKeyword != null && searchKeyword.isNotEmpty) {
          final keyword = searchKeyword.toLowerCase();
          list = list.where((item) {
            final title = (item['title'] ?? '').toString().toLowerCase();
            final desc = (item['description'] ?? '').toString().toLowerCase();
            return title.contains(keyword) || desc.contains(keyword);
          }).toList();
        }

        list.sort(
          (a, b) => (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp),
        );
        return list;
      });
    } else {
      Timer.run(() => _notifyListingsChanged());
      return _listingsStreamController.stream.map((list) {
        var filtered = list.where((item) => item['status'] == 'active').toList();
        if (categoryId != null && categoryId.isNotEmpty) {
          filtered = filtered.where((item) => item['categoryId'] == categoryId).toList();
        }
        if (region != null && region.isNotEmpty) {
          filtered = filtered.where((item) => item['region'] == region).toList();
        }
        if (searchKeyword != null && searchKeyword.isNotEmpty) {
          final keyword = searchKeyword.toLowerCase();
          filtered = filtered.where((item) {
            final title = (item['title'] ?? '').toString().toLowerCase();
            final desc = (item['description'] ?? '').toString().toLowerCase();
            return title.contains(keyword) || desc.contains(keyword);
          }).toList();
        }
        return filtered;
      });
    }
  }

  Future<ListingsPageResult> getListingsPage({
    String? categoryId,
    String? region,
    String? searchKeyword,
    dynamic startAfter,
    int limit = 6,
  }) async {
    if (AuthService.isFirebaseAvailable) {
      Query query = _firestore.collection('listings')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true);

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }
      if (region != null && region.isNotEmpty) {
        query = query.where('region', isEqualTo: region);
      }

      int queryLimit = limit;
      if (searchKeyword != null && searchKeyword.isNotEmpty) {
        queryLimit = limit * 4; // Fetch more since client-side filtering will discard non-matching titles/descriptions
      }

      Query pageQuery = query.limit(queryLimit + 1);
      if (startAfter != null && startAfter is DocumentSnapshot) {
        pageQuery = query.startAfterDocument(startAfter).limit(queryLimit + 1);
      }

      final snapshot = await pageQuery.get();
      final List<DocumentSnapshot> docs = List.from(snapshot.docs);
      
      var listingsList = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      
      // Client-side filtering for keywords
      if (searchKeyword != null && searchKeyword.isNotEmpty) {
        final keyword = searchKeyword.toLowerCase();
        listingsList = listingsList.where((item) {
          final title = (item['title'] ?? '').toString().toLowerCase();
          final desc = (item['description'] ?? '').toString().toLowerCase();
          return title.contains(keyword) || desc.contains(keyword);
        }).toList();
      }

      final bool hasMore = docs.length > queryLimit;
      if (hasMore && docs.isNotEmpty) {
        docs.removeLast();
        if (listingsList.length > limit) {
          listingsList = listingsList.sublist(0, limit);
        }
      }

      final lastDoc = docs.isNotEmpty ? docs.last : null;

      return ListingsPageResult(
        listings: listingsList,
        cursor: lastDoc,
        hasMore: hasMore,
      );
    } else {
      await _loadLocalData();
      var filtered = _mockListings.values.where((item) => item['status'] == 'active').toList();
      if (categoryId != null && categoryId.isNotEmpty) {
        filtered = filtered.where((item) => item['categoryId'] == categoryId).toList();
      }
      if (region != null && region.isNotEmpty) {
        filtered = filtered.where((item) => item['region'] == region).toList();
      }
      if (searchKeyword != null && searchKeyword.isNotEmpty) {
        final keyword = searchKeyword.toLowerCase();
        filtered = filtered.where((item) {
          final title = (item['title'] ?? '').toString().toLowerCase();
          final desc = (item['description'] ?? '').toString().toLowerCase();
          return title.contains(keyword) || desc.contains(keyword);
        }).toList();
      }

      // Sort descending by createdAt
      filtered.sort((a, b) {
        final dateA = UserModel.parseDateTime(a['createdAt']);
        final dateB = UserModel.parseDateTime(b['createdAt']);
        return dateB.compareTo(dateA);
      });

      int startIndex = 0;
      if (startAfter != null && startAfter is int) {
        startIndex = startAfter;
      }

      final endIndex = startIndex + limit;
      final listingsList = filtered.sublist(
        startIndex,
        endIndex > filtered.length ? filtered.length : endIndex,
      );
      final hasMore = endIndex < filtered.length;

      return ListingsPageResult(
        listings: listingsList,
        cursor: hasMore ? endIndex : null,
        hasMore: hasMore,
      );
    }
  }

  Stream<List<Map<String, dynamic>>> watchMyListings(String sellerId) {
    if (AuthService.isFirebaseAvailable) {
      return _firestore
          .collection('listings')
          .where('sellerId', isEqualTo: sellerId)
          .snapshots()
          .map((snap) {
        var list = snap.docs.map((doc) => doc.data()).toList();
        list.sort(
          (a, b) => (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp),
        );
        return list;
      });
    } else {
      Timer.run(() => _notifyListingsChanged());
      return _listingsStreamController.stream.map((list) {
        return list.where((item) => item['sellerId'] == sellerId).toList();
      });
    }
  }

  Future<void> incrementReportCount(
    String listingId, {
    String? reporterId,
    String? reason,
  }) async {
    final reportId = 'rep_${DateTime.now().millisecondsSinceEpoch}';
    final reportDoc = {
      'id': reportId,
      'listingId': listingId,
      'reporterId': reporterId ?? 'anonymous',
      'reason': reason ?? 'not_specified',
      'createdAt': Timestamp.now(),
    };

    if (AuthService.isFirebaseAvailable) {
      final batch = _firestore.batch();
      batch.set(_firestore.collection('reports').doc(reportId), reportDoc);
      batch.update(_firestore.collection('listings').doc(listingId), {
        'reportCount': FieldValue.increment(1),
      });
      await batch.commit();
    } else {
      if (_mockListings.containsKey(listingId)) {
        final current = _mockListings[listingId]!['reportCount'] ?? 0;
        _mockListings[listingId]!['reportCount'] = current + 1;
        await _saveLocalData();
      }
    }
  }

  // -------------------------------------------------------------
  // Chats
  // -------------------------------------------------------------
  Future<String> startChat({
    required String listingId,
    required String listingTitle,
    required String? listingPhotoUrl,
    required String buyerId,
    required String sellerId,
  }) async {
    final chatId = '${listingId}_${buyerId}_$sellerId';
    final chatDoc = {
      'id': chatId,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'listingPhotoUrl': listingPhotoUrl,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'participantIds': [buyerId, sellerId],
      'lastMessageText': '',
      'lastMessageSenderId': '',
      'lastMessageTime': Timestamp.now(),
      'createdAt': Timestamp.now(),
    };

    if (AuthService.isFirebaseAvailable) {
      await _firestore.collection('chats').doc(chatId).set(chatDoc, SetOptions(merge: true));
    } else {
      _mockChats[chatId] = chatDoc;
      await _saveLocalData();
      _notifyChatsChanged();
    }
    return chatId;
  }

  void _notifyChatsChanged() {
    final list = _mockChats.values.toList();
    list.sort(
      (a, b) => (b['lastMessageTime'] as Timestamp).compareTo(a['lastMessageTime'] as Timestamp),
    );
    _chatsStreamController.add(list);
  }

  Stream<List<Map<String, dynamic>>> watchUserChats(String userId) {
    if (AuthService.isFirebaseAvailable) {
      return _firestore
          .collection('chats')
          .where('participantIds', arrayContains: userId)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => doc.data()).toList());
    } else {
      Timer.run(() => _notifyChatsChanged());
      return _chatsStreamController.stream.map((list) {
        return list.where((chat) => (chat['participantIds'] as List).contains(userId)).toList();
      });
    }
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String chatId) {
    if (AuthService.isFirebaseAvailable) {
      return _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => doc.data()).toList());
    } else {
      if (!_messagesStreamControllers.containsKey(chatId)) {
        _messagesStreamControllers[chatId] =
            StreamController<List<Map<String, dynamic>>>.broadcast();
      }
      Timer.run(() => _notifyMessagesChanged(chatId));
      return _messagesStreamControllers[chatId]!.stream;
    }
  }

  void _notifyMessagesChanged(String chatId) {
    final list = _mockMessages[chatId] ?? [];
    list.sort(
      (a, b) => (a['createdAt'] as Timestamp).compareTo(b['createdAt'] as Timestamp),
    );
    _messagesStreamControllers[chatId]?.add(list);
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final timestamp = Timestamp.now();
    final messageDoc = {
      'id': messageId,
      'senderId': senderId,
      'text': text,
      'createdAt': timestamp,
    };

    if (AuthService.isFirebaseAvailable) {
      final batch = _firestore.batch();
      final chatRef = _firestore.collection('chats').doc(chatId);
      final msgRef = chatRef.collection('messages').doc(messageId);

      batch.set(msgRef, messageDoc);
      batch.update(chatRef, {
        'lastMessageText': text,
        'lastMessageSenderId': senderId,
        'lastMessageTime': timestamp,
      });
      await batch.commit();
    } else {
      if (!_mockMessages.containsKey(chatId)) {
        _mockMessages[chatId] = [];
      }
      _mockMessages[chatId]!.add(messageDoc);

      if (_mockChats.containsKey(chatId)) {
        _mockChats[chatId]!['lastMessageText'] = text;
        _mockChats[chatId]!['lastMessageSenderId'] = senderId;
        _mockChats[chatId]!['lastMessageTime'] = timestamp;
      }
      await _saveLocalData();
      _notifyMessagesChanged(chatId);
      _notifyChatsChanged();
    }
  }

  // -------------------------------------------------------------
  // Transactions
  // -------------------------------------------------------------
  Future<void> saveTransaction(Map<String, dynamic> txData) async {
    final id = txData['id'];
    txData['createdAt'] = txData['createdAt'] ?? Timestamp.now();
    txData['updatedAt'] = Timestamp.now();

    if (AuthService.isFirebaseAvailable) {
      await _firestore.collection('transactions').doc(id).set(txData);
    } else {
      _mockTransactions[id] = txData;
      await _saveLocalData();
    }
  }

  Future<Map<String, dynamic>?> getTransaction(String txId) async {
    if (AuthService.isFirebaseAvailable) {
      final doc = await _firestore.collection('transactions').doc(txId).get();
      return doc.data();
    } else {
      return _mockTransactions[txId];
    }
  }

  Stream<Map<String, dynamic>?> watchTransaction(String txId) {
    if (AuthService.isFirebaseAvailable) {
      return _firestore
          .collection('transactions')
          .doc(txId)
          .snapshots()
          .map((doc) => doc.data());
    } else {
      return Stream.periodic(
        const Duration(seconds: 1),
        (_) => _mockTransactions[txId],
      );
    }
  }

  // -------------------------------------------------------------
  // Shopping Cart & Orders
  // -------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getCartItems() async {
    if (AuthService.isFirebaseAvailable) {
      final uid = AuthService().currentUid;
      if (uid == null) return [];
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cart')
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } else {
      await _loadLocalData();
      return _mockCart;
    }
  }

  Future<void> addToCart(Map<String, dynamic> item) async {
    if (AuthService.isFirebaseAvailable) {
      final uid = AuthService().currentUid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cart')
          .doc(item['listingId'])
          .set(item);
    } else {
      final index = _mockCart.indexWhere((element) => element['listingId'] == item['listingId']);
      if (index >= 0) {
        _mockCart[index]['quantity'] = (_mockCart[index]['quantity'] ?? 1.0) + (item['quantity'] ?? 1.0);
      } else {
        _mockCart.add(item);
      }
      await _saveLocalData();
    }
  }

  Future<void> removeFromCart(String listingId) async {
    if (AuthService.isFirebaseAvailable) {
      final uid = AuthService().currentUid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cart')
          .doc(listingId)
          .delete();
    } else {
      _mockCart.removeWhere((element) => element['listingId'] == listingId);
      await _saveLocalData();
    }
  }

  Future<void> clearCart() async {
    if (AuthService.isFirebaseAvailable) {
      final uid = AuthService().currentUid;
      if (uid == null) return;
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cart');
      final snapshot = await cartRef.get();
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } else {
      _mockCart.clear();
      await _saveLocalData();
    }
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    if (AuthService.isFirebaseAvailable) {
      final uid = AuthService().currentUid;
      if (uid == null) return [];

      final query1 = await FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: uid)
          .get();
      final query2 = await FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: uid)
          .get();

      final List<Map<String, dynamic>> list = [];
      for (var doc in query1.docs) {
        list.add(doc.data());
      }
      for (var doc in query2.docs) {
        if (!list.any((element) => element['id'] == doc.id)) {
          list.add(doc.data());
        }
      }
      return list;
    } else {
      await _loadLocalData();
      return _mockOrders;
    }
  }

  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    if (AuthService.isFirebaseAvailable) {
      final doc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      return doc.data();
    } else {
      await _loadLocalData();
      final idx = _mockOrders.indexWhere((element) => element['id'] == orderId);
      return idx >= 0 ? _mockOrders[idx] : null;
    }
  }

  Future<void> createOrder(Map<String, dynamic> order) async {
    if (AuthService.isFirebaseAvailable) {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order['id'])
          .set(order);
    } else {
      _mockOrders.add(order);
      await _saveLocalData();
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    if (AuthService.isFirebaseAvailable) {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _loadLocalData();
      final idx = _mockOrders.indexWhere((element) => element['id'] == orderId);
      if (idx >= 0) {
        _mockOrders[idx]['status'] = newStatus;
        _mockOrders[idx]['updatedAt'] = DateTime.now().toIso8601String();
        await _saveLocalData();
      }
    }
  }

  Future<void> submitReview(Map<String, dynamic> review) async {
    if (AuthService.isFirebaseAvailable) {
      final batch = FirebaseFirestore.instance.batch();
      
      final reviewRef = FirebaseFirestore.instance.collection('reviews').doc(review['id']);
      batch.set(reviewRef, review);

      final orderRef = FirebaseFirestore.instance.collection('orders').doc(review['orderId']);
      batch.update(orderRef, {'isRated': true});

      await batch.commit();
    } else {
      await _loadLocalData();
      _mockReviews.add(review);
      
      final idx = _mockOrders.indexWhere((element) => element['id'] == review['orderId']);
      if (idx >= 0) {
        _mockOrders[idx]['isRated'] = true;
      }
      
      await _saveLocalData();
    }
  }

  Future<List<Map<String, dynamic>>> getSellerReviews(String sellerId) async {
    if (AuthService.isFirebaseAvailable) {
      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('sellerId', isEqualTo: sellerId)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } else {
      await _loadLocalData();
      return _mockReviews.where((element) => element['sellerId'] == sellerId).toList();
    }
  }
}

class ListingsPageResult {
  final List<Map<String, dynamic>> listings;
  final dynamic cursor;
  final bool hasMore;

  ListingsPageResult({
    required this.listings,
    required this.cursor,
    required this.hasMore,
  });
}
