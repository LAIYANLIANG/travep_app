class SocialPost {
  final String id;
  final String authorUid;
  final String content;
  final List<String> images;
  final DateTime createdAt;
  final String status;
  final int likeCount;

  SocialPost({
    required this.id,
    required this.authorUid,
    required this.content,
    required this.images,
    required this.createdAt,
    this.status = 'pending',
    this.likeCount = 0,
  });

  factory SocialPost.fromFirestore(Map<String, dynamic> data, String id) {
    return SocialPost(
      id: id,
      authorUid: data['authorUid'] ?? '',
      content: data['content'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      createdAt: data['createdAt'] != null ? data['createdAt'].toDate() : DateTime.now(),
      status: data['status'] ?? 'pending',
      likeCount: data['likeCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorUid': authorUid,
      'content': content,
      'images': images,
      'createdAt': createdAt,
      'status': status,
      'likeCount': likeCount,
    };
  }
}
