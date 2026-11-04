import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../domain/services/gemini_service.dart';
import '../../../../injection_container.dart';
import '../../../upload/domain/services/spot_registry_service.dart';
import '../../domain/services/smart_trip_service.dart';
import 'package:dio/dio.dart';
import '../../../../features/home/presentation/pages/flight_repository.dart';
import '../../../../core/services/billing_service.dart';

class SmartPlannerPage extends StatefulWidget {
  final Function(String projectName, List<Map<String, dynamic>> items) onApplyPlan;

  const SmartPlannerPage({super.key, required this.onApplyPlan});

  @override
  State<SmartPlannerPage> createState() => _SmartPlannerPageState();
}

class _SmartPlannerPageState extends State<SmartPlannerPage> {
  final TextEditingController _controller = TextEditingController();
  // 更新: 訊息結構加入 source 欄位以區分來源 ("start_planning" 或 "smart_chat")
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _isDirty = false; // Tracks unsaved changes
  bool _linkSettingsToChat = false; // 控制是否將上方設定帶入智慧規劃（預設關閉，獨立運作）
  String _budgetStr = ""; // UI State for text field
  late final GeminiService _geminiService;
  late final SpotRegistryService _registryService;
  late final SmartTripService _smartTripService;

  // Settings UI State
  final bool _isSettingsExpanded = true;
  final _formKey = GlobalKey<FormState>();
  
  // Form Data
  String _departureCity = "";
  String _destCity = "";
  
  DateTime _startDate = DateTime.now().add(const Duration(days: 30));
  DateTime _endDate = DateTime.now().add(const Duration(days: 35));
  String _deptTime = "Morning";
  String _retTime = "Afternoon";
  int _budget = 0;
  int _adults = 1;
  int _children = 0; 

  /// 驗證城市名稱是否包含特殊符號
  /// 僅允許中英文、數字、空格、常見標點符號
  bool _hasInvalidCharacters(String text) {
    if (text.trim().isEmpty) return true;
    final validPattern = RegExp(r'^[\u4e00-\u9fa5a-zA-Z0-9\s,.-]+$');
    return !validPattern.hasMatch(text);
  }

  @override
  void initState() {
    super.initState();
    _geminiService = sl<GeminiService>();
    _registryService = sl<SpotRegistryService>();
    // Inject Dio directly or use sl if registered. Assuming sl<Dio>() is available (it is in injection_container)
    _smartTripService = SmartTripService(sl<Dio>(), baseUrl: 'http://127.0.0.1:8080'); 
  }

  Future<void> _handleTripPlan({String? userQuery}) async {
    print('🟣 [_handleTripPlan] Called with userQuery: ${userQuery ?? "null"}');
    
    // Validate Form ONLY for "Start Planning" (when userQuery is null)
    if (userQuery == null && !_formKey.currentState!.validate()) {
      print('❌ [_handleTripPlan] Form validation failed');
      return;
    }
    print('✅ [_handleTripPlan] Validation passed or skipped');

    // --- Billing Interceptor ---
    try {
      // 呼叫 AI 的點數固定為 3 點 (先扣除免費次數)
      await BillingService().checkAndDeductPoints(3);
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('點數不足或無額度'),
            content: Text((e as InsufficientPointsException).message),
            actions: [
               TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
               ElevatedButton(
                 onPressed: () {
                   Navigator.pop(ctx);
                   // 提示前往側邊欄「繳費管理」
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請從左側邊欄前往【繳費管理】進行儲值或觀看廣告。')));
                 },
                 style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white),
                 child: const Text('前往儲值 (繳費管理)')
               )
            ]
          )
        );
      }
      return;
    }
    // --- Billing Interceptor End ---
    setState(() {
       _isLoading = true;
       _messages.add({"role": "user", "content": "Requesting trip plan for $_destCity..."});
    });

    // Determine if we should use form settings
    // Use form settings if:
    // 1. It is a direct "Start Planning" call (userQuery is null)
    // 2. OR it is a Smart Chat call AND linkage is ON
    final bool useForm = (userQuery == null) || _linkSettingsToChat;
    
    // DEBUG: Print toggle state and decision
    print('🔧 [DEBUG] _linkSettingsToChat: $_linkSettingsToChat');
    print('🔧 [DEBUG] userQuery: ${userQuery ?? "null"}');
    print('🔧 [DEBUG] useForm: $useForm');
    print('🔧 [DEBUG] Will send:');
    print('  - departureCity: ${useForm ? _departureCity : "EMPTY"}');
    print('  - destination: ${useForm ? _destCity : "EMPTY"}');
    print('  - startDate: ${useForm ? _startDate.toIso8601String().split('T')[0] : DateTime.now().toIso8601String().split('T')[0]}');
    print('  - endDate: ${useForm ? _endDate.toIso8601String().split('T')[0] : DateTime.now().add(const Duration(days: 4)).toIso8601String().split('T')[0]}');
    print('  - budget: ${useForm ? _budget : 0}');
    print('  - adults: ${useForm ? _adults : 1}, children: ${useForm ? _children : 0}');
    
    print('🔵 [_handleTripPlan] About to call API...');
    try {
      final result = await _smartTripService.searchSmartFlights(
        departureCity: useForm ? _departureCity : "",
        destination: useForm ? _destCity : "",
        startDate: useForm ? _startDate.toIso8601String().split('T')[0] : DateTime.now().toIso8601String().split('T')[0],
        endDate: useForm ? _endDate.toIso8601String().split('T')[0] : DateTime.now().add(const Duration(days: 4)).toIso8601String().split('T')[0],
        departureTimeInfo: useForm ? _deptTime : "Morning",
        returnTimeInfo: useForm ? _retTime : "Evening",
        budget: useForm ? _budget : 0,
        peopleAdults: useForm ? _adults : 1,
        peopleChildren: useForm ? _children : 0,
        returnOrigin: useForm ? _destCity : "", 
        returnDest: useForm ? _departureCity : "",
        userQuery: userQuery // Pass query to backend
      );
      print('🔵 [_handleTripPlan] API call completed');
      print('🔵 [_handleTripPlan] Result is null: ${result == null}');

      if (result != null) {
          // Construct a rich response message
          // We'll hide the raw JSON in a proprietary tag if needed, or just format it as Markdown.
          
          final flight = (result['flights'] as List).isNotEmpty ? result['flights'][0] : null;
          final price = flight != null ? flight['price']['total'] : "N/A";
          final itinerary = (flight != null && flight['itineraries'] != null) ? flight['itineraries'] as List : [];
          
          String flightMd = "### ✈️ 推薦航班 (Recommended Flight)\n";
          if (flight != null) {
             flightMd += "**總價格**: $price TWD\n\n";
             int segCount = 1;
             for (var itin in itinerary) {
                flightMd += "*航段 $segCount (${itin['duration']})*\n";
                for (var seg in itin['segments']) {
                   flightMd += "   - ${seg['departure']['iataCode']} (${seg['departure']['at']}) -> ${seg['arrival']['iataCode']} (${seg['arrival']['at']}) : ${seg['carrierCode']} ${seg['number']}\n";
                }
                segCount++;
             }
          } else {
             flightMd += "在您的預算內找不到符合的航班。\n";
          }
          
          // Itinerary Outline
          String outlineMd = "\n### 🗺️ 行程大綱 (Itinerary Outline)\n";
          List<dynamic> outline = result['itinerary_outline'] ?? [];
          final destinationName = result['metadata']?['effective_destination'] ?? (_destCity.isNotEmpty ? _destCity : "自由行");
          // Store raw JSON for "Apply"
          Map<String, dynamic> planJson = {
             "project_name": "Trip to $destinationName",
             "days": []
          };
          
          for (var day in outline) {
             outlineMd += "**Day ${day['day']}**: ${day['title']}\n";
             if (day['highlights'] != null) {
               outlineMd += "_${day['highlights']}_\n";
             }
             outlineMd += "> ${day['activities']}\n";
             
             List<dynamic> daySpots = [];
             if (day['spots'] != null && day['spots'] is List) {
               daySpots = List<dynamic>.from(day['spots']);
               for (var s in daySpots) {
                 final cat = (s['category'] != null && s['category'].toString().isNotEmpty) ? "[${s['category']}] " : "";
                 final notes = (s['notes'] != null && s['notes'].toString().isNotEmpty) ? " (${s['notes']})" : "";
                 outlineMd += "  - $cat${s['name']}$notes\n";
               }
             }
             outlineMd += "\n";
             
             // Build Plan JSON with real spots & coordinates
             (planJson['days'] as List).add({
                "label": day['title'] ?? "Day ${day['day']}",
                "spots": daySpots
             });
          }
          
          // If the backend returns a structured plan we can use it.
          // Currently backend returns `itinerary_outline` which is a list of dicts.
          // Let's attach the raw JSON for reference
          
          String responseContent = "$flightMd\n$outlineMd\n\n若要套用此行程，請點擊下方按鈕。";
          
          // Inject valid JSON for the Parse button
          responseContent += "\n<PLAN_JSON>\n${jsonEncode(planJson)}\n</PLAN_JSON>";

          // Save to Repository
          FlightRepository().saveFlights(result);

          // Automatically sync all AI-discovered spots & coordinates into SpotRegistryService
          int registeredCount = 0;
          for (var day in outline) {
             if (day['spots'] != null && day['spots'] is List) {
                for (var s in day['spots']) {
                   final name = s['name']?.toString() ?? '';
                   final lat = (s['lat'] as num?)?.toDouble();
                   final lng = (s['lng'] as num?)?.toDouble();
                   if (name.isNotEmpty && lat != null && lng != null && lat != 0.0 && lng != 0.0) {
                      _registryService.register(name, lat, lng);
                      registeredCount++;
                   }
                }
             }
          }
          debugPrint('✅ [SpotRegistryService] Auto-updated $registeredCount spots into local registry cache.');
          
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('✅ 機票已更新，且已自動將 AI 探索到的 $registeredCount 個景點座標存入知識庫！'),
                 backgroundColor: Colors.teal,
                 duration: const Duration(seconds: 3),
               )
             );
          }

          setState(() {
             // 標記為 Start Planning 來源，不顯示「套用此行程到編輯器」按鈕
            if (userQuery == null) {
               // Direct Start Planning call (no custom query from chat)
               _messages.add({"role": "ai", "content": responseContent, "source": "start_planning"});
             } else {
               // Called from Smart Chat - show apply button
               _messages.add({"role": "ai", "content": responseContent, "source": "smart_chat"});
             }
             _isDirty = true;
          });
      } else {
         setState(() => _messages.add({"role": "ai", "content": "❌ Failed to fetch trip plan. Please try again."}));
      }

    } catch (e, stackTrace) {
       print('❌ [ERROR] Trip planning failed: $e');
       print('❌ [STACK] $stackTrace');
       setState(() => _messages.add({"role": "ai", "content": "❌ 發生錯誤：$e\n\n請確認後端服務是否正常運行，或查看 Console 了解詳情。"}));
    } finally {
       setState(() => _isLoading = false);
    }
  }

  /// 智慧規劃功能：選擇性整合上方表單資料，不強制要求所有欄位填寫
  Future<void> _sendMessage() async {
    print('🟢 [_sendMessage] Method called');
    final text = _controller.text.trim();
    print('🟢 [_sendMessage] Text: "$text"');
    
    if (text.isEmpty) {
      print('🟡 [_sendMessage] Text is empty, returning');
      return;
    }
    
    // 檢查字數限制（100字）
    if (text.length > 100) {
      print('🟡 [_sendMessage] Text too long: ${text.length} chars');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ 輸入內容不可超過 100 字'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }
    print('🟢 [_sendMessage] Validation passed');
    
    // 如果上方表單欄位有值，且串接開關開啟，自動 append 到用戶輸入中
    String enhancedQuery = text;
    
    if (_linkSettingsToChat) {
      List<String> contextParts = [];
      
      if (_departureCity.isNotEmpty) contextParts.add('出發城市: $_departureCity');
      if (_destCity.isNotEmpty) contextParts.add('目的地: $_destCity');
      if (_budget > 0) contextParts.add('預算: $_budget 萬/人');
      if (_adults > 0 || _children > 0) {
        contextParts.add('人數: 成人 $_adults 人, 孩童 $_children 人');
      }
      
      // Append form context if exists
      if (contextParts.isNotEmpty) {
        enhancedQuery += '\\n\\n[行程設定參考: ${contextParts.join(', ')}]';
      }
    }

    // Clear controller and show user message
    _controller.clear();
    print('🟢 [_sendMessage] Controller cleared');
    
    setState(() {
      _messages.add({"role": "user", "content": text}); // 只顯示用戶原始輸入
    });
    print('🟢 [_sendMessage] User message added to chat');
    print('🟢 [_sendMessage] Enhanced query: "$enhancedQuery"');
    print('🟢 [_sendMessage] Calling _handleTripPlan...');

    // Trigger smart search with enhanced query
    await _handleTripPlan(userQuery: enhancedQuery);
    print('🟢 [_sendMessage] _handleTripPlan completed');
  }

  Future<void> _parseAndApply(String content) async {
    try {
      final regExp = RegExp(r'<PLAN_JSON>(.*?)</PLAN_JSON>', dotAll: true);
      final match = regExp.firstMatch(content);
      if (match != null) {
        String jsonStr = match.group(1)?.trim() ?? '';
        
        // Robust cleaning: AI often wraps JSON in ```json ... ``` even inside our tags
        if (jsonStr.startsWith('```')) {
          // Remove ```json or ``` at the start
          jsonStr = jsonStr.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
          // Remove ``` at the end
          jsonStr = jsonStr.replaceFirst(RegExp(r'\s*```$'), '');
          jsonStr = jsonStr.trim();
        }

        if (jsonStr.isNotEmpty) {
          debugPrint('Parsing cleaned JSON: $jsonStr');
          final data = jsonDecode(jsonStr);
          final String projectName = data['project_name'] ?? 'AI Trip';
          final List<dynamic> days = data['days'] ?? [];
          
          List<Map<String, dynamic>> items = [];
          for (var day in days) {
            items.add({
              'type': 'PlannerItemType.dayHeader',
              'label': day['label'] ?? 'Day',
            });
            final List<dynamic> spots = day['spots'] ?? [];
            for (var spot in spots) {
              final String spotName = spot['name'] ?? 'Unknown Spot';
              
              // 1. Direct coordinate from backend AI spot
              double? lat = spot['lat'] != null ? (spot['lat'] as num).toDouble() : null;
              double? lng = spot['lng'] != null ? (spot['lng'] as num).toDouble() : null;
              
              // 2. Fallback to Registry Service lookup if coordinates are missing or zero
              if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) {
                final coords = await _registryService.lookup(spotName);
                if (coords != null) {
                  lat = coords['lat'];
                  lng = coords['lng'];
                }
              }

              // 3. Register to cache (SharedPreferences)
              if (lat != null && lng != null && lat != 0.0) {
                _registryService.register(spotName, lat, lng);
              }

              items.add({
                'type': 'PlannerItemType.waypoint',
                'id': 'ai_spot_${DateTime.now().microsecondsSinceEpoch}_$spotName',
                'name': spotName,
                'showName': spotName,
                'category': spot['category'] ?? '景點',
                'notes': spot['notes'] ?? '',
                'lat': lat, 
                'lng': lng,
              });
            }
          }
          widget.onApplyPlan(projectName, items);
          setState(() => _isDirty = false); // Clear dirty flag on apply
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find structured plan in response.'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error parsing plan: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('尚未儲存行程'),
            content: const Text('如果未存檔，系統將無法儲存你的操作，要回去先儲存嗎？'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('關閉 (不儲存)')),
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
            ],
          ),
        );
        if (shouldPop == true) {
           if (context.mounted) Navigator.of(context).pop();
        }
      },
        child: Column(
          children: [
            // --- SECTION 1: START PLANNING (常駐顯示) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                     // Header
                     const Row(
                       children: [
                          Icon(Icons.flight_takeoff, color: Colors.purple),
                          SizedBox(width: 8),
                          Text("Start Planning (基本設定)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                       ],
                     ),
                     const SizedBox(height: 16),
                     // Cities Row
                     Row(
                       children: [
                           Expanded(child: TextFormField(
                            initialValue: _departureCity,
                            decoration: const InputDecoration(labelText: "出發城市 *", prefixIcon: Icon(Icons.location_on, size: 16), isDense: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return '必填';
                              if (_hasInvalidCharacters(v)) return '不可包含特殊符號';
                              return null;
                            },
                            onChanged: (v) => _departureCity = v,
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: TextFormField(
                            initialValue: _destCity,
                            decoration: const InputDecoration(labelText: "目的地 *", prefixIcon: Icon(Icons.flag, size: 16), isDense: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return '必填';
                              if (_hasInvalidCharacters(v)) return '不可包含特殊符號';
                              return null;
                            },
                            onChanged: (v) => _destCity = v,
                          )),
                       ]
                     ),
                     const SizedBox(height: 12),
                     // Dates & Times Row
                     Row(
                       children: [
                          // Start
                          Expanded(flex: 3, child: InkWell(
                            onTap: () async {
                               final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2030), initialDate: _startDate);
                               if (d != null) setState(() => _startDate = d);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: "去程日期 *", isDense: true, border: OutlineInputBorder()),
                              child: Text("${_startDate.year}/${_startDate.month}/${_startDate.day}"),
                            ),
                          )),
                          const SizedBox(width: 8),
                          Expanded(flex: 2, child: DropdownButtonFormField<String>(
                            initialValue: _deptTime,
                            isDense: true,
                            decoration: const InputDecoration(labelText: "時段", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                            items: ["Morning", "Afternoon", "Evening", "Night"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (v) => setState(() => _deptTime = v!),
                          )),
                          
                          const SizedBox(width: 8),
                          // End
                          Expanded(flex: 3, child: InkWell(
                            onTap: () async {
                               final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2030), initialDate: _endDate);
                               if (d != null) setState(() => _endDate = d);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: "回程日期 *", isDense: true, border: OutlineInputBorder()),
                              child: Text("${_endDate.year}/${_endDate.month}/${_endDate.day}"),
                            ),
                          )),
                          const SizedBox(width: 8),
                          Expanded(flex: 2, child: DropdownButtonFormField<String>(
                            initialValue: _retTime,
                            isDense: true,
                            decoration: const InputDecoration(labelText: "時段", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                            items: ["Morning", "Afternoon", "Evening", "Night"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (v) => setState(() => _retTime = v!),
                          )),
                       ]
                     ),
                     const SizedBox(height: 12),
                     // People Row
                     Row(
                       children: [
                          Expanded(child: TextFormField(
                            initialValue: _adults.toString(),
                            decoration: const InputDecoration(labelText: "成人人數 *", isDense: true, border: OutlineInputBorder(), suffixText: "人"),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                               final n = int.tryParse(v ?? "");
                               if (n == null || n < 1) return '最少1人';
                               return null;
                            },
                            onChanged: (v) => _adults = int.tryParse(v) ?? 1,
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: TextFormField(
                            initialValue: _children.toString(),
                            decoration: const InputDecoration(labelText: "孩童人數", isDense: true, border: OutlineInputBorder(), suffixText: "人"),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => _children = int.tryParse(v) ?? 0,
                          )),
                       ]
                     ),
                     const SizedBox(height: 12),
                     // Budget & Action
                     Row(
                       children: [
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              initialValue: _budgetStr,
                              decoration: const InputDecoration(labelText: "預算(萬)/人 *", suffixText: "萬TWD", isDense: true, border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return '必填';
                                final n = int.tryParse(v);
                                if (n == null || n <= 0) return '預算必須大於 0';
                                return null;
                              },
                              onChanged: (v) { _budgetStr = v; _budget = int.tryParse(v) ?? 0; },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: _isLoading ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search),
                              label: Text(_isLoading ? "Searching..." : "Start Planning"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16)
                              ),
                              onPressed: _isLoading ? null : _handleTripPlan,
                            ),
                          )
                       ]
                     )
                  ],
                ),
              ),
            ),

            // --- SECTION 2: LINKAGE TOGGLE ---
            Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: SwitchListTile(
                value: _linkSettingsToChat,
                onChanged: (val) => setState(() => _linkSettingsToChat = val),
                title: const Text("串接設定：Smart Chat 將參考上方設定", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text("開啟後，智慧規劃會自動帶入上方地點、預算等資訊", style: TextStyle(fontSize: 12, color: Colors.grey)),
                activeThumbColor: Colors.blue,
                dense: true,
              ),
            ),
            const Divider(height: 1, thickness: 1),

        Expanded(

          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isUser = msg['role'] == 'user';
              return Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser 
                        ? Colors.blue[100] 
                        : (msg['content']!.contains('限定旅遊排程') ? Colors.yellow[300] : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                      border: msg['content']!.contains('限定旅遊排程') 
                        ? Border.all(color: Colors.red, width: 2) 
                        : null,
                    ),
                    child: isUser 
                      ? Text(msg['content']!)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MarkdownBody(
                              data: msg['content']!.split('<PLAN_JSON>')[0],
                              styleSheet: msg['content']!.contains('限定旅遊排程') 
                                ? MarkdownStyleSheet(
                                    p: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
                                    strong: const TextStyle(fontSize: 36, color: Colors.black, backgroundColor: Colors.yellow),
                                  )
                                : null,
                            ),
                            // 僅當來源不是 Start Planning 且包含 PLAN_JSON 時才顯示「套用此行程到編輯器」按鈕
                            if (msg['content']!.contains('<PLAN_JSON>') && msg['source'] != 'start_planning')
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: ElevatedButton.icon(
                                  onPressed: () => _parseAndApply(msg['content']!),
                                  icon: const Icon(Icons.playlist_add_check),
                                  label: const Text('套用此行程到編輯器'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(),
        Container(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: 100, // 限制輸入最多 100 字
                      decoration: const InputDecoration(
                        hintText: '描述您的旅行需求...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text("智慧規劃"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '💡 問題詢問請說明要出發的地點、日期、預算、人數、家庭、個人…之類的旅遊需求，例如：我四月要去菲律賓玩6天，預算7萬，家庭4人二大二小。',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
      ),
    );
  }
}
