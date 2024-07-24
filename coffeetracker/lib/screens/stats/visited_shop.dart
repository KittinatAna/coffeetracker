import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:coffeetracker/services/firestore_service.dart';

class VisitedShopPage extends StatefulWidget {
  @override
  _VisitedShopPageState createState() => _VisitedShopPageState();
}

class _VisitedShopPageState extends State<VisitedShopPage> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _shopList = [];
  String _sortCriteria = 'volume';

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    List<Map<String, dynamic>> records = await _firestoreService.fetchData('coffeerecords');
    List<Map<String, dynamic>> filteredRecords = records.where((record) {
      DateTime recordDate = DateTime.parse(record['date']);
      return record['is_purchased'] == true && recordDate.isAfter(_startDate.subtract(const Duration(days: 1))) && recordDate.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    Map<String, Map<String, dynamic>> shopSummary = {};

    for (var record in filteredRecords) {
      String shopName = record['coffee_shop'];
      String shopAddress = record['shop_address'];
      String key = '$shopName - $shopAddress';
      int volume = record['volume'];
      double price = record['price'];

      if (!shopSummary.containsKey(key)) {
        shopSummary[key] = {
          'shopName': shopName,
          'address': shopAddress,
          'drinks': 0,
          'volume': 0,
          'expenditure': 0.0,
        };
      }

      shopSummary[key]?['drinks'] += 1;
      shopSummary[key]?['volume'] += volume;
      shopSummary[key]?['expenditure'] += price;
    }

    _shopList = shopSummary.values.toList();

    _sortShopList();

    setState(() {});
  }

  void _sortShopList() {
    if (_sortCriteria == 'volume') {
      _shopList.sort((a, b) => b['volume'].compareTo(a['volume']));
    } else if (_sortCriteria == 'drinks') {
      _shopList.sort((a, b) => b['drinks'].compareTo(a['drinks']));
    } else if (_sortCriteria == 'expenditure') {
      _shopList.sort((a, b) => b['expenditure'].compareTo(a['expenditure']));
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "$text" to clipboard'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Visited Coffee Shop',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextButton(
                  onPressed: () async {
                    DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                    );

                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                      _fetchRecords();
                    }
                  },
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  child: Text(
                    '${DateFormat('dd MMMM yyyy').format(_startDate)} - ${DateFormat('dd MMMM yyyy').format(_endDate)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: _sortCriteria,
              icon: const Icon(Icons.expand_more),
              borderRadius: BorderRadius.circular(10),
              onChanged: (String? newValue) {
                setState(() {
                  _sortCriteria = newValue!;
                  _sortShopList();
                });
              },
              items: <String>['volume', 'drinks', 'expenditure']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    'Sort by ${value[0].toUpperCase()}${value.substring(1)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              iconEnabledColor: Colors.black,
              underline: Container(
                height: 2,
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Long press to copy the shop name',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: _shopList.isNotEmpty
                ? ListView.builder(
                    itemCount: _shopList.length,
                    itemBuilder: (context, index) {
                      var shop = _shopList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 3,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            shop['shopName'],
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${shop['address']}\nDrinks: ${shop['drinks']}\nVolume: ${shop['volume']} mL\nExpenditure: £ ${shop['expenditure'].toStringAsFixed(2)}',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                            ),
                          ),
                          onLongPress: () {
                            _copyToClipboard("${shop['shopName']}");
                          },
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      'No records found',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
