import 'package:coffeetracker/screens/stats/statistic.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffeetracker/services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'home.dart';
import 'package:coffeetracker/screens/addcoffee/choose_coffee.dart';
import 'package:coffeetracker/screens/editrecord/edit_purchased_coffee.dart';
import 'package:coffeetracker/screens/editrecord/edit_homemade_coffee.dart';
import 'package:coffeetracker/screens/editrecord/edit_coffee_vending_machine.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class NoTransitionPageRoute<T> extends MaterialPageRoute<T> {
  NoTransitionPageRoute({required WidgetBuilder builder}) : super(builder: builder);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

class _CalendarPageState extends State<CalendarPage> {
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _allRecords = []; // All records loaded from Firestore
  bool isEditing = false;
  bool showAllRecords = true;
  bool selected = false;
  String _searchQuery = ""; // Search query

  bool _filterPurchased = true;
  bool _filterHomemade = true;
  bool _filterVendingMachine = true;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    String monthYear = DateFormat('yyyy-MM').format(_focusedDay);
    List<Map<String, dynamic>> records = await _firestoreService.fetchData('coffeerecords');

    setState(() {
      _allRecords = records.where((record) {
        String recordDate = record['date'];
        return recordDate.compareTo('$monthYear-01') >= 0 && recordDate.compareTo('$monthYear-31') <= 0;
      }).toList();
      _allRecords.sort((a, b) {
        int dateComparison = a['date'].compareTo(b['date']);
        if (dateComparison != 0) {
          return dateComparison;
        } else {
          return a['time'].compareTo(b['time']);
        }
      }); // Sort records by date and time
      _filterRecords();
    });
  }

  void _filterRecords() {
    setState(() {
      _records = _allRecords.where((record) {
        if (!_filterPurchased && record['is_purchased'] == true) return false;
        if (!_filterHomemade && record['is_homemade'] == true) return false;
        if (!_filterVendingMachine && record['is_vendingmachine'] == true) return false;

        if (_searchQuery.isEmpty) {
          return true;
        } else {
          return record['coffee_type_desc'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 (record['coffee_shop'] != null && record['coffee_shop'].toLowerCase().contains(_searchQuery.toLowerCase()));
        }
      }).toList();
    });
  }

  List<Map<String, dynamic>> get _selectedDayRecords {
    return _records
        .where((record) => record['date'] == DateFormat('yyyy-MM-dd').format(_selectedDay))
        .toList()
        ..sort((a, b) => a['time'].compareTo(b['time'])); // Sort records by time
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      if (_selectedDay == selectedDay && selected) {
        selected = false;
        _selectedDay = DateTime.now(); // Reset to current date
      } else {
        selected = true;
        _selectedDay = selectedDay;
      }
      _focusedDay = focusedDay;
      showAllRecords = !selected;
    });
  }

  void _navigateToEditRecord(Map<String, dynamic> record) {
    if (record['is_purchased'] == true) {
      Navigator.push(
        context,
        NoTransitionPageRoute(
          builder: (context) => EditRecord_PurchaseCoffee(record: record),
        ),
      ).then((_) {
        _loadRecords(); // Refresh the data when returning to the home page
      });
    } else if (record['is_homemade'] == true) {
      Navigator.push(
        context,
        NoTransitionPageRoute(
          builder: (context) => EditRecord_HomemadeCoffee(record: record),
        ),
      ).then((_) {
        _loadRecords(); // Refresh the data when returning to the home page
      });
    } else if (record['is_vendingmachine'] == true) {
      Navigator.push(
        context,
        NoTransitionPageRoute(
          builder: (context) => EditRecord_CoffeeVendingMachine(record: record),
        ),
      ).then((_) {
        _loadRecords(); // Refresh the data when returning to the home page
      });
    }
  }

  void _toggleEditMode() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  void _deleteRecord(int index) async {
    try {
      final record = showAllRecords ? _records[index] : _selectedDayRecords[index];
      
      // Delete the record from Firestore
      await FirestoreService().deleteDataByField('coffeerecords', 'purchase_id', record['purchase_id']);

      // Remove the record from the local list
      setState(() {
        if (showAllRecords) {
          _records.removeAt(index);
        } else {
          _selectedDayRecords.removeAt(index);
          _records.removeWhere((r) => r['purchase_id'] == record['purchase_id']);
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Filter Records',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: Text('Purchased Coffee',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    value: _filterPurchased,
                    onChanged: (value) {
                      setState(() {
                        _filterPurchased = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text('Homemade Coffee',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    value: _filterHomemade,
                    onChanged: (value) {
                      setState(() {
                        _filterHomemade = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text('Coffee Vending Machine',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    value: _filterVendingMachine,
                    onChanged: (value) {
                      setState(() {
                        _filterVendingMachine = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _filterRecords();
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _goToCurrentMonth() {
    setState(() {
      _selectedDay = DateTime.now();
      _focusedDay = DateTime.now();
      selected = false;
      showAllRecords = true;
      _loadRecords();
    });
  }

  Widget _buildCustomHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
              _loadRecords();
            });
          },
        ),
        TextButton(
          onPressed: () async {
            DateTime? selectedDate = await showDatePicker(
              context: context,
              initialDate: _focusedDay,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (selectedDate != null) {
              setState(() {
                _focusedDay = DateTime(selectedDate.year, selectedDate.month);
                _loadRecords();
              });
            }
          },
          child: Text(
            DateFormat('MMMM yyyy').format(_focusedDay),
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
              _loadRecords();
            });
          },
        ),
        IconButton(
          onPressed: _goToCurrentMonth, 
          icon: const Icon(Icons.replay_rounded)
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    bool hasRecords = showAllRecords ? _records.isNotEmpty : _selectedDayRecords.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Calendar',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: TextButton(
              onPressed: _toggleEditMode,
              child: Text(
                isEditing ? 'DONE' : 'EDIT',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search coffee type or shops...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _filterRecords();
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.filter_list),
                      onPressed: _showFilterDialog,
                    ),
                  ],
                ),
              ),
              _buildCustomHeader(),
              const SizedBox(height: 7),
              TableCalendar(
                focusedDay: _focusedDay,
                rowHeight: 45,
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2101, 12, 31),
                headerVisible: false,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day) && selected;
                },
                onDaySelected: _onDaySelected,
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  _loadRecords();
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (_records.any((record) => record['date'] == DateFormat('yyyy-MM-dd').format(day))) {
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 15),
              if (!hasRecords)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No records...')),
                ),
              if (hasRecords)
                showAllRecords
                    ? ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _records.length,
                        itemBuilder: (context, index) {
                          final record = _records[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (index == 0 || _records[index - 1]['date'] != record['date'])
                                Padding(
                                  padding:
                                    const EdgeInsets.fromLTRB(15, 25, 15, 5),
                                  child: Text(
                                    DateFormat('d MMMM yyyy').format(DateTime.parse(record['date'])),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Card(
                                color: Colors.white,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  leading: isEditing
                                      ? IconButton(
                                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                                          onPressed: () {
                                            _deleteRecord(index);
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
                                    '${record['time']} / £${record['price'].toStringAsFixed(2)}',
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
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _selectedDayRecords.length,
                        itemBuilder: (context, index) {
                          final record = _selectedDayRecords[index];
                          return Card(
                            color: Colors.white,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                              leading: isEditing
                                  ? IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                                      onPressed: () {
                                        _deleteRecord(index);
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
                            ),
                          );
                        },
                      ),
              const SizedBox(height: 50),
              if (!showAllRecords)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        NoTransitionPageRoute(builder: (context) => const ChooseCoffee()
                        ),
                      ).then((_) {
                        _loadRecords();  // Refresh the data when returning to the calendar page
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 110, 22, 240),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      elevation: 8,
                      shadowColor: Colors.black,
                    ),
                    child: Text(
                      'Add Coffee',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
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
        currentIndex: 1,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (int index) {
          setState(() {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                NoTransitionPageRoute(builder: (context) => Home()),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                NoTransitionPageRoute(builder: (context) => StatisticPage()),
              );
            } else if (index == 3) {
              // Add navigation for Settings page if needed
            }
          });
        },
      ),
    );
  }
}
