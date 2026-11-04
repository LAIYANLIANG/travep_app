import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  final List<XFile> _selectedImages = [];
  bool _isUploading = false;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() {
      setState(() {
        _charCount = _contentController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70, // Optimize size
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('選擇圖片失敗: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  bool get _isValid {
    return _charCount >= 50 && _selectedImages.isNotEmpty && !_isUploading;
  }

  Future<void> _submitPost() async {
    if (!_isValid) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('錯誤：使用者未登入')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      List<String> imageUrls = [];
      
      // Upload each image
      for (var file in _selectedImages) {
        final filename = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        // 隔離到 travel_social_images
        final ref = FirebaseStorage.instance
            .ref()
            .child('travel_social_images/${user.uid}/$filename');
            
        // Use readAsBytes to ensure Web/Mobile compatibility
        final Uint8List data = await file.readAsBytes();
        final uploadTask = await ref.putData(
            data, SettableMetadata(contentType: 'image/jpeg'));
            
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      // Write to Firestore mapping the SocialPost requirements
      await FirebaseFirestore.instance.collection('travel_social_posts').add({
        'authorUid': user.uid,
        'content': _contentController.text,
        'images': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // 強制進入待審核狀態
        'likeCount': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已送出！文章將由管理員審核，通過後即可顯示於動態牆'),
            duration: Duration(seconds: 4),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('發佈失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('新增動態', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: _isValid ? _submitPost : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('發佈 (需審核)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Content input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _contentController,
                  maxLines: 8,
                  minLines: 4,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    hintText: '分享您的旅遊經歷...(最少 50 字)',
                    border: InputBorder.none,
                    counterText: '', // Hide default counter, use custom below
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Character count validation display
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$_charCount 字',
                    style: TextStyle(
                      color: _charCount >= 50 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(' / 最少 50 字', style: TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 24),

              // Image Picker section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📍 附上旅遊照片 (必填)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('加入相片'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Image previews
              if (_selectedImages.isEmpty)
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                  ),
                  child: const Center(
                    child: Text('尚未選擇任何相片', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black12,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              // Use FutureBuilder to read bytes for Web support
                              child: FutureBuilder<Uint8List>(
                                future: _selectedImages[index].readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return const Center(child: CircularProgressIndicator());
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
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
    );
  }
}
