import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../social/domain/entities/post.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('後台管理 (Admin)'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('config').doc('billing').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          bool isBillingEnabled = false;
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            isBillingEnabled = data?['is_billing_enabled'] ?? false;
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SwitchListTile(
                    activeThumbColor: Colors.deepOrange,
                    title: const Text('啟用全站計費機制 (Billing Switch)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: const Text('開啟後，所有需要扣點的 AI 與路線優化功能將會正式扣除使用者點數；關閉則全面免費。'),
                    value: isBillingEnabled,
                    onChanged: (bool value) {
                      FirebaseFirestore.instance.collection('config').doc('billing').set(
                        {'is_billing_enabled': value},
                        SetOptions(merge: true),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value ? '已啟用全面計費機制' : '已關閉計費機制 (全站免費)'),
                          backgroundColor: value ? Colors.deepOrange : Colors.green,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Text('🛡️ 安全防護審查站 (Social Feed Moderation)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
              ),
              _buildModerationStation(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModerationStation(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('travel_social_posts')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('審核清單載入失敗: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text('太棒了！目前沒有待審核的文章。', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final post = SocialPost.fromFirestore(data, doc.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text('待審核貼文 • ${DateFormat('yyyy-MM-dd HH:mm').format(post.createdAt)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                        const Spacer(),
                        Text('User: ${post.authorUid.length > 6 ? post.authorUid.substring(0, 6) : 'Unknown'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(post.content, style: const TextStyle(fontSize: 15)),
                  ),
                  if (post.images.isNotEmpty)
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: post.images.length,
                        itemBuilder: (context, imgIndex) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0, right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                post.images[imgIndex],
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _updatePostStatus(doc.id, 'closed'),
                          icon: const Icon(Icons.block, color: Colors.red),
                          label: const Text('駁回封鎖', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => _updatePostStatus(doc.id, 'published'),
                          icon: const Icon(Icons.check),
                          label: const Text('核准發佈'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updatePostStatus(String docId, String status) async {
    await FirebaseFirestore.instance.collection('travel_social_posts').doc(docId).update({
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }
}
