import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../services/error_service.dart';

class UserProfileView extends ConsumerStatefulWidget {
  const UserProfileView({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends ConsumerState<UserProfileView> {
  UserModel? _profile;
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileDetails();
  }

  Future<void> _loadProfileDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userProfile = await FirestoreService().getUserProfile(widget.userId);
      final userReviews = await FirestoreService().getSellerReviews(widget.userId);
      
      double ratingSum = 0.0;
      if (userReviews.isNotEmpty) {
        ratingSum = userReviews.fold(0.0, (acc, r) => acc + (double.tryParse(r['rating'].toString()) ?? 0.0)) / userReviews.length;
      }

      setState(() {
        _profile = userProfile;
        _reviews = userReviews;
        _averageRating = ratingSum;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorService.getReadableError(context, e);
        _isLoading = false;
      });
    }
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = double.tryParse(review['rating'].toString()) ?? 0.0;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  review['buyerName'] ?? 'Buyer',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              review['comment'] ?? '',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : _profile == null
                  ? const Center(child: Text('User profile not found.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Profile Info
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor: const Color(0xFFE8F5E9),
                                    child: Text(
                                      _profile!.name.isNotEmpty ? _profile!.name[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _profile!.name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _profile!.role.toUpperCase(),
                                    style: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.0),
                                  ),
                                  if (_profile!.role == 'seller') ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                        const SizedBox(width: 4),
                                        Text(
                                          _averageRating.toStringAsFixed(1),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Text(
                                          ' (${_reviews.length} reviews)',
                                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Contact and Location details
                          const Text(
                            'Location & Details',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Region', style: TextStyle(color: Colors.grey)),
                                      Text(_profile!.region),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Zone', style: TextStyle(color: Colors.grey)),
                                      Text(_profile!.zone),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Woreda', style: TextStyle(color: Colors.grey)),
                                      Text(_profile!.woreda),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Reviews list if seller
                          if (_profile!.role == 'seller') ...[
                            Text(
                              'Reviews (${_reviews.length})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _reviews.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text('No reviews yet.', style: TextStyle(color: Colors.grey)),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _reviews.length,
                                    itemBuilder: (context, index) {
                                      return _buildReviewCard(_reviews[index]);
                                    },
                                  ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}
