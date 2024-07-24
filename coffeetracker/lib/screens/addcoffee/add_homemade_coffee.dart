import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:coffeetracker/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddHomemadeCoffee extends StatefulWidget {
  const AddHomemadeCoffee({super.key});

  @override
  _AddHomemadeCoffeeState createState() => _AddHomemadeCoffeeState();
}

class _AddHomemadeCoffeeState extends State<AddHomemadeCoffee> {

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController(text: "0.00");
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _coffeeNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Coffee Type and Coffee Size
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _coffeeTypes = [];
  String? _selectedCoffeeType;

  @override
  void initState() {
    super.initState();
    _loadCoffeeData();
  }

  Future<void> _loadCoffeeData() async {
    final coffeeTypes = await _firestoreService.fetchCoffeeTypes();
    setState(() {
      _coffeeTypes = coffeeTypes;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
        final localizations = MaterialLocalizations.of(context);
        final formattedTime = localizations.formatTimeOfDay(_selectedTime!, alwaysUse24HourFormat: true);
        _timeController.text = formattedTime;
      });
    }
  }


  void _saveData() async {

    setState(() {
      if (_priceController.text.isEmpty) {
        _priceController.text = "0.00";
      } else {
        double price = double.parse(_priceController.text);
        _priceController.text = price.toStringAsFixed(2);
      }
      
    });

    if (_selectedCoffeeType == null ||
        _volumeController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _timeController.text.isEmpty) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all required fields (*)',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Prepare data to save
    String deviceUUID = await _firestoreService.getDeviceUUID();
    Map<String, dynamic> newRecord = {
      'purchase_id': DateTime.now().millisecondsSinceEpoch, // Unique ID
      'device_uuid': deviceUUID,  
      'coffee_name': _coffeeNameController.text,
      'coffee_type_desc': _selectedCoffeeType,
      'coffee_size_desc': null,
      'volume': int.parse(_volumeController.text.isEmpty ? '0' : _volumeController.text),
      'price': double.parse(_priceController.text.isEmpty ? '0.00' : _priceController.text),
      'coffee_shop': '',
      'brand': '',
      'notes': _notesController.text,
      'shop_address': '',
      'date': _dateController.text,
      'time': _timeController.text,
      'is_purchased': false,
      'is_homemade': true,
      'is_vendingmachine': false,
      'created_at': FieldValue.serverTimestamp(),
    };

    // Save data to Firestore
    await _firestoreService.addCoffeeRecord(newRecord);

    // Show success message
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

    // back to two previous page
    Navigator.of(context)..pop()..pop();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Homemade Coffee',
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
          child: Center(
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
                      Text('\t\t * Field is required',
                        style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.red
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _coffeeNameController,
                    decoration: InputDecoration(
                      labelText: 'Coffee Name (Optional)',
                      labelStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      border: const OutlineInputBorder(),
                    ),
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
                      labelText: 'Price (Optional)',
                      labelStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _selectDate(context),
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
                    onTap: () => _selectTime(context),
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
                  const SizedBox(height: 25),
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 110, 22, 240),
                        padding: const EdgeInsets.symmetric(horizontal: 130, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
