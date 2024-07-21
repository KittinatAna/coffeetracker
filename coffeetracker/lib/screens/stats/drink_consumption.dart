import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:coffeetracker/services/firestore_service.dart';

class DrinksConsumptionPage extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String range;

  DrinksConsumptionPage({required this.startDate, required this.endDate, required this.range});

  final FirestoreService _firestoreService = FirestoreService();

  Future<Map<String, dynamic>> _fetchConsumptionData() async {
    List<Map<String, dynamic>> records = await _firestoreService.fetchData('coffeerecords');
    int totalDrinks = 0;
    Map<String, int> coffeeChoices = {
      'Purchased Coffee': 0,
      'Homemade Coffee': 0,
      'Vending Machine': 0,
    };

    Map<String, Map<String, int>> coffeeTypes = {
      'Purchased Coffee': {},
      'Homemade Coffee': {},
      'Vending Machine': {},
    };

    for (var record in records) {
      DateTime recordDate = DateTime.parse(record['date']);
      if (recordDate.isAfter(startDate) && recordDate.isBefore(endDate)) {
        totalDrinks++;
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

        String coffeeType = record['coffee_type_desc'];
        coffeeChoices[coffeeChoice] = (coffeeChoices[coffeeChoice] ?? 0) + 1;
        coffeeTypes[coffeeChoice]?[coffeeType] = (coffeeTypes[coffeeChoice]?[coffeeType] ?? 0) + 1;
      }
    }

    return {
      'totalDrinks': totalDrinks,
      'coffeeChoices': coffeeChoices,
      'coffeeTypes': coffeeTypes,
    };
  }

  String _getFormattedDateRange() {
    if (range == 'day') {
      DateTime startofDate = DateTime(startDate.year, startDate.month, startDate.day + 1);
      return DateFormat('d MMMM yyyy').format(startofDate);
    } else if (range == 'week') {
      DateTime startOfWeek = startDate.subtract(Duration(days: startDate.weekday - 8));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      return '${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}';
    } else if (range == 'month') {
      DateTime startOfMonth = DateTime(startDate.year, startDate.month + 2, 0);
      return DateFormat('MMMM yyyy').format(startOfMonth);
    } else if (range == 'year') {
      DateTime startOfYear = DateTime(startDate.year + 2, 1, 0);
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
          'Drinks Consumption',
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
            final totalDrinks = data['totalDrinks'] as int;
            final coffeeChoices = data['coffeeChoices'] as Map<String, int>;
            final coffeeTypes = data['coffeeTypes'] as Map<String, Map<String, int>>;

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
                      title:
                        Text(
                          'Total Consumption',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      trailing: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$totalDrinks',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: '\t\tdrinks',
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
                  _buildPieChart(coffeeChoices, totalDrinks),
                  const SizedBox(height: 20),
                  _buildCoffeeChoiceList(coffeeChoices, coffeeTypes),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> coffeeChoices, int totalDrinks) {
    List<PieChartSectionData> sections;
    if (totalDrinks == 0) {
      sections = [
        PieChartSectionData(
          color: Colors.grey[400],
          value: 100,
          showTitle: false,
          radius: 45,
        ),
      ];
    } else {
      sections = coffeeChoices.entries.map((entry) {
        final value = (entry.value / totalDrinks) * 100;
        final color = entry.key == 'Purchased Coffee'
            ? const Color.fromARGB(255, 255, 155, 119)
            : entry.key == 'Homemade Coffee'
                ? const Color.fromARGB(255, 159, 222, 108)
                : const Color.fromARGB(255, 118, 215, 239);
        return PieChartSectionData(
          color: color,
          value: value,
          showTitle: false,
          radius: 45,
        );
      }).toList();
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            swapAnimationDuration: const Duration(milliseconds: 750),
            PieChartData(
              sections: sections,
              centerSpaceRadius: 50,
              borderData: FlBorderData(show: false),
              sectionsSpace: 4,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: coffeeChoices.entries.map((entry) {
                final color = entry.key == 'Purchased Coffee'
                    ? const Color.fromARGB(255, 255, 155, 119)
                    : entry.key == 'Homemade Coffee'
                        ? const Color.fromARGB(255, 159, 222, 108)
                        : const Color.fromARGB(255, 118, 215, 239);
                final percentage = totalDrinks == 0 ? 0.0 : (entry.value / totalDrinks) * 100;
                return Row(
                  children: [
                    Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '\t${percentage.toStringAsFixed(2)}% ',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: '\t${entry.key}',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildCoffeeChoiceList(Map<String, int> coffeeChoices, Map<String, Map<String, int>> coffeeTypes) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: coffeeChoices.keys.map((choice) {
          final color = choice == 'Purchased Coffee'
              ? const Color.fromARGB(255, 255, 155, 119)
              : choice == 'Homemade Coffee'
                  ? const Color.fromARGB(255, 159, 222, 108)
                  : const Color.fromARGB(255, 118, 215, 239);
          // Sort coffeeTypes by number of drinks.
          List<MapEntry<String, int>> sortedEntries = coffeeTypes[choice]!.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    choice,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${coffeeChoices[choice]}',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '\t\tdrinks',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.fromLTRB(20,0,0,0),
                child: Divider(height: 10, thickness: 1,),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(20,0,0,0),
                child: Column(
                  children: sortedEntries
                  .map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          Text(
                            '${entry.value} \tdrinks',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList()
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        }).toList(),
      ),
    );
  }
}
