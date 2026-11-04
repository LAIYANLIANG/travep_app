import 'package:flutter/material.dart';
import '../../data/lodging_service.dart';

class LodgingPage extends StatefulWidget {
  const LodgingPage({super.key});

  @override
  State<LodgingPage> createState() => _LodgingPageState();
}

class _LodgingPageState extends State<LodgingPage> {
  final LodgingService _service = LodgingService();
  
  // Demo Logic: Hardcoded location (e.g., Dongdaemun)
  final double _demoLat = 37.5714;
  final double _demoLng = 127.0097;
  
  // Search Params
  final TextEditingController _checkInController = TextEditingController(text: "2026-02-01");
  final TextEditingController _checkOutController = TextEditingController(text: "2026-02-05");
  final TextEditingController _guestsController = TextEditingController(text: "2");

  List<dynamic> _hotelOffers = [];
  bool _isLoading = false;
  String? _statusMessage;
  String? _error;

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hotelOffers = [];
      _statusMessage = "Step 1/2: Finding hotels near location...";
    });

    try {
      // Step 1: Find Hotels
      final hotels = await _service.searchHotelsByLocation(
        latitude: _demoLat, 
        longitude: _demoLng,
        radius: 3 // km
      );

      if (hotels.isEmpty) {
        setState(() => _error = "No hotels found in this area (Step 1).");
        return;
      }

      final hotelIds = hotels.map<String>((h) => h['hotelId'].toString()).toList();
      setState(() => _statusMessage = "Step 2/2: Checking prices for ${hotelIds.length} hotels...");

      // Step 2: Get Prices
      final offers = await _service.getHotelOffers(
        hotelIds: hotelIds, 
        checkInDate: _checkInController.text, 
        checkOutDate: _checkOutController.text,
        adults: int.parse(_guestsController.text)
      );

      setState(() {
        _hotelOffers = offers;
        _statusMessage = null;
      });

    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hotel Search"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Form
          Container(
             padding: const EdgeInsets.all(16),
             color: Colors.purple[50],
             child: Column(
               children: [
                 Row(
                   children: [
                     Expanded(child: _buildTextField("Check-in", _checkInController, Icons.calendar_today)),
                     const SizedBox(width: 8),
                     Expanded(child: _buildTextField("Check-out", _checkOutController, Icons.calendar_today)),
                   ],
                 ),
                 const SizedBox(height: 8),
                 Row(
                    children: [
                      Expanded(child: _buildTextField("Guests", _guestsController, Icons.person)),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _performSearch,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24)),
                        child: const Text("Search"),
                      )
                    ],
                 )
               ],
             ),
          ),
          
          if (_statusMessage != null)
             Padding(padding: const EdgeInsets.all(8.0), child: Text(_statusMessage!, style: const TextStyle(color: Colors.purple))),

          // Results
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _error != null 
                  ? Center(child: Text("Error: $_error", style: const TextStyle(color: Colors.red)))
                  : _hotelOffers.isEmpty
                     ? const Center(child: Text("No offers found. Try different dates."))
                     : ListView.builder(
                         padding: const EdgeInsets.all(16),
                         itemCount: _hotelOffers.length,
                         itemBuilder: (context, index) {
                           final offerData = _hotelOffers[index];
                           final hotel = offerData['hotel'] ?? {};
                           final offers = offerData['offers'] as List? ?? [];
                           final firstOffer = offers.isNotEmpty ? offers.first : {};
                           final price = firstOffer['price']?['total'] ?? "N/A";
                           final currency = firstOffer['price']?['currency'] ?? "TWD";
                           final room = firstOffer['room']?['description']?['text'] ?? "Standard Room";

                           return Card(
                             margin: const EdgeInsets.only(bottom: 12),
                             child: Padding(
                               padding: const EdgeInsets.all(16),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(hotel['name'] ?? "Unknown Hotel", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                   const SizedBox(height: 4),
                                   Text("📍 ${hotel['latitude']}, ${hotel['longitude']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                   const Divider(),
                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Expanded(child: Text(room, overflow: TextOverflow.ellipsis)),
                                       Text("$currency $price", style: const TextStyle(fontSize: 20, color: Colors.purple, fontWeight: FontWeight.bold)),
                                     ],
                                   )
                                 ],
                               ),
                             ),
                           );
                         },
                     ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 16),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
      ),
    );
  }
}
