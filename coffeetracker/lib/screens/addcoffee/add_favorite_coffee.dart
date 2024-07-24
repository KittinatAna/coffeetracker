import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:coffeetracker/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../map_screen.dart';

class AddFavoriteCoffeePage extends StatefulWidget {
  const AddFavoriteCoffeePage({super.key});

  @override
  _AddFavoriteCoffeePageState createState() => _AddFavoriteCoffeePageState();
}

class _AddFavoriteCoffeePageState extends State<AddFavoriteCoffeePage> {
  final TextEditingController _priceController = TextEditingController(text: "0.00");
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _coffeeNameController = TextEditingController();
  final TextEditingController _coffeeShopController = TextEditingController();
  final TextEditingController _vendingMachineBrandController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Coffee Type and Coffee Size
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _coffeeSizes = [];
  List<Map<String, dynamic>> _coffeeTypes = [];
  String? _selectedCoffeeSize;
  String? _selectedCoffeeType;
  String _coffeeChoice = 'Purchased';

  @override
  void initState() {
    super.initState();
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

  void _saveData() async {
    setState(() {
      if (_priceController.text.isEmpty) {
        _priceController.text = "0.00";
      } else {
        double price = double.parse(_priceController.text);
        _priceController.text = price.toStringAsFixed(2);
      }
      _coffeeShopController.text = _coffeeShopController.text.toUpperCase();
      _vendingMachineBrandController.text = _vendingMachineBrandController.text.toUpperCase();
    });

    if (_coffeeChoice == 'Purchased' ?
        _selectedCoffeeType == null ||
        _selectedCoffeeSize == null ||
        _volumeController.text.isEmpty ||
        _coffeeShopController.text.isEmpty ||
        _addressController.text.isEmpty : 
        _coffeeChoice == 'Homemade' ? 
        _selectedCoffeeType == null ||
        _volumeController.text.isEmpty : 
        // Vending Machine
         _selectedCoffeeType == null ||
        _selectedCoffeeSize == null ||
        _volumeController.text.isEmpty
      ) {
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
      'favorite_id': DateTime.now().millisecondsSinceEpoch, // Unique ID
      'device_uuid': deviceUUID,
      'coffee_name': _coffeeNameController.text,
      'coffee_type_desc': _selectedCoffeeType,
      'coffee_size_desc': _selectedCoffeeSize,
      'volume': int.parse(_volumeController.text.isEmpty ? '0' : _volumeController.text),
      'price': double.parse(_priceController.text.isEmpty ? '0.00' : _priceController.text),
      'coffee_shop': _coffeeShopController.text,
      'brand': _vendingMachineBrandController.text,
      'notes': _notesController.text,
      'shop_address': _addressController.text,
      'is_purchased': _coffeeChoice == 'Purchased',
      'is_homemade': _coffeeChoice == 'Homemade',
      'is_vendingmachine': _coffeeChoice == 'Vending Machine',
      'created_at': FieldValue.serverTimestamp(),
    };

    // Save data to Firestore
    await _firestoreService.addFavoriteCoffee(newRecord);

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
    Navigator.of(context).pop();
  }

  Widget _buildCommonCoffeeDetails() {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildPurchasedCoffeeForm() {
    return Column(
      children: [
        _buildCommonCoffeeDetails(),
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
          controller: _coffeeShopController,
          decoration: InputDecoration(
            labelText: 'Coffee Shop*',
            labelStyle: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            border: const OutlineInputBorder(),
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
                  labelText: "Shop's Address*",
                  labelStyle: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  border: const OutlineInputBorder(),
                ),
                readOnly: true,  // Make the address field read-only
              ),
            ),
            IconButton(
              icon: const Icon(Icons.location_on),
              onPressed: _pickAddressOnMap,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHomemadeCoffeeForm() {
    return Column(
      children: [
        _buildCommonCoffeeDetails(),
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
      ],
    );
  }

  Widget _buildVendingMachineForm() {
    return Column(
      children: [
        _buildCommonCoffeeDetails(),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget formContent;

    switch (_coffeeChoice) {
      case 'Homemade':
        formContent = _buildHomemadeCoffeeForm();
        break;
      case 'Vending Machine':
        formContent = _buildVendingMachineForm();
        break;
      case 'Purchased':
      default:
        formContent = _buildPurchasedCoffeeForm();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Favorite Coffee',
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
            children: [
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
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
                      DropdownButtonFormField<String>(
                        value: _coffeeChoice,
                        decoration: InputDecoration(
                          labelText: 'Coffee Choice*',
                          labelStyle: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        items: ['Purchased', 'Homemade', 'Vending Machine'].map((choice) {
                          return DropdownMenuItem<String>(
                            value: choice,
                            child: Text(choice),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _coffeeChoice = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      formContent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 45),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
    );
  }
}
