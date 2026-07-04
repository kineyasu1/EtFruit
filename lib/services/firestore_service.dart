import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal() {
    _seedMockCategories();
  }

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Mock Database in memory
  final Map<String, UserModel> _mockUsers = {};
  final Map<String, Map<String, dynamic>> _mockListings = {};
  final List<Map<String, dynamic>> _mockCategories = [];
  final Map<String, Map<String, dynamic>> _mockChats = {};
  final Map<String, List<Map<String, dynamic>>> _mockMessages = {};
  final Map<String, Map<String, dynamic>> _mockTransactions = {};

  // Stream controllers for mock real-time updates
  final StreamController<List<Map<String, dynamic>>> _listingsStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _chatsStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final Map<String, StreamController<List<Map<String, dynamic>>>> _messagesStreamControllers = {};

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
        'suggestedUnits': ['quintal', 'kg']
      },
      {
        'id': 'pulses_oilseeds',
        'nameEn': 'Pulses & Oilseeds',
        'nameAm': 'የቅባት እህሎች እና ባቄላዎች',
        'nameOm': 'Kuduraa fi Muka',
        'nameSo': 'Saliidaha & Digirta',
        'nameTi': 'ጥረታት ዘይቲ',
        'suggestedUnits': ['quintal', 'kg']
      },
      {
        'id': 'coffee_cash_crops',
        'nameEn': 'Coffee & Cash Crops',
        'nameAm': 'ቡና እና የገንዘብ ሰብሎች',
        'nameOm': 'Buna fi Oomishaalee Gabaa',
        'nameSo': 'Bunka & Dalagyada Lacagta',
        'nameTi': 'ቡናን ካልኦት ዘፈርን',
        'suggestedUnits': ['kg', 'quintal', 'crate']
      },
      {
        'id': 'vegetables',
        'nameEn': 'Vegetables',
        'nameAm': 'አትክልቶች',
        'nameOm': 'Muduraa',
        'nameSo': 'Khudaarta',
        'nameTi': 'ኣሕምልቲ',
        'suggestedUnits': ['kg', 'crate', 'sack']
      },
      {
        'id': 'fruits',
        'nameEn': 'Fruits',
        'nameAm': 'ፍራፍሬዎች',
        'nameOm': 'Fuduraalee',
        'nameSo': 'Miroha',
        'nameTi': 'ፍራፍረታት',
        'suggestedUnits': ['kg', 'crate', 'piece']
      },
      {
        'id': 'livestock',
        'nameEn': 'Livestock',
        'nameAm': 'ከብት እና እንስሳት',
        'nameOm': 'Horii',
        'nameSo': 'Xoolaha',
        'nameTi': 'ኸብቲ',
        'suggestedUnits': ['head']
      },
      {
        'id': 'dairy_animal_products',
        'nameEn': 'Dairy & Animal Products',
        'nameAm': 'የወተት እና የእንስሳት ተዋጽኦዎች',
        'nameOm': 'Aanan fi Oomisha Hori',
        'nameSo': 'Caanaha & Waxyaabaha Xoolaha',
        'nameTi': 'ፍርያት ጸባን ከብትን',
        'suggestedUnits': ['liter', 'kg', 'piece']
      }
    ];
    _mockCategories.addAll(categoriesSeed);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    if (AuthService.isFirebaseAvailable) {
      final snap = await _firestore.collection('categories').get();
      if (snap.docs.isEmpty) {
        // Seed Firebase categories if empty
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
      return _mockUsers[uid];
    }
  }

  Future<void> saveUserProfile(UserModel user) async {
    if (AuthService.isFirebaseAvailable) {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } else {
      _mockUsers[user.id] = user;
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
        _notifyListingsChanged();
      }
    }
  }

  void _notifyListingsChanged() {
    final list = _mockListings.values.toList();
    list.sort((a, b) => (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp));
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
        
        // Local filtering for search text to support free-form checks
        if (searchKeyword != null && searchKeyword.isNotEmpty) {
          final keyword = searchKeyword.toLowerCase();
          list = list.where((item) {
            final title = (item['title'] ?? '').toString().toLowerCase();
            final desc = (item['description'] ?? '').toString().toLowerCase();
            return title.contains(keyword) || desc.contains(keyword);
          }).toList();
        }
        
        list.sort((a, b) => (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp));
        return list;
      });
    } else {
      // Memory watch
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

  Stream<List<Map<String, dynamic>>> watchMyListings(String sellerId) {
    if (AuthService.isFirebaseAvailable) {
      return _firestore
          .collection('listings')
          .where('sellerId', isEqualTo: sellerId)
          .snapshots()
          .map((snap) {
        var list = snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        list.sort((a, b) => (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp));
        return list;
      });
    } else {
      Timer.run(() => _notifyListingsChanged());
      return _listingsStreamController.stream.map((list) {
        return list.where((item) => item['sellerId'] == sellerId).toList();
      });
    }
  }

  Future<void> incrementReportCount(String listingId, {String? reporterId, String? reason}) async {
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
    final chatId = '${listingId}_${buyerId}_${sellerId}';
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
      _notifyChatsChanged();
    }
    return chatId;
  }

  void _notifyChatsChanged() {
    final list = _mockChats.values.toList();
    list.sort((a, b) => (b['lastMessageTime'] as Timestamp).compareTo(a['lastMessageTime'] as Timestamp));
    _chatsStreamController.add(list);
  }

  Stream<List<Map<String, dynamic>>> watchUserChats(String userId) {
    if (AuthService.isFirebaseAvailable) {
      return _firestore
          .collection('chats')
          .where('participantIds', arrayContains: userId)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
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
          .map((snap) => snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
    } else {
      if (!_messagesStreamControllers.containsKey(chatId)) {
        _messagesStreamControllers[chatId] = StreamController<List<Map<String, dynamic>>>.broadcast();
      }
      Timer.run(() => _notifyMessagesChanged(chatId));
      return _messagesStreamControllers[chatId]!.stream;
    }
  }

  void _notifyMessagesChanged(String chatId) {
    final list = _mockMessages[chatId] ?? [];
    list.sort((a, b) => (a['createdAt'] as Timestamp).compareTo(b['createdAt'] as Timestamp));
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
      // Memory Store
      if (!_mockMessages.containsKey(chatId)) {
        _mockMessages[chatId] = [];
      }
      _mockMessages[chatId]!.add(messageDoc);
      
      if (_mockChats.containsKey(chatId)) {
        _mockChats[chatId]!['lastMessageText'] = text;
        _mockChats[chatId]!['lastMessageSenderId'] = senderId;
        _mockChats[chatId]!['lastMessageTime'] = timestamp;
      }
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
      return _firestore.collection('transactions').doc(txId).snapshots().map((doc) => doc.data());
    } else {
      // Mock stream that emits updates
      return Stream.periodic(const Duration(seconds: 1), (_) => _mockTransactions[txId]);
    }
  }
}
