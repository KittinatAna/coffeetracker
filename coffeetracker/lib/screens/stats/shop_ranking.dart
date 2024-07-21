import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:coffeetracker/services/firestore_service.dart';

class ShopRankingPage extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String range;

  const ShopRankingPage({super.key, required this.startDate, required this.endDate, required this.range});

  @override
  _ShopRankingPageState createState() => _ShopRankingPageState();
}

class _ShopRankingPageState extends State<ShopRankingPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedOrderBy = 'Total Volume';

  Future<Map<String, dynamic>> _fetchConsumptionData() async {
    List<Map<String, dynamic>> records = await _firestoreService.fetchData('coffeerecords');
    int totalDrinks = 0;
    int totalVolume = 0;
    double totalExpenditure = 0.0;
    Map<String, int> coffeeShopDrinks = {};
    Map<String, int> coffeeShopVolume = {};
    Map<String, double> coffeeShopExpenditure = {};

    for (var record in records) {
      DateTime recordDate = DateTime.parse(record['date']);
      // data in range and coffee shop is not empty.
      if (recordDate.isAfter(widget.startDate) && recordDate.isBefore(widget.endDate) && record['coffee_shop'].isNotEmpty) {
        totalDrinks++;
        int volume = record['volume'] ?? 0;
        totalVolume += volume;
        double price = (record['price'] ?? 0.0).toDouble();
        totalExpenditure += price;

        String coffeeShop = record['coffee_shop'];
        coffeeShopDrinks[coffeeShop] = (coffeeShopDrinks[coffeeShop] ?? 0) + 1;
        coffeeShopVolume[coffeeShop] = (coffeeShopVolume[coffeeShop] ?? 0) + volume;
        coffeeShopExpenditure[coffeeShop] = (coffeeShopExpenditure[coffeeShop] ?? 0.0) + price;
      }
    }

    return {
      'totalDrinks': totalDrinks,
      'totalVolume': totalVolume,
      'totalExpenditure': totalExpenditure,
      'coffeeShopDrinks': coffeeShopDrinks,
      'coffeeShopVolume': coffeeShopVolume,
      'coffeeShopExpenditure': coffeeShopExpenditure,
    };
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shop Ranking',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchConsumptionData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final data = snapshot.data!;
            final coffeeShopDrinks = data['coffeeShopDrinks'] as Map<String, int>;
            final coffeeShopVolume = data['coffeeShopVolume'] as Map<String, int>;
            final coffeeShopExpenditure = data['coffeeShopExpenditure'] as Map<String, double>;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _getFormattedDateRange(),
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBarChart(coffeeShopDrinks, coffeeShopVolume, coffeeShopExpenditure),
                  const SizedBox(height: 16),
                  const Divider(height: 10, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order By',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          ),
                        ),
                        _buildOrderByDropdown(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildOrderByDropdown() {
    return DropdownButton<String>(
      value: _selectedOrderBy,
      icon: const Icon(Icons.expand_more),
      borderRadius: BorderRadius.circular(10),
      items: <String>['Total Volume', 'Total Drinks', 'Total Expenditure'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedOrderBy = newValue!;
        });
      },
    );
  }

  Widget _buildBarChart(Map<String, int> coffeeShopDrinks, Map<String, int> coffeeShopVolume, Map<String, double> coffeeShopExpenditure) {
    var isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    late TooltipBehavior tooltipBehavior;
    tooltipBehavior = TooltipBehavior(enable: true);
    late SelectionBehavior selectionBehavior = SelectionBehavior(enable: true, unselectedColor: Colors.grey);
    String xAxisName;
    List<_CoffeeShopData> chartData;

    if (_selectedOrderBy == 'Total Drinks') {
      chartData = coffeeShopDrinks.entries
          .map((entry) => _CoffeeShopData(entry.key, entry.value.toDouble()))
          .toList()
          ..sort((a, b) {
            int result = a.value.compareTo(b.value);
            if (result != 0) return result;
            return b.type.compareTo(a.type);
          });
      xAxisName = 'Drinks';
    } else if (_selectedOrderBy == 'Total Volume') {
      chartData = coffeeShopVolume.entries
          .map((entry) => _CoffeeShopData(entry.key, entry.value.toDouble()))
          .toList()
          ..sort((a, b) {
            int result = a.value.compareTo(b.value);
            if (result != 0) return result;
            return b.type.compareTo(a.type);
          });
      xAxisName = 'mL';
    } else {
      chartData = coffeeShopExpenditure.entries
          .map((entry) => _CoffeeShopData(entry.key, entry.value))
          .toList()
          ..sort((a, b) {
            int result = a.value.compareTo(b.value);
            if (result != 0) return result;
            return b.type.compareTo(a.type);
          });
      xAxisName = 'GBP';
    }

    // Calculate height based on the number of data points
    double chartHeight = 200 + chartData.length * 30.0;
    // Ensure a minimum height
    chartHeight = chartHeight < 300 ? 300 : chartHeight;

    return SizedBox(
      height: chartHeight,
      width: double.infinity,
      child: SfCartesianChart(
        tooltipBehavior: tooltipBehavior,
        primaryXAxis: const CategoryAxis(),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: xAxisName),
        ),
        series: <CartesianSeries>[
          BarSeries<_CoffeeShopData, String>(
            name: 'Coffee Shop',
            dataSource: chartData,
            animationDuration: 650,
            xValueMapper: (_CoffeeShopData data, _) => isLandscape || data.type.length <= 15 ? data.type : '${data.type.substring(0, 15)}...',
            yValueMapper: (_CoffeeShopData data, _) => data.value,
            pointColorMapper: (_CoffeeShopData data, _) => Colors.blue,
            dataLabelSettings: const DataLabelSettings(isVisible: false),
            spacing: 0.4,
            borderRadius: BorderRadius.circular(3),
            enableTooltip: true,
            selectionBehavior: selectionBehavior,
          ),
        ],
      ),
    );
  }
}

class _CoffeeShopData {
  _CoffeeShopData(this.type, this.value);
  final String type;
  final double value;
}
