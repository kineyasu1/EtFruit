import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/location_data.dart';
import '../../models/user_model.dart';
import '../listing/create_listing_view.dart';
import '../listing/listing_detail_view.dart';
import '../chat/chat_list_view.dart';
import '../profile/profile_view.dart';
import 'seller_dashboard_subview.dart';
import '../cart/cart_view.dart';
import 'package:agrimarketmob/l10n/app_localizations.dart';

// -----------------------------------------------------------------------------
// HOME VIEW SHELL (Directs based on User Role)
// -----------------------------------------------------------------------------
class HomeView extends ConsumerWidget {
  const HomeView({super.key, this.openCreateListing = false, this.initialTab = 0});

  final bool openCreateListing;
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user.role == 'seller') {
      return SellerHomeView(openCreateListing: openCreateListing, initialTab: initialTab);
    } else {
      return BuyerHomeView(initialTab: initialTab);
    }
  }
}

// -----------------------------------------------------------------------------
// SELLER WORKSPACE HOME VIEW
// -----------------------------------------------------------------------------
class SellerHomeView extends ConsumerStatefulWidget {
  const SellerHomeView({super.key, this.openCreateListing = false, this.initialTab = 0});

  final bool openCreateListing;
  final int initialTab;

  @override
  ConsumerState<SellerHomeView> createState() => _SellerHomeViewState();
}

class _SellerHomeViewState extends ConsumerState<SellerHomeView> {
  late int _currentIndex;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _pages = [
      const SellerDashboardSubView(),
      const WatchMyListingsSubView(),
      const ChatListView(),
      const ProfileView(),
    ];

    if (widget.openCreateListing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToCreateListing();
      });
    }
  }

  void _navigateToCreateListing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateListingView(
          onSuccess: () {
            Navigator.pop(context);
            setState(() {
              _currentIndex = 1; // Return to My Listings
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  Icons.dashboard_rounded,
                  color: _currentIndex == 0 ? const Color(0xFF1B5E20) : Colors.grey,
                ),
                onPressed: () => setState(() => _currentIndex = 0),
                tooltip: 'Dashboard',
              ),
              IconButton(
                icon: Icon(
                  Icons.list_alt_rounded,
                  color: _currentIndex == 1 ? const Color(0xFF1B5E20) : Colors.grey,
                ),
                onPressed: () => setState(() => _currentIndex = 1),
                tooltip: l10n.myListings,
              ),
              const SizedBox(width: 40), // FAB notch space
              IconButton(
                icon: Icon(
                  Icons.chat_bubble_rounded,
                  color: _currentIndex == 2 ? const Color(0xFF1B5E20) : Colors.grey,
                ),
                onPressed: () => setState(() => _currentIndex = 2),
                tooltip: l10n.chats,
              ),
              IconButton(
                icon: Icon(
                  Icons.person_rounded,
                  color: _currentIndex == 3 ? const Color(0xFF1B5E20) : Colors.grey,
                ),
                onPressed: () => setState(() => _currentIndex = 3),
                tooltip: l10n.myAccount,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateListing,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 36),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// -----------------------------------------------------------------------------
// BUYER WORKSPACE HOME VIEW
// -----------------------------------------------------------------------------
class BuyerHomeView extends ConsumerStatefulWidget {
  const BuyerHomeView({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<BuyerHomeView> createState() => _BuyerHomeViewState();
}

class _BuyerHomeViewState extends ConsumerState<BuyerHomeView> {
  late int _currentIndex;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _pages = [
      const BrowseFeedSubView(),
      const CartView(),
      const BuyerOrdersSubView(),
      const ChatListView(),
      const ProfileView(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Browse',
          ),
          const NavigationDestination(
            icon: Icon(Icons.shopping_cart_rounded),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_rounded),
            label: l10n.chats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_rounded),
            label: l10n.myAccount,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// BROWSE FEED SUB-VIEW
// -----------------------------------------------------------------------------
class BrowseFeedSubView extends ConsumerStatefulWidget {
  const BrowseFeedSubView({super.key});

  @override
  ConsumerState<BrowseFeedSubView> createState() => _BrowseFeedSubViewState();
}

class _BrowseFeedSubViewState extends ConsumerState<BrowseFeedSubView> with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String? _selectedCategoryId;
  String? _selectedRegion;
  String _searchKeyword = '';
  bool _isFilterOpen = false;

  // Pagination states
  final List<Map<String, dynamic>> _listings = [];
  dynamic _lastCursor;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isFirstLoad = true;

  // Debouncing timer
  Timer? _searchDebounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadInitialPage();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialPage() async {
    if (!mounted) return;
    setState(() {
      _listings.clear();
      _lastCursor = null;
      _hasMore = true;
      _isFirstLoad = true;
      _isLoadingMore = false;
    });
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    if (!mounted) return;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await FirestoreService().getListingsPage(
        categoryId: _selectedCategoryId,
        region: _selectedRegion,
        searchKeyword: _searchKeyword,
        startAfter: _lastCursor,
        limit: 8,
      );

      if (mounted) {
        setState(() {
          _listings.addAll(result.listings);
          _lastCursor = result.cursor;
          _hasMore = result.hasMore;
          _isFirstLoad = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading listings: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _isFirstLoad = false;
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedRegion = null;
      _searchKeyword = '';
      _searchController.clear();
    });
    _loadInitialPage();
  }

  Widget _buildListingCard(BuildContext context, Map<String, dynamic> item, String photoUrl, UserModel user, AppLocalizations l10n) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingDetailView(listingId: item['id']),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  photoUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: photoUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.green[50],
                            child: const Icon(
                              Icons.grass_rounded,
                              size: 40,
                              color: Colors.green,
                            ),
                          ),
                        )
                      : Image.file(
                          File(photoUrl),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.green[50],
                            child: const Icon(
                              Icons.grass_rounded,
                              size: 40,
                              color: Colors.green,
                            ),
                          ),
                        ),
                  if (item['isNegotiable'] ?? false)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
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
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item['price']} ETB / ${item['unit']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (user.role == 'buyer')
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart_rounded,
                              color: Color(0xFF1B5E20), size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            await FirestoreService().addToCart({
                              'listingId': item['id'],
                              'title': item['title'],
                              'price': double.tryParse(item['price'].toString()) ?? 0.0,
                              'unit': item['unit'],
                              'quantity': 1.0,
                              'photoUrl': photoUrl,
                              'sellerId': item['sellerId'],
                              'sellerName': item['sellerName'],
                            });
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${item['title']} added to cart!'),
                                backgroundColor: const Color(0xFF1B5E20),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${item['region']}, ${item['woreda']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final activeLang = ref.watch(languageProvider).languageCode;
    final user = ref.watch(authProvider)!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.agriculture_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.appName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isFilterOpen ? Icons.filter_alt_off_rounded : Icons.filter_alt_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isFilterOpen = !_isFilterOpen;
              });
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search & Filter Panel
          Container(
            color: const Color(0xFF1B5E20),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                // Keyword Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                      _searchKeyword = val.trim();
                      _loadInitialPage();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: l10n.searchProducts,
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _searchKeyword = '';
                              _loadInitialPage();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                // Collapsible Filter Panel
                if (_isFilterOpen) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Location/Region Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              hint: Text(l10n.region, style: const TextStyle(fontSize: 13)),
                              value: _selectedRegion,
                              items: LocationData.getRegions().map((r) {
                                return DropdownMenuItem(
                                  value: r,
                                  child: Text(r, style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedRegion = val;
                                });
                                _loadInitialPage();
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Reset Filters Button
                      ElevatedButton(
                        onPressed: _clearFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBC02D),
                          foregroundColor: const Color(0xFF1B5E20),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.clearFilters,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Categories Horizontal Scroll List
          FutureBuilder<List<Map<String, dynamic>>>(
            future: FirestoreService().getCategories(),
            builder: (context, catSnapshot) {
              if (!catSnapshot.hasData) return const SizedBox(height: 50);

              final categories = catSnapshot.data!;
              return SizedBox(
                height: 55,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final isSelected = isAll
                        ? _selectedCategoryId == null
                        : categories[index - 1]['id'] == _selectedCategoryId;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        showCheckmark: false,
                        label: Text(
                          isAll
                              ? (activeLang == 'am'
                                  ? 'ሁሉም'
                                  : activeLang == 'ti'
                                      ? 'ኩሉ'
                                      : activeLang == 'om'
                                          ? 'Hunda'
                                          : activeLang == 'so'
                                              ? 'Dhamaan'
                                              : 'All')
                              : categories[index - 1]['name${activeLang[0].toUpperCase()}${activeLang.substring(1)}'] ??
                                  categories[index - 1]['nameEn'] ??
                                  '',
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1B5E20),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.green[900],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        backgroundColor: Colors.white,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryId = isAll ? null : categories[index - 1]['id'];
                          });
                          _loadInitialPage();
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Product Listings Grid List
          Expanded(
            child: _isFirstLoad
                ? const Center(child: CircularProgressIndicator())
                : _listings.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noListingsFound,
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(12),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = _listings[index];
                                  final photoUrl = (item['photoUrls'] as List).isNotEmpty
                                      ? item['photoUrls'][0] as String
                                      : '';
                                  return _buildListingCard(context, item, photoUrl, user, l10n);
                                },
                                childCount: _listings.length,
                              ),
                            ),
                          ),
                          if (_isLoadingMore)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(
                                  child: SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(strokeWidth: 3),
                                  ),
                                ),
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
// SELLER'S OWN LISTINGS SUB-VIEW
// -----------------------------------------------------------------------------
class WatchMyListingsSubView extends ConsumerWidget {
  const WatchMyListingsSubView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider)!;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.myListings,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFF4F6F2),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService().watchMyListings(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final myListings = snapshot.data ?? [];
            if (myListings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.list_alt_rounded, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No products listed yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myListings.length,
              itemBuilder: (context, index) {
                final item = myListings[index];
                final price = double.tryParse(item['price'].toString()) ?? 0.0;
                final isSold = item['status'] == 'sold';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Small icon indicator
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSold ? Colors.grey[200] : Colors.green[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSold ? Icons.check_circle_outline : Icons.grass_rounded,
                            color: isSold ? Colors.grey : const Color(0xFF1B5E20),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Listing details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] ?? 'Product',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  decoration: isSold ? TextDecoration.lineThrough : null,
                                  color: isSold ? Colors.grey : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$price ETB / ${item['unit']} (${item['quantity']} available)',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        // Sold & Delete actions
                        if (!isSold)
                          IconButton(
                            icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                            tooltip: l10n.markAsSold,
                            onPressed: () async {
                              await FirestoreService().updateListingStatus(item['id'], 'sold');
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          tooltip: l10n.deleteListing,
                          onPressed: () async {
                            await FirestoreService().updateListingStatus(item['id'], 'deleted');
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
