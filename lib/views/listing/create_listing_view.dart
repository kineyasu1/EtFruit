import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/location_data.dart';
import '../../services/taxonomy_data.dart';
import '../../services/error_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'package:agrimarketmob/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CreateListingView extends ConsumerStatefulWidget {
  const CreateListingView({super.key, this.onSuccess});

  final VoidCallback? onSuccess;

  @override
  ConsumerState<CreateListingView> createState() => _CreateListingViewState();
}

class _CreateListingViewState extends ConsumerState<CreateListingView> {
  final _formKey = GlobalKey<FormState>();
  final _customProductController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaxonomyCategory? _selectedCategory;
  TaxonomyProduct? _selectedProduct;
  bool _isCustomProduct = false;

  String? _selectedUnit;
  bool _isNegotiable = false;

  String? _selectedRegion;
  String? _selectedZone;
  String? _selectedWoreda;

  List<String> _zones = [];
  List<String> _woredas = [];

  List<String> _photoUrls = []; // Stores unsplash URLs or base64 mock
  List<File> _localPhotos = [];
  final ImagePicker _picker = ImagePicker();

  bool _enableTelegram = false;
  bool _enableWhatsapp = false;
  bool _enableInAppChat = true;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-populate location from profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider);
      if (user != null) {
        setState(() {
          _selectedRegion = user.region;
          _zones = LocationData.getZones(user.region);
          _selectedZone = user.zone;
          _woredas = LocationData.getWoredas(user.region, user.zone);
          _selectedWoreda = user.woreda;

          _enableTelegram =
              user.telegramUsername != null &&
              user.telegramUsername!.isNotEmpty;
          _enableWhatsapp =
              user.whatsappNumber != null && user.whatsappNumber!.isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _customProductController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(TaxonomyCategory? category) {
    setState(() {
      _selectedCategory = category;
      _selectedProduct = null;
      _isCustomProduct = false;
      _selectedUnit = category?.suggestedUnits.first;
    });
  }

  void _onProductChanged(TaxonomyProduct? product) {
    setState(() {
      _selectedProduct = product;
      if (product != null) {
        _isCustomProduct = product.id == 'custom';
        _selectedUnit = product.suggestedUnit;
      }
    });
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

  // Allow uploading a real image
  Future<void> _pickImage(ImageSource source) async {
    if (_localPhotos.length + _photoUrls.length >= 5) return;
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null) {
        setState(() {
          _localPhotos.add(File(picked.path));
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // Simulated photo upload helper to bypass camera dependency in testing
  void _addMockPhoto() {
    if (_localPhotos.length + _photoUrls.length >= 5) return;

    // Choose Unsplash mockup based on category
    String url =
        'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=600'; // Wheat default
    if (_selectedCategory != null) {
      switch (_selectedCategory!.id) {
        case 'cereals_grains':
          url =
              'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=600';
          break;
        case 'coffee_cash_crops':
          url =
              'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600';
          break;
        case 'vegetables':
          url =
              'https://images.unsplash.com/photo-1610348725531-843dff163e2c?w=600';
          break;
        case 'fruits':
          url =
              'https://images.unsplash.com/photo-1610832958506-ee56336191d1?w=600';
          break;
        case 'livestock':
          url =
              'https://images.unsplash.com/photo-1570042225831-d98fa7577f1e?w=600';
          break;
        case 'dairy_animal_products':
          url =
              'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=600';
          break;
        default:
          url =
              'https://images.unsplash.com/photo-1610348725531-843dff163e2c?w=600';
      }
    }
    // Append a unique timestamp parameter to bypass cache
    url =
        '$url&sig=${DateTime.now().millisecondsSinceEpoch}_${_photoUrls.length}';

    setState(() {
      _photoUrls.add(url);
    });
  }

  void _removePhoto(int index) {
    setState(() {
      if (index < _photoUrls.length) {
        _photoUrls.removeAt(index);
      } else {
        _localPhotos.removeAt(index - _photoUrls.length);
      }
    });
  }

  void _publishListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      setState(() => _errorMessage = 'Please select a Category');
      return;
    }
    if (_selectedProduct == null && !_isCustomProduct) {
      setState(() => _errorMessage = 'Please select a Product');
      return;
    }
    if (_isCustomProduct && _customProductController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter custom product name');
      return;
    }
    if (_selectedRegion == null ||
        _selectedZone == null ||
        _selectedWoreda == null) {
      setState(() => _errorMessage = 'Please fill location');
      return;
    }
    if (!_enableTelegram && !_enableWhatsapp && !_enableInAppChat) {
      setState(() => _errorMessage = 'Select at least one contact method');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(authProvider)!;
      final languageCode = ref.read(languageProvider).languageCode;

      final title = _isCustomProduct
          ? _customProductController.text.trim()
          : _selectedProduct!.getName(languageCode);

      // In real mode, we upload localFiles to Firebase Storage and get URLs.
      // In sandbox/offline mode, we use the local file path so they can render locally!
      final finalPhotoUrls = List<String>.from(_photoUrls);

      if (AuthService.isFirebaseAvailable) {
        final storageRef = FirebaseStorage.instance.ref();
        for (int i = 0; i < _localPhotos.length; i++) {
          final file = _localPhotos[i];
          final extension = file.path.split('.').last;
          final fileName = 'listings/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$i.$extension';
          final uploadRef = storageRef.child(fileName);

          final uploadTask = uploadRef.putFile(file);
          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();
          finalPhotoUrls.add(downloadUrl);
        }
      } else {
        for (int i = 0; i < _localPhotos.length; i++) {
          finalPhotoUrls.add(_localPhotos[i].path);
        }
      }

      // If no photo was attached, add a category default placeholder
      if (finalPhotoUrls.isEmpty) {
        finalPhotoUrls.add(
          'https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?w=500&sig=default',
        );
      }

      final listingData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'sellerId': user.id,
        'sellerName': user.name,
        'title': title,
        'categoryId': _selectedCategory!.id,
        'categoryNameEn': _selectedCategory!.getName('en'),
        'categoryNameAm': _selectedCategory!.getName('am'),
        'categoryNameOm': _selectedCategory!.getName('om'),
        'categoryNameSo': _selectedCategory!.getName('so'),
        'categoryNameTi': _selectedCategory!.getName('ti'),
        'quantity': double.parse(_quantityController.text.trim()),
        'unit': _selectedUnit,
        'price': double.parse(_priceController.text.trim()),
        'isNegotiable': _isNegotiable,
        'region': _selectedRegion,
        'zone': _selectedZone,
        'woreda': _selectedWoreda,
        'photoUrls': finalPhotoUrls,
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'telegramContactEnabled': _enableTelegram,
        'whatsappContactEnabled': _enableWhatsapp,
        'inAppChatEnabled': _enableInAppChat,
        'status': 'active',
        'reportCount': 0,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await FirestoreService().saveListing(listingData);

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing published successfully!')),
      );

      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorService.getReadableError(context, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeLang = ref.watch(languageProvider).languageCode;

    // Filter product sublist based on category
    final categoryProducts = _selectedCategory != null
        ? TaxonomyData.getProductsByCategory(_selectedCategory!.id)
        : <TaxonomyProduct>[];

    // Include custom product selection in list
    final productItems = [
      ...categoryProducts,
      TaxonomyProduct(
        id: 'custom',
        categoryId: _selectedCategory?.id ?? '',
        suggestedUnit: _selectedUnit ?? 'kg',
        names: {
          'en': 'Other / Custom Product',
          'am': 'ሌላ / አዲስ ምርት',
          'om': 'Kuduraa kan biraa',
          'so': 'Dalag kale',
          'ti': 'ካልእ ፍርያት',
        },
      ),
    ];

    final units = [
      'kg',
      'quintal',
      'head',
      'crate',
      'sack',
      'liter',
      'piece',
      'bunch',
    ];

    final totalImages = _photoUrls.length + _localPhotos.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createListing),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFF4F6F2)),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.listingDetails,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Category Select
                        DropdownButtonFormField<TaxonomyCategory>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: l10n.productCategory,
                            prefixIcon: const Icon(Icons.category_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: TaxonomyData.categories.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(c.getName(activeLang)),
                            );
                          }).toList(),
                          onChanged: _onCategoryChanged,
                          validator: (value) =>
                              value == null ? 'Select Category' : null,
                        ),
                        if (_selectedCategory != null) ...[
                          const SizedBox(height: 16),
                          // Product Select
                          DropdownButtonFormField<TaxonomyProduct>(
                            value: _selectedProduct,
                            decoration: InputDecoration(
                              labelText: l10n.productName,
                              prefixIcon: const Icon(Icons.grass_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: productItems.map((p) {
                              return DropdownMenuItem(
                                value: p,
                                child: Text(p.getName(activeLang)),
                              );
                            }).toList(),
                            onChanged: _onProductChanged,
                            validator: (value) =>
                                value == null ? 'Select Product' : null,
                          ),
                        ],
                        if (_isCustomProduct) ...[
                          const SizedBox(height: 16),
                          // Custom Product Name Input
                          TextFormField(
                            controller: _customProductController,
                            decoration: InputDecoration(
                              labelText: l10n.customProductName,
                              prefixIcon: const Icon(Icons.edit_note_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (_isCustomProduct &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Enter custom product name';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              // Quantity
                              child: TextFormField(
                                controller: _quantityController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: l10n.quantity,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty)
                                    return 'Enter quantity';
                                  if (double.tryParse(value) == null)
                                    return 'Enter valid number';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Unit
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedUnit,
                                decoration: InputDecoration(
                                  labelText: l10n.unit,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: units.map((u) {
                                  return DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  );
                                }).toList(),
                                onChanged: (value) =>
                                    setState(() => _selectedUnit = value),
                                validator: (value) =>
                                    value == null ? 'Select unit' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              // Price
                              child: TextFormField(
                                controller: _priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: l10n.price,
                                  prefixText: 'ETB ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty)
                                    return 'Enter price';
                                  if (double.tryParse(value) == null)
                                    return 'Enter valid number';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Negotiable checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _isNegotiable,
                                  activeColor: const Color(0xFF1B5E20),
                                  onChanged: (val) => setState(
                                    () => _isNegotiable = val ?? false,
                                  ),
                                ),
                                Text(
                                  l10n.negotiable,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.addPhotos,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Photo Grid list
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: totalImages + 1,
                            itemBuilder: (context, index) {
                              if (index == totalImages) {
                                return totalImages >= 5
                                    ? const SizedBox()
                                    : GestureDetector(
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            builder: (ctx) => SafeArea(
                                              child: Wrap(
                                                children: [
                                                  ListTile(
                                                    leading: const Icon(
                                                      Icons.camera_alt_rounded,
                                                    ),
                                                    title: const Text(
                                                      'Take Photo',
                                                    ),
                                                    onTap: () {
                                                      Navigator.pop(ctx);
                                                      _pickImage(
                                                        ImageSource.camera,
                                                      );
                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(
                                                      Icons
                                                          .photo_library_rounded,
                                                    ),
                                                    title: const Text(
                                                      'Choose from Gallery',
                                                    ),
                                                    onTap: () {
                                                      Navigator.pop(ctx);
                                                      _pickImage(
                                                        ImageSource.gallery,
                                                      );
                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(
                                                      Icons
                                                          .add_photo_alternate_outlined,
                                                      color: Colors.green,
                                                    ),
                                                    title: const Text(
                                                      'Simulate Photo (No Camera)',
                                                    ),
                                                    onTap: () {
                                                      Navigator.pop(ctx);
                                                      _addMockPhoto();
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 90,
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey[400]!,
                                              style: BorderStyle.solid,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add_a_photo_outlined,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                              }

                              final isMock = index < _photoUrls.length;
                              final Widget imageWidget = isMock
                                  ? CachedNetworkImage(
                                      imageUrl: _photoUrls[index],
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 90,
                                        height: 90,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        width: 90,
                                        height: 90,
                                        color: Colors.green[50],
                                        child: const Icon(
                                          Icons.broken_image_outlined,
                                          color: Colors.green,
                                        ),
                                      ),
                                    )
                                  : Image.file(
                                      _localPhotos[index - _photoUrls.length],
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    );

                              return Stack(
                                children: [
                                  Container(
                                    width: 90,
                                    margin: const EdgeInsets.only(right: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: imageWidget,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () => _removePhoto(index),
                                      child: const CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.red,
                                        child: Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.location,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
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
                            return DropdownMenuItem(value: r, child: Text(r));
                          }).toList(),
                          onChanged: _onRegionChanged,
                          validator: (value) =>
                              value == null ? 'Select Region' : null,
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
                            return DropdownMenuItem(value: z, child: Text(z));
                          }).toList(),
                          onChanged: _onZoneChanged,
                          validator: (value) =>
                              value == null ? 'Select Zone' : null,
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
                            return DropdownMenuItem(value: w, child: Text(w));
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _selectedWoreda = value),
                          validator: (value) =>
                              value == null ? 'Select Woreda' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.description,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                'Describe quality, transport arrangements, etc.',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.contactPreferences,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          title: Text(l10n.enableTelegram),
                          value: _enableTelegram,
                          activeColor: const Color(0xFF1B5E20),
                          onChanged: (val) =>
                              setState(() => _enableTelegram = val ?? false),
                        ),
                        CheckboxListTile(
                          title: Text(l10n.enableWhatsapp),
                          value: _enableWhatsapp,
                          activeColor: const Color(0xFF1B5E20),
                          onChanged: (val) =>
                              setState(() => _enableWhatsapp = val ?? false),
                        ),
                        CheckboxListTile(
                          title: Text(l10n.enableInAppChat),
                          value: _enableInAppChat,
                          activeColor: const Color(0xFF1B5E20),
                          onChanged: (val) =>
                              setState(() => _enableInAppChat = val ?? false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _publishListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          l10n.publishListing,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
