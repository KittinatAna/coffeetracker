import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:coffeetracker/services/firestore_service.dart';

class VisitedShopPage extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String range;

  const VisitedShopPage({super.key, required this.startDate, required this.endDate, required this.range});

  @override
  _VisitedShopPageState createState() => _VisitedShopPageState();
}

class _VisitedShopPageState extends State<VisitedShopPage> {
  final FirestoreService _firestoreService = FirestoreService();
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
      return record['is_purchased'] == true && recordDate.isAfter(widget.startDate) && recordDate.isBefore(widget.endDate);
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

  String _getFormattedDateRange() {
    if (widget.range == 'day') {
      DateTime startofDate = DateTime(widget.startDate.year, widget.startDate.month, widget.startDate.day + 1);
      return DateFormat('d MMMM yyyy').format(startofDate);
    } else if (widget.range == 'week') {
      DateTime startOfWeek = widget.startDate.subtract(Duration(days: widget.startDate.weekday - 8));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      return '${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}';
    } else if (widget.range == 'month') {
      DateTime startOfMonth = DateTime(widget.startDate.year, widget.startDate.month + 2, 0);
      return DateFormat('MMMM yyyy').format(startOfMonth);
    } else if (widget.range == 'year') {
      DateTime startOfYear = DateTime(widget.startDate.year + 2, 1, 0);
      return DateFormat('yyyy').format(startOfYear);
    } else {
      return '';
    }
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
                Text(
                  _getFormattedDateRange(),
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
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
                            _copyToClipboard(shop['shopName']);
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
