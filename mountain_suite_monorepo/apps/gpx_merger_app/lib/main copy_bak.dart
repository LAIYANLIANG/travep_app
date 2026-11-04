/*
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'dart:io';
import 'gpx_merger.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // <--- 新增
import 'info_screen.dart'; // <--- 新增

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPX 檔案合併工具',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const GpxMergerScreen(),
    );
  }
}

class GpxMergerScreen extends StatefulWidget {
  const GpxMergerScreen({super.key});

  @override
  State<GpxMergerScreen> createState() => _GpxMergerScreenState();
}

class _GpxMergerScreenState extends State<GpxMergerScreen> {
  List<PlatformFile> selectedFiles = [];
  bool isProcessing = false;
  
  static const int maxFileSize = 500 * 1024; // 500KB
  static const int maxFiles = 2;

  Future<void> _pickFile(int index) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        
        if (!file.name.toLowerCase().endsWith('.gpx')) {
          _showError('請選擇 GPX 檔案');
          return;
        }
        
        if (file.size > maxFileSize) {
          _showError('檔案大小超過 500KB 限制');
          return;
        }
        
        setState(() {
          if (index < selectedFiles.length) {
            selectedFiles[index] = file;
          } else {
            selectedFiles.add(file);
          }
        });
      }
    } catch (e) {
      _showError('選擇檔案時發生錯誤: $e');
    }
  }

  Future<void> _mergeFiles() async {
    if (selectedFiles.isEmpty) {
      _showError('請至少選擇一個 GPX 檔案');
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final List<Uint8List> fileContents = [];
      for (final file in selectedFiles) {
        if (file.bytes != null) {
          fileContents.add(file.bytes!);
        }
      }

      final Uint8List mergedContent = GpxMerger.mergeGpxFiles(fileContents);
      
      Directory? directory;
      String? filePath;
      
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory != null) {
        final String fileName = 'merged_${DateTime.now().millisecondsSinceEpoch}.gpx';
        filePath = '${directory.path}/$fileName';
        
        final File file = File(filePath);
        await file.writeAsBytes(mergedContent);
        
        if (mounted) {
          _showSuccessDialog(filePath);
        }
      } else {
        final String fileName = 'merged_${DateTime.now().millisecondsSinceEpoch}.gpx';
        
        await FileSaver.instance.saveFile(
          name: fileName.replaceAll('.gpx', ''),
          bytes: mergedContent,
          mimeType: MimeType.other,
        );
        
        _showSuccess('檔案已儲存到下載資料夾');
      }
      
      setState(() {
        selectedFiles.clear();
      });
    } catch (e) {
      _showError('合併檔案時發生錯誤: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  void _showSuccessDialog(String filePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 8),
              Text('合併成功！'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '檔案已成功合併並儲存。',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '儲存位置：',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      filePath,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final result = await OpenFile.open(filePath);
                if (result.type != ResultType.done) {
                  _showError('無法開啟檔案: ${result.message}');
                }
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open, size: 18),
                  SizedBox(width: 4),
                  Text('開啟檔案'),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Share.shareXFiles(
                  [XFile(filePath)],
                  text: '分享合併後的 GPX 檔案',
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.share, size: 18),
                  SizedBox(width: 4),
                  Text('分享'),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('關閉'),
            ),
          ],
        );
      },
    );
  }

  void _removeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPX 檔案合併工具'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'GPX 檔案合併工具',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• 選擇最多 2 個 GPX 檔案\n• 每個檔案不超過 500KB\n• 合併後的檔案將按座標排序',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            for (int i = 0; i < maxFiles; i++) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GPX 檔案 ${i + 1}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (i < selectedFiles.length)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.map, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        selectedFiles[i].name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${(selectedFiles[i].size / 1024).toStringAsFixed(1)} KB',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeFile(i),
                            ),
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => _pickFile(i),
                          icon: const Icon(Icons.upload_file),
                          label: const Text('選擇檔案'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (i < maxFiles - 1) const SizedBox(height: 12),
            ],
            
            const Spacer(),
            
            ElevatedButton(
              onPressed: isProcessing || selectedFiles.isEmpty
                  ? null
                  : _mergeFiles,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('處理中...'),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.merge),
                        SizedBox(width: 8),
                        Text(
                          '合併檔案',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      // ===== 開始修改的部分 =====
      floatingActionButton: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.merge_type),
            label: '合併工具',
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            onTap: () {
              // 因為目前就在這個頁面，所以點擊後不需要做任何事
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.info_outline),
            label: '建議資訊',
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            onTap: () {
              // 導航到新的資訊頁面
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InfoScreen()),
              );
            },
          ),
        ],
      ),
      // ===== 結束修改的部分 =====
    );
  }
}
*/