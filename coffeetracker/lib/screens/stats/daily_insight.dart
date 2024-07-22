import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:coffeetracker/services/firestore_service.dart';

class DailyInsight extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String range;

  DailyInsight({super.key, required this.startDate, required this.endDate, required this.range});

  final FirestoreService _firestoreService = FirestoreService();
  final TooltipBehavior _tooltipBehavior = TooltipBehavior(enable: true, shared: true);

  Future<Map<String, dynamic>> _fetchConsumptionData() async {
    List<Map<String, dynamic>> records = await _firestoreService.fetchData('coffeerecords');
    int totalVolume = 0;
    int todaytotalVolume = 0;

    Map<DateTime, Map<String, int>> dailyConsumption = {};

    for (var record in records) {
      DateTime recordDate = DateTime.parse(record['date']);

      if (recordDate.isAfter(startDate) && recordDate.isBefore(endDate)) {
        int todayvolume = record['volume'] ?? 0;
        todaytotalVolume += todayvolume;
      }

      if (recordDate.isAfter(startDate.subtract(const Duration(days: 6))) && recordDate.isBefore(endDate)) {
        int volume = record['volume'] ?? 0;
        totalVolume += volume;
        String coffeeChoice;
        if (record['is_purchased'] == true) {
          coffeeChoice = 'Purchased Coffee';
        } else if (record['is_homemade'] == true) {
          coffeeChoice = 'Homemade Coffee';
        } else if (record['is_vendingmachine'] == true) {
          coffeeChoice = 'Vending Machine';
        } else {
          continue; // Skip if no coffee choice is true
        }

        if (!dailyConsumption.containsKey(recordDate)) {
          dailyConsumption[recordDate] = {
            'Purchased Coffee': 0,
            'Homemade Coffee': 0,
            'Vending Machine': 0,
            'Total': 0,
          };
        }
        dailyConsumption[recordDate]![coffeeChoice] = (dailyConsumption[recordDate]![coffeeChoice] ?? 0) + volume;
        dailyConsumption[recordDate]!['Total'] = (dailyConsumption[recordDate]!['Total'] ?? 0) + volume;
      }
    }

    return {
      'todaytotalVolume': todaytotalVolume,
      'totalVolume': totalVolume,
      'dailyConsumption': dailyConsumption,
    };
  }

  String _getFormattedDateRange() {
    if (range == 'day') {
      DateTime startofDate = DateTime(startDate.year, startDate.month, startDate.day + 1);
      return DateFormat('d MMMM yyyy').format(startofDate);
    } else {
      return '';
    }
  }

  String _getTrendDescription(List<_ChartData> trendData) {
    int n = trendData.length;

    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;

    for (int i = 0; i < n; i++) {
      double x = i.toDouble();
      double y = trendData[i].total.toDouble();
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

    if (slope > 0) {
      return 'Increasing';
    } else if (slope < 0) {
      return 'Decreasing';
    } else {
      return 'None';
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daily Insight',
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
            final todaytotalVolume = data['todaytotalVolume'] as int;
            final totalVolume = data['totalVolume'] as int;
            final dailyConsumption = data['dailyConsumption'] as Map<DateTime, Map<String, int>>;
            final averageVolume = (data['totalVolume'] as int) / 7;

            List<_ChartData> trendData = [];
            List<DateTime> last7Days = List.generate(7, (i) => endDate.subtract(Duration(days: 7 - i)));
            for (int i = 0; i < last7Days.length; i++) {
              DateTime date = last7Days[i];
              Map<String, int> consumption = dailyConsumption[date] ?? {'Purchased Coffee': 0, 'Homemade Coffee': 0, 'Vending Machine': 0, 'Total': 0};
              trendData.add(_ChartData(
                DateFormat('dd MMM').format(date),
                consumption['Purchased Coffee'] ?? 0,
                consumption['Homemade Coffee'] ?? 0,
                consumption['Vending Machine'] ?? 0,
                consumption['Total'] ?? 0,
              ));
            }
            // print('last7Days: $last7Days');
            // print('trendData: $trendData');
            String trendDescription = _getTrendDescription(trendData);
            

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
                    child: 
                    ListTile(
                      title: Text(
                        'Today',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$todaytotalVolume',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: '\t\tmL',
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
                  const SizedBox(height: 10),
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
                    child: 
                    ListTile(
                      title: Text(
                        'Last 7 Days',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$totalVolume',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: '\t\tmL',
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
                  const SizedBox(height: 20),
                  _buildStackedColumnChart(dailyConsumption),
                  const SizedBox(height: 5),
                  _buildLegend(),
                  const SizedBox(height: 20),
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
                    child: 
                    ListTile(
                      title: Text(
                        'Daily Average',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        '${averageVolume.toStringAsFixed(2)} mL',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ),
                  ),
                  const SizedBox(height: 10),
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
                    child: 
                    ListTile(
                      title: Text(
                        'Trends',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        trendDescription,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildRecommendation(todaytotalVolume, totalVolume),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildStackedColumnChart(Map<DateTime, Map<String, int>> dailyConsumption) {
    List<_ChartData> chartData = [];
    List<DateTime> last7Days = List.generate(7, (i) => endDate.subtract(Duration(days: 7 - i)));
    List<_ChartData> trendData = [];

    for (int i = 0; i < last7Days.length; i++) {
      DateTime date = last7Days[i];
      Map<String, int> consumption = dailyConsumption[date] ?? {'Purchased Coffee': 0, 'Homemade Coffee': 0, 'Vending Machine': 0, 'Total': 0};

      chartData.add(_ChartData(
        DateFormat('dd MMM').format(date),
        consumption['Purchased Coffee'] ?? 0,
        consumption['Homemade Coffee'] ?? 0,
        consumption['Vending Machine'] ?? 0,
        consumption['Total'] ?? 0,
      ));

      trendData.add(_ChartData(
        DateFormat('dd MMM').format(date),
        0,
        0,
        0,
        consumption['Total'] ?? 0,
      ));
    }
    
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: SfCartesianChart(
            primaryXAxis: const CategoryAxis(),
            primaryYAxis: const NumericAxis(
              minimum: 0,
            ),
            tooltipBehavior: _tooltipBehavior,
            series: <CartesianSeries>[
              StackedColumnSeries<_ChartData, String>(
                dataSource: chartData,
                animationDuration: 650,
                xValueMapper: (_ChartData data, _) => data.date,
                yValueMapper: (_ChartData data, _) => data.purchasedCoffee,
                name: 'Purchased Coffee',
                color: const Color.fromARGB(255, 255, 155, 119),
              ),
              StackedColumnSeries<_ChartData, String>(
                dataSource: chartData,
                animationDuration: 650,
                xValueMapper: (_ChartData data, _) => data.date,
                yValueMapper: (_ChartData data, _) => data.homemadeCoffee,
                name: 'Homemade Coffee',
                color: const Color.fromARGB(255, 159, 222, 108),
              ),
              StackedColumnSeries<_ChartData, String>(
                dataSource: chartData,
                animationDuration: 650,
                xValueMapper: (_ChartData data, _) => data.date,
                yValueMapper: (_ChartData data, _) => data.vendingMachineCoffee,
                name: 'Vending Machine',
                color: const Color.fromARGB(255, 118, 215, 239),
              ),
              SplineSeries<_ChartData, String>(
                animationDuration: 650,
                dataSource: trendData,
                xValueMapper: (_ChartData data, _) => data.date,
                yValueMapper: (_ChartData data, _) => data.total,
                name: 'Trend Line',
                color: const Color.fromARGB(0, 0, 0, 0), // hide the line chart
                width: 2,
                trendlines:<Trendline>[
                  Trendline(
                type: TrendlineType.linear,
                color: Colors.blue)
                ],
              ),
            ],
            onTooltipRender: (TooltipArgs args) {
              final pointIndex = args.pointIndex!.toInt();
              final data = chartData[pointIndex];
              args.text = 
                    'Purchased: ${data.purchasedCoffee} mL\n'
                    'Homemade: ${data.homemadeCoffee} mL\n'
                    'Vending: ${data.vendingMachineCoffee} mL\n'
                    'Total: ${data.total}';
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Center(
      child: Column(
        children: [
          _buildLegendItem(BoxShape.circle, const Color.fromARGB(255, 255, 155, 119), 'Purchased Coffee'),
          const SizedBox(height: 5),
          _buildLegendItem(BoxShape.circle, const Color.fromARGB(255, 159, 222, 108), 'Homemade Coffee'),
          const SizedBox(height: 5),
          _buildLegendItem(BoxShape.circle, const Color.fromARGB(255, 118, 215, 239), 'Vending Machine'),
          const SizedBox(height: 5),
          _buildLegendItem(BoxShape.circle, Colors.blue, 'Trend Line'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BoxShape boxShape, Color color, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: boxShape,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendation(int todaytotalVolume, int totalVolume) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: 
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notes',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Monitoring your coffee intake is important for maintaining good health and'
                'ensuring you stay within safe consumption limits. Based on health guidelines,'
                'it is generally recommended that adults limit their caffeine intake'
                'to no more than 400 milligrams (mg) per day, which is approximately 960 milliliters (mL) of coffee.',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartData {
  _ChartData(this.date, this.purchasedCoffee, this.homemadeCoffee, this.vendingMachineCoffee, this.total);

  final String date;
  final int purchasedCoffee;
  final int homemadeCoffee;
  final int vendingMachineCoffee;
  final int total;

  @override
  String toString() {
    return 'Date: $date, Purchased: $purchasedCoffee, Homemade: $homemadeCoffee, Vending: $vendingMachineCoffee, Total: $total';
  }
}
