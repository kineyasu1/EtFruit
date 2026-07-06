import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../chat/chat_detail_view.dart';
import '../payment/payment_checkout_view.dart';
import 'package:agrimarketmob/l10n/app_localizations.dart';

class ListingDetailView extends ConsumerStatefulWidget {
  const ListingDetailView({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<ListingDetailView> createState() => _ListingDetailViewState();
}

class _ListingDetailViewState extends ConsumerState<ListingDetailView> {
  int _currentPhotoIndex = 0;
  bool _isLoadingSeller = true;
  Map<String, dynamic>? _listing;
  UserModel? _sellerProfile;
  List<Map<String, dynamic>> _sellerReviews = [];
  double _averageRating = 0.0;

  void _loadReviews(String sellerId) async {
    final reviews = await FirestoreService().getSellerReviews(sellerId);
    if (mounted) {
      setState(() {
        _sellerReviews = reviews;
        if (reviews.isNotEmpty) {
          double sum = reviews.fold(0.0, (acc, r) => acc + (double.tryParse(r['rating'].toString()) ?? 0.0));
          _averageRating = sum / reviews.length;
        } else {
          _averageRating = 0.0;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadListingDetails();
  }

  void _loadListingDetails() async {
    // Get listing snapshot from Firestore/Mock
    final stream = FirestoreService().watchListings();
    final subscription = stream.listen((listings) async {
      final match = listings.firstWhere(
        (l) => l['id'] == widget.listingId,
        orElse: () => {},
      );

      if (match.isNotEmpty) {
        setState(() {
          _listing = match;
        });

        // Load seller profile to fetch Telegram/WhatsApp handles & Member since info
        final sellerId = match['sellerId'];
        if (sellerId != null) {
          final profile = await FirestoreService().getUserProfile(sellerId);
          _loadReviews(sellerId);
          if (mounted) {
            setState(() {
              _sellerProfile = profile;
              _isLoadingSeller = false;
            });
          }
        }
      } else {
        // If not in active listings, check user's own listings
        final user = ref.read(authProvider);
        if (user != null) {
          final myListingsStream = FirestoreService().watchMyListings(user.id);
          final mySubscription = myListingsStream.listen((myListings) async {
            final myMatch = myListings.firstWhere(
              (l) => l['id'] == widget.listingId,
              orElse: () => {},
            );
            if (myMatch.isNotEmpty && mounted) {
              _loadReviews(user.id);
              setState(() {
                _listing = myMatch;
                _sellerProfile = user;
                _isLoadingSeller = false;
              });
            }
          });
          mySubscription.resume();
        }
      }
    });
    subscription.resume();
  }

  void _launchTelegram() async {
    if (_sellerProfile?.telegramUsername == null) return;
    final username = _sellerProfile!.telegramUsername!;
    final url = Uri.parse('https://t.me/$username');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Telegram')),
        );
      }
    }
  }

  void _launchWhatsApp() async {
    if (_sellerProfile?.whatsappNumber == null) return;
    final number = _sellerProfile!.whatsappNumber!.replaceAll('+', '');
    final title = _listing?['title'] ?? 'listing';
    final text = Uri.encodeComponent(
      "Hi, I'm interested in your '$title' listing on FarmLink",
    );
    final url = Uri.parse('https://wa.me/$number?text=$text');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  void _startInAppChat() async {
    final currentUser = ref.read(authProvider);
    if (currentUser == null || _listing == null) return;

    if (currentUser.id == _listing!['sellerId']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message yourself!')),
      );
      return;
    }

    setState(() {});

    final photoUrls = List<String>.from(_listing!['photoUrls'] ?? []);
    final photoUrl = photoUrls.isNotEmpty ? photoUrls.first : null;

    final chatId = await FirestoreService().startChat(
      listingId: _listing!['id'],
      listingTitle: _listing!['title'],
      listingPhotoUrl: photoUrl,
      buyerId: currentUser.id,
      sellerId: _listing!['sellerId'],
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailView(
            chatId: chatId,
            otherUserName: _sellerProfile?.name ?? 'Seller',
          ),
        ),
      );
    }
  }

  void _paySellerDirect() {
    if (_listing == null || _sellerProfile == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentCheckoutView(
          listingId: _listing!['id'],
          listingTitle: _listing!['title'],
          price: _listing!['price'],
          sellerId: _listing!['sellerId'],
          sellerName: _sellerProfile!.name,
        ),
      ),
    );
  }

  void _reportListingPopup() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.reportReason),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.scamFraud),
                onTap: () => _submitReport(l10n.scamFraud),
              ),
              ListTile(
                title: Text(l10n.abusiveContent),
                onTap: () => _submitReport(l10n.abusiveContent),
              ),
              ListTile(
                title: Text(l10n.incorrectPrice),
                onTap: () => _submitReport(l10n.incorrectPrice),
              ),
              ListTile(
                title: Text(l10n.other),
                onTap: () => _submitReport(l10n.other),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitReport(String reason) async {
    Navigator.pop(context); // Close dialog
    final l10n = AppLocalizations.of(context);

    if (_listing != null) {
      await FirestoreService().incrementReportCount(
        _listing!['id'],
        reporterId: ref.read(authProvider)?.id,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.reportSuccess)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_listing == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final l10n = AppLocalizations.of(context);
    final user = ref.read(authProvider);

    final photoUrls = List<String>.from(_listing!['photoUrls'] ?? []);
    final isNegotiable = _listing!['isNegotiable'] ?? false;
    final isMyListing = user?.id == _listing!['sellerId'];

    // Formatting date
    final date = _listing!['createdAt'] is Timestamp
        ? (_listing!['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final dateString = '${date.day}/${date.month}/${date.year}';

    final sellerDate = _sellerProfile?.createdAt ?? DateTime.now();
    final sellerDateString = '${sellerDate.month}/${sellerDate.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.listingDetails),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isMyListing)
            IconButton(
              icon: const Icon(Icons.flag_outlined, color: Colors.white),
              onPressed: _reportListingPopup,
              tooltip: l10n.reportListing,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Photo Carousel
                  if (photoUrls.isNotEmpty)
                    Stack(
                      children: [
                        SizedBox(
                          height: 250,
                          child: PageView.builder(
                            itemCount: photoUrls.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPhotoIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final pUrl = photoUrls[index];
                              return pUrl.startsWith('http')
                                  ? Image.network(
                                      pUrl,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.green[50],
                                        child: const Icon(
                                          Icons.grass_rounded,
                                          size: 80,
                                          color: Colors.green,
                                        ),
                                      ),
                                    )
                                  : Image.file(
                                      File(pUrl),
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.green[50],
                                        child: const Icon(
                                          Icons.grass_rounded,
                                          size: 80,
                                          color: Colors.green,
                                        ),
                                      ),
                                    );
                            },
                          ),
                        ),
                        if (photoUrls.length > 1)
                          Positioned(
                            bottom: 12,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_currentPhotoIndex + 1}/${photoUrls.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                  // Product details card
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _listing!['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isNegotiable)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFBC02D),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      l10n.negotiable,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_listing!['price']} ETB / ${_listing!['unit']}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.shopping_basket_outlined,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${l10n.quantity}: ${_listing!['quantity']} ${_listing!['unit']}',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${l10n.location}: ${_listing!['region']}, ${_listing!['zone']}, ${_listing!['woreda']}',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Posted: $dateString',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Description
                  if (_listing!['description'] != null &&
                      _listing!['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _listing!['description'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Seller Info Card
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _isLoadingSeller
                            ? const Center(child: CircularProgressIndicator())
                            : Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.green[50],
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 32,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _sellerProfile?.name ?? 'Seller',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: Colors.blue,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              l10n.verifiedPhone,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_sellerReviews.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          GestureDetector(
                                            onTap: _showReviewsBottomSheet,
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.star_rounded,
                                                  color: Colors.amber,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${_averageRating.toStringAsFixed(1)} (${_sellerReviews.length} reviews)',
                                                  style: const TextStyle(
                                                    color: Color(0xFF1B5E20),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 2),
                                        Text(
                                          '${l10n.memberSince}: $sellerDateString',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Action Buttons panel at bottom
          if (!isMyListing)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Contact row (WhatsApp & Telegram)
                  Row(
                    children: [
                      if (_sellerProfile?.whatsappNumber != null &&
                          (_listing!['whatsappContactEnabled'] ?? true))
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _launchWhatsApp,
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Colors.green,
                            ),
                            label: const Text(
                              'WhatsApp',
                              style: TextStyle(color: Colors.green),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.green),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      if (_sellerProfile?.whatsappNumber != null &&
                          (_listing!['whatsappContactEnabled'] ?? true) &&
                          _sellerProfile?.telegramUsername != null &&
                          (_listing!['telegramContactEnabled'] ?? true))
                        const SizedBox(width: 12),
                      if (_sellerProfile?.telegramUsername != null &&
                          (_listing!['telegramContactEnabled'] ?? true))
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _launchTelegram,
                            icon: const Icon(
                              Icons.telegram_rounded,
                              color: Colors.blue,
                            ),
                            label: const Text(
                              'Telegram',
                              style: TextStyle(color: Colors.blue),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.blue),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Chat & Pay direct row
                  Row(
                    children: [
                      if (_listing!['inAppChatEnabled'] ?? true)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _startInAppChat,
                            icon: const Icon(
                              Icons.message_rounded,
                              color: Colors.white,
                            ),
                            label: Text(
                              l10n.contactSeller,
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      if (_listing!['inAppChatEnabled'] ?? true)
                        const SizedBox(width: 12),
                      
                      // Add to Cart Button (Only for Buyers)
                      if (ref.read(authProvider)?.role == 'buyer') ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final photoUrls = (_listing!['photoUrls'] as List?)?.map((e) => e.toString()).toList() ?? [];
                              await FirestoreService().addToCart({
                                'listingId': widget.listingId,
                                'title': _listing!['title'],
                                'price': double.tryParse(_listing!['price'].toString()) ?? 0.0,
                                'unit': _listing!['unit'],
                                'quantity': 1.0,
                                'photoUrl': photoUrls.isNotEmpty ? photoUrls[0] : '',
                                'sellerId': _listing!['sellerId'],
                                'sellerName': _listing!['sellerName'] ?? 'Seller',
                              });
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${_listing!['title']} added to cart!'),
                                  backgroundColor: const Color(0xFF1B5E20),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.add_shopping_cart_rounded,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Add to Cart',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],

                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _paySellerDirect,
                          icon: const Icon(
                            Icons.payment_rounded,
                            color: Color(0xFF1B5E20),
                          ),
                          label: Text(
                            l10n.paySeller,
                            style: const TextStyle(
                              color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBC02D),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  void _showReviewsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Seller Reviews & Ratings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _sellerReviews.isEmpty
                    ? const Center(child: Text('No reviews for this seller yet.'))
                    : ListView.builder(
                        itemCount: _sellerReviews.length,
                        itemBuilder: (context, index) {
                          final rev = _sellerReviews[index];
                          final rating = int.tryParse(rev['rating'].toString()) ?? 5;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        rev['buyerName'] ?? 'Buyer',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Row(
                                        children: List.generate(5, (starIdx) {
                                          return Icon(
                                            starIdx < rating ? Icons.star_rounded : Icons.star_border_rounded,
                                            color: Colors.amber,
                                            size: 16,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  if (rev['comment'] != null && rev['comment'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      rev['comment'],
                                      style: TextStyle(color: Colors.grey[800], fontSize: 13),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
