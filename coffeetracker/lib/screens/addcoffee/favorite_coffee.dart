import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coffeetracker/screens/addcoffee/add_favorite_coffee.dart';
import 'package:coffeetracker/screens/editrecord/edit_favorite_coffee.dart';
import 'package:flutter/material.dart';
import 'package:coffeetracker/services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class FavoriteCoffeesPage extends StatefulWidget {
  @override
  _FavoriteCoffeesPageState createState() => _FavoriteCoffeesPageState();
}

class NoTransitionPageRoute<T> extends MaterialPageRoute<T> {
  NoTransitionPageRoute({required WidgetBuilder builder}) : super(builder: builder);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

class _FavoriteCoffeesPageState extends State<FavoriteCoffeesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _favoriteCoffees = [];

  @override
  void initState() {
    super.initState();
    _fetchFavoriteCoffees();
  }

  Future<void> _fetchFavoriteCoffees() async {
    _favoriteCoffees = await _firestoreService.fetchFavoriteCoffees();
    setState(() {});
  }

  void _navigateToEditFavoriteCoffee(BuildContext context, Map<String, dynamic> coffee) {
    Navigator.push(
      context,
      NoTransitionPageRoute(builder: (context) => EditFavoriteCoffeePage(coffee: coffee)
      ),
    ).then((_) {
      // Refresh the list after returning from the edit page
      _fetchFavoriteCoffees();
    });
  }

  Future<void> _showAddRecordBottomSheet(BuildContext context, Map<String, dynamic> coffee) async {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Add Coffee Record', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Coffee Type: ${coffee['coffee_type_desc']}', style: GoogleFonts.montserrat(fontSize: 16)),
                Text('Volume: ${coffee['volume']} mL \t Price: £ ${coffee['price']}', style: GoogleFonts.montserrat(fontSize: 16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ListTile(
                        title: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null && picked != selectedDate) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text(MaterialLocalizations.of(context).formatTimeOfDay(selectedTime, alwaysUse24HourFormat: true)),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                            builder: (BuildContext context, Widget? child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null && picked != selectedTime) {
                            setState(() {
                              selectedTime = picked;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 110, 22, 240),
                    fixedSize: const Size(160, 45),
                  ),
                  child: Text('Add', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  onPressed: () {
                    _addCoffeeRecord(context, coffee, selectedDate, selectedTime);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    },
  );
}


  Future<void> _addCoffeeRecord(BuildContext context, Map<String, dynamic> coffee, DateTime date, TimeOfDay time) async {
    final DateTime dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    await _firestoreService.addCoffeeRecord({
      'device_uuid': coffee['device_uuid'],
      'purchase_id': DateTime.now().millisecondsSinceEpoch, // Unique ID
      'coffee_name': coffee['coffee_name'],
      'coffee_type_desc': coffee['coffee_type_desc'],
      'coffee_size_desc': coffee['coffee_size_desc'],
      'volume': coffee['volume'],
      'price': coffee['price'],
      'coffee_shop': coffee['coffee_shop'],
      'brand': coffee['brand'],
      'notes': coffee['notes'],
      'shop_address': coffee['shop_address'],
      'is_purchased': coffee['is_purchased'],
      'is_homemade': coffee['is_homemade'],
      'is_vendingmachine': coffee['is_vendingmachine'],
      'date': DateFormat('yyyy-MM-dd').format(dateTime),
      'time': DateFormat('HH:mm').format(dateTime),
      'created_at': FieldValue.serverTimestamp(),
    });

    Navigator.of(context)..pop()..pop()..pop(); // Close the bottom sheet and back to home page

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Record saved successfully!',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        dismissDirection: DismissDirection.up,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 230,
          left: 15,
          right: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Favourite Coffees',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Center(
              child: Text(
                'Add your favourite coffee to quickly log your drink\n'
                'Tap on a record to edit or delete',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _favoriteCoffees.length,
              itemBuilder: (context, index) {
                var coffee = _favoriteCoffees[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 7.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    leading: coffee['is_purchased'] == true
                        ? Image.asset('assets/coffee-cup.png', height: 45,)
                        : coffee['is_homemade'] == true
                            ? Image.asset('assets/latte.png', height: 45)
                            : coffee['is_vendingmachine'] == true
                                ? Image.asset('assets/coffee-machine.png', height: 45)
                                : const Icon(Icons.coffee),
                    title: Text("${coffee['coffee_type_desc']} ${coffee['coffee_name'].isNotEmpty ?  ': ${coffee['coffee_name']}': ''}",
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),),
                    subtitle: Text( "${coffee['is_purchased'] == true ?  '${coffee['coffee_shop']}\n': ''}"
                                    '${coffee['volume']} mL\t £ ${coffee['price']}',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_rounded, color: Colors.blue, size: 32),
                      onPressed: () => _showAddRecordBottomSheet(context, coffee),
                    ),
                    onTap: () => _navigateToEditFavoriteCoffee(context, coffee),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 75),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              NoTransitionPageRoute(builder: (context) => const AddFavoriteCoffeePage()),
            ).then((_) => _fetchFavoriteCoffees());
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0)),
          label: Text(
            'Add Favourite Coffee',
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
}
