import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/post.dart';
import 'create_post_page.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          '旅遊動態',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreatePostPage()));
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('travel_social_posts')
            .where('status', isEqualTo: 'published') // 僅顯示通過審核的文章
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('載入失敗: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.panorama, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '目前還沒有任何動態哦！',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  Text('趕快按下右下角新增第一篇吧。', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              bottom: 80,
              top: 12,
            ), // Leave space for FAB
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final post = SocialPost.fromFirestore(data, docs[index].id);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Feed Header: Author & Time
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  // 簡單顯示 Uid 前 8 碼作為示範，若有 user context 可換成 displayName
                                  post.authorUid.length > 8
                                      ? 'User: ${post.authorUid.substring(0, 8)}...'
                                      : 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'yyyy-MM-dd HH:mm',
                                  ).format(post.createdAt),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_horiz),
                            onPressed: () {
                              // 未來可加入檢舉功能
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('檢舉功能開發中')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Pictures (ViewPager or Single)
                    if (post.images.isNotEmpty)
                      SizedBox(
                        height: 300,
                        child: PageView.builder(
                          itemCount: post.images.length,
                          itemBuilder: (context, imgIndex) {
                            return Image.network(
                              post.images[imgIndex],
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 64,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    if (post.images.length > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.photo_library,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.images.length} 張相片',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        post.content,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),

                    // Interactions
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.favorite_border),
                            onPressed: () {},
                          ),
                          Text('${post.likeCount}'),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline),
                            onPressed: () {},
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.bookmark_border),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
