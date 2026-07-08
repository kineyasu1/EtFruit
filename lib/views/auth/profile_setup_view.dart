import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_data.dart';
import '../../services/error_service.dart';
import 'package:agrimarketmob/l10n/app_localizations.dart';

class ProfileSetupView extends ConsumerStatefulWidget {
  const ProfileSetupView({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  ConsumerState<ProfileSetupView> createState() => _ProfileSetupViewState();
}

class _ProfileSetupViewState extends ConsumerState<ProfileSetupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _telegramController = TextEditingController();
  final _whatsappController = TextEditingController();

  String? _selectedRegion;
  String? _selectedZone;
  String? _selectedWoreda;

  List<String> _regions = [];
  List<String> _zones = [];
  List<String> _woredas = [];

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _regions = LocationData.getRegions();
    _whatsappController.text = widget.phoneNumber;
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

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRegion == null ||
        _selectedZone == null ||
        _selectedWoreda == null) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).fillRequiredFields;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = ref.read(authProvider)!;
      final updatedUser = currentUser.copyWith(
        name: _nameController.text.trim(),
        region: _selectedRegion!,
        zone: _selectedZone!,
        woreda: _selectedWoreda!,
        telegramUsername: _telegramController.text.trim().isEmpty
            ? null
            : _telegramController.text.trim().replaceAll('@', ''),
        whatsappNumber: _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
      );

      await ref.read(authProvider.notifier).updateProfile(updatedUser);

      setState(() {
        _isLoading = false;
      });
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.setupProfile),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFFF1F8E9)],
            stops: [0.0, 0.3, 0.8],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.setupProfile,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      // Profile Picture PlaceHolder
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.green[50],
                              child: Icon(
                                Icons.person_rounded,
                                size: 60,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Name Input
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline),
                          labelText: l10n.name,
                          hintText: l10n.enterName,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.enterName;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Region Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedRegion,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.map_outlined),
                          labelText: l10n.region,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _regions.map((r) {
                          return DropdownMenuItem(value: r, child: Text(r));
                        }).toList(),
                        onChanged: _onRegionChanged,
                        validator: (value) =>
                            value == null ? 'Select Region' : null,
                      ),
                      const SizedBox(height: 16),
                      // Zone Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedZone,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_city_outlined),
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
                      const SizedBox(height: 16),
                      // Woreda Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedWoreda,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.pin_drop_outlined),
                          labelText: l10n.woreda,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _woredas.map((w) {
                          return DropdownMenuItem(value: w, child: Text(w));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedWoreda = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Select Woreda' : null,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.contactPreferences,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      // Telegram
                      TextFormField(
                        controller: _telegramController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.telegram_rounded,
                            color: Colors.blue,
                          ),
                          labelText: l10n.telegramUsername,
                          hintText: 'e.g. farmer_john',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // WhatsApp
                      TextFormField(
                        controller: _whatsappController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Colors.green,
                          ),
                          labelText: l10n.whatsappNumber,
                          hintText: 'e.g. +251911000000',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Save Profile Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
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
                                l10n.saveProfile,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
