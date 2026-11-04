import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/services/spot_registry_service.dart';

class UploadPage extends StatefulWidget {
  final SpotRegistryService registryService;
  final Function(String projectName, String day, String spotName, double lat, double lng) onUploadSuccess;
  final List<String> existingProjectNames;

  const UploadPage({
    super.key, 
    required this.registryService,
    required this.onUploadSuccess,
    required this.existingProjectNames,
  });

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  bool _isProcessing = false;
  List<String> _logs = [];

  Future<void> _handleUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result == null || (result.files.single.bytes == null && result.files.single.path == null)) return;

    setState(() {
      _isProcessing = true;
      _logs = ["Starting upload processing..."];
    });

    try {
      // 1. Validation (File Extension & Size)
      final file = result.files.single;
      if (file.extension != 'txt') {
        setState(() => _logs.add("❌ 錯誤：僅支援 .txt 檔案。"));
        return;
      }
      
      final fileSizeKB = (file.size / 1024);
      if (fileSizeKB > 100) {
        setState(() => _logs.add("❌ 錯誤：檔案大小超過 100KB (目前: ${fileSizeKB.toStringAsFixed(1)}KB)。"));
        return;
      }

      String content;
      if (kIsWeb) {
        content = utf8.decode(file.bytes!);
      } else {
        content = await File(file.path!).readAsString();
      }

      final lines = content.split('\n');
      int processedCount = 0;
      final Set<String> checkedProjects = {};

      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        
        // 2. Capacity Limit (Max 10 Spots)
        if (processedCount >= 10) {
          setState(() => _logs.add("⚠️ 已達單次上傳上限 (10個景點)，其餘景點已忽略。"));
          break;
        }

        final parts = line.split(',');
        if (parts.length < 3) {
          setState(() => _logs.add("⚠️ 跳過格式錯誤行：$line"));
          continue;
        }

        final projectName = parts[0].trim();
        final day = parts[1].trim();
        final spotName = parts[2].trim();

        // 3. Project Name Conflict Check
        if (widget.existingProjectNames.contains(projectName) && !checkedProjects.contains(projectName)) {
          setState(() => _logs.add("❌ 錯誤：目前專案中已有相同專案「$projectName」，請修改上傳檔案名稱或調整現有專案名稱。"));
          checkedProjects.add(projectName);
          continue;
        }
        
        if (checkedProjects.contains(projectName) && widget.existingProjectNames.contains(projectName)) {
           // Skip other spots for the same conflicted project
           continue;
        }

        setState(() => _logs.add("🔍 正在搜尋：$spotName..."));

        final coords = await widget.registryService.lookup(spotName);
        if (coords != null) {
          widget.onUploadSuccess(projectName, day, spotName, coords['lat']!, coords['lng']!);
          setState(() => _logs.add("✅ 已新增：$spotName"));
          processedCount++;
        } else {
          setState(() => _logs.add("❌ 找不到位置：$spotName"));
        }
      }
      
      setState(() => _logs.add("🎉 Processing complete!"));
    } catch (e) {
      setState(() => _logs.add("💥 Error: $e"));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("上傳景點 (Bulk Upload)", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              "請上傳 .txt 檔案（上限 100KB），單次上傳限 10 個景點。\n"
              "格式：專案名稱, Day, 景點名稱",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("範例內容 (Example):", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("東京五日遊, Day 1, 東京鐵塔\n東京五日遊, Day 1, 明治神宮\n京都賞楓, Day 2, 金閣寺"),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.tips_and_updates, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "提示：上傳方式請參考上方說明，上傳後的處理結果會在以下呈現，請注意同名專案會被忽略",
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleUpload,
                icon: const Icon(Icons.file_upload),
                label: Text(_isProcessing ? "處理中..." : "選擇檔案並上傳"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text("處理日誌 (Processing Logs):", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(_logs[index], style: const TextStyle(fontFamily: 'monospace')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
