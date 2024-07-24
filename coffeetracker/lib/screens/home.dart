import 'package:coffeetracker/screens/setting.dart';
import 'package:coffeetracker/screens/stats/visited_shop.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:coffeetracker/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:coffeetracker/screens/addcoffee/choose_coffee.dart';
import 'package:coffeetracker/screens/editrecord/edit_purchased_coffee.dart';
import 'package:coffeetracker/screens/editrecord/edit_homemade_coffee.dart';
import 'package:coffeetracker/screens/editrecord/edit_coffee_vending_machine.dart';
import 'package:coffeetracker/screens/calendar.dart';
import 'package:coffeetracker/screens/stats/statistic.dart';
import 'package:coffeetracker/screens/stats/predictive_analytics.dart';
import 'package:coffeetracker/screens/stats/daily_insight.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class NoTransitionPageRoute<T> extends MaterialPageRoute<T> {
  NoTransitionPageRoute({required WidgetBuilder builder}) : super(builder: builder);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

class _HomeState extends State<Home> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic> userData = {};
  bool isEditing = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await _firestoreService.insertUserData();
    List<Map<String, dynamic>> record = await _firestoreService.fetchData('coffeerecords');
    
    // Filter records for today
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    List<Map<String, dynamic>> todayRecords = record.where((record) => record['date'] == today).toList();
    
    // Sort records by time
    todayRecords.sort((a, b) => a['time'].compareTo(b['time']));
    
    setState(() {
      if (todayRecords.isNotEmpty) {
        userData = {
          "coffeeIntake": todayRecords.fold(0, (sum, item) => sum + (item['volume'] as int)),
          "coffeeDrinks": todayRecords.length,
          "totalExpenditure": todayRecords.fold(0.0, (sum, item) => sum + (item['price']?.toDouble() as double)),
          "dailyPurchases": todayRecords,
        };
      } else {
        userData = {
          "coffeeIntake": 0,
          "coffeeDrinks": 0,
          "totalExpenditure": 0.0,
          "dailyPurchases": [],
        };
      }
      isLoading = false;
    });
  }

  void _toggleEditMode() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  void _deletePurchase(int index) async {
  try {
    await _firestoreService.deleteDataByField('coffeerecords', 'purchase_id', userData['dailyPurchases'][index]['purchase_id']);

    setState(() {
      userData['coffeeIntake'] -= userData['dailyPurchases'][index]['volume'];
      userData['coffeeDrinks'] -= 1;
      userData['totalExpenditure'] -= userData['dailyPurchases'][index]['price'].toDouble();
      userData['dailyPurchases'].removeAt(index);
      if (userData['dailyPurchases'].isEmpty) {
        userData = {
          "coffeeIntake": 0,
          "coffeeDrinks": 0,
          "totalExpenditure": 0.0,
          "dailyPurchases": [],
        };
      }
    });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error deleting record: $e',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  void _navigateToEditRecord(Map<String, dynamic> record) {

    if (record['is_purchased'] == true) {
      Navigator.push(
        context,
        NoTransitionPageRoute(
          builder: (context) => EditRecord_PurchaseCoffee(record: record),
        ),
      ).then((_) {
        _loadUserData();  // Refresh the data when returning to the home page
      });

    } else if (record['is_homemade'] == true) {
      Navigator.push(
        context,
        NoTransitionPageRoute(
          builder: (context) => EditRecord_HomemadeCoffee(record: record),
        ),
      ).then((_) {
        _loadUserData();  // Refresh the data when returning to the home page
      });
    } else if (record['is_vendingmachine'] == true) {
      Navigator.push(
        context,
        NoTransitionPageRoute(
          builder: (context) => EditRecord_CoffeeVendingMachine(record: record),
        ),
      ).then((_) {
        _loadUserData();  // Refresh the data when returning to the home page
      });
    }

  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 1));
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            'CoffeeTracker',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              edgeOffset: 6,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Text(
                        "Today's Coffees",
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        padding: const EdgeInsets.all(16.0),
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
                          children: <Widget>[
                            Text(
                              'Coffee Intake',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${userData['coffeeIntake']} mL / ${userData['coffeeDrinks']} drinks',
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Total Expenditure',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '£ ${userData['totalExpenditure'].toStringAsFixed(2)}',
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (userData['dailyPurchases'] != null && userData['dailyPurchases'].isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Daily Purchases",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _toggleEditMode,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    backgroundColor: Colors.grey[200],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                  ),
                                  child: Text(
                                    isEditing ? 'DONE' : 'EDIT',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.85,
                              padding: const EdgeInsets.all(8.0),
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
                              child: ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: userData['dailyPurchases'].length,
                                itemBuilder: (context, index) {
                                  final record = userData['dailyPurchases'][index];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    leading: isEditing ?
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                                            onPressed: () {
                                              _deletePurchase(index);
                                            },
                                          )
                                        : null,
                                    title: Text(
                                      record['coffee_type_desc'],
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${record['time']} / £ ${record['price'].toStringAsFixed(2)}',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${record['volume']} mL ',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(255, 110, 22, 240),
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right, color: Colors.grey),
                                      ],
                                    ),
                                    onTap: isEditing ? null : () {
                                      _navigateToEditRecord(record);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    _buildRecommended(),
                    const SizedBox(height: 80),
                  ],
                ),
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
        currentIndex: 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (int index) {
          setState(() {
            if (index == 1) {
              Navigator.pushReplacement(
                context,
                NoTransitionPageRoute(builder: (context) => CalendarPage()),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                NoTransitionPageRoute(builder: (context) => StatisticPage()),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              NoTransitionPageRoute(builder: (context) => const ChooseCoffee()
              ),
            ).then((_) {
              _loadUserData();  // Refresh the data when returning to the home page
            });
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0)),
          label: Text(
            'Add Coffee',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 110, 22, 240),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildRecommended() {
    DateTime currentDate = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    startDate = DateTime(currentDate.year, currentDate.month, currentDate.day - 1);
    endDate = startDate.add(const Duration(days: 2));
      return Column(
        children: [
          ListTile(
            title: Text(
              'Recommended',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            color: Colors.white,
            child: ListTile(
              title: Text(
                'Predictive Analytics',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(Icons.auto_graph_rounded, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  NoTransitionPageRoute(
                    builder: (context) => const PredictiveAnalytics(
                      range: 'month',
                    )
                  ),
                );
              },
            ),
          ),
          Card(
            color: Colors.white,
            child: ListTile(
              title: Text(
                'Daily Insight',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(Icons.moving_rounded, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  NoTransitionPageRoute(
                    builder: (context) => DailyInsight(
                      startDate: startDate,
                      endDate: endDate,
                      range: 'day',
                    )
                  ),
                );
              },
            ),
          ),
          Card(
            color: Colors.white,
            child: ListTile(
              title: Text(
                'Visited Shops',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(Icons.location_on, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  NoTransitionPageRoute(
                    builder: (context) => VisitedShopPage(
                      startDate: startDate,
                      endDate: endDate,
                      range: 'day')
                  ),
                );
              },
            ),
          ),
        ],
      );
  }
}
