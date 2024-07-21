import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:coffeetracker/services/firestore_service.dart';
// import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Charts extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String range;

  const Charts({super.key, required this.startDate, required this.endDate, required this.range});

  @override
  _ChartsState createState() => _ChartsState();
}

class _ChartsState extends State<Charts> {
  final FirestoreService _firestoreService = FirestoreService();
  final TooltipBehavior _tooltipBehavior = TooltipBehavior(enable: true, shared: true);
  final SelectionBehavior _selectionBehavior = SelectionBehavior(enable: true, unselectedColor: Colors.grey);
  String _selectedOrderBy = 'Volume';

  Future<Map<String, dynamic>> _fetchConsumptionData() async {
    List<Map<String, dynamic>> records = await _firestoreService.fetchData('coffeerecords');
    int totalVolume = 0;
    int totalDrinks = 0;
    double totalExpenditure = 0.0;

    Map<DateTime, Map<String, dynamic>> dailyConsumption = {};
    Map<DateTime, Map<String, dynamic>> monthlyConsumption = {};

    for (var record in records) {
      DateTime recordDate = DateTime.parse(record['date']);

      if (recordDate.isAfter(widget.startDate) && recordDate.isBefore(widget.endDate)) {
        int volume = record['volume'] ?? 0;
        double expenditure = record['price'] ?? 0.0;
        totalVolume += volume;
        totalDrinks++;
        totalExpenditure += expenditure;

        // dailyConsumption
        if (!dailyConsumption.containsKey(recordDate)) {
          dailyConsumption[recordDate] = {
            'volume': 0,
            'drinks': 0,
            'expenditure': 0.0,
          };
        }
        dailyConsumption[recordDate]!['volume'] += volume;
        dailyConsumption[recordDate]!['drinks'] += 1;
        dailyConsumption[recordDate]!['expenditure'] += expenditure;

        // monthlyConsumption
        DateTime monthStart = DateTime(recordDate.year, recordDate.month, 1);
        if (!monthlyConsumption.containsKey(monthStart)) {
          monthlyConsumption[monthStart] = {
            'volume': 0,
            'drinks': 0,
            'expenditure': 0.0,
          };
        }
        monthlyConsumption[monthStart]!['volume'] += volume;
        monthlyConsumption[monthStart]!['drinks'] += 1;
        monthlyConsumption[monthStart]!['expenditure'] += expenditure;
      }
    }

    return {
      'totalVolume': totalVolume,
      'totalDrinks': totalDrinks,
      'totalExpenditure': totalExpenditure,
      'dailyConsumption': dailyConsumption,
      'monthlyConsumption': monthlyConsumption,
    };
  }

  String _getFormattedDateRange() {
    if (widget.range == 'week') {
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

  String _getAppBarTitle(String range) {
    if (range == 'week' || range == 'month') {
      return 'Daily Consumption';
    } else if (range == 'year') {
      return 'Monthly Consumption';
    } else {
      return 'Consumption';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(widget.range),
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
            final totalVolume = data['totalVolume'] as int;
            final totalDrinks = data['totalDrinks'] as int;
            final totalExpenditure = data['totalExpenditure'] as double;
            final dailyConsumption = data['dailyConsumption'] as Map<DateTime, Map<String, dynamic>>;
            final monthlyConsumption = data['monthlyConsumption'] as Map<DateTime, Map<String, dynamic>>;

            // Remove minute of startdate and enddate
            DateTime endDatewitheout = DateTime(widget.endDate.year, widget.endDate.month, widget.endDate.day);
            
            List<_ChartData> chartData = [];

            if (widget.range == 'week') {
              List<DateTime> last7Days = List.generate(7, (i) => endDatewitheout.subtract(Duration(days: 7 - i)));
              for (int i = 0; i < last7Days.length; i++) {
                DateTime date = last7Days[i];
                Map<String, dynamic> consumption = dailyConsumption[date] ?? {'volume': 0, 'drinks': 0, 'expenditure': 0.0};
                chartData.add(_ChartData(
                  ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
                  consumption['volume'] ?? 0,
                  consumption['drinks'] ?? 0,
                  consumption['expenditure'] ?? 0.0,
                ));
              }
            } else if (widget.range == 'month') {
              List<DateTime> daysInMonth = List.generate(
                DateTime(widget.startDate.year, widget.startDate.month, 0).day,
                (i) => DateTime(widget.startDate.year, widget.startDate.month + 1, i + 1),
              );
              for (var date in daysInMonth) {
                Map<String, dynamic> consumption = dailyConsumption[date] ?? {'volume': 0, 'drinks': 0, 'expenditure': 0.0};
                chartData.add(_ChartData(
                  DateFormat('dd').format(date),
                  consumption['volume'] ?? 0,
                  consumption['drinks'] ?? 0,
                  consumption['expenditure'] ?? 0.0,
                ));
              }
            } else if (widget.range == 'year') {
              List<DateTime> monthsInYear = List.generate(
                12,
                (i) => DateTime(widget.startDate.add(const Duration(days: 1)).year, i + 1, 1),
              );
              for (var date in monthsInYear) {
                Map<String, dynamic> consumption = monthlyConsumption[date] ?? {'volume': 0, 'drinks': 0, 'expenditure': 0.0};
                chartData.add(_ChartData(
                  DateFormat('MMM').format(date),
                  consumption['volume'] ?? 0,
                  consumption['drinks'] ?? 0,
                  consumption['expenditure'] ?? 0.0,
                ));
              }
            }

            double averageVolume = widget.range == 'week'
                ? totalVolume / 7
                : widget.range == 'month'
                    ? totalVolume / DateTime(widget.startDate.year, widget.startDate.month + 1, 0).day
                    : totalVolume / 12;
            double averageDrinks = widget.range == 'week'
                ? totalDrinks / 7
                : widget.range == 'month'
                    ? totalDrinks / DateTime(widget.startDate.year, widget.startDate.month + 1, 0).day
                    : totalDrinks / 12;
            double averageExpenditure = widget.range == 'week'
                ? totalExpenditure / 7
                : widget.range == 'month'
                    ? totalExpenditure / DateTime(widget.startDate.year, widget.startDate.month + 1, 0).day
                    : totalExpenditure / 12;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  Text(
                    _getFormattedDateRange(),
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(
                        _selectedOrderBy == 'Volume'
                          ? 'Total Consumption'
                          : _selectedOrderBy == 'Drinks'
                              ? 'Total Consumption'
                              : 'Total Expenditure',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: _selectedOrderBy == 'Volume'
                                  ? '$totalVolume'
                                  : _selectedOrderBy == 'Drinks'
                                      ? '$totalDrinks'
                                      : totalExpenditure.toStringAsFixed(2),
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: _selectedOrderBy == 'Volume'
                                  ? '\t\tmL'
                                  : _selectedOrderBy == 'Drinks'
                                      ? '\t\tdrinks'
                                      : '\t\tGBP',
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildOrderByDropdown(),
                  const SizedBox(height: 15),
                  _buildBarChart(chartData),
                  const SizedBox(height: 20),
                  _buildInsights(averageVolume, averageDrinks, averageExpenditure),
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
      items: <String>['Volume', 'Drinks', 'Expenditure'].map((String value) {
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

  Widget _buildBarChart(List<_ChartData> chartData) {
    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(),
        primaryYAxis: const NumericAxis(
          minimum: 0,
        ),
        tooltipBehavior: _tooltipBehavior,
        series: <CartesianSeries>[
          ColumnSeries<_ChartData, String>(
            dataSource: chartData,
            animationDuration: 650,
            selectionBehavior: _selectionBehavior,
            xValueMapper: (_ChartData data, _) => data.date,
            yValueMapper: (_ChartData data, _) => _selectedOrderBy == 'Volume'
                ? data.volume
                : _selectedOrderBy == 'Drinks'
                    ? data.drinks
                    : data.expenditure,
            name: _selectedOrderBy == 'Volume'
                ? 'Volume'
                : _selectedOrderBy == 'Drinks'
                    ? 'Drinks'
                    : 'Expenditure',
            color: Colors.blue,
            borderRadius: BorderRadius.circular(3),
            enableTooltip: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(double averageVolume, double averageDrinks, double averageExpenditure) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        _buildInsightTile('Average Volume', '${averageVolume.toStringAsFixed(2)} mL'),
        _buildInsightTile('Average Drinks', '${averageDrinks.toStringAsFixed(2)} drinks'),
        _buildInsightTile('Average Expenditure', '${averageExpenditure.toStringAsFixed(2)} GBP'),
      ],
    );
  }

  Widget _buildInsightTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(2.0),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.date, this.volume, this.drinks, this.expenditure);

  final String date;
  final int volume;
  final int drinks;
  final double expenditure;
}
