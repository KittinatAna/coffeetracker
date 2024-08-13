import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:coffeetracker/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../map_screen.dart';

class EditRecord_CoffeeVendingMachine extends StatefulWidget {
  final Map<String, dynamic> record;

  const EditRecord_CoffeeVendingMachine({required this.record, Key? key}) : super(key: key);

  @override
  _EditRecord_CoffeeVendingMachineState createState() => _EditRecord_CoffeeVendingMachineState();
}

class _EditRecord_CoffeeVendingMachineState extends State<EditRecord_CoffeeVendingMachine> {
  final FirestoreService _firestoreService = FirestoreService();
  late TextEditingController _coffeeNameController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _priceController;
  late TextEditingController _volumeController;
  late TextEditingController _vendingMachineBrandController;
  late TextEditingController _notesController;
  late TextEditingController _addressController;
  String? _selectedCoffeeSize;
  String? _selectedCoffeeType;
  List<Map<String, dynamic>> _coffeeTypes = [];
  List<Map<String, dynamic>> _coffeeSizes = [];

  @override
  void initState() {
    super.initState();
    _coffeeNameController = TextEditingController(text: widget.record['coffee_name']);
    _dateController = TextEditingController(text: widget.record['date']);
    _timeController = TextEditingController(text: widget.record['time']);
    _priceController = TextEditingController(text: widget.record['price'].toString());
    _volumeController = TextEditingController(text: widget.record['volume'].toString());
    _vendingMachineBrandController = TextEditingController(text: widget.record['brand']);
    _notesController = TextEditingController(text: widget.record['notes']);
    _addressController = TextEditingController(text: widget.record['shop_address']);
    _selectedCoffeeSize = widget.record['coffee_size_desc'];
    _selectedCoffeeType = widget.record['coffee_type_desc'];
    _loadCoffeeData();
  }

  Future<void> _loadCoffeeData() async {
    final coffeeSizes = await _firestoreService.fetchCoffeeSizes();
    final coffeeTypes = await _firestoreService.fetchCoffeeTypes();
    setState(() {
      _coffeeSizes = coffeeSizes;
      _coffeeTypes = coffeeTypes;
    });
  }

  void _selectDate() async {
  DateTime initialDate;
  try {
    initialDate = DateFormat('yyyy-MM-dd').parse(_dateController.text);
  } catch (e) {
    initialDate = DateTime.now();
  }

  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );

  if (pickedDate != null) {
    setState(() {
      _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
    });
  }
}


  void _selectTime() async {
    TimeOfDay initialTime;
    try {
      final timeParts = _timeController.text.split(":");
      if (timeParts.length == 2) {
        final int hour = int.parse(timeParts[0]);
        final int minute = int.parse(timeParts[1]);
        initialTime = TimeOfDay(hour: hour, minute: minute);
      } else {
        initialTime = TimeOfDay.now();
      }
    } catch (e) {
      initialTime = TimeOfDay.now();
    }

    final TimeOfDay? pickedTime = await showTimePicker(
    context: context,
    initialTime: initialTime,
    builder: (BuildContext context, Widget? child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      );
    },
  );

    if (pickedTime != null) {
      setState(() {
        final localizations = MaterialLocalizations.of(context);
        final formattedTime = localizations.formatTimeOfDay(pickedTime, alwaysUse24HourFormat: true);
        _timeController.text = formattedTime;
      });
    }
  }

  void _pickAddressOnMap() async {
    LatLng? addressLatLng;

    if (_addressController.text.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(_addressController.text);
        if (locations.isNotEmpty) {
          addressLatLng = LatLng(locations.first.latitude, locations.first.longitude);
        }
      } catch (e) {
        print('Error: $e');
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          onLocationPicked: (address) {
            setState(() {
              _addressController.text = address;
            }); 
          },
          initialPosition: addressLatLng,
        ),
      ),
    );
  }


  Future<void> _updateRecord() async {
    Map<String, dynamic> updatedRecord = {
      'coffee_name': _coffeeNameController.text,
      'coffee_type_desc': _selectedCoffeeType,
      'coffee_size_desc': _selectedCoffeeSize,
      'volume': int.parse(_volumeController.text),
      'price': double.parse(_priceController.text),
      'brand': _vendingMachineBrandController.text,
      'notes': _notesController.text,
      'shop_address': _addressController.text,
      'date': _dateController.text,
      'time': _timeController.text,
      'updated_at': FieldValue.serverTimestamp(),
    };

    await _firestoreService.updateDataByField('coffeerecords', 'purchase_id', widget.record['purchase_id'], updatedRecord);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Record updated successfully!',
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

    Navigator.pop(context);
  }

  Future<void> _deleteRecord() async {
    await _firestoreService.deleteDataByField('coffeerecords', 'purchase_id', widget.record['purchase_id']);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Record deleted successfully!',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        dismissDirection: DismissDirection.up,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 230,
          left: 15,
          right: 15,
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Record',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Text(
                'Coffee Vending Machine',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
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
                    Row(
                      children: [
                        const Icon(Icons.local_cafe, size: 30),
                        const SizedBox(width: 10),
                        Text(
                          'Coffee Details',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCoffeeType,
                      decoration: InputDecoration(
                        labelText: 'Coffee Type*',
                        labelStyle: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      items: _coffeeTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['coffee_type_desc'],
                          child: Text(type['coffee_type_desc']),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCoffeeType = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCoffeeSize,
                      decoration: InputDecoration(
                        labelText: 'Coffee Size*',
                        labelStyle: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      items: _coffeeSizes.map((size) {
                        return DropdownMenuItem<String>(
                          value: size['coffee_size_desc'],
                          child: Text(size['coffee_size_desc']),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCoffeeSize = newValue;
                          // Automatically fill volume based on selected coffee size
                          if (newValue == 'Small') {
                            _volumeController.text = '227';
                          } else if (newValue == 'Medium') {
                            _volumeController.text = '341';
                          } else if (newValue == 'Large') {
                            _volumeController.text = '455';
                          } else if (newValue == 'Extra Large') {
                            _volumeController.text = '568';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _volumeController,
                            decoration: InputDecoration(
                              labelText: 'Estimated Volume (mL)*',
                              labelStyle: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.info_outline, color: Colors.grey[600]),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Volume Information', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                                  content: SingleChildScrollView(
                                    child: Table(
                                      border: TableBorder.all(color: Colors.grey),
                                      columnWidths: const <int, TableColumnWidth>{
                                        0: FlexColumnWidth(),
                                        1: FixedColumnWidth(50),
                                        2: FixedColumnWidth(50),
                                      },
                                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                      children: <TableRow>[
                                        TableRow(
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('Size', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('Oz.', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('mL.', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('Small', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('8', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('227', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('Medium', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('12', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('341', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('Large', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('16', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('455', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                          ],
                                        ),
                                        TableRow(
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('Extra-large', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('20', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('568', style: GoogleFonts.montserrat(fontSize: 14)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text('Close', style: GoogleFonts.montserrat(fontSize: 14)),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price*',
                        labelStyle: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _vendingMachineBrandController,
                      decoration: InputDecoration(
                        labelText: 'Brand (Optional)',
                        labelStyle: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _dateController,
                          decoration: InputDecoration(
                            labelText: 'Date*',
                            labelStyle: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _selectTime,
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _timeController,
                          decoration: InputDecoration(
                            labelText: 'Time*',
                            labelStyle: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        labelStyle: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: "Location (Optional)",
                              labelStyle: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            readOnly: true,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.location_on),
                          onPressed: _pickAddressOnMap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _deleteRecord,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            fixedSize: const Size(155, 45),
                            side: const BorderSide(color: Colors.red)
                            ),
                            child: Text(
                              'Delete',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _updateRecord,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 110, 22, 240),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            fixedSize: const Size(155, 45),
                            ),
                            child: Text(
                              'Save',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),);
  }
}
