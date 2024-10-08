import 'dart:io';
import 'package:coffeetracker/screens/stats/visited_shop.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:coffeetracker/screens/home.dart';
import 'package:coffeetracker/screens/calendar.dart';
import 'package:coffeetracker/services/firestore_service.dart';
import 'package:coffeetracker/screens/stats/drink_consumption.dart';
import 'package:coffeetracker/screens/stats/volume_consumption.dart';
import 'package:coffeetracker/screens/stats/expenditure.dart';
import 'package:coffeetracker/screens/stats/type_ranking.dart';
import 'package:coffeetracker/screens/stats/shop_ranking.dart';
import 'package:coffeetracker/screens/stats/daily_insight.dart';
import 'package:coffeetracker/screens/stats/weekly_insight.dart';
import 'package:coffeetracker/screens/stats/monthly_insight.dart';
import 'package:coffeetracker/screens/stats/yearly_insight.dart';
import 'package:coffeetracker/screens/stats/charts.dart';
import 'package:coffeetracker/screens/stats/statistic_captrue.dart';
import 'package:coffeetracker/screens/setting.dart';

class StatisticPage extends StatefulWidget {
  @override
  _StatisticPageState createState() => _StatisticPageState();
}

class NoTransitionPageRoute<T> extends MaterialPageRoute<T> {
  NoTransitionPageRoute({required WidgetBuilder builder}) : super(builder: builder);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

class _StatisticPageState extends State<StatisticPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _currentDate = DateTime.now();
  final FirestoreService _firestoreService = FirestoreService();
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getFormattedDateRange(String range) {
    switch (range) {
      case 'day':
        return DateFormat('d MMMM yyyy').format(_currentDate);
      case 'week':
        DateTime startOfWeek = _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
        DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}';
      case 'month':
        return DateFormat('MMMM yyyy').format(_currentDate);
      case 'year':
        return DateFormat('yyyy').format(_currentDate);
      default:
        return '';
    }
  }

  Future<Map<String, dynamic>> _fetchStatisticsSummary(String range) async {
    List<Map<String, dynamic>> records = await _firestoreService.fetchData('coffeerecords');
    DateTime startDate;
    DateTime endDate;

    switch (range) {
      case 'day':
        startDate = DateTime(_currentDate.year, _currentDate.month, _currentDate.day - 1);
        endDate = startDate.add(const Duration(days: 2));
        break;
      case 'week':
        startDate = _currentDate.subtract(Duration(days: _currentDate.weekday));
        endDate = startDate.add(const Duration(days: 8));
        break;
      case 'month':
        startDate = DateTime(_currentDate.year, _currentDate.month, 0);
        endDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
        break;
      case 'year':
        startDate = DateTime(_currentDate.year, 1, 0);
        endDate = DateTime(_currentDate.year + 1, 1, 1);
        break;
      default:
        throw ArgumentError('Invalid range');
    }

    int totalDrinks = 0;
    int totalVolume = 0;
    double totalExpenditure = 0.0;

    for (var record in records) {
      DateTime recordDate = DateTime.parse(record['date']);
      if (recordDate.isAfter(startDate) && recordDate.isBefore(endDate)) {
        totalDrinks++;
        totalVolume += (record['volume'] as int);
        totalExpenditure += record['price'] ?? 0.0;
      }
    }

    return {
      'totalDrinks': totalDrinks,
      'totalVolume': totalVolume,
      'totalExpenditure': totalExpenditure,
    };
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchTopCoffeeData(String range) async {
    List<Map<String, dynamic>> records = await _firestoreService.fetchData('coffeerecords');
    DateTime startDate;
    DateTime endDate;

    switch (range) {
      case 'day':
        startDate = DateTime(_currentDate.year, _currentDate.month, _currentDate.day - 1);
        endDate = startDate.add(const Duration(days: 2));
        break;
      case 'week':
        startDate = _currentDate.subtract(Duration(days: _currentDate.weekday));
        endDate = startDate.add(const Duration(days: 8));
        break;
      case 'month':
        startDate = DateTime(_currentDate.year, _currentDate.month, 0);
        endDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
        break;
      case 'year':
        startDate = DateTime(_currentDate.year, 1, 0);
        endDate = DateTime(_currentDate.year + 1, 1, 1);
        break;
      default:
        throw ArgumentError('Invalid range');
    }

    Map<String, int> coffeeTypeVolumes = {};
    Map<String, int> coffeeShopVolumes = {};

    for (var record in records) {
      DateTime recordDate = DateTime.parse(record['date']);
      if (recordDate.isAfter(startDate) && recordDate.isBefore(endDate)) {
        String coffeeType = record['coffee_type_desc'];
        String coffeeShop = record['coffee_shop'];
        int volume = record['volume'] ?? 0;

        if (coffeeType.isNotEmpty) {
          coffeeTypeVolumes[coffeeType] = (coffeeTypeVolumes[coffeeType] ?? 0) + volume;
        }

        if (coffeeShop.isNotEmpty) {
          coffeeShopVolumes[coffeeShop] = (coffeeShopVolumes[coffeeShop] ?? 0) + volume;
        }
      }
    }

    List<Map<String, dynamic>> topCoffeeTypes = coffeeTypeVolumes.entries
        .map((entry) => {'name': entry.key, 'volume': entry.value})
        .toList();

    topCoffeeTypes.sort((a, b) {
      int volumeCompare = b['volume'].compareTo(a['volume']);
      if (volumeCompare != 0) return volumeCompare;
      return a['name'].compareTo(b['name']);
    });

    List<Map<String, dynamic>> topCoffeeShops = coffeeShopVolumes.entries
        .map((entry) => {'name': entry.key, 'volume': entry.value})
        .toList();

    topCoffeeShops.sort((a, b) {
      int volumeCompare = b['volume'].compareTo(a['volume']);
      if (volumeCompare != 0) return volumeCompare;
      return a['name'].compareTo(b['name']);
    });

    return {
      'coffeeTypes': topCoffeeTypes.take(3).toList(),
      'coffeeShops': topCoffeeShops.take(3).toList(),
    };
  }

  Future<Map<String, dynamic>> _fetchBarChartData(String range) async {
    List<Map<String, dynamic>> records = await _firestoreService.fetchData('coffeerecords');
    DateTime startDate;
    DateTime endDate;

    Map<int, double> volumePerPeriod = {};
    Map<int, double> expenditurePerPeriod = {};
    List<Map<String, dynamic>> detailedData = [];
    double barWidth;
    double totalVolume = 0.0;
    double totalExpenditure = 0.0;

    switch (range) {
      case 'day':
        startDate = DateTime(_currentDate.year, _currentDate.month, _currentDate.day - 1);
        endDate = startDate.add(const Duration(days: 2));
        volumePerPeriod[0] = 0;
        expenditurePerPeriod[0] = 0;
        barWidth = 15.0;
        break;
      case 'week':
        startDate = _currentDate.subtract(Duration(days: _currentDate.weekday));
        endDate = startDate.add(const Duration(days: 8));
        for (int i = 0; i < 7; i++) {
          volumePerPeriod[i] = 0;
          expenditurePerPeriod[i] = 0;
        }
        barWidth = 15.0;
        break;
      case 'month':
        startDate = DateTime(_currentDate.year, _currentDate.month, 0);
        endDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
        int daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 1).subtract(const Duration(days: 1)).day;
        for (int i = 0; i < daysInMonth; i++) {
          volumePerPeriod[i] = 0;
          expenditurePerPeriod[i] = 0;
        }
        barWidth = 7.0;
        break;
      case 'year':
        startDate = DateTime(_currentDate.year, 1, 0);
        endDate = DateTime(_currentDate.year + 1, 1, 1);
        for (int i = 0; i < 12; i++) {
          volumePerPeriod[i] = 0;
          expenditurePerPeriod[i] = 0;
        }
        barWidth = 10.0;
        break;
      default:
        throw ArgumentError('Invalid range');
    }

    for (var record in records) {
      DateTime recordDate = DateTime.parse(record['date']);
      if (recordDate.isAfter(startDate) && recordDate.isBefore(endDate)) {
        int volume = record['volume'] as int;
        double price = record['price'] ?? 0.0;
        totalVolume += volume;
        totalExpenditure += price;

        String coffeeChoice = record['is_purchased'] == true
            ? 'Purchased Coffee'
            : record['is_homemade'] == true
                ? 'Homemade Coffee'
                : 'Coffee Vending Machine';

        String coffeeShop = record['is_purchased'] == true
            ? record['coffee_shop']
            : record['is_homemade'] == true
                ? record['coffee_shop']
                : record['brand'];

        detailedData.add({
          'date': recordDate,
          'coffeeType': record['coffee_type_desc'],
          'coffeeShop': coffeeShop,
          'coffeeChoice': coffeeChoice,
          'volume': volume,
          'expenditure': price,
        });

        if (range == 'day') {
          volumePerPeriod[0] = (volumePerPeriod[0] ?? 0) + volume;
          expenditurePerPeriod[0] = (expenditurePerPeriod[0] ?? 0) + price;
        } else if (range == 'week') {
          int dayOfWeek = recordDate.weekday - 1;
          volumePerPeriod[dayOfWeek] = (volumePerPeriod[dayOfWeek] ?? 0) + volume;
          expenditurePerPeriod[dayOfWeek] = (expenditurePerPeriod[dayOfWeek] ?? 0) + price;
        } else if (range == 'month') {
          int dayOfMonth = recordDate.day - 1;
          volumePerPeriod[dayOfMonth] = (volumePerPeriod[dayOfMonth] ?? 0) + volume;
          expenditurePerPeriod[dayOfMonth] = (expenditurePerPeriod[dayOfMonth] ?? 0) + price;
        } else if (range == 'year') {
          int month = recordDate.month - 1;
          volumePerPeriod[month] = (volumePerPeriod[month] ?? 0) + volume;
          expenditurePerPeriod[month] = (expenditurePerPeriod[month] ?? 0) + price;
        }
      }
    }

    double averageVolume = totalVolume / volumePerPeriod.length;
    double averageExpenditure = totalExpenditure / volumePerPeriod.length;

    List<BarChartGroupData> barGroups = volumePerPeriod.entries
        .map((entry) => BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: Colors.blue,
                  width: barWidth,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            ))
        .toList();

    return {
      'barGroups': barGroups,
      'averageVolume': averageVolume,
      'averageExpenditure': averageExpenditure,
      'volumePerPeriod': volumePerPeriod,
      'expenditurePerPeriod': expenditurePerPeriod,
      'detailedData': detailedData,
    };
  }

  void _selectDate(BuildContext context, String range) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && range == 'week') {
      picked = picked.subtract(Duration(days: picked.weekday - 1));
    } else if (picked != null && range == 'year') {
      picked = DateTime(picked.year);
    }

    if (picked != null && picked != _currentDate) {
      setState(() {
        _currentDate = picked!;
      });
    }
  }

  DateTimeRange _DateRangeForNavigate(String range) {
    DateTime startDate;
    DateTime endDate;

    switch (range) {
      case 'day':
        startDate = DateTime(_currentDate.year, _currentDate.month, _currentDate.day - 1);
        endDate = startDate.add(const Duration(days: 2));
        break;
      case 'week':
        startDate = _currentDate.subtract(Duration(days: _currentDate.weekday));
        endDate = startDate.add(const Duration(days: 8));
        break;
      case 'month':
        startDate = DateTime(_currentDate.year, _currentDate.month, 0);
        endDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
        break;
      case 'year':
        startDate = DateTime(_currentDate.year, 1, 0);
        endDate = DateTime(_currentDate.year + 1, 1, 1);
        break;
      default:
        throw ArgumentError('Invalid range');
    }

    return DateTimeRange(start: startDate, end: endDate);
  }

  void _navigateToPage(String range, Widget page) {
    _DateRangeForNavigate(range);

    Navigator.push(
      context,
      NoTransitionPageRoute(
        builder: (context) => page,
      ),
    );
  }

  String _getCurrentRange() {
    switch (_tabController.index) {
      case 0:
        return 'day';
      case 1:
        return 'week';
      case 2:
        return 'month';
      case 3:
        return 'year';
      default:
        return 'day';
    }
  }

  void _navigateToCapturePage(String action) {
    DateTimeRange dateRange = _DateRangeForNavigate(_getCurrentRange());
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatisticCapturePage(
          startDate: dateRange.start,
          endDate: dateRange.end,
          range: _getCurrentRange(),
          content: _buildStatisticsContent(_getCurrentRange()),
          screenshotController: screenshotController,
        ),
      ),
    );
  }

  Widget _buildStatisticsContent(String range) {
    return Column(
      children: [
        _buildStatisticsSummary(range),
        if (range != 'day') _buildCharts(range),
      ],
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_library_rounded, size: 30, color: Colors.black54),
                        onPressed: () {
                          _navigateToCapturePage(_getCurrentRange());
                        },
                      ),
                      Text(
                        'Export Image',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.drive_file_move_outline, size: 30, color: Colors.black54),
                        onPressed: () {
                          _shareCsvFile(_getCurrentRange());
                        },
                      ),
                      Text(
                        'Export Data',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateCsvFile(String range, Map<String, dynamic> summaryData, Map<String, dynamic> barchartData) async {
    DateTimeRange dateRange = _DateRangeForNavigate(range);
    DateTime startDate = dateRange.start;

    String getFormattedDateRange() {
      switch (range) {
        case 'day':
          return DateFormat('d MMMM yyyy').format(startDate.add(const Duration(days: 1)));
        case 'week':
          DateTime startOfWeek = startDate.subtract(Duration(days: startDate.weekday - 8));
          DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
          return '${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}';
        case 'month':
          return DateFormat('MMMM yyyy').format(startDate.add(const Duration(days: 1)));
        case 'year':
          return DateFormat('yyyy').format(startDate.add(const Duration(days: 1)));
        default:
          return '';
      }
    }

    List<List<dynamic>> rows = [
      ["Date: ${getFormattedDateRange()}"],
      [],
      ["Statistic", "Value"],
      ["Total Drinks Consumed", summaryData['totalDrinks'], "drinks"],
      ["Total Volume Consumed (mL)", summaryData['totalVolume'], "mL"],
      ["Total Expenditure", summaryData['totalExpenditure'], "GBP"],
      []
    ];

    List<Map<String, dynamic>> detailedData = barchartData['detailedData'] as List<Map<String, dynamic>>;

    if (detailedData.isNotEmpty) {
      List<List<dynamic>> detailedRows = [
        ["Date", "Coffee Type", "Coffee Shop", "Coffee Choice", "Volume (mL)", "Expenditure (GBP)"]
      ];

      detailedData.sort((a, b) => a['date'].compareTo(b['date'])); // Sort by date

      for (var data in detailedData) {
        detailedRows.add([
          DateFormat('yyyy-MM-dd').format(data['date']),
          data['coffeeType'],
          data['coffeeShop'],
          data['coffeeChoice'],
          data['volume'],
          data['expenditure']
        ]);
      }

      rows.addAll(detailedRows);
    }

    List<BarChartGroupData> barGroups = barchartData['barGroups'] as List<BarChartGroupData>;
    Map<int, double> expenditurePerPeriod = barchartData['expenditurePerPeriod'] as Map<int, double>;

    if (range == 'week' || range == 'month' || range == 'year') {
      List<List<dynamic>> rowsAdd = [
        [],
        ["Date", "Volume (mL)", "Expenditure (GPB)"]
      ];

      for (var barGroup in barGroups) {
        int x = barGroup.x;
        double volume = barGroup.barRods.first.toY;
        double expenditure = expenditurePerPeriod[x] ?? 0.0;

        String formattedDate;
        if (range == 'week') {
          formattedDate = DateFormat('yyyy-MM-dd').format(startDate.add(Duration(days: x + 1)));
        } else if (range == 'month') {
          formattedDate = DateFormat('yyyy-MM-dd').format(startDate.add(Duration(days: x + 1)));
        } else {
          formattedDate = DateFormat('yyyy-MM-dd').format(DateTime(startDate.year + 1, x + 1));
        }

        rowsAdd.add([formattedDate, volume, expenditure]);
      }

      rows.addAll(rowsAdd);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/statistics_$range.csv";
    final File file = File(path);

    await file.writeAsString(csvData);
  }

  void _shareCsvFile(String range) async {
    Navigator.pop(context); // Close the bottom sheet

    final summaryData = await _fetchStatisticsSummary(range);
    final barchartData = await _fetchBarChartData(range);
    await _generateCsvFile(range, summaryData, barchartData);

    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/statistics_$range.csv";
    final XFile file = XFile(path);

    await Share.shareXFiles(
      [file],
      text: 'Here are my coffee statistics summary in $range',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Statistics',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: _showShareOptions,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            height: 35,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Colors.white,
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black54,
              labelStyle: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              tabs: const [
                Tab(text: 'D'),
                Tab(text: 'W'),
                Tab(text: 'M'),
                Tab(text: 'Y'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyStatistics(),
          _buildWeeklyStatistics(),
          _buildMonthlyStatistics(),
          _buildYearlyStatistics(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
        currentIndex: 2,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (int index) {
          setState(() {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                NoTransitionPageRoute(builder: (context) => const Home()),
              );
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                NoTransitionPageRoute(builder: (context) => CalendarPage()),
              );
            } else if (index == 3) {
              Navigator.pushReplacement(
                context,
                NoTransitionPageRoute(builder: (context) => SettingsPage()),
              );
            }
          });
        },
      ),
    );
  }

  Widget _buildDailyStatistics() {
    return _buildStatisticsPage('day', _getFormattedDateRange('day'), _buildDailyInsight);
  }

  Widget _buildWeeklyStatistics() {
    return _buildStatisticsPage('week', _getFormattedDateRange('week'), _buildWeeklyInsight);
  }

  Widget _buildMonthlyStatistics() {
    return _buildStatisticsPage('month', _getFormattedDateRange('month'), _buildMonthlyInsight);
  }

  Widget _buildYearlyStatistics() {
    return _buildStatisticsPage('year', _getFormattedDateRange('year'), _buildYearlyInsight);
  }

  Widget _buildStatisticsPage(String range, String dateRange, Widget Function(String) buildInsight) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 35,
              child: OutlinedButton(
                onPressed: () => _selectDate(context, range),
                style: ButtonStyle(
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0))),
                ),
                child: Text(
                  dateRange,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildStatisticsSummary(range),
            if (range != 'day') _buildCharts(range),
            _buildRanking(range),
            const SizedBox(height: 10),
            buildInsight(range),
            _buildVisitShop(range),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSummary(String range) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchStatisticsSummary(range),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final data = snapshot.data!;
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => _navigateToPage(range, DrinksConsumptionPage(startDate: _DateRangeForNavigate(range).start, endDate: _DateRangeForNavigate(range).end, range: range)),
                    child: _buildStatisticsTile(
                      'Total Drinks \nConsumed',
                      data['totalDrinks'].toString(),
                      const Icon(Icons.coffee, size: 25, color: Colors.grey),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToPage(range, VolumeConsumptionPage(startDate: _DateRangeForNavigate(range).start, endDate: _DateRangeForNavigate(range).end, range: range)),
                    child: _buildStatisticsTile(
                      'Total Volume \nConsumed (mL)',
                      data['totalVolume'].toString(),
                      const Icon(Icons.local_drink, size: 25, color: Colors.grey),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToPage(range, ExpenditurePage(startDate: _DateRangeForNavigate(range).start, endDate: _DateRangeForNavigate(range).end, range: range)),
                    child: _buildStatisticsTile(
                      'Total \nExpenditure',
                      '£ ${data['totalExpenditure'].toStringAsFixed(2)}',
                      Image.asset('assets/money_grey.png', width: 25, height: 25),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Click on the text to see more details',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.black26,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatisticsTile(String title, String value, Widget icon) {
    return Column(
      children: [
        const SizedBox(height: 10),
        icon,
        const SizedBox(height: 15),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildRanking(String range) {
    var isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: fetchTopCoffeeData(range),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final data = snapshot.data ?? {};
          final coffeeTypes = data['coffeeTypes'] ?? [];
          final coffeeShops = data['coffeeShops'] ?? [];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    'Ranking',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _navigateToPage(range, TypeRankingPage(startDate: _DateRangeForNavigate(range).start, endDate: _DateRangeForNavigate(range).end, range: range)),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Coffee Type',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ...List.generate(3, (index) {
                                  final coffeeType = index < coffeeTypes.length ? coffeeTypes[index]['name'] : 'None';
                                  return SizedBox(
                                    height: 40,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: index == 0
                                            ? const Color.fromARGB(255, 255, 215, 0)
                                            : index == 1
                                                ? const Color.fromARGB(255, 192, 192, 192)
                                                : const Color.fromARGB(255, 205, 127, 50),
                                        radius: 13,
                                        child: Text(
                                          (index + 1).toString(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        isLandscape || coffeeType.length <= 20 ? coffeeType : '${coffeeType.substring(0, 20)}...',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        Center(child: Text('Volume (mL)', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.normal))),
                        const SizedBox(height: 10),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _navigateToPage(range, ShopRankingPage(startDate: _DateRangeForNavigate(range).start, endDate: _DateRangeForNavigate(range).end, range: range)),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Coffee Shops',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ...List.generate(3, (index) {
                                  final coffeeShop = index < coffeeShops.length ? coffeeShops[index]['name'] : 'None';
                                  return SizedBox(
                                    height: 40,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: index == 0
                                            ? const Color.fromARGB(255, 255, 215, 0)
                                            : index == 1
                                                ? const Color.fromARGB(255, 192, 192, 192)
                                                : const Color.fromARGB(255, 205, 127, 50),
                                        radius: 13,
                                        child: Text(
                                          (index + 1).toString(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        isLandscape || coffeeShop.length <= 15 ? coffeeShop : '${coffeeShop.substring(0, 15)}...',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        Center(child: Text('Volume (mL)', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.normal))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildCharts(String range) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchBarChartData(range),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final data = snapshot.data!;
          final barGroups = data['barGroups'] as List<BarChartGroupData>;
          final averageVolume = data['averageVolume'] as double;
          final averageExpenditure = data['averageExpenditure'] as double;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    'Charts',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () => _navigateToPage(range, Charts(startDate: _DateRangeForNavigate(range).start, endDate: _DateRangeForNavigate(range).end, range: range)),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                            child: Text(
                              range == 'week'
                                  ? 'Daily Consumption'
                                  : range == 'month'
                                      ? 'Daily Consumption'
                                      : 'Monthly Consumption',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Average Volume',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    Text(
                                      '${averageVolume.toStringAsFixed(1)} mL',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Average Expenditure',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    Text(
                                      '£ ${averageExpenditure.toStringAsFixed(2)}',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => _navigateToPage(range, Charts(startDate: _DateRangeForNavigate(range).start, endDate: _DateRangeForNavigate(range).end, range: range)),
                            child: SizedBox(
                              height: 150,
                              child: BarChart(
                                BarChartData(
                                  barGroups: barGroups,
                                  borderData: FlBorderData(show: false),
                                  gridData: const FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          if (range == 'week') {
                                            return Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][value.toInt()],
                                                style: GoogleFonts.montserrat(fontSize: 10));
                                          } else if (range == 'month') {
                                            return Text((value.toInt() + 1).toString(), style: GoogleFonts.montserrat(fontSize: 7.5));
                                          } else if (range == 'year') {
                                            return Text(DateFormat('MMM').format(DateTime(0, value.toInt() + 1)), style: GoogleFonts.montserrat(fontSize: 10));
                                          }
                                          return Text('', style: GoogleFonts.montserrat(fontSize: 10));
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Volume (mL)',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildDailyInsight(String range) {
    return _buildInsightCard('Daily Insight', Icons.moving_rounded, () => _navigateToPage(range, DailyInsight(startDate: _DateRangeForNavigate(range).start, endDate: _DateRangeForNavigate(range).end, range: range)));
  }

  Widget _buildWeeklyInsight(String range) {
    return _buildInsightCard('Weekly Insight', Icons.moving_rounded, () => _navigateToPage(range, WeeklyInsight(startDate: _DateRangeForNavigate(range).start, endDate: _DateRangeForNavigate(range).end, range: range)));
  }

  Widget _buildMonthlyInsight(String range) {
    return _buildInsightCard('Monthly Insight', Icons.moving_rounded, () => _navigateToPage(range, MonthlyInsight(startDate: _DateRangeForNavigate(range).start, endDate: _DateRangeForNavigate(range).end, range: range)));
  }

  Widget _buildYearlyInsight(String range) {
    return _buildInsightCard('Yearly Insight', Icons.moving_rounded, () => _navigateToPage(range, YearlyInsight(startDate: _DateRangeForNavigate(range).start, endDate: _DateRangeForNavigate(range).end, range: range)));
  }

  Widget _buildInsightCard(String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        color: Colors.white,
        child: ListTile(
          title: Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: Icon(icon, color: Colors.grey),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildVisitShop(String range) {
    return _buildVisitShopCard('Visited Shops', Icons.location_on, () => _navigateToPage(range, VisitedShopPage(startDate: _DateRangeForNavigate(range).start, endDate: _DateRangeForNavigate(range).end, range: range)));
  }

  Widget _buildVisitShopCard(String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        color: Colors.white,
        child: ListTile(
          title: Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: Icon(icon, color: Colors.grey),
          onTap: onTap,
        ),
      ),
    );
  }
}
