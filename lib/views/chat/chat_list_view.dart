import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import 'chat_detail_view.dart';
import 'package:agrimarketmob/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatListView extends ConsumerStatefulWidget {
  const ChatListView({super.key});

  @override
  ConsumerState<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends ConsumerState<ChatListView> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentUser = ref.watch(authProvider);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.chats),
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chats),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFF4F6F2),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirestoreService().watchUserChats(currentUser.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading chats: ${snapshot.error}'),
              );
            }
            final chats = snapshot.data ?? [];
            if (chats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.noChatsYet,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];

                final isBuyer = chat['buyerId'] == currentUser.id;
                final otherUserId = isBuyer
                    ? chat['sellerId']
                    : chat['buyerId'];

                final time = chat['lastMessageTime'] is Timestamp
                    ? (chat['lastMessageTime'] as Timestamp).toDate()
                    : DateTime.now();
                final timeString =
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

                final photoUrl = chat['listingPhotoUrl'] ?? '';

                return FutureBuilder<UserModel?>(
                  future: FirestoreService().getUserProfile(otherUserId),
                  builder: (context, userSnapshot) {
                    final otherName =
                        userSnapshot.data?.name ??
                        (isBuyer ? 'Seller' : 'Buyer');

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailView(
                                chatId: chat['id'],
                                otherUserName: otherName,
                              ),
                            ),
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: photoUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: photoUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 1.5),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.green[50],
                                    child: const Icon(
                                      Icons.grass,
                                      color: Colors.green,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.green[50],
                                  child: const Icon(
                                    Icons.grass,
                                    color: Colors.green,
                                  ),
                                ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              otherName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              timeString,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chat['listingTitle'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                chat['lastMessageText'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
