import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:coffeetracker/services/firestore_service.dart';

class TypeRankingPage extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String range;

  const TypeRankingPage({super.key, required this.startDate, required this.endDate, required this.range});

  @override
  _TypeRankingPageState createState() => _TypeRankingPageState();
}

class _TypeRankingPageState extends State<TypeRankingPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedOrderBy = 'Total Volume';

  Future<Map<String, dynamic>> _fetchConsumptionData() async {
    List<Map<String, dynamic>> records = await _firestoreService.fetchData('coffeerecords');
    int totalDrinks = 0;
    int totalVolume = 0;
    double totalExpenditure = 0.0;
    Map<String, int> coffeeTypeDrinks = {};
    Map<String, int> coffeeTypeVolume = {};
    Map<String, double> coffeeTypeExpenditure = {};

    for (var record in records) {
      DateTime recordDate = DateTime.parse(record['date']);
      if (recordDate.isAfter(widget.startDate) && recordDate.isBefore(widget.endDate)) {
        totalDrinks++;
        int volume = record['volume'] ?? 0;
        totalVolume += volume;
        double price = (record['price'] ?? 0.0).toDouble();
        totalExpenditure += price;

        String coffeeType = record['coffee_type_desc'];
        coffeeTypeDrinks[coffeeType] = (coffeeTypeDrinks[coffeeType] ?? 0) + 1;
        coffeeTypeVolume[coffeeType] = (coffeeTypeVolume[coffeeType] ?? 0) + volume;
        coffeeTypeExpenditure[coffeeType] = (coffeeTypeExpenditure[coffeeType] ?? 0.0) + price;
      }
    }

    return {
      'totalDrinks': totalDrinks,
      'totalVolume': totalVolume,
      'totalExpenditure': totalExpenditure,
      'coffeeTypeDrinks': coffeeTypeDrinks,
      'coffeeTypeVolume': coffeeTypeVolume,
      'coffeeTypeExpenditure': coffeeTypeExpenditure,
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
          'Type Ranking',
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
            final coffeeTypeDrinks = data['coffeeTypeDrinks'] as Map<String, int>;
            final coffeeTypeVolume = data['coffeeTypeVolume'] as Map<String, int>;
            final coffeeTypeExpenditure = data['coffeeTypeExpenditure'] as Map<String, double>;

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
                  _buildBarChart(coffeeTypeDrinks, coffeeTypeVolume, coffeeTypeExpenditure),
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

  Widget _buildBarChart(Map<String, int> coffeeTypeDrinks, Map<String, int> coffeeTypeVolume, Map<String, double> coffeeTypeExpenditure) {
    var isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    late TooltipBehavior tooltipBehavior;
    tooltipBehavior = TooltipBehavior(enable: true);
    late SelectionBehavior selectionBehavior = SelectionBehavior(enable: true, unselectedColor: Colors.grey);
    String xAxisName;
    List<_CoffeeTypeData> chartData;

    if (_selectedOrderBy == 'Total Drinks') {
      chartData = coffeeTypeDrinks.entries
          .map((entry) => _CoffeeTypeData(entry.key, entry.value.toDouble()))
          .toList()
          ..sort((a, b) {
            int result = a.value.compareTo(b.value);
            if (result != 0) return result;
            return b.type.compareTo(a.type);
          });
      xAxisName = 'Drinks';
    } else if (_selectedOrderBy == 'Total Volume') {
      chartData = coffeeTypeVolume.entries
          .map((entry) => _CoffeeTypeData(entry.key, entry.value.toDouble()))
          .toList()
          ..sort((a, b) {
            int result = a.value.compareTo(b.value);
            if (result != 0) return result;
            return b.type.compareTo(a.type);
          });
      xAxisName = 'mL';
    } else {
      chartData = coffeeTypeExpenditure.entries
          .map((entry) => _CoffeeTypeData(entry.key, entry.value))
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
          BarSeries<_CoffeeTypeData, String>(
            name: 'Coffee Type',
            dataSource: chartData,
            animationDuration: 650,
            xValueMapper: (_CoffeeTypeData data, _) => isLandscape || data.type.length <= 15 ? data.type : '${data.type.substring(0, 15)}...',
            yValueMapper: (_CoffeeTypeData data, _) => data.value,
            pointColorMapper: (_CoffeeTypeData data, _) => Colors.blue,
            dataLabelSettings: const DataLabelSettings(isVisible: false),
            spacing: 0.2,
            borderRadius: BorderRadius.circular(3),
            enableTooltip: true,
            selectionBehavior: selectionBehavior,
          ),
        ],
      ),
    );
  }
}

class _CoffeeTypeData {
  _CoffeeTypeData(this.type, this.value);
  final String type;
  final double value;
}
