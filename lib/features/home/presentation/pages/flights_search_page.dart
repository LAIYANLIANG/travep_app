import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'flight_repository.dart';

class FlightSearchPage extends StatefulWidget {
  const FlightSearchPage({super.key});

  @override
  State<FlightSearchPage> createState() => _FlightSearchPageState();
}

class _FlightSearchPageState extends State<FlightSearchPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers & State
  final TextEditingController _originController = TextEditingController(text: "TPE");
  final TextEditingController _destController = TextEditingController(text: "ICN");
  
  DateTime _departureDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _returnDate;
  
  final Map<String, int> _travelerCounts = {'ADULT': 1, 'CHILD': 0, 'HELD_INFANT': 0};
  String _cabinClass = 'ECONOMY';
  
  final FlightRepository _repo = FlightRepository();
  final DateFormat _df = DateFormat('yyyy/MM/dd');

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("搜尋機票", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Toolbar Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: isWeb ? _buildHorizontalLayout() : _buildVerticalLayout(),
              ),
              
              const SizedBox(height: 24),
              
              // Search Button and Error Message
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ValueListenableBuilder<String?>(
                    valueListenable: _repo.errorNotifier,
                    builder: (context, error, child) {
                      if (error == null) return const SizedBox.shrink();
                      return Expanded(child: Text(error, style: const TextStyle(color: Colors.red)));
                    },
                  ),
                  const SizedBox(width: 16),
                  ValueListenableBuilder<bool>(
                    valueListenable: _repo.isLoadingNotifier,
                    builder: (context, isLoading, child) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                          backgroundColor: const Color(0xff0055D1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: isLoading ? null : _performSearch,
                        child: isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                          : const Text("搜尋", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalLayout() {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildLocationInput("出發地", _originController, true)),
          _buildSeparator(),
          _buildSwapButton(),
          _buildSeparator(),
          Expanded(flex: 2, child: _buildLocationInput("目的地", _destController, false)),
          _buildSeparator(),
          Expanded(flex: 2, child: _buildDateInput("出發", _departureDate, true)),
          _buildSeparator(),
          Expanded(flex: 2, child: _buildDateInput("回程", _returnDate, false)),
          _buildSeparator(),
          Expanded(flex: 3, child: _buildTravelerInput()),
        ],
      ),
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      children: [
        _buildLocationInput("出發地", _originController, true),
        const Divider(height: 1),
        _buildLocationInput("目的地", _destController, false),
        const Divider(height: 1),
        _buildDateInput("出發", _departureDate, true),
        const Divider(height: 1),
        _buildDateInput("回程", _returnDate, false),
        const Divider(height: 1),
        _buildTravelerInput(),
      ],
    );
  }

  Widget _buildSeparator() => Container(width: 1, color: Colors.grey[300]);

  Widget _buildLocationInput(String label, TextEditingController controller, bool isOrigin) {
    return InkWell(
      onTap: () {
        // Future: Show searchable city list
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              validator: (v) => v!.isEmpty ? "必填" : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwapButton() {
    return InkWell(
      onTap: () {
        setState(() {
          String temp = _originController.text;
          _originController.text = _destController.text;
          _destController.text = temp;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        child: const Icon(Icons.swap_horiz, color: Color(0xff0055D1)),
      ),
    );
  }

  Widget _buildDateInput(String label, DateTime? date, bool isDeparture) {
    return InkWell(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context, 
          initialDate: (isDeparture ? date : (date ?? _departureDate.add(const Duration(days: 7))))!,
          firstDate: isDeparture ? DateTime.now() : _departureDate, 
          lastDate: DateTime(2030)
        );
        if (picked != null) {
          setState(() {
            if (isDeparture) {
              _departureDate = picked;
              if (_returnDate != null && _returnDate!.isBefore(_departureDate)) {
                _returnDate = _departureDate.add(const Duration(days: 7));
              }
            } else {
              _returnDate = picked;
            }
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  date != null ? _df.format(date) : "選擇回程日期", 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: date != null ? Colors.black : Colors.grey[400]
                  )
                ),
                if (!isDeparture && _returnDate != null)
                   IconButton(
                     icon: const Icon(Icons.close, size: 16),
                     onPressed: () => setState(() => _returnDate = null),
                     padding: EdgeInsets.zero,
                     constraints: const BoxConstraints(),
                   )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelerInput() {
    int total = _travelerCounts.values.reduce((a, b) => a + b);
    String cabinLabels = {
      'ECONOMY': '經濟艙',
      'PREMIUM_ECONOMY': '豪華經濟艙',
      'BUSINESS': '商務艙',
      'FIRST': '頭等艙'
    }[_cabinClass]!;

    return InkWell(
      onTap: _showTravelerPicker,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("旅客和艙等", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text("$total 位成人, $cabinLabels", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showTravelerPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("選擇旅客與艙等"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   _buildCounterRow("成人", "ADULT", setDialogState),
                   _buildCounterRow("兒童", "CHILD", setDialogState),
                   _buildCounterRow("嬰兒", "HELD_INFANT", setDialogState),
                   const Divider(),
                   DropdownButton<String>(
                     isExpanded: true,
                     value: _cabinClass,
                     items: const [
                       DropdownMenuItem(value: 'ECONOMY', child: Text("經濟艙")),
                       DropdownMenuItem(value: 'PREMIUM_ECONOMY', child: Text("豪華經濟艙")),
                       DropdownMenuItem(value: 'BUSINESS', child: Text("商務艙")),
                       DropdownMenuItem(value: 'FIRST', child: Text("頭等艙")),
                     ],
                     onChanged: (v) {
                       setState(() => _cabinClass = v!);
                       setDialogState(() {});
                     },
                   )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("確定")),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildCounterRow(String label, String key, StateSetter setDialogState) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Text(label, style: const TextStyle(fontSize: 16)),
           Row(
             children: [
               IconButton(
                 icon: const Icon(Icons.remove_circle_outline),
                 onPressed: () {
                   if (_travelerCounts[key]! > (key == 'ADULT' ? 1 : 0)) {
                     setState(() => _travelerCounts[key] = _travelerCounts[key]! - 1);
                     setDialogState(() {});
                   }
                 },
               ),
               Text("${_travelerCounts[key]}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               IconButton(
                 icon: const Icon(Icons.add_circle_outline),
                 onPressed: () {
                   setState(() => _travelerCounts[key] = _travelerCounts[key]! + 1);
                   setDialogState(() {});
                 },
               ),
             ],
           )
        ],
      ),
    );
  }

  void _performSearch() async {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('機票搜尋功能暫停服務'),
          content: const Text('由於 Amadeus 機票 API 費用過於高昂，目前已經暫停提供機票搜尋功能。\n\n如需查詢機票，建議您前往 Skyscanner 或各大航空公司官網查詢。若有商業合作意願，歡迎與我們團隊聯繫。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('確定'),
            )
          ],
        );
      }
    );
  }

  // Temporary fix for _dateController access in performSearch
  TextEditingController get _dateController => TextEditingController(text: DateFormat('yyyy-MM-dd').format(_departureDate));
}
