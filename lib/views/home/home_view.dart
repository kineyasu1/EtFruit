import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/taxonomy_data.dart';
import '../../services/location_data.dart';
import '../listing/create_listing_view.dart';
import '../listing/listing_detail_view.dart';
import '../chat/chat_list_view.dart';
import '../profile/profile_view.dart';
import 'package:agrimarketmob/l10n/app_localizations.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  int _currentIndex = 0;

  // The pages for our bottom navigation tabs
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const BrowseFeedSubView(),
      const ChatListView(),
      const ProfileView(),
    ];
  }

  void _navigateToCreateListing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateListingView(
          onSuccess: () {
            Navigator.pop(context);
            setState(() {
              _currentIndex = 0; // Return to Browse Feed tab
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
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
                  Icons.grid_view_rounded,
                  color: _currentIndex == 0 ? const Color(0xFF1B5E20) : Colors.grey,
                ),
                onPressed: () => setState(() => _currentIndex = 0),
                tooltip: 'Browse',
              ),
              const SizedBox(width: 40), // Space for floating action button
              IconButton(
                icon: Icon(
                  Icons.chat_bubble_rounded,
                  color: _currentIndex == 1 ? const Color(0xFF1B5E20) : Colors.grey,
                ),
                onPressed: () => setState(() => _currentIndex = 1),
                tooltip: l10n.chats,
              ),
              IconButton(
                icon: Icon(
                  Icons.person_rounded,
                  color: _currentIndex == 2 ? const Color(0xFF1B5E20) : Colors.grey,
                ),
                onPressed: () => setState(() => _currentIndex = 2),
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
// BROWSE FEED SUB-VIEW
// -----------------------------------------------------------------------------
class BrowseFeedSubView extends ConsumerStatefulWidget {
  const BrowseFeedSubView({super.key});

  @override
  ConsumerState<BrowseFeedSubView> createState() => _BrowseFeedSubViewState();
}

class _BrowseFeedSubViewState extends ConsumerState<BrowseFeedSubView> {
  final _searchController = TextEditingController();
  
  String? _selectedCategoryId;
  String? _selectedRegion;
  String _searchKeyword = '';
  
  bool _isFilterOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedRegion = null;
      _searchKeyword = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeLang = ref.watch(languageProvider).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.agriculture_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text(
              l10n.appName,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
        children: [
          // Search & Filter Panel
          Container(
            color: const Color(0xFF1B5E20),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Input with Autocomplete Category matching
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchProducts,
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1B5E20)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              setState(() {
                                _searchController.clear();
                                _searchKeyword = '';
                              });
                            },
                            child: const Icon(Icons.clear, color: Colors.grey),
                          )
                        : null,
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchKeyword = val.trim();
                    });
                  },
                ),
                if (_isFilterOpen) ...[
                  const SizedBox(height: 12),
                  // Region Selector Dropdown
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedRegion,
                              hint: Text(l10n.region),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem(value: null, child: Text('All Regions')),
                                ...LocationData.getRegions().map(
                                  (r) => DropdownMenuItem(value: r, child: Text(r)),
                                ),
                              ],
                              onChanged: (val) => setState(() => _selectedRegion = val),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _clearFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFBC02D),
                          foregroundColor: const Color(0xFF1B5E20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(l10n.clearFilters),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Category Chips Row (Always visible)
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: TaxonomyData.categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedCategoryId == null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(l10n.all),
                      selected: isSelected,
                      selectedColor: const Color(0xFF1B5E20),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                      onSelected: (_) => setState(() => _selectedCategoryId = null),
                    ),
                  );
                }
                
                final cat = TaxonomyData.categories[index - 1];
                final isSelected = _selectedCategoryId == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat.getName(activeLang)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF1B5E20),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId = selected ? cat.id : null;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          
          // Listings Stream List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().watchListings(
                categoryId: _selectedCategoryId,
                region: _selectedRegion,
                searchKeyword: _searchKeyword,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final listings = snapshot.data ?? [];
                if (listings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noListingsFound,
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.74,
                  ),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final item = listings[index];
                    final photoUrls = List<String>.from(item['photoUrls'] ?? []);
                    final photoUrl = photoUrls.isNotEmpty ? photoUrls.first : '';
                    
                    return GestureDetector(
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
                                  Image.network(
                                    photoUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.green[50],
                                      child: const Icon(Icons.grass_rounded, size: 40, color: Colors.green),
                                    ),
                                  ),
                                  if (item['isNegotiable'] ?? false)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                  Text(
                                    '${item['price']} ETB / ${item['unit']}',
                                    style: const TextStyle(
                                      color: Color(0xFF1B5E20),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          '${item['region']}, ${item['woreda']}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
