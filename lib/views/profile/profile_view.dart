import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/location_data.dart';
import '../language_selection_view.dart';
import 'package:agrimarketmob/l10n/app_localizations.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _telegramController;
  late TextEditingController _whatsappController;

  String? _selectedRegion;
  String? _selectedZone;
  String? _selectedWoreda;

  List<String> _zones = [];
  List<String> _woredas = [];

  bool _isUpdating = false;
  List<Map<String, dynamic>> _myReviews = [];
  double _myAverageRating = 0.0;

  void _loadMyReviews() async {
    final user = ref.read(authProvider);
    if (user != null && user.role == 'seller') {
      final reviews = await FirestoreService().getSellerReviews(user.id);
      if (mounted) {
        setState(() {
          _myReviews = reviews;
          if (reviews.isNotEmpty) {
            double sum = reviews.fold(0.0, (acc, r) => acc + (double.tryParse(r['rating'].toString()) ?? 0.0));
            _myAverageRating = sum / reviews.length;
          } else {
            _myAverageRating = 0.0;
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _telegramController = TextEditingController();
    _whatsappController = TextEditingController();
    _populateFields();
    _loadMyReviews();
  }

  void _populateFields() {
    final user = ref.read(authProvider);
    if (user != null) {
      _nameController.text = user.name;
      _telegramController.text = user.telegramUsername ?? '';
      _whatsappController.text = user.whatsappNumber ?? '';
      _selectedRegion = user.region;
      _zones = LocationData.getZones(user.region);
      _selectedZone = user.zone;
      _woredas = LocationData.getWoredas(user.region, user.zone);
      _selectedWoreda = user.woreda;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _telegramController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _onRegionChanged(String? region) {
    setState(() {
      _selectedRegion = region;
      _selectedZone = null;
      _selectedWoreda = null;
      _zones = region != null ? LocationData.getZones(region) : [];
      _woredas = [];
    });
  }

  void _onZoneChanged(String? zone) {
    setState(() {
      _selectedZone = zone;
      _selectedWoreda = null;
      _woredas = (_selectedRegion != null && zone != null)
          ? LocationData.getWoredas(_selectedRegion!, zone)
          : [];
    });
  }

  void _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRegion == null ||
        _selectedZone == null ||
        _selectedWoreda == null)
      return;

    setState(() {
      _isUpdating = true;
    });

    final currentUser = ref.read(authProvider)!;
    final updated = currentUser.copyWith(
      name: _nameController.text.trim(),
      region: _selectedRegion!,
      zone: _selectedZone!,
      woreda: _selectedWoreda!,
      telegramUsername: _telegramController.text.trim().isEmpty
          ? null
          : _telegramController.text.trim(),
      whatsappNumber: _whatsappController.text.trim().isEmpty
          ? null
          : _whatsappController.text.trim(),
      updatedAt: DateTime.now(),
    );

    await ref.read(authProvider.notifier).updateProfile(updated);

    setState(() {
      _isUpdating = false;
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  void _markListingAsSold(String id) async {
    await FirestoreService().updateListingStatus(id, 'sold');
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Listing marked as Sold.')));
    }
  }

  void _deleteListing(String id) async {
    final l10n = AppLocalizations.of(context);

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteListing),
          content: Text(l10n.deleteConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirestoreService().updateListingStatus(id, 'deleted');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Listing deleted.')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showTermsDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.termsOfUse),
        content: SingleChildScrollView(child: Text(l10n.termsText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myAccount),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close_rounded : Icons.edit_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  _populateFields();
                }
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF4F6F2),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -------------------------------------------------------------
              // PROFILE DETAILS OR EDITOR
              // -------------------------------------------------------------
              Container(
                color: const Color(0xFF1B5E20),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _isEditing
                        ? Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l10n.editProfile,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green[900],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: l10n.name,
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? 'Enter name'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _selectedRegion,
                                  decoration: InputDecoration(
                                    labelText: l10n.region,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: LocationData.getRegions().map((r) {
                                    return DropdownMenuItem(
                                      value: r,
                                      child: Text(r),
                                    );
                                  }).toList(),
                                  onChanged: _onRegionChanged,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _selectedZone,
                                  decoration: InputDecoration(
                                    labelText: l10n.zone,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: _zones.map((z) {
                                    return DropdownMenuItem(
                                      value: z,
                                      child: Text(z),
                                    );
                                  }).toList(),
                                  onChanged: _onZoneChanged,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _selectedWoreda,
                                  decoration: InputDecoration(
                                    labelText: l10n.woreda,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: _woredas.map((w) {
                                    return DropdownMenuItem(
                                      value: w,
                                      child: Text(w),
                                    );
                                  }).toList(),
                                  onChanged: (value) =>
                                      setState(() => _selectedWoreda = value),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _telegramController,
                                  decoration: InputDecoration(
                                    labelText: l10n.telegramUsername,
                                    prefixIcon: const Icon(
                                      Icons.telegram_rounded,
                                      color: Colors.blue,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _whatsappController,
                                  decoration: InputDecoration(
                                    labelText: l10n.whatsappNumber,
                                    prefixIcon: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: Colors.green,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _isUpdating
                                      ? null
                                      : _saveProfileChanges,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B5E20),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isUpdating
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(l10n.save),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.green[50],
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 48,
                                  color: Colors.green[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.phoneNumber,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${user.region}, ${user.woreda}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              if (user.telegramUsername != null ||
                                  user.whatsappNumber != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (user.telegramUsername != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Chip(
                                          avatar: const Icon(
                                            Icons.telegram,
                                            color: Colors.blue,
                                            size: 18,
                                          ),
                                          label: Text(
                                            '@${user.telegramUsername}',
                                          ),
                                          padding: EdgeInsets.zero,
                                          backgroundColor: Colors.blue[50],
                                        ),
                                      ),
                                    if (user.whatsappNumber != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Chip(
                                          avatar: const Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                          label: Text(user.whatsappNumber!),
                                          padding: EdgeInsets.zero,
                                          backgroundColor: Colors.green[50],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                              if (user.role == 'seller' && _myReviews.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: _showMyReviewsBottomSheet,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_myAverageRating.toStringAsFixed(1)} (${_myReviews.length} reviews)',
                                        style: const TextStyle(
                                          color: Color(0xFF1B5E20),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ),

              // -------------------------------------------------------------
              // SETTINGS & CONTROL SECTION
              // -------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12,
                ),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.g_translate_rounded,
                          color: Color(0xFF1B5E20),
                        ),
                        title: Text(l10n.language),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LanguageSelectionView(
                                isFromSettings: true,
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.description_outlined,
                          color: Color(0xFF1B5E20),
                        ),
                        title: Text(l10n.termsOfUse),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _showTermsDialog,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.logout_rounded,
                          color: Colors.red,
                        ),
                        title: Text(
                          l10n.signOut,
                          style: const TextStyle(color: Colors.red),
                        ),
                        onTap: () => ref.read(authProvider.notifier).signOut(),
                      ),
                    ],
                  ),
                ),
              ),

              // -------------------------------------------------------------
              // MY LISTINGS SECTION
              // -------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Text(
                  l10n.myListings,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
              ),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService().watchMyListings(user.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final listings = snapshot.data ?? [];
                  // Filter out deleted ones
                  final activeListings = listings
                      .where((l) => l['status'] != 'deleted')
                      .toList();

                  if (activeListings.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No listings posted yet.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeListings.length,
                    itemBuilder: (context, index) {
                      final item = activeListings[index];
                      final photoUrls = List<String>.from(
                        item['photoUrls'] ?? [],
                      );
                      final photoUrl = photoUrls.isNotEmpty
                          ? photoUrls.first
                          : '';
                      final isSold = item['status'] == 'sold';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  photoUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.green[50],
                                    child: const Icon(
                                      Icons.grass,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item['price']} ETB / ${item['unit']}',
                                      style: TextStyle(
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSold
                                            ? Colors.orange[100]
                                            : Colors.green[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isSold ? 'Sold' : 'Active',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isSold
                                              ? Colors.orange[800]
                                              : Colors.green[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Controls
                              Column(
                                children: [
                                  if (!isSold)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () =>
                                          _markListingAsSold(item['id']),
                                      tooltip: l10n.markAsSold,
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteListing(item['id']),
                                    tooltip: l10n.deleteListing,
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  void _showMyReviewsBottomSheet() {
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
                'My Customer Feedback',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _myReviews.isEmpty
                    ? const Center(child: Text('No customer feedback yet.'))
                    : ListView.builder(
                        itemCount: _myReviews.length,
                        itemBuilder: (context, index) {
                          final rev = _myReviews[index];
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
