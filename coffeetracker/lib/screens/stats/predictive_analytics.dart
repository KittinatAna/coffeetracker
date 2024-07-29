import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:coffeetracker/services/firestore_service.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:coffeetracker/services/tfliteservice.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PredictiveAnalytics extends StatefulWidget {
  final String range;

  const PredictiveAnalytics({super.key, required this.range});

  @override
  _PredictiveAnalyticsState createState() => _PredictiveAnalyticsState();
}

class _PredictiveAnalyticsState extends State<PredictiveAnalytics> {
  final FirestoreService _firestoreService = FirestoreService();
  final TooltipBehavior _tooltipBehavior = TooltipBehavior(enable: true, shared: true);
  final TFLiteService _tfliteService = TFLiteService();
  String _selectedMetric = 'Volume';

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    await _tfliteService.loadModel();
  }

  Future<Map<String, dynamic>> _fetchConsumptionData() async {
    List<Map<String, dynamic>> records = await _firestoreService.fetchData('coffeerecords');
    int totalVolume = 0;
    double totalExpenditure = 0.0;

    Map<DateTime, Map<String, dynamic>> monthlyConsumption = {};
    // Map<DateTime, Map<String, dynamic>> yearlyConsumption = {};

    DateTime currentMonth = DateTime.now();
    DateTime afterDate = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    DateTime sixMonthsAgo = DateTime(currentMonth.year, currentMonth.month - 5, 1);

    print('currentMonth: $currentMonth');
    print('afterDate: $afterDate');
    print('sixMonthsAgo: $sixMonthsAgo');

    for (var record in records) {
      DateTime recordDate = DateTime.parse(record['date']);
      if (recordDate.isBefore(sixMonthsAgo)) {
        continue; // Skip records older than 6 months
      }

      if (recordDate.isAfter(afterDate)) {
        continue; // Skip records newer than current month
      }

      int volume = record['volume'] ?? 0;
      double expenditure = record['price'] ?? 0.0;
      totalVolume += volume;
      totalExpenditure += expenditure;

      // monthlyConsumption
      DateTime monthStart = DateTime(recordDate.year, recordDate.month, 1);
      if (!monthlyConsumption.containsKey(monthStart)) {
        monthlyConsumption[monthStart] = {
          'volume': 0,
          'expenditure': 0.0,
        };
      }
      monthlyConsumption[monthStart]!['volume'] += volume;
      monthlyConsumption[monthStart]!['expenditure'] += expenditure;

      // yearlyConsumption - Future Development
      // DateTime yearStart = DateTime(recordDate.year, 1, 1);
      // if (!yearlyConsumption.containsKey(yearStart)) {
      //   yearlyConsumption[yearStart] = {
      //     'volume': 0,
      //     'expenditure': 0.0,
      //   };
      // }
      // yearlyConsumption[yearStart]!['volume'] += volume;
      // yearlyConsumption[yearStart]!['expenditure'] += expenditure;
    }

    // Ensure last 6 months are included with default values if missing
    for (int i = 5; i >= 0; i--) {
      DateTime month = DateTime(currentMonth.year, currentMonth.month - i, 1);
      if (!monthlyConsumption.containsKey(month)) {
        monthlyConsumption[month] = {
          'volume': 0,
          'expenditure': 0.0,
        };
      }
    }

    final sortedMonthlyConsumption = Map.fromEntries(
      monthlyConsumption.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key)),
    );

    // final sortedYearlyConsumption = Map.fromEntries(
    //   yearlyConsumption.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key)),
    // );

    return {
      'totalVolume': totalVolume,
      'totalExpenditure': totalExpenditure,
      'monthlyConsumption': sortedMonthlyConsumption,
      // 'yearlyConsumption': sortedYearlyConsumption,
    };
  }

  Future<Map<String, double>> _getPrediction(Map<DateTime, Map<String, dynamic>> monthlyConsumption) async {
    print('monthlyConsumption: $monthlyConsumption');

    List<double> volumeInput = [];
    List<double> expenditureInput = [];

    for (var value in monthlyConsumption.values) {
      volumeInput.add(value['volume']?.toDouble() ?? 0.0);
      expenditureInput.add(value['expenditure']?.toDouble() ?? 0.0);
    }

    // Volume
    print('-----Volume-----');
    print('inputData.length: ${volumeInput.length}');
    print('inputData: $volumeInput');
    print('inputData.last: ${volumeInput.sublist(volumeInput.length - 3)}');

    // Expenditure
    print('-----Expenditure-----');
    print('inputData.length: ${expenditureInput.length}');
    print('inputData: $expenditureInput');
    print('inputData.last: ${expenditureInput.sublist(expenditureInput.length - 5)}');

    double predictedVolume;
    double predictedExpenditure;

    if (volumeInput.isNotEmpty && expenditureInput.isNotEmpty) {
    final response = await http.post(
      Uri.parse('https://api-ml-heroku-eaeb01fffd52.herokuapp.com/predict'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'volume_input': volumeInput.sublist(volumeInput.length - 3),
        'price_input': expenditureInput.sublist(expenditureInput.length - 5),
      }),
    );

    if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Response Data: $responseData');

        // Extracting the first element from the list
        predictedVolume = (responseData['volume_prediction'][0] as List).first.toDouble();
        predictedExpenditure = (responseData['price_prediction'][0] as List).first.toDouble();
      } else {
        predictedVolume = 0.0;
        predictedExpenditure = 0.0;
        print('Failed to load prediction: ${response.statusCode}');
      }
    } else {
      predictedVolume = 0.0; // Not enough data for prediction, use average value or default
      predictedExpenditure = 0.0; // Not enough data for prediction, use average value or default
    }

    return {
      'predictedVolume': predictedVolume,
      'predictedExpenditure': predictedExpenditure,
    };
  }

  String _getFormattedDateRange() {
    DateTime currentMonth = DateTime.now();
    if (widget.range == 'month') {
      DateTime startOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
      return DateFormat('MMMM yyyy').format(startOfMonth);
    // } else if (widget.range == 'year') {
    //   DateTime startOfYear = DateTime(widget.startDate.year + 1, 1, 1);
    //   return DateFormat('yyyy').format(startOfYear);
    } else {
      return '';
    }
  }

  String _getPredictionTitle() {
    if (widget.range == 'month') {
      return 'Predicted Next Month';
    } else if (widget.range == 'year') {
      return 'Predicted Next Year';
    } else {
      return 'Predictions';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Predictive Analytics',
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
            // final totalExpenditure = data['totalExpenditure'] as double;
            final monthlyConsumption = data['monthlyConsumption'] as Map<DateTime, Map<String, dynamic>>;
            // final yearlyConsumption = data['yearlyConsumption'] as Map<DateTime, Map<String, dynamic>>;

            // int averageVolume = (widget.range == 'month'
            //     ? (totalVolume / monthlyConsumption.length).round()
            //     : (totalVolume / yearlyConsumption.length).round());
            // double averageExpenditure = widget.range == 'month'
            //     ? totalExpenditure / monthlyConsumption.length
            //     : totalExpenditure / yearlyConsumption.length;

            return FutureBuilder<Map<String, double>>(
              future: _getPrediction(monthlyConsumption),
              builder: (context, predictionSnapshot) {
                if (predictionSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (predictionSnapshot.hasError) {
                  return Center(child: Text('Error: ${predictionSnapshot.error}'));
                } else {
                  final predictionData = predictionSnapshot.data!;
                  final predictedVolume = predictionData['predictedVolume']?.round() ?? 0;
                  final predictedExpenditure = predictionData['predictedExpenditure'] ?? 0.0;

                  print('totalVolume: $totalVolume');

                  // User Segmentation and Insights
                  // String userSegment = totalVolume > (widget.range == 'month' ? 28800*6 : 350400) ? 'High Consumer' : 'Moderate Consumer';
                  // String userRecommendation = userSegment == 'High Consumer'
                  //     ? 'Consider reducing your coffee intake for better health.'
                  //     : 'Your coffee consumption is within a moderate range.';

                  List<_ChartData> chartData = [];
                  DateTime currentMonth = DateTime.now();
                  if (widget.range == 'month') {
                    for (var entry in monthlyConsumption.entries) {
                      chartData.add(_ChartData(
                        DateFormat('MMM yy').format(entry.key),
                        entry.value['volume'] ?? 0,
                        entry.value['expenditure'] ?? 0.0,
                      ));
                    }
                    // Add prediction data for the next month
                    DateTime nextMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
                    chartData.add(_ChartData(
                      DateFormat('MMM yy').format(nextMonth),
                      predictedVolume,
                      predictedExpenditure,
                      isPrediction: true,
                    ));
                  // } else if (widget.range == 'year') {
                  //   for (var entry in yearlyConsumption.entries) {
                  //     chartData.add(_ChartData(
                  //       DateFormat('yyyy').format(entry.key),
                  //       entry.value['volume'] ?? 0,
                  //       entry.value['expenditure'] ?? 0.0,
                  //     ));
                  //   }
                  //   // Add prediction data for the next year
                  //   DateTime nextYear = DateTime(widget.startDate.year + 2, 1);
                  //   chartData.add(_ChartData(
                  //     DateFormat('yyyy').format(nextYear),
                  //     predictedVolume,
                  //     predictedExpenditure,
                  //     isPrediction: true,
                  //   ));
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DropdownButton<String>(
                              value: _selectedMetric,
                              icon: const Icon(Icons.expand_more),
                              borderRadius: BorderRadius.circular(10),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedMetric = newValue!;
                                });
                              },
                              items: <String>['Volume', 'Expenditure'].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        _buildChart(chartData),
                        const SizedBox(height: 20),
                        _buildPrediction(predictedVolume, predictedExpenditure),
                        // const SizedBox(height: 20),
                        // _buildUserInsights(userSegment, userRecommendation),
                        const SizedBox(height: 20),
                        _buildNotes(),
                      ],
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildChart(List<_ChartData> chartData) {
    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: const CategoryAxis(),
        primaryYAxis: const NumericAxis(minimum: 0),
        tooltipBehavior: _tooltipBehavior,
        legend: const Legend(isVisible: true, toggleSeriesVisibility: false),
        series: <CartesianSeries>[
          // All data for line between last month and predicted month
          LineSeries<_ChartData, String>(
            dataSource: chartData,
            animationDuration: 650,
            xValueMapper: (_ChartData data, _) => data.date,
            yValueMapper: (_ChartData data, _) => _selectedMetric == 'Volume' ? data.volume : data.expenditure,
            name: 'Prediction',
            color: Colors.red,
            dashArray: const <double>[5, 5],
            width: 2.5,
            markerSettings: const MarkerSettings(isVisible: true, height: 8, width: 8, color: Colors.red, borderColor: Colors.red),
            enableTooltip: false,
          ),
          // Data from original
          LineSeries<_ChartData, String>(
            dataSource: chartData.where((data) => !data.isPrediction).toList(),
            animationDuration: 650,
            xValueMapper: (_ChartData data, _) => data.date,
            yValueMapper: (_ChartData data, _) => _selectedMetric == 'Volume' ? data.volume : data.expenditure,
            name: _selectedMetric,
            color: _selectedMetric == 'Volume' ? Colors.blue : Colors.lightGreen,
            width: 3.5,
            markerSettings: const MarkerSettings(isVisible: true, shape: DataMarkerType.circle),
            enableTooltip: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPrediction(int predictedVolume, double predictedExpenditure) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getPredictionTitle(),
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        _buildInsightTile('Consumption', '$predictedVolume mL'),
        _buildInsightTile('Expenditure', '${predictedExpenditure.toStringAsFixed(2)} GBP'),
      ],
    );
  }

  // Future Development
  // Widget _buildUserInsights(String segment, String recommendation) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'User Insights',
  //         style: GoogleFonts.montserrat(
  //           fontSize: 16,
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //       const SizedBox(height: 10),
  //       _buildInsightTile('Segment', segment),
  //       const SizedBox(height: 5),
  //       Text(
  //         recommendation,
  //         style: GoogleFonts.montserrat(fontSize: 15),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'This forecast is generated using your historical data. Please note that predictions may not be entirely precise. This information is intended to offer general insights.',
          style: GoogleFonts.montserrat(fontSize: 15),
        ),
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
  _ChartData(this.date, this.volume, this.expenditure, {this.isPrediction = false});

  final String date;
  final int volume;
  final double expenditure;
  final bool isPrediction;
}
